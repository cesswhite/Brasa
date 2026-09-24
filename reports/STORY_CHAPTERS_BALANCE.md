# Capítulo 2 y corrección del nivel 2

La ruta original conserva sus ocho encuentros e identificadores. Nima, el segundo rival, ahora muestra **nivel 2**. El nuevo **Capítulo 2 · El paso de la tormenta** se desbloquea tras Ascua y se inicia mediante una acción explícita. El nivel del personaje, XP, puntos y mejoras continúan; el primer legado queda archivado.

## Auditoría natural final

Se ejecutaron **3,182 combates** con CombatEngine y StoryProgression reales, sin acceso a guardados: 108 campañas de ambos capítulos (9 personajes × 4 prioridades × 3 semillas) y 360 combates para aislar el ajuste del nivel de Nima. **108/108 campañas completaron ambos capítulos**. Cada capítulo tenía un límite de seguridad de 40 combates; ninguno se acercó a ese límite.

| Resultado | Capítulo 1 | Capítulo 2 |
|---|---:|---:|
| Combates medios | 13.24 | 12.89 |
| Rango observado de combates | 9–19 | 8–19 |
| Derrotas medias | 5.24 | 4.89 |
| Máximo de derrotas observado | 11 | 11 |
| Nivel medio al terminar | 11.61 | 21.71 |
| Rango de nivel final | 11–13 | 20–23 |
| Jefe al primer intento | 56.48% | 63.89% |

Las prioridades se mantienen durante toda la campaña: no hay reasignación de puntos al cambiar de rival ni al comenzar el capítulo 2. Los puntos nuevos se invierten en el siguiente atributo de la prioridad; si está al máximo se continúa con el siguiente. Las derrotas conceden la XP real del encuentro antes de reintentar.

## Cuatro estrategias viables

| Prioridad | Campañas completadas | Combates medios en capítulo 2 | Máximo de derrotas | Véspera al primer intento |
|---|---:|---:|---:|---:|
| Equilibrio | 27/27 | 14.59 | 11 | 70.37% |
| Agresión | 27/27 | 13.96 | 9 | 40.74% |
| Aguante | 27/27 | 9.89 | 6 | 74.07% |
| Ritmo | 27/27 | 13.11 | 11 | 70.37% |

- Equilibrio: vida, ataque, defensa, velocidad, precisión, evasión, crítico, resistencia.
- Agresión: ataque, ataque, vida, crítico, velocidad, precisión.
- Aguante: vida, defensa, vida, evasión, ataque, velocidad.
- Ritmo: velocidad, precisión, evasión, ataque, vida, crítico.

Aguante sigue siendo más eficiente en esta muestra. Todas las prioridades completan la ruta con los nueve personajes, pero eso no implica equivalencia entre todos los repartos posibles. Tres semillas por combinación permiten detectar bloqueos grandes y comprobar el ritmo de progresión; las tasas de cada celda pequeña no son probabilidades exactas.

## Ajuste acotado de Véspera

| Parámetro / resultado | Primera muestra | Versión final |
|---|---:|---:|
| Vida | 730 | 780 |
| Ataque | 48 | 52 |
| Primer intento ganado | 88.89% | 63.89% |
| Combates medios del capítulo | 12.51 | 12.89 |
| Campañas completadas | 108/108 | 108/108 |

La comparación usa las mismas semillas, prioridades y personajes. Solo se aumentaron vida y ataque de Véspera para que el jefe conserve dificultad después de la élite anterior. No hubo más iteraciones de balance.

Véspera es de nivel 23: 780 PV, ataque 52, defensa 30, velocidad 20, precisión 106%, evasión 22%, crítico 18%, daño crítico ×1.70 y resistencia 30%. Su armadura ligera permanece como debilidad. Al 60% de vida gana un 10% de velocidad; al 30% conserva esa velocidad y añade un 8% de ataque. Sus fases usan el despachador existente; no hay curación, invulnerabilidad, probabilidad oculta ni reglas nuevas.

Su firma Polvo de eclipse conserva la tirada normal del 1% por combate, se usa como máximo una vez, golpea con ×1.65 y reduce la precisión rival 12 puntos durante cuatro acciones propias del objetivo; la resistencia puede acortar la duración.

Los otros rivales del capítulo son Kiro (13), Iria (14), Mugo (16), Nima élite (17), Taro (18), Duna (20) y Sira élite (21). Sus perfiles distinguen ataque, veneno, aguante, velocidad, respuestas, armadura y críticos. Las victorias dan 340–680 XP; las derrotas, 95–180 XP. Los hitos élite conservan dos puntos adicionales.

## Corrección de Nima

Se compararon las mismas 180 semillas por versión, con los nueve personajes de nivel 2 y seis puntos distribuidos. Solo se cambió el nivel de Nima en la comparación; las demás estadísticas permanecieron fijas. La tasa de victoria del jugador pasó de **80.56%** frente a Nima de nivel 3 a **82.22%** frente a Nima de nivel 2: **+1.67 puntos porcentuales**. La corrección no introduce un salto grande de dificultad ni cambia IDs o partidas guardadas.

En el conjunto de la muestra, la duración media fue **31.09 segundos**, la incidencia de firmas **0.959%** por combatiente y partida, y hubo **62** desenlaces por límite de tiempo.

## Compatibilidad y pruebas

SAVE_VERSION pasa a 2. Un guardado v1 válido se normaliza únicamente en memoria como capítulo 1: no se reescribe al cargar, no se reinicia el personaje y no comienza el segundo capítulo. La primera escritura v2 desde el archivo v1 conserva una copia permanente `.v1.bak`, además de `.bak`; una copia v1 válida preexistente nunca se reemplaza.

`start_next_chapter()` congela el legado anterior y conserva nivel, XP, puntos, estadísticas, asignaciones y el historial de mejoras. Reinicia únicamente la ruta y los contadores locales del nuevo capítulo. Si no puede guardar, restaura el estado anterior para impedir una transición ficticia. Las recompensas comprueban personaje, capítulo, ID e índice local del encuentro. El registro de recompensas procesadas sigue vigente entre capítulos.

- `tests/test_story_chapters.gd`: **299 comprobaciones, 0 fallos**. Incluye migración v1, copias permanentes, rollback, preservación y lectura de los dos legados, capítulos por personaje, rechazo de resultados antiguos y de crecimiento borrado, límites y reglas de Véspera.
- `tests/test_story_progression.gd`: **217 comprobaciones, 0 fallos**, verificadas tras el cambio de formato.
- `tests/simulate_story_chapters.gd`: la auditoría natural acotada descrita aquí.

Reproducir la misma muestra desde la carpeta del proyecto:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_story_chapters.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/simulate_story_chapters.gd -- --quick
```

Datos completos: [story_chapters_balance.json](story_chapters_balance.json). La calibración original del primer capítulo permanece como informe histórico en STORY_BALANCE.md.
