# Brasa · Audio Bible

Fecha: 2026-09-21. Dirección original, derivada del juego inspeccionado y de `VISUAL-STYLE-BIBLE.md`. La revisión vigente prioriza **contacto físico natural, aire/tela, suelo y fuego reconocibles** después del feedback de tonos y metal arrastrado. El alcance sigue siendo **Ascua y Patio de Faroles**. El resto es un backlog explícito; un prompt no equivale a un sonido entregado. ElevenLabs se opera en **Google Chrome**, con la sesión del usuario; las generaciones no se comparten en Explore.

## 1. La misma materia que se ve

La piedra, el cuero, el tejido gastado y la madera de Historia definen el sonido. El bronce visible no obliga a añadir campanas, resonancias o arrastres metálicos a los golpes. El cuerpo y el suelo llegan antes que la ornamentación. Hay calidez de faroles, aire abierto y silencio entre gestos. El combate debe entenderse sin mirar los números: preparación, movimiento, contacto o evasión, consecuencia y regreso al reposo.

No hay voz de narrador ni diálogo añadido. Las vocalizaciones son esfuerzos breves y selectivos. Ascua pesa y respira como carbón vivo; no se convierte en un humano gritando ni en una explosión de película. La firma es excepcional por su forma temporal y su textura, no por saturar el Master. Los efectos circulares de fuego retirados no vuelven como zumbidos permanentes ni anillos sonoros.

Paleta común: cuero seco, fibras de algodón, golpes corporales secos con peso, tierra compacta, piedra porosa, fuego pequeño y madera. El golpe tiene un ataque reconocible y una caída natural; el aire acompaña y deja sitio al contacto. El fuego usa soplo, combustión y crepitar de carbón, sin barrido tonal ni zumbido de poder. Evitar láseres, sonidos de interfaz electrónica, metal arrastrado, campanillas de casino, cartón cómico, librerías mezcladas sin dirección y música épica genérica.

## 2. Inventario y autoridad

Los informes complementarios son parte de esta biblia:

- `AUDIO-TECHNICAL-AUDIT.md`: archivos, reproductores, buses, volumen, relojes y limitaciones.
- `AUDIO-CHARACTERS-AND-COMBAT.md`: los 15 compañeros, Ascua y Véspera; catálogo de movimientos, reacciones, firmas y fases reales.
- `AUDIO-WORLD-MUSIC-UI.md`: escenarios realmente renderizados, contextos de menú, música, UI y progresión.
- `../../../work/audio/audit/*.json`: inventario legible por herramientas.
- `../../../work/audio/production-plan.json`: lote de producción del primer slice, con prompts completos y parámetros. La procedencia real y las tomas seleccionadas se registran después de descargar.
- `../../../work/audio/revision-realism/production-plan.json`: dirección y fuentes V2. Los candidatos y su preselección técnica permanecen separados de la integración; la revisión V1 se conserva en `revision-realism/before/`.

Diagnóstico previo a producir: nueve tonos sintetizados en Main, sin archivos de audio importados, sin música/ambiente, sin buses dedicados ni mezcla persistente. Se conserva la intención semántica de sus llamadas; se reemplaza el timbre. El tono de firma se llama en el anuncio y otra vez en el impacto; deben ser dos capas diferentes, nunca dos reproducciones del mismo gesto. Las repeticiones, incluido Online, necesitan el mismo consumidor de eventos. `MoveVisualProfile` ya ofrece marcadores; el audio no debe depender de que existan partículas visibles.

KEEP: eventos de reglas y tiempos de movimiento; identidad del luchador y cosméticos; capas visuales; navegación y confirmaciones reales. REWORK: política de repetición, cooldowns, prioridad, pausa y volumen. REPLACE: tonos de prueba. MISSING: todos los bancos dirigidos, música, ambiente y la mayoría de feedback específico. No modificar daño, balance, RNG, progreso, cuenta, Worker ni registro servidor.

## 3. Cuerpo, arquetipo y escenario

El perfil corporal determina peso, respiración, pisada y tejido. El arquetipo determina poder, firma y motivo. La apariencia personalizada sigue siendo la misma identidad: el audio no infiere una armadura metálica de un tinte, no inventa accesorios ni anuncia cosméticos no equipados. Los perfiles de todos los cuerpos y sus propuestas constan en el inventario de personajes; compartir foley básico es deliberado, pero no equivale a haber producido cada banco de identidad.

