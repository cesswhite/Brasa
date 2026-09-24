import catalog from '../generated/cosmetic_catalog.json' with {type:'json'};
import metadata from '../generated/catalog_meta.json' with {type:'json'};
import {ApiError, invalid, objectKeys} from './errors.js';
export {catalog};
export const catalogHash=metadata.sha256;
export const slots=catalog.slots.map(s=>s.id);
export const archetypes=catalog.archetype_ids || catalog.items.filter(i=>i.slot==='body_style_id' && !i.species_id).map(i=>i.id);
export function defaultAppearance(archetype) {
  return {...catalog.presets.find(p=>p.id==='original').appearance,body_style_id:archetype};
}
export function validateName(input) {
  if (typeof input!=='string' || /[\p{C}\u2028\u2029]/u.test(input)) throw new ApiError(422,'INVALID_NAME','El nombre contiene caracteres no admitidos.');
  const name=input.replace(/^ +| +$/g,'').replace(/ +/g,' ');
  if ([...name].length<catalog.name_policy.minimum_length || [...name].length>catalog.name_policy.maximum_length || !new RegExp(catalog.name_policy.allowed_pattern,'u').test(name) || !new RegExp(catalog.name_policy.required_pattern,'u').test(name))
    throw new ApiError(422,'INVALID_NAME','Usa entre 2 y 24 letras, números, espacios, apóstrofos o guiones.');
  const normalized=name.toLowerCase();
  const blocked=catalog.name_policy.reserved_names || catalog.name_policy.reserved || ['admin','sistema','moderador'];
  if (blocked.includes(normalized)) throw new ApiError(422,'RESERVED_NAME','Ese nombre está reservado.');
  return {display_name:name, normalized_name:normalized};
}
export async function validateAppearance(db, account, archetype, appearance) {
  objectKeys(appearance,slots);
  const wanted=[];
  for(const slot of slots) {
    const value=appearance[slot];
    const item=catalog.items.find(i=>i.slot===slot && i.id===value);
    if(!item) throw new ApiError(422,'UNKNOWN_COSMETIC','El cosmético no existe en esa categoría.');
    if(!(item.compatible_body_styles||['*']).some(i=>i==='*'||i===appearance.body_style_id) || !(item.compatible_archetypes||['*']).some(i=>i==='*'||i===archetype))
      throw new ApiError(422,'INCOMPATIBLE_COSMETIC','El cosmético no es compatible con ese cuerpo o arquetipo.');
    wanted.push(item.inventory_id);
  }
  const owned=(await db.prepare('SELECT inventory_id FROM owned_cosmetics WHERE account_id=?').bind(account).all()).results.map(i=>i.inventory_id);
  if(wanted.some(i=>!owned.includes(i))) throw new ApiError(403,'COSMETIC_NOT_OWNED','La cuenta no posee ese cosmético.');
}
export async function assertCatalog(db) {
  const row=await db.prepare('SELECT hash FROM catalog_versions WHERE hash=?').bind(catalogHash).first();
  const mismatch=await db.prepare('SELECT COUNT(*) AS n FROM cosmetic_definitions WHERE catalog_hash!=?').bind(catalogHash).first();
  const count=await db.prepare('SELECT COUNT(*) AS n FROM cosmetic_definitions').first();
  if(!row || mismatch.n || count.n!==catalog.items.length) throw new ApiError(503,'CATALOG_NOT_SEEDED','El catálogo local requiere sincronización.');
}
