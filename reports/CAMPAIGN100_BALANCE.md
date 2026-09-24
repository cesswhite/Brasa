# Balance de la campaña de 100 encuentros

Configuración final: 100 encuentros, once capítulos, once jefes y nueve personajes jugables. Los primeros dieciséis IDs y sus estadísticas se conservan, incluido Nima de nivel 2. El nivel del personaje sigue limitado a 50; el número de encuentro de Historia llega a 100.

La validación final comprende **17,610 combates**: 13,135 en 108 campañas con prioridades fijas, 4,314 en 36 campañas adaptativas y 161 para reproducir y recuperar exactamente el único bloqueo de la muestra fija. Todos usan CombatEngine y StoryProgression reales, con guardado desactivado y semillas registradas. No se abrieron ni modificaron partidas reales.

| Política | Campañas terminadas | Combates medios | Observación |
|---|---:|---:|---|
| Cuatro prioridades fijas | 107/108 (99.1%) | 121.62 | Sin redistribuir durante la campaña. |
| Adaptación explícita | 36/36 | 119.83 | Prioridades iniciales menos completas; redistribución tras 3 o 6 derrotas en un encuentro. |

Las muestras adaptativas **no** se presentan como victorias de una distribución fija. El JSON registra cada cambio de prioridad, su encuentro y la revisión de la configuración. Es una prueba de la posibilidad de aprender y cambiar de estrategia; no un experimento causal entre dos políticas idénticas.

## Resultados por personaje y distribución

| Personaje | Completadas | Media de combates | Rango de combates | Jefe 100 al primer intento |
|---|---:|---:|---:|---:|
| Nima | 12/12 | 123.92 | 111–146 | 25.0% |
| Luma | 12/12 | 119.83 | 111–133 | 25.0% |
| Mugo | 12/12 | 125.50 | 113–137 | 33.3% |
| Sira | 12/12 | 108.42 | 102–119 | 66.7% |
| Iria | 12/12 | 121.92 | 113–132 | 25.0% |
| Duna | 11/12 | 132.25 | 118–153 | 25.0% |
| Kiro | 12/12 | 108.08 | 102–126 | 75.0% |
| Neris | 12/12 | 113.00 | 105–119 | 33.3% |
| Taro | 12/12 | 141.67 | 123–194 | 41.7% |

| Prioridad | Completadas | Media de combates | Derrotas medias | Puntos sin gastar al final |
|---|---:|---:|---:|---:|
| Equilibrada | 27/27 | 130.93 | 30.93 | 0.00 |
| Ofensiva | 26/27 | 123.15 | 23.19 | 6.44 |
| Aguante | 27/27 | 115.48 | 15.48 | 1.67 |
| Ritmo | 27/27 | 116.93 | 16.93 | 0.00 |

Aguante funciona bien en esta muestra, pero no es la mejor prioridad para todos los personajes. Taro necesita más intentos que el promedio y se conserva esa diferencia visible en los resultados. Las cuatro prioridades asignan puntos legalmente y mantienen decisiones distintas; ofensiva y ritmo incluyen una inversión limitada en Defensa. Seis talentos propios y tres elecciones permiten diferencias incluso al nivel máximo.

## Jefes y puntos de dificultad

| Encuentro | Jefe | Primer intento ganado | Intentos medios al llegar | Nivel medio del personaje |
|---|---|---:|---:|---:|
| 8 | Ascua | 54.6% | 2.05 | 10.58 |
| 16 | Véspera | 66.7% | 1.53 | 20.13 |
| 20 | Taro · Juramento de jade | 63.0% | 1.57 | 23.62 |
| 30 | Iria · Jardín de ecos | 39.8% | 3.04 | 30.42 |
| 40 | Luma · Las nueve sendas | 77.8% | 1.31 | 36.18 |
| 50 | Ascua · Corazón del solsticio | 53.7% | 2.21 | 41.69 |
| 60 | Duna · Fortaleza del regreso | 100.0% | 1.00 | 46.69 |
| 70 | Kiro · Rugido del relámpago | 75.9% | 1.36 | 50.00 |
| 80 | Neris · Círculo de los maestros | 54.6% | 2.43 | 50.00 |
| 90 | Sira · Filo de las estrellas | 57.4% | 1.78 | 50.00 |
| 100 | Véspera · El último eclipse | 38.9% | 2.91 | 50.00 |

