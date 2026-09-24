import test from 'node:test';
import assert from 'node:assert/strict';
import {authFixture,browser,authenticator,registrationOptions,register,ORIGIN,CLIENT} from './auth-helpers.mjs';
import {catalog} from '../scripts/admin.mjs';

async function assertStarterInventory(db) {
  const rows=(await db.prepare('SELECT inventory_id FROM owned_cosmetics ORDER BY inventory_id').all()).results;
  assert.deepEqual(rows.map(row=>row.inventory_id),[...catalog.starter_owned].sort());
}

test('passkey-first provisions one account only after verified ceremony and requires real user verification',async()=>{
  const f=await authFixture();try{
    const web=browser(f.mf),key=authenticator();
    const {context,options}=await registrationOptions(web);
    assert.equal(options.authenticatorSelection.userVerification,'required');assert.equal(options.authenticatorSelection.residentKey,'required');
    assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM accounts').first()).n,0);
    const rejected=await web.call('/api/auth/passkey/verify-registration',{response:key.registration(options,{uv:false}),createSession:true});
    assert.equal(rejected.status,401);assert.equal(rejected.data.code,'USER_VERIFICATION_REQUIRED');
    assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM accounts').first()).n,0);
    assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM auth_user').first()).n,0);
    const options2=await web.call('/api/auth/passkey/generate-register-options?context='+encodeURIComponent(context));
    const proof=key.registration(options2.data);
    const accepted=await web.call('/api/auth/passkey/verify-registration',{response:proof,createSession:true});
    assert.equal(accepted.status,200,JSON.stringify(accepted.data));
    assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM accounts').first()).n,1);
    await assertStarterInventory(f.db);
    assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM auth_account_links').first()).n,1);
    assert.equal((await f.db.prepare('SELECT consumed_at FROM auth_registration').first()).consumed_at>0,true);
    const replay=await web.call('/api/auth/passkey/verify-registration',{response:proof,createSession:true});assert.notEqual(replay.status,200);
    const account=await web.call('/v1/me',undefined,{headers:{Authorization:'Bearer '+accepted.data.session.token}});assert.equal(account.status,200);
    const cookieOnly=await web.call('/v1/me');assert.equal(cookieOnly.status,401);
    const wrongBearer=await web.call('/v1/me',undefined,{headers:{Authorization:'Bearer '+'a'.repeat(32)+'.invalid'}});assert.equal(wrongBearer.status,401);
    await web.call('/api/auth/sign-out',{});
    const loginOptions=await web.call('/api/auth/passkey/generate-authenticate-options');
    const uvLogin=await web.call('/api/auth/passkey/verify-authentication',{response:key.assertion(loginOptions.data,{uv:false})});assert.equal(uvLogin.status,401);
    const login2=await web.call('/api/auth/passkey/generate-authenticate-options');
    const login=await web.call('/api/auth/passkey/verify-authentication',{response:key.assertion(login2.data)});assert.equal(login.status,200,JSON.stringify(login.data));
    assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM accounts').first()).n,1);
  }finally{await f.close();}
});

test('device approval is explicit, tokens are single-use, bearer ownership and revocation work',async()=>{
  const f=await authFixture();try{
    const web=browser(f.mf),device=browser(f.mf);await register(web);
    const grant=await device.call('/api/auth/device/code',{client_id:CLIENT},{origin:null});assert.equal(grant.status,200,JSON.stringify(grant.data));
    assert.equal(grant.data.verification_uri,ORIGIN+'/device');assert.equal(grant.data.expires_in,600);assert.equal(grant.data.interval,5);
    const body={grant_type:'urn:ietf:params:oauth:grant-type:device_code',device_code:grant.data.device_code,client_id:CLIENT};
    const pending=await device.call('/api/auth/device/token',body,{origin:null});assert.equal(pending.status,400);assert.equal(pending.data.error,'authorization_pending');
    const slow=await device.call('/api/auth/device/token',body,{origin:null});assert.equal(slow.data.error,'slow_down');
    const auto=await device.call('/api/auth/device/approve',{userCode:grant.data.user_code});assert.notEqual(auto.status,200);
    const details=await web.call('/api/auth/device?user_code='+grant.data.user_code);assert.equal(details.status,200);
    assert.equal(details.data.status,'pending');
    assert.equal((await web.call('/api/auth/device/approve',{userCode:grant.data.user_code})).status,200);
    await f.db.prepare('UPDATE auth_device_code SET lastPolledAt=NULL').run();
    const redeemed=await Promise.all([device.call('/api/auth/device/token',body,{origin:null}),device.call('/api/auth/device/token',body,{origin:null})]);
    assert.equal(redeemed.filter(r=>r.status===200).length,1,JSON.stringify(redeemed));
    const token=redeemed.find(r=>r.status===200).data.access_token;
    assert.equal(typeof token,'string');assert.equal((await device.call('/v1/me',undefined,{headers:{Authorization:'Bearer '+token},origin:null})).status,200);
    assert.equal((await device.call('/api/auth/sign-out',{}, {headers:{Authorization:'Bearer '+token},origin:null})).status,200);
    assert.equal((await device.call('/v1/me',undefined,{headers:{Authorization:'Bearer '+token},origin:null})).status,401);
  }finally{await f.close();}
});

