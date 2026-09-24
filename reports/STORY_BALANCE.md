# Historia: auditoría de progresión y combate

Este informe corresponde a la primera entrega del capítulo 1. La corrección del segundo rival a nivel 2 y la ampliación a dos capítulos se documentan en [CAPITULO-2.md](CAPITULO-2.md).
La muestra final contiene **20,197 combates y 432 campañas completas**, repartidas entre los nueve personajes y cuatro prioridades de mejoras. Las 432 campañas llegaron a Ascua y lo derrotaron. La media fue de **13.42 combates y 5.42 derrotas**; el percentil 90 fue de 17 combates y el máximo observado, 20. El jefe cayó al primer intento en el **46.8%** de las campañas.

## Método

Se usó Godot 4.7.2 y el motor real con semillas fijas: 11.520 encuentros aislados (9 personajes × 4 estilos × 8 encuentros × 40 semillas), 2.880 controles de nivel 1 y 432 campañas (12 por combinación de personaje y estilo). Las campañas sumaron otros 5.797 combates. Los repartos persisten entre encuentros: no hay reasignación gratuita de puntos. Al llegar a un límite de atributo se pasa a la siguiente prioridad del mismo estilo.

La matriz aislada supone que se ganaron todas las peleas anteriores. Las campañas completas incorporan la XP de cada derrota antes del reintento, el crecimiento propio del personaje y los nuevos puntos de nivel e hitos. La simulación tiene un corte de seguridad de 40 combates; ninguna campaña lo alcanzó. No lee ni escribe guardados. Un test adicional recorre las 36 combinaciones con StoryProgression real y guardado desactivado para comprobar que los resultados del motor, las recompensas y el avance coinciden con esta auditoría.

## Ruta y nivel inicial

Las cifras siguientes son victorias del jugador al llegar con la XP de victorias anteriores, sin añadir derrotas. El jugador dispone de 3 puntos iniciales, 3 por nivel y 2 por cada élite superada. Los niveles de jugador son 1, 2, 4, 5, 6, 7, 8 y 9; los rivales son de nivel 1, 3, 4, 5, 7, 8, 9 y 12.

| Encuentro | Perfil rival | Media | Equilibrio | Agresión | Aguante | Ritmo | Control nivel 1 |
|---|---|---:|---:|---:|---:|---:|---:|
| 1 · Luma | Equilibrio y adaptación | 74.8% | 77.5% | 77.2% | 81.7% | 62.8% | 81.7% |
| 2 · Nima | Velocidad y combos | 74.6% | 71.9% | 76.1% | 77.5% | 72.8% | 36.1% |
| 3 · Duna | Armadura y escudos | 35.8% | 34.7% | 37.2% | 41.4% | 29.7% | 0.0% |
| 4 · Sira · Élite | Precisión y críticos | 41.5% | 34.7% | 46.4% | 49.4% | 35.3% | 0.0% |
| 5 · Iria | Veneno y resistencia | 39.0% | 32.5% | 38.9% | 53.1% | 31.4% | 0.0% |
| 6 · Neris | Evasión y recuperación única | 42.8% | 31.1% | 40.6% | 58.3% | 41.1% | 0.0% |
| 7 · Taro · Élite | Vida y contraataques | 19.5% | 8.6% | 16.9% | 41.9% | 10.6% | 0.0% |
| 8 · Ascua · Jefe | Presión progresiva y fases | 12.7% | 4.7% | 6.9% | 33.3% | 5.8% | 0.0% |

La primera pelea conserva estadísticas normales de Luma; los tres puntos libres permiten una ventaja inicial moderada. Los controles de nivel 1 usan esos tres puntos en el patrón Equilibrio. No ganaron ninguno de los encuentros 3–8 en las 360 muestras por encuentro: el personaje inicial no puede recorrer cómodamente la ruta sin mejorar. Un 0% observado no prueba imposibilidad matemática.

La dificultad no es una subida porcentual uniforme. Sira es una amenaza de críticos con poca defensa; Iria necesita tiempo para acumular veneno; Neris esquiva y se recupera una sola vez; Taro aguanta y replica. La probabilidad de ganar puede subir un poco al cambiar de rival debido a las mejoras recibidas y a los emparejamientos.

## Campañas por personaje

| Personaje | Completadas | Combates medios | Derrotas medias | Jefe al primer intento |
|---|---:|---:|---:|---:|
| Nima | 48/48 | 13.25 | 5.25 | 41.7% |
| Luma | 48/48 | 14.04 | 6.04 | 31.2% |
| Mugo | 48/48 | 14.17 | 6.17 | 56.2% |
| Sira | 48/48 | 13.29 | 5.29 | 50.0% |
| Iria | 48/48 | 13.50 | 5.50 | 47.9% |
| Duna | 48/48 | 12.83 | 4.83 | 39.6% |
| Kiro | 48/48 | 12.06 | 4.06 | 56.2% |
| Neris | 48/48 | 12.88 | 4.88 | 56.2% |
| Taro | 48/48 | 14.75 | 6.75 | 41.7% |

