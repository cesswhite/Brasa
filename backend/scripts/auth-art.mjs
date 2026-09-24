import {readFile,writeFile,copyFile,mkdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
const root=new URL('../../',import.meta.url),out=new URL('../web/public/auth/art/',import.meta.url);
await mkdir(out,{recursive:true});
const read=async path=>JSON.parse(await readFile(new URL(path,root),'utf8'));
const tokens=await read('data/game_visual_tokens.json'),manifest=await read('data/ui_visual_manifest.json');
const sources={'world.png':manifest.assets.camp.path.slice(6),'fighter.png':'assets/sprites/normalized/nima-base-v2.png','surfaces.png':manifest.assets.surfaces.path.slice(6)};
const records=[];
for(const [name,path]of Object.entries(sources)){const source=new URL(path,root);await copyFile(source,new URL(name,out));records.push({file:name,source:path,sha256:createHash('sha256').update(await readFile(source)).digest('hex'),operation:'byte-identical copy; CSS controls presentation'});}
const [x,y,w,h]=manifest.surfaces.primary.region;
const colors=Object.entries(tokens.colors).map(([key,value])=>`--${key.replaceAll('_','-')}:#${value};`).join('');
await writeFile(new URL('tokens.css',out),`:root{${colors}--font-body:'Avenir Next','DejaVu Sans',Arial,sans-serif;--font-heading:Georgia,'DejaVu Serif',serif}button.primary{background-color:transparent;background-image:url('/auth/art/surfaces.png');background-size:${100/w}% ${100/h}%;background-position:${100*x/(1-w)}% ${100*y/(1-h)}%;border:0;box-shadow:0 4px 12px #0005}\n`);
await writeFile(new URL('../auth-art-provenance.json',import.meta.url),JSON.stringify({authority:'Story visual tokens and material manifest',assets:records},null,2)+'\n');
