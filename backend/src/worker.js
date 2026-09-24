import {authenticate,handleAuthRequest} from './auth.js';
import {ApiError} from './errors.js';
import {catalog,catalogHash,assertCatalog} from './catalog.js';
import {createFighter,patchFighter,listFighters,readFighter,present} from './fighters.js';
import {readOwnedSnapshot} from './snapshots.js';
import {canonical,sha256} from './crypto.js';
import {gameRoute} from './game/routes.js';
import {ENGINE_VERSION} from '../battle-engine/index.js';
const MAX_BODY=8192;
async function jsonBody(request) {
  if(!request.headers.get('Content-Type')?.toLowerCase().startsWith('application/json')) throw new ApiError(415,'JSON_REQUIRED','Envía application/json.');
  if(Number(request.headers.get('Content-Length'))>MAX_BODY) throw new ApiError(413,'BODY_TOO_LARGE','La solicitud es demasiado grande.');
  const reader=request.body?.getReader(); let size=0,chunks=[];
  if(reader) while(true) {const {value,done}=await reader.read();if(done)break;size+=value.length;if(size>MAX_BODY){await reader.cancel();throw new ApiError(413,'BODY_TOO_LARGE','La solicitud es demasiado grande.');}chunks.push(value);}
  const bytes=new Uint8Array(size);let offset=0;for(const chunk of chunks){bytes.set(chunk,offset);offset+=chunk.length;}
  try{return JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(bytes));}catch{throw new ApiError(400,'INVALID_JSON','El JSON no es válido.');}
}
export default {
  async fetch(request,env) {
    const requestId=crypto.randomUUID(),started=performance.now();
    const headers={'Cache-Control':'no-store','X-Content-Type-Options':'nosniff','X-Request-ID':requestId};
    let responseStatus=500;
    try {
      const authResponse=await handleAuthRequest(request,env);
      if(authResponse){responseStatus=authResponse.status;return authResponse;}
      if(new URL(request.url).pathname==='/health'&&request.method==='GET') {
        const ready=await env.DB.prepare('SELECT COUNT(*) n FROM cosmetic_definitions').first();
        responseStatus=ready.n?200:503;
        return Response.json({data:{service:'Brasa',environment:env.APP_ENV||'local',engine_version:ENGINE_VERSION,ready:Boolean(ready.n)}},{status:responseStatus,headers});
      }
      const auth=await authenticate(request,env);
      await assertCatalog(env.DB);
      const game=await gameRoute(request,env,auth,jsonBody);
      if(game) {responseStatus=game.status||200;return Response.json({data:game.data},{status:responseStatus,headers});}
      const url=new URL(request.url),{pathname}=url,method=request.method;
      let data,status=200;
      if(pathname==='/v1/catalog'&&method==='GET') {
        const hash=url.searchParams.get('hash');
        if(!hash || hash===catalogHash) data={...catalog,catalog_hash:catalogHash};
        else {
          if(!/^[0-9a-f]{64}$/.test(hash)) throw new ApiError(422,'INVALID_REQUEST','Hash de catálogo inválido.');
          const version=await env.DB.prepare('SELECT payload FROM catalog_versions WHERE hash=?').bind(hash).first();
          if(!version) throw new ApiError(404,'CATALOG_NOT_FOUND','No se encontró esa versión del catálogo.');
          const historical=JSON.parse(version.payload);
          if(await sha256(canonical(historical))!==hash) throw new ApiError(500,'CATALOG_INTEGRITY','El catálogo histórico no supera la comprobación de integridad.');
          data={...historical,catalog_hash:hash};
        }
      }
      else if(pathname==='/v1/owned'&&method==='GET') data={account_id:auth.account_id,owned:(await env.DB.prepare('SELECT inventory_id,source,granted_at FROM owned_cosmetics WHERE account_id=? ORDER BY inventory_id').bind(auth.account_id).all()).results};
      else if(pathname==='/v1/fighters'&&method==='GET') data={fighters:await listFighters(env.DB,auth.account_id)};
      else if(pathname==='/v1/fighters'&&method==='POST') {data=await createFighter(env.DB,auth.account_id,await jsonBody(request));status=201;}
      else {
        const match=/^\/v1\/(fighters|opponents|snapshots)\/([0-9a-f-]{36})$/.exec(pathname);
        if(!match) throw new ApiError(404,'NOT_FOUND','La ruta no existe.');
        const [,resource,id]=match;
        if(resource==='fighters'&&method==='PATCH') data=await patchFighter(env.DB,auth.account_id,id,await jsonBody(request));
        else if(resource==='fighters'&&method==='GET') data=present(await readFighter(env.DB,id,auth.account_id),true);
        else if(resource==='opponents'&&method==='GET') data=present(await readFighter(env.DB,id));
        else if(resource==='snapshots'&&method==='GET') data=await readOwnedSnapshot(env.DB,id,auth.account_id);
        else throw new ApiError(405,'METHOD_NOT_ALLOWED','Ese método no está disponible.');
      }
      responseStatus=status;
      return Response.json({data},{status,headers});
    } catch(error) {
      if(!(error instanceof ApiError)) {
        if(String(error).includes('COSMETIC_NOT_OWNED')) error=new ApiError(403,'COSMETIC_NOT_OWNED','La cuenta no posee ese cosmético.');
        else error=new ApiError(500,'INTERNAL_ERROR','No se pudo completar la solicitud.');
      }
      responseStatus=error.status;
      if(error.status===429)headers['Retry-After']=error.code==='RATE_LIMITED'?'60':'3';
      return Response.json({error:{code:error.code,message:error.message},request_id:requestId},{status:error.status,headers});
    } finally {
      if(env.LOG_REQUESTS==='true')console.log(JSON.stringify({request_id:requestId,route:new URL(request.url).pathname,method:request.method,status:responseStatus,duration_ms:Math.round(performance.now()-started)}));
    }
  }
};
