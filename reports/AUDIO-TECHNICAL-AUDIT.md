# Auditoría técnica de audio · Brasa

Fecha: 21 de septiembre de 2026. Estado: **fotografía previa a la implementación del audio nuevo**. El servicio posterior se documenta en [AudioDirector · Implementación](../../../work/audio/audit/audio-director-implementation.md); los hechos y hashes de esta auditoría corresponden al código anterior.

Brasa tiene nueve tonos procedurales de confirmación y combate, reproducidos por cinco jugadores de audio reutilizables. No contiene archivos de audio, música, ambientes, voces, un catálogo sonoro ni buses propios. La separación entre motor y presentación permite sustituir este sistema sin cambiar daño, aleatoriedad, recompensas ni guardados.

La primera vertical acordada es **Ascua + arena de los faroles**. Este informe define su integración técnica; la Biblia maestra define dirección artística, selección de sonidos y backlog de producción. No se generó ni reprodujo audio, no se abrió el juego normal, no se consultó red y no se modificó runtime o partidas. Las valoraciones de reemplazo son decisiones frente al nuevo objetivo, no el resultado de una escucha que no se realizó.

## Alcance y evidencia

Se leyeron scripts, escenas, configuración, metadatos de presentación y pruebas existentes. El inventario de extensiones de audio y recursos `AudioBusLayout` abarca el proyecto, excluyendo `.godot`, backend, `node_modules` y `.git`. Resultado: **0 archivos de audio y 0 recursos de buses**. Los tonos existen sólo como PCM generado en memoria. El proyecto declara Godot 4.7 y el ejecutable local informa **4.7.2.stable.official.ed1daf0bf**. No se probaron dispositivos móviles ni latencia, sonoridad, consumo de voces o salida física.

Los hashes, rutas, líneas, parámetros e inventario estructurado están en [technical.json](../../../work/audio/audit/technical.json). Las referencias `[S01]`–`[S12]` remiten al índice al final. Son una fotografía de las fuentes al auditar, no un compromiso de que nunca cambiarán.

## Inventario y decisión

`KEEP` conserva una decisión válida; `REWORK` cambia un mecanismo aprovechable; `REPLACE` sustituye el contenido actual; `MISSING` identifica algo requerido que no existe. No todos los huecos deben producirse antes de escuchar la vertical.

| Elemento existente | Hecho comprobado | Decisión |
|---|---|---|
| Separación motor/presentación | El motor emite datos; Main reproduce sonidos después. No hay audio en las fórmulas. | **KEEP**. Mantener esta frontera. |
| Tonos generados | Nueve `AudioStreamWAV`, una variante por ID; oscilador fundamental + segundo armónico, envolvente y barrido. | **REPLACE** como contenido final; pueden quedar como fallback de desarrollo explícito. |
| Recursos reutilizados | PCM creado en `_ready()`, no en cada golpe; cinco `AudioStreamPlayer` reutilizados. | **KEEP** la reutilización; **REWORK** presupuestos, prioridades y configuración. |
| Mezcla | Todos los jugadores a −10 dB, sin bus asignado; ruta predeterminada Master. | **REWORK**. No equivale a normalización ni prueba de headroom. |
| Sonido sí/no | Booleano de Main, no persistido; sólo bloquea sonidos nuevos. | **REWORK**. Ajustes centralizados y mute efectivo. |
| Eventos de impacto | Hit/critical/signature separados; miss y dodge comparten tono. | **REWORK**. Material, intensidad y absorción deben tener significado. |
| Marcadores visuales | Pasos, salto, deslizamiento, carga y recuperación tienen tiempos resueltos. | **KEEP** como fuente temporal; añadir consumidor de audio independiente. |
| `sound_event` | Metadato presente con `hit`, `heavy` o `dash`; no se consume. | **REWORK**. Catálogo permitido y compatibilidad explícita. |
| Historia practicada | Repetir encuentro usa Main y los tonos actuales, sin conceder recompensas de progreso. | **KEEP** el flujo; distinguirlo de reproducción de un registro. |
| Repetición histórica y Online | Ambos presentan eventos con `BattleReplayPanel`, sin audio. | **MISSING** la paridad de presentación sonora. |
| Protección headless | `_play_sound` sale sin reproducir. `_make_sounds` sí construye PCM antes. | **KEEP** el sink silencioso; evitar preparación innecesaria en pruebas futuras. |
| Pruebas | Hay pruebas visuales de ajustes/reloj/pausa y fixtures que desactivan sonido; no una suite de audio. | **MISSING** pruebas de contrato, mezcla y escucha. |

