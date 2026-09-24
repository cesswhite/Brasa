# Brasa · Escala, transparencia y daño localizado

Actualizado el 21 de septiembre de 2026. Correcciones integradas en los recursos que carga el juego.

[Comparativa interactiva](sprite-precision/index.html) · [Verificación de los PNG de producción](../../../work/sprite-precision/verification-production.json) · [Capturas nativas](../../../work/sprite-precision/native)

## Revisión 2 · Heridas más visibles

La revisión anterior protegía el color, pero descartaba daños del rostro y la ropa al agruparlos en regiones demasiado extensas. Ahora se seleccionan zonas compactas dentro de esas regiones y se refuerza el contraste local de las abrasiones, hematomas y roturas ya ilustradas. No se añade un filtro global al personaje.

Se actualizaron únicamente los 69 atlas heridos y sus metadatos. Los 69 atlas sanos conservan exactamente sus hashes de la revisión anterior. En los 920 pares, el alfa sigue siendo idéntico y los píxeles fuera de las heridas se conservan exactamente. La mediana de superficie modificada es 12.12%; el máximo es 21.43%. El refuerzo está en la legibilidad de las marcas, no en teñir una superficie mayor.

La comparativa interactiva ahora muestra **sano / herido de la revisión 1 / herido reforzado**. La revisión 1 se conserva en `work/sprite-precision/revisions/v1/damage`.

Validación repetida tras esta actualización: 1,840 cuadros sin errores; 14,985 comprobaciones de daño sin fallos; 40,882 comprobaciones de contacto sin fallos; 3,832 comprobaciones del render nativo sin fallos, con 39 capturas nuevas. Se revisaron las seis láminas generales y las capturas nativas de Nima, Luma y Taro Roque. [Capturas de esta revisión](../../../work/sprite-precision/native-v2).

Las comprobaciones restantes de la tabla inferior corresponden a la primera revisión. Esta actualización no modifica la lógica, las escalas, las partidas ni las reglas de progresión.

## Resultado

23 cuerpos, incluidos jefes y apariencias familiares; 40 poses por cuerpo, con versiones sana y herida: **1,840 cuadros en 138 atlas RGBA**. Cada celda conserva 512 × 512 px, el origen (256, 448) y la densidad de 1.5 píxeles por unidad del juego.

La versión herida de cada pose usa ahora la geometría exacta de la versión sana. **El canal alfa es idéntico en los 920 pares**, por lo que recibir daño no puede encoger o ensanchar el dibujo. Fuera de las zonas de daño local, los valores RGBA son idénticos píxel por píxel: no se aplica un tinte, una desaturación, una exposición ni una opacidad global por estar herido.

El daño conserva detalles de las ilustraciones heridas anteriores: se registran sobre su pose sana, se separan las variaciones amplias de iluminación y se transfieren únicamente detalles locales de golpes, abrasiones y roturas. El resultado queda pintado en los PNG. No se añade un shader de desgaste ni una nueva capa flotante en tiempo de ejecución. Los grados de daño, la progresión y las reglas del combate no cambian.

## Escala y color entre grupos

Se calibra cada grupo de poses contra la guardia original de su propio personaje, con una transformación uniforme alrededor del punto de suelo. No se fuerza la altura de una pose agachada, una caída o un salto a la de una pose erguida. Se conservan las diferencias de volumen entre personajes.

Por ejemplo, la guardia de Cora en reacciones medía 307 px frente a los 267 px de su guardia original; ahora mide 267 px. La de Taro Sabio pasa de 296 a 276 px. También se corrige la reducción de Ónix en reacciones. Las poses de respiración se alinean con su guardia.

Los tonos de cada grupo sano se calibran mediante parches correspondientes de su pose de referencia, conservando las texturas. Este ajuste es independiente del daño: las versiones sana y herida reciben exactamente la misma calibración de base.

La corrección no equivale a redibujar anatómicamente todos los miembros de cada pose. Los dibujos conservan sus gestos, escorzos y variaciones artísticas originales; no se presenta el análisis de correspondencias como una certificación anatómica. Las garantías exactas son la geometría sana/herida, la conservación de las zonas intactas y la transparencia real.

## Transparencia y procedencia

- PNG con canal alfa real y bordes exteriores de cada celda completamente transparentes.
- Interpolación de escala con color premultiplicado para evitar halos de remuestreo.
- Limpieza conservadora del borde blanco neutro; se conserva el dibujo interior y no se erosiona la silueta.
- La prueba de generación que devolvió una cuadrícula pintada fue descartada y nunca se incorporó al juego.
- Originales de todos los atlas y metadatos conservados en `work/sprite-precision/originals`.
- Transformaciones, hashes y regiones de daño registrados en `work/sprite-precision`; metadatos y manifiesto actualizados.
- Las anotaciones anatómicas existentes se transforman con el dibujo. Las versiones heridas heredan únicamente las anotaciones que ya tenía la pose sana, cuya geometría comparten.

## Validación

| Comprobación | Resultado |
| --- | --- |
| RGBA, transparencia exterior, límites, hashes, igualdad del alfa y conservación fuera del daño | 1,840 cuadros; 0 errores |
| Daño ilustrado completo, transición de salud, identidad y límites de vista | 14,985 comprobaciones; 0 fallos |
| Contacto entre peleadores y continuidad del golpe/KO | 40,882 comprobaciones; 0 fallos; 1,933 casos |
| Render nativo de los 23 cuerpos | 3,832 comprobaciones; 0 fallos; 39 PNG |
| Geometría, anotaciones y consistencia visual | 2,213 comprobaciones; 0 fallos |
| Familias y estados de daño | 128 comprobaciones; 0 fallos |

Se inspeccionaron las seis láminas del elenco y capturas nativas representativas de Nima y Cora. Las 39 capturas están disponibles; no se afirma una revisión humana individual de las 1,840 ilustraciones.

Se actualizó la prueba de contacto para comprobar anotaciones compartidas en la misma geometría en lugar de proyecciones aproximadas sobre otro dibujo. También se corrigió un fixture de anotaciones para refrescar su cuadro de render después de inyectar una muestra. No fue necesario cambiar la lógica de juego.

El visor interactivo tiene enlaces locales y sintaxis verificados. La política del navegador integrado impidió abrirlo automáticamente; sus interacciones no se pudieron verificar con automatización de navegador en esta sesión. Puede abrirse manualmente desde el enlace.

Las pruebas usan escenas desechables; no abren partidas del usuario ni escriben en el backend. Si el juego estaba abierto, hay que cerrarlo y abrirlo para descartar las texturas que conserva en memoria.
