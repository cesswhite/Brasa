# Personajes con sprites propios · v3

Siete diseños originales creados con la herramienta nativa `image_gen` e integrados en Brasa. La herramienta no expone el nombre de su modelo interno. Los PNG finales están en esta misma carpeta, conservan el alfa generado y se cargan desde los catálogos del juego.

Sira, Iria, Duna, Kiro, Neris y Taro conservan sus habilidades, estadísticas, identificadores y progreso; ahora cada uno tiene su propia especie y silueta. Ascua tiene una hoja exclusiva de jefe. Nima, Luma y Mugo conservan sus tres hojas originales: el resultado es un plantel de nueve apariencias distintas y un jefe propio.

| Personaje | Diseño | PNG final | Regiones y anclajes |
| --- | --- | --- | --- |
| Sira | Mantis duelista | [sira-v3.png](sira-v3.png) | [sira-v3.json](sira-v3.json) |
| Iria | Rana botánica | [iria-v3.png](iria-v3.png) | [iria-v3.json](iria-v3.json) |
| Duna | Armadillo guardián | [duna-v3.png](duna-v3.png) | [duna-v3.json](duna-v3.json) |
| Kiro | Jabalí de la furia | [kiro-v3.png](kiro-v3.png) | [kiro-v3.json](kiro-v3.json) |
| Neris | Garza sanadora | [neris-v3.png](neris-v3.png) | [neris-v3.json](neris-v3.json) |
| Taro | Tejón contraatacante | [taro-v3.png](taro-v3.png) | [taro-v3.json](taro-v3.json) |
| Ascua | Guardián volcánico · jefe | [ascua-v3.png](ascua-v3.png) | [ascua-v3.json](ascua-v3.json) |

## Animación

Cada atlas contiene ocho poses, ordenadas por filas: reposo, respiración, preparación, golpe, impacto, esquiva, victoria y derrota. Son 56 poses nuevas. El movimiento usa estas imágenes en el mismo controlador de Godot que los personajes originales, con orientación, desplazamiento, sombras y efectos independientes.

Las regiones y anclajes describen las siluetas completas dentro del PNG; no recortan ni retocan el archivo original. Una escala común por personaje evita agrandar las poses agachadas o caídas. El atlas individual se aplica en las fichas, la selección, la arena y la vista previa de Historia.

## Verificación

Los siete atlas finales son PNG RGBA de 1774 × 887. Las regiones conservan cada píxel visible (alfa ≥ 31/255) exactamente una vez. Las pruebas verifican que las diez identidades carguen diez archivos distintos, sin sustituciones silenciosas por los tres originales, y que las 80 poses totales permanezcan dentro de la ventana en siete tamaños.

[Vista del plantel renderizada en Godot](../../reports/personajes-v3.png) · [Informe de pruebas](../../reports/PERSONAJES.md) · [Dimensiones y SHA-256 de los PNG](PERSONAJES-V3.json).

## Prompts exactos

Cada diseño usó una generación nativa independiente. Se conservaron los siete PNG de la primera generación. También se probaron ediciones nativas de encuadre para Kiro, Neris y Taro; sus variantes fueron descartadas porque devolvieron un fondo opaco. Sus prompts quedan documentados, pero no forman parte del arte instalado. No se usó una CLI de generación ni retoque de píxeles mediante scripts.

### Sira · Mantis duelista

Generación:

