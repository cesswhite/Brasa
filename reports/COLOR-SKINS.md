# Color y skins · Colección y pruebas de apariencia

## Interacción y jerarquía

| Antes | Después |
| --- | --- |
| Un punto de color de 10 × 10 px. | Muestras de tres tonos de 56 px de alto, nombre y estado; selección visible sin depender sólo del color. |
| Cinco paletas. | Doce paletas: se añaden Cempasúchil, Turquesa, Grana, Cacao, Marfil, Cobre y Amatista. |
| Las apariencias de familia estaban mezcladas con todos los cuerpos. | Dentro de Color, un selector Colores / Skins reúne las seis apariencias especiales ya dibujadas. La lista de Cuerpo conserva sus opciones. |
| Las variantes eran miniaturas poco descriptivas. | Tarjetas con figura, nombre y requisito; tres columnas en pantallas amplias, dos en medianas y filas compactas de skins en móvil. Se conserva una cámara común y la diferencia de volumen. |
| Elegir un elemento bloqueado sólo producía un aviso. | Puede probarse en el compañero con su requisito visible, sin alterar el borrador ni el inventario. Guardar queda desactivado y Volver restaura lo seleccionado. El controlador también rechaza confirmar pruebas bloqueadas. |
| La lista volvía arriba al elegir. | Conserva el desplazamiento y el foco al seleccionar; los cambios de sección tienen un destino de teclado válido. |
| Ayuda larga al pie. | Instrucciones cortas; descripción ampliada al pasar sobre una opción. Los botones compactos de la revisión anterior se conservan. |

Las muestras representan los tonos de cada paleta. El resultado sobre el personaje se muestra con su renderer real: conserva la ilustración y su transparencia. No se generaron sprites ni se reemplazaron las apariencias existentes.

## Nuevos colores y desbloqueos

| Paleta | Requisito |
| --- | --- |
| Cempasúchil | Nivel 2 con un luchador |
| Turquesa | Nivel 3 con un luchador |
| Grana | Encuentro 4 de Historia |
| Cacao | 3 victorias de Liga con un luchador |
| Marfil | Nivel 6 con un luchador |
| Cobre | Encuentro 12 de Historia |
| Amatista | 8 victorias de Liga con un luchador |

Original, Jade y Ocaso siguen disponibles desde el principio; Luna y Tinta mantienen sus requisitos. El inventario existente recibe las recompensas mediante su verificación habitual del progreso, sin reiniciar identidades ni partidas.

Las skins conservan los requisitos existentes: Roque / Cora / Ámbar en los encuentros 21 / 22 / 23, y Sabino / Pedernal / Nieve en 61 / 62 / 63. Se conceden automáticamente al superar esos encuentros. Probarlas aquí no concede su propiedad. Son cosméticas y no aumentan estadísticas.

## Validación y alcance

- **3133 comprobaciones de interfaz, 0 fallos:** siete tamaños, colores y skins, creación y edición, prueba bloqueada, retorno, requisitos sin solapamientos y conservación del borrador. Se comprueba también que las doce paletas alteren el pigmento y conserven exactamente el alfa del sprite.
- **1032 comprobaciones de identidad, 0 fallos:** partidas desechables, desbloqueos en el encuentro exacto, ausencia de recompensas anticipadas, persistencia, lectura posterior y fallos de escritura.
- **74 comprobaciones de foco, 0 fallos.**
- **11 pruebas de servidor local, 0 fallos:** familias, nuevas paletas y operaciones de identidad. Los siete colores se validan antes/en su umbral; el servidor rechaza equipar opciones no poseídas y conserva estadísticas.
- Catálogo cosmético versión 3 exportado y sincronizado con la copia generada del backend. **No se publicó en Cloudflare:** los siete nuevos colores requieren publicar ese catálogo para desbloquearlos y equiparlos online. Las seis skins ya tenían integración de servidor.

Las capturas usan perfiles en memoria o archivos de prueba. No se modificaron partidas personales ni datos remotos. [Revisión visual](color-skins/index.html); logs, PNG y métricas en `work/color-skins/`. Las capturas de `editor/` corresponden al estado final con las ayudas breves; `final/` contiene la matriz funcional, anterior sólo a ese ajuste de texto.
