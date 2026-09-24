import {Miniflare} from 'miniflare';
import {readFile,mkdtemp,rm,readdir} from 'node:fs/promises';
import {join,resolve} from 'node:path';
import {tmpdir} from 'node:os';
import {catalogSQL,credentialSQL,newCredential} from '../scripts/admin.mjs';
export async function fixture(path,initialize=true,bindings={},options={}) {
  const dir=path||await mkdtemp(join(tmpdir(),'brasa-d1-tests-'));
  // Bundle includes Better Auth's optional node:sqlite dynamic probe. D1 never uses it.
  const mf=new Miniflare({modules:[{type:'ESModule',path:resolve(options.scriptPath||'dist/worker.js')}],compatibilityDate:'2026-07-08',compatibilityFlags:['nodejs_compat'],d1Databases:{DB:'brasa-tests'},d1Persist:dir,bindings:{AUTH_MODE:'local_dev',...bindings},...(options.inspectorPort!==undefined?{inspectorPort:options.inspectorPort}:{})});
  let db;
  try {
  db=await mf.getD1Database('DB');
  if(initialize) {
    const files=(await readdir('migrations')).filter(name=>name.endsWith('.sql')).sort();
    const migration=(await Promise.all(files.map(name=>readFile('migrations/'+name,'utf8')))).join('\n');
    // D1 exec consumes complete SQL statements. Keep trigger BEGIN...END blocks whole.
    const statements=[];let buffer='',trigger=false;
    for(const line of migration.split('\n')) {
      if(!line.trim() || line.trim().startsWith('--'))continue;
      if(!buffer) trigger=line.startsWith('CREATE TRIGGER');
      buffer+=line+'\n';
      if((trigger && (line.trim()==='END;' || line.includes('BEGIN SELECT RAISE'))) || (!trigger && line.trim().endsWith(';'))) {statements.push(buffer.trim());buffer='';trigger=false;}
    }
    await db.batch(statements.map(sql=>db.prepare(sql)));
    await db.batch(catalogSQL().map(sql=>db.prepare(sql)));
  }
  } catch(error) {await mf.dispose();if(!path)await rm(dir,{recursive:true,force:true});throw error;}
  return {mf,db,dir,async close(remove=true){await mf.dispose();if(remove)await rm(dir,{recursive:true,force:true});}};
}
export async function account(db) {
  const credential=newCredential();await db.batch(credentialSQL(credential).map(sql=>db.prepare(sql)));return credential;
}
export async function request(mf,credential,path,method='GET',body,extra={}) {
  const headers={'Content-Type':'application/json',...(credential?{Authorization:'Bearer '+credential.token}:{}),...extra};
  const response=await mf.dispatchFetch('http://127.0.0.1:8787'+path,{method,headers,body:body===undefined?undefined:JSON.stringify(body)});
  return {status:response.status,body:await response.json(),headers:response.headers};
}
