import {betterAuth} from 'better-auth';
import {bearer,deviceAuthorization} from 'better-auth/plugins';
import {passkey} from '@better-auth/passkey';
import {APIError} from 'better-auth/api';
import {catalog} from '../catalog.js';
import {sha256} from '../crypto.js';

const instances=new WeakMap();
const encoder=new TextEncoder();
export const DEVICE_CLIENT='brasa-godot';
export function authOrigin(env) {
  if(env.AUTH_MODE!=='better_auth' || typeof env.BETTER_AUTH_SECRET!=='string' || env.BETTER_AUTH_SECRET.length<32) throw new Error('AUTH_NOT_CONFIGURED');
  const url=new URL(env.BETTER_AUTH_URL);
  if(url.origin!==env.BETTER_AUTH_URL || (url.protocol!=='https:' && !(url.protocol==='http:' && url.hostname==='localhost'))) throw new Error('AUTH_NOT_CONFIGURED');
  return url.origin;
}
const encode=bytes=>btoa(String.fromCharCode(...bytes)).replaceAll('+','-').replaceAll('/','_').replace(/=+$/,'');
const decode=text=>Uint8Array.from(atob(text.replaceAll('-','+').replaceAll('_','/')),c=>c.charCodeAt(0));
async function signingKey(env) {return crypto.subtle.importKey('raw',encoder.encode(env.BETTER_AUTH_SECRET),{name:'HMAC',hash:'SHA-256'},false,['sign','verify']);}
export async function makeRegistration(env,name) {
  const payload=encode(encoder.encode(JSON.stringify({nonce:crypto.randomUUID(),expires:Date.now()+300000})));
  const signature=encode(new Uint8Array(await crypto.subtle.sign('HMAC',await signingKey(env),encoder.encode(payload))));
  const context=payload+'.'+signature;
  await env.DB.prepare('INSERT INTO auth_registration(context_hash,user_id,name,expires_at) VALUES(?,?,?,?)').bind(await sha256(context),crypto.randomUUID(),name,Date.now()+300000).run();
  return {context,expires_in:300};
}
async function registration(env,context) {
  try {
    if(typeof context!=='string' || context.length>1024) throw new Error();
    const [payload,signature,...extra]=context.split('.');
    if(extra.length || !await crypto.subtle.verify('HMAC',await signingKey(env),decode(signature),encoder.encode(payload))) throw new Error();
    const parsed=JSON.parse(new TextDecoder().decode(decode(payload)));
    if(parsed.expires<=Date.now()) throw new Error();
    const row=await env.DB.prepare('SELECT * FROM auth_registration WHERE context_hash=? AND consumed_at IS NULL AND expires_at>?').bind(await sha256(context),Date.now()).first();
    if(!row) throw new Error();
    return row;
  } catch {throw new APIError('BAD_REQUEST',{code:'INVALID_REGISTRATION',message:'El registro venció o ya se utilizó. Vuelve a comenzar.'});}
}
function requireVerified(verification) {
  if(!(verification.registrationInfo?.userVerified || verification.authenticationInfo?.userVerified)) throw new APIError('UNAUTHORIZED',{code:'USER_VERIFICATION_REQUIRED',message:'Confirma la passkey con biometría o el PIN del dispositivo.'});
}
export async function ensureGameAccount(env,userId) {
  // A session alone never provisions gameplay: a successfully stored passkey is required.
  const linked=await env.DB.prepare('SELECT account_id FROM auth_account_links WHERE auth_user_id=? AND EXISTS(SELECT 1 FROM auth_passkey WHERE userId=?)').bind(userId,userId).first();
  if(linked) return linked.account_id;
  const exists=await env.DB.prepare('SELECT id FROM auth_passkey WHERE userId=? LIMIT 1').bind(userId).first();
  if(!exists) throw new APIError('UNAUTHORIZED',{code:'PASSKEY_REQUIRED',message:'Registra una passkey válida.'});
  const id=crypto.randomUUID(),now=new Date().toISOString();
  await env.DB.batch([
    env.DB.prepare('INSERT INTO accounts(id,created_at) SELECT ?,? WHERE NOT EXISTS(SELECT 1 FROM auth_account_links WHERE auth_user_id=?)').bind(id,now,userId),
    env.DB.prepare('INSERT INTO auth_account_links(auth_user_id,account_id,created_at) SELECT ?,?,? WHERE NOT EXISTS(SELECT 1 FROM auth_account_links WHERE auth_user_id=?)').bind(userId,id,now,userId),
    env.DB.prepare("INSERT OR IGNORE INTO owned_cosmetics(account_id,inventory_id,source,granted_at) SELECT account_id,j.value,'starter',? FROM auth_account_links,json_each(?) j WHERE auth_user_id=?").bind(now,JSON.stringify(catalog.starter_owned),userId)
  ]);
  return (await env.DB.prepare('SELECT account_id FROM auth_account_links WHERE auth_user_id=?').bind(userId).first()).account_id;
}
export function authOptions(env) {
  const origin=authOrigin(env);
  return {
    appName:'Brasa · Liga de los Faroles',baseURL:origin,basePath:'/api/auth',secret:env.BETTER_AUTH_SECRET,database:env.DB,
    trustedOrigins:[origin],emailAndPassword:{enabled:false},
    user:{modelName:'auth_user'},account:{modelName:'auth_provider_account'},verification:{modelName:'auth_verification'},
    session:{modelName:'auth_session',expiresIn:604800,updateAge:86400,cookieCache:{enabled:false}},
    // The HTTP boundary applies an atomic D1 limiter to every exposed auth route.
    rateLimit:{enabled:false},
    advanced:{useSecureCookies:origin.startsWith('https:'),cookiePrefix:'brasa',ipAddress:{ipAddressHeaders:['cf-connecting-ip']}},
    // Avoid emitting request details, credentials or provider exception payloads.
    logger:{level:'error',log:()=>console.error('AUTH_PROVIDER_ERROR')},
    databaseHooks:{session:{create:{after:async session=>{await ensureGameAccount(env,session.userId);}}}},
    plugins:[bearer(),deviceAuthorization({expiresIn:'10m',interval:'5s',validateClient:id=>id===DEVICE_CLIENT,verificationUri:origin+'/device',schema:{deviceCode:{modelName:'auth_device_code'}}}),passkey({
      rpID:new URL(origin).hostname,rpName:'Brasa · Liga de los Faroles',origin,
      authenticatorSelection:{residentKey:'required',userVerification:'required'},
      schema:{passkey:{modelName:'auth_passkey'}},
      registration:{requireSession:false,
        resolveUser:async({context})=>{const row=await registration(env,context);return {id:row.user_id,name:row.name,displayName:row.name};},
        afterVerification:async({ctx,verification,user,context})=>{
          requireVerified(verification);
          const credential=await env.DB.prepare('SELECT id FROM auth_passkey WHERE credentialID=?').bind(verification.registrationInfo.credential.id).first();
          if(credential) throw new APIError('CONFLICT',{code:'PASSKEY_ALREADY_REGISTERED',message:'Esta passkey ya está registrada.'});
          const existing=await env.DB.prepare('SELECT id FROM auth_user WHERE id=?').bind(user.id).first();
          if(existing) {
            const session=await getAuth(env).api.getSession({headers:ctx.headers});
            if(!session || session.user.id!==user.id || Date.now()-new Date(session.session.createdAt).getTime()>300000) throw new APIError('UNAUTHORIZED',{code:'FRESH_SESSION_REQUIRED',message:'Inicia sesión de nuevo para añadir otra passkey.'});
            return {userId:user.id};
          }
          const row=await registration(env,context);
          if(row.user_id!==user.id) throw new APIError('BAD_REQUEST',{code:'INVALID_REGISTRATION',message:'Registro inválido.'});
          const claim=crypto.randomUUID(),now=Date.now();
          const results=await env.DB.batch([
            env.DB.prepare('UPDATE auth_registration SET consumed_at=?,claim_id=? WHERE context_hash=? AND consumed_at IS NULL AND expires_at>?').bind(now,claim,row.context_hash,now),
            env.DB.prepare('INSERT INTO auth_user(id,name,email,emailVerified,createdAt,updatedAt) SELECT user_id,name,user_id || \'@passkey.brasa.invalid\',0,?,? FROM auth_registration WHERE context_hash=? AND claim_id=?').bind(new Date(now).toISOString(),new Date(now).toISOString(),row.context_hash,claim)
          ]);
          if(results[0].meta.changes!==1) throw new APIError('BAD_REQUEST',{code:'INVALID_REGISTRATION',message:'Este registro ya se utilizó.'});
          return {userId:user.id};
        }
      },authentication:{afterVerification:async({verification})=>requireVerified(verification)}
    })]
  };
}
export function getAuth(env) {
  let entry=instances.get(env.DB);
  if(!entry || entry.origin!==env.BETTER_AUTH_URL || entry.secret!==env.BETTER_AUTH_SECRET) {
    entry={origin:env.BETTER_AUTH_URL,secret:env.BETTER_AUTH_SECRET,auth:betterAuth(authOptions(env))};instances.set(env.DB,entry);
  }
  return entry.auth;
}
