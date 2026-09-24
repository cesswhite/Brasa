import {build} from 'esbuild';
await import('./auth-art.mjs');
await build({entryPoints:['web/client.js'],bundle:true,format:'esm',platform:'browser',target:'es2022',outfile:'web/client.bundle.js',minify:true});
const options={bundle:true,format:'esm',platform:'browser',target:'es2022',external:['node:*'],loader:{'.html':'text'},plugins:[{name:'browser-source',setup(builder){builder.onLoad({filter:/client\.bundle\.js$/},async args=>({contents:await(await import('node:fs/promises')).readFile(args.path,'utf8'),loader:'text'}));}}]};
if(!process.argv.includes('--auth-only'))await build({...options,entryPoints:['src/worker.js'],outfile:'dist/worker.js'});
await build({...options,entryPoints:['tests/auth-worker.mjs'],outfile:'dist/auth-test-worker.js'});
