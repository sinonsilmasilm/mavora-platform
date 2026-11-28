import { createClient } from "npm:@supabase/supabase-js@2";

const cors = (origin: string) => ({
  "Access-Control-Allow-Origin": origin,
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Vary": "Origin",
  "Content-Type": "application/json",
});

Deno.serve(async (req) => {
  const allowedOrigin = Deno.env.get("ALLOWED_ORIGIN") ?? "https://sinonsilmasilm.github.io";
  const origin = req.headers.get("Origin") ?? "";
  if (!allowedOrigin || origin !== allowedOrigin) return new Response("Origin not allowed", {status:403});
  const headers = cors(allowedOrigin);
  if (req.method === "OPTIONS") return new Response("ok", {headers});
  if (req.method !== "POST") return new Response("Method not allowed", {status:405,headers});

  const url = Deno.env.get("SUPABASE_URL");
  const anon = Deno.env.get("SUPABASE_ANON_KEY");
  const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const apiKey = Deno.env.get("PADDLE_API_KEY");
  const environment = Deno.env.get("PADDLE_ENVIRONMENT") ?? "sandbox";
  if (!url || !anon || !service || !apiKey || !["sandbox","production"].includes(environment)) {
    return Response.json({error:"Billing is not configured"},{status:503,headers});
  }

  const authorization = req.headers.get("Authorization") ?? "";
  if (!authorization.startsWith("Bearer ")) return Response.json({error:"Sign in required"},{status:401,headers});
  let body: {storeId?:string;planCode?:string;interval?:string};
  try { body = await req.json(); } catch { return Response.json({error:"Invalid request"},{status:400,headers}); }
  const storeId = String(body.storeId ?? "");
  const planCode = String(body.planCode ?? "");
  const interval = body.interval === "annual" ? "annual" : "monthly";
  if (!/^[0-9a-f-]{36}$/i.test(storeId) || !["starter","pro","business"].includes(planCode)) {
    return Response.json({error:"Invalid store or plan"},{status:400,headers});
  }

  const userClient = createClient(url,anon,{global:{headers:{Authorization:authorization}}});
  const {data:userData,error:userError} = await userClient.auth.getUser();
  if (userError || !userData.user) return Response.json({error:"Invalid session"},{status:401,headers});

  const admin = createClient(url,service,{auth:{persistSession:false}});
  const {data:member,error:memberError} = await admin.from("store_members")
    .select("role").eq("store_id",storeId).eq("user_id",userData.user.id).maybeSingle();
  if (memberError || !member || !["owner","admin"].includes(member.role)) {
    return Response.json({error:"Only a store owner or admin can manage billing"},{status:403,headers});
  }

  const {data:plan,error:planError} = await admin.from("plan_catalog")
    .select("plan_code,is_sellable").eq("plan_code",planCode).eq("is_public",true).maybeSingle();
  if (planError || !plan || !plan.is_sellable) {
    return Response.json({error:"This plan is not available for purchase yet"},{status:409,headers});
  }

  const priceEnv = `PADDLE_PRICE_${planCode.toUpperCase()}_${interval.toUpperCase()}`;
  const priceId = Deno.env.get(priceEnv);
  if (!priceId) return Response.json({error:"The selected plan price is not configured"},{status:503,headers});

  const base = environment === "production" ? "https://api.paddle.com" : "https://sandbox-api.paddle.com";
  const response = await fetch(`${base}/transactions`,{
    method:"POST",
    headers:{"Authorization":`Bearer ${apiKey}`,"Content-Type":"application/json","Paddle-Version":"1"},
    body:JSON.stringify({
      items:[{price_id:priceId,quantity:1}],
      collection_mode:"automatic",
      custom_data:{store_id:storeId,owner_user_id:userData.user.id,plan_code:planCode,interval,application:"MAVORA"}
    })
  });
  const result = await response.json().catch(()=>({}));
  const checkoutUrl = result?.data?.checkout?.url;
  if (!response.ok || typeof checkoutUrl !== "string") {
    return Response.json({error:"Could not create checkout session"},{status:502,headers});
  }
  return Response.json({checkoutUrl},{status:200,headers});
});
