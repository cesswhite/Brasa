# Mexican fauna prompts

Generations and corrections made with the integrated image_gen tool. Discarded iterations are also preserved; [manifest](fauna-mexicana-origen.json) identifies definitive sources.

## balam-alpha-prompt

```text
Use case: background-extraction. Produce a transparent-background PNG cutout of this exact complete eight-pose jaguar sprite atlas. The current white and light gray checkerboard is an unwanted opaque painted background. REMOVE ALL of that checkerboard from the entire image and replace it with ACTUAL transparent alpha pixels, including spaces around the characters, between legs and arms, around tails and inside curved tails. The deliverable MUST be RGBA with alpha=0 in all background areas, not RGB, not another visible checkerboard, not white, black or gray backdrop. Retain ONLY the eight jaguar fighter silhouettes, unchanged. Preserve their positions, dimensions, poses, physical scale, hand shapes, clothing, fine fur edges and colors. Keep the compact bent-arm victory pose already shown in bottom row third cell; do not raise that fist farther. Preserve canvas 1774x887 if possible and all eight separate sprite figures. No drawn grid, no letters, no shadow, no ground, no smoke, no glow. This is transparent background removal only.
```

## balam-edit-prompt

```text
Use case: precise-object-edit. This existing transparent 4-column by 2-row game sprite atlas is the exact edit target. Change ONLY the raised arm and raised fist of the VICTORY character, the THIRD sprite in the BOTTOM row. Its raised fist currently reaches upward into the top row, starting around source x1130,y391, and would be cut by atlas extraction. Bend that raised elbow and lower the fist to a confident victory pose beside and just above its head, entirely below source y450, with highest finger near y459. Keep the fist raised visibly but compact. Make all opaque pixels of this bottom victory pose lie below y450. Preserve the victory torso, head, feet, tail and physical scale; feet stay around y858. Preserve the entire rest of the image, all seven other poses, every other character's anatomy, shapes, tails, clothing, location, spacing, scale and colors exactly. Preserve 1774x887 canvas dimensions if possible. Do not move the top windup pose, whose feet end near y424. Leave a transparent horizontal gap of at least20pixels between the top windup sprite and this bottom victory sprite. Background remains genuinely transparent alpha, with no ground, shadows, glow, text or checkerboard. This is a targeted atlas overlap correction only.
```

## balam-final-prompt

