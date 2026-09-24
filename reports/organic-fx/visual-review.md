# Visual inspection of organic particles

The swatch uses actual `FighterView` and `CombatFX` on the illustrated background of Brasa. Their gestures are deliberately activated and the presentation clock is advanced by hand: these are technical samples, not recordings of natural combat. The replay test does get its events from the real engine, running in memory, and controls only history replay. No scene starts Main or opens a game or user identity.

Four frames are preserved in 1360×880 and 390×844: charging/contact with Lantern and Fireflies; Ascua transforming and Luma with burn; poison, shield, Crown and Pulse entry; jump, dust and displacement. The video also includes small impact and healing. Pause and reduced motion captures use the production replay panel.

| Before | After |
| --- | --- |
| The radial atlas could wrap around Ascua's torso and cover his head. | Small emission next to the body; free particles with drift and fading. |
| Auras and introduction traced circular contours. | Discreet specks and sparks around the back and feet, with soft lighting on the illustration. |
| Difficult comparison if the character size changed. | Same clock, background, framing and scale in both sets of eight captures. |

The reference above is compiled from copies of `fighter-before.gd` and `combat_fx-before.gd`, without restoring production code. The old FX expressly uses `combat_fx-before.json`, with the original 124/170 load/transform sizes. No pixels have been modified in any atlas or in the screenshots; Godot writes each PNG directly.

The independent test checks anchors when jumping and crouching, hand/chest/back/feet reflex when changing orientation, independence of particles already released, heights with respect to the HUD and the stage, maximum budget, pause/resume, reduced movement and invariance of historical events. Runs presentation with 20, 60 and 120 FPS steps; This verifies finite states, budgets and extinction, not a measure of device performance or exact equivalence of each mobile emission between rates.

Commands reproducible from the project root:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path outputs/Brasa --script res://tests/test_organic_fx.gd
/Applications/Godot.app/Contents/MacOS/Godot --path outputs/Brasa --script res://tests/test_organic_fx.gd -- --baseline --capture-dir="$PWD/work/organic-fx/before"
/Applications/Godot.app/Contents/MacOS/Godot --path outputs/Brasa --script res://tests/test_organic_fx.gd -- --capture-dir="$PWD/work/organic-fx/after"
/Applications/Godot.app/Contents/MacOS/Godot --path outputs/Brasa --script res://tests/test_organic_fx.gd -- --capture-dir="$PWD/work/organic-fx/after" --video-only
```

Final result: **185 native checks, 0 failures** in test-organic-native.log (`test-organic-native.log`; not included). Includes twelve final captures: four samples and two repeat states for each size. The previous comparison has eight captures, generated separately with the same frame. The 172 checks in the non-render pass are a subset; they are not added to the 185.

The final inspection confirms visible and discreet grains, without fire rings or enveloping halos. Lantern, Fireflies, Crown and Pulse retain small signs around the back/feet; The states leave specks close to the hands and body. Ascua's head is clear. The full jump fits under the display HUD. On mobile the effects remain subtle and are better distinguished in motion than in a still image; they are not trying to represent big flames.

[Previous comparison](before/observations.json) · [Final samples and data](after/observations.json) · [Test](../../tests/test_organic_fx.gd).

![Loading and contact with final particles](after/1-1360x880.png)

![Poison, Shield, Crown and Pulse on mobile](after/3-390x844.png)

Final videos: desktop (`organic-fx-desktop.mp4`; not included) and mobile (`organic-fx-mobile.mp4`; not included), each with native 96 frames at 30 FPS and 3,2 seconds, without audio. FFmpeg directly encodes the PNG stream; no atlas or PNG are altered. The separate export ended with 12 sample build checks and 0 failures; it does not add to the functional suite. [Manifest and final hashes](visual-validation.json).
