import {ApiError} from './errors.js';
import {slots,catalogHash} from './catalog.js';
export const fighterSelect=`SELECT f.*, i.display_name, i.normalized_name, p.payload AS progression_payload,p.revision AS progression_revision, a.body_style_id,a.palette_id,a.aura_id,a.trail_id,a.victory_pose_id,a.intro_animation_id FROM fighters f JOIN fighter_identity i ON i.fighter_id=f.id JOIN fighter_appearance a ON a.fighter_id=f.id JOIN fighter_progression p ON p.fighter_id=f.id`;
export function present(row, includeOwner=false) {
  const data={fighter_id:row.id,archetype_id:row.archetype_id,revision:row.revision,identity:{display_name:row.display_name,normalized_name:row.normalized_name,created_at:row.created_at,updated_at:row.updated_at},appearance:Object.fromEntries(slots.map(s=>[s,row[s]])),progression:JSON.parse(row.progression_payload),progression_revision:row.progression_revision,catalog_hash:catalogHash};
  if(includeOwner) data.account_id=row.account_id;
  return data;
}
export async function readFighter(db,id,owner=null) {
  const row=await db.prepare(fighterSelect+' WHERE f.id=?'+(owner?' AND f.account_id=?':'')).bind(...(owner?[id,owner]:[id])).first();
  if(!row) throw new ApiError(404,'FIGHTER_NOT_FOUND','No se encontró ese luchador.');
  return row;
}