```text
Use case: stylized-concept.
Asset type: production sprite atlas for the original 2D fighting game Brasa, Liga de los Faroles.
Create ONE complete PNG atlas, landscape 2:1, preferably 2048 by 1024, with a genuinely transparent alpha background. Exactly EIGHT separate full-body drawings arranged in four equal columns and two equal rows, read left to right. There are no drawn grid lines. Every pose faces RIGHT in a consistent side-three-quarter view, including the defeated pose.
Layout is essential: each logical cell is 512 by 512, each character fully contained in its cell with generous transparent margins and at least 30 pixels of separation. Center the standing body's hips at local x=245, feet baseline at local y=460, normal head height around y=100; the physical character remains the same scale in all eight poses. Stretched punching fist and tail never touch any cell edge. The victory pose must use a compact flexed arm with fist raised only to cheek/shoulder height; NEVER raise it above the head. The defeated body lies close to the same floor baseline and is not enlarged. Exactly one character per cell, no extra limbs, no duplicated or overlapping characters.
Pose order, exactly:
TOP ROW: (1) idle ready guard, (2) subtle breathing guard with relaxed shoulders, (3) visible punch windup with rear fist drawn back, (4) decisive straight punch fully extending to the right.
BOTTOM ROW: (5) hit reaction leaning backward yet looking right, (6) low evasive crouch/dodge, (7) proud compact victory with fist clenched beside the cheek at shoulder height, elbow bent, head looking right, nothing raised above the head, (8) defeated lying on side, head toward the RIGHT, eyes closed, non-graphic.
Style: polished hand-painted 2D gouache fantasy game illustration, mature heroic anthropomorphic animal about three heads tall, coherent anatomy and materials, subtle brush texture, dark clean readable contours, warm amber rim light and restrained teal shadows, textured matte fur and cloth. Warm dignified desert-night martial fighter, expressive adult face, not a cute toy, not 3D, not pixel art, no glossy plastic.
Transparent backdrop only: absolutely no environment, ground planes, cast shadows, floor shadows, smoke, clouds, glows, circles, aura, scenery, text, numbers, labels, border, watermark, or drawn checkerboard. No weapons or props floating separately. Preserve actual alpha; all empty space must be transparent.
Subject identity: BALAM, a broad and powerfully built golden jaguar martial guardian. Warm ochre-gold coat with clearly organized dark jaguar rosettes containing small central spots, creamy chin and chest, broad square feline muzzle, compact rounded black-backed ears WITHOUT lynx tufts, large forearms and strong thighs. A thick muscular spotted jaguar tail bends compactly behind him within each cell. Resolute amber eyes, confident adult face. Outfit: jade-green woven waist sash, short dark charcoal travel trousers, polished obsidian wrist guards with restrained green seams, plain cloth ankle wraps, bare feline paws. These clothes stay identical in all poses. Gold spotted fur remains prominent over chest, face and arms. He is visibly a jaguar, not a lynx, tiger, leopard cub, or a recolor of another fighter. Balam's silhouette should read as weighty, grounded and protective. The eight drawings are one consistent individual.
CRITICAL EXTRACTION REQUIREMENT: a broad empty TRANSPARENT HORIZONTAL GUTTER must completely separate the two rows. No part of any lower-row figure may reach into the upper row. The bottom victory silhouette must start at its head, aligned in height with the hit-reaction figure next to it. Make victory a confident biceps flex beside the face, not an overhead arm. Keep wide transparent gutters and all eight entire figures as cleanly isolated sprites. TRUE TRANSPARENT BACKGROUND PNG.
```

## balam-prompt

```text
Use case: stylized-concept.
Asset type: production sprite atlas for the original 2D fighting game Brasa, Liga de los Faroles.
Create ONE complete PNG atlas, landscape 2:1, preferably 2048 by 1024, with a genuinely transparent alpha background. Exactly EIGHT separate full-body drawings arranged in four equal columns and two equal rows, read left to right. There are no drawn grid lines. Every pose faces RIGHT in a consistent side-three-quarter view, including the defeated pose.
Layout is essential: each logical cell is 512 by 512, each character fully contained in its cell with generous transparent margins and at least 30 pixels of separation. Center the standing body's hips at local x=245, feet baseline at local y=460, normal head height around y=100; the physical character remains the same scale in all eight poses. Raised fist fits below y=35; stretched punching fist and tail never touch any cell edge. The defeated body lies close to the same floor baseline and is not enlarged. Exactly one character per cell, no extra limbs, no duplicated or overlapping characters.
Pose order, exactly:
TOP ROW: (1) idle ready guard, (2) subtle breathing guard with relaxed shoulders, (3) visible punch windup with rear fist drawn back, (4) decisive straight punch fully extending to the right.
BOTTOM ROW: (5) hit reaction leaning backward yet looking right, (6) low evasive crouch/dodge, (7) proud victory with one fist raised and face looking right, (8) defeated lying on side, head toward the RIGHT, eyes closed, non-graphic.
Style: polished hand-painted 2D gouache fantasy game illustration, mature heroic anthropomorphic animal about three heads tall, coherent anatomy and materials, subtle brush texture, dark clean readable contours, warm amber rim light and restrained teal shadows, textured matte fur and cloth. Warm dignified desert-night martial fighter, expressive adult face, not a cute toy, not 3D, not pixel art, no glossy plastic.
Transparent backdrop only: absolutely no environment, ground planes, cast shadows, floor shadows, smoke, clouds, glows, circles, aura, scenery, text, numbers, labels, border, watermark, or drawn checkerboard. No weapons or props floating separately. Preserve actual alpha; all empty space must be transparent.
Subject identity: BALAM, a broad and powerfully built golden jaguar martial guardian. Warm ochre-gold coat with clearly organized dark jaguar rosettes containing small central spots, creamy chin and chest, broad square feline muzzle, compact rounded black-backed ears WITHOUT lynx tufts, large forearms and strong thighs. A thick muscular spotted jaguar tail bends compactly behind him within each cell. Resolute amber eyes, confident adult face. Outfit: jade-green woven waist sash, short dark charcoal travel trousers, polished obsidian wrist guards with restrained green seams, plain cloth ankle wraps, bare feline paws. These clothes stay identical in all poses. Gold spotted fur remains prominent over chest, face and arms. He is visibly a jaguar, not a lynx, tiger, leopard cub, or a recolor of another fighter. Balam's silhouette should read as weighty, grounded and protective. The eight drawings are one consistent individual.
```

