import {spawnSync} from 'node:child_process';
import {mkdir,writeFile,readFile,mkdtemp,rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join,resolve} from 'node:path';
import {catalogSQL,newCredential,credentialSQL,grantSQL,revokeSQL} from './admin.mjs';
const [command,...args]=process.argv.slice(2);
const option=name=>{const index=args.indexOf(name);return index<0?null:args[index+1];};
async function run(statements) {
  const temp=await mkdtemp(join(tmpdir(),'brasa-local-sql-'));
  try {
    const file=join(temp,'data.sql');
    // Only hashes are written to this short-lived file; bearer tokens never enter SQL/logs.
    await writeFile(file,statements.join('\n'),{mode:0o600});
    const result=spawnSync(process.execPath,['node_modules/wrangler/bin/wrangler.js','d1','execute','DB','--local','--persist-to','.local/state','--file',file,'--yes'],{stdio:'pipe',env:{...process.env,WRANGLER_SEND_METRICS:'false'}});
    if(result.status!==0) throw new Error(result.stderr.toString()||result.stdout.toString());
  } finally {await rm(temp,{recursive:true,force:true});}
}
if(command==='seed') {await run(catalogSQL());console.log('Catálogo local sembrado.');}
else if(command==='account') {
  const accountId=option('--account');
  if(accountId && !/^[0-9a-f-]{36}$/.test(accountId)) throw new Error('Invalid account UUID');
  const credential=newCredential(accountId||undefined);
  await mkdir('.local/credentials',{recursive:true,mode:0o700});
  const filename=resolve('.local/credentials',credential.account_id+'-'+Date.now()+'.json');
  // Reserve the credential file before the database write; remove it if provisioning fails.
  await writeFile(filename,JSON.stringify(credential,null,2)+'\n',{mode:0o600,flag:'wx'});
  try {await run(credentialSQL(credential,!accountId));}catch(error){await rm(filename,{force:true});throw error;}
  console.log('Cuenta: '+credential.account_id+'\nCredencial (7 días): '+filename+'\nToken guardado con permiso 0600; no se imprime.');
} else if(command==='grant') {
  const account=option('--account'),item=option('--item');
  if(!account||!item) throw new Error('Use --account UUID --item inventory:id');
  await run([grantSQL(account,item)]);console.log('Cosmético concedido sólo en D1 local.');
} else if(command==='revoke') {
  const file=option('--credential');if(!file)throw new Error('Use --credential path');
  const credential=JSON.parse(await readFile(file,'utf8'));await run([revokeSQL(credential.token)]);console.log('Sesión local revocada.');
} else throw new Error('Use seed, account [--account UUID], grant --account UUID --item category:id, or revoke --credential path.');
