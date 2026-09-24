import {generateKeyPairSync,randomBytes,createHash,sign} from 'node:crypto';
import {fixture} from './helpers.mjs';
export const ORIGIN='https://brasa-api-staging.acessloop.workers.dev';
export const CLIENT='brasa-godot';
export async function authFixture(path,initialize=true,bindings){const authBindings=bindings||{AUTH_MODE:'better_auth',BETTER_AUTH_URL:ORIGIN,BETTER_AUTH_SECRET:'disposable-auth-test-secret-'+randomBytes(32).toString('hex')};return {...await fixture(path,initialize,authBindings,{scriptPath:'dist/auth-test-worker.js'}),authBindings};}
export function browser(mf,defaultHeaders={}){
  const jar=new Map();
  return {jar,async call(path,body,{origin=ORIGIN,headers={},method=body===undefined?'GET':'POST'}={}){
    const requestHeaders={...(origin?{Origin:origin}:{}),...defaultHeaders,...headers};
    if(body!==undefined)requestHeaders['Content-Type']='application/json';
    if(jar.size)requestHeaders.Cookie=[...jar].map(([key,value])=>key+'='+value).join('; ');
    const response=await mf.dispatchFetch(ORIGIN+path,{method,headers:requestHeaders,body:body===undefined?undefined:JSON.stringify(body)});
    for(const cookie of response.headers.getSetCookie()){const pair=cookie.split(';')[0];const at=pair.indexOf('=');if(at>0)jar.set(pair.slice(0,at),pair.slice(at+1));}
    const text=await response.text();let data;try{data=JSON.parse(text)}catch{data=text;}
    return {status:response.status,data,headers:response.headers};
  }};
}
const hash=value=>createHash('sha256').update(value).digest();
function cbor(value) {
  const header=(major,size)=>size<24?Buffer.from([(major<<5)|size]):size<256?Buffer.from([(major<<5)|24,size]):Buffer.from([(major<<5)|25,size>>8,size&255]);
  if(typeof value==='number')return value>=0?header(0,value):header(1,-value-1);
  if(typeof value==='string'){const bytes=Buffer.from(value);return Buffer.concat([header(3,bytes.length),bytes]);}
  if(Buffer.isBuffer(value))return Buffer.concat([header(2,value.length),value]);
  if(value instanceof Map)return Buffer.concat([header(5,value.size),...[...value].flatMap(([key,item])=>[cbor(key),cbor(item)])]);
  throw new Error('Unsupported fixture CBOR');
}
export function authenticator() {
  const {privateKey,publicKey}=generateKeyPairSync('ec',{namedCurve:'prime256v1'});
  const jwk=publicKey.export({format:'jwk'}),id=randomBytes(32),rpHash=hash(new URL(ORIGIN).hostname);let counter=0;
  return {id:id.toString('base64url'),registration(options,{uv=true,origin=ORIGIN}={}){
    const authData=Buffer.concat([rpHash,Buffer.from([uv?0x45:0x41]),Buffer.alloc(4),Buffer.alloc(16),Buffer.from([0,id.length]),id,cbor(new Map([[1,2],[3,-7],[-1,1],[-2,Buffer.from(jwk.x,'base64url')],[-3,Buffer.from(jwk.y,'base64url')]]))]);
    const clientData=Buffer.from(JSON.stringify({type:'webauthn.create',challenge:options.challenge,origin,crossOrigin:false}));
    return {id:id.toString('base64url'),rawId:id.toString('base64url'),type:'public-key',response:{clientDataJSON:clientData.toString('base64url'),attestationObject:cbor(new Map([['fmt','none'],['attStmt',new Map()],['authData',authData]])).toString('base64url'),transports:['internal']},clientExtensionResults:{},authenticatorAttachment:'platform'};
  },assertion(options,{uv=true,origin=ORIGIN}={}){
    const count=Buffer.alloc(4);count.writeUInt32BE(++counter);
    const authData=Buffer.concat([rpHash,Buffer.from([uv?5:1]),count]);
    const clientData=Buffer.from(JSON.stringify({type:'webauthn.get',challenge:options.challenge,origin,crossOrigin:false}));
    return {id:id.toString('base64url'),rawId:id.toString('base64url'),type:'public-key',response:{clientDataJSON:clientData.toString('base64url'),authenticatorData:authData.toString('base64url'),signature:sign('sha256',Buffer.concat([authData,hash(clientData)]),privateKey).toString('base64url'),userHandle:null},clientExtensionResults:{},authenticatorAttachment:'platform'};
  }};
}
export async function registrationOptions(client,name='Luna Brasa') {
  const nonce=await client.call('/api/auth/registration/nonce',{name});
  if(nonce.status!==200)throw new Error('Nonce: '+JSON.stringify(nonce));
  const options=await client.call('/api/auth/passkey/generate-register-options?context='+encodeURIComponent(nonce.data.context));
  if(options.status!==200)throw new Error('Options: '+JSON.stringify(options));
  return {context:nonce.data.context,options:options.data};
}
export async function register(client,key=authenticator(),name='Luna Brasa') {
  const {options}=await registrationOptions(client,name);
  const result=await client.call('/api/auth/passkey/verify-registration',{response:key.registration(options),name:'Fixture passkey',createSession:true});
  if(result.status!==200)throw new Error('Registration: '+JSON.stringify(result));
  return {key,result};
}
