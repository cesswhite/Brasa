import {ApiError,invalid,objectKeys} from './errors.js';
import {slots,archetypes,defaultAppearance,validateAppearance,validateName,catalogHash} from './catalog.js';
import {initialProgression,estimatePower,readOnline,presentOnline,onlineSelect} from './game/profiles.js';
import {insertOperation,operationGate,reloadOperation} from './game/operations.js';
import {fighterSelect,present,readFighter} from './fighter-records.js';
export {fighterSelect,present,readFighter} from './fighter-records.js';
export async function listFighters(db,owner) {
  return (await db.prepare(fighterSelect+' WHERE f.account_id=? ORDER BY f.created_at,f.id').bind(owner).all()).results.map(r=>present(r,true));
}
export async function createFighter(db,owner,body,op=null) {
  if(op?.previous) return present(await readFighter(db,op.previous.resource_id,owner),true);
  objectKeys(body,['archetype_id','display_name']);
  if(!archetypes.includes(body.archetype_id)) throw invalid('El arquetipo no existe.');
  const identity=validateName(body.display_name), appearance=defaultAppearance(body.archetype_id);
  await validateAppearance(db,owner,body.archetype_id,appearance);
  const id=crypto.randomUUID(),now=new Date().toISOString();
  const progression=initialProgression();
  const power=estimatePower({id,archetype_id:body.archetype_id,progression_payload:JSON.stringify(progression),display_name:identity.display_name,normalized_name:identity.normalized_name,created_at:now,updated_at:now,...appearance});
  try {
    const gate=op?` AND ${operationGate}`:'';
    const gateValues=op?[op.id]:[];
    const result=await db.batch([
      ...(op?[insertOperation(db,op,id,null)]:[]),
      db.prepare('INSERT INTO fighters (id,account_id,archetype_id,last_mutation,created_at,updated_at) SELECT ?,?,?,?,?,? WHERE 1'+gate).bind(id,owner,body.archetype_id,crypto.randomUUID(),now,now,...gateValues),
      db.prepare('INSERT INTO fighter_identity SELECT ?,?,? WHERE 1'+gate).bind(id,identity.display_name,identity.normalized_name,...gateValues),
      db.prepare('INSERT INTO fighter_progression(fighter_id,payload) SELECT ?,? WHERE 1'+gate).bind(id,JSON.stringify(progression),...gateValues),
      db.prepare(`INSERT INTO fighter_appearance(fighter_id,${slots.join(',')}) SELECT ${Array(slots.length+1).fill('?').join(',')} WHERE 1`+gate).bind(id,...slots.map(s=>appearance[s]),...gateValues),
      db.prepare('INSERT INTO fighter_arena(fighter_id,power,updated_at) SELECT ?,?,? WHERE 1'+gate).bind(id,power,Date.now(),...gateValues),
      db.prepare(fighterSelect+' WHERE f.id=?').bind(id)
    ]);
    if(op) return present(await readFighter(db,(await reloadOperation(db,op)).resource_id,owner),true);
    return present(result.at(-1).results[0],true);
  } catch(error) {
    if(String(error).includes('fighters.account_id, fighters.archetype_id')) throw new ApiError(409,'FIGHTER_EXISTS','Ya existe un luchador de ese arquetipo en la cuenta.');
    throw error;
  }
}
export async function patchFighter(db,owner,id,body,op=null) {
  if(op?.previous)return JSON.parse(op.previous.result_json);
  objectKeys(body,['expected_revision','display_name','appearance']);
  if(!Number.isSafeInteger(body.expected_revision)||body.expected_revision<1) throw invalid('Indica expected_revision.');
  if(body.display_name===undefined && body.appearance===undefined) throw invalid('No hay cambios para guardar.');
  const before=await readOnline(db,id,owner);
  if(before.revision!==body.expected_revision) throw new ApiError(409,'REVISION_CONFLICT','El luchador cambió. Recarga su ficha.');
  const identity=body.display_name===undefined?{display_name:before.display_name,normalized_name:before.normalized_name}:validateName(body.display_name);
  if(body.appearance!==undefined) objectKeys(body.appearance,slots);
  const appearance={...Object.fromEntries(slots.map(s=>[s,before[s]])),...body.appearance};
  await validateAppearance(db,owner,before.archetype_id,appearance);
  const mutation=crypto.randomUUID(),now=new Date().toISOString();
  const response=presentOnline({...before,...identity,...appearance,revision:before.revision+1,updated_at:now},true);
  // Every dependent write is gated by this unique mutation ID inside one D1
  // transaction. A losing optimistic write cannot touch identity or equipment.
  const gate='EXISTS(SELECT 1 FROM fighters WHERE id=? AND last_mutation=?)';
  const results=await db.batch([
    ...(op?[insertOperation(db,op,id,response,'EXISTS(SELECT 1 FROM fighters WHERE id=? AND account_id=? AND revision=?)',[id,owner,body.expected_revision])]:[]),
    db.prepare('UPDATE fighters SET revision=revision+1,last_mutation=?,updated_at=? WHERE id=? AND account_id=? AND revision=?'+(op?` AND ${operationGate}`:'')).bind(mutation,now,id,owner,body.expected_revision,...(op?[op.id]:[])),
    db.prepare(`UPDATE fighter_identity SET display_name=?,normalized_name=? WHERE fighter_id=? AND ${gate}`).bind(identity.display_name,identity.normalized_name,id,id,mutation),
    db.prepare(`UPDATE fighter_appearance SET ${slots.map(s=>s+'=?').join(',')} WHERE fighter_id=? AND ${gate}`).bind(...slots.map(s=>appearance[s]),id,id,mutation),
    db.prepare(onlineSelect+' WHERE f.id=?').bind(id)
  ]);
  if(op)return JSON.parse((await reloadOperation(db,op)).result_json);
  if(results[0].meta.changes!==1) throw new ApiError(409,'REVISION_CONFLICT','El luchador cambió. Recarga su ficha.');
  return presentOnline(results.at(-1).results[0],true);
}
