// Explicit, two-phase staging check. Never included in npm test and never seeds auth/gameplay.
import {open,readFile,writeFile,mkdir,stat} from 'node:fs/promises';
import {dirname,resolve} from 'node:path';
import {randomUUID} from 'node:crypto';
import {setTimeout as delay} from 'node:timers/promises';
import {browser,authenticator,ORIGIN,CLIENT} from './auth-helpers.mjs';
import {catalog as canonicalCatalog,catalogHash} from '../scripts/admin.mjs';
import {gameCatalog,ENGINE_VERSION,CATALOG_VERSION} from '../battle-engine/index.js';

const args=process.argv.slice(2),option=name=>{const i=args.indexOf(name);return i<0?undefined:args[i+1];};
const phase=option('--phase'),credentialPath=option('--credentials');
if(!args.includes('--allow-remote') || !['provision','verify'].includes(phase) || !credentialPath || (option('--origin')&&option('--origin')!==ORIGIN)){
  console.error('Uso explícito: node tests/remote-smoke.mjs --allow-remote --phase provision|verify --credentials .local/staging-smoke.json [--origin '+ORIGIN+']');process.exit(2);
}
const file=resolve(credentialPath),reportPath=resolve(option('--report')||file+'.report.json');
let state;const checks=[];
const transport={dispatchFetch:(url,options)=>{
  if(new URL(url).origin!==ORIGIN)throw new Error('El origen remoto no coincide con staging.');
  return fetch(url,{...options,redirect:'error',signal:AbortSignal.timeout(30000)});
}};
function check(condition,label){checks.push({label,passed:!!condition});if(!condition)throw new Error(label);console.log('OK '+label);}
const sameIds=(actual,expected)=>JSON.stringify([...actual].sort())===JSON.stringify([...expected].sort());
function expect(result,status,label){if(result.headers)checks.push({label,status:result.status,cf_ray:result.headers.get('cf-ray')});check((Array.isArray(status)?status:[status]).includes(result.status),label+' HTTP '+result.status);return result.data;}
async function save(){await writeFile(file,JSON.stringify(state,null,2)+'\n',{mode:0o600});}
async function request(account,path,body,{method=body===undefined?'GET':'POST',key,status=200,label=path}={}){
  const headers={Authorization:'Bearer '+account.token,...(body===undefined?{}:{'Content-Type':'application/json'}),...(key?{'Idempotency-Key':key}:{})};
  const response=await transport.dispatchFetch(ORIGIN+path,{method,headers,body:body===undefined?undefined:JSON.stringify(body)});
  let data;try{data=await response.json();}catch{throw new Error(label+' devolvió una respuesta no JSON (HTTP '+response.status+').');}
  checks.push({label,status:response.status,cf_ray:response.headers.get('cf-ray')});
  expect({status:response.status,data},status,label);
  return data.data??data;
}
async function provisionAccount(letter){
  const label='QA Brasa '+letter+' '+randomUUID().slice(0,6),web=browser(transport),native=browser(transport),key=authenticator();
  const nonce=expect(await web.call('/api/auth/registration/nonce',{name:label}),200,letter+' nonce');
  const options=expect(await web.call('/api/auth/passkey/generate-register-options?context='+encodeURIComponent(nonce.context)),200,letter+' opciones WebAuthn');
  expect(await web.call('/api/auth/passkey/verify-registration',{response:key.registration(options),name:'Prueba automatizada staging',createSession:true}),200,letter+' registro WebAuthn');
  expect(await web.call('/api/auth/sign-out',{}),200,letter+' cerrar sesión inicial');
  // Prove possession of the EC private key with an actual signed assertion, then obtain a native session.
  const login=expect(await web.call('/api/auth/passkey/generate-authenticate-options'),200,letter+' opciones de login');
  expect(await web.call('/api/auth/passkey/verify-authentication',{response:key.assertion(login)}),200,letter+' login con firma EC');
  const code=expect(await native.call('/api/auth/device/code',{client_id:CLIENT},{origin:null}),200,letter+' código dispositivo');
  check(code.verification_uri===ORIGIN+'/device' && new URL(code.verification_uri_complete).origin===ORIGIN,letter+' origen de verificación');
  const poll={grant_type:'urn:ietf:params:oauth:grant-type:device_code',device_code:code.device_code,client_id:CLIENT};
  const pending=expect(await native.call('/api/auth/device/token',poll,{origin:null}),400,letter+' pendiente antes de aprobar');
  check(pending.error==='authorization_pending',letter+' no se aprueba automáticamente');
  expect(await web.call('/api/auth/device?user_code='+encodeURIComponent(code.user_code)),200,letter+' revisar dispositivo');
  expect(await web.call('/api/auth/device/approve',{userCode:code.user_code}),200,letter+' aprobación explícita');
  await delay((Math.max(5,code.interval)+.2)*1000);
  const session=expect(await native.call('/api/auth/device/token',poll,{origin:null}),200,letter+' canje de dispositivo');
  check(typeof session.access_token==='string' && session.token_type==='Bearer',letter+' bearer emitido');
  expect(await web.call('/api/auth/sign-out',{}),200,letter+' navegador desconectado');
  const account={label,token:session.access_token,expires_at:Date.now()+session.expires_in*1000};
  const me=await request(account,'/v1/me',undefined,{label:letter+' identidad propia'});account.account_id=me.account_id;
  state.accounts.push(account);await save();
  console.log('CUENTA_PRUEBA '+letter+' '+account.account_id+' '+label);
}
async function waitCooldown(account,id){const fighter=await request(account,'/v1/fighters/'+id);const remaining=Math.max(0,Number(fighter.online.next_challenge_at)-Date.now()+300);if(remaining>60000)throw new Error('Cooldown mayor de un minuto: vuelve a revisar la prueba manualmente.');if(remaining)await delay(remaining);return fighter;}
async function verify(){
  check(state.accounts.length===2 && state.phase==='provisioned','Dos cuentas nuevas listas para verificar');
  const [a,b]=state.accounts;
  for(const account of [a,b]){
    const me=await request(account,'/v1/me');
    check(me.account_id===account.account_id,'Identidad de la cuenta guardada');
    check(me.is_test===1 || me.is_test===true,'Servidor confirma is_test antes de crear luchadores');
    check((await request(account,'/v1/fighters')).fighters.length===0,'Cuenta de prueba sin luchadores previos');
  }
  state.phase='verifying';await save();
  try {
    const catalog=await request(a,'/v1/game/catalog');
    check(sameIds(catalog.characters.map(character=>character.id),gameCatalog.character_ids)&&sameIds(catalog.story_stages.map(stage=>stage.id),gameCatalog.campaign.stages.map(stage=>stage.id)),'Catálogo de juego completo');
    check(catalog.engine_version===ENGINE_VERSION&&catalog.catalog_version===CATALOG_VERSION,'Versiones de motor y catálogo de juego');
    const cosmetics=await request(a,'/v1/catalog');
    check(sameIds(cosmetics.items.map(item=>item.inventory_id),canonicalCatalog.items.map(item=>item.inventory_id))&&sameIds(cosmetics.slots.map(slot=>slot.id),canonicalCatalog.slots.map(slot=>slot.id)),'Catálogo cosmético');
    check(cosmetics.version===canonicalCatalog.version&&cosmetics.catalog_hash===catalogHash,'Versión y hash del catálogo cosmético');
    const owned=await request(a,'/v1/owned');check(sameIds(owned.owned.map(item=>item.inventory_id),canonicalCatalog.starter_owned),'Inventario inicial del servidor');
    const createKey=randomUUID(),body={archetype_id:'luma',display_name:'QA Arena A'};
    let p=await request(a,'/v1/fighters',body,{key:createKey,status:201,label:'Crear luchador A'});
    const pRetry=await request(a,'/v1/fighters',body,{key:createKey,status:200,label:'Repetir creación A'});check(pRetry.fighter_id===p.fighter_id,'Creación idempotente');
    let r=await request(b,'/v1/fighters',{archetype_id:'luma',display_name:'QA Arena B'},{key:randomUUID(),status:201,label:'Crear luchador B'});
    state.fighter_ids=[p.fighter_id,r.fighter_id];await save();
    await request(b,'/v1/fighters/'+p.fighter_id,undefined,{status:404,label:'Lectura ajena rechazada'});
    const allocationKey=randomUUID(),allocation={stat:'attack',amount:1,expected_revision:p.progression_revision};
    const allocated=await request(a,'/v1/fighters/'+p.fighter_id+'/allocate',allocation,{key:allocationKey});
    const allocationRetry=await request(a,'/v1/fighters/'+p.fighter_id+'/allocate',allocation,{key:allocationKey});
    check(allocated.fighter.progression.stat_points===2 && allocationRetry.fighter.progression.allocations.attack===1,'Asignación exactamente una vez');p=allocated.fighter;
    const renamed=await request(a,'/v1/fighters/'+p.fighter_id,{expected_revision:p.revision,display_name:'QA Jade A',appearance:{palette_id:'jade'}},{method:'PATCH',key:randomUUID()});p=renamed;
    check(p.appearance.palette_id==='jade' && p.progression.allocations.attack===1,'Nombre y apariencia conservan progreso');
    const preview=await request(b,'/v1/opponents/'+p.fighter_id);check(preview.identity.display_name==='QA Jade A'&&preview.appearance.palette_id==='jade','Previsualización persistida');
    await request(a,'/v1/arena/opponents?fighter_id='+p.fighter_id);
    await request(a,'/v1/battles',{fighter_id:p.fighter_id,opponent_id:r.fighter_id,winner:'player'},{key:randomUUID(),status:422,label:'Resultado declarado por cliente rechazado'});
    const battleKey=randomUUID(),challenge={fighter_id:p.fighter_id,opponent_id:r.fighter_id};
    const arena=await request(a,'/v1/battles',challenge,{key:battleKey,status:201,label:'Arena autoritativa'});
    const retry=await request(a,'/v1/battles',challenge,{key:battleKey,status:200,label:'Reintento Arena'});
    check(arena.battle.id===retry.battle.id,'Un combate por clave');
    const snapshot=arena.battle.record.battle_snapshot;
    check(snapshot.events.length>5 && typeof snapshot.seed==='string' && !!snapshot.engine_version,'Snapshot y eventos reales de motor');
    const feed=await request(b,'/v1/arena/offline-results');check(feed.totals.battles===1 && feed.results[0].battle_id===arena.battle.id,'Defensa offline registrada una vez');
    const history=await request(a,'/v1/history?fighter_id='+p.fighter_id);check(history.battles.filter(battle=>battle.id===arena.battle.id).length===1,'Historial sin duplicado');
    p=await request(a,'/v1/fighters/'+p.fighter_id);
    await request(a,'/v1/fighters/'+p.fighter_id,{expected_revision:p.revision,display_name:'QA Tras Combate'},{method:'PATCH',key:randomUUID()});
    const historical=await request(a,'/v1/battles/'+arena.battle.id);check(JSON.stringify(historical.battle.record.battle_snapshot)===JSON.stringify(snapshot),'Cambio de nombre preserva snapshot histórico');
    const ackKey=randomUUID(),ack={ids:feed.results.map(item=>item.id)};
    await request(b,'/v1/arena/offline-results/ack',ack,{key:ackKey});await request(b,'/v1/arena/offline-results/ack',ack,{key:ackKey});
    check((await request(b,'/v1/arena/offline-results')).totals.battles===0,'Acuse offline idempotente');
    await waitCooldown(a,p.fighter_id);
    const route=await request(a,'/v1/story?fighter_id='+p.fighter_id);check(route.next_stage.global_level===1,'Primera ruta del servidor');
    const storyKey=randomUUID(),storyBody={fighter_id:p.fighter_id};
    const story=await request(a,'/v1/story/battles',storyBody,{key:storyKey,status:201,label:'Historia autoritativa'});
    const storyRetry=await request(a,'/v1/story/battles',storyBody,{key:storyKey,status:200,label:'Reintento Historia'});
    check(story.battle.id===storyRetry.battle.id && story.battle.mode==='story','Historia usa un resultado persistido');
    check(story.fighter.progression.total_xp===storyRetry.fighter.progression.total_xp,'XP de Historia no se duplica');
    state.battle_ids=[arena.battle.id,story.battle.id];state.phase='verified';await save();
  } finally {
    const cleanupErrors=[];
    for(const account of [a,b]){
      try {
        await request(account,'/api/auth/sign-out',{}, {label:'Revocar sesión de prueba'});
        await request(account,'/v1/me',undefined,{status:401,label:'Bearer revocado rechazado'});
        delete account.token;
      } catch {cleanupErrors.push(account.account_id);}
    }
    state.credentials_revoked=cleanupErrors.length===0;await save();
    if(cleanupErrors.length)throw new Error('No se pudo confirmar la revocación de '+cleanupErrors.length+' sesión(es) de prueba; conserva el archivo privado para revocación administrativa.');
  }
}
try {
  if(phase==='provision'){
    await mkdir(dirname(file),{recursive:true,mode:0o700});
    const output=await open(file,'wx',0o600);await output.close();
    state={version:1,origin:ORIGIN,phase:'provisioning',created_at:new Date().toISOString(),accounts:[]};await save();
    await provisionAccount('A');await provisionAccount('B');state.phase='provisioned';await save();
    console.log('PAUSA: marca ambas cuentas is_test=1 mediante administración de D1. No se han creado luchadores ni combates.');
    console.log('Después ejecuta --phase verify con este mismo archivo privado.');
  } else {
    const metadata=await stat(file);if((metadata.mode&0o077)!==0 || (process.getuid && metadata.uid!==process.getuid()))throw new Error('El archivo de credenciales debe ser propio y privado (0600).');
    state=JSON.parse(await readFile(file,'utf8'));if(state.origin!==ORIGIN)throw new Error('El archivo pertenece a otro origen.');await verify();
  }
  await writeFile(reportPath,JSON.stringify({origin:ORIGIN,phase:state.phase,accounts:state.accounts.map(({account_id,label})=>({account_id,label})),fighter_ids:state.fighter_ids||[],battle_ids:state.battle_ids||[],checks,completed_at:new Date().toISOString()},null,2)+'\n');
  console.log('REMOTE SMOKE '+phase+': '+checks.filter(check=>check.passed===true).length+' comprobaciones aprobadas.');
} catch(error){
  // Deliberately omit stacks, raw responses and credential contents.
  console.error('REMOTE SMOKE FAILED: '+String(error.message).slice(0,240));process.exitCode=1;
  await writeFile(reportPath,JSON.stringify({origin:ORIGIN,phase:state?.phase||phase,failed:true,checks},null,2)+'\n').catch(()=>{});
}
