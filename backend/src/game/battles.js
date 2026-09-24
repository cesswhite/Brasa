import {ApiError,invalid,objectKeys} from '../errors.js';
import {catalogHash} from '../catalog.js';
import {simulateBattle,getStoryStage,getStoryOpponent,ENGINE_VERSION,CATALOG_VERSION} from '../../battle-engine/index.js';
import {ONLINE,dayStart} from './config.js';
import {readOnline,combatantOf,presentOnline,estimatePower} from './profiles.js';
import {arenaRewards,storyReward,earnedCosmetics} from './rewards.js';
import {uuid,insertOperation,operationGate,reloadOperation} from './operations.js';

function serverSeed() {
  const words=crypto.getRandomValues(new Uint32Array(2));
  return ((BigInt(words[0])<<32n)|BigInt(words[1])||1n).toString();
}
async function rewardCounts(db,owner,defender,now) {
  const start=dayStart(now);
  const rows=await db.batch([
    db.prepare('SELECT COUNT(*) AS n FROM online_battles WHERE mode=\'arena\' AND created_at>=? AND ((challenger_account_id=? AND defender_account_id=?) OR (challenger_account_id=? AND defender_account_id=?))').bind(start,owner,defender,defender,owner),
    db.prepare('SELECT COUNT(*) AS n,COALESCE(SUM(xp),0) AS xp FROM progression_events WHERE account_id=? AND side=\'rival\' AND created_at>=?').bind(defender,start),
    db.prepare('SELECT COALESCE(SUM(e.xp),0) AS xp FROM progression_events e JOIN online_battles b ON b.id=e.battle_id WHERE e.account_id=? AND e.side=\'player\' AND e.created_at>=? AND b.mode=\'arena\'').bind(owner,start),
  ]);
  return {pair:rows[0].results[0].n,defenses:rows[1].results[0].n,defensiveXp:rows[1].results[0].xp,activeXp:rows[2].results[0].xp};
}
export async function readBattle(db,id,owner) {
  const row=await db.prepare('SELECT * FROM online_battles WHERE id=? AND (challenger_account_id=? OR defender_account_id=?)').bind(id,owner,owner).first();
  if(!row) throw new ApiError(404,'BATTLE_NOT_FOUND','No se encontró ese combate.');
  const snapshot=JSON.parse(row.snapshot_json), events=JSON.parse(row.events_json), result=JSON.parse(row.result_json),record=JSON.parse(row.summary_json);
  record.battle_snapshot={version:1,battle_id:id,seed:row.seed,...snapshot,events,duration:result.duration,winner:result.winner,reason:result.reason,engine_version:row.engine_version,catalog_version:row.catalog_version};
  const ownFighter=owner===row.challenger_account_id?row.player_id:row.rival_id;
  return {battle:{id,mode:row.mode,story_level:row.story_level,created_at:row.created_at,record,rewards:result.rewards,viewing_side:owner===row.challenger_account_id?'player':'rival'},fighter:presentOnline(await readOnline(db,ownFighter,owner),true)};
}
function progressionStatements(db,row,reward,battleId,op,side) {
  const statements=[
    db.prepare(`UPDATE fighter_progression SET payload=?,revision=revision+1 WHERE fighter_id=? AND ${operationGate}`).bind(row.progression_payload,row.id,op.id),
    db.prepare(`UPDATE fighter_arena SET rating=?,wins=?,losses=?,draws=?,story_cleared=?,story_attempts=?,power=?,next_challenge_at=?,updated_at=? WHERE fighter_id=? AND ${operationGate}`).bind(row.rating,row.wins,row.losses,row.draws,row.story_cleared,row.story_attempts,estimatePower(row),row.next_challenge_at,op.now,row.id,op.id),
    db.prepare(`INSERT INTO progression_events(id,battle_id,fighter_id,account_id,side,xp,rating_delta,level_before,level_after,created_at) SELECT ?,?,?,?,?,?,?,?,?,? WHERE ${operationGate}`).bind(crypto.randomUUID(),battleId,row.id,row.account_id,side,reward.xp_gained,reward.rating_delta||0,reward.level_before,reward.level_after,op.now,op.id),
  ];
  for(const cosmetic of earnedCosmetics(row)) statements.push(db.prepare(`INSERT OR IGNORE INTO owned_cosmetics(account_id,inventory_id,source,granted_at) SELECT ?,?,'server_achievement',? WHERE ${operationGate}`).bind(row.account_id,cosmetic,new Date(op.now).toISOString(),op.id));
  return statements;
}
export async function createBattle(db,owner,body,op,story=false) {
  if(op.previous) return readBattle(db,op.previous.resource_id,owner);
  objectKeys(body,story?['fighter_id','story_level']:['fighter_id','opponent_id']);
  uuid(body.fighter_id); if(!story) uuid(body.opponent_id);
  // Retrying a CAS race recomputes from fresh DB records, never from client stats.
  for(let attempt=0;attempt<3;attempt++) {
    const player=await readOnline(db,body.fighter_id,owner), playerVersion=player.progression_revision;
    let rival,stage=null,mode='arena';
    if(player.next_challenge_at>op.now) throw new ApiError(429,'CHALLENGE_COOLDOWN','Espera unos segundos antes del siguiente combate.');
    if(story) {
      const stageLevel=body.story_level===undefined?player.story_cleared+1:body.story_level;
      if(!Number.isSafeInteger(stageLevel)||stageLevel<1||stageLevel>100||stageLevel>player.story_cleared+1) throw invalid('Este encuentro de Historia aún no está disponible.');
      stage=getStoryStage(stageLevel);mode=stageLevel<=player.story_cleared?'practice':'story';
    } else {
      rival=await readOnline(db,body.opponent_id);
      if(rival.is_test!==player.is_test) throw new ApiError(404,'FIGHTER_NOT_FOUND','No se encontró ese luchador.');
      if(rival.account_id===owner) throw invalid('Elige un luchador de otra cuenta.');
      const ratio=estimatePower(rival)/estimatePower(player);
      if(ratio<ONLINE.matchmakingMinRatio||ratio>ONLINE.matchmakingMaxRatio) throw new ApiError(422,'OPPONENT_OUT_OF_RANGE','Las fuerzas de esos luchadores están demasiado alejadas.');
    }
    const rivalVersion=rival?.progression_revision;
    const pDescriptor=combatantOf(player),rDescriptor=story?getStoryOpponent(stage.global_level):combatantOf(rival);
    const seed=serverSeed(), battleId=crypto.randomUUID();
    const simulation=simulateBattle(pDescriptor,rDescriptor,seed,{battle_id:battleId});
    if(!['player','rival'].includes(simulation.winner)||!Number.isFinite(simulation.duration)||simulation.events.length>10000) throw new Error('Invalid authoritative battle result');
    const counts=story?null:await rewardCounts(db,owner,rival.account_id,op.now);
    const rewards=story?storyReward(player,stage,simulation,mode==='practice'):arenaRewards(player,rival,simulation,counts);
    player.next_challenge_at=op.now+ONLINE.challengeCooldownMs;
    const snapshot={player:simulation.player,rival:simulation.rival,cosmetic_catalog_hash:catalogHash};
    const events=simulation.events.map((event,event_seq)=>({...event,event_seq}));
    const summary={battle_id:battleId,timestamp:Math.floor(op.now/1000),mode,story_level:stage?.global_level||null,player_name:pDescriptor.name,rival_name:rDescriptor.name,player_fighter_id:player.id,rival_fighter_id:rival?.id||'story:'+stage?.id,winner:simulation.winner,winner_name:simulation.winner==='player'?pDescriptor.name:rDescriptor.name,reason:simulation.reason,duration:simulation.duration,turns:simulation.turns,player_xp:rewards.player.xp_gained,rival_xp:rewards.rival.xp_gained,player:rewards.player,rival:rewards.rival};
    const result={winner:simulation.winner,reason:simulation.reason,duration:simulation.duration,rewards};
    const conditions=['EXISTS(SELECT 1 FROM fighter_progression WHERE fighter_id=? AND revision=?)'];
    const values=[player.id,playerVersion];
    if(rival) {conditions.push('EXISTS(SELECT 1 FROM fighter_progression WHERE fighter_id=? AND revision=?)');values.push(rival.id,rivalVersion);}
    // Counts are account-scoped: guard them too, so simultaneous defenses against
    // different fighters cannot each spend the same daily XP/rating allowance.
    if(rival) {
      conditions.push('(SELECT COUNT(*) FROM progression_events WHERE account_id=? AND side=\'rival\' AND created_at>=?)=?');values.push(rival.account_id,dayStart(op.now),counts.defenses);
      conditions.push('(SELECT COALESCE(SUM(e.xp),0) FROM progression_events e JOIN online_battles b ON b.id=e.battle_id WHERE e.account_id=? AND e.side=\'player\' AND e.created_at>=? AND b.mode=\'arena\')=?');values.push(owner,dayStart(op.now),counts.activeXp);
      conditions.push('(SELECT COUNT(*) FROM online_battles WHERE mode=\'arena\' AND created_at>=? AND ((challenger_account_id=? AND defender_account_id=?) OR (challenger_account_id=? AND defender_account_id=?)))=?');values.push(dayStart(op.now),owner,rival.account_id,rival.account_id,owner,counts.pair);
    }
    const statements=[
      insertOperation(db,op,battleId,null,conditions.join(' AND '),values),
      db.prepare(`INSERT INTO online_battles(id,operation_id,mode,challenger_account_id,defender_account_id,player_id,rival_id,story_level,seed,engine_version,catalog_version,snapshot_json,events_json,result_json,summary_json,created_at) SELECT ${Array(16).fill('?').join(',')} WHERE ${operationGate}`).bind(battleId,op.id,mode,owner,rival?.account_id||null,player.id,rival?.id||null,stage?.global_level||null,seed,ENGINE_VERSION,CATALOG_VERSION,JSON.stringify(snapshot),JSON.stringify(events),JSON.stringify(result),JSON.stringify(summary),op.now,op.id),
      ...progressionStatements(db,player,rewards.player,battleId,op,'player'),
    ];
    if(rival) {
      statements.push(...progressionStatements(db,rival,rewards.rival,battleId,op,'rival'));
      const notice={battle_id:battleId,challenger_name:pDescriptor.name,fighter_name:rDescriptor.name,won:simulation.winner==='rival',...rewards.rival};
      statements.push(db.prepare(`INSERT INTO offline_activity(id,account_id,fighter_id,battle_id,summary_json,created_at) SELECT ?,?,?,?,?,? WHERE ${operationGate}`).bind(crypto.randomUUID(),rival.account_id,rival.id,battleId,JSON.stringify(notice),op.now,op.id));
    }
    await db.batch(statements);
    const receipt=await db.prepare('SELECT * FROM game_operations WHERE account_id=? AND idempotency_key=?').bind(owner,op.key).first();
    if(receipt) {
      await reloadOperation(db,op); // Validate hash even for a concurrent retry.
      return readBattle(db,receipt.resource_id,owner);
    }
  }
  throw new ApiError(409,'FIGHTER_BUSY','El luchador está recibiendo otro resultado. Vuelve a intentar la misma solicitud.');
}
