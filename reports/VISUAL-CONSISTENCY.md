# Consistencia visual de personajes

> Actualización de producción: [escala, transparencia y daño localizado](SPRITE-PRECISION.md). Esta revisión sustituye las comparativas y hashes visuales históricos de este documento.

La biblioteca utiliza **17 perfiles visuales y 680 poses en 51 bancos**: 8 poses base, 16 de movimiento y 16 de reacción por cuerpo. La escala física procede del perfil canónico; la pose modifica la postura y la silueta visible, sin cambiar el tamaño del personaje para encajar en una caja.

La auditoría original clasificó **344 poses KEEP, 208 FIX y 128 REGENERATE**. Se sustituyeron los **21 bancos afectados, equivalentes a 336 poses**, conservando las otras 344 ilustraciones y normalizando toda la biblioteca. Sustitución de fuente, revisión estática, normalización y aceptación en animación son hitos distintos. **La integración final pasó la revisión estática y nativa; los 51 bancos están aceptados para esta entrega.**

Fuentes de inventario: [auditoría por pose](../../../work/visual-consistency/audit/audit.json), [dictamen estático original](../../../work/visual-consistency/audit/AUDIT.md) y [manifest de producción](../assets/sprites/normalized/manifest.json). Los documentos de auditoría describen el estado anterior; sus propuestas ilustrativas de canvas o densidad no sustituyen el contrato final siguiente.

## Antes / Después — Before / After

| Aspecto | Antes | Después |
|---|---|---|
| Autoridad visual | Referencias base reconocibles, con cambios de anatomía, masa o material en bancos posteriores. | Referencia canónica, hash, materiales, proporciones proyectadas y altura deliberada por cuerpo; 336 poses sustituidas contra esa referencia. |
| Escala | Altura base uniforme de 166 y factores separados derivados de la altura de referencia de cada banco en runtime. | Alturas deliberadas de 146–214 unidades de mundo; normalización offline con un factor uniforme por banco y densidad global 1.5. |
| Canvas y raíz | Rectángulos variables; recorte alfa y corrección de elevación derivados de la silueta. Algunos apoyos desplazaban la raíz al pie extremo. | Celdas completas de 512×512, pivot [256,448], línea de suelo 448 y raíces revisadas; el alfa no decide escala, pivot ni altura del salto en runtime. |
| Carga y materiales | La luz de carga o forma afectaba a todo el cuerpo; algunos bancos ya tenían materiales lavados en la fuente. | Cuerpo normal estable, flash de impacto acotado y energía anatómica en una capa independiente; las fuentes defectuosas se reemplazan. |
| FX y suelo | Partículas orgánicas existentes, con contactos temporales aproximados y anclajes proporcionales al rectángulo visible. | Marcadores por fase, sockets explícitos y suelo proyectado; las partículas emitidas quedan en espacio de mundo. |
| KO y victoria | Algunas órdenes podían interrumpir estados terminales; la pose final volvía al banco base antiguo. | KO prioritario, victoria ligada al resultado resuelto y pose normalizada final sostenida. La celebración de preview tiene API separada. |
| Retratos | Algunas pantallas ajustaban cada cuerpo o reservaban el espacio completo de combate. | Cámaras compartidas por presentación, proporciones conservadas y preview móvil de Nima de aproximadamente 80 a 129 px en el fixture revisado. |
| Aceptación | Una ilustración reconocible podía parecer válida por sí sola. | Comparación con canon y poses vecinas, diagnóstico geométrico y revisión nativa de la secuencia completa como requisitos separados. |

## Inventario y escala deliberada

El perfil corresponde al **cuerpo visual**, no a la cuenta, nivel o arquetipo de combate. Elegir otro cuerpo cosmético no modifica estadísticas. Hay 15 cuerpos jugables y 2 jefes.

| Cuerpo | Altura de pie en mundo | Bancos de fuente sustituidos |
|---|---:|---|
| Nima | 164 | reactions |
| Luma | 158 | — |
| Mugo | 196 | movement |
| Sira | 184 | movement |
| Iria | 160 | movement |
| Duna | 178 | movement |
| Kiro | 180 | movement, reactions |
| Neris | 182 | movement, reactions |
| Taro | 184 | movement, reactions |
| Balam | 182 | movement, reactions |
| Tepa | 146 | movement, reactions |
| Xuna | 174 | — |
| Copal | 152 | movement, reactions |
| Onix | 154 | — |
| Bruma | 186 | movement |
| Ascua | 214 | movement |
| Véspera | 204 | movement, reactions |

