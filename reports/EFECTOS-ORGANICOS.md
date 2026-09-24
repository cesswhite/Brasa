# Integrated character effects

The circles of fire and energy are replaced by small particles that are born next to the body, detach with movement and gradually disappear. Color, direction and duration distinguish an impact, a charge and each state.

| Before | now |
|---|---|
| Large rings in loads and transformation | Rising embers and sparks close to hands and torso |
| Radial bursts over the character | Directional sparks from the point of contact |
| Intense white flash over the entire illustration | Brief lighting that preserves character detail |
| Auras with circular outline under the feet | Warm specks, fireflies and golden dust around the body |
| Circular wave upon entry | A small release of embers |
| Painted contrails and fixed clouds | Particles that separate from the actor, slow down and fade away |
| Active Character Ring | Diffused contact light and small shift marker |

Fire uses warm embers; poison, dull greenish specks; healing, soft green light; defense, short cold flashes. The effects are born in areas of the current pose - hand, chest, back or feet - and respect your orientation, inclination and jump. The reflected light is applied within the transparency of the illustration.

The same system is used in combat and replays. There is a limit of 20 emitters, 12 pending emissions and 320 particles; the extinguished particles are released. The pause freezes their watches. Reduced Movement suppresses bursts and jerks, and preserves a static indication of the turn.

Particles are drawn with a small smooth grain generated in memory by Godot. The atlases of characters and settings maintain their original pixels. The eight effect IDs continue to work with existing techniques, events, and histories; The old effects atlas remains available for compatibility and comparison above.

## Samples and validation

Comparisons are captured directly in Godot, with equal framing and manual clocking. They are distinguished from real combat and do not generate rewards or player saves.

Final revision was performed on 1360×880 and 390×844. The embers have a small core and a smooth edge to remain visible when reduced in size; The impact preserves the details of the face and clothing. Also revised are jump, dash, poison, heal, defense, pause, and reduced movement.

Sample videos: desktop (`organic-fx/organic-fx-desktop.mp4`; not included) · mobile (`organic-fx/organic-fx-mobile.mp4`; not included). Each brings together four scenes in 3,2 seconds at 30 FPS, without audio.

| Sample | Before | After |
| --- | --- | --- |
| Fire and transformation, desktop | [PNG](organic-fx/before/2-1360x880.png) | [PNG](organic-fx/after/2-1360x880.png) |
| Charge, Impact and Auras, Desktop | [PNG](organic-fx/before/1-1360x880.png) | [PNG](organic-fx/after/1-1360x880.png) |
| Fire and transformation, mobile | [PNG](organic-fx/before/2-390x844.png) | [PNG](organic-fx/after/2-390x844.png) |
| States, mobile | [PNG](organic-fx/before/3-390x844.png) | [PNG](organic-fx/after/3-390x844.png) |

In addition to the game, eight League and Story Mode matches were started from the production interface with disposable profiles. The screenshots were taken by observing real events, without imposing poses: [desktop](organic-fx/live/league-battle-onix-1360x880.png), [mobile](organic-fx/live/battle-bruma-390x844.png), [observations](organic-fx/live/observations.json).

| Validation | Result |
| --- | --- |
| Emitters, limits, anchors, late events and memory | 129 checks, 0 faults |
| Anchors and repetitions, without window | 172 checks, 0 faults |
| Native rendering, pause, reduced motion and 20/60/120 FPS | 185 checks, 0 faults |
| Combat distribution in seven sizes | 2.139 checks, 0 faults |
| Clocks, KO, customization, sequences, identity and online interface | 10.164 checks, 0 faults |
| Eight fights from Main | 153 checks, 0 faults |
| Local backend catalog and inventory | 9 tests, 0 failures; successful build |

20/60/120 FPS checks verify states, limits, and extinction; They are not a measurement of device performance. Logs and file traces are saved in [validation.json](organic-fx/validation.json). Lantern and Crown's descriptions have been updated to match their appearance, while retaining their IDs and unlock conditions.
