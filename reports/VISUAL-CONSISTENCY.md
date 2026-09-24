# Character Visual Consistency

> Production update: [scale, transparency and localized damage](SPRITE-PRECISION.md). This revision replaces the historical visual hashes and benchmarks in this document.

The library uses **17 visual profiles and 680 poses in 51 banks**: 8 base poses, movement 16 and body reaction 16. The physical scale comes from the canonical profile; The pose modifies the posture and visible silhouette, without changing the size of the character to fit into a box.

The original audit classified **344 poses KEEP, 208 FIX and 128 REGENERATE**. Replaced the affected **21 banks, equivalent to 336 poses**, preserving the other 344 illustrations and normalizing the entire library. Source substitution, static revision, normalization and acceptance in animation are different milestones. **Final integration passed static and native review; 51 banks are accepted for this delivery.**

Inventory sources: pose audit (`work/visual-consistency/audit/audit.json`; not included), original static opinion (`work/visual-consistency/audit/AUDIT.md`; not included), and [production manifest](../assets/sprites/normalized/manifest.json). The audit documents describe the previous status; Your illustrative canvas or density proposals do not substitute the following final contract.

## Before / After — Before / After

| Appearance | Before | After |
|---|---|---|
| visual authority | Recognizable base references, with changes in anatomy, mass or material in later banks. | Canonical reference, hash, materials, projected proportions and deliberate height per body; 336 substituted poses against that reference. |
| Scale | Uniform base height of 166 and separate factors derived from the reference height of each bank at runtime. | Deliberate heights of 146–214 world units; offline normalization with a uniform factor per bank and global density 1.5. |
| Canvas and root | Variable rectangles; alpha clipping and elevation correction derived from the silhouette. Some supports displaced the root to the extreme foot. | 512×512 complete cells, pivot [256,448], 448 soil line and roots revised; The alpha does not decide scale, pivot or jump height in runtime. |
| Cargo and materials | The light of charge or form affected the entire body; some banks already had materials washed at the source. | Stable normal body, limited impact flash and anatomical energy in an independent layer; defective sources are replaced. |
| FX and floor | Existing organic particles, with approximate temporal contacts and anchors proportional to the visible rectangle. | Markers per phase, explicit sockets and projected ground; The emitted particles remain in world space. |
| KO and victory | Some commands could interrupt terminal states; the final pose returned to the old base bench. | Priority KO, victory linked to the resolved result and sustained final normalized pose. Holding preview has separate API. |
| Portraits | Some screens adjusted each body or reserved the entire combat space. | Cameras shared by presentation, preserved proportions and moving preview of Nima from approximately 80 to 129 px in the revised fixture. |
| Acceptance | A recognizable illustration could seem valid on its own. | Comparison with canon and neighboring poses, geometric diagnosis and native review of the entire sequence as separate requirements. |

## Inventory and deliberate scale

The profile corresponds to the **visual body**, not the account, level or combat archetype. Choosing another cosmetic body does not modify statistics. There are 15 playable bodies and 2 bosses.

| Body | Standing height in world | Replaced font banks |
|---|---:|---|
| Nima | 164 | reactions |
| Luma | 158 | — |
| Mugo | 196 | movement |
| Sira | 184 | movement |
| Iria | 160 | movement |
| Duna | 178 | movement |
| Kiro | 180 | movements, reactions |
| Neris | 182 | movements, reactions |
| Taro | 184 | movements, reactions |
| Balam | 182 | movements, reactions |
| Tepa | 146 | movements, reactions |
| Xuna | 174 | — |
| Copal | 152 | movements, reactions |
| Onix | 154 | — |
| Bruma | 186 | movement |
| Ascua | 214 | movement |
| Véspera | 204 | movements, reactions |

These heights include the fixed features of the standing silhouette, such as ears or horns. They are design decisions in shared units, not actual centimeters. Crouching, falling, raising an arm or extending a tail changes the visible silhouette; does not redefine this height.

## Profiles and offline normalization

[character_visual_profiles.json](../data/character_visual_profiles.json) records idle authority, color, material, lighting, equipment, size, projected ratios, landmarks and variants. [CharacterVisualProfile](../scripts/character_visual_profile.gd) validates and exposes the common contract:

| Field | Production value |
|---|---|
| Profile version / pack | 1 / 2 |
| `profile_id` normal | `<body>:normal:v1` |
| `canvas_px` | [512,512] |
| `pivot_px` | [256,448] |
| `ground_baseline_px` | 448 |
| `pixels_per_world_unit` | 1.5 |
| Canvas drawing in runtime | 1/1.5 fixed scale before scene camera |
| Base Atlas | 2048×1024, 8 cells |
| Atlas movement / reactions | 2048×2048, 16 cells per bank |