Hay dos arenas de combate actuales: `arena_faroles`, tierra seca compacta con terracota; y `arena_tormenta`, losas húmedas, agua y viento. Once capítulos reutilizan esas localizaciones. Los nombres narrativos de un jardín u horno no autorizan una nueva acústica si el fondo real sigue siendo el mismo. El audio debe resolver el mismo fondo que renderiza la escena; un Replay sin capítulo cae a Faroles como el código visual.

Formato conceptual de CharacterAudioProfile: id, body, weight, movement texture, power material, reaction density, signature cues, supported transformation cues, motif, per-event overrides. ArenaAudioProfile: id, surface, ambience, music, outdoor/interior character, stereo spread, gain, intro/results. Campos aún sin archivo quedan ausentes y silenciosos; jamás elegir un poder de otro personaje como reemplazo.

## 4. Gramática del combate

| Acción real | Antes / movimiento | Resolución | Consecuencia |
| --- | --- | --- | --- |
| Rápido | planta breve + whoosh corto | cuerpo ligero si hay daño | reacción ligera selectiva |
| Pesado | tejido y tensión; Ascua carbón contenido | cuerpo denso | reacción de peso / retroceso |
| Carga | presión + una fricción en `slide_start` | impacto pesado si acierta | la parada no vuelve a reproducir el arrastre |
| Salto | impulso en `jump_takeoff`, aire en viaje | contacto autorizado | suelo en `landing`, sin duplicar `right_foot_impact` simultáneo |
| Guardia | planta/ropa al adoptar postura | contacto seco sólo si la resolución lo justifica | nunca etiquetar guardia como parry perfecto |
| Escudo | preparación de defensa | absorción distinta del daño | si daño y absorción coexisten, capa defensiva más tenue |
| Réplica | `move_started(counter=true)` | ataque real de réplica | sin inventar «perfect block» |
| Esquiva | aire y desplazamiento del objetivo | ningún cuerpo/impacto | no acierto ni crítico |
| Fallo | conserva movimiento del atacante | ningún impacto y ningún premio de esquiva | silencio de contacto |
| Crítico | mismo ataque | cuerpo + contacto seco breve de cuero/cuerpo | sin bronce ni cola tonal; prioridad alta, no volumen desproporcionado |
| Firma | anuncio breve propio | acento de firma distinto, una sola vez | espacio en música, reacción / KO reales |
| Quemadura | ignición inicial tenue | los ticks conservan su feedback visual sin repetir `ascua_release` | el tick letal conserva la caída/KO |
| Transformación | Ascua `phase_shift`, índice > 0 | gesto de ignición de su núcleo | cola breve, sin bucle permanente |
| KO | conserva último impacto | caída diferenciada tras el movimiento | suelo y resolución; no multiplicar KO por ataque + finished |

Los tiempos proceden de `move.windup/travel/recovery` y `MoveVisualProfile.resolve().markers`; no hardcodear un reloj de animación paralelo para daño. Seleccionar gestos de ataque limpio y cola natural corta; recortar sólo los bordes sin actividad. No acelerar una toma para hacerla caber ni truncar una cola activa para cumplir una duración. Una fricción por desplazamiento; sus marcadores visuales pueden seguir existiendo sin otra capa de audio. Si un cuadro recibe varios eventos atrasados, descartar marcadores de movimiento obsoletos en vez de reproducir una ráfaga. Identidad de consumo por sesión + índice del evento + marcador. No cambiar eventos recibidos ni añadir rutas de audio a contratos de servidor.

El audio sigue su propio reloj de presentación en Main y Replay. La pausa detiene nuevas programaciones y pausa las cargas ligadas a una acción; las camas musicales/ambientales y las colas breves continúan. Al reanudar no recupera sonidos perdidos. El hitstop visual y movimiento reducido no paran el audio. ×2 debe acelerar el disparo de marcadores, no subir una octava la música. Al cerrar una repetición o iniciar otra sesión se limpian colas y voces del contexto anterior.

Ascua tiene `ember_core` real de 0.72 s / 8 s visuales, sin nuevos stats. Otros cuerpos poseen poses de firma pero no una transformación registrada. No producir formas nuevas. La probabilidad de firma se decide al iniciar el combate (1% por combatiente); QA usa fixtures/semillas controladas, no modifica la probabilidad de producción. Counter/parry de Ascua: no aplica. Sus cargas sí tienen locomoción de dash, sin añadir una técnica nueva.

