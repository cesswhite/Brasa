# Brasa — revisión técnica de activos de audio

Generado: 2026-09-21T17:16:36.978072+00:00.

**Medición técnica; escucha humana pendiente.** Este informe no afirma que las tomas estén aprobadas por oído, que no contengan voz accidental o que el timbre/mezcla sean adecuados.

## Demo de la mezcla real de Godot

Playtest seleccionado: `work/audio/revision-realism/playtest/final`.

[Escuchar o descargar la demo Master (47.371 s)](audio-combat-demo.mp3). El reproductor está al principio de la página HTML de revisión.

Es una captura nativa del bus Master mediante AudioEffectRecord, exportada a MP3 para entrega. No es una síntesis nueva ni un montaje de resultados. Las dos corridas de prueba conservan su desenlace real; la demo de entrega es un archivo de audio, no dos pistas concatenadas.

Evidencia del playtest: **23 comprobaciones, 0 fallos**. Hash de eventos idéntico entre corridas: **sí**. Esto verifica el registro de combate, no que las formas de onda sean idénticas.

| Corrida | Combate (s) | Tiempo real de corrida (s) | LUFS integrados | True peak (dBTP) |
| --- | ---: | ---: | ---: | ---: |
| Normal · pausa de Ajustes | 44.086 | 47.784 | -26.5 | -6.4 |
| Movimiento reducido | 44.086 | 46.899 | -26.5 | -6.9 |

LUFS y true peak se toman del resumen FFmpeg existente de cada **WAV Master**, no del MP3 de entrega ni de una escucha humana. El tiempo de corrida incluye la presentación/pausa; no sustituye a la duración decodificada del archivo.

Fixture registrada: `Real Mugo20 vs Ascua12, force_signature=rival turn2 only in this tool; no balance or production probability change`. La firma se fuerza sólo en esta prueba; no cambia la probabilidad de producción ni el balance.

**Escucha pendiente:** grabar, medir y pasar pruebas no certifica timbre, inteligibilidad, balance subjetivo o calidad musical.

[audio-asset-review.html](audio-asset-review.html) permite comparar las variantes integradas sin conexión. Sus reproductores individuales no simulan buses; la demo Master sí registra la mezcla real. Empieza con volumen moderado. El validador no modifica fuentes ni activos de producción.

Cobertura: **51 destinos medidos**, 51 integrados, 51 variantes previstas en 22 grupos. Faltan 0 destinos esperados. Hay 0 archivos con errores técnicos y 0 con indicadores para revisar.

La generación puede seguir en curso: Missing no es un fallo de formato. Generated significa que el ledger declara una toma; Measured añade medición del destino final. Pendinglisten es independiente: medir no equivale a escuchar.

## Método y límites

- ffprobe identifica el primer stream de audio; ffmpeg/astats mide muestras decodificadas por canal, duración, pico de muestra, RMS y media residual/DC.
- En las variantes, pico/RMS son dBFS, no LUFS ni true peak; las métricas de Master se documentan aparte. No se aplica umbral rígido al RMS: gestos distintos tienen diferente envolvente. La dispersión entre variantes se muestra para una comparación auditiva controlada.
- Una media residual de un transitorio corto puede ser asimetría de la forma de onda. Entre 0,001 y 0,01 es informativa; por encima de 0,01 pide revisión, no prueba un defecto audible.
- Un gesto recortado puede durar menos que el prompt. No se rechaza por esa diferencia. La compresión OGG no debe confundirse con acortar un gesto o cambiar el tiempo.
- Cada loop integrado se decodifica desde el archivo final, incluido OGG. Se mide la diferencia última→primera muestra, la relación con derivadas próximas y RMS de los primeros/últimos 250 ms. Los avisos son heurísticos: no comprueban tempo, estructura musical ni una unión perceptualmente perfecta.
- Sólo se abren destinos locales bajo outputs/Brasa/assets/audio. Se comprueba SHA-256 contra el ledger, además de cambios de tamaño/fecha/hash durante la medición. No se leen URLs ni se normaliza, recorta o vuelve a codificar nada.

Snapshot de plan: `a2ff97f1cd07249acf638394b106026bf31137b2fb27758338353eaf33a81d9c`. Snapshot de ledger: `1bafa52f7e2e77ea8e0710a6ebbe32b8819f0b648d36d1b45f62a80ae9e71b01`.
Entradas cambiadas mientras se validaba: **no**.

Datos completos: `work/audio/asset-validation.json`. Repetir con `python3 work/audio/validate_assets.py --playtest-dir RUTA` para la carpeta indicada en la evidencia Master.

## Estado por grupo

