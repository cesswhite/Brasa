# Nivel 2 corregido y segundo capítulo

Nima, el segundo rival de la primera ruta, ahora es de nivel **2**. El encuentro conserva su identidad, estadísticas declaradas, recompensa y posición; el ajuste de nivel usa las mismas reglas de combate. La interfaz distingue **Capítulo**, número de **Encuentro** y **nivel del rival/personaje** para evitar confundir las tres progresiones.

El segundo capítulo, **El paso de la tormenta**, añade ocho encuentros y se desbloquea después de Ascua. Incluye rivales de niveles 13–23, dos élites y la jefa **Véspera**, una polilla lunar de velocidad y evasión altas con armadura ligera. Historia tiene dieciséis encuentros entre las dos rutas. El nuevo escenario y las ocho poses de Véspera se generaron con `image_gen` nativo.

![Combate del segundo capítulo](capitulo2-batalla.png)

## Continuar y conservar el legado

En el cierre del primer capítulo, **Legado → Comenzar capítulo 2** inicia la nueva ruta. Se conservan nivel, XP, puntos disponibles, mejoras, historial de asignaciones y XP acumulada. Se archiva una copia del perfil y del resumen del primer capítulo; los combates y reintentos nuevos se cuentan aparte. El selector de Legado permite consultar ambos cierres.

El guardado de Historia pasa a versión 2. Cargar una partida v1 la interpreta como Capítulo 1 y no escribe el archivo ni comienza la continuación. La primera escritura conserva una copia permanente `.v1.bak`, además del respaldo rotatorio y la escritura atómica. Si falla el guardado de la transición, se vuelve al estado anterior. Las recompensas verifican personaje, capítulo y encuentro y conservan la deduplicación entre capítulos.

La liga conserva su adaptador, archivo y escenario. El fondo de la tormenta se usa en el segundo capítulo; volver a la liga recupera el mercado nocturno.

## Verificación

Godot 4.7.2: **9981 comprobaciones, cero fallos**.

| Suite | Comprobaciones |
| --- | ---: |
| Núcleo | 185 |
| Combate de la liga | 396 |
| Sprites originales | 258 |
| Plantel | 283 |
| Distribución de batalla | 2139 |
| Sprites distintos | 3165 |
| Combate y catálogo de Historia | 518 |
| Campañas del primer capítulo | 1563 |
| Integración original de Historia | 85 |
| Panel de Historia con capítulos | 429 |
| Integración de los dos capítulos y capturas nativas | 444 |
| Capítulos, migración, legados y Véspera | 299 |
| Progresión de Historia | 217 |

La integración usa la interfaz y el motor reales con archivos de prueba separados. Cubre las dieciséis victorias, pérdida y reintento en el segundo capítulo, recompensas únicas, recarga, ambas pantallas de legado, transición por el botón y recuperación de la liga. Las victorias forzadas de estas pruebas revisan el flujo, no el balance.

La revisión visual cubre siete tamaños: 1360×880, 1224×792, 1920×1080, 768×1024, 390×844, 430×932 y 844×390. Las 28 capturas de integración se conservan en `work/level2/chapter-integration-captures`, respecto a la raíz del espacio de trabajo; las capturas del panel están en `work/level2/panel-qa`. Se verificaron encabezados, numeración, vista previa, botón para continuar, Véspera, barras de vida, escenario y controles.

También se probó una **copia aislada de la partida v1 real de Sira**: el inicio del segundo capítulo y su recarga conservaron nivel 12, XP, puntos, estadísticas, mejoras y el legado completo. La copia `.v1.bak` coincidió byte por byte. El juego real se reabrió y se verificaron la tarjeta de Nima de nivel 2 y el acceso a la continuación en Legado. Los dos archivos reales conservaron sus SHA-256 durante el reinicio y esa navegación; no se empezó el capítulo 2 por el jugador.

## Balance natural

La muestra final usa el motor y la progresión reales, sin modificar vida ni forzar victorias: **3182 combates y 108 campañas**, con los nueve personajes, cuatro prioridades de mejoras y tres semillas por combinación. **108 de 108** completaron ambos capítulos. El segundo necesitó una media de **12.89 combates**, con rango de **8–19**, y terminó con nivel medio **21.71**, dentro de **20–23**. Véspera cayó al primer intento en el **63.89%** de las campañas.

El perfil final de Véspera tiene 780 PV, 52 de ataque, 30 de defensa y velocidad 20. Sus fases declaradas añaden 10% de velocidad al 60% de vida y 8% de ataque al 30%; no cura ni ignora las reglas. Su firma mantiene la tirada única del 1% por combate y reduce temporalmente la precisión. Los niveles, estados, probabilidades y límites siguen siendo los del sistema común.

Son resultados de una muestra finita; no garantizan la misma dificultad para todos los repartos. [Datos de la simulación](story_chapters_balance.json) · [Informe de balance](STORY_CHAPTERS_BALANCE.md).

## Archivos y reproducción

[Escenario, atlas y prompts exactos](../assets/CAPITULO-2.md) · [Vista móvil](capitulo2-movil.png) · [Desbloqueo de la continuación](capitulo2-desbloqueo.png).

Desde la carpeta del proyecto:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_story_chapters.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_story_chapter_integration.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/simulate_story_chapters.gd -- --quick --output=res://reports/story_chapters_balance.json
```
