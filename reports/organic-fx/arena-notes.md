Arena: efectos de turno e impacto sin anillos

El foco del turno usa dos manchas de pigmento difuso, bajas y ligeramente descentradas, mediante ParticleInk.mote. Conserva el pequeño rombo para distinguir el turno también por forma. El impacto deja únicamente las partículas existentes, dibujadas como pequeñas chispas suaves con ParticleInk.spark; ya no crea ni dibuja el anillo expansivo.

Movimiento reducido borra las partículas y actualiza el foco de turno inmediatamente, con luz y rombo estáticos. No avanza el reloj visual. Los fondos, su transformación de perspectiva, faroles, estrellas y decoración no se modificaron.

Comprobaciones: parser de arena_view.gd sin errores; test_battle_layout.gd pasó 2139 comprobaciones, 0 fallos, en siete tamaños y los estados reposo/combate/resultado. El test usa sus rutas aisladas dentro de work/immersive; no se abrió Main de producción ni se importaron assets.

Copia anterior exacta: arena-before.gd. Diff: arena-changes.patch. Log: test_battle_layout.log.