test('origin checks, nonce tampering, unsupported identity inputs, D1 rate limits and local tokens fail closed',async()=>{
  const f=await authFixture();try{
    const web=browser(f.mf);
    assert.equal((await web.call('/auth')).status,200);
    assert.equal((await web.call('/api/auth/registration/nonce',{name:'Sol'},{origin:'https://evil.invalid'})).status,403);
    assert.equal((await web.call('/api/auth/registration/nonce',{name:'Sol'},{origin:null})).status,403);
    assert.equal((await web.call('/api/auth/device/code',{client_id:CLIENT,user_id:'victim'})).status,400);
    assert.equal((await web.call('/api/auth/device/code',{client_id:'rogue'})).status,400);
    assert.equal((await web.call('/api/auth/sign-up/email',{email:'a@b.test',password:'secret'})).status,404);
    const bad=await web.call('/api/auth/passkey/generate-register-options?context=forged.signature');assert.equal(bad.status,400);
    assert.equal((await web.call('/v1/me',undefined,{headers:{Authorization:'Bearer brasa_local_'+'a'.repeat(43)}})).status,401);
    const results=await Promise.all(Array.from({length:7},()=>web.call('/api/auth/registration/nonce',{name:'Sol'})));
    assert.equal(results.filter(r=>r.status===200).length,5);assert.equal(results.filter(r=>r.status===429).length,2);
    assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM auth_throttle').first()).n>0,true);
  }finally{await f.close();}
});

test('expired and denied device grants never create sessions, and another user cannot approve a claimed code',async()=>{
  const f=await authFixture();try{
    const first=browser(f.mf),second=browser(f.mf),device=browser(f.mf);await register(first);await register(second,authenticator(),'Otra Brasa');
    const grant=await device.call('/api/auth/device/code',{client_id:CLIENT});
    const body={grant_type:'urn:ietf:params:oauth:grant-type:device_code',device_code:grant.data.device_code,client_id:CLIENT};
    assert.equal((await first.call('/api/auth/device?user_code='+grant.data.user_code)).status,200);
    await second.call('/api/auth/device?user_code='+grant.data.user_code);
    assert.notEqual((await second.call('/api/auth/device/approve',{userCode:grant.data.user_code})).status,200);
    assert.equal((await first.call('/api/auth/device/deny',{userCode:grant.data.user_code})).status,200);
    assert.equal((await device.call('/api/auth/device/token',body,{origin:null})).data.error,'access_denied');
    const expiring=await device.call('/api/auth/device/code',{client_id:CLIENT});
    await f.db.prepare('UPDATE auth_device_code SET expiresAt=? WHERE deviceCode=?').bind(new Date(Date.now()-1000).toISOString(),expiring.data.device_code).run();
    const expired=await device.call('/api/auth/device/token',{...body,device_code:expiring.data.device_code},{origin:null});assert.equal(expired.status,400);assert.equal(expired.data.error,'expired_token');
    assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM auth_session').first()).n,2);
  }finally{await f.close();}
});