## 5. Música y ambiente

Motivo común propuesto «Farol»: 1–♭3–5–2, expresado con cuerda pulsada cálida, percusión de piel/madera y bronce amortiguado. Es una composición original sugerida, no una afirmación de que el modelo musical devolverá notas exactas. El manifiesto distingue música generada y edición posterior.

Faroles: 96 BPM, re menor, tensión contenida y aire nocturno. Tormenta: el mismo lenguaje con cuerda frotada baja, piedra/aire y pulso más tenso. Menús de refugio, preparación, taller y legado son variaciones de la familia, no canciones completamente distintas por pestaña. Jefes añaden densidad y motivo de identidad; Véspera es el jefe final, Ascua vuelve en el encuentro 50. El inventario de mundo detalla el mapa completo, incluidas introducciones, bucles y finales.

Una cama ambiental continua, natural y sin eventos invasivos: aire exterior, hojas/tela y mecha discreta. Faroles no tiene crowd inventado; Tormenta no usa lluvia interior. La música y ambiente cambian con crossfade suave y no reinician por reconstruir un panel. La revisión reduce la música y hace más presente el lugar; el motivo instrumental no debe ocupar el espacio de un golpe. Música debajo de contacto y avisos; duck de 3–6 dB de 300–800 ms en firma, fase y resultado. No duck en cada golpe pesado. Evitar fundir colas de KO dentro del siguiente anuncio.

Bucles de fuente no se dan por perfectos: se inspeccionan extremos, se editan a ciclos estables con solapamiento/ecualización compatible y se verifican dos vueltas. Guardar fuente y edición. No poner una canción con crescendo y final abrupto a repetir sin trabajo de sonido.

## 6. Interfaz y progresión

Un clic táctil de cuero/madera/bronce une todas las pantallas del sistema visual. Navegación breve y tenue; confirmación una vez en una acción válida; errores con menor nota/gesto amortiguado. Foco de teclado y ratón usan la misma semántica. No sonidos al reconstruir widgets, sondear login o recibir estado sin cambios. Botones deshabilitados permanecen silenciosos. UI global al centro, sin panning de combate.

Mejora, reclutamiento, subida de nivel, encuentro completado, jefe derrotado y cosmético confirmado se disparan después del commit local o respuesta Online válida y actual. Las animaciones contables no producen un sonido por cada punto de XP. Victoria/derrota conservan fondo del combate y una resolución corta de la misma familia. El backlog separa estos avisos; el primer slice incluye confirmación y resultados, no presume haber terminado toda la UI.

## 7. Mezcla e implementación

AudioDirector central y manifiesto de eventos, perfiles como datos. Buses: Master; Music; Ambience; SFX como padre de Combat, Movement, UI y Voice. No reverbs globales largos. Pool acotado, prioridades y cooldowns por evento/fuente. El director selecciona variantes evitando repetición inmediata, con RNG de presentación independiente. Tono de Combat y Movement fijo a 1.0 en esta revisión; ganancia de los impactos ±0.5 dB y variación tenue de movimiento. Música/UI tonal sin aleatorizar notas.

Master mantiene headroom. Preparar fuentes a 48 kHz PCM16 mono; camas en OGG estéreo. Objetivo de pico de archivo ≤ −3 dBFS, fades mínimos y conservación de la envolvente. Medir DC antes de corregirlo: la media de un transitorio asimétrico no prueba un defecto. La ganancia positiva de preparación tiene un techo de **+12 dB**; una fuente débil no se rescata amplificando ruido. Para golpes, la preselección exige pico de fuente ≥ −18 dBFS y contacto breve identificable por la envolvente; aun así requiere escucha.

Las ganancias de reproducción mantienen el contacto delante: UI −18 dB; aire rápido/pesado −17/−15; pisadas −18; cuerpo ligero/pesado −8/−6; carga/liberación de Ascua −19/−17; ambiente −19; música −20. Son ajustes del catálogo, no mediciones de una captura final. El acento de crítico es aditivo a −10 dB, físico y breve. Master conserva una sola etapa `Brasa Master Safety`: +7 dB de preganancia y limitador con techo nominal −1 dB, junto al fader y mute del usuario. El techo nominal no sustituye la medición de true peak de cada captura.

