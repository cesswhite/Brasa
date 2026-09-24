import {ApiError, invalid} from '../errors.js';
import {canonical, sha256} from '../crypto.js';
import {ONLINE} from './config.js';

export function uuid(value) {
  if (typeof value !== 'string' || !/^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/.test(value)) throw invalid('Identificador inválido.');
  return value;
}
export async function operation(db, owner, request, kind, body) {
  const key = uuid(request.headers.get('Idempotency-Key'));
  const hash = await sha256(canonical({kind, body}));
  const previous = await db.prepare('SELECT * FROM game_operations WHERE account_id=? AND idempotency_key=?').bind(owner, key).first();
  if (previous && (previous.kind !== kind || previous.request_hash !== hash)) throw new ApiError(409, 'IDEMPOTENCY_CONFLICT', 'Esta clave ya corresponde a otra operación.');
  return {owner, key, hash, kind, id: crypto.randomUUID(), previous, now: Date.now()};
}
export function insertOperation(db, op, resourceId, result, condition='1', values=[]) {
  return db.prepare(`INSERT INTO game_operations(account_id,idempotency_key,kind,request_hash,mutation_id,resource_id,result_json,created_at) SELECT ?,?,?,?,?,?,?,? WHERE ${condition} ON CONFLICT(account_id,idempotency_key) DO NOTHING`)
    .bind(op.owner, op.key, op.kind, op.hash, op.id, resourceId, result === null ? null : JSON.stringify(result), op.now, ...values);
}
export const operationGate = 'EXISTS(SELECT 1 FROM game_operations WHERE mutation_id=?)';
export async function reloadOperation(db, op) {
  const row = await db.prepare('SELECT * FROM game_operations WHERE account_id=? AND idempotency_key=?').bind(op.owner, op.key).first();
  if (!row) throw new ApiError(409, 'REVISION_CONFLICT', 'El luchador cambió. Recarga y vuelve a intentarlo.');
  if (row.kind !== op.kind || row.request_hash !== op.hash) throw new ApiError(409, 'IDEMPOTENCY_CONFLICT', 'Esta clave ya corresponde a otra operación.');
  return row;
}
export async function limitMutation(db, owner, now=Date.now()) {
  const window = Math.floor(now/60000);
  const row = await db.prepare('INSERT INTO game_rate_limits(account_id,window,count) VALUES(?,?,1) ON CONFLICT(account_id,window) DO UPDATE SET count=count+1 RETURNING count').bind(owner,window).first();
  if (row.count > ONLINE.maxMutationsPerMinute) throw new ApiError(429, 'RATE_LIMITED', 'Demasiadas solicitudes. Espera un minuto.');
  // A bounded per-account cleanup keeps this table from growing indefinitely.
  if (row.count === 1) await db.prepare('DELETE FROM game_rate_limits WHERE account_id=? AND window<?').bind(owner,window-2).run();
}
