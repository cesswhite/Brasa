import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp,readFile,rm,stat} from 'node:fs/promises';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
import {randomBytes} from 'node:crypto';
import {fixture} from './helpers.mjs';
import {ORIGIN} from './auth-helpers.mjs';

test('opt-in remote workflow runs both phases against isolated local D1 only',async()=>{
  const f=await fixture(undefined,true,{AUTH_MODE:'better_auth',BETTER_AUTH_URL:ORIGIN,BETTER_AUTH_SECRET:randomBytes(48).toString('hex')});
  const directory=await mkdtemp(join(tmpdir(),'brasa-remote-script-test-')),file=join(directory,'credentials.json');
  const previousFetch=globalThis.fetch,previousArgs=process.argv,previousExit=process.exitCode;
  // Every network request is intercepted before importing the opt-in script.
  // No request reaches staging; only the local Worker receives these URLs.
  globalThis.fetch=(url,options)=>{assert.equal(new URL(url).origin,ORIGIN);return f.mf.dispatchFetch(url,options);};
  try {
    process.argv=['node','remote-smoke.mjs','--allow-remote','--phase','provision','--credentials',file];
    await import('./remote-smoke.mjs?local-provision');
    assert.equal(process.exitCode,previousExit);
    const provisioned=JSON.parse(await readFile(file,'utf8'));assert.equal(provisioned.phase,'provisioned');assert.equal(provisioned.accounts.length,2);assert.equal((await stat(file)).mode&0o777,0o600);
    assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM fighters').first()).n,0);
    process.argv=['node','remote-smoke.mjs','--allow-remote','--phase','verify','--credentials',file];
    await import('./remote-smoke.mjs?local-unmarked');
    assert.equal(process.exitCode,1);process.exitCode=previousExit;
    assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM fighters').first()).n,0);
    assert.equal(JSON.parse(await readFile(file,'utf8')).phase,'provisioned');
    // Administrator step occurs only in this temporary database between script phases.
    await f.db.prepare('UPDATE accounts SET is_test=1').run();
    process.argv=['node','remote-smoke.mjs','--allow-remote','--phase','verify','--credentials',file];
    await import('./remote-smoke.mjs?local-verify');
    assert.equal(process.exitCode,previousExit);
    const verified=JSON.parse(await readFile(file,'utf8'));assert.equal(verified.phase,'verified');assert.equal(verified.credentials_revoked,true);assert(verified.accounts.every(account=>!account.token));
    const report=JSON.parse(await readFile(file+'.report.json','utf8'));assert.equal(report.failed,undefined);
    assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM online_battles').first()).n,2);
  }finally{globalThis.fetch=previousFetch;process.argv=previousArgs;process.exitCode=previousExit;await f.close();await rm(directory,{recursive:true,force:true});}
});
