import {startRegistration,startAuthentication} from '@simplewebauthn/browser';
const $=id=>document.getElementById(id);
const code=(new URL(location.href).searchParams.get('user_code')||'').toUpperCase();
const hasCode=/^[A-Z2-9]{8}$/.test(code);
const invalidDevice=location.pathname==='/device'&&!hasCode;
let pending=false,current=null,state='checking',done=false,started=0;
// Bounded, local diagnostic categories only. No identity, URL, code, challenge or token.
const metrics=[];
function metric(event,category='') {metrics.push({event,category,milliseconds:started?Math.round(performance.now()-started):0});if(metrics.length>40)metrics.shift();window.dispatchEvent(new CustomEvent('brasa-auth-metric',{detail:metrics.at(-1)}));}
class FlowError extends Error {constructor(code,status=0){super('auth');this.code=code;this.status=status;}}
async function api(path,body) {
  let response;
  try {response=await fetch('/api/auth'+path,{method:body===undefined?'GET':'POST',credentials:'same-origin',headers:body===undefined?{}:{'Content-Type':'application/json'},body:body===undefined?undefined:JSON.stringify(body),redirect:'error',signal:AbortSignal.timeout(20000)});}catch{throw new FlowError('NETWORK');}
  let value;try{value=await response.json();}catch{throw new FlowError('INVALID_RESPONSE');}
  if(!response.ok)throw new FlowError(typeof value.code==='string'?value.code:typeof value.error==='string'?value.error:'FAILED',response.status);
  return value;
}
function cancelled(error){return ['NotAllowedError','AbortError'].includes(error.name)||['NotAllowedError','AbortError'].includes(error.cause?.name)||error.code==='ERROR_CEREMONY_ABORTED';}
function message(error){
  if(error.status===429)return 'Espera un momento antes de volver a intentarlo.';
  if(error.code==='NETWORK')return 'No pudimos conectar. Comprueba tu conexión y vuelve a intentarlo.';
  if(error.code==='FRESH_SESSION_REQUIRED')return 'Confirma tu acceso de nuevo para continuar.';
  if(error.code==='DEVICE_EXPIRED'||error.code==='expired_token')return 'Este acceso venció. Vuelve al juego para intentarlo de nuevo.';
  if(error.code==='UNSUPPORTED')return 'Este navegador no puede usar tu passkey. Abre Brasa en un navegador compatible.';
  return 'No pudimos completar el acceso. Puedes volver a intentarlo.';
}
function action(id,text,callback,visible=true){const button=$(id);button.hidden=!visible;button.textContent=text;button.onclick=callback;button.disabled=pending;}
function render(next=state){
  state=next;document.querySelector('.entry').setAttribute('aria-busy',String(pending||state==='checking'));
  for(const id of ['primary','secondary','recovery','security','device','keys','why'])$(id).hidden=true;
  $('footer').textContent='';$('status').textContent='';$('description').textContent='';
  $('eyebrow').textContent=state==='security'?'TU CUENTA':'EL PATIO TE ESPERA';
  if(state==='checking'){$('title').textContent='Entrando…';return;}
  if(invalidDevice){$('title').textContent='Volvamos al juego';$('description').textContent='Abre un nuevo acceso desde Brasa.';return;}
  if(state==='complete'){$('title').textContent='Tu lugar está listo';$('description').textContent='Vuelve a Brasa. Tu luchador te espera.';return;}
  if(state==='denied'){$('title').textContent='Acceso cancelado';$('description').textContent='Puedes volver al juego cuando quieras.';return;}
  if(state==='recover'){
    $('title').textContent='Volvamos al patio';$('description').textContent='Usa una passkey sincronizada o elige otro dispositivo en la ventana de tu navegador.';
    action('primary','Probar otra passkey',()=>run(async()=>{await signIn();render(current?'ready':'signin');metric('recovery_success');}));
    action('secondary','Volver',()=>render(current?'ready':'signin'));
    $('footer').textContent='Si perdiste todas tus passkeys, todavía no podemos recuperar esa cuenta. Tu nombre no sustituye tu acceso.';return;
  }
  if(state==='security'){
    $('title').textContent='Protege tu lugar';$('description').textContent='Guarda otra passkey para entrar desde más dispositivos.';
    $('keys').hidden=false;action('primary','Añadir una passkey',()=>run(addPasskey));
    action('secondary','Volver',()=>render('ready'));
    action('security','Cerrar sesión del navegador',()=>run(async()=>{await api('/sign-out',{});current=null;render('signin');}));
    $('footer').textContent='Cerrar esta sesión no borra tu cuenta ni las passkeys de tu dispositivo.';return;
  }
  if(state==='new'){
    $('title').textContent='Protege a tu luchador';$('description').textContent='Guarda tu acceso con este dispositivo.';
    action('primary','Empezar',()=>run(register));action('secondary','Ya tengo cuenta',()=>render('signin'));$('why').hidden=false;return;
  }
  if(current){
    $('title').textContent='Bienvenido de nuevo';$('description').textContent=current.user.name==='Viajero'?'Tu aventura continúa.':current.user.name;
    if(hasCode&&!done){$('device').hidden=false;$('code').textContent=code;action('primary','Entrar en este juego',()=>run(()=>decide('approve')));action('secondary','Cancelar',()=>run(()=>decide('deny')));}
    else{$('description').textContent='Vuelve al juego para continuar tu aventura.';action('primary','Cuenta y seguridad',()=>run(openSecurity));}
    action('security',hasCode?'Cuenta y seguridad':'Usar otra cuenta',hasCode?()=>run(openSecurity):()=>run(switchAccount));
    if(hasCode)action('recovery','Usar otra cuenta',()=>run(switchAccount));return;
  }
  $('title').textContent='Entra al mundo';$('description').textContent='Tu aventura continúa con tu dispositivo.';
  action('primary','Continuar',()=>run(async()=>{await signIn();render('ready');}));
  action('secondary','Soy nuevo en Brasa',()=>render('new'));action('recovery','No puedo entrar',()=>{metric('recovery_started');render('recover');});
}
async function run(action){
  if(pending)return;pending=true;started=performance.now();$('status').textContent='';document.querySelector('.entry').setAttribute('aria-busy','true');document.querySelectorAll('button').forEach(b=>b.disabled=true);
  try{await action();}catch(error){
    if(cancelled(error)){metric('login_cancelled');render();}
    else{metric('login_error_category',error.code==='NETWORK'?'network':error.status===429?'rate_limit':'unavailable');$('status').textContent=message(error);}
  }finally{pending=false;document.querySelector('.entry').setAttribute('aria-busy','false');document.querySelectorAll('button').forEach(b=>b.disabled=false);}
}
function supported(){if(!window.PublicKeyCredential||!isSecureContext)throw new FlowError('UNSUPPORTED');}
async function session(){current=await api('/get-session');return current;}
async function signIn(){
  supported();metric('login_started');const options=await api('/passkey/generate-authenticate-options');metric('passkey_prompt_started');
  const response=await startAuthentication({optionsJSON:options});await api('/passkey/verify-authentication',{response});await session();
  if(!current?.user)throw new FlowError('FAILED');metric('login_success');
}
async function register(){
  supported();const {context}=await api('/registration/nonce',{name:'Viajero'});
  const options=await api('/passkey/generate-register-options?context='+encodeURIComponent(context));metric('passkey_prompt_started');
  const response=await startRegistration({optionsJSON:options});await api('/passkey/verify-registration',{response,name:'Mi acceso a Brasa',createSession:true});await session();
  if(!current?.user)throw new FlowError('FAILED');metric('new_account_completed');render('ready');
}
async function decide(decision){
  if(!hasCode||done||!current?.user)throw new FlowError('FAILED');
  // Consent remains a separate explicit action AFTER authentication, never a load effect.
  const details=await api('/device?user_code='+encodeURIComponent(code));
  if(details.client_id!=='brasa-godot')throw new FlowError('FAILED');
  await api('/device/'+decision,{userCode:code});done=true;render(decision==='approve'?'complete':'denied');
}
async function switchAccount(){await api('/sign-out',{});current=null;render('signin');}
async function openSecurity(){
  if(!current?.user){render('signin');return;}
  const list=await api('/passkey/list-user-passkeys');$('keys').replaceChildren();
  for(const [i,key] of (Array.isArray(list)?list:[]).entries()){const row=document.createElement('li');row.textContent=key.name||`Passkey ${i+1}`;$('keys').append(row);}
  render('security');
}
async function addPasskey(){
  const owner=current?.user?.id;if(!owner)throw new FlowError('FAILED');
  await session();if(current?.user?.id!==owner)throw new FlowError('FAILED');
  if(Date.now()-new Date(current.session.createdAt).getTime()>240000){await signIn();if(current?.user?.id!==owner){render('ready');throw new FlowError('FAILED');}}
  const options=await api('/passkey/generate-register-options');metric('passkey_prompt_started');
  const response=await startRegistration({optionsJSON:options});await api('/passkey/verify-registration',{response,name:'Acceso adicional',createSession:true});await session();await openSecurity();$('status').textContent='Tu nuevo acceso está guardado.';
}
run(async()=>{await session();if(new URL(location.href).searchParams.get('screen')==='recovery')render('recover');else if(new URL(location.href).searchParams.get('screen')==='security'&&current?.user)await openSecurity();else render(current?.user?'ready':'signin');}).then(()=>{if(state==='checking'){render('signin');$('status').textContent='No pudimos conectar. Vuelve a intentarlo.';}});
