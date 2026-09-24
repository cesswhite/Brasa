import {ApiError, invalid, objectKeys} from '../errors.js';
import {fighterSelect, present, readFighter} from '../fighter-records.js';
import {buildCombatant, statsForProfile, getUnlockedMoves, getPerks, getStatOptions, pointsForLevel, xpForLevel, AI_STYLES} from '../../battle-engine/index.js';
import {insertOperation, operationGate, reloadOperation} from './operations.js';

export const initialProgression = () => ({level:1,xp:0,stat_points:3,move_points:0,perk_points:0,total_xp:0,cap_xp:0,allocations:{},move_upgrades:{},perks:[]});
export const onlineSelect = fighterSelect.replace('SELECT f.*,','SELECT f.*, a.is_test,ar.rating,ar.wins,ar.losses,ar.draws,ar.story_cleared,ar.story_attempts,ar.ai_style,ar.power,ar.next_challenge_at,')+' JOIN fighter_arena ar ON ar.fighter_id=f.id JOIN accounts a ON a.id=f.account_id';
export function progressionOf(row) { return {...initialProgression(), ...JSON.parse(row.progression_payload)}; }
export function combatantOf(row) {
  const dto=present(row), profile=progressionOf(row);
  return buildCombatant({fighter_id:row.id,character_id:row.archetype_id,...profile,identity:dto.identity,appearance:dto.appearance,ai_config:{style:row.ai_style||'balanced'}});
}
export function estimatePower(row) {
  const fighter=combatantOf(row), s=fighter.combat_stats;
  const accuracy=Math.max(.62,Math.min(.96,s.accuracy-.1));
  const durability=s.max_hp*(1+s.defense/100)/Math.max(.65,1-s.evasion);
  const base=Math.sqrt(Math.max(1,durability*s.attack*(1+s.crit_chance*(s.crit_damage-1))*accuracy/Math.max(.5,s.interval)));
  const p=progressionOf(row), tiers=Object.values(p.move_upgrades).reduce((n,v)=>n+v,0);
  return base*(1+.015*tiers+.025*p.perks.length+.01*Math.max(0,fighter.moves.length-1));
}
export function presentOnline(row, owner=false) {
  const dto=present(row,owner); dto.progression=progressionOf(row);
  dto.progression.xp_required=xpForLevel(dto.progression.level);
  dto.progression.unlocked_moves=getUnlockedMoves(row.archetype_id,dto.progression.level);
  dto.online={rating:row.rating,wins:row.wins,losses:row.losses,draws:row.draws,story_cleared:row.story_cleared,ai_style:row.ai_style,power:row.power||estimatePower(row),next_challenge_at:row.next_challenge_at};
  dto.combatant=combatantOf(row);
  return dto;
}
export async function readOnline(db,id,owner=null) {
  const row=await db.prepare(onlineSelect+' WHERE f.id=?'+(owner?' AND f.account_id=?':'')).bind(...(owner?[id,owner]:[id])).first();
  if(!row) throw new ApiError(404,'FIGHTER_NOT_FOUND','No se encontró ese luchador.');
  return row;
}
export async function listOnline(db,owner) {
  const rows=(await db.prepare(onlineSelect+' WHERE f.account_id=? ORDER BY f.created_at,f.id').bind(owner).all()).results;
  return rows.map(row=>presentOnline(row,true));
}
export async function repairMissingPower(db,limit=32) {
  const rows=(await db.prepare(onlineSelect+' WHERE ar.power=0 ORDER BY f.id LIMIT ?').bind(limit).all()).results;
  if(rows.length)await db.batch(rows.map(row=>db.prepare('UPDATE fighter_arena SET power=? WHERE fighter_id=? AND power=0 AND EXISTS(SELECT 1 FROM fighter_progression WHERE fighter_id=? AND revision=?)').bind(estimatePower(row),row.id,row.id,row.progression_revision)));
  return rows.length;
}
export function grantXp(row,amount) {
  if(!Number.isSafeInteger(amount)||amount<0) throw new Error('Invalid authoritative XP');
  const p=progressionOf(row),before=p.level,oldMoves=getUnlockedMoves(row.archetype_id,p.level).map(m=>m.id);
  p.total_xp+=amount; p.xp+=amount; let points=0;
  while(p.level<50 && p.xp>=xpForLevel(p.level)) {p.xp-=xpForLevel(p.level);p.level++;const grant=pointsForLevel(p.level);points+=grant;p.stat_points+=grant;}
  if(p.level===50) {p.cap_xp+=p.xp;p.xp=0;}
  row.progression_payload=JSON.stringify(p);
  return {xp_gained:amount,level_before:before,level_after:p.level,levels_gained:p.level-before,points_gained:points,moves_unlocked:getUnlockedMoves(row.archetype_id,p.level).filter(m=>!oldMoves.includes(m.id)),rating_delta:0};
}
function validRevision(body,row) {
  if(!Number.isSafeInteger(body.expected_revision)||body.expected_revision!==row.progression_revision) throw new ApiError(409,'REVISION_CONFLICT','El progreso cambió. Recarga su ficha.');
}
export async function changeBuild(db,owner,id,kind,body,op) {
  if(op.previous) return JSON.parse(op.previous.result_json);
  const row=await readOnline(db,id,owner),p=progressionOf(row);
  validRevision(body,row);
  if(kind==='allocate') {
    objectKeys(body,['expected_revision','stat','amount']);
    if(!getStatOptions().some(s=>s.key===body.stat)||!Number.isSafeInteger(body.amount)||body.amount<1||body.amount>30||p.stat_points<body.amount) throw invalid('No hay puntos suficientes o el atributo no es válido.');
    const previous=p.allocations[body.stat]||0;
    if(previous+body.amount>30) throw invalid('Ese atributo ya alcanzó su límite de inversión.');
    let before=statsForProfile({character_id:row.archetype_id,...p});
    for(let step=1;step<=body.amount;step++) {
      p.allocations[body.stat]=previous+step;
      const after=statsForProfile({character_id:row.archetype_id,...p});
      if(after[body.stat]<=before[body.stat]+1e-7) throw invalid('Parte de esa inversión excede el máximo del atributo.');
      before=after;
    }
    p.stat_points-=body.amount;
  } else if(kind==='ai') {
    objectKeys(body,['expected_revision','style']);
    const ids=Array.isArray(AI_STYLES)?AI_STYLES.map(s=>typeof s==='string'?s:s.id):Object.keys(AI_STYLES);
    if(!ids.includes(body.style)) throw invalid('Estrategia no válida.');
    row.ai_style=body.style;
  } else if(kind==='upgrade-move') {
    objectKeys(body,['expected_revision','move_id']);
    if(!getUnlockedMoves(row.archetype_id,p.level).some(m=>m.id===body.move_id)||p.move_points<1||(p.move_upgrades[body.move_id]||0)>=2) throw invalid('No puedes mejorar esa técnica.');
    p.move_upgrades[body.move_id]=(p.move_upgrades[body.move_id]||0)+1;p.move_points--;
  } else if(kind==='perk') {
    objectKeys(body,['expected_revision','perk_id']);
    if(!getPerks(row.archetype_id).some(v=>v.id===body.perk_id)||p.perk_points<1||p.perks.length>=3||p.perks.includes(body.perk_id)) throw invalid('No puedes elegir ese talento.');
    p.perks.push(body.perk_id);p.perk_points--;
  } else if(kind==='respec') {
    objectKeys(body,['expected_revision']);
    p.stat_points+=Object.values(p.allocations).reduce((a,b)=>a+b,0);p.allocations={};
    p.move_points+=Object.values(p.move_upgrades).reduce((a,b)=>a+b,0);p.move_upgrades={};
    p.perk_points+=p.perks.length;p.perks=[];
  } else throw invalid('Operación no disponible.');
  row.progression_payload=JSON.stringify(p); row.progression_revision++;row.power=estimatePower(row);
  const response={fighter:presentOnline(row,true)};
  await db.batch([
    insertOperation(db,op,id,response,'EXISTS(SELECT 1 FROM fighter_progression WHERE fighter_id=? AND revision=?)',[id,body.expected_revision]),
    db.prepare(`UPDATE fighter_progression SET payload=?,revision=revision+1 WHERE fighter_id=? AND ${operationGate}`).bind(row.progression_payload,id,op.id),
    db.prepare(`UPDATE fighter_arena SET ai_style=?,power=?,updated_at=? WHERE fighter_id=? AND ${operationGate}`).bind(row.ai_style,row.power,op.now,id,op.id),
  ]);
  return JSON.parse((await reloadOperation(db,op)).result_json);
}
