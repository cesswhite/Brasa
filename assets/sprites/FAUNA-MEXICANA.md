# Four colleagues from Mexico

Four original atlases were created using the built-in **image_gen** tool, with a separate generation for each character and native framing and transparency fixes where necessary. The final PNGs were copied to the project without altering their pixels with external tools.

| Character | Inspiration and design | File |
| --- | --- | --- |
| Balam | Jaguar with golden fur with rosettes, robust build, jade sash and dark wristbands. | [balam-v1.png](balam-v1.png) |
| Tepa | Teporingo with brown hair, short ears, indigo jacket and mustard sash. | [tepa-v1.png](tepa-v1.png) |
| Xuna | Xoloitzcuintle with charcoal skin without hair, erect ears, copper vest and coral sash. | [xuna-v1.png](xuna-v1.png) |
| Copal | Cacomixtle with brown fur, thin snout, ringed tail, light vest and plum sash. | [copal-v1.png](copal-v1.png) |

The style retains the legible shapes and painted textures of Brasa, with amber lighting and cool shadows. The characters have fantasy anthropomorphic proportions; Their names, personalities and techniques belong to the game.

## Poses and animation

Each PNG contains eight right-facing silhouettes: rest, breathing, preparation, hit, hit received, dodge, victory and defeat. There are four columns and two rows in an RGBA image of 1774 × 887, with real transparency. Rivals use the same horizontally mirrored poses.

JSON files of the same name delimit each complete silhouette. `FighterView` computes a common scale from rest and anchors each pose to the ground. Separation and coverage are checked against the alpha of the PNG; The regions do not share visible pixels or cut off legs, ears, fists, or tails. The movements, jumps, anticipations and recoveries are built with the existing movement system on these poses.

The [full prompts](fauna-mexicana-prompts.md) preserve the text of the builds and corrections. The [PNG source](fauna-mexicana-origen.json) records local sources and hashes of the final files. The project consumes only copies of this folder.

## Animal References

The teporingo is a rabbit endemic to the central area of the Neovolcanic Axis; Its compact body and short ears guided Tepa. [CONANP: teporingo file](https://www.conanp.gob.mx/pdf_especies/teporingo.pdf).

The jaguar lives in Mexico, with records from Sonora to Yucatán. Its rosettes and strong silhouette guided Balam. [CONANP: jaguar](https://www.gob.mx/conanp/articulos/jaguar-especie-ejemplar?idiom=es).

The xoloitzcuintle is a breed of dog native to Mexico. Xuna takes the hairless skin and upright ears of its most recognizable variety. [INAH: the dog, guardian of life after death](https://inah.gob.mx/index.php/boletines/el-perro-guardian-de-la-vida-despues-de-la-muerte).

The northern cacomixtle has a distribution in Mexico and a long ringed tail that defines Copal. [CONANP: Bassariscus astutus](https://conanp.gob.mx/conanp/dominios/iztapopo/documentos/fichas_de_especies/Bassariscus_astutus.pdf), [El Marqués Biodiversity: cacomixtle](https://elmarques.gob.mx/biodiversidad/portfolio-items/bassariscus-sp/).

The integration, native captures and tests are in [Mexican fauna](../../reports/FAUNA-MEXICANA.md).
