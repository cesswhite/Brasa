import {authOrigin,getAuth,makeRegistration} from './config.js';
import {sha256} from '../crypto.js';
import {validateName} from '../catalog.js';
import page from '../../web/index.html';
import browser from '../../web/client.bundle.js';

const allowed=new Set(['/get-session','/sign-out','/device/code','/device/token','/device','/device/approve','/device/deny','/passkey/generate-register-options','/passkey/verify-registration','/passkey/generate-authenticate-options','/passkey/verify-authentication','/passkey/list-user-passkeys']);
const native=new Set(['/device/code','/device/token','/sign-out','/get-session']);
const headers={'Cache-Control':'no-store','X-Content-Type-Options':'nosniff','Referrer-Policy':'no-referrer','X-Frame-Options':'DENY'};
const failure=(status,code,message)=>Response.json({error:code,error_description:message},{status,headers});
async function boundedJSON(request) {
  if(!request.headers.get('content-type')?.startsWith('application/json')) throw new Error('JSON_REQUIRED');
  const reader=request.body?.getReader();let length=0,chunks=[];
  if(reader) while(true) {const {value,done}=await reader.read();if(done)break;length+=value.length;if(length>32768){await reader.cancel();throw new Error('BODY_TOO_LARGE');}chunks.push(value);}
  const bytes=new Uint8Array(length);let at=0;for(const chunk of chunks){bytes.set(chunk,at);at+=chunk.length;}
  const value=JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(bytes));
  if(!value || typeof value!=='object' || Array.isArray(value)) throw new Error('INVALID_JSON');
  return value;
}
async function throttle(request,env,path) {
  const now=Date.now(),window=Math.floor(now/60000);
  const group=path==='/registration/nonce'?'signup':path==='/device/code'?'device-code':path==='/device/token'?'device-poll':'auth';
  const maximum={signup:5,'device-code':10,'device-poll':30,auth:60}[group];
  const key=await sha256((request.headers.get('cf-connecting-ip')||'local')+':'+group+':'+window);
  const row=await env.DB.prepare('INSERT INTO auth_throttle(bucket,hits,expires_at) VALUES(?,1,?) ON CONFLICT(bucket) DO UPDATE SET hits=hits+1 RETURNING hits').bind(key,(window+2)*60000).first();
  if(row.hits>maximum) return new Response(JSON.stringify({error:'rate_limited',error_description:'Demasiados intentos. Espera un minuto.'}),{status:429,headers:{...headers,'Content-Type':'application/json','Retry-After':'60'}});
  if(row.hits===1) await env.DB.batch([
    env.DB.prepare('DELETE FROM auth_throttle WHERE bucket IN (SELECT bucket FROM auth_throttle WHERE expires_at<? LIMIT 100)').bind(now),
    env.DB.prepare('DELETE FROM auth_registration WHERE context_hash IN (SELECT context_hash FROM auth_registration WHERE expires_at<? LIMIT 100)').bind(now-3600000),
    env.DB.prepare('DELETE FROM auth_device_code WHERE id IN (SELECT id FROM auth_device_code WHERE expiresAt<? LIMIT 100)').bind(new Date(now-3600000).toISOString()),
    env.DB.prepare('DELETE FROM auth_verification WHERE id IN (SELECT id FROM auth_verification WHERE expiresAt<? LIMIT 100)').bind(new Date(now-3600000).toISOString())
  ]);
  return null;
}
export async function handleAuthRequest(request,env) {
  const url=new URL(request.url),route=url.pathname;
  if(!route.startsWith('/auth/art/') && !['/auth','/device','/auth/client.js'].includes(route) && !route.startsWith('/api/auth/')) return null;
  let origin;
  try {origin=authOrigin(env);} catch{return failure(503,'AUTH_NOT_CONFIGURED','El acceso en línea no está configurado.');}
  if(url.origin!==origin) return failure(403,'INVALID_ORIGIN','Origen no permitido.');
  if(request.headers.has('origin') && request.headers.get('origin')!==origin) return failure(403,'INVALID_ORIGIN','Origen no permitido.');
  if(request.headers.get('sec-fetch-site')==='cross-site') return failure(403,'INVALID_ORIGIN','Origen no permitido.');
  if(route.startsWith('/auth/art/')) {
    if(request.method!=='GET' && request.method!=='HEAD') return failure(405,'METHOD_NOT_ALLOWED','Método no permitido.');
    if(!['/auth/art/world.png','/auth/art/fighter.png','/auth/art/surfaces.png','/auth/art/tokens.css'].includes(route) || !env.AUTH_ASSETS) return failure(404,'NOT_FOUND','Recurso no disponible.');
    const asset=await env.AUTH_ASSETS.fetch(request);
    const assetHeaders=new Headers(asset.headers);
    assetHeaders.set('X-Content-Type-Options','nosniff');
    assetHeaders.set('Referrer-Policy','no-referrer');
    return new Response(asset.body,{status:asset.status,headers:assetHeaders});
  }
  if(['/auth','/device','/auth/client.js'].includes(route)) {
    if(request.method!=='GET') return failure(405,'METHOD_NOT_ALLOWED','Método no permitido.');
    return new Response(route==='/auth/client.js'?browser:page,{headers:{...headers,'Content-Type':route==='/auth/client.js'?'text/javascript; charset=utf-8':'text/html; charset=utf-8','Content-Security-Policy':"default-src 'none'; script-src 'self'; style-src 'self' 'unsafe-inline'; connect-src 'self'; img-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'self'"}});
  }
  const path=route.slice('/api/auth'.length);
  if(!allowed.has(path) && path!=='/registration/nonce') return failure(404,'NOT_FOUND','La ruta no está disponible.');
  if(!['GET','POST'].includes(request.method)) return failure(405,'METHOD_NOT_ALLOWED','Método no permitido.');
  if(request.method==='POST' && !native.has(path) && request.headers.get('origin')!==origin) return failure(403,'INVALID_ORIGIN','Confirma desde el navegador de Brasa.');
  const limited=await throttle(request,env,path);if(limited)return limited;
  let body;
  if(request.method==='POST') {
    try {body=await boundedJSON(request.clone());} catch(error){return failure(error.message==='BODY_TOO_LARGE'?413:400,'INVALID_REQUEST','Solicitud JSON inválida o demasiado grande.');}
    // Better Auth supports pre-binding a device to a user. Public game clients never may.
    if(path==='/device/code' && Object.keys(body).some(key=>key!=='client_id')) return failure(400,'invalid_request','Sólo se permite client_id.');
  }
  if(path==='/registration/nonce') {
    if(request.method!=='POST') return failure(405,'METHOD_NOT_ALLOWED','Método no permitido.');
    try {
      if(Object.keys(body).some(key=>key!=='name')) return failure(422,'INVALID_REQUEST','Sólo se permite el nombre.');
      return Response.json(await makeRegistration(env,validateName(body.name).display_name),{headers});
    } catch(error){return failure(error.status||400,error.code||'INVALID_REGISTRATION',error.message||'Registro inválido.');}
  }
  const response=await getAuth(env).handler(request);
  const safeHeaders=new Headers(response.headers);for(const [key,value]of Object.entries(headers))safeHeaders.set(key,value);
  return new Response(response.body,{status:response.status,headers:safeHeaders});
}