Los jefes 50 y 100 usan fases anunciadas y las mismas reglas de acierto, daño, resistencia, estados y Firma que el resto. Ascua del solsticio tiene 1.070 PV, 76 de Ataque, 120 de Defensa y 23 de Velocidad; su 5% de Evasión y las preparaciones de sus golpes dejan oportunidades. Véspera final tiene 1.020 PV, 85 de Ataque, 100 de Defensa y 31 de Velocidad; su Resistencia es 28%, no se cura y sus golpes fuertes se preparan de forma visible.

La dificultad no sube en cada encuentro individual. El jefe 60 se mantiene como un respiro —100% al primer intento en esta muestra—, mientras que los jefes 30, 50 y 100 son obstáculos claros. No se ajustaron todos los duelos a 50/50.

| Encuentros con mayor dificultad observada | Primer intento ganado | Intentos medios |
|---|---:|---:|
| 100 · Jefe · Véspera · El último eclipse | 38.9% | 2.91 |
| 30 · Jefe · Iria · Jardín de ecos | 39.8% | 3.04 |
| 3 · La muralla de ocre | 44.4% | 2.31 |
| 4 · Élite · El filo de cristal | 45.4% | 2.04 |
| 50 · Jefe · Ascua · Corazón del solsticio | 53.7% | 2.21 |
| 8 · Jefe · El último farol | 54.6% | 2.05 |
| 80 · Jefe · Neris · Círculo de los maestros | 54.6% | 2.43 |
| 9 · El desfiladero rojo | 54.6% | 1.67 |
| 11 · Las raíces de hierro | 56.5% | 1.81 |
| 90 · Jefe · Sira · Filo de las estrellas | 57.4% | 1.78 |

## Recuperación del caso detenido

La distribución ofensiva de Duna, semilla de campaña `15311002`, se detuvo en el encuentro 100 tras alcanzar el límite de auditoría de 24 intentos. Se reprodujeron sus 153 combates y la distribución final exactamente. La API `respec_build()` devolvió exclusivamente recursos ya obtenidos y conservó nivel, XP, ruta y legados. La prioridad equilibrada completó el combate pendiente en 8 intentos adicionales.

Este caso se conserva como límite de la política fija; no se oculta ni se cuenta como una victoria sin redistribución. Todas las identidades y las 36 combinaciones de personaje/prioridad lograron completar al menos una de sus tres réplicas fijas.

## Técnicas, ritmo y eventos raros

Duración media de combate: **31.12 segundos**. 174 combates llegaron al límite de 60 segundos (1.3%); el desempate sigue usando la proporción de vida restante. Incidencia de Firma por combatiente y partida: **0.967%**, compatible con la tirada única de 1%. La corrección final del combo de Nima cuenta intentos ofensivos y no posturas de guardia.

| Identidad | Técnicas disponibles y usadas | Acciones con técnicas |
|---|---:|---:|
| Ascua | 5/5 | 10,469 |
| Duna | 5/5 | 77,701 |
| Iria | 5/5 | 67,140 |
| Kiro | 5/5 | 49,066 |
| Luma | 5/5 | 87,631 |
| Mugo | 5/5 | 69,747 |
| Neris | 5/5 | 89,588 |
| Nima | 5/5 | 64,856 |
| Sira | 5/5 | 50,067 |
| Taro | 5/5 | 73,569 |
| Vespera | 5/5 | 13,197 |

