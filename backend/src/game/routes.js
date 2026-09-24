import {ApiError} from '../errors.js';
import {createFighter,patchFighter} from '../fighters.js';
import {operation,limitMutation,uuid} from './operations.js';
import {listOnline,readOnline,presentOnline,changeBuild} from './profiles.js';
import {createBattle,readBattle} from './battles.js';
import {publicGameCatalog,opponents,story,history,offlineResults,acknowledgeOffline} from './queries.js';

export async function gameRoute(request,env,auth,readBody) {
  const url=new URL(request.url),path=url.pathname,method=request.method,db=env.DB,owner=auth.account_id;
  if(method==='GET') {
    if(path==='/v1/me')return {data:{account_id:owner,is_test:Boolean((await db.prepare('SELECT is_test FROM accounts WHERE id=?').bind(owner).first())?.is_test)}};
    if(path==='/v1/game/catalog')return {data:publicGameCatalog()};
    if(path==='/v1/fighters')return {data:{fighters:await listOnline(db,owner)}};
    if(path==='/v1/arena/opponents')return {data:await opponents(db,owner,url.searchParams.get('fighter_id'))};
    if(path==='/v1/story')return {data:await story(db,owner,url.searchParams.get('fighter_id'))};
    if(path==='/v1/history')return {data:await history(db,owner,url.searchParams)};
    if(path==='/v1/arena/offline-results')return {data:await offlineResults(db,owner)};
    const fighter=/^\/v1\/fighters\/([^/]+)$/.exec(path);
    if(fighter)return {data:presentOnline(await readOnline(db,uuid(fighter[1]),owner),true)};
    const battle=/^\/v1\/battles\/([^/]+)$/.exec(path);
    if(battle)return {data:await readBattle(db,uuid(battle[1]),owner)};
  }
  if(method==='POST') {
    const change=/^\/v1\/fighters\/([^/]+)\/(allocate|ai|upgrade-move|perk|respec)$/.exec(path);
    if(!change&&!['/v1/fighters','/v1/battles','/v1/story/battles','/v1/arena/offline-results/ack'].includes(path))return null;
    const body=await readBody(request);
    // Retain the old local development creation contract for existing tools.
    const legacy=path==='/v1/fighters'&&env.AUTH_MODE==='local_dev'&&!request.headers.has('Idempotency-Key');
    const op=legacy?null:await operation(db,owner,request,path,body);
    if(!op?.previous)await limitMutation(db,owner);
    if(path==='/v1/fighters') {
      const created=await createFighter(db,owner,body,op);
      return {status:op?.previous?200:201,data:presentOnline(await readOnline(db,created.fighter_id,owner),true)};
    }
    if(path==='/v1/battles'||path==='/v1/story/battles')return {status:op.previous?200:201,data:await createBattle(db,owner,body,op,path==='/v1/story/battles')};
    if(path==='/v1/arena/offline-results/ack')return {data:await acknowledgeOffline(db,owner,body,op)};
    if(change)return {data:await changeBuild(db,owner,uuid(change[1]),change[2],body,op)};
  }
  if(method==='PATCH') {
    const match=/^\/v1\/fighters\/([^/]+)$/.exec(path);
    if(match&&(env.AUTH_MODE!=='local_dev'||request.headers.has('Idempotency-Key'))) {
      const body=await readBody(request),op=await operation(db,owner,request,path+':appearance',body);
      if(!op.previous)await limitMutation(db,owner);
      return {data:await patchFighter(db,owner,uuid(match[1]),body,op)};
    }
  }
  if(path.startsWith('/v1/battles/')&&method==='POST')throw new ApiError(409,'BATTLE_AUTOMATIC','El servidor resuelve el combate automático al aceptar el desafío; recupera el resultado guardado.');
  return null;
}