## tepa-prompt

```text
Primary request: create TEPA, an original small adult female teporingo (Mexican volcano rabbit) martial fighter.
Subject identity: compact athletic rabbit with VERY SHORT small rounded ears, each about one third of the head height, unlike long-eared hares. Dense dark brown fur with warm brown cheek highlights, short round rabbit muzzle and small dark nose, alert amber eyes, small subtle rabbit tail. Strong springy rabbit hind legs and large rabbit feet, sturdy hips, nimble torso. Confident mature expression; animal rabbit face, not human face.
Costume: fitted short indigo-blue jacket with rolled sleeves, mustard-yellow waist sash tied at the side, simple dark brown cropped training trousers leaving lower rabbit legs and broad furry feet visible, modest cream wrist wraps. No weapons, hats or extra props. Athletic adult, not a cute baby or toy.
Use case: stylized-concept.
Asset type: production-ready 2D fighting-game character sprite atlas. Create a landscape 2:1 PNG sprite sheet, ideally 2048x1024, with GENUINE TRANSPARENT RGBA background. Exactly eight full-body poses of ONE consistent character, four columns by two rows. Invisible equal cells. No background paint, no checkerboard pattern, no floor, no ground shadow, no text, no frames, no labels, no particles, no other characters.
Style: polished hand-painted 2D gouache fantasy game illustration. Compact adult athletic heroic proportions approximately three heads tall, detailed expressive animal face, warm amber edge lighting and cool teal shaded planes, confident dark silhouette edges, rich restrained natural materials and cloth brush texture, clean readable silhouette at 166px standing height. Not 3D, not pixel art, not plush, not baby proportions.
Layout is critical: all eight poses face RIGHT in consistent three-quarter side view. Preserve identical body and head scale across frames; do not enlarge crouched or fallen poses. Each standing figure is around 335px tall within its 512px square cell. Feet rest at local y=450, with root centered at local x=246. Keep at least 44px empty transparency at every cell edge, including above raised victory hand and beyond punch knuckles. No body parts touch or cross cell borders. The final fallen pose is low and horizontal near the same ground baseline, at the same physical body size. Keep both full feet, all ears, paws, tails and fists visible.
Exact pose order reading left-to-right:
top row 1 idle: balanced ready guard, fists near torso; 2 breathe: the same guard with subtle chest rise; 3 windup: hips shift back, rear striking fist visibly pulled backward near shoulder, front hand guarding; 4 punch: clear long straight punch toward the RIGHT, striking arm fully extended horizontally, front foot planted.
bottom row 5 hit: recoiling backward toward left from an incoming hit, eyes squeezed, arms slightly lifted, feet still grounded; 6 dodge: deep low crouch duck, bent knees, protective forearms; 7 victory: upright with ONE fist raised overhead, confident smile, fist completely inside cell; 8 defeat: lying on side near ground, eyes closed, head at right, whole body visible and correctly scaled.
Keep costume, anatomy, colors and face markings exactly consistent in every pose.
```

## tepa-punch-composite-prompt

