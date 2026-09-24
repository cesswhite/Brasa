# Arena online · staging en Cloudflare

Implementados Workers+D1, Better Auth/passkeys, autorización de Godot desde el navegador, 15 arquetipos persistentes, Arena asíncrona automática, Historia de 100 encuentros, progresión compartida online, estilos de IA, técnicas, talentos, cosméticos, historial, replay y resumen defensivo. Los resultados se deciden y guardan en el servidor; Godot los presenta.

El servidor está publicado en [Cloudflare staging](https://brasa-api-staging.acessloop.workers.dev/health), con cinco migraciones aplicadas a D1. La prueba remota confirmó acceso, combate, Historia y revocación. **El usuario activó Workers Paid**, confirmado como plan actual en Cloudflare. La repetición bajo Paid pasó **32/32 comprobaciones de acceso y 60/60 de Arena, Historia y revocación**. [Registro de Cloudflare y mediciones](CLOUDFLARE-STAGING.md) · [Despliegue](../backend/docs/DEPLOYMENT.md).

## Verificación actual en Paid

El smoke terminó el 21 de septiembre de 2026 a las 03:48 UTC —20 de septiembre en Ciudad de México— sobre la versión `3faaf02a-8427-4329-9ab8-7c8e50ef13ec`. La publicación final es **`99077f34-8895-4b12-98ee-a3b692d8596e`**, con el mismo bundle y secreto, `limits.cpu_ms: 1000` y muestreo `0.1`. El paquete ocupa 676.79 KiB comprimidos; sus 102 ms de startup no son CPU por solicitud.

| Validación en Paid | Resultado |
| --- | --- |
| HTTPS y configuración remota final | 5/5 endpoints; API de versiones confirma `standard` y `cpu_ms: 1000`. |
| Registro, login WebAuthn y autorización de Godot | 32/32 comprobaciones. |
| Arena, Historia, reintentos y revocación | 60/60 comprobaciones. |
| Cuentas nuevas de esta ejecución | 2 QA aisladas, 1 luchador y 24 cosméticos por cuenta; 0 sesiones. |
| Combates de esta ejecución | 1 Arena y 1 Historia. |
| D1 acumulada | 4 cuentas QA, 0 cuentas ordinarias y 0 sesiones QA. |
| Configuración de ejecución | Paid, 1000 ms de CPU por solicitud; no es un presupuesto mensual. |

Los reportes están en `work/cloudflare-paid/`. No se obtuvo una nueva lectura de CPU por invocación en Paid porque el panel de Observability no cargó en Chrome. Los estados HTTP esperados sí se verificaron con Paid y el límite configurado. No se realizó una prueba de carga. La evidencia local disponible sigue siendo 365/365; no se repitió por cambiar sólo la configuración del despliegue.

## Evidencia previa al cambio de plan

La prueba terminó el 21 de septiembre de 2026 a las 03:27 UTC —20 de septiembre en Ciudad de México— sobre la versión `ce9db916-5337-4c93-8724-fdaed84cca91`. Esta versión identifica el smoke y las mediciones de CPU. La versión que cerró aquella publicación es `0f3491e2-c017-402e-a39d-5ea7dff1aec0`, con el mismo bundle, la quinta migración aplicada y muestreo `0.1`. El secreto se conservó sin rotación.

| Validación | Resultado |
| --- | --- |
| Backend completo: motor, auth, D1, autoridad y concurrencia | 365 pruebas finales, 0 fallos; 360/360 antes del smoke. |
| Migraciones remotas | Las cinco, de `0001_identity` a `0005_starter_expansions`, aplicadas; catálogo resembrado y expansión `cats-v1` registrada. |
| HTTPS, salud, origen, caché, UI y 401 | 5/5 comprobaciones, repetidas con 5/5 sobre la publicación final. |
| Registro, login WebAuthn y autorización de Godot | 32/32 comprobaciones. |
| Arena e Historia remotas, reintentos y revocación | 60/60 comprobaciones. |
| Reconciliación D1 final | 2 cuentas QA aisladas, 24 cosméticos —incluidos Ónix y Bruma— y 1 luchador cada una, 1 Arena y 1 Historia; 0 sesiones y 0 jugadores ordinarios. |
| Catálogo publicado | 31 cosméticos, 24 iniciales, 15 personajes y 100 encuentros. |
| Paquete publicado | 676.79 KiB comprimidos. |
| CPU histórica de Cloudflare Free | 9 de 11 invocaciones críticas superan 10 ms; Arena 81 ms e Historia 48 ms. Todas finalizaron con `outcome=ok`; [detalle y estado operativo](CLOUDFLARE-STAGING.md). |

Los logs y reportes de esta publicación están en `work/cloudflare-deploy/` desde la raíz del workspace. Los reportes contienen estados e IDs, sin credenciales. Las cuentas de prueba no aparecen como rivales de jugadores ordinarios.

## Evidencia histórica de la integración

Los siguientes resultados corresponden a la entrega local de Arena anterior al despliegue. Se conservan como evidencia de esa revisión; **no son pruebas repetidas durante esta publicación**.

| Validación histórica | Resultado |
| --- | --- |
| Godot API / UI nativa / HTTP contra Worker+D1 / Main | 27 / 787 / 32 / 25 comprobaciones, 0 fallos. |
| Regresión identidad / interfaz de batalla / campaña | 80 / 2139 / 337 comprobaciones, 0 fallos. |
| Paridad del motor | 274 combates de referencia; 626375 campos numéricos idénticos. |
| Simulación | 10000 combates; media 2.73 ms y p95 4.08 ms en Node local. |
| Guardados existentes en aquella entrega | 7 archivos idénticos byte por byte a su línea base. |

Los logs, hashes y 57 capturas históricos están en `work/online/final/manifest.json` y `work/online-audit/validation.json`. Las pruebas usan fixtures aislados. El benchmark de Node no representa CPU facturada de Cloudflare.

## Acceso desde el juego

1. Abre `Jugar online.command` o **Arena online** desde el menú.
2. Pulsa **Iniciar sesión en el navegador**. El juego abre una página con su código de dispositivo.
3. En la primera visita, escribe **Nombre de la cuenta**, pulsa **Crear cuenta con passkey** y confirma con la huella, rostro o PIN del dispositivo. Si ya tienes cuenta, usa **Entrar con mi passkey**.
4. Compara el código del navegador con Godot y pulsa **Autorizar este dispositivo**.
5. Vuelve al juego; recogerá la sesión automáticamente. Elige base de combate, escribe **Nombre de tu luchador** y pulsa **Crear luchador**.
6. En **Historia**, usa **Entrar al encuentro**. En Arena, **Actualizar rivales** y **Desafiar** cuando haya otros jugadores.

El [acceso web directo](https://brasa-api-staging.acessloop.workers.dev/auth) permite crear o iniciar una cuenta; para conectar Godot se debe iniciar y aprobar el código desde el juego. La passkey personal la crea el usuario. El progreso remoto empieza de nuevo y se guarda en el servidor; no importa estadísticas de las partidas locales. La sesión de Godot permanece en memoria.

Esta versión conserva las peleas automáticas. No añade selección manual de ataques ni rendición durante una pelea activa. No inventa rivales cuando no hay otros jugadores y no simula peleas espontáneas en segundo plano. Los modos locales siguen funcionando sin conexión.

[Contrato completo](../backend/docs/ONLINE.md) · [Auditoría previa](../backend/docs/ARCHITECTURE-AUDIT.md) · [Autenticación](../backend/docs/AUTH.md)
