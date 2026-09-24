# Entorno Cloudflare de pruebas

Estado: **publicado en staging, con Workers Paid activado por el usuario** en [brasa-api-staging.acessloop.workers.dev](https://brasa-api-staging.acessloop.workers.dev/health). La autorización de Wrangler está completada. D1 `brasa-staging` (`9b3299f9-1c43-417e-9b02-28842b8e05a5`) tiene aplicadas las cinco migraciones: `0001_identity.sql`, `0002_auth.sql`, `0003_online_arena.sql`, `0004_validation_accounts.sql` y `0005_starter_expansions.sql`.

El usuario contrató **Workers Paid** y se confirmó en Cloudflare como plan actual. La nueva prueba remota terminó el **21 de septiembre de 2026 a las 03:48 UTC** —20 de septiembre en Ciudad de México— sobre la versión `3faaf02a-8427-4329-9ab8-7c8e50ef13ec`: **32/32 comprobaciones de acceso y 60/60 de juego y revocación**.

La **versión final publicada es `99077f34-8895-4b12-98ee-a3b692d8596e`**, con el mismo bundle y secreto, límite de CPU de `1000` ms por solicitud y muestreo de logs restaurado a `0.1`. Las versiones de prueba y final confirmaron remotamente `usage_model: standard` y `limits.cpu_ms: 1000`; `work/cloudflare-paid/version-settings-final.json` conserva la consulta final. El paquete ocupa 676.79 KiB comprimidos; los 102 ms de startup final no son CPU por solicitud.

| Comprobación en Paid | Resultado |
| --- | --- |
| HTTPS sobre la versión final | 5/5: salud, acceso, dispositivo, JavaScript y rechazo 401; `https-probes-final.json`. |
| Registro, inicio de sesión WebAuthn y autorización de dispositivo | 32/32. |
| Arena, Historia, progreso, reintentos, historial, defensa y revocación | 60/60. |
| Cuentas de esta ejecución | 2 cuentas QA nuevas, con 1 luchador, 24 cosméticos y 0 sesiones cada una. |
| Combates de esta ejecución | 1 Arena y 1 Historia, con resultados persistidos por el servidor. |
| Reconciliación D1 acumulada | 4 cuentas QA, 0 cuentas ordinarias y 0 sesiones QA. |
| CPU por solicitud configurada | 1000 ms; es un límite de ejecución, no un tope mensual de facturación. |

Los reportes de esta ejecución están en `work/cloudflare-paid/remote-provision.json`, `remote-verify.json` y `remote-db-reconciliation.json`. El cambio de plan y configuración conserva la aplicación y sus datos. La suite local de referencia sigue siendo 365/365; no se repitió por cambiar únicamente la configuración de despliegue.

Cambios locales posteriores en dos descripciones de auras y su bundle generado no están incluidos en esta publicación. El [informe](../../reports/CLOUDFLARE-STAGING.md) distingue sus fechas y hashes del snapshot desplegado.

Los estados HTTP esperados se comprobaron bajo Paid y su límite configurado. **No se obtuvo una nueva lectura de CPU por invocación en Paid**: el panel de Observability de Chrome no cargó durante los intentos de revisión. La prueba tampoco es una prueba de carga. Las mediciones Free se conservan a continuación como evidencia histórica y no se presentan como valores de Paid. El [informe de Cloudflare](../../reports/CLOUDFLARE-STAGING.md) conserva versiones, evidencia y esta limitación.

## Verificación anterior al cambio de plan

El smoke original terminó el 21 de septiembre de 2026 a las 03:27 UTC sobre la versión `ce9db916-5337-4c93-8724-fdaed84cca91`. La versión `0f3491e2-c017-402e-a39d-5ea7dff1aec0` cerró aquella publicación con el mismo bundle, la quinta migración y muestreo `0.1`. Los datos siguientes son históricos.

| Comprobación | Resultado |
| --- | --- |
| Suite local de la publicación final | 365 pruebas, 0 fallos, tras incorporar la quinta migración. La versión del smoke había pasado 360/360. |
| HTTPS, salud, origen, caché, UI y rechazo sin credencial | 5/5 antes del smoke y 5/5 repetidas sobre la versión final. |
| Registro, inicio de sesión WebAuthn y autorización de dispositivo | 32/32. |
| Arena, Historia, progreso, reintentos, historial, defensa y revocación | 60/60. |
| Reconciliación D1 final | 5 migraciones, expansión `cats-v1`, 2 cuentas QA con `is_test=1`, 24 cosméticos —incluidos Ónix y Bruma— y 1 luchador por cuenta, 1 combate de Arena y 1 de Historia; 0 sesiones y 0 jugadores ordinarios. |
| Catálogo publicado | 31 cosméticos, 24 iniciales; 15 personajes y 100 encuentros. |

Hash lógico/API del catálogo cosmético: `728f17d468b127d7d019e8513939e322ea6b5b03caa56f0dd27973697f99e43e`. Los reportes sin credenciales están en `work/cloudflare-deploy/https-probes-final.json`, `remote-provision.json`, `remote-verify.json` y `remote-db-reconciliation-final.json`, desde la raíz del workspace. `npm-test-release.log` registra la suite local final de 365 pruebas; `npm-test-final.log` conserva las 360 previas al smoke. Estas cifras describen esa revisión comprobada; no validan automáticamente cambios locales posteriores.

## Actualizar el staging existente

El Worker y D1 ya existen. Conservar el UUID de la base y el secreto de autenticación. No repetir `d1 create` ni generar otra clave para una actualización ordinaria. Desde `backend/`:

```sh
npx wrangler whoami
npm test
npm run catalog:check
npx wrangler d1 migrations apply DB --remote --config wrangler.staging.jsonc
npx wrangler deploy --dry-run --config wrangler.staging.jsonc
npx wrangler deploy --config wrangler.staging.jsonc
```

Antes de desplegar, revisar las migraciones nuevas y sincronizar el catálogo si cambió. La prueba remota original se ejecutó con las cuatro primeras migraciones. Después se aplicó `0005_starter_expansions.sql` en D1 remoto y se volvió a sembrar el catálogo con 35 sentencias correctas, incluido el registro de expansión `cats-v1`. Esta quinta migración registra expansiones de inventario entregadas y debe aplicarse antes de ejecutar la versión nueva de `catalogSQL()`.

Para sembrar el catálogo, exportar `catalogSQL()` de `scripts/admin.mjs` a un archivo temporal y ejecutarlo con `wrangler d1 execute DB --remote --config wrangler.staging.jsonc --file ARCHIVO.sql`. La versión nueva concede una sola vez los cuerpos gratuitos de Ónix y Bruma a las cuentas ya existentes; su registro evita reponerlos tras una revocación. No repone otros cosméticos ni concede premios de progreso. No sembrar usuarios, sesiones ni progreso de cliente.

### Secreto y observabilidad

El primer despliegue recibió `BETTER_AUTH_SECRET` mediante `wrangler deploy --secrets-file`, con un archivo privado fuera del repositorio, permisos 0600 y 48 bytes aleatorios criptográficos. El archivo temporal se eliminó al terminar. El valor sólo permanece como secret binding del Worker y no se entrega a Godot.

Las actualizaciones ordinarias usan `wrangler deploy --config wrangler.staging.jsonc`: heredan el secreto existente. No volver a ejecutar el generador del primer despliegue ni rotarlo sin una necesidad concreta. `AUTH_MODE=better_auth`, el origen HTTPS exacto y `nodejs_compat` permanecen configurados.

En la prueba de Paid se usó temporalmente `head_sampling_rate: 1.0`; la versión final `99077f34-8895-4b12-98ee-a3b692d8596e` restauró `0.1` y conserva `limits.cpu_ms: 1000`. Los logs de aplicación guardan ruta, método, estado, ID y duración de pared; esta última no mide CPU. No se registran cuerpos ni credenciales. No hay colas, cron, Durable Objects ni Workers auxiliares.

### Compatibilidad de migraciones

La primera aplicación remota de `0001_identity.sql` falló con `incomplete input`; se comprobó que la transacción se había revertido y no había tablas de juego. La ruta remota envía el SQL completo a la API de D1. Tres triggers que usaban `SELECT CASE WHEN EXISTS (...) THEN RAISE(...) END` se reescribieron como `SELECT RAISE(...) WHERE EXISTS (...)`, conservando condiciones y errores. Después se aplicaron las cuatro migraciones correctamente.

El splitter local de Wrangler ya aceptaba el SQL anterior; el fallo no se atribuye a ese parser. `tests/migrations.test.mjs` comprueba migraciones, propiedad, rollback e inmutabilidad. `work/cloudflare-deploy/migrations.log` conserva el resultado remoto exitoso.

## Provisionar otro entorno

Usar un nombre, configuración y base independientes. Verificar antes la cuenta con `wrangler whoami` y las bases con `wrangler d1 list`. Si es necesaria una autorización nueva, el flujo usado fue:

```sh
npx wrangler login --browser=false --use-keyring --scopes account:read user:read workers_scripts:write workers_tail:read d1:write
```

La credencial OAuth se conserva cifrada con el llavero de macOS. Crear D1 sólo si no existe, copiar el UUID devuelto a la configuración de ese entorno, aplicar todas sus migraciones y sembrar el catálogo canónico. El primer Worker requiere un secreto criptográfico de al menos 32 bytes, suministrado por un archivo privado temporal o por el mecanismo de secretos soportado por Wrangler. No incluir el valor en archivos del proyecto, argumentos impresos ni configuración del cliente.

## Repetir la prueba remota

`tests/remote-smoke.mjs` exige opt-in y un archivo de credenciales nuevo para cada ejecución:

```sh
node tests/remote-smoke.mjs --allow-remote --phase provision --credentials .local/staging-smoke-NUEVA-EJECUCION.json
# Marcar administrativamente sólo los dos account_id impresos como is_test=1.
node tests/remote-smoke.mjs --allow-remote --phase verify --credentials .local/staging-smoke-NUEVA-EJECUCION.json
```

El archivo se crea con permisos 0600 y no contiene claves privadas WebAuthn. La fase `verify` exige que el servidor confirme la marca de prueba antes de crear luchadores. Al terminar revoca las sesiones y retira los bearers del archivo. Las cuentas QA quedan separadas de rivales ordinarios. El usuario crea su passkey personal en su propio dispositivo, siguiendo [el acceso desde Godot](AUTH.md#entrar-desde-godot).

Revisar CPU real de registro y combate en Cloudflare después de cambios relevantes. Un resultado correcto de `npm test`, un dry-run o un benchmark local no sustituye esa medición. El usuario activó [Workers Paid, desde 5 USD al mes más uso adicional aplicable](https://developers.cloudflare.com/workers/platform/pricing/). El límite `limits.cpu_ms` acota CPU por solicitud: no es un presupuesto mensual ni un tope de facturación.

Fuentes: [Wrangler D1 y migraciones](https://developers.cloudflare.com/workers/wrangler/commands/d1/), [límites CPU y formas de medición](https://developers.cloudflare.com/workers/platform/limits/), [Workers Logs](https://developers.cloudflare.com/workers/observability/logs/workers-logs/).