```text
Usa la primera imagen como atlas base. Sustituye ÚNICAMENTE el cuarto personaje (fila superior, columna derecha) por la pose de golpe corregida del cuarto personaje de la segunda imagen. Conserva las otras siete poses de la primera imagen, sus colores, escala y posiciones. Ajusta sólo el nuevo golpe a la altura y suelo del personaje original. Mantén el hombro lateral, codo flexionado y puño corto a altura de pecho de la segunda imagen. Resultado: el atlas completo 1774×887, ocho poses, PNG con fondo transparente real. No cambies el resto ni añadas ningún fondo.
```

## tepa-punch-correction-2-prompt

```text
Edit only the TOP-RIGHT punch sprite (row 1 column 4) in this 4x2 Tepa atlas. Preserve the other seven sprites and the full 1774x887 layout as closely as possible.

The arm in that frame is anatomically wrong: it looks like a straight long tube coming out of the neck. Redraw the punch pose with visibly DIFFERENT corrected anatomy. LOWER THE ENTIRE STRIKING ARM to upper-chest height, well below the nose. Clearly show the rounded shoulder at the side of the ribcage, then a short upper arm with an indigo sleeve, a visible elbow bent approximately 30 degrees, a shorter forearm and neutral wrist. The forearm should be angled slightly upward from elbow to fist, not a perfectly horizontal tube. Keep the compact furry rabbit paw fist at chest height and no larger than her idle fists. Expose enough torso/shoulder contour that the arm cannot be mistaken for coming from the neck. Turn the ribcage and hips into the right-facing short punch. Place the opposite paw beside the jaw in guard. Keep a stable planted forward leg and supported rear rabbit foot. No elongated forearm, no big glove, no fused neck and arm, no extra limb.

Keep Tepa's adult athletic rabbit proportions, short rounded ears, brown fur, face, amber eyes, indigo jacket, mustard sash, brown trousers and cream wrist wraps. Preserve height, source scale and feet baseline. Keep all other seven poses unchanged. No new costume, no background, no text or shadows. Output genuine transparent RGBA PNG with the empty spaces fully alpha zero; never paint checkerboard pixels.
```

## tepa-punch-correction-prompt

```text
Use case: precise-object-edit / identity-preserve. This is a surgical anatomy correction in ONE animation frame of a production game atlas.
Edit ONLY the TOP-RIGHT character: row 1, column 4, the punch pose, within x1331..1773 and y0..443 in the attached 1774x887 sprite sheet. Leave the other SEVEN poses unchanged as closely as possible: their exact positions, scale, head, ears, costume, silhouette, textures, colors, and expressions are invariants. Keep the 4-column by 2-row atlas and canvas dimensions. Output real transparent RGBA PNG, no painted backdrop or checkerboard.

The player specifically rejected the anatomy and punching pose. Replace the top-right punch with a physically coherent compact adult rabbit martial-arts strike:
- A clearly visible rounded shoulder joint and short indigo sleeve originate at the SIDE of the upper torso, anatomically below the neck. The arm must NOT emerge from the neck or form one horizontal tube through the shoulder.
- Show a believable upper arm leading to a visible elbow, then a forearm, then a neutral aligned wrist. Keep arm length proportional to her arms in the other seven frames, with a slight natural elbow bend (roughly 15–20 degrees), never hyperextended.
- The striking paw is a compact furry rabbit paw fist, the same size as the fists in idle and windup. Modest knuckles, no inflated boxing glove, no balloon fist, no extra fingers. Cream wraps surround only the wrist/lower forearm.
- Rotate the ribcage and hips into the right-facing punch so the shoulder is connected to the torso; the head stays in a natural neck posture looking right.
- Keep the opposite arm bent with its small paw held in an effective guard near the chest/chin, clearly separate from the striking arm.
- Both strong rabbit hind legs provide a stable grounded stance: bent forward knee, supported rear foot, body weight plausibly balanced. Preserve the existing feet baseline and overall character height, and keep every body part inside that one cell.
Keep Tepa's exact identity: short rounded teporingo ears, dark-brown fur, amber eyes, mature athletic compact rabbit body, indigo-blue short jacket, mustard sash, brown cropped trousers, cream wrist wraps, natural furry rabbit feet. Maintain the same polished 2D hand-painted gouache illustration style and lighting. No new costume, no weapons, no human face, no infant proportions.
Do not modify any of the seven other poses. No text, no labels, no borders, no ground, no shadow, no particles. Preserve genuine alpha transparency.
```

