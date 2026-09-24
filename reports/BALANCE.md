# Auditoría de balance — Brasa

Corrida final reproducible: **17,100 combates** con las nueve identidades, sus habilidades y sus Firmas habilitadas. Los niveles comprobados son 1, 10, 25 y 50. Los combatientes usan su entrenamiento inicial para aislar diferencias de personaje y crecimiento.

## Resultados

- Duración media: **32.11 s**; mediana: **30.85 s**; percentiles 10–90: **21.30–44.74 s**.
- Firmas: **330** activaciones entre 34,200 participaciones (**0.965%**). Se lanza una sola Bernoulli del 1% por combatiente al comenzar, nunca una por ataque.
- Aciertos: **85.5%** de ataques normales/Firma; críticos: **11.4%** de impactos.
- Combates resueltos por límite de tiempo: **0.58%**.
- Victorias agregadas de cada personaje por nivel: **43.9–58.3%**; **0** parejas observadas con 0% o 100%.
- Un personaje de nivel 1 venció a su misma identidad de nivel 4 en **8.2%** de 900 encuentros. El más fuerte mantiene ventaja, pero no tiene garantizada la victoria.

## Victorias frente a todo el elenco

Cada cifra es la tasa como participante izquierdo frente a los nueve rivales. Por nivel 1 se muestrearon 80 semillas por pareja ordenada; por niveles 10, 25 y 50, 40. Los enfrentamientos simétricos están incluidos.

| Personaje | Nivel 1 | Nivel 10 | Nivel 25 | Nivel 50 |
|---|---:|---:|---:|---:|
| Nima | 49.4% | 49.4% | 45.8% | 46.4% |
| Luma | 49.4% | 48.6% | 53.3% | 46.7% |
| Mugo | 48.9% | 49.7% | 49.7% | 56.9% |
| Sira | 45.4% | 45.3% | 49.7% | 47.2% |
| Iria | 43.9% | 45.3% | 46.7% | 51.7% |
| Duna | 56.2% | 51.7% | 51.9% | 48.3% |
| Kiro | 52.1% | 58.3% | 48.3% | 54.7% |
| Neris | 52.6% | 58.3% | 49.7% | 51.9% |
| Taro | 45.3% | 45.0% | 48.6% | 46.9% |

## Matrices por nivel

Fila: personaje del jugador. Columna: rival. Las celdas indican porcentaje de victorias del jugador; cada pareja usa semillas distintas.

### Nivel 1

| Jugador / rival | Nima | Luma | Mugo | Sira | Iria | Duna | Kiro | Neris | Taro |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Nima | 49% | 48% | 55% | 51% | 55% | 51% | 50% | 39% | 48% |
| Luma | 52% | 51% | 46% | 55% | 52% | 48% | 42% | 42% | 55% |
| Mugo | 52% | 49% | 48% | 75% | 51% | 21% | 49% | 42% | 52% |
| Sira | 48% | 41% | 30% | 54% | 40% | 56% | 48% | 44% | 49% |
| Iria | 36% | 36% | 54% | 42% | 49% | 39% | 57% | 32% | 49% |
| Duna | 60% | 54% | 75% | 50% | 61% | 40% | 51% | 60% | 55% |
| Kiro | 52% | 50% | 59% | 57% | 56% | 52% | 39% | 40% | 62% |
| Neris | 54% | 57% | 57% | 59% | 64% | 44% | 52% | 39% | 48% |
| Taro | 55% | 45% | 39% | 57% | 45% | 34% | 42% | 35% | 55% |

### Nivel 10

| Jugador / rival | Nima | Luma | Mugo | Sira | Iria | Duna | Kiro | Neris | Taro |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Nima | 50% | 50% | 42% | 57% | 50% | 65% | 32% | 40% | 57% |
| Luma | 65% | 48% | 52% | 48% | 70% | 38% | 38% | 48% | 32% |
| Mugo | 65% | 40% | 48% | 75% | 45% | 28% | 52% | 48% | 48% |
| Sira | 57% | 50% | 25% | 48% | 52% | 57% | 28% | 38% | 52% |
| Iria | 48% | 48% | 45% | 50% | 52% | 35% | 48% | 40% | 42% |
| Duna | 65% | 62% | 75% | 30% | 52% | 35% | 22% | 57% | 65% |
| Kiro | 68% | 60% | 57% | 60% | 68% | 62% | 48% | 45% | 57% |
| Neris | 57% | 52% | 70% | 57% | 45% | 55% | 55% | 60% | 72% |
| Taro | 50% | 35% | 42% | 60% | 50% | 40% | 38% | 48% | 42% |