### Los nueve tonos actuales

Todos se construyen a 22.050 Hz, muestras signed 16-bit, una muestra por instante y sin configuración estéreo. La base de frecuencia es un parámetro de síntesis, no una medición perceptual. [S01:1763–1795]

| ID | Base Hz | Duración s | Uso actual | Decisión |
|---|---:|---:|---|---|
| `hit` | 130 | 0,11 | Impacto normal y contraataque; también absorción de escudo | REPLACE |
| `critical` | 210 | 0,17 | Impacto crítico | REPLACE |
| `dodge` | 680 | 0,12 | Esquiva y fallo | REPLACE |
| `upgrade` | 760 | 0,15 | Mejorar, personalizar, crear, redistribuir y activar sonido | REPLACE |
| `start` | 420 | 0,30 | Inicio de combate y algunas selecciones/cambio de capítulo | REPLACE |
| `win` | 660 | 0,50 | Resultado ganado | REPLACE |
| `lose` | 240 | 0,40 | Resultado perdido | REPLACE |
| `ability` | 530 | 0,20 | Curación, escudo y cualquier evento de habilidad | REPLACE |
| `signature` | 980 | 0,75 | Anuncio de firma **y** su impacto | REPLACE y corregir duplicación |

La generación usa una sola forma de onda por ID; no hay variación, paneo, selección por compañero, ropa/cuerpo, material o arena. Ningún audio artístico previo necesita borrarse o convertirse.

## Conexiones actuales y huecos concretos

| Entrada real | Presentación sonora actual | Integración recomendada |
|---|---|---|
| `move_started` | Silencio | Programar preparación, apoyo y desplazamiento por fases. Nunca anticipar el impacto confirmado. |
| `attack: hit / critical / signature` | Uno de tres tonos | Resolver impacto a partir del resultado, material y absorción; crítico/firma con acento controlado. |
| `attack: miss / dodge` | Mismo tono `dodge` | Conservar movimiento en aire; sonido de esquiva sólo para dodge. **Sin impacto corporal** en ambos. |
| `attack` con `counter=true` | `hit` | Movimiento/respuesta de contraataque y contacto confirmado, sin inventar parry perfecto. |
| `defensive_stance` | Silencio | Entrada de guardia discreta; no fabricar un bloqueo al activarse. |
| `shield` y absorción en `attack` | `ability` al conceder; `hit` al absorber | Concesión y contacto con escudo diferentes. Absorción total no debe prometer daño corporal. |
| `heal` | `ability` | Cue propio y limitado por cadencia. |
| `status_applied / tick / expired / resisted` | Silencio | Aplicación y ticks seleccionados según efecto; no sonar cada partícula ni cada texto. |
| `ability: phase_shift` | `ability` | Transición de fase de Ascua, respaldada por su definición real y presentación. |
| `signature` | `signature` | Acento de activación diferenciado del impacto; respetar cuándo llega el evento. |
| Daño letal normal o por estado | Sin cue específico de KO | Impacto/tick letal, cancelación de futuras acciones y caída según presentación. |
| `finished` | `win/lose`, tras espera visual de 0,30 s salvo rendición | Un cierre de combate; no confundir timeout/rendición con un golpe mortal. |
| Recompensa/XP/desbloqueo | Sólo algunos `upgrade`, sin jerarquía de recompensas | UI/progreso desde confirmación de la operación real, jamás desde un replay. |
| Tabs, foco, volver, error, cerrado, inventario | Sin enrutamiento compartido | Pequeño vocabulario UI común; mensajes de error y acciones bloqueadas discretos. |
| Música, ambientes, voces, pasos, salto, aterrizaje, telas, energía, intro y cosméticos | Sin recursos ni rutas | MISSING; producir por prioridad de la Biblia y evitar loops cosméticos permanentes. |

Fuentes: Main [S01:956–1087,1161–1216], motor [S03:290–612], reglas [S04:25–51], repetición [S07:170–276], Online [S08:840–881]. El motor tiene guardia, absorción y contraataque; **no ofrece un resultado `parry` o `perfect_block`**. Sus resultados de ataque son hit, critical, signature, miss y dodge.