Estas alturas incluyen los rasgos fijos de la silueta de pie, como orejas o cuernos. Son decisiones de diseño en unidades compartidas, no centímetros reales. Agacharse, caer, levantar un brazo o extender una cola cambia la silueta visible; no redefine esta altura.

## Perfiles y normalización offline

[character_visual_profiles.json](../data/character_visual_profiles.json) registra autoridad de idle, color, material, iluminación, equipamiento, tamaño, ratios proyectados, landmarks y variantes. [CharacterVisualProfile](../scripts/character_visual_profile.gd) valida y expone el contrato común:

| Campo | Valor de producción |
|---|---|
| Versión del perfil / pack | 1 / 2 |
| `profile_id` normal | `<body>:normal:v1` |
| `canvas_px` | [512,512] |
| `pivot_px` | [256,448] |
| `ground_baseline_px` | 448 |
| `pixels_per_world_unit` | 1.5 |
| Dibujo del canvas en runtime | Escala fija 1/1.5 antes de la cámara de escena |
| Atlas base | 2048×1024, 8 celdas |
| Atlas movement / reactions | 2048×2048, 16 celdas por banco |

El [normalizador](../../../work/visual-consistency/audit/normalize_roster.py) calcula una vez por banco `factor = altura_canónica_mundo × 1.5 / reference_height_fuente`. Aplica exactamente ese factor a todos sus fotogramas, con el pivot de fuente anotado, y compone cada resultado en el mismo canvas. Los bancos pueden proceder de resoluciones distintas; ningún fotograma recibe una escala correctora propia. La raíz puede anotarse por pose para colocar correctamente la figura dibujada, sin derivarla automáticamente del centro de su caja alfa o del único pie apoyado.

Los rectángulos de extracción son almacenamiento de la fuente, no marcos de ajuste visual. Si dos rectángulos incluyen regiones vecinas, `component_isolation_alpha_threshold` y `component_id` separan los cuerpos. Un desbordamiento del canvas hace fallar la normalización: no se encoge la pose para ocultarlo. La extracción y el remuestreo conservan el original y registran hashes, factor y coordenadas de origen.

La revisión nativa rechazó las primeras correcciones de movimiento de Mugo, Iria, Bruma y Sira por simplificación de materiales. La siguiente pasada usa grupos de cuatro poses con el idle canónico como primera autoridad visual. Cada familia conserva una sola densidad y se compone por traslación, sin corregir la escala de poses individuales. Los candidatos y rechazos permanecen en `work/visual-consistency/generated/audit-fixes/` para distinguir una mejora comprobada de una mera nueva generación.

Los packs se guardan en `assets/sprites/normalized/<body>-<bank>-v2.png/.json`. [FighterAnimationSet](../scripts/fighter_animation_set.gd) comprueba identidad, canvas, pivot, densidad, orden de poses y regiones completas. Conserva compatibilidad con packs antiguos, identificados como fallback, sin considerarlos aprobados por ello. `alpha_bounds_px` es una medición offline para diagnóstico de píxeles pintados; no dirige el render, la escala ni el salto. `intrinsic_lift_px: 0` evita una segunda corrección basada en el pie visible; la articulación dibujada y la trayectoria de Godot mantienen funciones distintas.

## Animación híbrida y tres capas

**1. Cuerpo.** [FighterView](../scripts/fighter_view.gd) selecciona poses y dibuja el canvas completo. Los sprites aportan postura, expresión y deformación articulada; Godot aplica desplazamiento, salto, retroceso, rotaciones pequeñas, pausa e hit stop. El shader conserva paletas cosméticas y flash de impacto acotado; se retiraron la luz global de carga y el baño de color global de transformación.

**2. FX ligados al cuerpo.** Un segundo `Sprite2D` consume un atlas pareado opcional o la textura anatómica de [AttachedEnergyTrack](../scripts/attached_energy_track.gd). Comparte exactamente frame, canvas, pivot, posición, espejo, escala y rotación con el cuerpo. No tiene un segundo reloj de animación. La intensidad usa el mismo avance de carga/recuperación o transformación; reposo normal y KO apagan la emisión. `attached_fx_enabled` permite comparar con el cuerpo sin FX durante QA. Un fotograma sin entrada válida no conserva accidentalmente la energía del anterior.

El generador anatómico actual está implementado para **Ascua**, desde sockets de núcleo y mano anotados en la pose. Sus radios son 12 y 10 px y su alfa máximo es 0.35; no lee ni repinta la textura corporal. Un núcleo sin anotación u oculto no emite; una mano oculta tampoco. Otros cuerpos admiten el contrato de atlas pareado, pero no se inventan núcleos anatómicos para ellos. `effect_anchor()` utiliza sockets explícitos y zonas fijas de compatibilidad cuando faltan; estas últimas no equivalen a landmarks anatómicos verificados.

