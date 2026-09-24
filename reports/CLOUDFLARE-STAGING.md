# Brasa en Cloudflare · 20 de septiembre de 2026

**Workers Paid está activo, comprado por el usuario y confirmado en Cloudflare.** El servidor de pruebas está publicado con un límite de **1.000 ms de CPU por petición**. Se repitieron y aprobaron las 92 comprobaciones remotas de acceso y juego, además de cinco comprobaciones HTTPS. El modelo `standard` y el límite se consultaron directamente a Cloudflare tras el despliegue final.

Servicio: [brasa-api-staging.acessloop.workers.dev](https://brasa-api-staging.acessloop.workers.dev/health). El juego ya utiliza este origen HTTPS. [Evidencia estructurada, versiones, IDs y resultados](cloudflare-staging-validation.json).

## Publicación verificada

| Recurso | Estado |
| --- | --- |
| Worker | `brasa-api-staging` |
| Versión final con Paid | `99077f34-8895-4b12-98ee-a3b692d8596e` |
| Versión de las pruebas remotas con Paid | `3faaf02a-8427-4329-9ab8-7c8e50ef13ec` |
| Versión histórica de las mediciones CPU con Free | `ce9db916-5337-4c93-8724-fdaed84cca91` |
| Código Worker | Mismo bundle que la suite local aprobada; SHA-256 `d856f319739893b4147364ac781eb937626ae727b4f76dd5825034dcda1037b0` |
| Capacidad | Modelo `standard`, máximo CPU por petición `1000 ms`, confirmado por la API de versiones |
| D1 | `brasa-staging` · `9b3299f9-1c43-417e-9b02-28842b8e05a5` |
| Migraciones | `0001`–`0005`, aplicadas y comprobadas en remoto |
| Catálogo | 15 personajes, 100 encuentros, 31 cosméticos, 24 iniciales |
| Muestreo de logs | 100 % durante las pruebas; restaurado a 10 % |
| Secreto de Better Auth | Generado en archivo temporal privado, cargado y retirado del disco; conservado entre versiones |

La primera migración necesitó una escritura SQL equivalente para tres triggers: `SELECT RAISE(...) WHERE EXISTS(...)`. La ruta remota rechazaba `CASE ... END`; sus condiciones de propiedad no cambiaron. Se verificó la reversión del intento fallido antes de aplicar las migraciones. La quinta migración registra la entrega única de Ónix y Bruma a cuentas existentes; la siembra final preservó sus inventarios de 24 elementos.

## Resultados

| Comprobación | Resultado |
| --- | --- |
| Backend local de la revisión publicada | 365 pruebas, 0 fallos ni omisiones; fuentes y bundle idénticos, sin repetir la suite por el cambio de plan |
| HTTPS tras la publicación final | 5/5: salud, acceso, dispositivo, JavaScript y rechazo 401 |
| Acceso remoto | 32/32: registro WebAuthn, login con firma EC, autorización del dispositivo y sesión nativa |
| Juego remoto | 60/60: creación, inventario, permisos, progreso, Arena, Historia, historial, defensa offline y revocación |
| Reintentos | Misma creación y batalla; sin duplicar XP, historial ni defensa |
| Reconciliación D1 | Cuatro cuentas QA en total; la última pareja tiene un luchador por cuenta, un combate de Arena y uno de Historia |
| Limpieza de acceso | Cero sesiones activas de prueba; ambos tokens revocados y retirados del archivo privado |

Las dos cuentas nuevas se marcaron administrativamente `is_test=1` antes de crear luchadores. No participan en el matchmaking público. La reconciliación encontró cero cuentas ordinarias y cero sesiones activas entre las cuatro cuentas QA. Las claves privadas WebAuthn de prueba existieron únicamente en memoria. La passkey personal del usuario se crea en su propio dispositivo.

La primera prueba con Free se ejecutó con cuatro migraciones; después se aplicó la quinta. La nueva prueba con Paid se ejecutó con las cinco migraciones y el límite de CPU confirmado. Las 92 comprobaciones terminaron el 21 de septiembre de 2026 a las 03:48 UTC —20 de septiembre en Ciudad de México—. Tras restaurar el muestreo a 10 %, se repitieron las cinco comprobaciones HTTPS y se consultaron modelo, límite y secret binding de la versión final. [Evidencia de esta ejecución](../../../work/cloudflare-paid/remote-verify.json).

La versión final se creó a las 03:50:02 UTC. Después, otro trabajo local actualizó el catálogo cosmético y reconstruyó `dist/worker.js` a las 03:52:36 UTC. Esos archivos posteriores no forman parte de esta publicación ni de sus resultados; el informe identifica el hash del bundle efectivamente validado y desplegado. [Comparación y fechas](../../../work/cloudflare-paid/drift-investigation.json).

## CPU: medición histórica y configuración actual

Los siguientes valores corresponden a la primera ejecución con **Free**. Se observaron en las columnas nativas `$workers.cpuTimeMs` del panel de Cloudflare, no en la duración de pared del log de aplicación. No son mediciones del plan Paid:

| Operación | CPU |
| --- | --- |
| Nonce de registro A / B | 7 / 5 ms |
| Opciones de registro A / B | 46 / 15 ms |
| Verificación de registro A / B | 29 / 35 ms |
| Rechazo del ganador enviado por el cliente | 15 ms |
| Arena original / reintento | 81 / 12 ms |
| Historia original / reintento | 48 / 13 ms |

Las once invocaciones terminaron con `outcome=ok`, incluido el rechazo HTTP 422 intencional. Es una muestra pequeña de dos cuentas: no demuestra un percentil de servicio ni identifica qué isolate estaba caliente. Cloudflare admite excedentes ocasionales, pero eso no garantiza operación sostenida bajo el [límite Free de 10 ms](https://developers.cloudflare.com/workers/platform/limits/). [Mediciones y correlación sanitizada](../../../work/cloudflare-deploy/CPU-OBSERVATION.md).

La revisión del código no encontró una optimización pequeña con evidencia suficiente para llevar todas las rutas por debajo de 10 ms. La instancia de Better Auth ya se reutiliza; cambiar su manejo de contexto o revocación para ahorrar CPU requiere un trabajo específico y nueva validación. El usuario resolvió la capacidad del entorno activando Paid.

**Paid activo:** el mínimo del plan es de **5 USD por cuenta al mes**, con posibles cargos adicionales por uso; no es un tope de gasto. Incluye 10 millones de peticiones y 30 millones de milisegundos CPU mensuales. [Tarifas oficiales](https://developers.cloudflare.com/workers/platform/pricing/). El usuario realizó la compra personalmente. El límite de 1.000 ms configurado controla cada petición, no el importe mensual.

La API de Cloudflare confirmó el nuevo límite y todos los estados HTTP esperados pasaron. No se obtuvo una nueva lectura de CPU porque el panel Observability permaneció sin cargar tras varios intentos; esta limitación queda registrada y no se sustituyó por tiempos de pared. [Observación de la ejecución Paid](../../../work/cloudflare-paid/CPU-OBSERVATION.md). La verificación funcional no constituye una prueba de carga sostenida.

## Acceso personal al entorno de pruebas

Abrir `Jugar online.command` o **Arena online** y pulsar **Iniciar sesión en el navegador**. Crear la cuenta con una passkey, confirmar en el dispositivo y pulsar **Autorizar este dispositivo** tras comparar el código con Godot. Al volver al juego, crear un luchador. Historia está disponible aunque todavía no haya rivales públicos; las cuentas QA no aparecen como rivales.

El progreso online comienza aparte de la partida local. [Procedimiento operativo](../backend/docs/DEPLOYMENT.md) · [Contrato de Arena](../backend/docs/ONLINE.md).
