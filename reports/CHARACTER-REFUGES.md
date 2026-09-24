# Each one, their refuge

The menu uses 21 original artwork: the 15 playable bodies and the six unlockable individuals. The body chosen in Customize has priority over the combat archetype. Each character appears integrated into their environment, busy in a daily routine; there is no superimposed animated fighter.

[Report index](README.md) · Full Prompts (`work/menu-refuge/prompts-v2.json`; not included) · Provenance, dimensions and hashes (`work/menu-refuge/art-acceptance.json`; not included).

## Visual changes

| Before | After |
| --- | --- |
| Almost identical buttons in a single grid. | Story is the main action; Arena and Arena online are secondary; growth and collection form a second group; settings, help and registration are discreet. The twelve routes are preserved. |
| Generic background and animated figure on top. | Complete illustration chosen by `appearance.body_style_id`, including all six individuals. No decorative props glued on top. |
| First proposal with mountains, vegetation and frames that are too similar. | Own habitats: chinampas, quarry, bush, desert market, kitchen, coast, forest, night jungle, patio, zacatonal, treetop, roofs, workshops and snowy cabin. Only Nima retains the original barrel. |
| Repeated gestures and poses. | Eat, wash a cup, plant a flower, prune, collect mushrooms, sort merchandise, cook, repair a net, split acorns, track, light a lantern, dig up roots, pick fruit, sleep, hang clothes, repair a bag, read, model clay, polish a shield, knead and sew. |
| Navigation always on the same side. | Column left or right depending on the composition; different trim point per scene. On mobile, the illustration occupies the upper area and the options continue below with a focus scroll. |
| Initial focus on closing. | Initial focus on the first available action. Esc, Tab, 48 px controls, disabled states during combat, pause, and reduced movement remain. |
| Generic foot. | Title and phrase specific to the place, with a lower veil to preserve contrast on the desktop. |

## Art and selection

The final PNGs are in `assets/ui/refuges/` and are registered in `data/ui_visual_manifest.json`. `data/character_refuges.json` defines title, phrase, focus and menu side. `WorldBackdrop` keeps your shared registry and loads only the active background; `GameHomePanel` continues to use typography, leather/brass, cards, header and Story Mode focus. The change of menu composition responds to the user's explicit request.

Images were generated with the built-in tool **image_gen**, using the canonical sprite as an identity reference. A model was not selected by name. The final PNGs are exact copies of the generated originals, without pixel retouching. The first repetitive batch is archived outside the game in `work/menu-refuge/rejected-v1/`; It is not used as final art. They are static scenes per body, not random variations or a dynamic simulation of tasks.

## Verification

- 21 funds: verified dimensions, original sources and registered hashes.
- `test_character_refuges.gd`: **4581 checks, 0 failures**. Selection by appearance, 21 bodies × four sizes, twelve destinations, keyboard navigation, full scroll, correct background loading and immutable profile. Twelve native captures of six characters, including compositions on both sides and a family variant.
- `test_visual_menu_navigation.gd`: **294 checks, 0 failures**. Real routes for Main, pause, availability, Esc, focus cycle and saving disposable saves.
- `test_world_visuals.gd`: **1453 checks, 0 failures**. Shared registration, materials, decorations and existing contexts.
- Shared components: **68/0**. Final Main audit with two additional native captures: **15/0**. Total of the final five suites: **6411 checks, 0 failures**.

Native Captures (`work/menu-refuge/native-final/`; not included) · Shelter Log (`work/menu-refuge/refuges-final.log`; not included) · Navigation Log (`work/menu-refuge/navigation-final.log`; not included) · Environment Log (`work/menu-refuge/world-final.log`; not included).

The evidence comes from isolated fixtures. No changes were made to personal games, combat rules, progress, or server status.


## Post adjustment: direct menu

At the user's request, the header, name/level, "The path continues" and "The refuge" were removed. The button shows **Start story** when that character has not advanced and **Continue story** if they already have attempts or progress, even at the beginning of another chapter. Does not check another character's Arena level or campaign. Pressing it opens the history of the selected character, preserving the other campaigns; a failed save restores the previous selection.

The white outline of the main button was replaced with a variation of gold leather when brought into focus. The twelve paths, Tab, Esc and touch targets are preserved. The historical gallery screenshots correspond to this setting; the previous ones remain in `work/menu-refuge/native-final/` as historical evidence.

Main Current Screenshot (`work/menu-cleanup/native/menu-1360x880.png`; not included) · Mobile (`work/menu-cleanup/native/menu-390x844.png`; not included) · Navigation Tests (`work/menu-cleanup/navigation.log`; not included) · Background Tests (`work/menu-cleanup/refuges.log`; not included).