The normalizer (`work/visual-consistency/audit/normalize_roster.py`; not included) calculates `factor = altura_canónica_mundo × 1.5 / reference_height_fuente` once per bank. It applies exactly that factor to all its frames, with the source pivot noted, and composes each result on the same canvas. The banks can come from different resolutions; no frame receives its own corrective scale. The root can be annotated by pose to correctly position the drawn figure, without automatically deriving it from the center of its alpha box or the single supported foot.

Extract rectangles are source storage, not visual adjustment frames. If two rectangles include neighboring regions, `component_isolation_alpha_threshold` and `component_id` separate the bodies. A canvas overflow causes normalization to fail: the pose is not shrunk to hide it. Extraction and resampling preserve the original and record hashes, factor, and origin coordinates.

The native patch rejected the first motion fixes for Mugo, Iria, Bruma, and Sira for material simplification. The next pass uses groups of four poses with the canonical idle as the first visual authority. Each family retains a single density and is composed by translation, without correcting the scale of individual poses. Candidates and rejects remain in `work/visual-consistency/generated/audit-fixes/` to distinguish a proven improvement from a mere new generation.

The packs are saved in `assets/sprites/normalized/<body>-<bank>-v2.png/.json`. [FighterAnimationSet](../scripts/fighter_animation_set.gd) checks identity, canvas, pivot, density, pose order and entire regions. It retains compatibility with old packs, identified as fallback, without considering them approved for this reason. `alpha_bounds_px` is an offline measurement for diagnosis of painted pixels; it does not drive rendering, scaling or jumping. `intrinsic_lift_px: 0` prevents a second correction based on the visible foot; the drawn joint and Godot's trajectory maintain distinct functions.

## Hybrid animation and three layers

**1. Body.** [FighterView](../scripts/fighter_view.gd) selects poses and draws the entire canvas. The sprites provide posture, expression and articulated deformation; Godot applies scroll, jump, backspace, small rotations, pause and hit stop. The shader retains cosmetic palettes and limited impact flash; The global loading light and the global transformation color bath were removed.

**2. Body-bound FX.** A second `Sprite2D` consumes an optional paired atlas or anatomical texture from [AttachedEnergyTrack](../scripts/attached_energy_track.gd). It exactly shares frame, canvas, pivot, position, mirror, scale and rotation with the body. It does not have a second animation clock. Intensity uses the same load/recovery advance or transformation; Normal sleep and KO turn off the broadcast. `attached_fx_enabled` allows comparison to body without FX during QA. A frame with no valid input does not accidentally conserve the energy of the previous one.

The current anatomical generator is implemented for **Ascua**, from pose-annotated hand and core sockets. Its radii are 12 and 10 px and its maximum alpha is 0.35; does not read or repaint body texture. An unannotated or hidden kernel does not emit; a hidden hand either. Other bodies admit the paired atlas contract, but anatomical nuclei are not invented for them. `effect_anchor()` uses explicit sockets and fixed compatibility zones when they are missing; the latter are not equivalent to verified anatomical landmarks.

**3. World FX.** [CombatFX](../scripts/combat_fx.gd) composites dust, trails, embers, impacts, and fragments using existing organic pigment language. Senders can follow the source while broadcasting; each particle becomes independent in the world at birth. Ground and feet use the Y of the floor and the current X of the contact, without following the elevation of the sprite during a jump. The budget is still limited to 20 effects/emitters, 320 particles and 12 pending actions.

The `ember_core` profile explicitly defines the same anatomy, canvas and density as the normal shape, with local energy changes allowed. The currently activated transformation on clips is Ascua; Registering profile variants on other bodies does not by itself introduce playable transformations, statistics, or new shape libraries. A future actual horn, armor, or silhouette alteration requires a revised variant and corresponding art.

## Markers, states and combat authority

[MoveVisualProfile](../scripts/move_visual_profile.gd) describes animation, impact, wake, ground, reaction, camera, hit stop and extension fields for track, variant, sound and morph requirement. The events are resolved from the `windup`, `travel`, and `recovery` phases of the actual motion. Extension values ​​do not automatically create a new asset or gameplay behavior.

There are markers for left/right stance, takeoff, landing, glide start/end, preparatory rollback, loading, forward, continuation, and recovery. `CombatFX.play_move()` retains one cursor per action, deduplicates per actor/side/time/motion, and processes all cross markers in a frame. The damage impact follows the authoritative event, not a visual marker. Main and replay use the same functions and ages; Moves, damage, RNG, rewards, and logs are not recalculated from launch.

