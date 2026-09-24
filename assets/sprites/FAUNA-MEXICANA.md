# Cuatro compañeros de México

Se crearon cuatro atlas originales con la herramienta integrada **image_gen**, con una generación separada para cada personaje y correcciones nativas de encuadre y transparencia cuando fueron necesarias. Los PNG finales se copiaron al proyecto sin alterar sus píxeles con herramientas externas.

| Personaje | Inspiración y diseño | Archivo |
| --- | --- | --- |
| Balam | Jaguar de pelaje dorado con rosetas, constitución robusta, faja jade y muñequeras oscuras. | [balam-v1.png](balam-v1.png) |
| Tepa | Teporingo de pelo pardo, orejas cortas, chaqueta añil y faja mostaza. | [tepa-v1.png](tepa-v1.png) |
| Xuna | Xoloitzcuintle de piel carbón sin pelo, orejas erguidas, chaleco cobre y faja coral. | [xuna-v1.png](xuna-v1.png) |
| Copal | Cacomixtle de pelaje pardo, hocico fino, cola anillada, chaleco claro y faja ciruela. | [copal-v1.png](copal-v1.png) |

El estilo conserva las formas legibles y texturas pintadas de Brasa, con luz ámbar y sombras frías. Los personajes tienen proporciones antropomorfas de fantasía; sus nombres, personalidades y técnicas pertenecen al juego.

## Poses y animación

Cada PNG contiene ocho siluetas orientadas a la derecha: reposo, respiración, preparación, golpe, impacto recibido, esquiva, victoria y derrota. Son cuatro columnas y dos filas en una imagen RGBA de 1774 × 887, con transparencia real. Los rivales usan las mismas poses reflejadas horizontalmente.

Los archivos JSON del mismo nombre delimitan cada silueta completa. `FighterView` calcula una escala común a partir del reposo y ancla cada pose al suelo. La separación y cobertura se verifican contra el alfa del PNG; las regiones no comparten píxeles visibles ni cortan patas, orejas, puños o colas. Los desplazamientos, saltos, anticipaciones y recuperaciones se construyen con el sistema de movimientos existente sobre estas poses.

Los [prompts completos](fauna-mexicana-prompts.md) conservan el texto de las generaciones y correcciones. La [procedencia de los PNG](fauna-mexicana-origen.json) registra fuentes locales y hashes de los archivos finales. El proyecto consume únicamente las copias de esta carpeta.

## Referencias de los animales

El teporingo es un conejo endémico de la zona central del Eje Neovolcánico; su cuerpo compacto y sus orejas cortas guiaron a Tepa. [CONANP: ficha del teporingo](https://www.conanp.gob.mx/pdf_especies/teporingo.pdf).

El jaguar habita en México, con registros desde Sonora hasta Yucatán. Sus rosetas y su silueta fuerte guiaron a Balam. [CONANP: jaguar](https://www.gob.mx/conanp/articulos/jaguar-especie-ejemplar?idiom=es).

El xoloitzcuintle es una raza de perro originaria de México. Xuna toma la piel sin pelo y las orejas erguidas de su variedad más reconocible. [INAH: el perro, guardián de la vida después de la muerte](https://inah.gob.mx/index.php/boletines/el-perro-guardian-de-la-vida-despues-de-la-muerte).

El cacomixtle norteño tiene distribución en México y una cola larga anillada que define a Copal. [CONANP: Bassariscus astutus](https://conanp.gob.mx/conanp/dominios/iztapopo/documentos/fichas_de_especies/Bassariscus_astutus.pdf), [Biodiversidad El Marqués: cacomixtle](https://elmarques.gob.mx/biodiversidad/portfolio-items/bassariscus-sp/).

La integración, las capturas nativas y las pruebas están en [Fauna mexicana](../../reports/FAUNA-MEXICANA.md).
