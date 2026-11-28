const CACHE='mavora-cloud-v3';
const ASSETS=['./cloud.html','./cloud.js','./styles.css','./supabase-client-config.js','./manifest.webmanifest','./mavora-icon.svg','./help.html'];
self.addEventListener('install',event=>{event.waitUntil(caches.open(CACHE).then(cache=>cache.addAll(ASSETS)));self.skipWaiting()});
self.addEventListener('activate',event=>{event.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(key=>key!==CACHE).map(key=>caches.delete(key)))).then(()=>self.clients.claim()))});
self.addEventListener('fetch',event=>{
 const request=event.request;
 if(request.method!=='GET')return;
 const url=new URL(request.url);
 if(url.origin!==self.location.origin)return;
 const allowed=ASSETS.some(path=>new URL(path,self.location.origin).pathname===url.pathname);
 if(!allowed)return;
 event.respondWith(fetch(request).then(response=>{
  if(response&&response.ok){const copy=response.clone();caches.open(CACHE).then(cache=>cache.put(request,copy))}
  return response;
 }).catch(()=>caches.match(request).then(cached=>cached||caches.match('./cloud.html'))));
});