```text
Use case: stylized-concept
Asset type: production-ready 2D combat animation sprite atlas for a Godot game.
Primary request: ONE landscape 2:1 transparent PNG sprite sheet, ideally 2048 x 1024 pixels, with EXACTLY 8 full-body poses of the SAME character in an invisible regular 4-column by 2-row grid. This is a playable character asset, not a poster or a concept page.
Scene/backdrop: genuinely transparent background with a real alpha channel. Absolutely no colored background, no checkerboard, no floor, no cast shadows, no labels, no grid lines, no letters, no captions, no watermark.
Style/medium: sophisticated hand-painted 2D storybook gouache character, rich but restrained shapes, subtle brush texture, readable silhouette at a final on-screen standing height around 166 px. Desert night-market palette, warm amber rim lighting and cool teal shadows. Adult heroic proportions approximately three heads tall; not a plush toy, not a baby, not pixel art, not a 3D render.
Composition: each cell is ideally 512 x 512. Keep every body part, toe, fist, antenna, accessory and tail entirely within its own cell with at least 28 px transparent clearance from cell borders. Feet on each cell's baseline y=452, approximate standing height 350–370 px, stable body anchor around local x=240. All eight views face RIGHT in the same side/three-quarter perspective. Preserve the same physical character size and consistent face, clothes, anatomy and materials in all poses. No automatic enlarging for compact poses. Clear transparent gutters. No motion ghosts and no duplicate limbs.
Pose order, left-to-right:
TOP ROW: 1 neutral combat idle with guard raised; 2 breathing idle with slight chest rise and lowered shoulders; 3 clear attack windup pulling the striking arm backward; 4 fully extended forward rightward striking attack with visible follow-through and feet still contained.
BOTTOM ROW: 5 hit reaction recoiling backward but facing right; 6 low evasive crouch leaning backward; 7 victorious upright pose raising an arm proudly; 8 defeated lying on side near the same baseline with the SAME physical body size, limbs safely inside the cell.
Do not include any typography. Exactly 8 individually isolated full-body figures.
Subject and identity: SIRA: an elegant upright adult praying-mantis duelist. Pale jade and subtle lilac chitin, narrow amber insect eyes, distinctly triangular mantis head, two delicate short antennae, lean articulated insect torso, short dark obsidian waistcoat. Long segmented forearms ending in folded natural blade-like mantis claws, poised precision duelist stance. Two strong digitigrade insect hind legs; distinctive angular mantis silhouette. The striking arm unfolds into a natural forearm blade for attack. No carried sword or additional weapon. Keep her lean, mature and graceful, a real mantis warrior rather than a humanoid wearing a mask.
```

### Iria · Rana botánica

Generación:

```text
Use case: stylized-concept
Asset type: production-ready 2D combat animation sprite atlas for a Godot game.
Primary request: ONE landscape 2:1 transparent PNG sprite sheet, ideally 2048 x 1024 pixels, with EXACTLY 8 full-body poses of the SAME character in an invisible regular 4-column by 2-row grid. This is a playable character asset, not a poster or a concept page.
Scene/backdrop: genuinely transparent background with a real alpha channel. Absolutely no colored background, no checkerboard, no floor, no cast shadows, no labels, no grid lines, no letters, no captions, no watermark.
Style/medium: sophisticated hand-painted 2D storybook gouache character, rich but restrained shapes, subtle brush texture, readable silhouette at a final on-screen standing height around 166 px. Desert night-market palette, warm amber rim lighting and cool teal shadows. Adult heroic proportions approximately three heads tall; not a plush toy, not a baby, not pixel art, not a 3D render.
Composition: each cell is ideally 512 x 512. Keep every body part, toe, fist, antenna, accessory and tail entirely within its own cell with at least 28 px transparent clearance from cell borders. Feet on each cell's baseline y=452, approximate standing height 350–370 px, stable body anchor around local x=240. All eight views face RIGHT in the same side/three-quarter perspective. Preserve the same physical character size and consistent face, clothes, anatomy and materials in all poses. No automatic enlarging for compact poses. Clear transparent gutters. No motion ghosts and no duplicate limbs.
Pose order, left-to-right:
TOP ROW: 1 neutral combat idle with guard raised; 2 breathing idle with slight chest rise and lowered shoulders; 3 clear attack windup pulling the striking arm backward; 4 fully extended forward rightward striking attack with visible follow-through and feet still contained.
BOTTOM ROW: 5 hit reaction recoiling backward but facing right; 6 low evasive crouch leaning backward; 7 victorious upright pose raising an arm proudly; 8 defeated lying on side near the same baseline with the SAME physical body size, limbs safely inside the cell.
Do not include any typography. Exactly 8 individually isolated full-body figures.
Subject and identity: IRIA: a stout athletic adult poison-frog herbalist fighter. Mottled moss-green and jade amphibian skin, broad expressive frog head with rounded amber eyes, recognizably frog face and feet, powerful athletic bent frog legs. Small worn botanical satchel worn close to the body, simple leaf collar, teal-and-brown woven wrist and waist wraps. Hands raised in an unarmed compact boxer guard, plant ingredients visible only as small leaves tucked into satchel. Rich organic skin and cloth textures, mature capable frog adventurer, not a plush or baby. No potion splash, no particle effects, no floating leaves, no carried staff or weapon.
```

