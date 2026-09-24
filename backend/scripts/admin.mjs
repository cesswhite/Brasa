import {randomBytes,randomUUID,createHash} from 'node:crypto';
import {readFile} from 'node:fs/promises';
import {canonical} from '../src/crypto.js';
import {starterExpansionSQL} from './starter-expansions.mjs';
export const catalog=JSON.parse(await readFile(new URL('../generated/cosmetic_catalog.json',import.meta.url),'utf8'));
export const catalogHash=createHash('sha256').update(canonical(catalog)).digest('hex');
const q=value=>"'"+String(value).replaceAll("'","''")+"'";
export function catalogSQL() {
  const now=new Date().toISOString();
  return [
    `INSERT OR IGNORE INTO catalog_versions(hash,version,payload,created_at) VALUES (${q(catalogHash)},${catalog.version},${q(canonical(catalog))},${q(now)});`,
    ...catalog.items.map(i=>`INSERT INTO cosmetic_definitions(inventory_id,slot,cosmetic_id,definition,catalog_hash) VALUES (${q(i.inventory_id)},${q(i.slot)},${q(i.id)},${q(canonical(i))},${q(catalogHash)}) ON CONFLICT(inventory_id) DO UPDATE SET definition=excluded.definition,catalog_hash=excluded.catalog_hash;`),
    ...starterExpansionSQL(catalog,q,now)
  ];
}
export function newCredential(accountId=randomUUID(),days=7) {
  return {account_id:accountId,token:'brasa_local_'+randomBytes(32).toString('base64url'),expires_at:Date.now()+days*86400000};
}
export function credentialSQL(credential,createAccount=true) {
  const now=new Date().toISOString(), hash=createHash('sha256').update(credential.token).digest('hex');
  return [
    ...(createAccount?[`INSERT INTO accounts(id,created_at) VALUES (${q(credential.account_id)},${q(now)});`]:[]),
    `INSERT INTO local_sessions(token_hash,account_id,expires_at,created_at) VALUES (${q(hash)},${q(credential.account_id)},${credential.expires_at},${q(now)});`,
    ...catalog.starter_owned.map(id=>grantSQL(credential.account_id,id,'starter'))
  ];
}
export function grantSQL(accountId,inventoryId,source='local_admin') {
  if(!catalog.items.some(i=>i.inventory_id===inventoryId)) throw new Error('Unknown inventory ID');
  return `INSERT OR IGNORE INTO owned_cosmetics(account_id,inventory_id,source,granted_at) VALUES (${q(accountId)},${q(inventoryId)},${q(source)},${q(new Date().toISOString())});`;
}
export function revokeSQL(token) {
  return `UPDATE local_sessions SET revoked_at=${Date.now()} WHERE token_hash=${q(createHash('sha256').update(token).digest('hex'))};`;
}
