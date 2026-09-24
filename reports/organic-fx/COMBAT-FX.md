# Organic combat particles

CombatFX retains its eight IDs and the hits, moves, states, pause, and camera APIs. The render no longer loads or draws the previous illustrated atlas: its regions remain as support for the `effect_texture` API, unused in normal rendering. No PNG was modified.

- `small_hit`, `heavy_hit`, `critical_hit`: narrow sparks directed by the blow, with small dispersion, braking and gravity.
- `dust`, `landing_dust`: light dust stuck to the feet and distributed horizontally.
- `dash_trail`: short particles released behind the body, losing speed and opacity.
- `charge_energy`, `transformation`: small embers that arise next to the body and rise, without rings, waves or large balls.
- States: Ascending smooth green healing, olive poison with mist drift, blue-gray guard/shield with narrow fringes; other states use low haze.

`emit_attached(id, actor, anchor="body", age=0, tint=WHITE)` follows `actor.effect_anchor()` by converting global to local coordinates of the FX. Loading uses hand, chest states, feet takeoff/landing and back movement. Only a weak reference is preserved: particles already emitted are released and extinguished, and slopes are eliminated when the actor disappears.

Reflected lighting uses `illuminate_effect` with intensity 0.065 and maximum duration 0.4 s. Delayed event offsets apply to light and particles. Reduced Motion disables these emissions and the camera; Pause freezes your watches.

Limits: 20 emitters, 320 reserved particles, 12 pending phases and a maximum of 24 particles per emitter. The current configuration expires in 0.17–0.74 s. The variation is analytical and does not use the chance of the motor or the global generator.

**129 checks passed, 0 failed** in `test_combat_fx.gd`. They include organic emission without loading atlas, sizes, coordinates with transformed parents, tracking vs. drift, events intact, global randomness intact, catchup, limits, pause, reduced movement, and actor release. Native visual review is done separately.

[Results and hashes](combat-fx-validation.json). No actual game was opened or written.

Readability adjustment after first capture: spark cores from 1–1.5 px and embers from 1.5–2.2 × 1.9–2.5 px before scaling; sustained colors and opacity, without large halo. In states and transformation, two-thirds of the births are distributed along the hand and back to distinguish themselves from the sprite, preserving anchored emission and free drift. Final desktop samples 1 (charge/contact) and 2 (fire/transformation) were approved by root. Main native passed 153 checks, 0 failures. Frozen code; Mobile and video QA are documented separately upon completion.
