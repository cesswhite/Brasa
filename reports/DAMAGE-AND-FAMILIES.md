# Families and visual damage — delivery

> **Historical document.** The hybrid damage described here was replaced by [full illustrated damage for 23 bodies](ILLUSTRATED-DAMAGE.md). This evidence and the family rules are preserved; Ascua's exclusive coverage and wear shader no longer describe the current render.

The first two requested implementations have been completed: hybrid damage with Ascua as a pilot and three families with six additional individuals. The original canonical sprites, progression, balance and existing identities are preserved.

## Integrated families

| Family | New individuals | Discovery and unlocking |
| --- | --- | --- |
| Taro / badgers | Roque, experienced adult; Sabino, master with a silver beard | Story Mode 21 and 61 |
| Duna / armadillos | Cora, reinforced armor; Pedernal, buckler veteran | Story Mode 22 and 62 |
| Bruma / cats | Ámbar, orange tabby; Nieve, veteran cream and charcoal | Story Mode 23 and 63 |

Each individual has 40 poses: eight base, sixteen movement and sixteen reaction. They are 240 poses in 18 banks. Pedernal retains his buckler in guard, hit, reaction, victory and KO. Equipment is appearance: it does not change range, damage, defense or statistics.

Subsequent meetings of each family use the corresponding experience. Bosses retain their unique designs. The six complete appearances share a catalog between Story Mode, customization and Arena; They are unlocked by beating their encounter. Complete sets were chosen to preserve the paint and animations: beard, clothing and armor are not pieces that can be mixed freely. Existing palette, aura, trail, and celebration options remain available.

The combat identity remains separate from the appearance. The server checks ownership and compatibility; Match history saves the complete appearance of each battle. Players who have already passed these milestones receive the new cosmetics upon resolving their next authorized match, using the existing achievement mechanism.

## visual damage

Four states per character: prepared, worn, damaged and critical. The initial configurable thresholds are 72%, 45%, and 22% life. The transition awaits the reaction; continuous blows cannot postpone it indefinitely. Healing does not clean clothes during the fight. Pause freezes the presentation, the results preserve the wear and a new battle restarts it.

23 visual bodies have material profiles and wear regions. Dirt, abrasion and fatigue are retained during movements and powers; They do not affect stats, inventory, RNG, or saves. No blood was added.

Ascua also has 56 poses with drawn damage: damaged reactions and full critical coverage of base, movement and reactions. Breaks do not disappear during charge, transformation, victory or KO. The rest of the cast uses surface wear and the existing fatigue poses; it is not claimed to have generated libraries of torn clothing for all characters.

## Visual check

| Before | After |
| --- | --- |
| Repetition of the original individual by species | Three families with recognizable age, clothing, brands and equipment |
| No persistent wear | Four states preserved until the combat ends |
| Feet cut by an irregular generated grid | Separation into transparent spaces, preserving complete figures |
| Painted checkered background | True transparency through authorized cleaning |

We reviewed 240 cells for individuals, families together, and 23 references from four states within Godot. Normalization uses one scalar per bank, canvas 512×512, pivot 256/448, and density 1.5; It never adjusts the size per frame. Differences between drawings are not presented as pixel-by-pixel equality. Bench surface regions without annotated anatomy use a visual approach; They do not alter FX anchors or geometry.

Seven native passes at normal speed covered six individuals and Ascua: 32 poses used per character, 651 captures and zero misses. The remaining cells were reviewed on the static sheets. No unreported transformations were applied to other species.

## Validation and server

- 10 861 Godot checks on damage, identity, customization, campaign, online interface, replay and visual continuity; zero failures.
- 366 server tests; zero failures. They include unlocking, rejection of unowned cosmetics, invariant statistics, Arena battle and immutable history.
- Catalog exported from Godot; Parity corpus of 300 battles and nine RNG sequences updated.
- Cloudflare staging updated: version `2761b4cc-373f-4dca-bb84-0074498447d3`. Service health and six appearances were verified in D1. Remote update wrote only catalog definitions and versions, without accounts, inventories, or personal progression.
- The catalog API is still protected by authentication; a request without credentials receives 401, accordingly.

Acceptance and hashes (`work/damage-families/acceptance.json`; not included) · Sources and family prompts (`work/damage-families/final-sources.json`; not included).

The generated originals and sources for each bank are in `work/damage-families/generated/`. The previous acceptance of 17 bodies is preserved without overwriting; This delivery adds six profiles and their independent acceptance.

## Pending access also closed

The login experience is complete and deployed: simplified entry, passkeys, device consent, guided recovery, and secure restore using Keychain on macOS. Fixed canceling during session save so you don't log back in after canceling. Final additional validation: API 27/0 and session/Keychain 16/0. [Access Report](AUTH-EXPERIENCE.md).
