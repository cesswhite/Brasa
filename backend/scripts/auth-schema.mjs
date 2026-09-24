// Generates the pinned Better Auth schema in an isolated, ephemeral D1. Never runs against a deployed database.
import {Miniflare} from 'miniflare';
import {getMigrations} from 'better-auth/db/migration';
import {authOptions} from '../src/auth/config.js';
const mf=new Miniflare({modules:true,compatibilityDate:'2026-07-08',script:'export default {fetch(){return new Response()}}',d1Databases:['DB']});
try {
  const DB=await mf.getD1Database('DB');
  const plan=await getMigrations(authOptions({DB,AUTH_MODE:'better_auth',BETTER_AUTH_URL:'http://localhost:8787',BETTER_AUTH_SECRET:'schema-only-ephemeral-not-production-credential'}));
  const sql=await plan.compileMigrations();
  // Print for review; do not overwrite the application tables appended to 0002.
  process.stdout.write(sql);
} finally {await mf.dispose();}