### Fallos y riesgos verificados

1. **La firma puede duplicar el mismo sonido.** El motor emite `signature` y luego `attack` con resultado `signature` en la misma resolución. Main reproduce el tono en ambos handlers. Si hay dos jugadores libres, se solapan dos copias de 0,75 s. No es una preparación y un impacto diferenciados. [S03:364,401; S04:48; S01:1043,1087]
2. **Silenciar no silencia lo que ya está sonando.** Cambia un booleano consultado al solicitar el siguiente sonido; no cambia Master ni detiene jugadores. Reabrir la aplicación restaura el valor inicial `true`. [S01:85,1223–1227,1788–1795]
3. **El pool pierde eventos sin jerarquía.** Cuando sus cinco jugadores están ocupados, `_play_sound` termina sin reproducir y sin registrar descarte. UI/habilidad tienen la misma oportunidad de ocupar un slot que firma/resultado. La saturación efectiva no se midió. [S01:1782–1795]
4. **Online y registros históricos son silenciosos.** No llegan al helper de Main. No confundir este hueco con repetir un encuentro de Historia, que sí ejecuta Main. [S07; S08:840–866; S01:402–407]
5. **Un metadato no constituye una integración.** `sound_event` sólo se valida como cadena de hasta 80 caracteres; `heavy` y `dash` ni siquiera existen en los nueve tonos. El futuro consumidor debe aceptar IDs registrados, no interpretar rutas/URLs desde eventos o apariencias. [S05:15–59; S01:1764]
6. **No existe política de audio tardío.** Visuales reciben `elapsed-event.time`; el sonido de impacto se reproduce completo al manejar el evento. Aceleración, lotes de eventos o pausas largas necesitan un criterio explícito de descarte/coalescencia. No se verificó un desfase audible concreto. [S01:1007–1043]
7. **Los ajustes futuros pueden perderse si se amplía ingenuamente el archivo actual.** `_toggle_reduced_motion()` crea un `ConfigFile` vacío y guarda sólo su clave. Añadir volumen al mismo archivo sin cargar/mezclar primero haría que este camino lo sobreescribiera. Hoy no hay volúmenes persistidos que se estén perdiendo. [S01:1229–1234]

## Arquitectura recomendada — aún no implementada

Un único **AudioDirector** para la sesión de aplicación, con contexto de pantalla/arena y de combate. Main y `BattleReplayPanel` serán adaptadores del mismo servicio; Online reutilizará el adaptador de repetición. El director no llama al motor, no recompensa, no escribe identidades o snapshots y no incorpora archivos en eventos del servidor.

### API propuesta para acordar antes de programar

```gdscript
# Nombres propuestos; no existen en el juego auditado.
configure_context(arena_id: String, fighter_profiles: Dictionary,
                  session_context: Dictionary = {}) -> void
on_combat_event(event: Dictionary, presentation_time: float,
                event_index: int) -> void
advance(presentation_time: float) -> void
play_ui(event_id: String, context: Dictionary = {}) -> void
set_volumes(settings: Dictionary) -> void
set_paused(paused: bool) -> void
stop_session() -> void
```

`session_context` contiene identificador local de sesión, battle_id si existe, modo `live/replay/online/preview` y política de resultados. Los perfiles resuelven **IDs locales permitidos**, no nodos propietarios de daño ni rutas proporcionadas por servidor. El reloj lo entrega el presentador: `combat.elapsed` en vivo, `elapsed` en repetición; `advance` despacha marcadores vencidos una vez. Música/UI usan tiempo real y no necesitan que un combate avance.

El motor no emite un ID único por evento: añade turno, tiempo y PV, y preserva orden en `event_log`. Usar el índice estable del registro junto con sesión/battle_id/lado/acción/marker; no sólo move_id o turno. Mantener la historia intacta. Una nueva sesión de replay permite oírlo de nuevo; un evento duplicado dentro de una sesión no lo reproduce otra vez. [S03:625–633]

**Catálogo sonoro:** IDs semánticos locales, familias de variantes, bus, ganancia, prioridad, máximo simultáneo, cooldown, duración máxima, política de cola, loop/one-shot, material y fase. Ejemplos de futuros IDs: `movement.jump.takeoff`, `movement.jump.land`, `attack.swing.heavy`, `impact.body.light`, `impact.shield`, `signature.activate`, `signature.impact`, `status.burn`, `ascua.phase_change`, `ui.confirm`, `result.victory`. Ninguno está implementado todavía.

