import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {canonical} from '../src/crypto.js';
const source=new URL('../../data/cosmetic_catalog.json',import.meta.url);
const input=JSON.parse(await readFile(source,'utf8'));
if(!Array.isArray(input.items)||!Array.isArray(input.slots)||input.slots.length!==6||!Array.isArray(input.starter_owned)) throw new Error('Invalid canonical cosmetic catalog');
const text=canonical(input)+'\n';
const meta=JSON.stringify({source:'../data/cosmetic_catalog.json',version:input.version,sha256:createHash('sha256').update(canonical(input)).digest('hex')},null,2)+'\n';
await mkdir('generated',{recursive:true});
for(const [path,data] of [['generated/cosmetic_catalog.json',text],['generated/catalog_meta.json',meta]]) {
  if(process.argv.includes('--check')) {if(await readFile(path,'utf8')!==data) throw new Error('Stale generated catalog: '+path);}
  else await writeFile(path,data);
}
console.log('Canonical cosmetic catalog '+(process.argv.includes('--check')?'verified':'synchronized')+'.');