El nivel medio al completar fue de 11.66. Los reintentos dan XP positiva, no retroceden la ruta ni eliminan puntos. Las victorias aportan entre 120 y 300 XP; las derrotas, entre 40 y 85. La rendición tiene su recompensa menor y su espera breve, y no forma parte de estas campañas simuladas.

## Estilos de mejoras

| Estilo | Prioridad repetida | Completadas | Combates medios | Jefe al primer intento |
|---|---|---:|---:|---:|
| Equilibrio | Vida, ataque, defensa, velocidad, precisión, evasión, crítico, resistencia | 108/108 | 14.77 | 33.3% |
| Agresión | Ataque, ataque, vida, crítico, velocidad, precisión | 108/108 | 13.30 | 38.0% |
| Aguante | Vida, defensa, vida, evasión, ataque, velocidad | 108/108 | 11.19 | 77.8% |
| Ritmo | Velocidad, precisión, evasión, ataque, vida, crítico | 108/108 | 14.43 | 38.0% |

| Personaje | Equilibrio: combates | Agresión: combates | Aguante: combates | Ritmo: combates |
|---|---:|---:|---:|---:|
| Nima | 15.67 | 13.00 | 10.58 | 13.75 |
| Luma | 15.75 | 14.17 | 10.67 | 15.58 |
| Mugo | 15.83 | 13.67 | 13.00 | 14.17 |
| Sira | 14.50 | 13.75 | 11.08 | 13.83 |
| Iria | 14.00 | 13.08 | 11.00 | 15.92 |
| Duna | 13.08 | 13.25 | 10.75 | 14.25 |
| Kiro | 13.42 | 11.17 | 10.83 | 12.83 |
| Neris | 14.33 | 12.58 | 10.42 | 14.17 |
| Taro | 16.33 | 15.00 | 12.33 | 15.33 |

Aguante es la estrategia más eficiente en esta muestra, especialmente contra Ascua. Sigue sufriendo derrotas en la ruta y las otras tres estrategias también completan todas las campañas con un número acotado de reintentos. No se promete equivalencia entre todos los repartos: gastar todos los puntos en un atributo poco relevante para un encuentro puede retrasar mucho el progreso. Estos cuatro patrones son una muestra práctica; no agotan los repartos posibles ni sustituyen observaciones de jugadores.

## Ascua y reglas compartidas

Ascua usa un atlas exclusivo de guardián volcánico (`ascua-v3.png`). Esta actualización visual conserva el balance medido. Sus estadísticas públicas son 550 PV, 38 de ataque, 48 de defensa, velocidad 6, precisión 97%, evasión 6%, crítico 13%, daño crítico ×1.55 y resistencia 35%. El nivel 12 entra en el mismo ajuste acotado de nivel que cualquier personaje.

- Por encima del 60% de vida: estadísticas iniciales.
- Al 60% o menos: ataque +8%.
- Al 30% o menos: conserva ese ataque y gana velocidad +15%.

Las fases se anuncian al cruzar el umbral y también aparecen en las estadísticas de ejecución. La velocidad conserva el progreso ya realizado hacia la siguiente acción. Los estados negativos siguen funcionando, los límites globales siguen vigentes y el jefe no tiene curación, invulnerabilidad ni ataques fuera de turno.

La noche encendida usa la misma tirada del 1% por combatiente y partida, se activa como máximo una vez y golpea con ×1.7 sin combinar crítico. Aplica −18% de ataque durante tres acciones propias del objetivo. El golpe sigue la variación ordinaria de ±8%. No se altera la tirada base de firma para el jefe.

En toda la auditoría: duración media **30.37 s**, percentiles 10–90 **19.73–42.98 s**, **86** límites de tiempo (**0.43%**) e incidencia de firmas **1.013%** por combatiente y partida. Los controles de nivel inicial frente a rivales tardíos también forman parte de estas duraciones.

## Pistas y comprobaciones

Las pistas de derrota utilizan conteos reales: fallos sobre intentos, acciones de ambos lados, daño de estados registrado, daño por impacto y desenlace por tiempo. La resistencia solo se menciona cuando acortó una duración o cuando la misma tirada habría aplicado el efecto sin resistencia y lo impidió con ella. No consume una tirada adicional ni confunde un fallo normal de la habilidad con resistencia.

- `tests/test_story_combat.gd`: 518 comprobaciones sobre catálogo, independencia de atributos, límites, fases, estados, firmas letales, rendición, DoT simultáneo, semillas/delta y pistas.
- `tests/test_story_campaign.gd`: 1.575 comprobaciones, 36 campañas con el adaptador real y una implementación de guardado solo en memoria.
- `tests/simulate_story.gd`: genera los datos completos de esta auditoría.
- `reports/story_balance.json`: todas las celdas de la muestra y resultados por personaje/estilo.

Reproducir desde la carpeta del proyecto:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_story_combat.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_story_campaign.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/simulate_story.gd
```
