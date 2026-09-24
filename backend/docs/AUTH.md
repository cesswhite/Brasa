# Acceso con passkey y código de dispositivo

Implementación fijada a `better-auth 1.7.5` y `@better-auth/passkey 1.7.5`, con D1 nativo. El navegador realiza WebAuthn; Godot recibe una sesión opaca por autorización de dispositivo. No se habilitan contraseñas, cuentas anónimas, SMTP, proveedores OAuth ni importación de partidas locales.

El usuario activó **Workers Paid**, confirmado como plan actual en Cloudflare. El acceso se volvió a verificar en [staging](https://brasa-api-staging.acessloop.workers.dev/auth): **32/32 comprobaciones remotas de registro, inicio de sesión y autorización de dispositivo**, seguidas de **60/60 de juego y revocación**, con `limits.cpu_ms: 1000`. La versión final es `99077f34-8895-4b12-98ee-a3b692d8596e`, con el mismo bundle y secreto, y muestreo `0.1`. El [informe de Cloudflare](../../reports/CLOUDFLARE-STAGING.md) registra la evidencia y distingue las mediciones históricas Free de la nueva verificación funcional Paid.

## Entrar desde Godot

1. Abre `Jugar online.command` o **Arena online** en el menú y pulsa **Iniciar sesión en el navegador**.
2. En la primera visita, escribe **Nombre de la cuenta**, pulsa **Crear cuenta con passkey** y confirma con la huella, rostro o PIN que pida tu dispositivo. Si ya existe la cuenta, pulsa **Entrar con mi passkey**.
3. Compara el código del navegador con Godot y pulsa **Autorizar este dispositivo**. Crear la cuenta o iniciar sesión no autoriza por sí solo el juego.
4. Vuelve a Godot; la sesión se recoge automáticamente. Elige la base de combate, escribe **Nombre de tu luchador** y pulsa **Crear luchador**.
5. Puedes entrar en **Historia** aunque no haya rivales públicos. Arena muestra únicamente otros jugadores disponibles; las cuentas QA permanecen separadas.

Abrir `/auth` directamente permite gestionar el acceso, pero no conecta Godot sin el código iniciado desde el juego. La passkey personal la crea el usuario en su dispositivo; el panel ofrece **Añadir una segunda passkey**. El progreso online se guarda en el servidor y no importa la partida local.

## Configuración

El entorno en línea requiere:

```json
{
  "compatibility_date": "2026-07-08",
  "compatibility_flags": ["nodejs_compat"],
  "vars": {
    "AUTH_MODE": "better_auth",
    "BETTER_AUTH_URL": "https://brasa-api-staging.acessloop.workers.dev"
  }
}
```

`BETTER_AUTH_SECRET` se proporciona mediante un secret binding, generado con al menos 32 bytes aleatorios; nunca se guarda en el repositorio ni se entrega al juego. El binding D1 se llama `DB`. Aplicar las migraciones versionadas y sembrar el catálogo antes de admitir usuarios. `0002_auth.sql` contiene el esquema de Better Auth, enlaces a cuentas, nonces de registro y límites de solicitudes.

`AUTH_MODE=local_dev` conserva el adaptador anterior exclusivamente en loopback. Los tokens `brasa_local_*` no son credenciales en línea. La compatibilidad Node también es necesaria al cargar el nuevo bundle en desarrollo local. Una configuración ausente o débil devuelve 503; un origen distinto del configurado devuelve 403.

En `worker.js`, llamar `handleAuthRequest(request, env)` antes de `authenticate`; una respuesta no nula ya corresponde al servicio de acceso. `authenticate` devuelve `{account_id, auth_user_id}` en modo Better Auth y conserva `{account_id}` en modo local.

## Navegador

`GET /auth` muestra creación e inicio de sesión. `GET /device?user_code=ABCDEFGH` muestra el código recibido del juego y botones separados para autorizar o rechazar. Abrir la página o iniciar sesión no aprueba la solicitud.

1. `POST /api/auth/registration/nonce` recibe `{name}` y devuelve un contexto firmado con cinco minutos de vigencia.
2. El cliente obtiene las opciones de registro y ejecuta WebAuthn. El servidor verifica challenge, origen, RP ID y verificación del usuario.
3. Sólo después de una ceremonia válida se consume el nonce una vez y se crea el usuario. Al almacenar la passkey y crear su sesión, un lote D1 crea una cuenta de juego y el inventario inicial del catálogo canónico —24 cosméticos en esta versión—, de forma idempotente.

La columna email requerida por el esquema de Better Auth usa un identificador interno `UUID@passkey.brasa.invalid`; no identifica una dirección real, no se considera verificada y no habilita recuperación ni vinculación por correo. Los UUID del juego se enlazan al usuario de autenticación; ningún nombre otorgado por el cliente identifica a otra cuenta.

La página permite añadir una segunda passkey. El servidor exige una sesión creada en los últimos cinco minutos para añadir credenciales. No hay borrado público de passkeys ni recuperación por un secreto administrativo compartido. Sin una passkey disponible no hay recuperación implementada; debe conservarse una passkey sincronizada o una segunda credencial.

## Contrato Godot

| Operación | Petición | Respuesta |
|---|---|---|
| Solicitar código | `POST /api/auth/device/code`, `{client_id:"brasa-godot"}` | `device_code`, `user_code`, `verification_uri`, `verification_uri_complete`, `expires_in:600`, `interval:5` |
| Consultar autorización | `POST /api/auth/device/token`, `{grant_type:"urn:ietf:params:oauth:grant-type:device_code",device_code,client_id:"brasa-godot"}` | `access_token`, `token_type:"Bearer"`, `expires_in`, `scope:""` |
| Usar API | `Authorization: Bearer <access_token>` | Contrato `/v1/*` existente |
| Desconectar | `POST /api/auth/sign-out`, cuerpo `{}`, bearer | Revoca esa sesión |

Los errores de dispositivo son HTTP 400 con `{error,error_description}`: `authorization_pending`, `slow_down`, `expired_token`, `access_denied`, `invalid_grant` o `invalid_request`. Respetar el intervalo; ante `slow_down`, aumentarlo al menos cinco segundos. Cancelar el flujo descarta respuestas tardías. No registrar códigos ni tokens. `client_id` es público; sólo identifica la aplicación y no sirve como contraseña.

Godot debe validar HTTPS, host y ruta de la URL de verificación antes de abrirla; no debe seguir redirecciones de llamadas API. En macOS, el bearer se guarda en Keychain mediante el helper firmado de `native/macos`; se valida contra `/api/auth/get-session` antes de restaurar la cuenta. El archivo local de presentación no contiene credenciales. En plataformas sin adaptador seguro el bearer permanece sólo en memoria. No se requieren cookies en Godot. Este flujo devuelve una sesión de Better Auth, no un JWT OAuth ni un refresh token OAuth.

## Controles

- RP ID y origen exactos, cookies seguras, comprobaciones de origen/CSRF conservadas y CSP de la página sin scripts externos.
- La API de juego exige bearer: una cookie de navegador por sí sola no permite ejecutar acciones de juego; una cookie válida tampoco rescata un bearer inválido.
- El plugin solicita `userVerification:"required"`. Además, ambos callbacks del servidor rechazan `userVerified=false`: la versión 1.7.5 verifica internamente con `requireUserVerification:false`, por lo que pedirlo sólo al navegador sería insuficiente.
- El nonce firmado se consume mediante comparación y actualización en D1. Los credential IDs tienen un índice único. No se concede una cuenta de juego sin una passkey almacenada.
- El wrapper HTTP aplica límites atómicos en D1, por IP de Cloudflare y minuto: cinco registros, diez códigos de dispositivo, treinta consultas de token y sesenta solicitudes generales. Devuelve 429 y `Retry-After:60`. El limitador en memoria de Better Auth está deshabilitado porque el wrapper protege las rutas expuestas, incluidos los endpoints personalizados.
- Se rechaza `user_id` en la solicitud pública de dispositivo. Un código aprobado sólo puede canjearse una vez; la sesión que reclama el código debe ser la que lo apruebe.
- Los logs del proveedor emiten una marca genérica, sin credenciales, cuerpos ni excepciones que puedan contenerlos. Las respuestas de acceso no se almacenan en caché.

## Pruebas y rendimiento

`node scripts/build.mjs --auth-only` reconstruye únicamente el Worker aislado de pruebas de acceso. `node --test tests/auth.test.mjs` verifica ocho grupos con respuestas WebAuthn firmadas y una base D1 temporal real: alta, biometría/PIN obligatorio, origen, nonces, doble canje, aislamiento de usuarios, rechazo/expiración, revocación, segunda passkey, sesión reciente, persistencia y límites concurrentes. No utiliza un endpoint de bypass ni sesiones sembradas para iniciar la prueba.

Resultado de la entrega inicial de acceso: **8 tests aprobados, 0 fallos**, log `work/identity/auth-tests.log` desde la raíz del workspace. La suite completa que incluye los tests de acceso pasó **360/360** antes del smoke remoto (`work/cloudflare-deploy/npm-test-final.log`) y **365/365** tras incorporar la quinta migración (`work/cloudflare-deploy/npm-test-release.log`). Los tests usan archivos temporales propios y no acceden a la partida ni a las credenciales personales.

Wrangler `4.110.0` y Miniflare `4.20260708.1` se mantienen fijados. Overrides concretos: `undici 7.29.0` y `sharp 0.35.4`; `npm audit` termina sin alertas en `work/identity/auth-npm-audit.json`.

La primera medición con el profiler V8 de workerd local se conserva en `work/identity/auth-local-profile.json`. Encontró aproximadamente 1.9–4.5 ms activos en API autenticada caliente, 5 ms en código de dispositivo, 16.7 ms en registro de passkey y 39 ms entre nonce/opciones del primer acceso. Son muestras locales con instrumentación, **no CPU facturada por Cloudflare ni prueba de cumplimiento del límite Free de 10 ms**. La medición remota posterior confirmó solicitudes de acceso por encima de ese límite; véanse los resultados reales a continuación. No se redujo la seguridad criptográfica para alterar esos valores. Posteriormente el usuario activó Workers Paid.

La segunda medición separa ambas solicitudes y se conserva en `work/identity/auth-local-profile-warm.json`. Primer nonce: 4.94 ms; primeras opciones: 27.77 ms. En 20 muestras calientes por operación:

| Operación | Mediana local | p95 de la muestra local |
|---|---:|---:|
| Nonce | 3.20 ms | 3.87 ms |
| Opciones WebAuthn | 4.67 ms | 6.16 ms |
| Verificar registro | 8.47 ms | 10.72 ms |

El pico inicial proviene principalmente de la inicialización de opciones; la verificación caliente también queda cerca del límite y algunas muestras lo superan. La muestra pequeña de una máquina local no representa el p95 del servicio desplegado. El script de profiling ahora guarda la medición separada en el archivo `*-warm.json` y mantiene la captura inicial como referencia.

## CPU histórica en Workers Free

Antes de activar Paid, la versión de smoke `ce9db916-5337-4c93-8724-fdaed84cca91` produjo las siguientes muestras de CPU por solicitud en las dos cuentas QA. Son mediciones de Cloudflare, distintas de la duración de pared de los logs de aplicación y de los perfiles locales anteriores.

| Operación | Cuenta A | Cuenta B |
| --- | ---: | ---: |
| Nonce de registro | 7 ms | 5 ms |
| Opciones de registro WebAuthn | 46 ms | 15 ms |
| Verificación de registro | 29 ms | 35 ms |

El registro consolidado contiene 11 invocaciones críticas de registro y combate, 9 por encima de 10 ms. Todas terminaron con `outcome=ok`, incluido el rechazo deliberado HTTP 422 de una petición que declaraba al ganador. La prueba obtuvo los estados HTTP esperados, pero estas muestras no permiten anunciar estabilidad con el límite de [10 ms del plan Free](https://developers.cloudflare.com/workers/platform/limits/). Arena y Historia también lo superaron: 81 ms y 48 ms, respectivamente. Una revisión acotada no encontró un cambio pequeño demostrado que garantice cumplirlo. El usuario contrató posteriormente [Workers Paid, desde 5 USD al mes más uso adicional aplicable](https://developers.cloudflare.com/workers/platform/pricing/), y se confirmó que es el plan actual. No se ha reducido la seguridad criptográfica. El [informe de Cloudflare](../../reports/CLOUDFLARE-STAGING.md) conserva la evidencia. La versión `0f3491e2-c017-402e-a39d-5ea7dff1aec0` cerró aquella validación con el mismo bundle y secreto, y muestreo restaurado a `0.1`. La prueba funcional posterior sobre Paid pasó 32/32 comprobaciones de acceso y 60/60 de juego. No se obtuvo una nueva lectura de CPU por invocación porque el panel de Observability no cargó; los valores de esta tabla siguen siendo exclusivamente históricos. No se realizó una prueba de carga. El límite Paid configurado de 1000 ms es por solicitud y no constituye un tope mensual de facturación.

## Prueba remota en dos fases

La ejecución sobre Paid terminó el 21 de septiembre de 2026 a las 03:48 UTC con **32/32 comprobaciones de acceso y 60/60 de juego**, en la versión `3faaf02a-8427-4329-9ab8-7c8e50ef13ec`. Sus dos cuentas QA nuevas terminaron con un luchador, 24 cosméticos y cero sesiones cada una; se guardaron un combate de Arena y uno de Historia. D1 contiene ahora cuatro cuentas QA acumuladas y cero cuentas ordinarias; no quedan sesiones QA. Los reportes están en `work/cloudflare-paid/remote-provision.json`, `remote-verify.json` y `remote-db-reconciliation.json`.

La prueba anterior en Free también pasó 32/32 y 60/60; sus reportes permanecen en `work/cloudflare-deploy/`. Son ejecuciones separadas, con cuentas QA diferentes.

`tests/remote-smoke.mjs` no forma parte de `npm test` y no realiza ninguna solicitud sin `--allow-remote`. Sólo acepta el origen staging fijo. Ejecutarlo únicamente tras la autorización del responsable del despliegue:

```sh
node tests/remote-smoke.mjs --allow-remote --phase provision --credentials .local/staging-smoke.json
```

La primera fase crea dos cuentas identificadas `QA Brasa A/B`, registra passkeys, verifica una firma EC de inicio de sesión, completa device authorization y guarda exclusivamente sus bearers e IDs en un archivo 0600. Las claves privadas permanecen en memoria y se descartan. Se cierra la sesión de navegador. **Todavía no crea luchadores ni combates.**

El administrador debe marcar esas dos cuentas `is_test=1` mediante D1 y después ejecutar:

```sh
node tests/remote-smoke.mjs --allow-remote --phase verify --credentials .local/staging-smoke.json
```

La segunda fase exige que `/v1/me` confirme `is_test` en ambas cuentas y que no tengan luchadores previos. Comprueba perfiles, cambios cosméticos, asignación, Arena y Story reales, reintentos idempotentes, defensa offline, historial inmutable y revocación. No fuerza ganadores ni concede XP mediante fixtures remotos. Al finalizar revoca ambos bearers y los elimina del archivo; si no logra confirmar una revocación, conserva la credencial privada para intervención administrativa. Los reportes y logs contienen estados/IDs, nunca tokens o claves.

`tests/auth-remote-smoke.test.mjs` comprueba las dos fases contra una base D1 temporal interceptando todos los `fetch` antes de importar el script: **ninguna solicitud de ese test llega a staging**. También comprueba que una cuenta sin la marca de prueba no puede continuar. El workflow local pasó: log `work/identity/auth-remote-harness.log`.

## Fuentes oficiales consultadas

- [Better Auth: soporte D1 nativo](https://better-auth.com/blog/1-5).
- [Better Auth: passkeys, registro sin sesión y callbacks](https://better-auth.com/docs/plugins/passkey).
- [Better Auth: autorización de dispositivo](https://better-auth.com/docs/plugins/device-authorization).
- [Better Auth: bearer](https://better-auth.com/docs/plugins/bearer).
- [Better Auth: seguridad y comprobación de origen](https://better-auth.com/docs/reference/security).
- [Cloudflare: transacciones con D1.batch](https://developers.cloudflare.com/d1/worker-api/d1-database/#batch).
- [Cloudflare: compatibilidad Node](https://developers.cloudflare.com/workers/runtime-apis/nodejs/).
- [Cloudflare: límites y CPU](https://developers.cloudflare.com/workers/platform/limits/).

Las APIs y la comprobación de verificación del usuario también se contrastaron con el código instalado de las versiones fijadas. `scripts/auth-schema.mjs` imprime el SQL generado para revisión; no sobrescribe las tablas adicionales de la migración ni toca D1 remoto.


### Experiencia de entrada actual (21 septiembre 2026)

Una acción primaria por pantalla, sin nombre de cuenta ni correo obligatorios. El nombre del luchador se elige después en el juego. La confirmación explícita del código de dispositivo permanece obligatoria. Cancelar el prompt vuelve a Continuar sin alerta. Recuperación y segunda passkey están en rutas secundarias; añadir otra credencial conserva la exigencia de sesión reciente y mismo propietario.

`/auth/art/` sirve las copias verificadas del fondo, Nima, materiales compartidos y tokens. La CSP permite estos estilos únicamente desde el mismo origen. El helper de Keychain debe incluirse y firmarse dentro de la distribución macOS; el binario actual sirve al entorno de desarrollo. El cierre de sesión deja primero una marca local de no-restauración para que un fallo de borrado no reactive una sesión. Métricas locales: categorías y tiempos, sin tokens ni identificadores.

Ver `reports/AUTH-EXPERIENCE.md` y `work/auth-experience` para pruebas y capturas con fixtures.
