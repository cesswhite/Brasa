# El paso de la tormenta · Arte del capítulo 2

El segundo capítulo utiliza dos imágenes originales creadas con la herramienta nativa `image_gen`: una plaza nocturna entre montañas y el atlas transparente de Véspera. La herramienta no expone el nombre de su modelo interno.

| Recurso | Archivo final |
| --- | --- |
| Escenario · plaza de piedra húmeda | [arena-tormenta-v3.png](arena-tormenta-v3.png) |
| Véspera · polilla lunar | [sprites/vespera-v3.png](sprites/vespera-v3.png) |
| Regiones y anclajes de sus ocho poses | [sprites/vespera-v3.json](sprites/vespera-v3.json) |

Ambos PNG tienen 1774 × 887 píxeles y se conservan sin retoque de píxeles. El escenario es opaco; el atlas conserva el canal alfa generado. Las poses de Véspera son reposo, respiración, preparación, golpe, impacto, esquiva, victoria y derrota. Godot las anima con el mismo controlador que el resto del plantel.

[Vista del escenario y Véspera dentro del juego](../reports/capitulo2-batalla.png).

## Prompts exactos

### Escenario

```text
Use case: illustration-story
Asset type: seamless full-screen 2D game arena backdrop, landscape panorama with a 2:1 aspect ratio, ideally 2048 x 1024 pixels.
Primary request: an original hand-painted nocturnal mountain sanctuary called El paso de la tormenta, in the same visual family as an elegant gouache fantasy desert lantern-market game. Draw NO title or lettering. Rich illustrated environment, restrained painterly shapes, not a photograph or 3D render.
Scene: a jade-stone monastery and ancient terraces nestled between layered dark mountains at night. Weathered teal-green stone, broken ceremonial arches, modest pagoda-like roofs and faraway ruined stairways; warm amber hanging lanterns and softly lit windows at the far left and far right. Mist-covered water and distant mountain silhouettes beyond a low terrace wall. The dark teal sky has soft storm clouds and a small veiled moon, atmospheric and magical without violent lightning. Cool teal shadows, mossy jade stone, muted slate blues, warm amber lantern contrast; inviting mystery after rainfall.
Composition for actual combat gameplay: a very broad, quiet, clear wet-stone fighting plaza occupies the ENTIRE LOWER HALF of the image. Plaza begins around y=48% and reaches past the bottom edge. Gentle large paving shapes, subtle wet amber reflections at side edges; center floor is uninterrupted low-detail dark jade/slate stone with no emblems, cracks dominating, steps, props, puddle obstacles or dramatic light effects. Place ALL prominent architecture, foreground plants and lanterns toward outer left and right edges. Keep the middle 50% width open and visually calm. Distant water sits beyond the rear low terrace wall, not in the fighting plaza. Camera at an elevated game-stage angle, broad elliptical plaza in shallow perspective, level horizontal baseline.
Style: polished high-quality painterly 2D storybook background, confident broad brush shapes and delicate texture, sophisticated illustrated adventure-game art. Make the environment legible behind small animated characters and an upper HUD. Smooth quieter sky behind HUD; strong depth at the edges; avoid excessive detail or noise in center.
Constraints: no people, creatures, silhouettes, weapons, words, typography, logos, watermarks, UI, banners with text, grid, borders, black bars. Opaque finished environment, not transparent.
```

### Véspera

```text
Use case: stylized-concept
Asset type: production-ready 2D boss animation sprite atlas for a Godot game.
Primary request: ONE landscape 2:1 PNG sprite sheet, ideally 2048 x 1024 pixels, with EXACTLY eight full-body poses of the SAME character in an invisible 4-column by 2-row grid.
Subject: VÉSPERA, an adult anthropomorphic lunar moth warrior, a tall slender formidable second-chapter boss. Recognizable moth face with softly glowing violet eyes, feathered antennae, finely textured pale moon-silver fur around neck and chest, dark indigo segmented protective forearms and wrist guards. Folded moth wings rest behind the body like a beautifully patterned lunar cloak, with silver and indigo bands, subtle moonlike markings and scalloped edges. Long slim but strong limbs, elegant combat posture, approximately three heads high, mature heroic anatomy. Wings remain closed or compactly folded in EVERY pose, never spread wide. No carried weapons or staff. An unmistakable moth guardian, not a butterfly fairy or human woman with wings.
Scene/backdrop: genuinely transparent background with a real alpha channel. No checkerboard, no colored background, no floor, no cast shadows or contact shadows, no labels, grid lines, letters, captions or watermark.
Style: sophisticated hand-painted gouache 2D storybook character, same game family as warm amber desert lanterns and cool teal night shadows. Rich but restrained shapes with subtle brush textures, crisp readable silhouette at about 166 px displayed standing height. Warm amber rim light, cool teal shadows, soft silver/indigo wing patterns. Not a plush toy, not a child, not pixel art, not a 3D render.
Composition: each of the 8 cells is 512 x 512. Keep every antenna tip, wing, toe and fist ENTIRELY inside its own cell with at least 30 px transparent gutters from all cell edges. Ideal standing height 340–360 px including antennae, feet baseline local y=452, body anchor local x=240. All eight poses face RIGHT in the SAME three-quarter side view. Preserve identical character size, identity, clothing, anatomy and markings across poses. Keep raised victory arm below antenna-height ceiling. No automatic scaling up of compact poses. Attack arm cannot cross right boundary. No overlap or intersection between figures.
EXACT pose order from left to right:
TOP ROW: 1 neutral combat idle with protective forearms guarding torso; 2 breathing idle, subtle chest rise and relaxed shoulders; 3 visible attack windup drawing striking forearm back; 4 fully extended forward rightward unarmed strike with a compact follow-through.
BOTTOM ROW: 5 recoiling backward from a hit while still facing right; 6 low evasive crouch leaning backward; 7 victorious upright pose with one forearm raised proudly, antennae and fist safely inside the frame; 8 defeated lying on her side near the baseline with folded wings, same physical body size, no enlargement.
Constraints: exactly eight isolated full-body figures, transparent clean gutters; no glowing circles, dust, magical effects, motion ghosts or duplicate limbs. Keep folded-wing silhouette restrained enough for 4x2 animation slicing. No text anywhere.
```
