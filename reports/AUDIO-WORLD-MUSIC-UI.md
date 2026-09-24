# Brasa — auditoría de mundo, música e interfaz

Auditoría de sólo lectura realizada el 21 de septiembre de 2026, antes de generar audio. Los nombres de cues, BPM, capas y parámetros que siguen son **propuestas**, no activos existentes ni resultados de escucha. La dirección general y el primer corte de producción los fija `AUDIO-BIBLE.md`; este informe concreta sus lugares y acciones reales.

El inventario completo, con 27 fuentes y sus SHA-256, mapa de los 11 capítulos, puntos de integración y prompts de generación, está en `../../../work/audio/audit/world-ui.json`. No se abrió una partida, no se usó el navegador ni se generó audio durante esta auditoría.

## 1. Qué existe ahora

`main.gd:1763` sintetiza nueve tonos de seno y segundo armónico en memoria: hit, critical, dodge, upgrade, start, win, lose, ability y signature. Son WAV mono de 22.050 Hz y 16 bits, de 0,11 a 0,75 s. Cinco `AudioStreamPlayer` a −10 dB reproducen la primera voz libre, por Master; si todas están ocupadas se descarta el sonido nuevo. No hay variaciones ni prioridades. `_play_sound`, línea 1788, también omite sonido en headless.

La búsqueda de fuentes no encontró música, ambientes o archivos WAV/OGG/MP3/FLAC/Opus en `assets`, ni otros reproductores o un layout de buses. Online, Replay y componentes de UI no reproducen audio. Ajustes sólo cambia `sound_enabled`: evita llamadas futuras, no detiene colas ya audibles y no persiste el valor. La preferencia de movimiento reducido sí se guarda, pero es otra función (`main.gd:1223–1240`).

| Decisión | Elementos |
| --- | --- |
| KEEP | Tiempos/eventos de combate; resultados de transacciones; señales de usuario; identidad y apariencia; reloj de Replay; generaciones e idempotencia Online. |
| REWORK | Un mismo `start` para elegir compañero, comenzar capítulo y combatir; `upgrade` para entrenar, talentos, técnicas, respec, apariencia y activar sonido; política de voces y silencio. |
| REPLACE | Timbre de los nueve tonos provisionales. Conservar sus puntos semánticos útiles no obliga a conservar sus pitidos. |
| MISSING | Música, ambiente, superficies, jerarquía de UI y premios, paridad Replay/Online, director central, mezcla y controles persistentes. |

La firma reproduce hoy el mismo tono en el anuncio (`main.gd:1087`) y en el impacto (`1043`). La nueva dirección debe distinguir anticipación y contacto, con una sola reproducción de cada gesto; no repetir dos veces una liberación completa.

## 2. Lugares reales y materiales

Se inspeccionaron visualmente las siete ilustraciones finales y su selección en código. El lenguaje es pintura cálida y tangible: cuero cosido, tela, madera, bronce amortiguado, piedra, tierra, faroles ámbar y profundidad azul petróleo. La música debe dejar el mismo aire que la composición visual. No necesita electrónica de interfaz, fanfarrias de tráiler o una capa de fuego continuo.

| Lugar | Evidencia visible | Traducción sonora propuesta |
| --- | --- | --- |
| Arena Faroles | Patio circular naranja de tierra/terracota compacta; bordes de piedra, ciudad de adobe, toldos, banderines, palmas, luna y agua lejana. | Contacto seco y granular, aire nocturno, tela ocasional. Sin estadio ni aplausos inventados. |
| Arena Tormenta | Losas húmedas, arcos y templos de montaña, lago y cascadas visibles, nubes iluminadas por la luna y faroles. | Piedra firme con humedad mínima, agua lejana y aire abierto. No barro, chapoteos profundos, lluvia continua o truenos automáticos. |
| Ruta Journey | Sendero/terraza de piedra entre montañas, árboles laterales, estandartes y cascadas lejanas al atardecer. | Aire de valle y agua distante, tema de marcha tranquila. Los árboles no crean una nueva arena de bosque. |
| Ruta Storm / Late | Ruinas, raíces, suelo mojado y niebla de montaña; capítulos posteriores reutilizan esa pintura con tinte. | Variación suspendida del mismo viaje. No producir otro bioma por el título de cada encuentro. |
| Taller / Técnicas / Creación | Patio de entrenamiento abrigado, bolsas de cuero, bancos de madera, tejidos y faroles. | Cuerda apagada y tacto de tela/madera. No se ve una forja en operación: sin martillos o maquinaria ambiental. |
| Refugio / Compañeros / Menú | Tiendas, suelo terroso, faroles y brasas de cocina junto a una tetera. | Aire calmo, tela y fuego pequeño, no rugido de incendio. |
| Legado / Historial | Arcos de piedra, telas, cofre y abertura al exterior. | Silencio de sala ventilada, música sobria. No cueva embrujada, voces ni coro. |

