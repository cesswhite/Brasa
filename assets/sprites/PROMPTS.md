# Hojas de sprites ilustrados

Estas son las tres hojas originales. Los siete diseños adicionales están en [PERSONAJES-V3.md](PERSONAJES-V3.md).

Se crearon para Brasa con la herramienta integrada `image_gen`, sin CLI ni API externa. Cada PNG original tiene 1774 × 887 píxeles y un canal alfa real. Los archivos originales se conservan sin recortar; Godot usa regiones de atlas y metadatos de anclaje para mostrarlos.

| Personaje | Hoja final |
| --- | --- |
| Nima · Lince | `lince-v2.png` |
| Luma · Ajolote | `ajolote-v2.png` |
| Mugo · Gólem | `golem-v2.png` |

Las ocho poses se leen por filas: reposo, respiración, preparación de ataque, puñetazo, reacción al golpe, esquiva, victoria y derrota. El movimiento combina estas imágenes con desplazamientos y transiciones de Godot; las sombras y destellos se dibujan por separado. El nombre del modelo interno no se expone en la herramienta.

## Prompts de las hojas finales

### Lince

```text
Use case: stylized-concept.
Asset type: PRODUCTION TRANSPARENT PNG SPRITE SHEET for a 2D side-view fighting game. This is a game asset atlas, not a concept-art poster.
Create EXACTLY 8 full-body sprites of ONE identical original anthropomorphic desert lynx fighter, arranged in a STRICT 4 COLUMNS x 2 ROWS equal-cell grid. Landscape canvas 2:1 aspect ratio, preferably 2048 x 1024 (each cell 512 x 512). Genuine fully transparent alpha background everywhere outside the character silhouettes. No painted backdrop, no white or solid background, NO CHECKERBOARD pattern, no ground or shadows, no text, no grid lines, no labels, no effects crossing cells.
Character: Nima, a nimble desert lynx brawler. Athletic compact 3-heads-tall proportions, strong readable silhouette, pointed ears with long black tufts, tawny ochre fur with subtle dark spots, cream muzzle and chest, sharp amber eyes and expressive eyebrows, confident scrappy demeanor. A weathered short dark-teal sleeveless fighter tunic, layered leather belt with a small amber clasp, terracotta red scarf flowing behind, wrapped forearms with robust leather knuckle guards, dark cropped trousers, worn soft leather boots, a short fluffy lynx tail. Barehanded martial fighter, no weapons, no hats.
ART STYLE: gorgeous hand-painted 2D indie game character sprites, sophisticated storybook gouache with clean crisp shapes, subtle material textures and painted highlights, selective dark contours, dimensional expressive face, warm amber rim-light on the left and restrained teal shadow. High quality animation concept art refined into actual usable sprites. Not pixel art, not 3D, not vector geometric stick figures, not baby/chibi/plush proportions. Match an atmospheric desert night market with blue-teal shadows and warm terracotta sand. Keep details bold enough to read when character is 170 pixels high.
All 8 instances must be unmistakably the same character, same clothing, same head proportions, same camera angle, same LIGHTING, and EXACT SAME PHYSICAL SCALE. Side-view camera, three-quarter profile facing RIGHT, viewer sees front/side of face, eyes look right toward an opponent. Every sprite is fully contained inside its own cell with >=32px clear transparent margins. Character standing height approximately 370px, feet baseline about 452px within each cell; same planted-foot position/anchor around x240 in each cell. Arms can extend right within that cell; never overlap adjacent cells. Do NOT center each pose independently: preserve the same body anchor and same proportions across all frames. Duck and defeat naturally have less height; do not enlarge them.
POSE ORDER reading left to right:
TOP ROW cell1: neutral combat idle, feet apart, both fists raised near torso, alert confident expression.
TOP ROW cell2: alternate idle breathing frame, same exact stance, shoulders lowered slightly, scarf and ears subtly shift, slight blink.
TOP ROW cell3: clear attack anticipation: torso leans back slightly, front fist pulled back, knees compressed.
TOP ROW cell4: powerful extended straight punch toward RIGHT at shoulder height, front fist reaching right, torso following, back arm guarding, feet still on the same baseline.
BOTTOM ROW cell1: hit reaction: recoiling backward to LEFT, face winces, arms partially open, impact felt, NO drawn impact star or effects.
BOTTOM ROW cell2: dodge: crouch low with bent knees, torso leaning back left, guarded face, same feet baseline, visibly shorter silhouette.
BOTTOM ROW cell3: victory: planted feet, one fist raised high, proud smile, scarf flutter, no jump and no props.
BOTTOM ROW cell4: defeated: lying on side on the baseline, head left, legs right, eyes closed, visibly exhausted but harmless, no gore.
Deliver a pristine transparent game sprite atlas with eight isolated poses. Prioritize consistent character identity, the exact grid and usable transparent silhouettes over decorative presentation.
```

