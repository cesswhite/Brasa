# FX sincronizados y contactos de suelo

El renderer de partículas conserva su estilo orgánico y sus ocho efectos existentes. Se añadieron `dust_small`, `dust_medium`, `dust_heavy`, `footplant_dust`, `dash_dust`, `slide_dust`, `knockback_dust` y `stone_debris`. El atlas radial antiguo no se dibuja. Los granos tienen nacimiento y trayectoria de mundo, nunca se quedan pegados al personaje después de emitirse.

`MoveVisualProfile` describe animación, variante compuesta, track anatómico, impacto, estela, suelo, reacción, cámara, hit stop, sonido y requisito de transformación. Sus marcadores usan fases y fracciones de los tiempos reales del movimiento; no crean ataques, daño, recompensas ni nuevos resultados de combate.

`CombatFX.play_move()` es el único programador de esos marcadores para las llamadas existentes de combate y repetición. Un cursor por acción procesa todos los marcadores cruzados, incluso a 20 FPS o en reproducción x2. Su identidad incluye actor, lado, tiempo e ID del movimiento. Reconciliar el mismo evento no vuelve a emitirlo; entrar tarde conserva la edad de las partículas aún visibles y descarta las expiradas. `clear()` es el reinicio explícito para un seek. Los eventos sintéticos sin tiempo/ID representan una sola acción hasta ese reinicio.

Los marcadores incluyen contactos de pie izquierdo/derecho, despegue, aterrizaje, inicio y final del deslizamiento, retroceso preparatorio, carga, inicio de FX anatómico, avance, continuación y recuperación. Despegue y aterrizaje se vinculan a las fases de animación. El emisor consume `FighterView.effect_anchor()` para obtener el contacto proyectado en el suelo, separado de la posición del pie en el aire. Las partículas se asientan en su propia altura de nacimiento y no atraviesan el piso.

La API de impacto añade un argumento opcional: `play_impact(at, presentation, actor_scale, facing, age, target_actor)`. Con un defensor disponible, heavy/critical producen polvo y knockback/knockdown/KO emplean polvo de arrastre; knockdown/KO añaden unos fragmentos pequeños. El contacto de daño y el impacto principal siguen llegando del evento autoritativo existente. La reacción del suelo acompaña el inicio de esa reacción: no pretende simular una colisión física nueva al caer.

No se llama a `illuminate_effect()` desde `CombatFX`. Carga, estados y transformación emiten partículas sin iluminar todo el cuerpo. La capa anatómica pareada pertenece a `FighterView` y sigue su frame/transform. `AttachedEnergyTrack` genera una textura RGBA transparente de 512×512 desde los sockets de núcleo y mano medidos en la pose actual de Ascua. El radio del núcleo es 12 px, el de la mano 10 px, y el alfa nunca supera 0.35, incluso si ambas regiones se solapan. No hay núcleo blanco ni anillo grande; fuera de esas regiones todos los píxeles son transparentes. Si falta el núcleo anotado, no se inventa su ubicación. Una caché LRU conserva como máximo 16 texturas; el generador no lee ni modifica la imagen del cuerpo.

`FighterView` aplica la intensidad desde su propio reloj de carga o transformación, con una opción para apagar FX durante la revisión. Las dos capas tienen exactamente el mismo transform, reflejo, pivot y offset; pausa e hit stop no pueden separarlas. El perfil del piloto usa canvas 512, pivot [256,448] y densidad 1.5, suministrados por el pipeline canónico. La forma `ember_core` reutiliza esta anatomía y cambia la energía superpuesta.

Los límites siguen siendo 20 emisores, 320 partículas y 12 acciones pendientes. Cada acción guarda un cursor sobre un perfil compacto (máximo 9 marcadores en los perfiles actuales), en lugar de ocupar una entrada pendiente por cada partícula o callback. La memoria de deduplicación conserva 64 acciones completadas y el historial de diagnóstico 128 marcadores. Pausa congela cursores y partículas; movimiento reducido limpia emisiones, programación y sacudidas. Los actores se conservan mediante referencias débiles.

## Validación

Los fixtures no abren Main, partidas guardadas ni cuentas remotas. `test_combat_fx.gd` verifica los 16 efectos, ausencia de atlas radial y luz global, presupuestos, coordenadas entre padres transformados, catchup, pausa, reducción de movimiento y conservación del RNG. `test_visual_fx_markers.gd` comprueba los mismos marcadores a 20/60/120 FPS en x1/x2, deduplicación, recuperación tardía, piso, reflejo horizontal, deriva libre y liberación de actores. `test_organic_fx.gd` conserva la regresión previa de partículas y repetición. `test_attached_energy_track.gd` exige al menos 16 poses reales con núcleo anotado y prueba `FighterView` de Ascua en siete momentos de carga, mirando a ambos lados: canvas compartido, intensidad sincronizada, pausa, hit stop, movimiento reducido y comparación exacta de los bytes del cuerpo al apagar y encender FX.

Estos tests validan el sistema de FX; la revisión visual se realiza por separado. El piloto Ascua ya pasó la reproducción nativa a velocidad real y la revisión de sus fuentes finales, incluidos los 32 contactos de suela anotados en movimiento. La carga mantiene legibles piedra, metal y tela, y el polvo nace en el suelo. Véanse el [dictamen por banco](../../../work/visual-consistency/roster-native/acceptance-current.md), el [vídeo final](../../../work/visual-consistency/ascua-final.mp4) y la [evidencia de contactos](../../../work/visual-consistency/roster-native/ascua/movie/footplant-detail.png). El vídeo usa MovieMaker a 60 fps y sirve de evidencia visual; la prueba de velocidad real se ejecutó sin grabación ni tasa de fotogramas forzada.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path outputs/Brasa --script res://tests/test_combat_fx.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path outputs/Brasa --script res://tests/test_visual_fx_markers.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path outputs/Brasa --script res://tests/test_organic_fx.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path outputs/Brasa --script res://tests/test_attached_energy_track.gd
```

La posición de un marcador tardío se evalúa en la pose disponible al despacharlo. Su edad es exacta, pero no se reconstruye una trayectoria histórica de sockets cuando varios fotogramas fueron omitidos; los tests de frecuencia garantizan eventos únicos y suelo estable, no identidad píxel a píxel entre tasas de refresco.