Los objetos decorativos aparecen por estado real del jugador. No disparar sonido cada vez que se reconstruye un farol, medalla, venda o brasero. El bucle de brasas del refugio se justifica por su pintura; un prop desbloqueado no requiere por sí solo un emisor nuevo.

### Capítulos y jefes

La fuente autoritativa es `campaign_config.gd:15` (`CHAPTERS`), no el nombre narrativo de la misión:

| Capítulo | Encuentros | Fondo de combate | Jefe de cierre |
| --- | --- | --- | --- |
| 1 · El camino de los faroles | 1–8 | Faroles | Ascua |
| 2 · El paso de la tormenta | 9–16 | Tormenta | Véspera |
| 3 · El juramento del puente | 17–20 | Faroles | Taro · Juramento de jade |
| 4 · El jardín de los ecos | 21–30 | Faroles | Iria · Jardín de ecos |
| 5 · Las sendas entrelazadas | 31–40 | Tormenta | Luma · Las nueve sendas |
| 6 · El horno del solsticio | 41–50 | Faroles | Ascua · Corazón del solsticio |
| 7 · Los rostros del regreso | 51–60 | Tormenta | Duna · Fortaleza del regreso |
| 8 · La escuela del relámpago | 61–70 | Tormenta | Kiro · Rugido del relámpago |
| 9 · El círculo de los maestros | 71–80 | Faroles | Neris · Círculo de los maestros |
| 10 · La víspera de las estrellas | 81–90 | Tormenta | Sira · Filo de las estrellas |
| 11 · El último eclipse | 91–100 | Tormenta | Véspera · El último eclipse |

**Véspera es el jefe final.** Ascua reaparece en el 50. Sus fases están en `story_catalog.gd:220`: Ascua pasa a Horno vivo al 60% y Última ascua al 30%; Véspera a Alas del vendaval y Ojo de la tormenta. Ya llegan como `ability_id: phase_shift` y `phase_index`, consumidos por Main y Replay. Una capa musical puede responder a esos eventos sin crear nuevas reglas.

Hay una distinción importante: Ruta usa `journey` en capítulo 1, `storm` en el 2 y `route_late` después (`story_panel.gd:367`); el combate sigue la tabla anterior (`main.gd:432`). Online muestra Tormenta en su menú, pero Replay resuelve `snapshot.rival.story_chapter_id`, con capítulo 1 como valor por defecto (`battle_replay_panel.gd:170`). Un combate online sin ese dato muestra **Faroles**. El perfil acústico debe seguir el fondo realmente resuelto; no se cambia el escenario visual en esta tarea.

## 3. ArenaAudioProfiles propuestos

| Campo | `arena_faroles` | `arena_tormenta` |
| --- | --- | --- |
| Resolución | `arena-faroles-v2.png`, también fallback real | `arena-tormenta-v3.png` |
| Música | `mus_battle_faroles`, 96 BPM | `mus_battle_tormenta`, 120 BPM |
| Ambiente | `amb_faroles_air`; tela muy ocasional | `amb_storm_water` + `amb_mountain_air` |
| Suelo | `earth_packed_dry` | `stone_wet` |
| Espacio | Exterior seco; reflejo leve de bordes, decay de partida 0,3 s | Exterior con piedra; reflejos cortos dispersos, decay de partida 0,55 s |
| Público | Ninguno inicialmente | Ninguno |
| Acentos opcionales | Tela; mecha casi inaudible | Gota aislada bajo arco, infrecuente |
| Inicio | Pickup de un compás, sin retrasar el motor | Pickup de un compás, sin retrasar el motor |
| Resultado | Cama baja y un sting; aire permanece | Cama baja y un sting; agua/aire permanecen |

