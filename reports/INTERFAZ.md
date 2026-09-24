# Interfaz de combate inmersiva

Validada con Godot 4.7.2 en macOS el 20 de septiembre de 2026.

La arena cubre toda la ventana con el fondo ilustrado original y sprites de mayor tamaño. Un degradado inferior integra la acción principal, los controles secundarios y la rendición. Los HUD enfrentados muestran nombre, nivel y vida; la actividad de cada luchador se señala mediante texto y énfasis en el suelo. Los estados se sitúan junto a los personajes, el registro se puede abrir bajo demanda y el resultado conserva la escena de combate.

Entrenamiento, equipo, ficha, historial, registro, ayuda, audio y ritmo siguen disponibles. Los paneles pausan la simulación; rendirse requiere confirmar. El motor, las recompensas y los datos de balance no se modificaron.

| Prueba final | Comprobaciones | Fallos |
| --- | ---: | ---: |
| Regresión de controles, entrenamiento y compatibilidad | 185 | 0 |
| Motor, probabilidades, firmas y estados | 396 | 0 |
| Progresión, migración, XP y guardado | 563 | 0 |
| Sprites, transparencia, anclajes y transiciones | 258 | 0 |
| Plantel adaptable, selección y fichas | 283 | 0 |
| Distribución de batalla, controles, resultados y ciclo de firma | 2139 | 0 |
| **Total de suites del proyecto** | **3824** | **0** |

La prueba integrada también pasó: plantel, panel de entrenamiento, mejora, firma, combate, recompensa única, resumen, historial, ficha, revancha, cancelación y confirmación de rendición, y recarga. Todas las pruebas usan guardados separados de la partida real.

Se verificaron siete tamaños de viewport: **1360×880, 1224×792, 1920×1080, 768×1024, 390×844, 430×932 y 844×390**. Las comprobaciones incluyen límites reales de controles, ausencia de solapamientos, accesibilidad de Equipo y Resumen tras una pelea, pausa en documentos y conservación de la semilla, el estado de combate y el progreso al redimensionar. Cambiar el tamaño durante la entrada de los personajes cancela el desplazamiento anterior y aplica las posiciones nuevas.

Una prueba adicional del renderizado de la arena pasó **144 comprobaciones** con GPU: cobertura sin deformación, coordenadas de impactos y partículas, indicador de turno y fondo de respaldo. Se revisaron capturas nativas de reposo, combate, resultado, menú, entrenamiento y rendición, además de una firma forzada exclusivamente para revisión visual. Los tamaños móviles se simularon en viewports de Godot; no se probaron dispositivos móviles físicos.

Se añadieron regresiones para una firma que termina la pelea y para dos firmas consecutivas: el resultado cierra el banner y el reemplazo cancela la animación anterior, evitando que reaparezca el registro bajo una firma aún visible.

La aplicación real se reabrió y se verificaron el panel de entrenamiento y F11. Quedó abierta a pantalla completa con **Mugo, nivel 3, 65 XP y 2 puntos**, listo para jugar. El guardado real es idéntico byte por byte al archivo anterior a esta reapertura; no se gastaron puntos ni se jugaron batallas de prueba en esa partida.

Capturas de la interfaz con partidas de prueba:

- [Combate en escritorio](interfaz-escritorio.png)
- [Combate en formato móvil](interfaz-movil.png)
- [Resultado en formato horizontal](interfaz-horizontal.png)
- [Golpe Firma](interfaz-firma.png)
