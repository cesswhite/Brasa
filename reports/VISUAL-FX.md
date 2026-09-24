# Synchronized FX and ground contacts

The particle renderer retains its organic style and eight existing effects. Added `dust_small`, `dust_medium`, `dust_heavy`, `footplant_dust`, `dash_dust`, `slide_dust`, `knockback_dust`, and `stone_debris`. The old radial atlas is not drawn. The grains have birth and history of the world, they never remain attached to the character after being broadcast.

`MoveVisualProfile` describes animation, composite variant, anatomical track, impact, wake, ground, reaction, camera, hit stop, sound and transformation requirement. Its markers use phases and fractions of the actual times of the movement; they do not create attacks, damage, rewards, or new combat results.

`CombatFX.play_move()` is the only scheduler of those markers for existing combat and replay calls. One cursor per action processes all cross markers, even at 20 FPS or in x2 playback. Its identity includes actor, side, time and move ID. Reconciling the same event does not reissue it; entering late preserves the age of the particles still visible and discards the expired ones. `clear()` is the explicit reset for a seek. Synthetic events without time/ID represent a single action until that reset.

Markers include left/right foot contacts, takeoff, landing, glide start and end, preparatory rollback, loading, anatomical FX start, forward, follow through, and recovery. Takeoff and landing are linked to the animation phases. The emitter consumes `FighterView.effect_anchor()` to obtain the projected contact on the ground, separate from the position of the foot in the air. The particles settle at their own birth height and do not cross the floor.

The Impact API adds an optional argument: `play_impact(at, presentation, actor_scale, facing, age, target_actor)`. With a defender available, heavy/critical produce powder and knockback/knockdown/KO use drag powder; knockdown/KO add some small fragments. Damage contact and primary hit continue to come from the existing authoritative event. The ground reaction accompanies the beginning of that reaction: it is not intended to simulate a new physical collision when falling.

`illuminate_effect()` is not called from `CombatFX`. Charge, states and transformation emit particles without illuminating the entire body. The paired anatomical layer belongs to `FighterView` and follows its frame/transform. `AttachedEnergyTrack` generates a transparent RGBA texture of 512×512 from the core and hand sockets measured at the current pose of Ascua. The core radius is 12 px, the hand radius is 10 px, and the alpha never exceeds 0.35, even if both regions overlap. There is no white core or large ring; Outside these regions all pixels are transparent. If the annotated core is missing, its location is not invented. An LRU cache retains at most 16 textures; the generator does not read or modify the body image.

`FighterView` applies intensity from its own load or morph clock, with an option to turn off FX during review. The two layers have exactly the same transform, reflection, pivot and offset; pause and hit stop cannot separate them. The pilot profile uses canvas 512, pivot [256,448] and density 1.5, supplied by the canonical pipeline. The `ember_core` shape reuses this anatomy and changes the superimposed energy.

The limits remain 20 emitters, 320 particles, and 12 pending actions. Each action saves a cursor over a compact profile (maximum 9 markers in current profiles), instead of occupying a pending entry per particle or callback. Deduplication memory retains 64 completed actions and 128 diagnostic history markers. Pause freezes cursors and particles; Reduced movement cleans emissions, programming and shaking. Actors are preserved through weak references.

## Validation

Fixtures do not open Main, saved games or remote accounts. `test_combat_fx.gd` verifies the 16 effects, absence of radial atlas and global light, budgets, coordinates between transformed parents, catchup, pause, movement reduction and RNG conservation. `test_visual_fx_markers.gd` checks the same markers at 20/60/120 FPS in x1/x2, deduplication, late recovery, floor, horizontal reflection, free drift and actor release. `test_organic_fx.gd` preserves the previous particle and repeat regression. `test_attached_energy_track.gd` requires at least 16 real poses with annotated core and tests `FighterView` of Ascua in seven loading moments, facing both sides: shared canvas, synchronized intensity, pause, hit stop, reduced movement and exact comparison of body bytes when turning FX off and on.

These tests validate the FX system; visual inspection is carried out separately. The Ascua pilot has already passed native playback at full speed and review of its final sources, including motion-annotated sole contacts 32. The charge keeps stone, metal and fabric legible, and the dust is born on the ground. See report by bank (`work/visual-consistency/roster-native/acceptance-current.md`; not included), final video (`work/visual-consistency/ascua-final.mp4`; not included) and evidence of contacts (`work/visual-consistency/roster-native/ascua/movie/footplant-detail.png`; not included). The video uses MovieMaker at 60 fps and serves as visual evidence; The actual speed test was run without recording or forced frame rate.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path outputs/Brasa --script res://tests/test_combat_fx.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path outputs/Brasa --script res://tests/test_visual_fx_markers.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path outputs/Brasa --script res://tests/test_organic_fx.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path outputs/Brasa --script res://tests/test_attached_energy_track.gd
```

The position of a late marker is evaluated in the pose available when it is dispatched. Its age is exact, but a historical trajectory of sockets is not reconstructed when several frames were omitted; Frequency tests guarantee unique events and stable ground, no pixel-by-pixel identity between refresh rates.