Los valores de reverb son puntos de escucha, no medidas del escenario. Foley seco separado del envío de espacio; UI centrada y seca fuera del bus de reverb. Bastan dos superficies de combate: seis variantes iniciales de paso y tres de roce/aterrizaje por suelo. El cuerpo aporta peso, tejido y reacción por otra capa, coordinada con el inventario de personajes. No duplicar cuerpo y pisada al generar el banco de superficie. Las previews estáticas del taller/refugio no necesitan pasos en bucle.

## 4. Mapa musical y parentesco

Motivo **Farol** propuesto: 1–♭3–5–2, D–F–A–E en re menor; respuesta lunar 2–5–♭3–1. Es una célula original para dirigir la escucha, no una promesa de que un generador obedecerá exactamente las notas. La biblia maestra fija Faroles a 96 BPM; este inventario ya está alineado. Las otras velocidades son propuestas posteriores al primer corte.

Cuerda pulsada cálida, apoyo grave frotado, percusión de piel y madera, bronce redondo y aliento de flauta conectan toda la familia. El registro, la densidad y el silencio distinguen refugio, patio, montaña y jefe. No se atribuye autenticidad ritual a una cultura real ni se copia una canción. La fauna del roster no exige cambiar a un estereotipo nacional cuando se selecciona un cuerpo cosmético.

| ID / uso | BPM | Instrumentación y pulso | Loop propuesto | Intro / final |
| --- | --- | --- | --- | --- |
| `mus_home` · menú, refugio, compañeros, ajustes | 80 | Pulsada cálida, arco suave, madera escasa, bronce apagado; respiración amplia. | 48 compases, 144 s | 1 compás / cola de 3 s |
| `mus_route_journey` · Ruta 1 | 96 | Pulsada y flauta de madera, tambor de mano tenue; caminar sugerido. | 64, 160 s | 1 / 3 s |
| `mus_route_storm` · Ruta 2 y posteriores | 96 | Arreglo de Journey con aire y armónicos, más suspensión. | 64, 160 s | 1 / 3 s |
| `mus_workshop` · entrenar, técnicas, crear, personalizar | 80 | Arreglo de Home, ataques apagados y repetición paciente. | 32, 96 s | 1 / 3 s |
| `mus_archive` · Legado, historial | 80 | Arreglo de Home a sensación de medio tiempo, bronce muy escaso. | 32, 96 s | 1 / 3 s |
| `mus_battle_faroles` · combate normal | 96 | Mano/madera seca, cuerda grave pulsada, respuestas cortas del motivo. | 64, 160 s | 1 / 3 s |
| `mus_battle_tormenta` · combate normal | 120 | Madera hueca más ágil, armónicos y frases aéreas, sin alfombra de agudos. | 64, 128 s | 1 / 3 s |
| `mus_boss_ascua` · encuentros 8/50 | 104 | Tambor grave ceñido, arco y bronce bajo; amenazas con pausas. | 64, 147,69 s | 1 / 3 s |
| `mus_boss_vespera` · encuentros 16/100 | 120 | Flauta aireada, armónicos, pulso circular, contraste de registros. | 64, 128 s | 1 / 3 s |

Son **nueve camas lógicas**, con arreglos derivados; no nueve composiciones desconectadas. Los capítulos 3–11 no requieren una pista nueva por nombre. Élites y jefes del roster usan la cama de la arena con presión contenida; sus motivos particulares pueden añadirse cuando se aprueben los perfiles de personaje. Ascua y Véspera sí tienen identidad propia. El encuentro 100 añade al arreglo lunar una respuesta grave de Farol; no recicla la fanfarria normal como final de campaña.

Cinco variantes previstas: élite Faroles, élite Tormenta, presión de Ascua, presión de Véspera y arreglo final Eclipse. La misma capa de presión entra tenue en fase 1 y más presente en fase 2. Generar después del padre aprobado. Dos generaciones independientes no son automáticamente stems sincronizados: verificar tempo, armonía, frases y muestras; si no encajan, usar un arreglo completo alternativo y crossfade seguro.

