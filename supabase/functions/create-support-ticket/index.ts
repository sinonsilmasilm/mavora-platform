import { createClient } from "npm:@supabase/supabase-js@2";

const allowedCategories=["general","billing","technical","data","security","feature"];
Deno.serve(async(req)=>{
  if(req.method!=="POST") return new Response("Method not allowed",{status:405});
  const url=Deno.env.get("SUPABASE_URL"),anon=Deno.env.get("SUPABASE_ANON_KEY"),service=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if(!url||!anon||!service) return Response.json({error:"Support service is not configured"},{status:503});
  const auth=req.headers.get("Authorization")??"";
  if(!auth.startsWith("Bearer ")) return Response.json({error:"Sign in required"},{status:401});
  let body:any;try{body=await req.json()}catch{return Response.json({error:"Invalid JSON"},{status:400})}
  const storeId=String(body.storeId??""),subject=String(body.subject??"").trim(),message=String(body.message??"").trim(),category=String(body.category??"general");
  if(!/^[0-9a-f-]{36}$/i.test(storeId)||subject.length<4||subject.length>180||message.length<1||message.length>10000||!allowedCategories.includes(category)){
    return Response.json({error:"Invalid ticket details"},{status:400});
  }
  const userClient=createClient(url,anon,{global:{headers:{Authorization:auth}}});
  const {data:userData,error:userError}=await userClient.auth.getUser();
  if(userError||!userData.user) return Response.json({error:"Invalid session"},{status:401});
  const admin=createClient(url,service,{auth:{persistSession:false}});
  const {data:member,error:memberError}=await admin.from("store_members").select("role").eq("store_id",storeId).eq("user_id",userData.user.id).maybeSingle();
  if(memberError||!member) return Response.json({error:"Store access denied"},{status:403});
  const {data:ticket,error:ticketError}=await admin.from("support_tickets").insert({
    store_id:storeId,created_by:userData.user.id,subject,category,priority:category==="security"?"high":"normal"
  }).select("id").single();
  if(ticketError||!ticket) return Response.json({error:"Could not create ticket"},{status:500});
  const {error:messageError}=await admin.from("support_messages").insert({
    ticket_id:ticket.id,store_id:storeId,author_user_id:userData.user.id,author_type:"merchant",message
  });
  if(messageError){
    await admin.from("support_tickets").delete().eq("id",ticket.id);
    return Response.json({error:"Could not save ticket message"},{status:500});
  }
  return Response.json({ticketId:ticket.id,status:"open"},{status:201});
});