## tepa-punch-extraction-2-prompt

```text
Use case: background-extraction. Remove the checkerboard background from this sprite sheet and output a PNG with a REAL TRANSPARENT ALPHA CHANNEL. Make every pixel outside the eight character silhouettes fully transparent (alpha 0). The visible checkerboard is currently painted background that must be removed; do not draw another checkerboard. This is a transparent cutout extraction. Keep all eight Tepa rabbit character sprites exactly in place, with the same size, proportions, colors, eight poses, and margins as the attached image. Preserve every ear, tail, paw, fist and costume edge. Do not add any backdrop, shadows, grid, texture or text. The result must be a genuinely transparent RGBA PNG sprite atlas, with the empty background absent.
```

## tepa-punch-extraction-3-prompt

```text
Elimina el fondo y deja únicamente los ocho personajes recortados sobre transparencia real. Devuelve un PNG transparente con canal alfa. Conserva sus poses, posiciones, tamaño, anatomía y colores.
```

## tepa-punch-extraction-prompt

```text
Use case: background-extraction. Remove the painted checkerboard background from this Tepa sprite atlas. Output a REAL RGBA PNG with fully transparent alpha-zero pixels everywhere outside the eight character silhouettes. The checkerboard is unwanted background and must disappear, not be redrawn.

Preserve all eight existing sprites EXACTLY as closely as possible: same locations, same sizes, same costume and colors, same eight poses. In particular preserve the CORRECTED TOP-RIGHT PUNCH: compact right-facing arm at chest height with visible lateral shoulder, bent elbow, short forearm and small furry paw; opposite paw guarding at chin. Do not lengthen or straighten that arm. Preserve all ear tips, paws, tails, wrist wraps and edges. This is only transparent cutout extraction; no pose changes, no redraw of anatomy, no added shadow, no floor, no background, no labels. Keep 1774x887 and the existing four-by-two layout.
```

## tepa-punch-regenerated-prompt

```text
Create a production-ready 2D game sprite atlas of TEPA, an original small adult female Mexican volcano rabbit (teporingo) martial artist. GENUINE TRANSPARENT PNG with real alpha-zero background. Landscape 2:1 canvas, ideally 2048x1024. Exactly eight full-body figures of the same character in four columns and two rows. Invisible equal square cells with clear gutters around all figures. No ground, shadows, props, text, labels, particles, frames, backdrop or checkerboard.

Tepa has VERY SHORT rounded rabbit ears (about one third of head height), dark brown natural fur, warm brown cheeks, small short rabbit muzzle, amber eyes, strong springy rabbit hind legs and broad furry rabbit feet. A mature athletic compact body about three heads high; expressive animal face, not human or baby. Costume consistent in all frames: short indigo-blue cloth jacket with rolled short sleeves, mustard-yellow waist sash tied to the side, dark-brown cropped training trousers, simple cream wrist wraps. Small round brown rabbit tail.
Polished 2D painterly gouache fantasy illustration, adult heroic animal proportions, clear dark silhouette, warm amber edge light and subtle cool teal shadows, restrained colors, detailed cloth and fur, legible when standing 166px high. No 3D rendering or toy look.

All eight poses face RIGHT in consistent three-quarter side view, same body scale in every frame. Keep whole hands, paws, ears and tail inside the intended cell with 8% clear transparent margins; standing figures occupy about 75% of each cell's height. Same standing feet baseline in each row. Never enlarge crouched or fallen figures.

Pose order:
1 top-left IDLE, balanced ready guard.
2 top-second BREATHE, same guard with slight chest rise.
3 top-third WINDUP, striking arm pulled back near shoulder, elbow clearly bent, other hand guarding.
4 top-right SHORT PUNCH: a visibly anatomically coherent compact punch directed RIGHT at CHEST height, below the muzzle. Rounded shoulder is attached to the SIDE of the torso below the neck, indigo short sleeve ends before the elbow, elbow remains flexed about30degrees, proportionate SHORT forearm angled slightly upward toward a small furry rabbit paw fist at chest height, wrist neutral. The paw is no bigger than either idle fist. Rotate ribcage and hips into the strike; the opposite paw guards beside the chin. Stable forward bent knee and supported rear rabbit foot. Never a horizontal tube, stretched arm, arm emerging from neck, giant glove or extra limb.
5 bottom-left HIT, leaning slightly back from impact.
6 bottom-second DODGE, deep low crouch with bent knees and protective forearms.
7 bottom-third VICTORY, upright smiling with one fist lifted only beside the head at EYE HEIGHT, not above the ear tips. Compact victory silhouette wholly inside cell, wide empty gutter above. The other fist rests at the waist.
8 bottom-right DEFEAT, whole body lying sideways near the same feet baseline, head at right, eyes closed, no injury detail, body at same physical scale.

Maintain the precise character identity and costume in every pose. The top-right punch must have a clear shoulder, elbow and wrist with proportionate anatomy. Every pose must be isolated with true alpha transparency around it.
```

