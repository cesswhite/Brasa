# Procedencia y avisos de terceros

Revisión documental: 24 de septiembre de 2026. Este inventario distingue procedencia de concesión de derechos.

## PCG y Godot

`backend/battle-engine/rng.js` adapta PCG XSH RR y el comportamiento float32 de Godot a JavaScript/BigInt para reproducir resultados. Son modificaciones respecto a la implementación C/C++ original; se mantienen los avisos en el archivo.

- PCG: Copyright (c) 2014 M. E. O'Neill. Apache License 2.0. [Texto incluido](licenses/Apache-2.0.txt), [fuente inspeccionada](https://github.com/godotengine/godot/blob/ed1daf0bf/thirdparty/misc/pcg.cpp).
- Godot: Copyright (c) 2014-present Godot Engine contributors; Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur. MIT. [Texto incluido](licenses/Godot-MIT.txt), [adaptación de referencia](https://github.com/godotengine/godot/blob/ed1daf0bf/core/math/random_pcg.h).

Godot se instala por separado. Al distribuir un ejecutable, conserva además los avisos requeridos por su motor y los componentes efectivamente incluidos.

## Imágenes

La documentación de [arte](assets/ARTE.md), [sprites](assets/sprites/PROMPTS.md) y [dirección visual](assets/ui/ART-DIRECTION.md) identifica imágenes generadas con la herramienta de ChatGPT. No se afirma un identificador de modelo que no esté registrado. Se reservan los derechos aplicables; no se relicencian las imágenes bajo MIT. [Términos de OpenAI](https://openai.com/policies/terms-of-use/).

## Audio

El [manifiesto](assets/audio/SOURCE-MANIFEST.json) registra ElevenLabs Sound Effects y Eleven Music. Crédito: **ElevenLabs — elevenlabs.io; música generada con Eleven Music**. Los archivos de audio y videos no se incluyen en la edición pública.

La [política de ElevenLabs, 9(c)](https://elevenlabs.io/use-policy) restringe distribuir salidas de Sound Effects como archivos aislados. Los [términos de Eleven Music](https://elevenlabs.io/eleven-music-model-specific-terms) y el plan vigente en la generación determinan derechos adicionales. El manifiesto demuestra procedencia técnica, no permiso para cualquier redistribución. No se ha verificado aquí una licencia comercial para cada grabación.

## Dependencias de desarrollo

El backend instala sus dependencias con `npm ci` y su lockfile. Better Auth, el plugin passkey, Wrangler, Miniflare, esbuild y dependencias transitivas conservan sus licencias. No se distribuye `node_modules` en este repositorio. Antes de distribuir un bundle, revisa los avisos del conjunto instalado y conserva los que le correspondan; la licencia MIT de Brasa no los sustituye.
