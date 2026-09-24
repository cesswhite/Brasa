# Third-party notices and provenance

Document review: 24 September 2026. This inventory distinguishes provenance from permission to use or redistribute content.

## PCG and Godot

`backend/battle-engine/rng.js` ports PCG XSH RR and float32 behavior from Godot to JavaScript/BigInt to reproduce results. This is an adaptation of the original C/C++ implementation; its notices remain in the source file.

- PCG: Copyright (c) 2014 M. E. O'Neill. Apache License 2.0. [Text included](licenses/Apache-2.0.txt), [source inspected](https://github.com/godotengine/godot/blob/ed1daf0bf/thirdparty/misc/pcg.cpp).
- Godot: Copyright (c) 2014-present Godot Engine contributors; Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur. MIT. [Text included](licenses/Godot-MIT.txt), [reference adaptation](https://github.com/godotengine/godot/blob/ed1daf0bf/core/math/random_pcg.h).

Godot is installed separately. When distributing an executable, preserve the notices required by the engine and the components actually included.

## Images

The documentation for [art](assets/ARTE.md), [sprites](assets/sprites/PROMPTS.md), and [visual direction](assets/ui/ART-DIRECTION.md) identifies images generated with the ChatGPT tool. No model identifier is claimed unless it was recorded. Applicable rights are reserved; images are not relicensed under MIT. [OpenAI Terms](https://openai.com/policies/terms-of-use/).

## Audio

The [manifest](assets/audio/SOURCE-MANIFEST.json) records ElevenLabs Sound Effects and Eleven Music. Credit: **ElevenLabs — elevenlabs.io; music generated with Eleven Music**. Audio and video files are not included in the public edition.

[ElevenLabs policy, 9(c)](https://elevenlabs.io/use-policy) restricts distributing Sound Effects outputs as isolated files. The [Eleven Music terms](https://elevenlabs.io/eleven-music-model-specific-terms) and the plan in effect at generation determine additional rights. The manifest records technical provenance, not blanket permission to redistribute. A commercial license for each recording has not been verified here.

## Development dependencies

The backend installs its dependencies with `npm ci` and its lockfile. Better Auth, the passkey plugin, Wrangler, Miniflare, esbuild, and transitive dependencies retain their licenses. `node_modules` is not distributed in this repository. Before distributing a bundle, review the notices of the installed set and keep the ones that apply; the MIT license of Brasa does not replace them.
