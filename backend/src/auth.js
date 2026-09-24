import {ApiError} from './errors.js';
import {sha256} from './crypto.js';
import {authOrigin,getAuth,ensureGameAccount} from './auth/config.js';
export {handleAuthRequest} from './auth/http.js';
export async function authenticate(request, env) {
  if(env.AUTH_MODE==='better_auth') {
    let origin;try {origin=authOrigin(env);} catch{throw new ApiError(503,'AUTH_NOT_CONFIGURED','La autenticación no está configurada.');}
    if(new URL(request.url).origin!==origin) throw new ApiError(403,'INVALID_ORIGIN','Origen no permitido.');
    // Gameplay API accepts a native bearer only; browser cookies cannot trigger gameplay.
    if(!/^Bearer [A-Za-z0-9._%~-]{20,512}$/.test(request.headers.get('authorization')||'')) throw new ApiError(401,'UNAUTHENTICATED','Se requiere una sesión válida.');
    const bearerHeaders=new Headers(request.headers);bearerHeaders.delete('cookie');
    const session=await getAuth(env).api.getSession({headers:bearerHeaders});
    if(!session) throw new ApiError(401,'UNAUTHENTICATED','Se requiere una sesión válida.');
    return {account_id:await ensureGameAccount(env,session.user.id),auth_user_id:session.user.id};
  }
  const host=new URL(request.url).hostname;
  if (env.AUTH_MODE!=='local_dev' || !['127.0.0.1','localhost','[::1]'].includes(host))
    throw new ApiError(503,'AUTH_NOT_CONFIGURED','La autenticación de producción no está configurada.');
  const match=/^Bearer (brasa_local_[A-Za-z0-9_-]{43})$/.exec(request.headers.get('Authorization')||'');
  if (!match) throw new ApiError(401,'UNAUTHENTICATED','Se requiere una sesión válida.');
  const hash=await sha256(match[1]);
  const row=await env.DB.prepare('SELECT account_id FROM local_sessions WHERE token_hash=? AND revoked_at IS NULL AND expires_at>?').bind(hash,Date.now()).first();
  if (!row) throw new ApiError(401,'UNAUTHENTICATED','Se requiere una sesión válida.');
  return {account_id:row.account_id};
}