**Selección de variaciones:** RNG exclusivo de presentación o hash de sesión/evento/actor; nunca consumir el RNG del combate o el global usado por gameplay. Evitar repetición inmediata dentro de una familia; variación de pitch/ganancia pequeña y acotada por asset, desactivable cuando altere identidad. La elección debe ser reproducible para QA. No alterar stats cuando cambie la apariencia; el perfil debe distinguir identidad del compañero y material visible del cuerpo equipado mediante catálogos conocidos.

**Marcadores:** reutilizar tiempos de `MoveVisualProfile.resolve`, no copiar duraciones en cada sonido. Su tabla ya resuelve windup/travel/recovery y permite apoyo, despegue, aterrizaje, deslizamiento y carga. El scheduler de FX aporta patrones útiles de cursor, WeakRef, límite y descarte por sesión. **No colgar audio de `CombatFX._dispatch_markers`: FX se borra en movimiento reducido.** El audio consume los metadatos independientemente. Fusionar `landing` y `landing_debris` si representan un solo contacto físico, para no duplicar el aterrizaje. [S05:7–90; S06:227–310]

**Impactos y KO:** el resultado `attack` decide si hubo contacto, crítico o absorción. Ni el marker ni el fotograma cambian esa verdad. Cancelar cues pendientes del actor con PV ≤0 incluso si la causa es `status_tick`; permitir el tail del último impacto y el apoyo final de caída. `finished` por rendición/tiempo no prueba un impacto mortal. No emitir dos KO por tick letal + finished. Firmas se separan por función sonora, sin duplicar la misma muestra. La carga puede comenzar con `move_started.signature`; no mover hacia atrás el evento `signature` que el motor emite al resolver el impacto.

### Buses, pool y recursos

Propuesta de jerarquía para el director:

```text
Master
├── Music
├── Ambience
├── SFX
│   ├── Combat
│   ├── Movement
│   └── UI
└── Voice  (activar cuando haya contenido vocal aprobado)
```

La UI de ajustes puede mostrar General, Música, Efectos, Ambiente y Voces cuando exista contenido; los hijos de SFX permiten mezclar sin multiplicar sliders. Persistir preferencias de dispositivo fuera de los perfiles de fuerza/XP y conservar las claves de pantalla existentes. `mute` debe actuar sobre buses; probar también las colas activas, reapertura y cambio de modo.

Punto de partida para validar, **no capacidad ya medida**: 12 slots Combat (dos reservables para eventos importantes), cuatro Movement, dos UI y dos Voice; máximo 20 one-shots, más dos Music y dos Ambience para crossfades. Eliminar primero un paso redundante o un evento menor vencido; proteger impacto crítico, KO y confirmación importante. Evitar cortes duros con fades breves, respetar prioridades y exponer contadores de solicitudes/reproducciones/descartes. La vertical decidirá si estos límites se reducen; no reservar memoria de voces inexistentes.

Preparar y cachear sólo las familias necesarias para los dos actores y la arena actual, con caché limitada entre contextos. Sin `load()` por frame, generación de PCM por golpe ni crecimiento ilimitado del historial de deduplicación. `AudioStreamPlayer` es suficiente para UI/música y la primera vertical; posicionamiento opcional mediante `AudioStreamPlayer2D` debe tener paneo suave y límites estables entre escritorio/móvil. No usar tamaño del viewport para cambiar el volumen percibido. El anclaje visual del actor puede informar posición; no crea un emisor por partícula.

### Relojes y estados