| Grupo | Integradas / previstas | Medidas | Pico dBFS | RMS dBFS | Estado |
| --- | ---: | ---: | --- | --- | --- |
| Golpe ligero (`impact_light`) | 2 / 2 | 2 | -3.0…-3.0 | -27.5…-24.3 | Generado, Medido, Escucha pendiente |
| Golpe pesado (`impact_heavy`) | 4 / 4 | 4 | -3.0…-3.0 | -23.9…-19.5 | Generado, Medido, Escucha pendiente |
| Acento crítico (`critical_accent`) | 1 / 1 | 1 | -3.0…-3.0 | -23.8…-23.8 | Generado, Medido, Escucha pendiente |
| Contacto defendido (`guard`) | 1 / 1 | 1 | -3.0…-3.0 | -17.3…-17.3 | Generado, Medido, Escucha pendiente |
| Esquiva (`dodge`) | 4 / 4 | 4 | -3.0…-3.0 | -21.7…-18.1 | Generado, Medido, Escucha pendiente |
| Aire rápido (`whoosh_quick`) | 2 / 2 | 2 | -3.0…-3.0 | -17.5…-13.9 | Generado, Medido, Escucha pendiente |
| Aire pesado (`whoosh_heavy`) | 3 / 3 | 3 | -3.0…-3.0 | -18.1…-15.9 | Generado, Medido, Escucha pendiente |
| Pisada en tierra (`footstep_earth`) | 1 / 1 | 1 | -3.0…-3.0 | -24.0…-24.0 | Generado, Medido, Escucha pendiente |
| Deslizamiento en tierra (`slide_earth`) | 1 / 1 | 1 | -3.0…-3.0 | -19.2…-19.2 | Generado, Medido, Escucha pendiente |
| Aterrizaje en tierra (`landing_earth`) | 4 / 4 | 4 | -3.0…-3.0 | -23.1…-18.8 | Generado, Medido, Escucha pendiente |
| Ascua · preparación (`ascua_charge`) | 4 / 4 | 4 | -3.0…-3.0 | -26.4…-20.0 | Generado, Medido, Escucha pendiente |
| Ascua · liberación (`ascua_release`) | 3 / 3 | 3 | -3.0…-3.0 | -18.2…-15.4 | Generado, Medido, Escucha pendiente |
| Ascua · cambio de fase (`ascua_transform`) | 3 / 3 | 3 | -3.0…-3.0 | -30.3…-19.6 | Generado, Medido, Escucha pendiente |
| Ascua · reacción (`ascua_reaction`) | 3 / 3 | 3 | -3.0…-3.0 | -19.4…-18.9 | Generado, Medido, Escucha pendiente |
| Caída final (`ko_ground`) | 3 / 3 | 3 | -3.0…-3.0 | -27.6…-24.3 | Generado, Medido, Escucha pendiente |
| Confirmación (`ui_confirm`) | 4 / 4 | 4 | -3.0…-3.0 | -30.3…-24.9 | Generado, Medido, Escucha pendiente |
| Inicio de combate (`fight_intro`) | 1 / 1 | 1 | -3.0…-3.0 | -19.6…-19.6 | Generado, Medido, Escucha pendiente |
| Victoria (`victory`) | 2 / 2 | 2 | -3.0…-3.0 | -20.9…-20.7 | Generado, Medido, Escucha pendiente |
| Derrota (`defeat`) | 2 / 2 | 2 | -3.0…-3.0 | -19.4…-18.4 | Generado, Medido, Escucha pendiente |
| Faroles · ambiente (`faroles_ambience`) | 1 / 1 | 1 | -3.0…-3.0 | -25.5…-25.5 | Generado, Medido, Escucha pendiente |
| Faroles · música (`faroles_music`) | 1 / 1 | 1 | -3.5…-3.5 | -24.6…-24.6 | Generado, Medido, Escucha pendiente |
| Ascua · firma (`ascua_signature`) | 1 / 1 | 1 | -3.0…-3.0 | -16.2…-16.2 | Generado, Medido, Escucha pendiente |

## Hallazgos técnicos

No se detectaron errores técnicos ni indicadores de revisión en los destinos disponibles. La escucha continúa pendiente.

## Escucha que falta

Comparar las variantes a igual ajuste del reproductor; comprobar material y carácter, gesto único, voz/música accidental, transitorio útil, cola, frecuencia de repetición y claridad. En música/ambiente, escuchar al menos dos vueltas de loop y su entrada/salida. Después comprobar en la mezcla real de Godot: la página no reproduce buses, ducking, prioridades o simultaneidad del juego.

Este validador no crea narración ni reel de montaje: enlaza las tomas integradas y, cuando existe, la demo Master registrada previamente por Godot.
