# Contacto y profundidad de los peleadores

El límite anterior retraía cualquier píxel que cruzara el centro, incluido el brazo que debía golpear. El resultado era un golpe al aire aunque la animación intentara avanzar. Arena, Historia y Replay comparten ahora una aproximación visual adaptada a la pareja y un orden de dibujo que coloca al atacante delante.

| Aspecto | Antes | Después |
| --- | --- | --- |
| Contacto | Cada silueta completa debía permanecer en su mitad. | El brazo cruza el centro y apunta al tercio frontal del torso neutral rival. |
| Profundidad | El rival derecho siempre se dibujaba delante. | El atacante ocupa el primer plano de la pareja durante su acción; FX y HUD conservan sus puestos. |
| Recuperación | El avance quedaba anulado por el límite central. | Acercamiento y regreso usan el reloj de la animación existente. |
| Acciones simultáneas | Dos golpes separados. | Se limita el cruce de centros y el último evento decide la prioridad visual. |
| KO/victoria durante contacto | El cambio de pose podía devolver la figura a su posición neutral. | Se conserva la posición horizontal de la figura hasta reiniciar el combate. |
| Movimiento reducido | Poses sin avance animado. | Conserva esa opción y añade la prioridad visual del atacante. |

No se modificaron estadísticas, RNG, daño, tiempos del motor, progresión, guardados, backend, audios ni arte. Las raíces de los actores y su escala física por especie permanecen fijas. Los retratos sin rival enlazado conservan el comportamiento anterior.

## Evidencia

[Tablero antes/después](combat-contact/index.html), con capturas nativas de Main y BattleReplayPanel en escritorio y móvil. Son fixtures explícitos en memoria; no abren perfiles del usuario ni generan recompensas.

`tools/contact_showcase.gd` reproduce las fases de guardia, viaje, contacto y recuperación de parejas de distintos tamaños; también comprueba movimiento reducido y finales de combate. `tests/test_fighter_contact.gd` añade comprobaciones de cercanía, límites, orientación, raíces, pausa, cambio de tamaño, concurrencia, contraataques, orden visual y reinicio.

| Validación ejecutada | Resultado |
| --- | --- |
| Contacto: 23 cuerpos, 7 tamaños, ambos sentidos, 1.933 casos | 40.882 comprobaciones, 0 fallos. |
| Capturas nativas finales de Main y Replay | 128 PNG, 528 comprobaciones, 0 fallos; 108 instantes comparables con la base. |
| Límites previos de figuras sin pareja | 185.472 comprobaciones, 0 fallos. |
| Relojes de movimientos | 154 comprobaciones, 0 fallos. |
| Estado, KO y presentación | 91 comprobaciones, 0 fallos. |
| Marcadores de FX | 434 comprobaciones, 0 fallos. |
| Reproducción visual | 821 comprobaciones, 0 fallos en 7 tamaños. |
| Layout de batalla | 2.139 comprobaciones, 0 fallos. |
| Presentación de movimientos existente | 857 comprobaciones, 1 fallo anterior confirmado con código previo (Balam/HUD). |

La matriz de contacto conserva hashes idénticos de entrada/salida. Resultados detallados: `work/fighter-contact/validation.json` y `work/contact/after/observations.json`, desde la raíz del workspace.

## Límites de la corrección

El ajuste resuelve distancia horizontal y superposición. No redibuja las extremidades: un gigante contra un personaje muy pequeño conserva la altura de golpe que tiene su sprite. Siete cuerpos tienen mano anotada en la pose de extensión; el resto usa el borde pintado de esa pose como aproximación de alcance visual. No se presenta esa aproximación como un socket anatómico exacto.

La prueba existente `test_move_presentation.gd` encuentra un solapamiento de HUD con `balam_salto` a 1224×792. Se reprodujo también con `work/contact/before/source/fighter_view.gd`: es anterior a este ajuste, no una regresión de contacto.

La matriz nueva registra además 14 intersecciones de guardia con las cajas del HUD a 844×390 (Duna, Cora, Pedernal y Ascua). Sus límites pintados son idénticos con y sin pareja; quedan registrados como observaciones previas en el JSON. No se cambió el encuadre para corregirlos dentro de este ajuste de contacto.
