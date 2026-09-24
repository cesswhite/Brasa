// Deliberately explicit: only newly introduced free bodies are backfilled.
// Do not infer missing rewards or restore any older/default revoked inventory.
export const starterExpansions = [
  {id:'cats-v1',inventoryIds:['body_style:onix','body_style:bruma']},
];
export function starterExpansionSQL(catalog,quote,now) {
  const statements=[];
  for(const expansion of starterExpansions) {
    for(const id of expansion.inventoryIds) {
      const item=catalog.items.find(candidate=>candidate.inventory_id===id);
      if(!item?.default || item.unlock?.kind!=='default' || !catalog.starter_owned.includes(id)) throw new Error('Starter expansion is not a catalog default: '+id);
      statements.push(`INSERT OR IGNORE INTO owned_cosmetics(account_id,inventory_id,source,granted_at) SELECT id,${quote(id)},'starter_expansion',${quote(now)} FROM accounts WHERE NOT EXISTS (SELECT 1 FROM catalog_starter_expansions WHERE id=${quote(expansion.id)});`);
    }
    // Write only after every item was granted. A failed seed can be retried safely.
    statements.push(`INSERT OR IGNORE INTO catalog_starter_expansions(id,applied_at) VALUES (${quote(expansion.id)},${quote(now)});`);
  }
  return statements;
}
