# Combat sequences for the entire squad

The 13 companions and the two bosses have 32 new poses per body: **480 frames in 30 transparent atlases**, integrated into combat and replay. The specification comes from [shared link](https://chatgpt.com/s/t_6ab06420418c8191a4a456f505cb9a2e); a [copy of reference text](ANIMATION-REFERENCE.txt) is retained. The link contains animation instructions, not a downloadable image pack.

![Real frames of the 15 bodies rendered by Godot](animation-roster.png)

Godot combat video (`animation-combat.mp4`; not included). Deterministic test match Mugo–Ascua, with explicit fixture data and no rewards to the player profile.

![Contact of a charge and independent effects](animation-desktop.png)

![Final combat frame on mobile](animation-mobile.png)

## What changes when playing

The actions cover preparation, movement, contact, monitoring and recovery. Fast and heavy blows, charges, jumps, replies, guards, techniques and signatures have different sequences. The phases use the times that the motor already delivers; The number of poses does not change the timing of the damage.

The reactions distinguish light blows, body blows, heavy blows, critical blows, recoil and knockdown. The takedown includes falling and lifting; the defeat ends in the canonical KO pose. The fatal event immediately breaks any pending action, including status ticks, and the result screen does not reset that crash. A non-lethal hit received during a self-action retains the authoritative attack and applies visual knockback before completing the pending reaction.

Eight painted effects are composed separately: light impact, heavy impact, critical, dust, slipstream, landing dust, energy and transformation corona. Strong impacts add a short visual pause and a limited jolt. The fight clock remains authoritative. Reduced motion mode eliminates scrolling, shaking, visual pauses and combat effects while maintaining poses and timing; cosmetic auras remain static. Panels pause actors and effects along with combat; repetition applies the same flow of events.

Ascua incorporates the visual transformation `ember_core`, with transition of 0,72 s and visual duration of 8 s. It does not alter statistics or add combat rules. The other bodies have poses of concentration and energy used by their Signature, and the record is prepared for future explicit transformations. This release does not grant new game transformations to the rest of the squad.

## Art delivered

| Bodies | motion bench | Reaction bank | Total new |
| --- | ---: | ---: | ---: |
| Nima, Luma, Mugo, Sira, Iria, Duna, Kiro, Neris, Taro, Balam, Tepa, Xuna, Copal, Ascua, Véspera | 16 per body | 16 per body | 480 poses |

Each generation used the approved atlas of the body as a reference. 32 canonical files registered at startup retain their hash. The new PNGs were copied directly from the generator output; its pixels were not retouched with scripts. `AtlasTexture` regions, pivots, and shared heights are in JSON. Crouching, fallen, or mid-air poses maintain the scale of the body and its virtual ground; Each pose is not normalized by its own height.

The integrated tool `image_gen` was used. It does not expose a version selector "2.5", so that version is not attributed to the results. The [asset manifest](../assets/sprites/sequences/manifest.json) lists destinations, sources, hashes, transparency, base memory, and frame names 480. The complete history of prompts and corrections is in [animation-provenance](animation-provenance); Prompts referenced as files are also included in full in [referenced-prompts.json](animation-provenance/referenced-prompts.json). The origin of the effects is in [fx-provenance.json](animation-provenance/fx-provenance.json).

| Bank | semantic names |
| --- | --- |
| Movement | `guard_shift`, `step_back`, `charge_crouch`, `heavy_windup`, `quick_windup`, `quick_extend`, `follow_through`, `recovery`, `dash_lean`, `dash_stride`, `jump_start`, `jump_apex`, `jump_strike`, `jump_fall`, `landing`, `guard_settle` |
| Reactions | `light_hit`, `body_hit`, `heavy_hit`, `critical_stagger`, `fall_start`, `fall_mid`, `grounded`, `getup_support`, `getup_kneel`, `getup_rise`, `low_health`, `victory_start`, `victory_peak`, `transform_start`, `transform_peak`, `transformed_idle` |

## Integration and cost

`FighterAnimationSet` resolves the equipped body, loading only the used banks and preserving a six-bank LRU cache. Before starting the fight or a repetition, the two benches of each actor are prepared. The static portraits still use the original atlas. 30 images occupy 43.811.042 bytes; loading them all simultaneously would mean some 180 MiB RGBA base, which is why they are not preloaded globally. The cache limit does not represent a total memory limit: original textures, effects, backgrounds, and active references also exist.

Reading visible boundaries uses native image operations instead of traversing a million pixels from GDScript. In the local cold load measurement, the two pilot banks went from approximately 93/109 ms to 22/25 ms; Pre-combat preparation avoids transferring that work to the first impact. It is a local measurement, not a guarantee for other devices.

Motion regions are framed with a fixed envelope that includes tails, wings, rotation, and recoil. Mobile, tablet and repetition share the calculation. At 390 px wide, the reference body remains about 136 px high and does not change scale when changing from rest to combat or result. The frame is not corrected by moving or resizing each pose.

To expand the system, banks and their sidecars are added to the `assets/sprites/sequences` directory, clips are registered to `FighterAnimationSet`, and effects are registered to `data/combat_fx.json`. The optional fields `move.presentation` and `event.presentation` allow you to choose reaction, effect, visual pause and camera. The attacker recovers the definition received in `move_started` using the `move_id` of the hit, both in Main and in replay, without modifying the authoritative event. Values ​​are validated; The explicit configuration of the event takes priority over that of the movement, and a KO or a failure retains its semantic priority.

## Reproducible verification

Consolidated result: **15.538 checks in nine validation runs, zero failures**. The six domain suites were repeated with the 30 banks installed; effects are added, KO by states and the continuous native tour.

The Ascua pilot passed native review before expanding the other 14 bodies. The complete delivery includes strict control that requires 30 banks, 480 real frames, transparency, valid regions and no fallback. Continuous scanning checks all bodies in both orientations and different screen sizes.

Combat tests use fixtures and isolated egress routes; They do not grant progress to the player's profile. The hashes of `combat_engine`, `combat_rules`, `story_progression`, `progression`, `fighter_identity`, `move_catalog`, and `campaign_config` match the base before this change. No damage, RNG, rewards or save formats are changed.

From the project folder:

```sh
BRASA_GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
"$BRASA_GODOT" --headless --path . --script res://tests/test_animation_sequences.gd -- --require-roster
"$BRASA_GODOT" --headless --path . --script res://tests/test_combat_fx.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_status_ko_presentation.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_battle_layout.gd
```

The final native execution passed **1.116 checks. without failures**, and saved 96 temporary observations of both actors: combat and repetition in 1360×880 and 390×844. Verify continuous advance of poses, contact, landing, pause, geometry and clock consistency. The screenshots come from the running scene tree; a pose was not forced to simulate contact. Actual capture times are recorded and may differ from the requested instant due to the cost of reading and saving the image.

The integrated presentation test passed **91 checks**, using real poison, burn and bleed events, with result and persistence replaced by memory. It also verifies that the visual configuration of a movement reaches the impact, its priorities, and the immutability of historical events and records. The effects passed **43 checks**. The complete atlas and sequence control passed **6.218 checks**, and the framing **2.139**, without lowering the previous minimum of mobile readability.

The [native results](animation-native-results.json) and its [sources manifest](animation-native-manifest.json) document the environment and hashes. On the test Mac, the median was 16,67 ms per frame and the 95 percentile ranged between 16,67 and 20,83 ms during captures; This tour includes reading and writing PNG and is not an isolated benchmark. The summary of all the suites in this delivery is in [animation-validation.json](animation-validation.json).
