# Brasa · superficies y lugares de Historia

Pintura digital 2D con textura de pincel, materiales gastados y siluetas legibles. Luz cálida de faroles, sombras azul petróleo, piedra/ocre/cobre, madera y tejidos. La Ruta inicial mira hacia el camino de faroles; Tormenta usa raíces, hierro, musgo y roca mojada. Taller, refugio y archivo son lugares distintos dentro del mismo mundo.

Los cinco fondos contienen espacio vacío útil para controles y personajes nativos. No son pantallas completas. Los sprites actuales se dibujan por separado y conservan nombre, aspecto y animación. Números, XP, capítulos, recomendaciones y etiquetas siguen siendo texto de Godot.

`shared/surfaces-v1.png` contiene ocho superficies aisladas: dos botones, dos marcos, tres medallones y un separador. `shared/props-v1.png` contiene seis objetos: uniforme azul y cinturón amarillo de Tepa, vendas jade de Balam, brasero de Ascua, reliquia de tormenta, mochila usada y medalla de Arena. Las regiones reales, no una cuadrícula asumida, se usan para evitar recortar objetos.

El registro `data/ui_visual_manifest.json` define contextos, estilos, regiones y condiciones de decoración. Sus objetos son decorativos, no controles, no comprobaciones de logros y no lógica de progresión. Los fondos se cargan bajo demanda. El atlas de superficies se adapta una vez a escala de interfaz por Godot y se reutiliza.

Se generaron siete imágenes con la herramienta integrada `image_gen`, conservando los PNG originales y el canal alfa. La herramienta no ofrecía selector explícito «2.5»; no se cambió a una API o CLI. Los prompts completos, destinos y hashes están en [GENERATION-PROMPTS.json](GENERATION-PROMPTS.json).

Fuentes de implementación: [StyleBoxTexture / nine-patch](https://docs.godotengine.org/en/4.6/classes/class_styleboxtexture.html). El comportamiento se valida además con el Godot 4.7.2 instalado y capturas nativas.