| Situación | Hecho actual | Política propuesta |
|---|---|---|
| ×1 / ×2 | Main cambia `Engine.time_scale`; no configura pitch ni velocidad de audio. | Conservar identidad/pitch; programar por reloj de presentación. Coalescer apoyos menores si la densidad a ×2 lo exige. Medir la salida nativa. |
| Hitstop | Congela pose; el reloj de acción sigue avanzando. No toca audio. | Dejar terminar impacto/reverberación. No pausar todos los buses por la congelación visual. |
| Modal durante combate | Deja de avanzar motor y pausa actores/FX; jugadores de audio siguen sin cambios. | Detener nuevos cues de combate; pausar/fadear sólo loops de acción. UI disponible; tails breves terminan; ambiente/música siguen o se atenúan según Biblia. |
| Reanudar | No hay scheduler sonoro actual. | Continuar desde tiempo conservado; no descargar una ráfaga de cues vencidos. |
| Replay pausa / reinicio / cierre | Pausa/limpia visuales; no audio. | Conservar reloj al pausar; al reiniciar/cerrar cancelar sesión, loops, colas y asociaciones. No cortar UI ajena al replay. |
| Movimiento reducido | Sólo cambia actores, arena y FX. | Mantener significado y volumen de audio. Sus marcadores no dependen de la existencia de partículas. |
| Evento tardío | Se dispara tono completo al manejarlo. | Ventana de tolerancia por clase: descartar pasos tardíos; no acumular one-shots antiguos; mantener resultado actual una vez. Medir antes de fijar umbrales definitivos. |
| Resultado / historial | Recompensas se confirman antes del retraso visual; replay no recompensa. | Stinger asociado a presentación, reward cue sólo a operación nueva confirmada. Nunca reactivar desbloqueos desde historia. |

Fuentes del comportamiento actual: [S01:936–969,1161–1239; S07:178–222; S09:376–386,428,673–675]. `set_paused` no debe cambiar `SceneTree.paused`, velocidad del motor ni `reduced_motion`.

## Importación, sonoridad y mezcla propuestas

Conservar originales lossless, sus licencias/procedencia y un manifiesto con hash, ID semántico, variación, canales, frecuencia, duración, loop y medición. La generación y el tratamiento posterior serán pasos explícitos posteriores a la Biblia; esta auditoría no produce audio.

Para la vertical: originales WAV de buena calidad; preferencia de trabajo 48 kHz/24-bit cuando la fuente lo permita, sin fingir resolución que no tenga. Exportar one-shots cortos a WAV PCM adecuado al presupuesto e importar con ajustes reproducibles; música/ambiente largo puede usar Ogg Vorbis tras validar loop y coste en Godot 4.7.2. Inspeccionar las opciones reales de importación al disponer de archivos. No convertir por extensión ni asumir que un MP3 tiene un loop sin costura. Mono para contacto/pasos; estéreo sólo si aporta espacio. Registrar puntos de loop y tiempos de ataque/tail.

Objetivos **provisionales para medir**, no valores del audio actual: fuentes con true peak ≤−3 dBTP; captura final de mezcla ≤−1 dBTP; música de combate de referencia alrededor de −20 LUFS-I (±2), ajustada contra SFX mediante escucha. Los sonidos de 0,1–0,3 s requieren comparar transiente, energía y nivel percibido, no normalizarlos ciegamente con LUFS integrado. No se ha medido LUFS, true peak ni clipping del sintetizador actual.

Tomar el impacto normal como referencia relativa 0 dB; comenzar pasos/telas 6–10 dB debajo y UI 8–12 dB debajo; crítico alrededor de +1 dB y firma +2 dB como límites iniciales, diferenciados sobre todo por material/transiente. Son relaciones de diseño para calibrar, no ganancias absolutas a aplicar sin medir. Evitar duplicar cuerpo/grave en dos capas coincidentes. Dejar margen en Master y verificar suma estéreo/mono y móvil.

Ducking de música suave, central y reversible sólo en firma, cambio de fase, KO, presentación de jefe o recompensa mayor: punto de partida 2–4 dB, ataque 30–60 ms y recuperación 250–600 ms. No duck en cada golpe. Un solo gestor compone motivos superpuestos y restaura el nivel; nunca varios tweens competitivos sobre el mismo bus. Ambiente discreto y estable; cosméticos sólo tienen cue si existe un momento perceptible relevante, no por cada aura dibujada.

## Plan de implementación y aceptación

1. **Cerrar Biblia e interfaces.** Usar Ascua + arena_faroles, su `phase_shift` real y `ember_core`, única transformación registrada actualmente. No extrapolar transformaciones a todo el plantel ni parry. [S10:246–257; S11:47]
2. **Director, buses, catálogo y ajustes sin cambiar el motor.** Implementar sink silencioso para pruebas, metadatos permitidos, límites y API anterior. Migrar el toggle conservando preferencias de pantalla; no migrar/reescribir progreso.
3. **Conectar presentación en Main y repetición.** Enrutar una vez cada evento y marker con índice/reloj. Online usa ese mismo consumidor. Retirar la llamada procedimental equivalente al activar un cue nuevo, evitando dos sistemas simultáneos.
4. **Integrar los recursos de la vertical aprobados por la Biblia.** Preparación, contacto, paso, carga, fase, KO y entorno con pocas variantes útiles; UI mínima. Escuchar antes de multiplicar por personajes o arenas.
5. **Aprobar contratos, rendimiento y mezcla.** Sólo después ampliar familias del plantel y música/contextos, reutilizando materiales coherentes.