Cinco resoluciones: victoria normal 2,4 s; derrota 1,6 s; empate 1,6 s; capítulo completado 4 s; campaña completada 6 s. Elegir **una** por resultado. Las recompensas mayores sustituyen el sting normal. La derrota conserva dignidad y permite la XP positiva y el reintento; no burlas ni alarma. El empate sólo se usa cuando los datos realmente lo identifican y respeta `viewing_side`.

La música conserva posición al refrescar o pasar entre pantallas de la misma familia. Abrir Ajustes encima del combate baja la cama, no inicia Home desde cero. Las capas musicales pueden entrar en el siguiente compás; contactos, KO y acciones no esperan ese compás. ×2 no acelera ni cambia el tono de música/voz. La selección de un jefe en Ruta permite tensión ligera, no su introducción completa cada vez que se navega.

## 5. UI: intención frente a confirmación

Todos los cues nuevos son ausentes hoy. La tabla identifica dónde ya hay señales/retornos útiles y dónde falta un evento semántico; no propone que los helpers visuales de estilo reproduzcan sonido.

| Acción | Hook actual | Audio observado / integración propuesta |
| --- | --- | --- |
| Menú, abrir/cerrar modal | `home_panel.gd:71`; `game_modal.gd:104,117`; `main.gd:1292,1364` | Sin sonido. Tela breve al abrir, regreso bajo al cerrar; una vez por transición. |
| Pestaña, ruta, capítulo, Legado | `story_panel.gd:198,573,579,988` | Sin sonido. Navegación muy tenue sólo si cambia una selección deliberada. Configure, restaurar foco y rebuild son silenciosos. |
| Elegir compañero | `main.gd:374,1269` | `start` tras selección. Sustituir por selección de compañero, no anuncio de combate. |
| Stat local | `main.gd:382,878` | `upgrade` si devuelve éxito. Clic de ajuste más pequeño que una técnica o talento. |
| Técnica/talento/respec local | `main.gd:391,396,409` | Todo `upgrade`. Técnica/talento más firme; respec sólo confirmación, no premio de nivel. |
| Resultado/nivel/desbloqueo | `main.gd:1161,303`; `story_progression.gd:434,572` | Sólo win/lose. Ya existen `level_before/after`, `level_ups`, `moves_unlocked`, `cosmetics_unlocked`: emitir un grupo confirmado, sin un sonido por punto XP. |
| Nuevo capítulo / archivo | `main.gd:418`; `story_panel.gd:988` | Inicio reutiliza start. Completar por primera vez merece sting; ver archivo no concede otro premio. |
| Color, cuerpo, efectos, estilo | `customization_panel.gd:344,358` | Borrador silencioso. Tela leve al cambiar; apariencia no significa poder nuevo. |
| Aleatorio/preset | `customization_panel.gd:389,407` | Un cambio de borrador: un cue, no seis por slots. |
| Confirmar identidad/crear | `customization_panel.gd:429`; `main.gd:269`; `online_panel.gd:929` | La señal confirmed es intención. Éxito sólo tras guardar identidad y progreso requerido, o respuesta remota válida. Crear actualmente puede encadenar start+upgrade; unificar en un gesto. |
| Cancelar/error/nombre | `customization_panel.gd:422,436` | Regreso pequeño; error nuevo amortiguado; escritura del nombre silenciosa. Repetir layout del error no lo reproduce. |
| Retador online | `online_panel.gd:472,746` | DTO real y selección ya disponibles. Clic al elegir; lista vacía y desafío fallido no anuncian combate. |
| Mejora/IA/talento/remoto | `online_panel.gd:750–820` | Sin sonido. `_mutate` después de `_current(stamp)` y `response.ok` es el límite fiable; dedupe por operación/revisión. |
| Entrar con navegador | `online_panel.gd:253,289`; `online_api.gd:103` | Continue mínimo; una entrada cuando la sesión pasa de no válida a válida. Poll, WAIT, pending y slow_down quedan mudos. Ningún sonido de «seguridad» en passkey nativa. |
| Cancelar/salir de sesión | `online_panel.gd:275,897,970` | Regreso discreto. Cancelación no es error; borrar sesión local no equivale a confirmar revocación remota. |
| Pendiente/reintentar/error red | `online_panel.gd:777,820,943,968` | Silencio durante espera/countdown; aviso único ante fallo nuevo. Una respuesta descartada por generación no produce sonido. |
| Actividad mientras no estabas | `online_panel.gd:658,770` | Un aviso tenue por lote nuevo no vacío. ACK no gana XP; no fanfarria por cada fila o refresh. |
| Reproducir/historial online | `online_panel.gd:840,874`; `battle_replay_panel.gd:170–226` | Todo silencioso actualmente. Mismo audio de combate por tiempo/índice; nunca eventos de recompensas nuevas al ver un combate guardado. |
| Sonido / velocidad / movimiento reducido | `main.gd:1218–1240,1468` | Sólo activar sonido reproduce upgrade. Faltan buses/volúmenes; no tick por frame de slider. Movimiento reducido y silencio son preferencias distintas. |