16 Ascua motion poses include 32 sole contacts manually annotated and projected to the ground. They replace the pilot's generic standing areas, without moving or resizing the body. Refined families incorporate the same foot, core and hand contract into their sidecars. In an aerial pose, the projected socket expresses where it is emitted above the floor; it does not claim that the drawn foot is supported. The rest of the banks retain the fixed zone of compatibility when a specific entry is missing.

KO interrupts even a visible victory. A real win requires `resolve_battle()` after the result; `preview_victory()` serves Story Mode and Creation. No cosmetic order revives a KO. The final poses `grounded` and `victory_peak` remain held without reverting to previous art. Diagnostic states distinguish rest, charge, attack, air, recovery, reaction, transformation and terminals. Head, Body, Low, Air, Guard, Status, Critical, and Knockdown Reactions reuse appropriate poses; invalid aliases preserve a safe fallback and do not create damage zones.

## Common cameras and portraits

Arena and replay apply a common framework to both combatants. The outer margin of Arena is 165 units, obtained from a measurement of 164.52; the space towards contact is still available. The roster is measured to define shared constants, never to scale an actor to the current frame.

Story Mode and idle previews use `REST_ENVELOPE = Rect2(-122,-224,244,232)`. Creation selects explicit shared cameras: idle/enter, attack `Rect2(-154,-224,308,232)` and victory `Rect2(-132,-260,264,276)`. The selection occurs when you press the action and is maintained throughout the sequence and its final pose. You can switch once between chosen presentations; It does not pursue the animated silhouette nor does it depend on the character.

Portrait measurement covered 25.585 samples from 17 bodies. In the reviewed fixtures, Nima measures 129 px at rest to 390×844 and 312 px to 1360×880. New sources must pass these checks again so that the frame still contains their poses. See measurement and review (`work/visual-consistency/portrait-framing/review.md`; not included) and native captures (`work/visual-consistency/portrait-framing/screens/screens.json`; not included).

## Flow to add a character or bank

1. **Define the canon before zooming in on poses.** Choose the idle and authority of material, texture, lighting and equipment; preserve source and hash. Set world height with respect to the roster. Record landmarks, uncertainty and any legitimate variants in `character_visual_profiles.json`.
2. **Register the body.** Add its atlas/ID relationship to `FighterAnimationSet.BASE_TO_BODY`; For a playable appearance, integrate the character catalog and `CosmeticCatalog.BODY_ASSETS`. Chiefs also record where their definitions of Story Mode are constructed. Do not confuse cosmetic identity with archetype, progression or account.
3. **Prepare the necessary poses.** Respect the names and order of `BASE_POSES` and `BANKS`; Those arrays are the authority of the loader. Use the canon as the first reference and the previous sequence only for pose semantics. Ask for a single scale, same angle, consistent materials, transparent margin and absence of external baked-on FX. Add transitions when they resolve a specific discontinuity, not to inflate the number of images.
4. **Audit source.** Compare each pose to canon and its neighbors: head, torso, limbs, tail/horns, equipment, texture, and lighting. Check for local foreshortening without tolerating growth of the entire body. Register KEEP/FIX/REGENERATE with reason. Regenerate incorrect anatomy; do not compensate it with a scale per frame.
5. **Prepare RGBA and sidecar.** Keep original, prompt and result. Technical cleaning of the background must be authorized, protect materials and record which pixels change. Note regions, source pivots, a common `reference_height`, sockets, and visibility; If a measure is missing, leave it absent instead of inventing it.
6. **Normalize offline.** Incorporate the source reference required by the normalizer—including `canonical-runtime-before.json` for a new body—and pass explicit overrides of the revised banks. Run the single factor and check that no pose overflows. Import the three v2 packs; maintain traceability and fallback sources.
7. **Connect presentation.** Choose clips and markers within existing times. A paired track must have the same regions, canvas and pivot. Note occlusion. Any new body reflection needs a revised localized mask; The absence of a mask preserves the normal material.
8. **Validate the real sequence.** Run loaders, geometry, clocks, terminal states, FX, cameras and UI. Play both directions, attacks/charge, reactions, fall/get up, sustained KO and victory, with pause, hit stop, reduced movement and replay ×1/×2. Compare body only and FX activated. Check mobile, desktop and crossings between banks. Register art and runtime separately before approving.

## Limits of measurement and acceptance

The landmarks and anatomical ratios are **manual estimates of 2D projection with uncertainty of ±8 px**. The 8% relative threshold is a signal to review, not an automatic rule that approves or rejects anatomy. Volume 3D remains uninferred (`body_volume: null`); Perceived mass is qualitatively compared against canonical torso, neck, and thighs. Alpha width, area, and luminance describe the image and do not alone demonstrate consistency of anatomy, texture, or exposure.

Late markers retain their age, but their position is evaluated against the pose available when they are dispatched; a complete historical history of sockets is not reconstructed. Different frequencies should produce unique events and stable ground, without promising pixel identity between refresh rates. [FX report](VISUAL-FX.md) details this limitation and its evidence.