### Ajolote

```text
Use case: stylized-concept.
Asset type: PRODUCTION TRANSPARENT PNG SPRITE SHEET for a 2D side-view fighting game. This is a game asset atlas, not a concept-art poster.
Create EXACTLY 8 full-body sprites of ONE identical original anthropomorphic axolotl fighter, arranged in a STRICT 4 COLUMNS x 2 ROWS equal-cell grid. Landscape canvas 2:1 aspect ratio, preferably 2048 x 1024 (each cell 512 x 512). Genuine fully transparent alpha background everywhere outside the character silhouettes. No painted backdrop, no white or solid background, NO CHECKERBOARD pattern, no ground or shadows, no text, no grid lines, no labels, no effects crossing cells.
Character: Luma, a graceful athletic anthropomorphic AXOLOTL martial fighter. Compact 3-heads-tall proportions, strong readable silhouette, smooth peach-pink skin, round salamander head, SIX elegant branching coral-red external gills (three on each side of head), expressive focused burgundy eyes, small confident smile, long tapering salamander tail. A weathered short dark-teal sleeveless martial vest with warm brass edging, layered leather belt with amber round clasp, ochre waist sash flowing behind, cream wrapped forearms with protective knuckle guards, dark cropped loose trousers, bare broad salamander feet. Barehanded fighter, no weapons, no hats, no cat features, no fur, no pointy mammal ears. Clearly an axolotl, entirely original character, adult/young-adult heroic proportions rather than a plush toy.
ART STYLE: gorgeous hand-painted 2D indie game character sprites, sophisticated storybook gouache with clean crisp shapes, subtle material textures and painted highlights, selective dark contours, dimensional expressive face, warm amber rim-light on the left and restrained teal shadow. High quality animation concept art refined into actual usable sprites. Not pixel art, not 3D, not vector geometric stick figures, not baby/chibi/plush proportions. Match an atmospheric desert night market with blue-teal shadows and warm terracotta sand. Keep details bold enough to read when character is 170 pixels high.
All 8 instances must be unmistakably the same character, same clothing, same head proportions, same camera angle, same LIGHTING, and EXACT SAME PHYSICAL SCALE. Side-view camera, three-quarter profile facing RIGHT, viewer sees front/side of face, eyes look right toward an opponent. Every sprite is fully contained inside its own cell with >=32px clear transparent margins. Character standing height approximately 370px, feet baseline about 452px within each cell; same planted-foot position/anchor around x240 in each cell. Arms can extend right within that cell; never overlap adjacent cells. Do NOT center each pose independently: preserve the same body anchor and same proportions across all frames. Duck and defeat naturally have less height; do not enlarge them.
POSE ORDER reading left to right:
TOP ROW cell1: neutral combat idle, feet apart, both fists raised near torso, alert confident expression.
TOP ROW cell2: alternate idle breathing frame, same exact stance, shoulders lowered slightly, scarf and ears subtly shift, slight blink.
TOP ROW cell3: clear attack anticipation: torso leans back slightly, front fist pulled back, knees compressed.
TOP ROW cell4: powerful extended straight punch toward RIGHT at shoulder height, front fist reaching right, torso following, back arm guarding, feet still on the same baseline.
BOTTOM ROW cell1: hit reaction: recoiling backward to LEFT, face winces, arms partially open, impact felt, NO drawn impact star or effects.
BOTTOM ROW cell2: dodge: crouch low with bent knees, torso leaning back left, guarded face, same feet baseline, visibly shorter silhouette.
BOTTOM ROW cell3: victory: planted feet, one fist raised high, proud smile, scarf flutter, no jump and no props.
BOTTOM ROW cell4: defeated: lying on side on the baseline, head left, legs right, eyes closed, visibly exhausted but harmless, no gore.
Deliver a pristine transparent game sprite atlas with eight isolated poses. Prioritize consistent character identity, the exact grid and usable transparent silhouettes over decorative presentation.
```