La UI debe ser seca, centrada y más discreta que un golpe. Navegación de 40–90 ms, seleccionar 80–160 ms, confirmar 180–300 ms; cuero/madera/bronce, no pitidos. Hover de puntero apagado por defecto. Foco de teclado deliberado puede compartir navegación; el foco programático no. Botones deshabilitados son silenciosos; un ítem bloqueado que acepta interacción para explicar requisito puede dar un golpe amortiguado.

Las 16 familias propuestas incluyen navegar, seleccionar, confirmar, volver, abrir, bloquear, error, stat, build, equipar en preview, nivel, técnica desbloqueada, cosmético desbloqueado, creación, entrada de cuenta y lote offline. Cues frecuentes tienen 2–3 variantes. Los avisos de recompensa de 0,65–1,4 s comparten el motivo y se agrupan para evitar melodías simultáneas.

## 6. Requisitos de integración y QA

Main tiene `_dispatch_events` (`955`), Replay `_apply_event` (`226`) y un reloj/índice explícito. Un consumidor central puede cubrir ambos sin tocar el motor ni cambiar eventos guardados. El perfil de arena deriva del fondo resuelto, la identidad del descriptor y el resultado de su perspectiva. Un único director controla la cama de música para que un overlay no cree otro reproductor independiente.

En Replay, reiniciar/cerrar invalida generación y cancela colas; no reproducir en ráfaga eventos pasados al seleccionar. Reproducir otra vez el desenlace puede tener su sting cinematográfico, pero jamás el sonido de un nivel/cosmético recién concedido. Online usa el mismo panel, conserva la autoridad del servidor y no toca XP local. Firmas y fases usan eventos existentes; no disparar música desde partículas ni inventar probabilidades o cambios de estado.

Mezcla y entrega siguen la biblia maestra: audio físico legible, ambientes bajos y compatibles con mono, pistas con headroom, UI fuera de reverb de arena. Los valores de duck/volumen son metas de escucha, no mediciones de tomas inexistentes. Probar pausa, cierre, ×2, movimiento reducido, dos vueltas de loop, límite de voces y silencio total en todas las rutas. Testear con fixtures aisladas; no autenticar ni modificar una cuenta real.

El backlog JSON contiene **49 IDs lógicos**: 9 camas, 5 variantes, 5 stings, 8 ambientes, 6 familias de superficie y 16 de UI. Cada fila incluye uso, duración, loop, descripción, intensidad, material, lugar/personaje cuando aplica, variantes, sequedad/reverb, tonalidad, exclusiones y prompt ElevenLabs. Música añade BPM, modo, motivo, instrumento, introducción/final y dependencia del padre. Las variantes y archivos intro/final aumentan el total de entregables; no son 49 archivos finales ni una orden para generarlos todos.

Primero aprobar Faroles + combate físico de un luchador + resultado y el mismo Replay. Después completar identidad, jefe, Tormenta, navegación y progresión según prioridades de la biblia. Guardar toma original, prompt exacto, procedencia, hash y parámetros medidos; rechazar voz accidental, timbre ajeno, gestos múltiples cuando se pide uno, transitorios invasivos o loops que no cierran. Las notas exactas, BPM y sincronía de stems se verifican, no se asumen por estar en un prompt.