Normalizing 680 poses certifies a geometric contract, not 680 artistic decisions. The `PILOT_REVIEW`, `CORRECTED_STATIC_REVIEW`, or `REGENERATED_STATIC_REVIEWED` states preserve the historical preparation stage for each source. Final acceptance is recorded separately, against the exact hashes of each atlas and sidecar, in [acceptance.json](../assets/sprites/normalized/acceptance.json). `profile_status` preserves the description of the canon definition stage; It does not replace that ruling by the bank. Renormalize resets the core approval fields to require review of new sources.

## Evidence of stages already executed

| Stage | Recorded result | Evidence |
|---|---|---|
| Original audit | 680 poses; 344 KEEP / 208 FIX / 128 REGENERATE | audit.json (`work/visual-consistency/audit/audit.json`; not included) |
| Initial canonical runtime | 20.430 checks, 0 faults | runtime-validation.json (`work/visual-consistency/runtime-validation.json`; not included) |
| FX and markers | Suites of particles, markers, paired track and organic regression without errors in that cut | fx-validation.json (`work/visual-consistency/fx-validation.json`; not included) |
| Portrait framing | 61.163 added checks for headless and native runs, 0 crashes; They are not independent items | portrait-framing/validation.json (`work/visual-consistency/portrait-framing/validation.json`; not included) |
| New sources | Prompts, RGBA, sidecars, cleanup, revisions and hashes per group | generated/ (`work/visual-consistency/generated/`; not included) |

These figures belong to specific cuts of work. The historical figures do not add up as a global certification of the final state; the latest integration has its own regressions and traps, recorded below.

## Final validation

**Accepted: 17 bodies, 51 banks and 680 poses; no overt visual incidence in this cut.** The review distinguished geometry, material and continuity. Bruma, Sira, Mugo and Iria were accepted after regenerating their moves more closely to canon. Duna was accepted after removing the magenta residue and its antialias border, preserving anatomy, pivots and scale. Nima maintains minor stroke and saturation variations compatible with the same material and mass at game size.

| Final check | Result | Evidence |
|---|---|---|
| Asset integrity | 680 exact reconstructions; 51 current imports; 51 original intact; no overflow | final-asset-integrity.json (`work/visual-consistency/final-asset-integrity.json`; not included) |
| Composition of refined families | 4 families, 16 sheets; composition by translation and a single factor per family | sources and verifications (`work/visual-consistency/generated/audit-fixes/`; not included) |
| Regressions | 12 suites, 48.587 checks, 0 faults and 0 Godot errors | validation-final.json (`work/visual-consistency/validation-final.json`; not included) |
| actual speed | 17 native passes ×1, 1.749 observations; no entry modified since execution | results and hashes (`work/visual-consistency/roster-native/summary.json`; not included) |
| artistic acceptance | Opinion by the 51 banks, with comparison against fees, captures and coverage limits | acceptance-final.json (`work/visual-consistency/roster-native/acceptance-final.json`; not included), readable review (`work/visual-consistency/roster-native/acceptance-current.md`; not included) |
| Combat and replay | 1.113 checks and 96 traps in 1360×880 and 390×844; pause, hit stop, contact and terminals | main-replay/results.json (`work/visual-consistency/main-replay/results.json`; not included) |

True Speed Passes do not use PNG capture, MovieMaker, or forced FPS. Each showcase cycled through 33 active pose names per body; the 136 base cells and the 17 poses `low_health` were also reviewed in static. This coverage is not presented as a reproduction of the 680 independent cells. The fixtures go through types of movement and states; When a character does not have an attack of a certain type in his catalog, the sample is identified as a visual fixture and not a new playable ability.

The Ascua final video (`work/visual-consistency/ascua-final.mp4`; not included) shows localized charging, anticipation, attacks, jump, dust, reactions, transformation and terminal states. It is a MovieMaker visual recording: 20,97 s, 1.258 frames, 60 fps and 1224×792 actual resolution. It is not used as a performance test; that check comes from the separate native pass. The video manifest (`work/visual-consistency/roster-native/ascua/movie/movie-manifest.json`; not included) preserves command, resolution and hash.

The combat/replay screenshots correspond to the exact cut recorded in main-replay-inputs.json (`work/visual-consistency/main-replay-inputs.json`; not included). The parallel UI task then adjusted the location of the result poster on the desktop and presentation texts, with its own tests; These screenshots are not labeled as the latest design of all screens. The final PNGs and sidecars on the roster are individually identified in the acceptance of this delivery.

Acceptance is linked to these files. A new source must repeat the compare and play flow before inheriting that state; It is not enough to keep the same file name.