## xuna-correction-prompt

```text
Use case: identity-preserve sprite atlas layout correction.
Edit the attached Xuna sprite atlas ONLY to increase EMPTY TRANSPARENT spacing around every pose. Preserve the exact character design, hairless gray charcoal canine skin, elegant xolo dog face, large triangular ears, copper waistcoat, coral sash, turquoise beads, colors, painterly finish, all eight exact poses and their order. Preserve real RGBA alpha transparency; the output background must contain zero-alpha pixels, not black paint or a checkerboard pattern.
Keep the same landscape 2:1 canvas and four-column two-row layout, eight full poses. Uniformly reduce the scale of ALL eight drawn poses by approximately 18% within their own cells. Maintain exactly the same relative body scale across every frame. Position each full silhouette inside its own equal cell with at least 35px clear transparency on all sides at the current 1774x887 resolution. The victory fist must be completely below the horizontal boundary y444, with a wide clear gutter; the windup feet must be fully above that boundary. Standing feet should share baselines near y402 in the first row and y845 in the second row. Keep the fallen body near the second-row baseline and don't enlarge it. Do not crop, cut off, delete or change any hand, foot, ear or tail. Every pose, especially the long horizontal punch and the fallen body, must remain wholly inside its own cell.
No new poses, no weapons, no shadows, no ground, no background color, no frames, no letters, no labels. Correct margins only; preserve identity and genuine transparency.
```

## xuna-extraction-prompt

```text
Use case: background-extraction. Remove the checkerboard background from this sprite sheet and output a PNG with a REAL TRANSPARENT ALPHA CHANNEL. Make every pixel outside the eight character silhouettes fully transparent (alpha 0). The visible checkerboard is currently painted background that must be removed; do not draw another checkerboard. This is a transparent cutout extraction. Keep all eight Xuna dog character sprites exactly in place, with the same size, proportions, colors, eight poses, and large margins as the attached image. Preserve every ear, tail, paw, fist and costume edge. Do not add any backdrop, shadows, grid, texture or text. The result must be a genuinely transparent RGBA PNG sprite atlas, with the empty background absent.
```

## xuna-prompt

