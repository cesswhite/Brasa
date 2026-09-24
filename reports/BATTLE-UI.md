# Combat · Painted HUD and central result

| Before | After |
| --- | --- |
| Brand BRASA/ARENA and access Story Mode above the combat. | Both elements are removed. Menu is centered above; Story Mode is still accessible from the menu. |
| “Automatic attacks and abilities” text at the bottom. | Removed from the combat screen. |
| Names, levels and life without their own material. | Two dark leather and bronze painted frames, system typography, life jade/coral and compact figures. Bars of equal width, mirrored per side. |
| Victory separated from the action, at the foot. | Result and button form a group centered vertically and horizontally. The finished scene remains veiled behind, deliberately subordinated to the result. |
| Copy and scattered actions. | Victory/defeat/surrender, XP and continuation grouped together. Menu, Train, Companions and Summary maintain their actions. Wait/save prompts appear next to the button when needed. |
| Online presented as a replay selector. | In online combat the title and selector are hidden; Centered menu, shared HUD and result based on user side. The button returns to Arena online. Historical replays preserve their distribution. |

## Contextual continuation

- Arena: **Refight** retains the existing controller.
- Story: **Next Encounter**, **Prepare Retry**, or **View Legacy**, depending on campaign status.
- Online: **Return to Arena online** closes the presentation and returns to the existing section. XP and rating are supplied from the server response, without recalculating them.

The `game_combatant_hud.gd` component reuses the original surfaces and health bars of `GameVisualSystem`. No new images were necessary: ​​the existing painted atlas provides the edges and texture; Names and figures remain native text. There are no changes to combat rules, statistics, physical positions, inventory or rewards.

## Validation

- Layout: **2 107 checks**, seven sizes and three states, no errors.
- Results visibility: **1 782 checks**, victory and defeat in seven sizes; single reward, persistence and callbacks preserved. The previous criterion of keeping the entire silhouette out of the result is expressly replaced by the requested central overlap.
- Replays: **821 checks**, no failures; historical geometry, health/events recorded and navigation preserved.
- Result component: **160 checks**, no failures.
- Menu: **327 checks**, no errors.
- Specific native pass: **385 checks, 0 failures; 49 captures** in seven sizes, Arena, Story Mode and Online, both perspectives of the online result, controls and immutable records. Result in `work/battle-ui/native-final.log`.

[Report index](README.md). They all use disposable profiles and real engine combat with reduced initial opponent life for fast and reproducible results. Online uses the authorized record format, reproduced locally; **this is not a network match or a Cloudflare test**. The result screenshots already show the existing wounded art. No personal games were modified and no server changes were published.
