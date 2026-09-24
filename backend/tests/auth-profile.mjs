// Local V8 CPU samples are an engineering estimate, not Cloudflare's billed CPU metric.
import {fixture} from './helpers.mjs';
import {browser,authenticator,registrationOptions,ORIGIN} from './auth-helpers.mjs';
import {randomBytes} from 'node:crypto';
import {writeFile} from 'node:fs/promises';
const f=await fixture(undefined,true,{AUTH_MODE:'better_auth',BETTER_AUTH_URL:ORIGIN,BETTER_AUTH_SECRET:randomBytes(48).toString('hex')},{scriptPath:'dist/auth-test-worker.js',inspectorPort:0});
let socket;
try {
  const inspector=await f.mf.getInspectorURL();
  inspector.protocol='http:';
  const targets=await (await fetch(new URL('/json/list',inspector))).json();
  const target=targets.find(item=>item.id==='core:user:' || item.title?.includes('core:user:'));
  if(!target)throw new Error('User Worker inspector target unavailable: '+JSON.stringify(targets.map(t=>({id:t.id,title:t.title}))));
  socket=new WebSocket(target.webSocketDebuggerUrl);
  await new Promise((resolve,reject)=>{socket.addEventListener('open',resolve,{once:true});socket.addEventListener('error',reject,{once:true});});
  let id=0;const pending=new Map();socket.addEventListener('message',event=>{const response=JSON.parse(event.data);if(response.id){const handlers=pending.get(response.id);pending.delete(response.id);response.error?handlers.reject(new Error(JSON.stringify(response.error))):handlers.resolve(response.result);}});
  const send=(method,params={})=>new Promise((resolve,reject)=>{const key=++id;pending.set(key,{resolve,reject});socket.send(JSON.stringify({id:key,method,params}));});
  await send('Profiler.enable');await send('Profiler.setSamplingInterval',{interval:100});
  const measured=[];
  async function measure(name,action){await send('Profiler.start');const start=performance.now();await action();const wall=performance.now()-start;const {profile}=await send('Profiler.stop');const nodes=new Map(profile.nodes.map(node=>[node.id,node]));let active=0;for(let i=0;i<(profile.samples||[]).length;i++){const node=nodes.get(profile.samples[i]);if(node && !['(idle)','(program)'].includes(node.callFrame.functionName))active+=(profile.timeDeltas[i]||0)/1000;}measured.push({name,wall_ms:Math.round(wall*100)/100,sampled_v8_active_ms:Math.round(active*100)/100,samples:profile.samples?.length||0});}
  const web=browser(f.mf),key=authenticator();let options,token,context;
  await measure('cold_nonce',async()=>{const response=await web.call('/api/auth/registration/nonce',{name:'Perfil inicial'});if(response.status!==200)throw new Error('Nonce failed');context=response.data.context;});
  const optionsPath='/api/auth/passkey/generate-register-options?context='+encodeURIComponent(context);
  await measure('cold_options',async()=>{const response=await web.call(optionsPath);if(response.status!==200)throw new Error('Options failed');options=response.data;});
  for(let i=0;i<20;i++)await measure('warm_options_'+i,async()=>{const response=await web.call(optionsPath);if(response.status!==200)throw new Error('Options failed');options=response.data;});
  await measure('first_registration',async()=>{const result=await web.call('/api/auth/passkey/verify-registration',{response:key.registration(options),createSession:true});if(result.status!==200)throw new Error('Registration failed');token=result.data.session.token;});
  for(let i=0;i<20;i++) {
    // Reserved documentation IPs distinguish isolated simulated users; no production state or headers are altered.
    const client=browser(f.mf,{'cf-connecting-ip':'198.51.100.'+(i+1)}),fixtureKey=authenticator();let registrationOptionsJSON,nonce;
    await measure('warm_nonce_'+i,async()=>{const result=await client.call('/api/auth/registration/nonce',{name:'Perfil '+i});if(result.status!==200)throw new Error('Nonce failed');nonce=result.data.context;});
    const response=await client.call('/api/auth/passkey/generate-register-options?context='+encodeURIComponent(nonce));if(response.status!==200)throw new Error('Warm registration options failed');registrationOptionsJSON=response.data;
    await measure('warm_registration_'+i,async()=>{const result=await client.call('/api/auth/passkey/verify-registration',{response:fixtureKey.registration(registrationOptionsJSON),createSession:true});if(result.status!==200)throw new Error('Warm registration failed');});
  }
  for(let i=0;i<5;i++)await measure('authenticated_api_'+i,async()=>{if((await web.call('/v1/me',undefined,{headers:{Authorization:'Bearer '+token}})).status!==200)throw new Error('Auth failed');});
  await measure('device_code',async()=>{if((await web.call('/api/auth/device/code',{client_id:'brasa-godot'})).status!==200)throw new Error('Device code failed');});
  const summaries={};for(const prefix of ['warm_nonce_','warm_options_','warm_registration_','authenticated_api_']){const samples=measured.filter(m=>m.name.startsWith(prefix)).map(m=>m.sampled_v8_active_ms).sort((a,b)=>a-b);summaries[prefix]={count:samples.length,median_ms:samples[Math.floor(samples.length/2)],p95_ms:samples[Math.ceil(samples.length*.95)-1],max_ms:samples.at(-1)};}
  const report={runtime:'local workerd via Miniflare 4.20260708.1',method:'V8 profiler 100us sampling; excludes idle/program samples; local estimate, not edge CPU quota validation',requires_edge_cpu_measurement:true,summaries,measurements:measured};
  await writeFile('../../../work/identity/auth-local-profile-warm.json',JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report,null,2));
}finally{socket?.close();await f.close();}
