# Brasa: auditoría previa a la Arena asíncrona

Este documento conserva el estado anterior a la implementación de Arena. La implementación y disponibilidad actuales se registran en [Arena online](../../reports/ARENA-ONLINE.md) y [Despliegue de Cloudflare](DEPLOYMENT.md). Los hallazgos siguientes son históricos.

Fecha: 20 de septiembre de 2026. Se inspeccionó el código antes de modificar el servicio. La línea base y los hashes de guardados están en `work/online-audit/before.json`, fuera del proyecto distribuible.

## Mapa comprobado

| Área | Estado real y decisión |
| --- | --- |
| Godot y organización | Godot 4.7.2, GL Compatibility; `project.godot` inicia `scenes/main.tscn`. No autoloads. Scripts separados de recursos gráficos y backend excluido con `.gdignore`. |
| Personajes | `scripts/character_catalog.gd`: 13 definiciones canónicas con estadísticas base, crecimiento, habilidad, firma y referencias visuales. |
| Luchadores | `progression.gd` y `story_progression.gd` guardan perfiles por arquetipo. `fighter_identity.gd` agrega ID, nombre y apariencia independientes. Un ID local no acredita propiedad remota. |
| Estadísticas | `character_catalog.gd:stats_for`, `story_catalog.gd:stats_for` y `balance.gd` distinguen base, crecimiento, inversión y límites. No confiar en `combat_stats` enviado por clientes. |
| Movimientos | `move_catalog.gd` centraliza técnicas, desbloqueos, mejoras y talentos. `combat_rules.gd` contiene fórmulas compartidas; `status_effects.gd` administra efectos. |
| Motor | `combat_engine.gd` es un RefCounted sin UI ni recompensas, con reloj de preparación/impacto/recuperación, eventos y resultado terminal inmutable. Es candidato a portado y pruebas cruzadas. |
| Azar | El motor concentra RandomNumberGenerator; catálogo/creación de oponentes tienen otros RNG locales. El servidor elegirá la semilla y no admitirá opciones de prueba del cliente. La secuencia PCG/randf debe verificarse con el binario, no suponerse. |
| Animación | `main.gd:_handle_event`, `fighter_view.gd` y `arena_view.gd` transforman eventos en poses, movimiento, sonido y HUD. Se mantienen en Godot. |
| Estado | Main llama `combat.advance` y consulta `snapshot`; éste es un modelo visual, no una serialización completa reanudable. Arena conservará el modelo autobattler: desafiar es la intención; el servidor resuelve la pelea. |
| XP y niveles | Se conceden actualmente en `progression.reward_match`/`story_progression.reward_match`. Online requiere cálculo y confirmación atómica en D1. Nunca llamar a esas recompensas locales para un resultado remoto. |
| Historia | 100 encuentros y 11 capítulos, definidos en `story_catalog.gd`/`campaign_config.gd`; rivales, talentos, técnicas y fases comparten el motor. Se conserva la campaña local y se exportan sus definiciones para el servidor. |
| Persistencia | Liga, Historia e identidad usan archivos separados y migraciones locales. Backend: accounts, local_sessions, fighters, identidad, progreso, apariencia, catálogo, inventario y snapshots. No existen aún batallas online ni ratings. |
| Red | `identity_api.gd` sólo permite loopback, token manual en memoria y una petición a la vez. Main no lo instancia. Se necesita una capa HTTPS, ciclo de sesión, cancelación y recuperación idempotente. |
| Backend | `backend/src/worker.js`, ESM y D1; Wrangler 4.110.0, Miniflare 4.20260708.1, esbuild 0.28.2. Node instalado 22.23.1. Configuración `wrangler.jsonc` exclusivamente local. |
| Auth | El adaptador actual rechaza cualquier host no local. Better Auth no está instalado en la línea base. Evaluar documentación y compatibilidad antes de escoger el flujo de navegador/dispositivo. |
| Autoridad en UI | Main decide cuándo ejecutar motor y cuándo otorgar recompensas; las fórmulas están fuera de la UI. La nueva pantalla remota consumirá snapshots/eventos y perfiles del servidor. |
| Datos incompatibles | La API devuelve `archetype_id` y progreso anidado; el renderer necesita un descriptor con `character_id`, nombre, nivel y apariencia. El servidor debe producirlo. Main reconstruye rivales omitiendo apariencia: no usar esa ruta para rivales reales. |
| Pruebas | 24 suites de regresión, suites de identidad/renderer/HTTP, 15 pruebas D1 y simuladores de combate/campaña. Añadir paridad entre runtimes, autoridad, carreras, reintentos y desconexión. |
| Riesgos | RNG/float/redondeos, divergencia entre dos motores, guardar resultados parciales, fabricar rivales cuando no haya usuarios, cargar progreso local no verificable, perder cosméticos del rival y entregar respuestas tras cerrar sesión. |
| Cloudflare | La sesión Chrome muestra la cuenta elegida, sin Workers existentes y subdominio `acessloop.workers.dev`. Wrangler no está autenticado. El primer despliegue será un servicio de pruebas separado; no se contrata un plan ni se reutilizan datos de producción. |

## Secuencia de implementación

1. Congelar línea base, exportar definiciones canónicas y construir corpus de combate real. Portar reglas/motor con pruebas de paridad y versión explícita; mantener todas las animaciones locales.
2. Integrar autenticación de primera parte apropiada para navegador y cliente público, con sesiones revocables, validación servidor y límites. Mantener el entorno local independiente.
3. Añadir perfil autoritativo y migraciones relacionales: rating, historial, IA, progresión y operaciones idempotentes. Las cuentas remotas empiezan con progreso acreditado por el servidor; los guardados existentes siguen disponibles localmente.
4. Crear un circuito vertical Arena: cuenta → luchador persistente → rivales de otros usuarios → desafío → snapshots inmutables → simulación servidor → actualización atómica de ambos perfiles → historial y resultados defensivos. No inventar un sistema de turnos manuales que el juego no tiene.
5. Reutilizar las definiciones de Historia con el mismo motor y perfil autoritativo cuando el circuito anterior pase las pruebas. Desbloqueos, inversión de puntos y cambios de build expresan intenciones, nunca valores finales.
6. Conectar Godot por HTTPS: entrada independiente, autorización, listado real, presentación de eventos, perfil, historial y resumen offline. Ante un timeout conservar la misma clave de operación y consultar el resultado.
7. Probar D1 con carreras, repetición de solicitudes, fallos y límites; ejecutar simulador y regresiones afectadas. Preparar configuración y migraciones revisables antes de autorizar Wrangler y publicar el entorno de pruebas.

## Invariantes

Los cosméticos no cambian poder. Ningún cliente concede XP, puntos, niveles, movimientos, cosméticos, rating o victorias. Las batallas copian datos autoritativos y versiones; las modificaciones posteriores no cambian el resultado. Las escrituras dependientes se condicionan a una misma operación dentro de un batch transaccional D1. Los rivales de Arena son fichas reales y el estado vacío no contiene bots disfrazados. No se ejecutan peleas espontáneas en segundo plano.

Referencia: [D1 batch y transacciones](https://developers.cloudflare.com/d1/worker-api/d1-database/), [Wrangler y entornos](https://developers.cloudflare.com/workers/wrangler/configuration/), [autorización de Wrangler](https://developers.cloudflare.com/workers/wrangler/commands/general/). Las instrucciones se contrastan también con `--help` de la versión instalada.