```text
Primary request: create XUNA, an original adult female xoloitzcuintle (Mexican hairless dog) guardian martial fighter.
Subject identity: visibly HAIRLESS charcoal-gray smooth-skinned canine, elegant long dog muzzle and black nose, large upright triangular ears with warm dark inner planes, fine alert amber eyes, slender hairless tail, defined lean athletic shoulders and long agile legs. Serene dignified mature guardian expression; unmistakably an elegant xolo dog face, never a human face or hairy wolf. No fur coat, no hair tuft, no mane.
Costume: fitted short copper-colored leather waistcoat over charcoal skin, coral-red waist sash, small restrained turquoise bead bracelets and one short small-bead necklace. Deep dark brown cropped training trousers and simple cream wrist wraps. Bare charcoal canine paws. No weapons, hats or extra props. Lean confident adult build, not a baby or toy.
Use case: stylized-concept.
Asset type: production-ready 2D fighting-game character sprite atlas. Create a landscape 2:1 PNG sprite sheet, ideally 2048x1024, with GENUINE TRANSPARENT RGBA background. Exactly eight full-body poses of ONE consistent character, four columns by two rows. Invisible equal cells. No background paint, no checkerboard pattern, no floor, no ground shadow, no text, no frames, no labels, no particles, no other characters.
Style: polished hand-painted 2D gouache fantasy game illustration. Compact adult athletic heroic proportions approximately three heads tall, detailed expressive animal face, warm amber edge lighting and cool teal shaded planes, confident dark silhouette edges, rich restrained natural materials and cloth brush texture, clean readable silhouette at 166px standing height. Not 3D, not pixel art, not plush, not baby proportions.
Layout is critical: all eight poses face RIGHT in consistent three-quarter side view. Preserve identical body and head scale across frames; do not enlarge crouched or fallen poses. Each standing figure is around 335px tall within its 512px square cell. Feet rest at local y=450, with root centered at local x=246. Keep at least 44px empty transparency at every cell edge, including above raised victory hand and beyond punch knuckles. No body parts touch or cross cell borders. The final fallen pose is low and horizontal near the same ground baseline, at the same physical body size. Keep both full feet, all ears, paws, tails and fists visible.
Exact pose order reading left-to-right:
top row 1 idle: balanced ready guard, fists near torso; 2 breathe: the same guard with subtle chest rise; 3 windup: hips shift back, rear striking fist visibly pulled backward near shoulder, front hand guarding; 4 punch: clear long straight punch toward the RIGHT, striking arm fully extended horizontally, front foot planted.
bottom row 5 hit: recoiling backward toward left from an incoming hit, eyes squeezed, arms slightly lifted, feet still grounded; 6 dodge: deep low crouch duck, bent knees, protective forearms; 7 victory: upright with ONE fist raised overhead, confident smile, fist completely inside cell; 8 defeat: lying on side near ground, eyes closed, head at right, whole body visible and correctly scaled.
Keep costume, anatomy, colors and face markings exactly consistent in every pose.
```

## copal-hit-correction-prompt

```text
Use case: precise-object-edit. This is an existing 1774x887 transparent sprite atlas, four columns and two rows. Edit ONLY the RINGED TAIL of the HIT REACTION character in the BOTTOM LEFT cell (row2,column1; sprite bounds approximately x36..444,y460..846). The character is leaning backward with face looking up/right.
Curl and tuck that particular black-and-white ringed tail much closer behind the torso and hip. Reduce its backward horizontal projection by at least30percent. The existing tail left edge near source x36 must become near x125, with the compact curve contained from x125 to x260. Keep a full, fluffy, visibly long ringtail with the same alternating ivory and dark rings and an intact tip; coil the length into a tighter upward C-shape close behind the character instead of stretching it far left. Keep the tail attached naturally at the same pelvis. There must be transparent empty space where its old far-left extension was.
Preserve everything else EXACTLY: the hit character's face, ears, torso, arms, hands, vest, plum sash, legs, feet and physical scale/position. The feet stay at their current baseline and x coordinates. In particular do not move or resize the entire hit character, do not shift foot anchors, and do not change its backward hit reaction. Preserve ALL OTHER SEVEN POSES completely: same silhouettes, anatomy, colors, canvas positions, tail shape, clothing, lighting and painterly style. Keep the 4x2 layout and1774x887 canvas.
The final image must be a real transparent RGBA PNG, alpha-zero outside the eight silhouettes. No painted checkerboard, no background color, no shadows, no text. Only this one tail changes.
```

