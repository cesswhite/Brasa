import {handleAuthRequest,authenticate} from '../src/auth.js';
export default {async fetch(request,env){try{
  const authResponse=await handleAuthRequest(request,env);if(authResponse)return authResponse;
  const session=await authenticate(request,env);
  return Response.json({data:session});
}catch(error){return Response.json({error:{code:error.code||'INTERNAL_ERROR',message:error.message}},{status:error.status||500});}}};
