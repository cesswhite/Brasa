import {readFighter,present} from './fighters.js';
import {catalogHash} from './catalog.js';
import {canonical,sha256} from './crypto.js';
import {ApiError,objectKeys,invalid} from './errors.js';
// Trusted server integration ONLY. Not exported from the HTTP entrypoint.
// The caller supplies record IDs, never a client-provided fighter or result.
export async function captureFighterSnapshot(db,options) {
  objectKeys(options,['fighter_id','kind','reference_id']);
  if(!['battle_participant','opponent_listing'].includes(options.kind)||typeof options.reference_id!=='string'||!options.reference_id.length||options.reference_id.length>160) throw invalid('Referencia de snapshot inválida.');
  const existing=await db.prepare('SELECT * FROM fighter_snapshots WHERE fighter_id=? AND kind=? AND reference_id=?').bind(options.fighter_id,options.kind,options.reference_id).first();
  if(existing) return decode(existing);
  const row=await readFighter(db,options.fighter_id);
  const payload=canonical(present(row));
  const hash=await sha256(payload), id=crypto.randomUUID();
  await db.prepare('INSERT INTO fighter_snapshots(id,fighter_id,owner_account_id,kind,reference_id,source_revision,progression_revision,catalog_hash,payload,sha256,created_at) VALUES (?,?,?,?,?,?,?,?,?,?,?) ON CONFLICT(fighter_id,kind,reference_id) DO NOTHING').bind(id,row.id,row.account_id,options.kind,options.reference_id,row.revision,row.progression_revision,catalogHash,payload,hash,new Date().toISOString()).run();
  return decode(await db.prepare('SELECT * FROM fighter_snapshots WHERE fighter_id=? AND kind=? AND reference_id=?').bind(options.fighter_id,options.kind,options.reference_id).first());
}
function decode(row) {return {snapshot_id:row.id,kind:row.kind,reference_id:row.reference_id,source_revision:row.source_revision,sha256:row.sha256,created_at:row.created_at,fighter:JSON.parse(row.payload)};}
// Historical reads are owner-scoped. A future battle service must independently
// authorize its participants before exposing somebody else's snapshot.
export async function readOwnedSnapshot(db,id,account) {
  const row=await db.prepare('SELECT * FROM fighter_snapshots WHERE id=? AND owner_account_id=?').bind(id,account).first();
  if(!row) throw new ApiError(404,'SNAPSHOT_NOT_FOUND','No se encontró esa ficha histórica.');
  if(await sha256(row.payload)!==row.sha256) throw new ApiError(500,'SNAPSHOT_INTEGRITY','La ficha histórica no supera la comprobación de integridad.');
  return decode(row);
}