### Gólem

```text
Use case: stylized-concept.
Asset type: PRODUCTION TRANSPARENT PNG SPRITE SHEET for a 2D side-view fighting game. This is a game asset atlas, not a concept-art poster.
Create EXACTLY 8 full-body sprites of ONE identical original anthropomorphic jade stone golem fighter, arranged in a STRICT 4 COLUMNS x 2 ROWS equal-cell grid. Landscape canvas 2:1 aspect ratio, preferably 2048 x 1024 (each cell 512 x 512). Genuine fully transparent alpha background everywhere outside the character silhouettes. No painted backdrop, no white or solid background, NO CHECKERBOARD pattern, no ground or shadows, no text, no grid lines, no labels, no effects crossing cells.
Character: Mugo, a heavy original living JADE STONE GOLEM brawler. Compact heroic roughly 2.8-heads-tall proportions, very broad shoulders, sturdy short legs, powerful huge stone forearms and fists, strong readable silhouette. Body made of beautifully weathered desaturated jade-green and sage stone slabs with rounded/chipped irregular edges, subtle cracks and carved organic ornamental details, small restrained moss patches. A slightly squared but expressive stone face with a strong brow, narrow warm amber eyes and a small confident carved smile, NO hair or ears. An amber and turquoise diamond-shaped gemstone embedded in the chest inside a simple bronze mount, tiny internal glow ONLY inside the stone; no bright external aura. A weathered terracotta-red shoulder cowl draped around the neck and behind one shoulder, broad brown leather belt with bronze buckle and three short dark-teal fabric waist panels, leather wraps at wrists. Rock feet and stone knuckles exposed. Barehanded guardian, no weapons, no hat, no animal features, no robots or machinery, no skin or fur. He is an expressive ancient magical stone guardian rather than a baby, cute toy or round geometric snowman. All poses retain the same detailed stone anatomy and outfit.
ART STYLE: gorgeous hand-painted 2D indie game character sprites, sophisticated storybook gouache with clean crisp shapes, subtle material textures and painted highlights, selective dark contours, dimensional expressive face, warm amber rim-light on the left and restrained teal shadow. High quality animation concept art refined into actual usable sprites. Not pixel art, not 3D, not vector geometric stick figures, not baby/chibi/plush proportions. Match an atmospheric desert night market with blue-teal shadows and warm terracotta sand. Keep details bold enough to read when character is 170 pixels high.
All 8 instances must be unmistakably the same character, same clothing, same head proportions, same camera angle, same LIGHTING, and EXACT SAME PHYSICAL SCALE. Side-view camera, three-quarter profile facing RIGHT, viewer sees front/side of face, eyes look right toward an opponent. Every sprite is fully contained inside its own cell with >=32px clear transparent margins. Character standing height approximately 370px, feet baseline about 452px within each cell; same planted-foot position/anchor around x240 in each cell. Arms can extend right within that cell; never overlap adjacent cells. Do NOT center each pose independently: preserve the same body anchor and same proportions across all frames. Duck and defeat naturally have less height; do not enlarge them.
POSE ORDER reading left to right:
TOP ROW cell1: neutral combat idle, feet apart, both fists raised near torso, alert confident expression.
TOP ROW cell2: alternate idle breathing frame, same exact stance, shoulders lowered slightly, shoulder cowl subtly shifts, slight blink.
TOP ROW cell3: clear attack anticipation: torso leans back slightly, front fist pulled back, knees compressed.
TOP ROW cell4: powerful extended straight punch toward RIGHT at shoulder height, front fist reaching right, torso following, back arm guarding, feet still on the same baseline.
BOTTOM ROW cell1: hit reaction: recoiling backward to LEFT, face winces, arms partially open, impact felt, NO drawn impact star or effects.
BOTTOM ROW cell2: dodge: crouch low with bent knees, torso leaning back left, guarded face, same feet baseline, visibly shorter silhouette.
BOTTOM ROW cell3: victory: planted feet, one fist raised high, proud smile, shoulder cowl flutter, no jump and no props.
BOTTOM ROW cell4: defeated: lying on side on the baseline, head left, legs right, eyes closed, visibly exhausted but harmless, no gore.
Deliver a pristine transparent game sprite atlas with eight isolated poses. Prioritize consistent character identity, the exact grid and usable transparent silhouettes over decorative presentation.
```