## copal-hit-extraction-prompt

```text
Use case: background-extraction. Remove the checkerboard background from this sprite sheet and output a PNG with a REAL TRANSPARENT ALPHA CHANNEL. Make every pixel outside the eight character silhouettes fully transparent (alpha 0). The visible checkerboard is currently painted background that must be removed; do not draw another checkerboard. This is a transparent cutout extraction. Keep all eight Copal ringtail character sprites exactly in place, with the same size, proportions, colors, eight poses, and margins as the attached image. Preserve every ear, tail, paw, fist and costume edge. Do not add any backdrop, shadows, grid, texture or text. The result must be a genuinely transparent RGBA PNG sprite atlas, with the empty background absent.
```

## copal-hit-extraction-short-prompt

```text
Remove the background from this sprite sheet. Transparent background PNG cutout. Keep the eight characters.
```

## copal-prompt

```text
Use case: stylized-concept.
Asset type: production sprite atlas for the original 2D fighting game Brasa, Liga de los Faroles.
Create ONE complete PNG atlas, landscape 2:1, preferably 2048 by 1024, with a genuinely transparent alpha background. Exactly EIGHT separate full-body drawings arranged in four equal columns and two equal rows, read left to right. There are no drawn grid lines. Every pose faces RIGHT in a consistent side-three-quarter view, including the defeated pose.
Layout is essential: each logical cell is 512 by 512, each character fully contained in its cell with generous transparent margins and at least 30 pixels of separation. Center the standing body's hips at local x=245, feet baseline at local y=460, normal head height around y=100; the physical character remains the same scale in all eight poses. Raised fist fits below y=35; stretched punching fist and tail never touch any cell edge. The defeated body lies close to the same floor baseline and is not enlarged. Exactly one character per cell, no extra limbs, no duplicated or overlapping characters.
Pose order, exactly:
TOP ROW: (1) idle ready guard, (2) subtle breathing guard with relaxed shoulders, (3) visible punch windup with rear fist drawn back, (4) decisive straight punch fully extending to the right.
BOTTOM ROW: (5) hit reaction leaning backward yet looking right, (6) low evasive crouch/dodge, (7) proud victory with one fist raised and face looking right, (8) defeated lying on side, head toward the RIGHT, eyes closed, non-graphic.
Style: polished hand-painted 2D gouache fantasy game illustration, mature heroic anthropomorphic animal about three heads tall, coherent anatomy and materials, subtle brush texture, dark clean readable contours, warm amber rim light and restrained teal shadows, textured matte fur and cloth. Warm dignified desert-night martial fighter, expressive adult face, not a cute toy, not 3D, not pixel art, no glossy plastic.
Transparent backdrop only: absolutely no environment, ground planes, cast shadows, floor shadows, smoke, clouds, glows, circles, aura, scenery, text, numbers, labels, border, watermark, or drawn checkerboard. No weapons or props floating separately. Preserve actual alpha; all empty space must be transparent.
Subject identity: COPAL, an agile anthropomorphic Mexican cacomixtle (ringtail), clearly a slender ring-tailed procyonid, not a cat, fox, lemur or red panda. Grey-brown fur, pale cream throat, narrow pointed muzzle, very large rounded ears, expressive dark eyes edged by subtle pale orbital markings, nimble paws and long athletic limbs. Most recognizable feature: an enormous long fluffy tail with bold alternating clean ivory-white and near-black rings, longer than the torso, curved in a compact C or S behind him so the entire tip stays safely inside EACH cell. The huge tail must be preserved in ALL eight poses including punch and defeat, with no intersection into neighboring drawings and no cropping. Outfit: light oat-colored sleeveless cloth vest, plum-purple woven waist sash, warm brown short trousers, understated cloth wrist and ankle wraps. Identical outfit and tail pattern in every pose. Mature sly but kind expression, youthful adult martial artist with springy low stance and slim silhouette, never baby proportions. The eight drawings are one consistent individual.
```
