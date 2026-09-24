import {ApiError,invalid,objectKeys} from '../errors.js';
import {gameCatalog,AI_STYLES,getStoryStage,ENGINE_VERSION,CATALOG_VERSION} from '../../battle-engine/index.js';
import {ONLINE} from './config.js';
import {readOnline,onlineSelect,presentOnline,estimatePower,repairMissingPower} from './profiles.js';
import {uuid,insertOperation,operationGate,reloadOperation} from './operations.js';

export function publicGameCatalog() {
  return {engine_version:ENGINE_VERSION,catalog_version:CATALOG_VERSION,
    characters:gameCatalog.character_ids.map(id=>gameCatalog.characters[id]),
    stat_options:gameCatalog.campaign.allocations,
    ai_styles:Object.keys(AI_STYLES),moves:gameCatalog.moves,perks:gameCatalog.perks,
    story_stages:gameCatalog.campaign.stages.map(({opponent,...stage})=>stage),chapters:gameCatalog.campaign.chapters,
    policy:{shared_online_progression:true,local_save_import:false,battle_control:'automatic',initial_stat_points:3},
  };
}
export async function opponents(db,owner,id) {
  await repairMissingPower(db);
  const player=await readOnline(db,uuid(id),owner),power=estimatePower(player);
  const batches=await db.batch([
    db.prepare(onlineSelect+' WHERE ar.power BETWEEN ? AND ? AND f.account_id!=? AND a.is_test=? ORDER BY ar.power DESC,f.id LIMIT ?').bind(power*ONLINE.matchmakingMinRatio,power,owner,player.is_test,ONLINE.opponentCandidates/2),
    db.prepare(onlineSelect+' WHERE ar.power BETWEEN ? AND ? AND f.account_id!=? AND a.is_test=? ORDER BY ar.power,f.id LIMIT ?').bind(power,power*ONLINE.matchmakingMaxRatio,owner,player.is_test,ONLINE.opponentCandidates/2),
  ]);
  const rows=[...new Map(batches.flatMap(b=>b.results).map(r=>[r.id,r])).values()];
  const ranked=rows.map(row=>({row,distance:Math.abs(Math.log(estimatePower(row)/power))+.2*Math.min(2,Math.abs(row.rating-player.rating)/400)})).sort((a,b)=>a.distance-b.distance||a.row.id.localeCompare(b.row.id));
  return {fighter_id:id,opponents:ranked.slice(0,ONLINE.opponentChoices).map(({row})=>({...presentOnline(row),power:estimatePower(row),difficulty:estimatePower(row)<power*.9?'easier':estimatePower(row)>power*1.1?'harder':'similar'})),empty_reason:rows.length?'':'Todavía no hay luchadores de otras cuentas con una fuerza cercana. Comparte la Arena para encontrar rivales.'};
}
export async function story(db,owner,id) {
  const row=await readOnline(db,uuid(id),owner),complete=row.story_cleared>=100;
  const stage=complete?null:getStoryStage(row.story_cleared+1);
  return {fighter_id:id,cleared:row.story_cleared,complete,next_stage:stage?{...stage,opponent:undefined,opponent_name:stage.opponent?.name,appearance:stage.opponent?.appearance,individual_id:stage.opponent?.individual_id,species_id:stage.opponent?.species_id,description:stage.profile||stage.strength}:null,chapters:gameCatalog.campaign.chapters};
}
export async function history(db,owner,query) {
  const id=query.get('fighter_id');if(id)await readOnline(db,uuid(id),owner);
  let cursorTime=Number.MAX_SAFE_INTEGER,cursorId='ffffffff-ffff-ffff-ffff-ffffffffffff';
  if(query.has('cursor')) {
    const parts=query.get('cursor').split(':');
    if(parts.length!==2||!/^\d+$/.test(parts[0]))throw invalid('Cursor inválido.');
    cursorTime=Number(parts[0]);cursorId=uuid(parts[1]);
    if(!Number.isSafeInteger(cursorTime))throw invalid('Cursor inválido.');
  }
  const rows=(await db.prepare('SELECT id,mode,challenger_account_id,created_at,summary_json FROM online_battles WHERE (challenger_account_id=? OR defender_account_id=?)'+(id?' AND (player_id=? OR rival_id=?)':'')+' AND (created_at<? OR (created_at=? AND id<?)) ORDER BY created_at DESC,id DESC LIMIT ?').bind(owner,owner,...(id?[id,id]:[]),cursorTime,cursorTime,cursorId,ONLINE.pageSize+1).all()).results;
  const more=rows.length>ONLINE.pageSize,page=rows.slice(0,ONLINE.pageSize),last=page.at(-1);
  return {battles:page.map(row=>({id:row.id,...JSON.parse(row.summary_json),viewing_side:owner===row.challenger_account_id?'player':'rival'})),next_cursor:more?last.created_at+':'+last.id:null};
}
export async function offlineResults(db,owner) {
  const results=await db.batch([
    db.prepare('SELECT id,fighter_id,created_at,summary_json FROM offline_activity WHERE account_id=? AND acknowledged_at IS NULL ORDER BY created_at DESC,id DESC LIMIT 20').bind(owner),
    db.prepare("SELECT COUNT(*) battles,COALESCE(SUM(json_extract(summary_json,'$.won')),0) wins,COALESCE(SUM(json_extract(summary_json,'$.xp_gained')),0) xp,COALESCE(SUM(json_extract(summary_json,'$.rating_delta')),0) rating_change FROM offline_activity WHERE account_id=? AND acknowledged_at IS NULL").bind(owner),
  ]);
  const totals=results[1].results[0];totals.losses=totals.battles-totals.wins;
  return {results:results[0].results.map(row=>({id:row.id,fighter_id:row.fighter_id,created_at:row.created_at,...JSON.parse(row.summary_json)})),totals};
}
export async function acknowledgeOffline(db,owner,body,op) {
  if(op.previous)return JSON.parse(op.previous.result_json);
  objectKeys(body,['ids']);
  if(!Array.isArray(body.ids)||body.ids.length<1||body.ids.length>50||new Set(body.ids).size!==body.ids.length)throw invalid('Selecciona entre 1 y 50 resultados diferentes.');
  body.ids.forEach(uuid);const marks=body.ids.map(()=>'?').join(',');
  const count=await db.prepare(`SELECT COUNT(*) n FROM offline_activity WHERE account_id=? AND id IN (${marks})`).bind(owner,...body.ids).first();
  if(count.n!==body.ids.length)throw new ApiError(404,'ACTIVITY_NOT_FOUND','No se encontraron esos resultados.');
  await db.batch([
    insertOperation(db,op,null,{acknowledged:body.ids.length}),
    db.prepare(`UPDATE offline_activity SET acknowledged_at=COALESCE(acknowledged_at,?) WHERE account_id=? AND id IN (${marks}) AND ${operationGate}`).bind(op.now,owner,...body.ids,op.id),
  ]);
  return JSON.parse((await reloadOperation(db,op)).result_json);
}
