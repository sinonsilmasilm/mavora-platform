import { createClient } from "npm:@supabase/supabase-js@2";

function constantTimeEqual(a: string,b: string): boolean {
  if (a.length !== b.length) return false;
  let diff=0; for(let i=0;i<a.length;i++) diff |= a.charCodeAt(i)^b.charCodeAt(i);
  return diff===0;
}
function hex(bytes: Uint8Array): string { return [...bytes].map(x=>x.toString(16).padStart(2,"0")).join(""); }

async function verifySignature(raw: string, header: string, secret: string): Promise<boolean> {
  const parts = Object.fromEntries(header.split(";").map(p=>p.split("=",2) as [string,string]));
  const ts=parts.ts, signature=parts.h1;
  if(!ts || !signature || !/^\d+$/.test(ts)) return false;
  const seconds=Number(ts);
  if(!Number.isFinite(seconds) || Math.abs(Date.now()/1000-seconds)>300) return false;
  const key=await crypto.subtle.importKey("raw",new TextEncoder().encode(secret),{name:"HMAC",hash:"SHA-256"},false,["sign"]);
  const digest=await crypto.subtle.sign("HMAC",key,new TextEncoder().encode(ts + ":" + raw));
  return constantTimeEqual(hex(new Uint8Array(digest)),signature);
}

Deno.serve(async(req)=>{
  if(req.method!=="POST") return new Response("Method not allowed",{status:405});
  const secret=Deno.env.get("PADDLE_WEBHOOK_SECRET");
  const url=Deno.env.get("SUPABASE_URL"),service=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if(!secret||!url||!service) return new Response("Webhook not configured",{status:503});
  const raw=await req.text();
  const signature=req.headers.get("Paddle-Signature")??"";
  if(!(await verifySignature(raw,signature,secret))) return new Response("Invalid signature",{status:401});

  let event:any;
  try{event=JSON.parse(raw)}catch{return new Response("Invalid JSON",{status:400})}
  if(typeof event?.event_id!=="string"||typeof event?.event_type!=="string"||!event?.data) return new Response("Invalid event",{status:400});

  const admin=createClient(url,service,{auth:{persistSession:false}});
  const data=event.data;
  const custom=data.custom_data??{};
  const storeId=custom.store_id;
  const planCode=custom.plan_code;
  const safePayload={event_id:event.event_id,event_type:event.event_type,occurred_at:event.occurred_at,subscription_id:data.id,status:data.status,custom_data:custom};
  const {data:inserted,error:insertError}=await admin.from("billing_events").insert({
    provider:"paddle",provider_event_id:event.event_id,event_type:event.event_type,
    store_id:typeof storeId==="string"?storeId:null,payload_safe:safePayload
  }).select("id").maybeSingle();
  if(insertError){
    if(insertError.code==="23505") return new Response("Already processed",{status:200});
    return new Response("Could not record event",{status:500});
  }

  try{
    if(event.event_type.startsWith("subscription.") && typeof storeId==="string" && ["starter","pro","business"].includes(planCode)){
      const paddleStatus=String(data.status??"");
      const status=paddleStatus==="active"?"active":paddleStatus==="trialing"?"trialing":paddleStatus==="past_due"?"past_due":paddleStatus==="canceled"?"cancelled":paddleStatus==="paused"?"paused":"inactive";
      const periodEnd=data.current_billing_period?.ends_at??data.ends_at??null;
      const occurredAt=event.occurred_at??new Date().toISOString();
      const {data:existing,error:readError}=await admin.from("subscriptions")
        .select("provider_event_occurred_at").eq("store_id",storeId).maybeSingle();
      if(readError) throw readError;
      const prior=existing?.provider_event_occurred_at ? Date.parse(existing.provider_event_occurred_at) : 0;
      if(Date.parse(occurredAt)>=prior){
        const {error}=await admin.from("subscriptions").upsert({
          store_id:storeId,provider:"paddle",provider_subscription_id:data.id??null,
          provider_customer_id:data.customer_id??null,plan_code:planCode,status,
          current_period_end:periodEnd,provider_event_occurred_at:occurredAt,updated_at:new Date().toISOString()
        },{onConflict:"store_id"});
        if(error) throw error;
      }
    }
    await admin.from("billing_events").update({processed_at:new Date().toISOString()}).eq("id",inserted.id);
    return new Response("ok",{status:200});
  }catch(_){
    await admin.from("billing_events").update({processing_error:"Subscription update failed"}).eq("id",inserted.id);
    return new Response("Event processing failed",{status:500});
  }
});
