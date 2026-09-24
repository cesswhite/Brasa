import {readFile} from 'node:fs/promises';
const args=process.argv.slice(2),option=name=>{const i=args.indexOf(name);return i<0?null:args[i+1];};
const file=option('--credential'),path=option('--path'),method=option('--method')||'GET';
if(!file||!path?.startsWith('/v1/')||path.includes('://')||path.includes('\\')||!['GET','POST','PATCH'].includes(method)) throw new Error('Use --credential local.json --path /v1/... [--method GET|POST|PATCH] [--body-file JSON]');
const {token}=JSON.parse(await readFile(file,'utf8'));
const bodyFile=option('--body-file');
const response=await fetch('http://127.0.0.1:8787'+path,{method,redirect:'error',headers:{Authorization:'Bearer '+token,'Content-Type':'application/json'},...(bodyFile?{body:await readFile(bodyFile,'utf8')}:{})});
console.log(response.status,JSON.stringify(await response.json(),null,2));
if(!response.ok)process.exitCode=1;
