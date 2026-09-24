# Foco y rendimiento de Brasa

21 de septiembre de 2026 · Godot 4.7.2 · Apple M1 Max

Se elimina el contorno exterior de foco que se recortaba y se reduce trabajo repetido en animación, interfaz y presentación. El arte de los marcos conserva su material pintado. La navegación por teclado conserva una señal visible dentro del control.

| Área | Antes | Después |
| --- | --- | --- |
| Foco de controles | Trazo claro expandido fuera del control, susceptible a recorte | Relleno ámbar interior al 22%, retraído 4 px; sin borde. Compartido por botones, campos, selectores y pestañas. Token de grosor actualizado a cero. |
| Tema y materiales | Copias profundas del registro completo para consultas internas pequeñas | Lectura interna del registro en caché; las API públicas siguen devolviendo copias defensivas. |
| Sprites heridos | Consultas de archivos y copias de bancos durante cada actualización | Validación al preparar el combate, caché acotada de bancos, copia del fotograma necesario y reutilización del resultado mientras no cambia la pose o el nivel de daño. |
| Texturas y salud | Textura sana intermedia y recálculos ante la misma salud | Asignación final única; actualizaciones de salud idénticas terminan inmediatamente. Las llamadas explícitas de resolución siguen refrescando los metadatos. |
| HUD del combate | Reconstrucción de salud, estados y turnos cada frame | Actualización cuando el combate produce eventos; reloj independiente. |
| Listas de personajes | Retratos recortados seguían animándose | Se suspenden al salir del área visible y se reanudan al volver. |
| Arena oculta | Animación y dibujo bajo pantallas opacas completas | Arena suspendida y oculta mientras está cubierta; se restaura al cerrar. Se conserva durante transiciones y diálogos translúcidos. |
| Audio | Asignaciones repetidas de pausa y mezcla | Cambios de pausa y atenuación aplicados solo cuando cambian; ajustes de volumen siguen siendo inmediatos. |
| Efectos | Redibujado incluso sin partículas ni cámara activa | Reposo cuando no hay efectos, marcadores pendientes ni sacudida. Se conserva el último redibujado de limpieza. |

## Medición de CPU

Mismo programa, cachés calientes, perfiles desechables, ejecución headless. Medianas; estas cifras no miden FPS, GPU ni el tiempo total de un frame. No implican que todo el juego sea quince veces más rápido.

| Operación | Antes | Después | Reducción |
| --- | ---: | ---: | ---: |
| Actualizar dos luchadores heridos | 392 µs | 26 µs | 93,4% |
| Construir y estilizar 100 botones | 75,48 ms | 4,87 ms | 93,6% |
| Refrescar el HUD del combate | 56 µs | 28 µs | 50% |

Repetir la misma salud pasó de 382 µs a menos de 1 µs de media; la mediana queda por debajo de la resolución del temporizador. Se midieron 1.200 muestras de animación y salud, 20 lotes de botones y 1.000 refrescos del HUD.

[Datos previos](../../../work/performance-ui/baseline.json) · [Datos posteriores](../../../work/performance-ui/after.json) · [Programa de medición](../../../work/performance-ui/benchmark.gd)

## Validación

24 suites pasaron, cubriendo combate, contacto, reloj de movimientos, secuencias, daño ilustrado, efectos, audio/pausa, identidad, Historia, personalización, compañeros, tema y refugios. La nueva prueba de eficiencia verifica foco sin borde, protección de datos compartidos, suspensión/reanudación de retratos y cobertura de arena.

La primera ejecución encontró una invalidación demasiado agresiva al editar sockets con la misma textura; se corrigió conservando el refresco explícito. La suite de consistencia volvió a pasar: 2.213 comprobaciones sin fallos. Los resultados originales y la consolidación final se conservan por separado.

Auditoría nativa: 143 comprobaciones sin fallos, 74 capturas (37 superficies en escritorio y móvil). Se revisaron las dos paredes visuales y capturas individuales de Ajustes y Redistribuir mejoras. No se midió FPS en una sesión interactiva prolongada.

[Resultados finales](../../../work/performance-ui/checks/final-results.json) · [Escritorio](../../../work/performance-ui/screens/wall-1360x880.png) · [Móvil](../../../work/performance-ui/screens/wall-390x844.png)

La comparación de scripts con el respaldo previo limita los cambios a diez archivos de presentación y sus cachés. No se editaron reglas de combate, progresión, guardados del usuario, backend ni sprites. La preparación explícita de los bancos de daño sigue siendo el punto de validación de cambios de archivos durante una sesión de desarrollo.
