# Partículas orgánicas de combate

CombatFX conserva sus ocho IDs y las APIs de impactos, movimientos, estados, pausa y cámara. El render ya no carga ni dibuja el atlas ilustrado anterior: sus regiones permanecen como compatibilidad de la API `effect_texture`, sin uso en la presentación normal. No se modificó ningún PNG.

- `small_hit`, `heavy_hit`, `critical_hit`: chispas estrechas dirigidas por el golpe, con dispersión pequeña, frenado y gravedad.
- `dust`, `landing_dust`: polvo tenue pegado a los pies y repartido horizontalmente.
- `dash_trail`: partículas cortas liberadas detrás del cuerpo, que pierden velocidad y opacidad.
- `charge_energy`, `transformation`: pequeñas brasas que nacen junto al cuerpo y ascienden, sin anillos, ondas ni bolas grandes.
- Estados: curación verde suave ascendente, veneno oliva con deriva de niebla, guardia/escudo azul gris con flecos estrechos; otros estados usan bruma tenue.

`emit_attached(id, actor, anchor="body", age=0, tint=WHITE)` sigue `actor.effect_anchor()` mediante conversión de coordenadas globales a locales del FX. Carga usa mano, estados pecho, despegue/aterrizaje pies y desplazamiento espalda. Se conserva únicamente una referencia débil: las partículas ya emitidas se sueltan y se extinguen, y las pendientes se eliminan cuando desaparece el actor.

La iluminación reflejada usa `illuminate_effect` con intensidad 0.065 y duración máxima 0.4 s. Los offsets de eventos atrasados se aplican a luz y partículas. Movimiento reducido desactiva estas emisiones y la cámara; pausa congela sus relojes.

Límites: 20 emisores, 320 partículas reservadas, 12 fases pendientes y como máximo 24 partículas por emisor. La configuración actual expira en 0.17–0.74 s. La variación es analítica y no usa el azar del motor ni el generador global.

**129 comprobaciones aprobadas, 0 fallos** en `test_combat_fx.gd`. Incluyen emisión orgánica sin cargar atlas, tamaños, coordenadas con padres transformados, seguimiento frente a deriva, eventos intactos, azar global intacto, catchup, límites, pausa, movimiento reducido y liberación de actores. La revisión visual nativa se realiza por separado.

[Resultados y hashes](combat-fx-validation.json). Ninguna partida real fue abierta ni escrita.

Ajuste de legibilidad tras la primera captura: núcleos de chispa de 1–1.5 px y brasas de 1.5–2.2 × 1.9–2.5 px antes de escala; colores y opacidad sostenidos, sin halo grande. En estados y transformación, dos tercios de los nacimientos se reparten junto a mano y espalda para distinguirse del sprite, conservando emisión anclada y deriva libre. Las muestras finales de escritorio 1 (carga/contacto) y 2 (fuego/transformación) fueron aprobadas por root. Main nativo pasó 153 comprobaciones, 0 fallos. Código congelado; QA móvil y vídeo se documentan por separado al completarse.
