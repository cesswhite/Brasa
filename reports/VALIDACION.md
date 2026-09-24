# Validación de la ampliación

Verificado con Godot 4.7.2 en macOS el 20 de septiembre de 2026.

| Prueba | Comprobaciones | Fallos |
| --- | ---: | ---: |
| Regresión de controles, entrenamiento y compatibilidad | 185 | 0 |
| Motor, probabilidades, firmas y estados | 396 | 0 |
| Progresión, migración, XP y guardado | 563 | 0 |
| Sprites, alfa, anclajes y transiciones | 258 | 0 |
| Plantel, selección y fichas | 69 | 0 |
| **Total** | **1471** | **0** |

La prueba integrada `--smoke-test` también pasó: plantel, entrenamiento, firma forzada solo en pruebas, combate, recompensa única, resumen, historial, ficha, revancha, confirmación y cancelación de rendición, recarga y progreso separado por personaje. Usa un guardado de prueba nuevo dentro de `work/` en cada ejecución.

Se comprobaron semillas reproducibles con diferentes pasos de tiempo; límites de daño y probabilidades; estados repetidos, caducidad y daño periódico simultáneo; lentitud de un turno; rendición con efectos activos; firmas al terminar o contra un rival casi derrotado; intentos de actuar después del resultado; XP después de perder o rendirse; varios niveles con XP sobrante; máximo de nivel; perfiles muy distantes; protección frente a corrupción; respaldo y recompensa idempotente después de recargar.

La simulación final contiene **17 100 combates** entre los nueve personajes en niveles 1, 10, 25 y 50, más enfrentamientos de nivel 1 contra 4. Los resultados completos están en `balance.json` y el informe de balance adjunto. El entrenamiento se mantiene en su base para aislar identidades y crecimiento; la prueba no representa todas las combinaciones posibles de entrenamiento.

Se revisó la interfaz en una ventana real: selección de los nueve personajes, arena, vida y niveles, resumen de ambos participantes, rendición, estados y animaciones. Una captura de firma forzada permitió corregir la superposición de su título, daño y efecto. Los nombres largos se recortan dentro de su espacio y las fichas disponen de desplazamiento.

La partida real migró a V2 y se comprobó campo por campo: **Mugo, nivel 3, 65 XP, 2 puntos, 5 victorias, 0 derrotas**, con entrenamiento Vida 8, Fuerza 7, Agilidad 4 y Velocidad 8. La copia anterior está en `brasa_save.json.v1.bak`, junto al guardado de macOS. Ninguna batalla de prueba consumió puntos ni alteró resultados de esa partida. La aplicación quedó abierta con Mugo listo para jugar.
