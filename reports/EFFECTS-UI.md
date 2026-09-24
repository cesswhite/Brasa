# Effects · Visible particles and collection previews

## Presentation and interaction

| Before | After |
| --- | --- |
| Particles drawn by the parent node, behind the opaque sprite. | Layer of particles on top of the illustration, spread along the sides and around the torso/feet, without energy circles. |
| Lantern had few sparks; the effects shared a very similar appearance. | Greater density and contrast, luminous nuclei, soft halos and differentiated shapes: sparks, fireflies, petals, rain, ash, leaves and crystals. They are born and gradually disappear. |
| The trail depended on the short shadow frame of the hit. | Maintains a tail of particles that fades for about half a second after movement. |
| Auras and trails mixed in a text list. | Auras / Trails sections and cards with samples of the real renderer, name, selection and requirement. Two or three columns depending on the space. |
| A locked effect only displayed a warning. | It can be tested on the companion. Save is disabled and Return recovers the draft without granting ownership. Color and skin tests are also preserved. |
| The trail could disappear before being appreciated. | Choosing it demonstrates a hit immediately and the section repeats the gesture every 2.2 seconds when the character is at rest. |
| Reduced motion suppressed trail display. | In the editor it offers a static sample of up to five particles, without automatic attacks. In combat it does not add trails in reduced movement. |

There are **7 auras and 5 trails active**, in addition to the No Aura / No Trail options. The combatant's forms and timing are preserved, with no changes to rules, damage, initiative, or statistics.

## New effects

| Type | Effect | Requirement |
| --- | --- | --- |
| Aura | Cempasuchil petals | Level 3 |
| Aura | Moon Drizzle | Level 6 |
| Aura | live ash | Story Mode encounter 12 |
| Aura | amethyst crystals | 6 League wins |
| Trail | blue kite | Story Mode encounter 30 |
| Trail | Leaves in the wind | Level 8 |
| Trail | copper powder | 5 League wins |

Levels and victories are achieved with one fighter; rewards still belong to shared inventory. The old conditions were not changed. The preview uses a separate temporary appearance: neither the button nor the controller allows you to confirm a locked test.

## Validation

- **3167 customization checks, 0 failures:** seven sizes, ownership, draft, confirmation, locked previews, and framing.
- **303 particle checks, 0 failures:** deterministic samples, maximum 28 particles per emitter, in front of artwork, trail persistence/fading, pause, reduced movement, and unequipped automatic demo.
- **1046 identity checks, 0 failures:** unlocks, integrity and persistence using disposable files.
- **172 FX checks and replay, 0 failures.** The old technical sample placed the Ascua 3 px transform outside the moving range. It was verified that the previous and current geometry were identical and 8 px was adjusted exclusively to the position of that sample, without changing the camera or the game characters.
- **74 focus checks, 0 faults.**
- **11 local server tests, 0 bugs:** new effects, palettes and identity operations. Thresholds, rejection of unowned equipment, and intact statistics are checked.

[Report index](README.md). Sixteen final native captures and four-second video, generated from 64 game frames with manual display clock. Fixtures in memory; No personal saves or remote data were modified. `work/effects-ui/demo/` is the final visual evidence; `native/` preserves the interface matrix prior to the final adjustment of the petal outline and fade.

Catalog version 4 exported and synchronized with the local backend. **The seven new effects, as well as the new colors, still require publishing the catalog on Cloudflare to unlock them online.** The rendering improvement for existing effects belongs to the game client.
