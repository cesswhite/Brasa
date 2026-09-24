# Arena e Historia autoritativas

El servicio está publicado en [staging](https://brasa-api-staging.acessloop.workers.dev/health). El usuario activó Workers Paid, confirmado en Cloudflare. La nueva prueba remota de Arena e Historia pasó **60/60 comprobaciones**, precedida de **32/32 de acceso**, con dos cuentas QA nuevas separadas de los jugadores ordinarios y sesiones revocadas al terminar. La versión final es `99077f34-8895-4b12-98ee-a3b692d8596e`, con límite de CPU de 1000 ms por solicitud y muestreo `0.1`. [Estado y mediciones de Cloudflare](../../reports/CLOUDFLARE-STAGING.md).

## Flujo y límites de esta versión

Godot conserva Liga e Historia locales, con sus archivos y sistemas actuales. «Arena online» abre un perfil remoto nuevo, autenticado por passkey y autorización de dispositivo. No se importan estadísticas ni posesiones del cliente. El mismo luchador remoto comparte XP, nivel, inversión, técnicas, talentos y cosméticos entre Arena y los 100 encuentros de Historia.

Se mantiene el combate automático existente: el jugador elige luchador, build, estilo y rival; una solicitud resuelve el combate entero. El servidor controla ambos combatientes y Godot presenta sus eventos. Esta versión **no implementa selección manual de ataques ni rendición durante un combate activo**. No hay partida parcialmente resuelta que reanudar: un desafío confirmado tiene un resultado terminal. Cerrar la animación no cancela el resultado ni concede premios adicionales.

Los oponentes de Arena pertenecen a otras cuentas. No se crean bots de relleno ni combates espontáneos en segundo plano. La defensa offline ocurre cuando otro jugador solicita un desafío. Las cuentas administrativas de validación (`accounts.is_test=1`) sólo pueden verse y desafiarse entre ellas; el cliente no puede activar esa marca.

## Contrato HTTP

Autenticación: bearer de sesión obtenido por el flujo documentado en [AUTH.md](AUTH.md). Las rutas de juego no aceptan la cookie del navegador como autoridad. HTTPS en staging; loopback explícito sólo para pruebas locales. Cuerpos JSON de hasta 8192 bytes, claves desconocidas rechazadas, UUID y revisiones validados. Formato de respuesta: `{ "data": ... }`; errores: `{ "error": { "code", "message" }, "request_id" }`.

Toda mutación remota necesita `Idempotency-Key: UUID`. Reutilizarla con el mismo cuerpo devuelve el resultado de la operación; otro cuerpo obtiene 409. Los recibos no caducan en esta versión. La creación/PATCH de la antigua herramienta local mantiene su contrato sin cabecera.

| Ruta | Función y cuerpo |
| --- | --- |
| `GET /health` | Disponibilidad de D1/catálogo y versión del motor, sin credencial. |
| `GET /v1/me` | Identidad interna de la sesión. |
| `GET /v1/game/catalog` | Personajes, reglas de inversión, técnicas, talentos, estilos, capítulos y metadatos de los 100 encuentros. |
| `GET /v1/catalog`, `/v1/owned` | Catálogo cosmético versionado e inventario propio. |
| `GET /v1/fighters`, `/v1/fighters/:id` | Luchadores propios con progreso, revisiones, rating y descriptor visual. |
| `POST /v1/fighters` | `{archetype_id, display_name}`; un luchador por arquetipo y cuenta. |
| `PATCH /v1/fighters/:id` | `{expected_revision, display_name?, appearance?}`; usa `fighter.revision`, no la revisión de progreso. |
| `POST /v1/fighters/:id/allocate` | `{expected_revision, stat, amount}`; consume sólo puntos disponibles y rechaza lotes que sobrepasen el máximo. |
| `POST /v1/fighters/:id/ai` | `{expected_revision, style}`; siete estilos validados. |
| `POST /v1/fighters/:id/upgrade-move` | `{expected_revision, move_id}`; técnica desbloqueada, puntos y máximo de dos mejoras. |
| `POST /v1/fighters/:id/perk` | `{expected_revision, perk_id}`; talento del arquetipo, sin duplicados, máximo de tres. |
| `POST /v1/fighters/:id/respec` | `{expected_revision}`; devuelve puntos invertidos de estadísticas, técnicas y talentos. |
| `GET /v1/arena/opponents?fighter_id=UUID` | Hasta seis rivales reales cercanos en poder y rating; estado vacío honesto. |
| `POST /v1/battles` | `{fighter_id, opponent_id}`; combate Arena completo. |
| `GET /v1/story?fighter_id=UUID` | Próximo encuentro y capítulos. |
| `POST /v1/story/battles` | `{fighter_id, story_level?}`; por omisión siguiente encuentro; repetir uno superado es práctica sin XP. |
| `GET /v1/battles/:id` | Resultado, snapshots, semilla y eventos; sólo sus participantes. |
| `GET /v1/history?fighter_id=UUID&cursor=...` | Hasta 20 resúmenes y cursor estable; los eventos se descargan al abrir la pelea. |
| `GET /v1/arena/offline-results` | Resumen de resultados no vistos y hasta 20 avisos. |
| `POST /v1/arena/offline-results/ack` | `{ids:[UUID...]}`; marca hasta 50 avisos propios. No concede recompensas. |

Las mutaciones de build usan `fighter.progression_revision`. Ante 409 se recarga la ficha; no se inventa una revisión nueva ni se reenvía automáticamente una intención obsoleta. Ante timeout/JSON incompleto el cliente conserva la misma clave de operación en memoria. Si se cierra la aplicación, el historial y perfil recuperan lo confirmado; la sesión y la cola temporal no se escriben en texto plano.

## Motor, versiones y reproducción

`battle-engine/` no conoce HTTP, D1, UI ni sesiones. El catálogo se exporta de Godot, y corpus de combates reales comprueba PCG, números float32, eventos y estados contra el binario 4.7.2. Las fórmulas no se recalculan en la pantalla online. La semilla de 64 bits se genera con `crypto.getRandomValues` y se transporta como cadena decimal para no perder precisión JSON.

Cada combate almacena versión del motor/catálogo, ambos descriptores, semilla, resultado y eventos secuenciados. Los triggers impiden actualizar o borrar el registro de combate. Cambiar nombre, apariencia, puntos o estilo después no cambia ese registro. Reproducir usa eventos almacenados, sin volver a tirar azar ni conceder XP. Para una resimulación exacta de una versión antigua deben conservarse su código y catálogo; actualizar el motor no convierte los resultados históricos a la versión nueva.

Paridad y benchmark: [battle-engine/README.md](../battle-engine/README.md). Firma permanece aproximadamente al 1% **por combatiente/combate**, separada de los críticos ordinarios.

## Commit, carreras y antiabuso

`game_operations` tiene unicidad por cuenta/clave y hash de intención. El servidor lee perfiles, simula y construye una transacción D1 `batch`: recibo → combate inmutable → progreso de ambos → libro de recompensas → cosméticos ganados → aviso defensivo. Todas las escrituras dependen del mismo ID de mutación. El recibo sólo se inserta si siguen vigentes las revisiones y los contadores diarios usados para calcular premios. Una carrera recalcula con datos frescos hasta tres veces; si persiste devuelve 409 reintentable. Un error SQL revierte el batch completo.

XP y rating son independientes. Los parámetros están en `src/game/config.js`: cooldown de tres segundos, 45 nuevas mutaciones por minuto/cuenta, tres combates con rating por pareja de cuentas/día, XP de pareja agotada tras diez, primeras cinco defensas con XP completo y hasta veinte reducido, tope defensivo de 1200 XP y activo Arena de 12000 XP diarios. La XP de Historia no consume el tope de Arena. Aunque la XP se agote, se conserva el resultado y su historial. El límite de pareja abarca todos los luchadores de ambas cuentas.

El poder de matchmaking deriva de estadísticas, técnicas y talentos; no modifica el daño. Consultas indexadas toman candidatos por encima y debajo del poder propio y consideran rating. El rango permitido es 0.45–2.2 de poder relativo. El juego conserva su tope de nivel 50 y las reglas canónicas de crecimiento/desbloqueo. Los premios de hitos de Historia y los cosméticos sólo los acredita el servidor.

Los límites por cuenta y pareja reducen repetición y farming ordinario. No constituyen detección de cuentas coludidas ni verificación de identidad humana. No se añadieron Redis, colas, cron ni un servicio LLM para IA.

## Datos

Migraciones ordenadas:

1. `0001_identity.sql`: cuentas, credenciales locales, identidad/apariencia/progreso, catálogo, inventario y snapshots históricos de identidad.
2. `0002_auth.sql`: Better Auth, passkeys, device codes, nonces y límites de autenticación.
3. `0003_online_arena.sql`: rating/estilo/poder, operaciones, combates, libro de progreso, avisos y límites de juego.
4. `0004_validation_accounts.sql`: separación administrativa de cuentas de prueba.
5. `0005_starter_expansions.sql`: registro de expansiones iniciales entregadas, para no reponer una concesión revocada al volver a sembrar el catálogo. Aplicada en remoto después del smoke original, antes de la publicación final; el [registro de despliegue](DEPLOYMENT.md) distingue lo validado en cada versión.

Los documentos JSON almacenan valores acotados de build o snapshots/eventos inmutables; relaciones, propiedad, índices, recibos y recompensas permanecen normalizados. Los perfiles antiguos con poder cero se recalculan en lotes de hasta 32 al consultar rivales. Los archivos locales de Godot y su identidad no se sincronizan automáticamente con D1.

## Operación

La configuración local y la de staging son archivos distintos. No publicar `AUTH_MODE=local_dev`. La credencial Better Auth sólo reside en el secret binding del Worker; Godot contiene la URL pública. Los logs estructurados guardan ID, ruta, método, estado y duración de pared, no sesiones/cuerpos ni credenciales.

Los benchmarks de Node y V8 local no representan CPU facturada por Cloudflare. Las mediciones del smoke original en Free dieron 81 ms para Arena y 48 ms para Historia, además de varios accesos por encima de los [10 ms de aquel plan](https://developers.cloudflare.com/workers/platform/limits/). El usuario activó posteriormente Workers Paid; las muestras Free se conservan como evidencia histórica. El límite de CPU por solicitud no es un tope mensual de facturación. El paquete de aquella versión ocupó 676.79 KiB comprimidos. La repetición funcional sobre Paid pasó 32/32 comprobaciones de acceso y 60/60 de juego. No se obtuvo nueva CPU por invocación porque Observability no cargó en Chrome; no se trata de una prueba de carga. Véase el [informe de Cloudflare](../../reports/CLOUDFLARE-STAGING.md).