### Duna · Armadillo guardián

Generación:

```text
Use case: stylized-concept
Asset type: production-ready 2D combat animation sprite atlas for a Godot game.
Primary request: ONE landscape 2:1 transparent PNG sprite sheet, ideally 2048 x 1024 pixels, with EXACTLY 8 full-body poses of the SAME character in an invisible regular 4-column by 2-row grid. This is a playable character asset, not a poster or a concept page.
Scene/backdrop: genuinely transparent background with a real alpha channel. Absolutely no colored background, no checkerboard, no floor, no cast shadows, no labels, no grid lines, no letters, no captions, no watermark.
Style/medium: sophisticated hand-painted 2D storybook gouache character, rich but restrained shapes, subtle brush texture, readable silhouette at a final on-screen standing height around 166 px. Desert night-market palette, warm amber rim lighting and cool teal shadows. Adult heroic proportions approximately three heads tall; not a plush toy, not a baby, not pixel art, not a 3D render.
Composition: each cell is ideally 512 x 512. Keep every body part, toe, fist, antenna, accessory and tail entirely within its own cell with at least 28 px transparent clearance from cell borders. Feet on each cell's baseline y=452, approximate standing height 350–370 px, stable body anchor around local x=240. All eight views face RIGHT in the same side/three-quarter perspective. Preserve the same physical character size and consistent face, clothes, anatomy and materials in all poses. No automatic enlarging for compact poses. Clear transparent gutters. No motion ghosts and no duplicate limbs.
Pose order, left-to-right:
TOP ROW: 1 neutral combat idle with guard raised; 2 breathing idle with slight chest rise and lowered shoulders; 3 clear attack windup pulling the striking arm backward; 4 fully extended forward rightward striking attack with visible follow-through and feet still contained.
BOTTOM ROW: 5 hit reaction recoiling backward but facing right; 6 low evasive crouch leaning backward; 7 victorious upright pose raising an arm proudly; 8 defeated lying on side near the same baseline with the SAME physical body size, limbs safely inside the cell.
Do not include any typography. Exactly 8 individually isolated full-body figures.
Subject and identity: DUNA: a sand-colored adult armadillo guardian fighter. Very broad segmented armored back with visibly overlapping natural shell plates, rounded tough snout with small alert eyes and readable armadillo ears, compact muscular body, heavy ochre forearm guards, dark teal fabric waist sash, short plated tail visible safely inside cells, broad clawed armadillo feet. Low strong defensive silhouette, stoic friendly desert protector, about three heads tall. Warm sand hide contrasted with ochre shell edges and dark teal cloth. Unarmed guard and a heavy forearm punch. Distinct armadillo natural anatomy, not a turtle, no separate shield, no helmet, no carried weapon.
```

### Kiro · Jabalí de la furia

Generación:

```text
Use case: stylized-concept
Asset type: production-ready 2D game animation sprite atlas, transparent PNG.
Primary request: Exactly ONE complete atlas, 2048 × 1024 pixels, aspect ratio 2:1, a precise 4-column by 2-row layout of EIGHT poses of the SAME character. Each invisible cell is 512 × 512 pixels. This is an actual game asset, not a presentation sheet.
Scene/backdrop: genuinely transparent alpha background. Every pixel outside the character cutouts is transparent. No checkerboard, no opaque white or colored background, no floor, no ground line, no drop shadow, no framing, no dividers, no text.
Style/medium: polished hand-painted 2D storybook / gouache adventure-game illustration, warm amber rim light and cool teal shadows inside the character. Readable textured materials and confident shapes at a displayed character height of 166 pixels. Adult heroic proportions, about three heads tall; not a baby or plush toy. Not 3D, not pixel art.
Composition: all eight characters face RIGHT, seen in the same full-body side-three-quarter camera. Same physical body size, costume, identity and anchor in every cell. Standing body height roughly 360 pixels, standing baseline y=452 in each cell (global baselines 452 and 964); torso/hips center around local x=240. Keep every body part at least 24–32 pixels from every cell edge; no pose overlaps another cell. Full fists, feet, head and accessories inside their own cell. Do not upscale the fallen pose: lying body is the same body turned horizontally near the standing baseline.
Pose order, strictly left to right:
TOP ROW: (1) IDLE: calm ready guard, grounded feet; (2) BREATHING: same guard with subtle raised chest and slight shoulders change; (3) WINDUP: readable fist/arm pulled back, weight braced, preparing a strike rightward; (4) PUNCH: front fist/arm forcefully extended to the RIGHT, one clear physical strike, no visual effect trail.
BOTTOM ROW: (5) HIT: recoiling from an impact, shoulders and face leaning slightly LEFT while still facing RIGHT; (6) DODGE: torso leaning back/left and lower, arms protecting, feet remain close to normal baseline; (7) VICTORY: grounded celebratory raised arm, same body scale; (8) DEFEAT: defeated lying on their side near the baseline, alive/exhausted, body horizontally extended, facing right, no injuries.
Constraints: exactly eight separate poses, one per cell, no duplicate ninth sprite, no hidden background, no motion streaks, no permanent magic effects, no extra characters, no weapons, no writing, no UI.
Subject: KIRO, a distinct anthropomorphic russet WILD BOAR pugilist. A visibly boar-like broad blunt snout, two short ivory tusks visible at the sides of the mouth, rust-colored bristle crest, small alert adult eyes, broad strong shoulders and powerful forearms. Red cloth waist sash, dark leather travel trousers, copper knuckle guards, bare sturdy cloven feet. Rough russet fur and textured copper. Expressive determined brow. This is a boar fighter, not a cat, fox, bear, human or goblin. No flames.
```

Prueba de encuadre descartada (se conserva la generación anterior con alfa):

```text
Use case: identity-preserve
Asset type: corrected transparent game sprite atlas.
Edit target: the supplied KIRO atlas. Preserve this exact character, costume, materials, face, painterly rendering and all eight existing actions. Change ONLY the composition and physical scale within the eight cells.
Required correction: the figures currently fill too much of each cell, and victory/defeat leak into neighboring cells. Make ALL EIGHT figures uniformly about 25% SMALLER than in the input, while retaining exactly the same physical body proportions between poses. Keep a 4-column × 2-row layout on the same 2:1 landscape canvas, ideally the input's 1774 × 887 size. Each invisible cell occupies exactly one quarter of the image width and half the height.
Within EVERY cell, ground contact baseline is at 88% of cell height, normal standing head-to-foot body height is only 70% of cell height. Center the body near 48% of cell width. Keep at least 8% of the cell dimension as completely empty transparent margin on ALL FOUR sides of EVERY pose, including the raised victory hand and both ends of the lying defeat pose. The defeat figure is the same physical-size character lying horizontally; do not enlarge it to fill the cell. No subject pixel may touch or cross a cell boundary. There must be a visibly wide empty horizontal gutter between rows and empty vertical gutters between all columns.
Pose order stays unchanged: top row idle, breathing, windup, punch right; bottom row hit recoil, backward dodge, victory with raised arm, lying defeat. All face right. Do not remove or duplicate a pose. Keep the punch arm fully visible within its cell. Keep the raised victory fist or wing wholly in the bottom row, below the horizontal midpoint. The lying figure must lie entirely in the bottom-right cell.
The background must remain genuine PNG ALPHA transparency, not painted black, white or checkerboard. No floor, shadows under feet, grid lines, framing, labels, new props or effects. The only permitted changes are uniform downscaling and safe repositioning of the existing eight complete figures.
```

### Neris · Garza sanadora

Generación:

```text
Use case: stylized-concept
Asset type: production-ready 2D game animation sprite atlas, transparent PNG.
Primary request: Exactly ONE complete atlas, 2048 × 1024 pixels, aspect ratio 2:1, a precise 4-column by 2-row layout of EIGHT poses of the SAME character. Each invisible cell is 512 × 512 pixels. This is an actual game asset, not a presentation sheet.
Scene/backdrop: genuinely transparent alpha background. Every pixel outside the character cutouts is transparent. No checkerboard, no opaque white or colored background, no floor, no ground line, no drop shadow, no framing, no dividers, no text.
Style/medium: polished hand-painted 2D storybook / gouache adventure-game illustration, warm amber rim light and cool teal shadows inside the character. Readable textured materials and confident shapes at a displayed character height of 166 pixels. Adult heroic proportions, about three heads tall; not a baby or plush toy. Not 3D, not pixel art.
Composition: all eight characters face RIGHT, seen in the same full-body side-three-quarter camera. Same physical body size, costume, identity and anchor in every cell. Standing body height roughly 360 pixels, standing baseline y=452 in each cell (global baselines 452 and 964); torso/hips center around local x=240. Keep every body part at least 24–32 pixels from every cell edge; no pose overlaps another cell. Full fists, feet, head and accessories inside their own cell. Do not upscale the fallen pose: lying body is the same body turned horizontally near the standing baseline.
Pose order, strictly left to right:
TOP ROW: (1) IDLE: calm ready guard, grounded feet; (2) BREATHING: same guard with subtle raised chest and slight shoulders change; (3) WINDUP: readable fist/arm pulled back, weight braced, preparing a strike rightward; (4) PUNCH: front fist/arm forcefully extended to the RIGHT, one clear physical strike, no visual effect trail.
BOTTOM ROW: (5) HIT: recoiling from an impact, shoulders and face leaning slightly LEFT while still facing RIGHT; (6) DODGE: torso leaning back/left and lower, arms protecting, feet remain close to normal baseline; (7) VICTORY: grounded celebratory raised arm, same body scale; (8) DEFEAT: defeated lying on their side near the baseline, alive/exhausted, body horizontally extended, facing right, no injuries.
Constraints: exactly eight separate poses, one per cell, no duplicate ninth sprite, no hidden background, no motion streaks, no permanent magic effects, no extra characters, no weapons, no writing, no UI.
Subject: NERIS, a distinct anthropomorphic WHITE HERON martial healer. Elegant long gently curved white neck, slender straight HERON BEAK, small alert adult bird eyes, white feathered head with blue crest, blue-tipped wing feathers. Cobalt-and-cream short martial tunic, coral cloth waist sash, natural bird legs and long bird feet. Wings fold forward like guarding arms and the wing forearms perform the eight martial poses, with a closed feathered wing tip striking right in the punch frame. Lean athletic mature body, poised and calm, clearly bird anatomy rather than human arms pasted on a bird. White plumage must remain opaque while the surrounding canvas has true alpha transparency. Not a duck, penguin, owl, baby chick or axolotl.
```

Prueba de encuadre descartada (se conserva la generación anterior con alfa):

```text
Use case: identity-preserve
Asset type: corrected transparent game sprite atlas.
Edit target: the supplied NERIS atlas. Preserve this exact character, costume, materials, face, painterly rendering and all eight existing actions. Change ONLY the composition and physical scale within the eight cells.
Required correction: the figures currently fill too much of each cell, and victory/defeat leak into neighboring cells. Make ALL EIGHT figures uniformly about 25% SMALLER than in the input, while retaining exactly the same physical body proportions between poses. Keep a 4-column × 2-row layout on the same 2:1 landscape canvas, ideally the input's 1774 × 887 size. Each invisible cell occupies exactly one quarter of the image width and half the height.
Within EVERY cell, ground contact baseline is at 88% of cell height, normal standing head-to-foot body height is only 70% of cell height. Center the body near 48% of cell width. Keep at least 8% of the cell dimension as completely empty transparent margin on ALL FOUR sides of EVERY pose, including the raised victory hand and both ends of the lying defeat pose. The defeat figure is the same physical-size character lying horizontally; do not enlarge it to fill the cell. No subject pixel may touch or cross a cell boundary. There must be a visibly wide empty horizontal gutter between rows and empty vertical gutters between all columns.
Pose order stays unchanged: top row idle, breathing, windup, punch right; bottom row hit recoil, backward dodge, victory with raised arm, lying defeat. All face right. Do not remove or duplicate a pose. Keep the punch arm fully visible within its cell. Keep the raised victory fist or wing wholly in the bottom row, below the horizontal midpoint. The lying figure must lie entirely in the bottom-right cell.
The background must remain genuine PNG ALPHA transparency, not painted black, white or checkerboard. No floor, shadows under feet, grid lines, framing, labels, new props or effects. The only permitted changes are uniform downscaling and safe repositioning of the existing eight complete figures.
```