**3. FX de mundo.** [CombatFX](../scripts/combat_fx.gd) compone polvo, estelas, brasas, impactos y fragmentos con el lenguaje de pigmento orgánico existente. Los emisores pueden seguir el origen mientras emiten; cada partícula se independiza en mundo al nacer. Suelo y pies usan la Y del piso y la X actual del contacto, sin seguir la elevación del sprite durante un salto. El presupuesto sigue acotado a 20 efectos/emisores, 320 partículas y 12 acciones pendientes.

El perfil `ember_core` define explícitamente la misma anatomía, canvas y densidad que la forma normal, con cambios de energía local permitidos. La transformación activada actualmente en clips es Ascua; registrar variantes de perfil en otros cuerpos no introduce por sí solo transformaciones jugables, estadísticas o nuevas bibliotecas de forma. Una futura alteración real de cuernos, armadura o silueta requiere una variante revisada y arte correspondiente.

## Marcadores, estados y autoridad de combate

[MoveVisualProfile](../scripts/move_visual_profile.gd) describe animación, impacto, estela, suelo, reacción, cámara, hit stop y campos de extensión para track, variante, sonido y requisito de transformación. Los eventos se resuelven desde las fases `windup`, `travel` y `recovery` del movimiento real. Los valores de extensión no crean automáticamente un nuevo asset ni un comportamiento de gameplay.

Hay marcadores de apoyo izquierdo/derecho, despegue, aterrizaje, inicio/final de deslizamiento, retroceso preparatorio, carga, avance, continuación y recuperación. `CombatFX.play_move()` conserva un cursor por acción, deduplica por actor/lado/tiempo/movimiento y procesa todos los marcadores cruzados en un frame. El impacto de daño sigue el evento autoritativo, no un marcador visual. Main y replay utilizan las mismas funciones y edades; los movimientos, daño, RNG, recompensas y registros no se recalculan desde la presentación.

Las 16 poses de movimiento de Ascua incluyen 32 contactos de suela anotados manualmente y proyectados al suelo. Sustituyen las zonas de pie genéricas del piloto, sin mover ni redimensionar el cuerpo. Las familias refinadas incorporan el mismo contrato de pies, núcleo y mano en sus sidecars. En una pose aérea, el socket proyectado expresa dónde se emite sobre el piso; no afirma que el pie dibujado esté apoyado. El resto de bancos conserva la zona fija de compatibilidad cuando falta una anotación específica.

KO interrumpe incluso una victoria visible. Una victoria real requiere `resolve_battle()` después del resultado; `preview_victory()` sirve a Historia y Creación. Ninguna orden cosmética revive un KO. Las poses finales `grounded` y `victory_peak` permanecen sostenidas sin volver al arte anterior. Los estados de diagnóstico distinguen reposo, carga, ataque, aire, recuperación, reacción, transformación y terminales. Reacciones de cabeza, cuerpo, zona baja, aire, guardia, estado, crítico y derribo reutilizan poses adecuadas; los aliases inválidos conservan un fallback seguro y no inventan zonas de daño.

## Cámaras comunes y retratos

Arena y replay aplican un encuadre común a ambos combatientes. El margen exterior de Arena es de 165 unidades, obtenido de una medición de 164.52; el espacio hacia el contacto sigue disponible. Se mide el roster para definir constantes compartidas, nunca para ajustar la escala de un actor al fotograma actual.

Historia y los previews en reposo usan `REST_ENVELOPE = Rect2(-122,-224,244,232)`. Creación selecciona cámaras compartidas explícitas: reposo/entrada, ataque `Rect2(-154,-224,308,232)` y victoria `Rect2(-132,-260,264,276)`. La selección ocurre al pulsar la acción y se mantiene durante toda la secuencia y su pose final. Puede cambiar una vez entre presentaciones elegidas; no persigue la silueta animada ni depende del personaje.

La medición de retratos cubrió 25.585 muestras de 17 cuerpos. En los fixtures revisados, Nima mide 129 px en reposo a 390×844 y 312 px a 1360×880. Las nuevas fuentes deben volver a pasar estas comprobaciones para que el encuadre siga conteniendo sus poses. Véanse [medición y revisión](../../../work/visual-consistency/portrait-framing/review.md) y [capturas nativas](../../../work/visual-consistency/portrait-framing/screens/screens.json).

## Flujo para añadir un personaje o banco

