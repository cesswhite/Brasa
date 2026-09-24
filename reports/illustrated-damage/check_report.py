from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import unquote,urlparse
import json,hashlib,re,subprocess
ROOT=Path(__file__).resolve().parent
checks=0;errors=[]
def check(ok,note):
 global checks
 checks+=1
 if not ok:errors.append(note)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
class Links(HTMLParser):
 def handle_starttag(self,tag,attrs):
  for key,value in attrs:
   if key in ['src','href'] and value and not value.startswith('#'):
    parsed=urlparse(value);check(not parsed.scheme,'external resource '+value)
    if not parsed.scheme:check((ROOT/unquote(parsed.path)).exists(),'missing '+value)
page=(ROOT/'index.html').read_text();Links().feed(page)
m=json.loads((ROOT/'manifest.json').read_text())
check(m['available']=={'bodies':23,'banks':69,'poses':920},'scope incomplete')
for e in m['entries']:
 check(e['status']=='ready',e['id']+' missing')
 if e['status']!='ready':continue
 check(e['source_hash_verified'],e['id']+' source hash')
 check(sha(ROOT/e['atlas'])==e['sha256'],e['id']+' production hash')
 check(sha(ROOT/e['sidecar'])==e['sidecar_sha256'],e['id']+' metadata hash')
 check(sha(ROOT/e['thumb'])==e['thumb_sha256'],e['id']+' thumb hash')
 check(sha(ROOT/e['clean_thumb'])==e['clean_thumb_sha256'],e['id']+' clean thumb hash')
 check(e['alpha_mode']=='RGBA' and e['alpha_extrema']==[0,255],e['id']+' alpha')
 check(len(e['frames'])==e['expected_poses'],e['id']+' pose count')
 check(e['damage_tiers']==[2,3],e['id']+' tier family')
 for field in ['atlas','sidecar','clean_atlas','thumb','clean_thumb','review_evidence','validation_evidence','prompt_evidence']:
  if field in e:check((ROOT/e[field]).is_file(),e['id']+' missing link '+field)
 for f in e['frames']:check(f['region'][2:]==[512,512],e['id']+'/'+f['name']+' cell')
 if e['body_id']=='ascua':check(e['byte_identical_reuse'],e['id']+' changed reused PNG')
native=json.loads((ROOT/'native-manifest.json').read_text())
check(native['count']==39,'native capture count')
for e in native['captures']:
 check((ROOT/e['path']).is_file(),'native missing '+e['path'])
 check(sha(ROOT/e['path'])==e['sha256'],'native copy hash '+e['path'])
 check(e['first_pass_byte_identical'],'native first/final unchanged '+e['path'])
for path,value in native['evidence_hashes'].items():check(sha(ROOT/path)==value,'native evidence hash '+path)
for href in re.findall(r'\]\(([^)]+)\)',(ROOT.parent/'ILLUSTRATED-DAMAGE.md').read_text()):
 if not urlparse(href).scheme:check((ROOT.parent/href.split('#')[0]).is_file(),'report missing '+href)
scripts=re.findall(r'<script>(.*?)</script>',page,re.S);check(len(scripts)==1,'single inline script')
(ROOT/'viewer-check.js').write_text(scripts[0]);run=subprocess.run(['node','--check',str(ROOT/'viewer-check.js')],capture_output=True,text=True);check(run.returncode==0,'JS syntax: '+run.stderr)
result={'type':'report links, scope, hashes, syntax only; no browser/native gameplay claim','checks':checks,'failures':len(errors),'errors':errors,'html_sha256':sha(ROOT/'index.html'),'manifest_sha256':sha(ROOT/'manifest.json'),'comparison_sha256':sha(ROOT/'comparison.png')}
(ROOT/'report-validation.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2));assert not errors