### Taro · Tejón contraatacante

Generación:

```text
Use case: stylized-concept
Asset type: production-ready 2D game animation sprite atlas, transparent PNG.
Primary request: Exactly ONE complete atlas, 2048 × 1024 pixels, aspect ratio 2:1, a precise 4-column by 2-row layout of EIGHT poses of the SAME character. Each invisible cell is 512 × 512 pixels. This is an actual game asset, not a presentation sheet.
Scene/backdrop: genuinely transparent alpha background. Every pixel outside the character cutouts is transparent. No checkerboard, no opaque white or colored background, no floor, no ground line, no drop shadow, no framing, no dividers, no text.
Style/medium: polished hand-painted 2D storybook / gouache adventure-game illustration, warm amber rim light and cool teal shadows inside the character. Readable textured materials and confident shapes at a displayed character height of 166 pixels. Adult heroic proportions, about three heads tall; not a baby or plush toy. Not 3D, not pixel art.
Composition: all eight characters face RIGHT, seen in the same full-body side-three-quarter camera. Same physical body size, costume, identity and anchor in every cell. Standing body height roughly 360 pixels, standing baseline y=452 in each cell (global baselines 452 and 964); torso/hips center around local x=240. Keep every body part at least 24–32 pixels from every cell edge; no pose overlaps another cell. Full fists, feet, head and accessories inside their own cell. Do not upscale the fallen pose: lying body is the same body turned horizontally near the standing baseline.
Pose order, strictly left to right:
TOP ROW: (1) IDLE: calm ready guard, grounded feet; (2) BREATHING: same guard with subtle raised chest and slight shoulders change; (3) WINDUP: readable fist/arm pulled back, weight braced, preparing a strike rightward; (4) PUNCH: front fist/arm forcefully extended to the RIGHT, one clear physical strike, no visual effect trail.
BOTTOM ROW: (5) HIT: recoiling from an impact, shoulders and face leaning slightly LEFT while still facing RIGHT; (6) DODGE: torso leaning back/left and lower, arms protecting, feet remain close to normal baseline; (7) VICTORY: grounded celebratory raised arm, same body scale; (8) DEFEAT: defeated lying on their side near the baseline, alive/exhausted, body horizontally extended, facing right, no injuries.
Constraints: exactly eight separate poses, one per cell, no duplicate ninth sprite, no hidden background, no motion streaks, no permanent magic effects, no extra characters, no weapons, no writing, no UI.
Subject: TARO, a distinct anthropomorphic BLACK-AND-WHITE BADGER counterfighter. Strong broad black-and-white striped badger cheek mask, tapered badger muzzle, small rounded ears, narrow attentive adult eyes, a stocky muscular torso and powerful forearms. Charcoal work vest, jade bead wrist wraps, brown cloth waist sash, bare clawed feet. Short coarse black, white and gray fur, textured cloth, small jade beads. Patient grounded defensive expression, a mature tough badger with a clear low powerful silhouette. No hat and no weapons. Not a panda, raccoon, bear, cat, baby or plush toy.
```

Prueba de encuadre descartada (se conserva la generación anterior con alfa):