1. **Definir el canon antes de ampliar poses.** Elegir el idle y la autoridad de material, textura, iluminación y equipo; conservar fuente y hash. Fijar altura de mundo respecto al roster. Registrar landmarks, incertidumbre y cualquier variante legítima en `character_visual_profiles.json`.
2. **Registrar el cuerpo.** Añadir su relación de atlas/ID a `FighterAnimationSet.BASE_TO_BODY`; para una apariencia jugable, integrar el catálogo de personajes y `CosmeticCatalog.BODY_ASSETS`. Los jefes se registran también donde se construyen sus definiciones de Historia. No confundir identidad cosmética con arquetipo, progresión o cuenta.
3. **Preparar las poses necesarias.** Respetar los nombres y orden de `BASE_POSES` y `BANKS`; esos arrays son la autoridad del loader. Usar el canon como primera referencia y la secuencia anterior sólo para semántica de pose. Pedir una escala única, mismo ángulo, materiales consistentes, margen transparente y ausencia de FX externos horneados. Añadir transiciones cuando resuelvan una discontinuidad concreta, no para inflar el número de imágenes.
4. **Auditar la fuente.** Comparar cada pose con el canon y sus vecinas: cabeza, torso, extremidades, cola/cuernos, equipo, textura e iluminación. Revisar escorzo local sin tolerar crecimiento de todo el cuerpo. Registrar KEEP/FIX/REGENERATE con motivo. Regenerar una anatomía incorrecta; no compensarla con una escala por frame.
5. **Preparar RGBA y sidecar.** Conservar original, prompt y resultado. La limpieza técnica del fondo debe estar autorizada, proteger materiales y registrar qué píxeles cambia. Anotar regiones, pivots de fuente, un `reference_height` común, sockets y visibilidad; si falta una medida, dejarla ausente en vez de inventarla.
6. **Normalizar offline.** Incorporar la referencia de fuente requerida por el normalizador —incluido `canonical-runtime-before.json` para un cuerpo nuevo— y pasar overrides explícitos de los bancos revisados. Ejecutar el factor único y comprobar que ninguna pose desborde. Importar los tres packs v2; mantener trazabilidad y fuentes de fallback.
7. **Conectar presentación.** Elegir clips y marcadores dentro de los tiempos existentes. Un track pareado debe tener las mismas regiones, canvas y pivot. Anotar oclusión. Cualquier reflejo corporal nuevo necesita una máscara localizada revisada; la ausencia de máscara conserva el material normal.
8. **Validar la secuencia real.** Ejecutar loaders, geometría, clocks, estados terminales, FX, cámaras y UI. Reproducir ambos sentidos, ataques/carga, reacciones, caída/levantarse, KO sostenido y victoria, con pausa, hit stop, movimiento reducido y replay ×1/×2. Comparar cuerpo solo y FX activados. Revisar móvil, escritorio y los cruces entre bancos. Registrar arte y runtime por separado antes de aprobar.

## Límites de la medición y de la aceptación

Los landmarks y ratios anatómicos son **estimaciones manuales de proyección 2D con incertidumbre de ±8 px**. El umbral relativo del 8% es una señal para revisar, no una regla automática que aprueba o rechaza anatomía. El volumen 3D sigue sin inferirse (`body_volume: null`); la masa percibida se compara cualitativamente contra torso, cuello y muslos canónicos. Anchura de alfa, área y luminancia describen la imagen y no demuestran por sí solas consistencia de anatomía, textura o exposición.

Los marcadores tardíos conservan su edad, pero su posición se evalúa con la pose disponible al despacharlos; no se reconstruye una trayectoria histórica completa de sockets. Frecuencias distintas deben producir eventos únicos y suelo estable, sin prometer identidad de píxeles entre tasas de refresco. El [informe de FX](VISUAL-FX.md) detalla esta limitación y sus pruebas.

Normalizar 680 poses certifica un contrato geométrico, no 680 decisiones artísticas. Los estados `PILOT_REVIEW`, `CORRECTED_STATIC_REVIEW` o `REGENERATED_STATIC_REVIEWED` conservan la etapa histórica de preparación de cada fuente. La aceptación final se registra por separado, contra los hashes exactos de cada atlas y sidecar, en [acceptance.json](../assets/sprites/normalized/acceptance.json). El `profile_status` conserva la descripción de la etapa de definición del canon; no sustituye ese dictamen por banco. Volver a normalizar restablece los campos centrales de aprobación para exigir una revisión de las nuevas fuentes.

## Evidencia de etapas ya ejecutadas

