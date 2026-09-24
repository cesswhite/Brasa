# Brasa · Daño ilustrado en todo el elenco

> Actualización de producción: [escala, transparencia y daño localizado](SPRITE-PRECISION.md). Esta revisión sustituye las comparativas y hashes visuales históricos de este documento.

El rostro, la ropa y la postura muestran el desgaste dentro de la propia pintura. Esta entrega sustituye las manchas y rayas procedurales de la implementación anterior por una biblioteca herida completa para los **23 cuerpos visuales**, conservando la identidad y los materiales de cada uno.

[Tablero de revisión](illustrated-damage/index.html) · [Fuentes, prompts y SHA-256](illustrated-damage/manifest.json) · [Estado de la QA nativa](illustrated-damage/native-qa.json).

![Nima, Bruma y Mugo: limpio y herido a la misma escala](illustrated-damage/comparison.png)

El montaje procede de los PNG de producción, con la misma celda y escala. Es una comparación técnica estática, no una captura de combate.

## Cobertura y estados

**22 cuerpos reciben arte nuevo; Ascua reutiliza sus tres bancos critical-v1 previamente existentes.** Cada cuerpo tiene ocho poses base, dieciséis de movimiento y dieciséis de reacción: **920 poses en 69 pares PNG/JSON**. Las seis apariencias familiares y los dos jefes están incluidos. La selección sigue el cuerpo visual efectivo, que puede diferir del arquetipo de combate.

| Estado | Biblioteca utilizada |
| --- | --- |
| Preparado · grado 0 | Arte limpio existente. |
| Desgastado · grado 1 | Arte limpio y poses de fatiga existentes, sin marcas procedurales. |
| Dañado · grado 2 | Familia herida completa de 40 poses. |
| Crítico · grado 3 | La misma familia herida del grado 2. No representa otro nivel de arte generado. |

Los umbrales de presentación siguen siendo 72 %, 45 % y 22 % de vida mínima observada. La transición se coordina con la reacción; el alcance de un golpe no cambia de ilustración a mitad del contacto. La curación durante una pelea no repara la ropa. El desenlace conserva el estado y una batalla nueva lo reinicia.

La ropa rasgada, el rostro magullado y la postura cansada persisten en preparación, golpe, desplazamiento, salto, réplica, caída, incorporación, victoria y transformación. No se añade sangre, equipamiento ajeno ni una capa de marcas flotantes. El tinte cosmético y el flash de impacto siguen siendo funciones separadas; eliminar el desgaste procedural no obliga a eliminarlos.

## Cuerpos incluidos

| Conjunto | Cuerpos |
| --- | --- |
| Elenco inicial | Nima, Luma, Mugo, Sira, Iria, Duna, Kiro, Neris y Taro. |
| Fauna mexicana | Balam, Tepa, Xuna y Copal. |
| Gatos | Ónix y Bruma. |
| Jefes | Ascua y Véspera. |
| Familia Taro | Roque y Sabino. |
| Familia Duna | Cora y Pedernal. |
| Familia Bruma | Ámbar y Nieve. |

Los materiales se resuelven desde cada referencia: piedra astillada y tela gastada en Mugo; pelaje y ropa en Bruma; piel, membranas o caparazón cuando corresponden. Se preservan color de ojos, marcas de especie, prendas y equipos reconocibles. La postura encorvada no debe aumentar el tamaño de la cabeza ni acortar los miembros.

## Alfa real y preparación

Los originales nuevos se conservan con su hash. Se generaron sobre fondo plano de extracción —verde o magenta cuando la figura requiere conservar verde—, con una excepción histórica de fondo cuadriculado en el piloto de Nima. La limpieza autorizada elimina el fondo también dentro de los huecos entre brazos, piernas, colas y prendas. Ascua conserva byte por byte los tres PNG críticos aceptados.

La extracción actúa sobre alfa. La normalización usa RGB premultiplicado y un filtro bilineal de pesos positivos para evitar contaminación verde inventada en bordes semitransparentes. Las excepciones de huecos o superficies que comparten el color del fondo se registran mediante polígonos concretos ligados al SHA de la fuente, sin reclasificar indiscriminadamente toda la ropa o piel. No se borran todos los componentes pequeños: pueden ser dedos, flecos o partes legítimas del dibujo.

Los PNG finales son RGBA con transparencia real. La comprobación numérica de chroma no sustituye la revisión sobre fondos claro y oscuro: hay que comprobar huecos, ojos, color, anatomía, piezas completas y ausencia de halo. El tablero permite cambiar el fondo y ampliar cada pose. Sus miniaturas reducen todo el atlas al 50 %; no ajustan cada silueta por separado ni modifican los originales de producción.

## Escala, apoyos y contacto

El contrato permanece en celdas de **512 × 512**, pivote **256/448** y **1,5 píxeles por unidad**. Cada banco usa un único escalar. Una figura herida puede estar más baja por su postura; no se infla hasta llenar la caja limpia. La cámara y las proporciones físicas de cada especie siguen compartidas con el resto del juego.