Controles persistentes Master / Music / SFX; ambiente y Voice dentro de la mezcla con opción apropiada si hay bancos reales. Mute conserva valores. Usar el modal y estilos compartidos de Historia, foco y etiquetas accesibles. La configuración es un archivo de preferencias propio; no alterar el progreso del usuario al abrir Ajustes ni durante pruebas.

Localización estéreo sutil (izquierda/derecha según combatiente); prioridad KO/firma > crítico/contacto > poder > movimiento > decoración. Cortar o rechazar sonidos de baja prioridad bajo saturación, nunca bloquear el hilo. Cachear bancos usados; no cargar los 17 perfiles completos por entrar al menú. Liberar contexto y colas al cerrar Replay. Tolerar archivos pendientes sin error ni tonos sintéticos sorpresa.

## 8. Producción y primer slice

El plan cubre contacto, defensa, movimiento, identidad de Ascua (carga, liberación, firma, fase y reacción), KO, inicio, resultados, confirmación, ambiente y música. La revisión V2 sustituye las familias que no cumplen la dirección física. La revisión integrada contiene 51 archivos: 20 de las nuevas generaciones, 30 originales reprocesados a velocidad natural y una pieza musical conservada. Las variantes elegidas y las dos capturas nativas constan en AUDIO-DELIVERY.md; el número de descargas o candidatos no cuenta como entrega. El backlog amplía variación cuando se apruebe el carácter acústico. No fingir que cambios de pitch son variantes originales.

Orden: P0 legibilidad → P1 identidad y KO/firma → P2 lugar/música → P3 confirmación esencial → P4 queda para después de escuchar y revisar. El plan incluye prompts en inglés descriptivos por fuente, duración, material, sequedad, intensidad y exclusiones; no se envía el repositorio ni datos privados a ElevenLabs. Music se crea en la herramienta de música de la misma sesión Chrome, no como ruido ambiente disfrazado de canción.

Cada descarga debe registrar grupo, prompt exacto, duración elegida, variante, archivo fuente, hash, créditos observados cuando disponibles, edición y destino. Rechazar/reeditar tomas con introducciones largas, voz accidental, golpes múltiples cuando se pidió uno, colas invasivas o timbre fuera del mundo. La cantidad de candidatos que entregue la web se documenta; no asumir número fijo por generación.

Se conservan originales y hashes separados de cada edición. La política vigente usa `process_natural.py`: **velocidad y tono originales, sin `atempo`, sin estiramiento temporal y sin normalización de rescate por encima de +12 dB**. El procesador conserva el ataque y la cola activa; un límite de duración rechaza una toma demasiado larga, no la comprime. El ambiente mantiene estéreo y sólo admite un solapamiento circular pequeño, documentado. La música no se acelera para forzar BPM o bucle. Las ediciones anteriores con compresión temporal quedan como evidencia histórica, no como receta de V2.

Las mediciones de discontinuidad, energía y envolvente orientan la selección y no aprueban realismo o naturalidad musical. Procedencia integrada: `../assets/audio/SOURCE-MANIFEST.json`; escucha comparativa: `audio-asset-review.html`. `measure_mix.py --playtest-dir RUTA` mide los WAV de esa captura y vincula su demo mediante hashes; `validate_assets.py --playtest-dir RUTA` incorpora esa misma evidencia al informe y HTML. La ruta predeterminada histórica se conserva y una revisión nueva debe indicar su carpeta explícita.

## 9. Puerta de revisión

Antes de generar: inventario, perfiles, mapa musical, eventos de combate/UI, transformaciones/jefes y backlog presentes. Después: importar, prueba de carga, prueba del enrutamiento semántico (fallo/esquiva/absorbido/crítico/firma/KO), sesión real offline con fixture, Replay y Online Replay sin mutaciones, pausa/×2/movimiento reducido y cambios de volumen. Verificar falta de clipping, colas, densidad, cortes, repetición y bucles con una captura de mezcla real.

Las mediciones de pico/RMS y capturas de forma de onda no sustituyen el juicio auditivo. El informe de validación debe distinguir pruebas automáticas, reproducción en Godot y escucha humana, y dejar explícito cualquier límite. Entregar un demo reproducible con fuentes reales de ElevenLabs y avances de la sesión, sin tocar partidas del usuario. Sólo después de revisar este slice procede producir el resto del elenco.