| Etapa | Resultado registrado | Evidencia |
|---|---|---|
| Auditoría original | 680 poses; 344 KEEP / 208 FIX / 128 REGENERATE | [audit.json](../../../work/visual-consistency/audit/audit.json) |
| Runtime canónico inicial | 20.430 comprobaciones, 0 fallos | [runtime-validation.json](../../../work/visual-consistency/runtime-validation.json) |
| FX y marcadores | Suites de partículas, marcadores, track pareado y regresión orgánica sin fallos en ese corte | [fx-validation.json](../../../work/visual-consistency/fx-validation.json) |
| Encuadre de retratos | 61.163 comprobaciones agregadas de ejecuciones headless y nativas, 0 fallos; no son partidas independientes | [portrait-framing/validation.json](../../../work/visual-consistency/portrait-framing/validation.json) |
| Nuevas fuentes | Prompts, RGBA, sidecars, limpieza, revisiones y hashes por grupo | [generated/](../../../work/visual-consistency/generated/) |

Estas cifras pertenecen a cortes concretos del trabajo. Las cifras históricas no se suman como una certificación global del estado final; la última integración tiene sus propias regresiones y capturas, registradas a continuación.

## Validación final

**Aceptado: 17 cuerpos, 51 bancos y 680 poses; ninguna incidencia visual abierta en este corte.** La revisión distinguió geometría, material y continuidad. Bruma, Sira, Mugo e Iria se aceptaron después de regenerar sus movimientos con mayor fidelidad al canon. Duna se aceptó tras quitar el residuo magenta y su borde de antialias, conservando anatomía, pivots y escala. Nima mantiene variaciones menores de trazo y saturación compatibles con el mismo material y masa a tamaño de juego.

| Comprobación final | Resultado | Evidencia |
|---|---|---|
| Integridad de assets | 680 reconstrucciones exactas; 51 imports vigentes; 51 originales intactos; ningún desbordamiento | [final-asset-integrity.json](../../../work/visual-consistency/final-asset-integrity.json) |
| Composición de familias refinadas | 4 familias, 16 hojas; composición por traslación y un único factor por familia | [fuentes y comprobaciones](../../../work/visual-consistency/generated/audit-fixes/) |
| Regresiones | 12 suites, 48.587 comprobaciones, 0 fallos y 0 errores de Godot | [validation-final.json](../../../work/visual-consistency/validation-final.json) |
| Velocidad real | 17 pases nativos ×1, 1.749 observaciones; ninguna entrada modificada desde la ejecución | [resultados y hashes](../../../work/visual-consistency/roster-native/summary.json) |
| Aceptación artística | Dictamen por los 51 bancos, con comparación contra canon, capturas y límites de cobertura | [acceptance-final.json](../../../work/visual-consistency/roster-native/acceptance-final.json), [revisión legible](../../../work/visual-consistency/roster-native/acceptance-current.md) |
| Combate y replay | 1.113 comprobaciones y 96 capturas en 1360×880 y 390×844; pausa, hit stop, contacto y terminales | [main-replay/results.json](../../../work/visual-consistency/main-replay/results.json) |

Los pases de velocidad real no usan captura PNG, MovieMaker ni FPS forzados. Cada showcase recorrió 33 nombres de pose activos por cuerpo; las 136 celdas base y las 17 poses `low_health` se revisaron también en estático. Esta cobertura no se presenta como una reproducción de las 680 celdas independientes. Los fixtures recorren tipos de movimiento y estados; cuando un personaje no tiene un ataque de cierto tipo en su catálogo, la muestra se identifica como fixture visual y no como nueva habilidad jugable.

El [vídeo final de Ascua](../../../work/visual-consistency/ascua-final.mp4) muestra la carga localizada, anticipación, ataques, salto, polvo, reacciones, transformación y estados terminales. Es una grabación visual de MovieMaker: 20,97 s, 1.258 fotogramas, 60 fps y resolución real 1224×792. No se usa como prueba de rendimiento; esa comprobación procede del pase nativo separado. El [manifest del vídeo](../../../work/visual-consistency/roster-native/ascua/movie/movie-manifest.json) conserva comando, resolución y hash.

Las capturas de combate/replay corresponden al corte exacto registrado en [main-replay-inputs.json](../../../work/visual-consistency/main-replay-inputs.json). La tarea paralela de UI ajustó después la ubicación del cartel de resultado en escritorio y textos de presentación, con sus propias pruebas; estas capturas no se etiquetan como el último diseño de todas las pantallas. Los PNG y sidecars finales del roster sí están identificados individualmente en la aceptación de esta entrega.

La aceptación queda ligada a estos archivos. Una nueva fuente debe repetir el flujo de comparación y reproducción antes de heredar ese estado; no basta con conservar el mismo nombre de archivo.