Los metadatos describen el cuadro herido efectivo, incluyendo región, límites de alfa, raíz y procedencia. Los apoyos obtenidos por proyección se identifican expresamente como **aproximados**. No se presentan sockets de mano o torso heredados como mediciones anatómicas sobre dibujos nuevos.

Cuando falta una mano anotada, el renderer usa el **borde delantero pintado de la pose de golpe** como aproximación del alcance visual (`painted_strike_edge`). Esta solución no es un collider, una hitbox ni un cambio del alcance lógico. Los anclajes auxiliares sin anotación pueden usar las referencias generales del perfil; requieren revisión nativa para comprobar su colocación. La caché de daño está acotada a seis bancos y cada cuerpo se valida como conjunto completo antes de habilitar su familia herida.

No cambian PV, estadísticas, iniciativa, RNG, técnicas, resultados, recompensas, inventario ni guardados. El trabajo modifica la representación de eventos ya existentes, no las reglas que los producen.

## Validación técnica disponible

La [preservación de fuentes y referencias](illustrated-damage/evidence/final-art-preservation.json) pasó **276 comprobaciones, 0 fallos**: fuente original, referencias limpias cuando están registradas y hashes de PNG/JSON de producción. Los tres PNG de Ascua son idénticos a critical-v1. El pipeline pasó **23 pruebas, 0 fallos**. Estas cifras verifican preparación y procedencia; no son resultados de la presentación nativa.

## QA final y límites de la evidencia

- **3832 comprobaciones nativas, 0 fallos:** 23 cuerpos, 368 muestras y 39 PNG. Se prueban guardia, golpe, reacción y KO en 1360 × 880 y 390 × 844, en ambas direcciones. [Resultado](illustrated-damage/native/validation.json) y [39 copias con hashes](illustrated-damage/native-manifest.json).
- **Seis suites headless, 56 484 comprobaciones, 0 fallos:** daño ilustrado, familias, contacto, sprites, reloj de movimientos y KO por estado. La cifra **incluye** el gate estricto de 14 977 comprobaciones que confirma 23/23 cuerpos y 920 poses; no se suma dos veces. [Regresión consolidada](illustrated-damage/evidence/final-runtime-validation.json) y [gate de cobertura](illustrated-damage/evidence/final-runtime.json).
- **Revisión visual de las 39 capturas:** [11 láminas y los 16 contextos](illustrated-damage/evidence/root-native-art-review.json), más [las otras 12 láminas](illustrated-damage/evidence/fighter-art-native-review.json). Sin defectos de arte observados. Cada lámina muestra cuatro clips en dos orientaciones —184 sprites mostrados entre las 23—, no las 40 poses únicas en movimiento. Los bancos completos se revisan por separado en el tablero técnico.

La fixture nativa usa FighterView y BattleLayout de producción, con escenarios y clips reales del renderer. **No inicia Main, no abre perfiles y no simula victorias ni recompensas.** Mostrar la animación común de guardia en el muestrario no concede esa habilidad a quien no la tenga. La paridad de mínimos de vida entre Main y Replay se comprueba separadamente en la suite de daño ilustrado. Las fuentes y el runtime permanecieron estables durante la captura.

El [primer pase](illustrated-damage/evidence/first-pass/validation.json) se conserva: 3878 comprobaciones y 46 fallos, debidos a una aserción de avance de contacto aplicada a figuras sin rival. Se restringió esa aserción a parejas, manteniendo las verificaciones de raíz y encuadre de las figuras aisladas. El pase final conserva 92 comprobaciones de contacto terminal con pareja y registra 46 muestras de KO sin pareja. No se recortó arte ni se modificó el runtime para resolverlo; los 39 PNG finales son idénticos a los ya revisados.

El visor se comprobó en enlaces, hashes y sintaxis JavaScript. **No se realizó QA de navegador ni de DOM:** Chrome no estaba disponible mediante CUA y los entornos Node locales no incluyen jsdom, happy-dom o linkedom. Esa limitación del informe HTML no se presenta como una prueba del juego.

## Procedencia e historial

Producción: `assets/sprites/damage/illustrated-v2/<body>-<bank>.png` y JSON hermano. El [manifiesto del tablero](illustrated-damage/manifest.json) registra fuentes aprobadas, hashes de PNG/JSON, referencias limpias, prompts disponibles, validaciones y revisiones. El manifiesto global original está en `work/illustrated-damage/final-art-manifest.json`; el tablero conserva una [copia del manifiesto global](illustrated-damage/evidence/final-art-manifest.json).

[La entrega anterior de familias y daño híbrido](DAMAGE-AND-FAMILIES.md) se conserva como historial. Su descripción del shader y de la cobertura exclusiva de Ascua dejó de ser la implementación vigente. Las familias, desbloqueos y demás reglas de aquella entrega continúan fuera del alcance de este cambio visual.