### Nivel 25

| Jugador / rival | Nima | Luma | Mugo | Sira | Iria | Duna | Kiro | Neris | Taro |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Nima | 45% | 38% | 42% | 62% | 52% | 52% | 42% | 38% | 40% |
| Luma | 60% | 48% | 40% | 62% | 62% | 62% | 55% | 40% | 50% |
| Mugo | 57% | 50% | 35% | 62% | 38% | 50% | 50% | 45% | 60% |
| Sira | 57% | 48% | 40% | 57% | 40% | 55% | 35% | 68% | 48% |
| Iria | 55% | 52% | 28% | 50% | 45% | 50% | 48% | 45% | 48% |
| Duna | 70% | 45% | 70% | 40% | 48% | 52% | 38% | 50% | 55% |
| Kiro | 50% | 40% | 57% | 60% | 55% | 45% | 45% | 30% | 52% |
| Neris | 52% | 35% | 52% | 55% | 55% | 55% | 45% | 52% | 45% |
| Taro | 48% | 42% | 52% | 50% | 68% | 38% | 42% | 48% | 50% |

### Nivel 50

| Jugador / rival | Nima | Luma | Mugo | Sira | Iria | Duna | Kiro | Neris | Taro |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Nima | 48% | 35% | 32% | 52% | 57% | 48% | 45% | 57% | 42% |
| Luma | 40% | 50% | 38% | 57% | 42% | 48% | 48% | 52% | 45% |
| Mugo | 60% | 72% | 50% | 72% | 57% | 48% | 40% | 50% | 62% |
| Sira | 48% | 52% | 28% | 48% | 55% | 57% | 55% | 50% | 32% |
| Iria | 48% | 42% | 57% | 60% | 60% | 35% | 48% | 52% | 62% |
| Duna | 40% | 60% | 60% | 38% | 42% | 52% | 32% | 50% | 60% |
| Kiro | 57% | 52% | 40% | 52% | 65% | 65% | 50% | 52% | 57% |
| Neris | 60% | 40% | 55% | 55% | 55% | 45% | 57% | 45% | 55% |
| Taro | 48% | 42% | 40% | 50% | 60% | 48% | 42% | 38% | 55% |

## Reglas auditadas

- Acierto entre 62% y 96%, crítico entre 3% y 32%; daño aleatorio limitado a ±8%. La defensa reduce con rendimiento decreciente y los niveles tienen una influencia adicional acotada.
- Cada Firma se utiliza como máximo una vez, no combina crítico, siempre acierta, multiplica daño entre 1.4 y 1.8 y aplica un estado temporal. Su programación entre acciones propias 2–5 realiza aproximadamente el 1% de incidencia en encuentros completos.
- Los estados duran acciones del afectado; una aplicación durante una acción no consume inmediatamente un turno. Lentitud recalcula el tiempo pendiente y afecta incluso cuando dura una sola acción. Veneno, quemadura y sangrado ignoran escudos; sus magnitudes y acumulaciones tienen límites explícitos.
- Si los dos combatientes reciben daño periódico en el mismo instante, ambos daños se resuelven antes de comprobar el desenlace. Si ambos caen, un sorteo reproducible decide el ganador y queda registrado en el historial del combate.
- La rendición termina inmediatamente. No avanza efectos, no genera ataques posteriores y produce un solo resultado; el motor nunca concede experiencia directamente.
- El resumen conserva participantes originales, métricas, estados finales y eventos. Las estadísticas base nunca se alteran por los estados temporales.

## Cambios de balance verificados

Se redujo la ventaja inicial de Duna, se hizo que el veneno de Iria creciera con su Ataque y se ajustaron las curvas de Neris, Mugo, Nima, Kiro y Duna. La última corrida dejó todos los agregados por identidad y nivel dentro del intervalo 43.9–58.3%, sin perseguir que cada pareja individual termine en 50/50.

## Reproducir

Desde la carpeta Brasa:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_combat_v2.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/simulate_balance.gd
```

La simulación escribe `reports/balance.json`. Para iterar sobre nivel 1 se admite `-- --quick`; `--output=/ruta/reporte.json` elige un archivo distinto.

## Alcance

Son estimaciones de muestras finitas, no garantías de probabilidades exactas. No observar un 0% no demuestra que todas las parejas tengan idéntica dificultad. La prueba cubre crecimiento natural hasta el nivel máximo, no todas las distribuciones posibles de puntos de entrenamiento. Partidas interrumpidas o rendidas antes de la acción programada pueden terminar sin consumir una Firma sorteada. La progresión, migración y protección contra recompensas duplicadas tienen pruebas separadas.