| Tipo | Usos observados |
|---|---:|
| charge | 41,147 |
| counter | 23,592 |
| dash | 49,866 |
| guard | 28,397 |
| heavy | 94,573 |
| jump | 61,969 |
| quick | 318,014 |
| technique | 35,473 |

Ninguna de las 55 técnicas normales de las once identidades quedó sin uso. La estadística incluye jugadores y rivales; el número de usos o las victorias asociadas a una técnica no prueban por sí solos su superioridad. La IA considera vida, estados, enfriamientos, repetición y preferencias declaradas. Las Firmas permanecen fuera de su selección normal.

## Progresión y configuración

- Puntos de atributos: 3 al alcanzar los niveles de personaje 2–20; 2 al alcanzar 21–50. Las cuatro élites de los primeros dieciséis encuentros conservan sus 2 puntos. Las nuevas élites conceden XP, sin inflar el presupuesto de atributos.
- Fichas de técnica en los encuentros 5, 10, 20, 30, 40, 50, 60, 70, 80 y 90. Cinco técnicas, dos mejoras máximas por técnica y coste de una ficha.
- Talentos en 10, 30 y 50: elegir tres de seis opciones propias del personaje. La redistribución permite cambiar decisiones posteriormente.
- Desbloqueos de técnicas en niveles de personaje 1, 1, 5, 12 y 20. Los jefes muestran sus cinco técnicas conocidas.
- Las derrotas conservan XP positiva y decreciente por repetición; rendirse conserva su reducción y espera breve. La práctica de encuentros vencidos concede cero XP y ningún hito adicional.
- Los rivales nuevos usan presupuestos de inversión, límites por estilo y distribuciones diferentes. Algunas casillas tienen un conjunto pequeño de identidades estables por personaje y semilla de campaña; los jefes nunca se sortean.
- Los guardados v1/v2 se normalizan en memoria, sin avanzar capítulos ni escribir durante una carga normal. La primera escritura conserva la copia permanente de su versión. Se respetan los puntos ganados con la curva anterior mediante un crédito limitado a su progreso histórico posible.
- Los legados guardan el perfil al vencer al jefe, incluido el encuentro 100. Entrenar o redistribuir después no modifica ese resultado. Las revisiones de configuración y su historial permiten volver a invertir sin borrar los legados.

Las campañas fijas terminadas alcanzaron nivel de personaje 50. Esto deja las mejoras de técnicas de los encuentros 80 y 90 y la adaptación del personaje como decisiones posteriores al crecimiento básico, sin aumentar el límite de nivel ni introducir bonificaciones ocultas.

## Archivos y reproducción

- [Muestra fija: 108 campañas](campaign100_balance.json)
- [Muestra adaptativa: 36 campañas](campaign100_adaptation.json)
- [Reproducción y recuperación del bloqueo](campaign100_recovery.json)
- [Catálogo exportado: encuentros, técnicas y talentos](campaign100_catalog.json)

```sh
BRASA_GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
"$BRASA_GODOT" --headless --path outputs/Brasa --script res://tests/simulate_campaign100.gd -- --runs=3
"$BRASA_GODOT" --headless --path outputs/Brasa --script res://tests/simulate_campaign100.gd -- --runs=1 --adaptive --output=res://reports/campaign100_adaptation.json
"$BRASA_GODOT" --headless --path outputs/Brasa --script res://tests/simulate_campaign_recovery.gd
```

Los JSON contienen semillas, distribuciones finales, elecciones, intentos por encuentro, métricas de técnicas y hashes de las fuentes de combate. El límite de 24 intentos por encuentro es una protección de la auditoría, no una garantía probabilística. Tres réplicas por personaje/prioridad y una adaptativa son muestras finitas; no prueban todas las inversiones o secuencias posibles.

Validación de dominio final: `test_campaign100.gd` 2.117 comprobaciones; `test_story_progression.gd` 217; `test_story_chapters.gd` 299; `test_story_campaign.gd` 1.796. Todas sin fallos. Las suites de motor, interfaz y regresión general se registran por separado en el informe principal.