Pruebas propuestas — **ninguna se ejecutó como parte de esta auditoría**:

| Grupo | Comprobación que debe demostrar |
|---|---|
| Eventos y semántica | Firma activa/impacta una vez; miss no produce contacto; shield total/parcial coherente; counter sólo cuando existe; sin parry inventado. |
| Reloj | 20/60/120 FPS simulados, ×1/×2 y llegada en lotes: markers una vez, orden estable, descartes tardíos explícitos. |
| Pausa/KO | Hitstop deja tails; modal pausa cues futuros; resume sin ráfaga; tick letal cancela carga/pasos pendientes; cierre/reinicio invalida sesión previa. |
| Replay/Online | Misma lista semántica para el mismo registro en vivo/replay; variantes reproducibles; snapshots y eventos inmutables; ningún XP/desbloqueo repetido. |
| Variaciones | RNG independiente; no repetición inmediata cuando hay alternativas; pitch/ganancia dentro de límites; inválidos rechazados. |
| Pool/caché | Cota de jugadores, loops y cola; prioridad comprobada; no lectura de archivo por frame; memoria estable tras 100 cambios de combate/contexto. |
| Ajustes | Volúmenes persisten, mute afecta sonidos existentes, `reduced_motion` conserva audio y otras preferencias; valores no finitos/fuera de rango saneados. |
| Integridad | Misma semilla produce los mismos eventos, HP, ganador y recompensas con audio activo/inactivo; hashes de snapshots/partidas de fixture sin alteración por presentación. |
| Recursos | Archivos decodifican, frecuencia/canales/duración/loops coinciden con manifiesto; sin clipping; variante inexistente usa fallback explícito y diagnóstico. |
| Nativo/escucha | Vertical en escritorio y móvil real, auriculares y altavoz, mono/estéreo, volumen bajo; medir latencia/true peak y juzgar material, fatiga, claridad de crítico/firma y loop sin costura. |

Los fixtures visuales existentes que desactivan sonido y el guard headless no certifican estos criterios. Sus pruebas de reloj y pausa sí son regresiones reutilizables: `test_animation_sequences.gd`, `test_visual_fx_markers.gd`, `test_status_ko_presentation.gd`, `test_visual_history_settings.gd`. No se atribuye a sus resultados una validación auditiva.

## Índice de fuentes locales

| Ref | Archivo y puntos leídos |
|---|---|
| S01 | [main.gd](../scripts/main.gd): 85–91,150–169,287,380–424,883,934–1087,1161–1239,1289,1468–1488,1763–1795 |
| S02 | [project.godot](../project.godot): 4–7,26–27; [main.tscn](../scenes/main.tscn) |
| S03 | [combat_engine.gd](../scripts/combat_engine.gd): 290–328,344–442,455–507,581,605–633 |
| S04 | [combat_rules.gd](../scripts/combat_rules.gd): 25–51,63–67 |
| S05 | [move_visual_profile.gd](../scripts/move_visual_profile.gd): 3–90 |
| S06 | [combat_fx.gd](../scripts/combat_fx.gd): 227–310 |
| S07 | [battle_replay_panel.gd](../scripts/ui/battle_replay_panel.gd): 170–276 |
| S08 | [online_panel.gd](../scripts/ui/online_panel.gd): 840–881 |
| S09 | [fighter_view.gd](../scripts/fighter_view.gd): 376–386,428,673–688 |
| S10 | [story_catalog.gd](../scripts/story_catalog.gd): 246–257 |
| S11 | [fighter_animation_set.gd](../scripts/fighter_animation_set.gd): 45–59 |
| S12 | [test_animation_sequences.gd](../tests/test_animation_sequences.gd), [test_visual_fx_markers.gd](../tests/test_visual_fx_markers.gd), [test_status_ko_presentation.gd](../tests/test_status_ko_presentation.gd), [test_visual_history_settings.gd](../tests/test_visual_history_settings.gd) |