test('WebAuthn origin, single-use registration context and duplicate credentials are enforced',async()=>{
  const f=await authFixture();try{
    const first=browser(f.mf),key=authenticator();
    const initial=await registrationOptions(first);
    const badOrigin=await first.call('/api/auth/passkey/verify-registration',{response:key.registration(initial.options,{origin:'https://evil.invalid'}),createSession:true});assert.notEqual(badOrigin.status,200);
    assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM auth_user').first()).n,0);
    await f.db.prepare('UPDATE auth_registration SET expires_at=?').bind(Date.now()-1).run();
    assert.equal((await first.call('/api/auth/passkey/generate-register-options?context='+encodeURIComponent(initial.context))).status,400);
    const registered=await register(first,key);
    const used=await f.db.prepare('SELECT context_hash FROM auth_registration WHERE consumed_at IS NOT NULL').first();assert.ok(used);
    const second=browser(f.mf),secondOptions=await registrationOptions(second,'Otro nombre');
    const reused=await second.call('/api/auth/passkey/verify-registration',{response:key.registration(secondOptions.options),createSession:true});assert.notEqual(reused.status,200);
    assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM accounts').first()).n,1);
    assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM auth_passkey').first()).n,1);
    assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM auth_session').first()).n,1);
    const current=await first.call('/api/auth/get-session');assert.equal(current.data.user.id,registered.result.data.user.id);
  }finally{await f.close();}
});

test('adding a second passkey preserves account; registration needs a recent authenticated session',async()=>{
  const f=await authFixture();try{
    const web=browser(f.mf);const initial=await register(web);
    const options=await web.call('/api/auth/passkey/generate-register-options');assert.equal(options.status,200);
    assert.equal(options.data.excludeCredentials.length,1);
    const added=await web.call('/api/auth/passkey/verify-registration',{response:authenticator().registration(options.data),createSession:true});assert.equal(added.status,200,JSON.stringify(added.data));
    assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM accounts').first()).n,1);
    assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM auth_passkey').first()).n,2);
    await f.db.prepare('UPDATE auth_session SET createdAt=?').bind(new Date(Date.now()-600000).toISOString()).run();
    const staleOptions=await web.call('/api/auth/passkey/generate-register-options');
    const stale=await web.call('/api/auth/passkey/verify-registration',{response:authenticator().registration(staleOptions.data),createSession:true});assert.equal(stale.status,401);assert.equal(stale.data.code,'FRESH_SESSION_REQUIRED');
    assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM auth_passkey').first()).n,2);
  }finally{await f.close();}
});

test('session/account/ownership persist across Worker restarts and expiry is authoritative',async()=>{
  const first=await authFixture();let second;try{
    const web=browser(first.mf),{result}=await register(web);const token=result.data.session.token;
    const before=await web.call('/v1/me',undefined,{headers:{Authorization:'Bearer '+token}});assert.equal(before.status,200);
    await first.close(false);second=await authFixture(first.dir,false,first.authBindings);
    const client=browser(second.mf);const after=await client.call('/v1/me',undefined,{headers:{Authorization:'Bearer '+token},origin:null});assert.deepEqual(after.data,before.data);
    await assertStarterInventory(second.db);
    await second.db.prepare('UPDATE auth_session SET expiresAt=?').bind(new Date(Date.now()-1).toISOString()).run();
    assert.equal((await client.call('/v1/me',undefined,{headers:{Authorization:'Bearer '+token},origin:null})).status,401);
  }finally{if(second)await second.close();else await first.close();}
});

test('missing or weak configuration and alternate hosts fail closed',async()=>{
  for(const bindings of [{AUTH_MODE:'better_auth',BETTER_AUTH_URL:ORIGIN},{AUTH_MODE:'better_auth',BETTER_AUTH_URL:ORIGIN,BETTER_AUTH_SECRET:'short'}]){
    const f=await authFixture(undefined,true,bindings);try{assert.equal((await browser(f.mf).call('/api/auth/device/code',{client_id:CLIENT})).status,503);}finally{await f.close();}
  }
  const f=await authFixture();try{
    const response=await f.mf.dispatchFetch('https://attacker.invalid/api/auth/device/code',{method:'POST',headers:{Origin:ORIGIN,'Content-Type':'application/json'},body:JSON.stringify({client_id:CLIENT})});assert.equal(response.status,403);
  }finally{await f.close();}
});
