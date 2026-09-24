# Contact and depth of the fighters

The previous limit retracted any pixel that crossed the center, including the arm that was supposed to hit. The result was a punch in the air even though the animation tried to move forward. Arena, Story Mode and Replay now share a visual approach adapted to the pair and a drawing order that places the attacker in front.

| Appearance | Before | After |
| --- | --- | --- |
| Contact | Each complete silhouette had to remain in its half. | The arm crosses the center and points to the front third of the opponent's neutral torso. |
| Depth | The right rival was always drawn in front. | The attacker occupies the foreground of the couple during their action; FX and HUD retain their positions. |
| Recovery | The advance was canceled by the central limit. | Zooming in and out uses the existing animation clock. |
| Simultaneous actions | Two separate hits. | The crossing of centers is limited and the last event decides the visual priority. |
| KO/victory during contact | The change of pose could return the figure to its neutral position. | The horizontal position of the figure is preserved until the combat restarts. |
| Reduced movement | Poses without animated progress. | Keep that option and add the attacker's visual priority. |

No changes to stats, RNG, damage, engine times, progression, saves, backend, audio, or art. The roots of the actors and their physical scale by species remain fixed. Portraits without a linked rival retain the previous behavior.

## Evidence

[Report index](README.md), with native screenshots of Main and BattleReplayPanel on desktop and mobile. They are explicit fixtures in memory; They do not open user profiles or generate rewards.

`tools/contact_showcase.gd` reproduces the guard, travel, contact and recovery phases of pairs of different sizes; also checks reduced movement and combat endings. `tests/test_fighter_contact.gd` adds closeness, boundary, orientation, roots, pause, resize, concurrency, counterattacks, visual order, and reset checks.

| Validation executed | Result |
| --- | --- |
| Contact: 23 bodies, 7 sizes, both ways, 1.933 cases | 40.882 checks, 0 failures. |
| Final native captures from Main and Replay | 128 PNG, 528 checks, 0 failures; 108 instants comparable to the base. |
| Previous limits of figures without a partner | 185.472 checks, 0 failures. |
| Movement watches | 154 checks, 0 failures. |
| Status, KO and presentation | 91 checks, 0 failures. |
| FX Markers | 434 checks, 0 failures. |
| visual reproduction | 821 checks, 0 failures in 7 sizes. |
| Battle layout | 2.139 checks, 0 failures. |
| Existing movement presentation | 857 checks, 1 previous fault confirmed with previous code (Balam/HUD). |

The contact matrix preserves identical input/output hashes. Detailed results: `work/fighter-contact/validation.json` and `work/contact/after/observations.json`, from the workspace root.

## Limits of correction

The adjustment resolves horizontal distance and overlap. Does not redraw limbs: a giant against a very small character retains the hit height that his sprite has. Seven bodies have hand noted in the extension pose; the rest use the painted edge of that pose as a visual range approximation. This approximation is not presented as an exact anatomical socket.

The existing test `test_move_presentation.gd` finds a HUD overlap with `balam_salto` to 1224×792. Reproduced also with `work/contact/before/source/fighter_view.gd`: it is before this adjustment, not a contact regression.

The new matrix also records 14 guard intersections with the HUD boxes at 844×390 (Duna, Cora, Pedernal and Ascua). Their painted boundaries are identical with and without a partner; They are recorded as previous observations in the JSON. The framing was not changed to correct them within this contact setting.
