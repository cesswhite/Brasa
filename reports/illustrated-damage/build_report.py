"""Read-only art inspection -> report artifacts. Never modifies art/runtime/imports."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import hashlib,json,html,datetime,shutil
OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[3]
PRODUCT=ROOT/'outputs/Brasa'
WORK=ROOT/'work/illustrated-damage'
ART=PRODUCT/'assets/sprites/damage/illustrated-v2'
BODIES=['nima','luma','mugo','sira','iria','duna','kiro','neris','taro','balam','tepa','xuna','copal','onix','bruma','ascua','vespera','taro_roque','taro_sabio','duna_cora','duna_pedernal','bruma_ambar','bruma_nieve']
BANKS={'base':8,'movement':16,'reactions':16}
NAMES={i['id']:i['name'] for i in json.loads((PRODUCT/'data/cosmetic_catalog.json').read_text())['items'] if i['slot']=='body_style_id'}
NAMES.update(ascua='Ascua',vespera='Véspera')
LABELS={'base':'Base · 8 poses','movement':'Movimiento · 16 poses','reactions':'Reacción · 16 poses'}
POSES={'idle':'Guardia','idle_breathe':'Respiración','windup':'Preparación','punch':'Puñetazo','hit':'Reacción','dodge':'Esquiva','victory':'Victoria','defeat':'Derrota','guard_shift':'Cambio de guardia','quick_anticipation':'Anticipación rápida','quick_extend':'Extensión rápida','quick_recover':'Recuperación rápida','heavy_anticipation':'Anticipación fuerte','heavy_extend':'Extensión fuerte','heavy_recover':'Recuperación fuerte','step_forward':'Paso adelante','dash':'Avance','jump_takeoff':'Despegue','jump_apex':'Ápice del salto','jump_strike':'Golpe en salto','landing':'Aterrizaje','follow_through':'Continuación','counter_ready':'Guardia de réplica','counter_strike':'Réplica','light_hit':'Impacto ligero','body_hit':'Golpe al cuerpo','heavy_hit':'Impacto fuerte','critical_stagger':'Tambaleo crítico','fall_start':'Inicio de caída','fall_mid':'Caída','grounded':'En el suelo','getup_support':'Apoyo al levantarse','getup_kneel':'Incorporación de rodillas','getup_rise':'Volver a pie','low_health':'Fatiga','victory_start':'Inicio de victoria','victory_peak':'Victoria','transform_start':'Inicio de transformación','transform_peak':'Transformación','transformed_idle':'Guardia transformada'}
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
rel=lambda p:str(Path(p).relative_to(ROOT))
for directory in ['thumbs','evidence/reviews','evidence/validations','evidence/prompts']:(OUT/directory).mkdir(parents=True,exist_ok=True)
raw_ledgers=[]
for file in [WORK/'group-b/sources.json',WORK/'group-c/sources.json']:
 if file.exists():
  parsed=json.loads(file.read_text());raw_ledgers.extend(parsed if isinstance(parsed,list) else parsed.get('entries',[]))
entries=[]; bodies=[]
for body in BODIES:
 banks=[]
 for bank,count in BANKS.items():
  key=f'{body}-{bank}';png=ART/f'{key}.png';side=png.with_suffix('.json');clean=PRODUCT/f'assets/sprites/normalized/{key}-v2.png'
  item={'id':key,'body_id':body,'name':NAMES.get(body,body),'bank':bank,'label':LABELS[bank],'expected_poses':count,'status':'pending','frames':[],'origin':'Reutilización critical-v1' if body=='ascua' else 'Ilustración nueva'}
  if png.exists() and side.exists():
   meta=json.loads(side.read_text());source=ROOT/meta['source']['path'];image=Image.open(png);clean_image=Image.open(clean)
   assert image.mode=='RGBA',key
   thumb=OUT/f'thumbs/{key}.png';clean_thumb=OUT/f'thumbs/{key}-clean.png'
   for original,target in [(image,thumb),(clean_image,clean_thumb)]:original.resize((original.width//2,original.height//2),Image.Resampling.LANCZOS).save(target)
   source_hash=sha(source) if source.exists() else None
   item.update(status='ready',poses=len(meta['frames']),frames=[{'name':f['name'],'label':POSES.get(f['name'],f['name'].replace('_',' ')),'region':f['region'],'bounds':f.get('alpha_bounds_px'),'socket_annotation_method':f.get('socket_annotation_method',''),'socket_verification':f.get('socket_verification',{})} for f in meta['frames']],thumb=str(thumb.relative_to(OUT)),clean_thumb=str(clean_thumb.relative_to(OUT)),atlas=f'../../assets/sprites/damage/illustrated-v2/{key}.png',sidecar=f'../../assets/sprites/damage/illustrated-v2/{key}.json',clean_atlas=f'../../assets/sprites/normalized/{key}-v2.png',production_path=rel(png),sha256=sha(png),sidecar_sha256=sha(side),clean_sha256=sha(clean),source=meta['source'],source_hash_verified=source_hash==meta['source']['sha256'],alpha_mode=image.mode,alpha_extrema=list(image.getchannel('A').getextrema()),dimensions=list(image.size),thumb_sha256=sha(thumb),clean_thumb_sha256=sha(clean_thumb),art_review_status=meta.get('art_review_status','unrecorded'),damage_tiers=meta.get('damage_tiers',[2,3]))
   assert item['sha256']==meta['atlas_sha256'],key
   assert item['poses']==count,key
   source_match=[e for e in raw_ledgers if e.get('body')==body and e.get('bank')==bank and (e.get('sha256',e.get('raw_sha256'))==source_hash)]
   if source_match:item['generation_record']=source_match[-1]
   source_note=WORK/f'prompts/{key}-source.json'
   if source_note.exists():item['generation_record']=json.loads(source_note.read_text())
   for kind,src in [('review',WORK/f'reviews/{key}.json'),('validation',WORK/f'prepared/{body}/{bank}/validation.json')]:
    if src.exists():
     dest=OUT/f'evidence/{kind}s/{key}.json';shutil.copyfile(src,dest);item[kind+'_evidence']=str(dest.relative_to(OUT));item[kind+'_sha256']=sha(src)
   candidates=[WORK/f'prompts/{key}.json',WORK/f'group-c/{key}-prompt.json',WORK/f'group-b/prompts/{key}.txt']
   for prompt in candidates:
    if not prompt.exists():continue
    text=prompt.read_text();ext=prompt.suffix;dest=OUT/f'evidence/prompts/{key}{ext}';dest.write_text(text);item['prompt_evidence']=str(dest.relative_to(OUT));item['prompt_sha256']=sha(dest);item['prompt_text']=json.loads(text).get('prompt',text) if ext=='.json' else text;break
   if body=='ascua':item['byte_identical_reuse']=item['sha256']==source_hash
  entries.append(item);banks.append(item)
 bodies.append({'id':body,'name':NAMES.get(body,body),'origin':'reused' if body=='ascua' else 'new','banks':banks,'ready':all(b['status']=='ready' for b in banks)})
ready=[e for e in entries if e['status']=='ready']
qa_file=OUT/'native-qa.json'
if not qa_file.exists():qa_file.write_text(json.dumps({'status':'pending','label':'QA nativa pendiente','description':'La revisión de los PNG y sus metadatos no sustituye la comprobación de contactos, transiciones, KO, pausa y Replay con el renderer real. Se añadirá la evidencia cuando el responsable confirme el pase final.'},indent=2,ensure_ascii=False)+'\n')
qa=json.loads(qa_file.read_text())
global_manifest=WORK/'final-art-manifest.json'
if global_manifest.exists():shutil.copyfile(global_manifest,OUT/'evidence/final-art-manifest.json')
for audit_name in ['final-art-preservation.json','pipeline-tests.log']:
 source=WORK/audit_name
 if source.exists():shutil.copyfile(source,OUT/'evidence'/audit_name)
manifest={'title':'Brasa · Daño ilustrado','scope':{'bodies':23,'new_bodies':22,'reused_bodies':1,'banks':69,'poses':920,'damage_tiers':[2,3],'illustrated_families_per_body':1,'tier1':'arte limpio + fatiga'},'available':{'bodies':sum(b['ready'] for b in bodies),'banks':len(ready),'poses':sum(e['poses'] for e in ready)},'native_qa':qa,'thumbnail_method':'Production RGBA atlas reduced uniformly to 50%, without per-pose fitting, geometry/color edits or generative changes. Clean and wounded have the same canvas, crop, density and CSS display scale. Backgrounds are viewer surfaces, not embedded into PNG. These are technical previews, not native screenshots.','entries':entries}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False)+'\n')
# Static technical cover: same 512px region and 0.6 camera for all six figures.
cover=Image.new('RGB',(1320,330),'#0b2026');draw=ImageDraw.Draw(cover)
try:font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Georgia.ttf',24);small=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',17)
except OSError:font=small=ImageFont.load_default()
for col,body in enumerate(['nima','bruma','mugo']):
 draw.text((col*440+20,16),NAMES.get(body,body),(239,182,111),font=font)
 for state in range(2):
  path=(PRODUCT/f'assets/sprites/normalized/{body}-base-v2.png') if state==0 else ART/f'{body}-base.png'
  if not path.exists():continue
  cell=Image.open(path).convert('RGBA').crop((0,90,512,470)).resize((307,228),Image.Resampling.LANCZOS)
  x=col*440+state*210-36;cover.paste(cell,(x,40),cell)
  draw.text((col*440+state*210+35,295),'Limpio' if state==0 else 'Herido',(179,198,189),font=small)
cover.save(OUT/'comparison.png')
# Embed data; file:// needs neither fetch nor a server.
payload=json.dumps({'bodies':bodies,'scope':manifest['scope'],'available':manifest['available'],'qa':qa},ensure_ascii=False).replace('</',r'<\/')
template=(OUT/'template.html').read_text()
native_section=(OUT/'native-section.html').read_text() if (OUT/'native-section.html').exists() else ''
(OUT/'index.html').write_text(template.replace('/*DATA*/',payload).replace('<!--NATIVE-->',native_section))
print(json.dumps({'available':manifest['available'],'target':manifest['scope'],'native':qa['status'],'manifest_sha256':sha(OUT/'manifest.json')},ensure_ascii=False))