```text
Use case: identity-preserve
Asset type: corrected transparent game sprite atlas.
Edit target: the supplied TARO atlas. Preserve this exact character, costume, materials, face, painterly rendering and all eight existing actions. Change ONLY the composition and physical scale within the eight cells.
Required correction: the figures currently fill too much of each cell, and victory/defeat leak into neighboring cells. Make ALL EIGHT figures uniformly about 25% SMALLER than in the input, while retaining exactly the same physical body proportions between poses. Keep a 4-column × 2-row layout on the same 2:1 landscape canvas, ideally the input's 1774 × 887 size. Each invisible cell occupies exactly one quarter of the image width and half the height.
Within EVERY cell, ground contact baseline is at 88% of cell height, normal standing head-to-foot body height is only 70% of cell height. Center the body near 48% of cell width. Keep at least 8% of the cell dimension as completely empty transparent margin on ALL FOUR sides of EVERY pose, including the raised victory hand and both ends of the lying defeat pose. The defeat figure is the same physical-size character lying horizontally; do not enlarge it to fill the cell. No subject pixel may touch or cross a cell boundary. There must be a visibly wide empty horizontal gutter between rows and empty vertical gutters between all columns.
Pose order stays unchanged: top row idle, breathing, windup, punch right; bottom row hit recoil, backward dodge, victory with raised arm, lying defeat. All face right. Do not remove or duplicate a pose. Keep the punch arm fully visible within its cell. Keep the raised victory fist or wing wholly in the bottom row, below the horizontal midpoint. The lying figure must lie entirely in the bottom-right cell.
The background must remain genuine PNG ALPHA transparency, not painted black, white or checkerboard. No floor, shadows under feet, grid lines, framing, labels, new props or effects. The only permitted changes are uniform downscaling and safe repositioning of the existing eight complete figures.
```

### Ascua · Guardián volcánico · jefe

Generación:

```text
Use case: stylized-concept.
Asset type: production 2D game sprite sheet, ONE character, exactly EIGHT poses in a strict 4-column by 2-row grid, landscape 2:1 canvas (ideally 2048x1024).
Create ASCUA, an original volcanic salamander-drake martial guardian and final boss for a hand-painted desert night-market fantasy fighting game. Ascua has a distinctive broad compact heroic body, an expressive reptilian face with a blunt snout, swept-back curved ramlike horns forming a crown silhouette, charcoal OBSIDIAN armored scales with restrained glowing amber seams, a bright amber lantern-shaped core set in the chest, huge dark brass gauntlets, clawed reptile feet, a thick tapering dragon tail, a weathered short golden mantle and black waist armor. The face is stern and noble. NOT a stone golem, NOT a cat, NOT an axolotl. No weapons. No floating flames or detached effects. About three heads tall, adult heroic anatomy, not a plush or baby character.
Beautiful painterly 2D indie-game gouache art, dimensional materials, crisp readable silhouettes and selective dark contours, refined amber rim lighting with teal shadows, high detail that stays legible at 166px standing height. Not pixel art, not vector shapes, not a 3D render. Consistent same identity, proportions, clothing, lighting, physical scale and camera in every pose.
CRITICAL OUTPUT: genuine fully TRANSPARENT background and alpha channel outside every silhouette. No checkerboard drawing, no white/black/colored backdrop, no ground or cast shadows, no captions or grid lines, no border, no watermark.
Strict equal 512x512 logical cells if canvas2048x1024. Each character completely isolated within its cell with at least32px transparent gutters. Ground baseline y452 within eachcell and planted-body center x240. Idle standing character including horns about350px tall. SAME PHYSICAL SCALE across allposes; never enlarge the crouched or fallen character. Camera side-three-quarter, facing RIGHT in every standingpose; player can mirror these in game.
Pose order reading left to right:
TOP ROW 1: combat idle, feet apart, raised guarded fists, stern alert gaze to right.
TOP ROW 2: same idle stance with subtle breath, slightly lowered shoulders and near-blink, minimal shift.
TOP ROW 3: obvious punch anticipation, torso twists back LEFT and front fist retracts, right opponent direction retained.
TOP ROW 4: committed punch reaching RIGHT, fully extended gauntlet, back hand guards, feet remain on baseline. Entirefist inside cell.
BOTTOM ROW 1: hit reaction recoiling LEFT, arms open slightly and face winces, no drawn impacteffects.
BOTTOM ROW 2: clear low dodge, knees bent and torso leaning back, guarded arms, lower silhouette, feet on samebaseline.
BOTTOM ROW 3: victory with one gauntlet raised high overhead and proud expression, feet planted, horn/hand fullywithin cell.
BOTTOM ROW 4: defeated lying on side on baseline, head left and legs/tail right, eyes closed, exhausted unharmed, no gore.
Produce a clean usable animation atlas, not a character presentation poster. Exactly8 sprites, no overlapping cells or isolated ornamental objects.
```
