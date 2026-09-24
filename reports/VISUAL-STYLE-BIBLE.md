# Brasa · Visual interface bible

**Authority: the approved Story Mode.** This document describes the language of its five tabs and the shared system that extends it to the rest of Brasa. It doesn't change the rules of the game. The initial diagnosis was based on code, manifest and captures; The migration was later verified with local fixtures and native captures, without modifying production.

Sections 1–11 preserve the analysis of the original reference; section 12 defines the implemented APIs. The progress figures visible in the screenshots are fixture data, not balance specifications.

## 1. DNA that must be preserved

Brasa features **places inhabited by fighters**, with information and actions readable within those places. Story Mode works because the environment occupies the entire screen, the figure has presence and the controls share their materials.

- 2D digital painting with visible brush, worn surfaces and sharp silhouettes. Texture comes from art; does not require an additional layer of noise over the interface.
- Stone, wood, fabric and dark leather with copper/bronze hardware. Stitching, small gems and rivets express artisanal manufacturing.
- Warm lanterns, petrol blue shadows and darker backgrounds than the characters. Ambient light unites figure, ground and architecture.
- Narrative tone serif titles; Readable sans body for decisions, statistics and actions.
- A clear focus per view: rival in Route, decisions in Workshop, techniques in Movements, companion in Shelter, achievement preserved in Legacy.
- Visible materials where they help: navigation, actions and key callouts. The lists of attributes, techniques and companions let the scene breathe.

The Route hierarchy is the main reference: stable header and navigation; rival and information in the first block; compact tour after; main action fixed to the foot. The rival does not need a large rectangular container behind it.

## 2. Sources and precedence

| Source | What it defines |
| --- | --- |
| `scripts/ui/story_panel.gd` | Typography, semantic color, composition, responsive behavior, content and readable states. |
| `scripts/ui/world_visuals.gd` | Roles of material, nine-slice, focus, states, load sharing and conditional decoration. |
| `scripts/ui/world_backdrop.gd` | Full-bleed background, aspect conservation, veil, decoration order and loading of the active context. |
| `data/ui_visual_manifest.json` | Backgrounds, tints by location, real regions, margins, aliases and object conditions. |
| `assets/ui/ART-DIRECTION.md` and `GENERATION-PROMPTS.json` | Artistic direction and provenance of the seven original PNGs. |
| Story Mode captures | Evidence of composition and legibility; They do not replace code when displaying an older version of the data. |
| `reports/organic-fx/COMBAT-FX.md` and current render | Recent FX Limit: Organic flecks and sparks, no ornamental rings of fire. |

If a new component conflicts with an old capture, the current code and the user's recent instruction prevail. If a local exception differs from the shared system, document it before converting it to another global token.

## 3. Color and light

### Reading palette

| Current constant | Value | Observed role |
| --- | --- | --- |
| `CREAM` | `#F5E7CF` | Main text, rival name, secondary control labels. |
| `GOLD` | `#EFB66F` | Chapters, encounters, XP, recommendations and section titles. |
| `TEAL` | `#7DD7BD` | Strengths, growth, availability and completed progress. |
| `MUTED` | `#9AB3AC` | Metadata, secondary explanation, level and context. |
| `CORAL` | `#ED997F` | Weakness, risk and save notice. |
| `DARK` | `#0C2228` | Base color for dark surfaces; it does not define every background. |
| `SURFACE` | `#153137` | Flat support surface present in local dialogue. |
| Primary action text | `#152329` | Dark text on amber strap. |
| Shared focus | Amber `#EFB66F`, Alpha `.22` | Inset highlight with 4 px, no outer outline. |

These colors have meaning. Do not use coral for a neutral data or jade for a dangerous action. Strengths and risks always have words: color is not the only indicator. Do not replace this palette with neutral grays, pure white or new accents on each page.

### Variation of the place, from the manifest

Context accents are data available from the record. Story Mode also uses its semantic constants for the text; It should not be claimed that all text automatically changes to the local accent.

| Context | Background | accent | base shadow | background tint |
| --- | --- | --- | --- | --- |
| `route_journey` | `journey` | `#EFB66F` | `#0B2026` | `#FFFFFF` |
| `route_storm` | `storm` | `#A4D5E6` | `#101E2C` | `#FFFFFF` |
| `route_late` | `storm` | `#DFC891` | `#101E26` | `#E8D7C0` |
| `route_boss_journey` | `journey` | `#EFB780` | `#281B17` | `#FFE4C3` |
| `route_boss_storm` | `storm` | `#AFCEDF` | `#151B2F` | `#E5DEF4` |
| `route_boss_late` | `storm` | `#EDB39B` | `#251422` | `#F4C8C1` |
| `workshop` | `workshop` | `#ECC18D` | `#221A19` | `#FFFFFF` |
| `moves` | `workshop` | `#CBB398` | `#181B23` | `#D5E2EF` |
| `camp` | `camp` | `#F0BC84` | `#211C1A` | `#FFFFFF` |
| `legacy` | `archive` | `#DECDB0` | `#171D28` | `#FFFFFF` |

`route_boss` remains a supported context; Normal selection uses the boss variant corresponding to the chapter. A boss keeps the location of his route, adds insignia and increases character presence; It does not force an alien visual scene.

### Veils, depth and contrast

`WorldBackdrop` draws an opaque background with `STRETCH_KEEP_ASPECT_COVERED`: occupies the area, maintains proportion and crops as necessary. It doesn't stretch characters or controls along with the image.

The vertical veil has RGB `(0.015, 0.03, 0.04)` and `(position, alpha)` stops of `(0, .68)`, `(.42, .14)`, `(.76, .20)`, `(1, .88)`. It keeps the center clear and protects the header and footer. Story Mode adds a horizontal RGB veil `(0.015, .025, .025)`: alpha `.66` on the left, `.42` on `.46` and `.14` on the right of Path; in the other tabs the latest alpha is `.58`.

Preserve the light of the ground and the character. Resolve the contrast with the position of the text and the necessary veil; Reserve opaque frames for an important grouping or dialogue. The numbers above are the current reference, not a guarantee of contrast for any future cuts.

## 4. Typography

| Observed role | Family and logical size |
| --- | --- |
| Default body | `Avenir Next`, fallback `DejaVu Sans`, then `Arial`; 15 px. |
| Explanatory text and metadata | Same sans, normally 14 px; compact data 12–13 px. |
| Section label / encounter | Sans, 12 px, short caps, amber. |
| Chapter Title | `Georgia`, fallback `DejaVu Serif`; 29 px, 20 on phone or short height. |
| Main name in Route | Serif 42 px; 32 on phone or short height. |
| Encounter title | Serif 20 px, amber. |
| Workshop / Shelter | Serif headlines 30–32 px; secondary and notable figures 20–22 px. |
| Navigation | Sans 15 px; 13 on phone. |
| Name in companion list | Serif 20 px; sans role 13, level 12, path 11. |
| Route markers | Number 15, name 13, detail 10 px. |

The current helper applies serif to any tag 20 px or larger. To centralize, convert uses into explicit roles—for example page title, protagonist name, block title, body, metadata, and label—while maintaining their appearance first. These names are an organizational proposal, not existing APIs.

The families are `SystemFont`: today there is no bundled font that guarantees identical metrics on all systems. Keep fallbacks and verify widths before distributing to another platform. Do not copy figures of typographical weight that the code does not establish. A future built-in font requires resolving its license and checking it against Story Mode.

The 10–11 px route labels are an observed compact exception; do not convert them into the general size of error messages, requirements or controls. Important text supports line breaks. The ellipsis is reserved for compact labels, with full detail accessible.

## 5. Materials and controls

### Existing Atlas

`assets/ui/shared/surfaces-v1.png` contains eight pieces: amber primary strap, petroleum secondary strap, regular panel, boss panel, normal badge, boss badge, separator and elite badge. The regions are the actual registered boxes, not eight ideal grid cells.

The buttons retain leather, stitching and metal finishes; The panels retain reinforced corners. The insignia maintain their proportion when drawn. Do not embed names or numbers in these PNGs.

| Current Role/API | Nine-slice L/T/R/B | Padding L/T/R/B | Use |
| --- | --- | --- | --- |
| `primary`, `secondary` | `24 / 8 / 24 / 8` | `14 / 10 / 14 / 10` | Complete actions with finishes. |
| `navigation`, `navigation_active` | `8 / 8 / 8 / 8` | `3 / 8 / 3 / 8` | Central cutout of the same straps; It preserves seams and leaves space for text. |
| `panel`, `boss_panel` | `26 / 22 / 26 / 22` | `18 / 16 / 18 / 16` | Featured grouping and special framework. |

The surface atlas is scaled once to `.35` in memory; the original PNGs are preserved. The margins are those used by the current render on that texture. Regions and scale must have a single source in the manifest.

Current aliases: `danger → secondary`, `reward → panel`, `dialog → boss_panel`, `tooltip → panel`. `danger` adds tint `#DC9A86`; `navigation_active` adds `#FFE6B9`. A material alias does not itself implement a dialog, tooltip, or error state.

### Shared states

| Status | Current presentation |
| --- | --- |
| Normal | `#FFFFFF` dye. |
| Hover | `#FFF3DB` warm tint. |
| Pressed / hover pressed | `#B9A789` dye; It does not change size or silhouette. |
| Disabled | Material `#717878`, text `#9CA9A6`; The cause is expressed in text when it affects the decision. |
| Selected | Amber Primary Navigation Strap; dark text. |
| keyboard focus | Transparent background, 2 px border `#F8E8B9`, 5 radius, 2 px expansion. |

Button text shadow is black to alpha `.2` on primaries and `.8` on secondaries, vertical offset 1 px. There is no general scale of floating shadows; the main depth comes from the painted materials and lighting.

`apply_button` sets minimum 44 px; Story Mode requests 48 px. Extend with 48 px as reference height of actions, selectors and close buttons. The controls maintain their silhouette in all states: a companion token should not transform into a giant strap when receiving hover.

### Open surfaces

Workshop and Moves are grouped together with subtle columns, titles, and dividers, with no individual panel around each stat or technique. In Refuge the tiles use translucent petrol-blue background and bottom border: normal alpha `.16`, selected `.42`, hover `.55`. The selection is recognized by the amber border of 2 px; preserves native focus. This treatment is a deliberate variant for figures, not a replacement for the action buttons.

## 6. Responsive spacing and composition

The observed scale groups distances of `4, 8, 10, 12, 16, 18, 20, 24, 32, 36` px. Use them according to function; not artificially reduce it to a grid that changes Story Mode.

| Relationship | Current measurement |
| --- | --- |
| Outer margin | 32; 16 on phone or short height. |
| Title and metadata | 4 separation. |
| Usual internal stack/navigation | 8. |
| Sections, footer, and standard grid | 12; 10 shell with low height. |
| Header | 16 between groups. |
| Rival and information / Refuge header | 32 horizontal, 12 vertical. |
| Workshop | Bank 24; attributes 36 horizontal and 18 vertical. |
| Footer | Two actions, separation 12; primary with expansion ratio 1.4. |
| Route | 96 px row, 92 px marker target; max badge 48 px. |

Existing breakpoints: phone if width `<600`; short layout if height `<540`; Path stacked hero if width `<900` and height not short. The width `<1100` reduces columns of certain grids. They are different content rules, not a single global scaling.

- **Desktop:** reading on the left, large rival on the right; reserved height 420 px, 470 for boss. Horizontal route with the actual number of chapter encounters.
- **Phone and tablet stacked:** character before information, height 270 px or 290 for boss; Scrollable content and footer always visible. Navigation retains five options with short names: Route, Upgrades, Moves, Companions, Legacy.
- **Horizontal with low height:** two Path columns, 160 px figure and reduced top metadata. Priority to decision and achievable actions.
- **Mobile route:** four markers per row and height `ceil(cantidad / 4) × 96`; ten matches require three lines. IDs, order, name, level, status and enemy type are preserved. The code connects markers of the same row; it does not represent a continuous path between rows.
- **Shelter:** two companions per row on the phone, three under 1100, four on desktop; minimum height 242/280. The large selected portrait and its description precede the collection.
- **Workshop and Movements:** one column on the phone, two outside of it. Legacy uses two or four column metrics.

The screen does not have horizontal scrolling; `ScrollContainer.follow_focus` accompanies the focus. The vertical scroll reaches the last requirement and the last row without hiding them behind the footer. Keeping actions in the footer does not allow you to delete description, rewards or recommendation so that everything seems to fit.

## 7. Images, figures, icons and objects

### Grammar of places

| Section | Composition that is preserved |
| --- | --- |
| Initial route | Road, lanterns, architecture towards edges; space for the figure and dark reading area. |
| Storm/later routes | Roots, iron, moss, wet stone, mountains and cold light; localized heat from lanterns. |
| Improvements | Stone and wood workshop, workbench; statistics as decisions about that space. |
| Movements | Same workshop with cooler tint; useful repetition of place, not another arbitrary background. |
| Companions | Open shelter, tent, shared floor, complete figures. |
| Legacy | Stone archive, depth of steps, relic and memory of the companion. |

The figures are instances of the fighter renderer. They preserve identity, appearance and animation; the UI does not replace its body with an illustration embedded in the background. The shared framing is obtained from `CharacterVisualProfiles.portrait_scale` and `portrait_envelope`: rest for tokens, attack for the move test, and victory for Legacy. The physical size of each species comes from `world_height`; Each silhouette is not enlarged to fill its box. The pivots share the floor, with space for feet and extremities. The victory pose reserves the raised arm and its movement. Do not trim antennas, tails or fists to make boxes uniform.

The insignia are painted objects: normal medallion, elite diamond piece and boss frame with flamed finial. They are accompanied by text "NOW", "COMPLETED", "UPCOMING", "ELITE" or "BOSS". The functional circle highlighting a route marker is not a combat fire effect; do not extend it to ornamental auras.

Native symbols `×`, `+ 1`, growth arrow and badge star cover simple actions. Do not add foreign style icon packs by default. Decorative icons ignore pointer and focus; the interactive area belongs to the native control.

### Decoration with real meaning

There are six source objects in `props-v1.png` and seven usage definitions in the manifest. A maximum of three are displayed, one per anchor, ordered by priority. Existing anchors: bottom left, bottom right and top right; 8 px minimum margins and `.55–1.25` adaptive scaling.

| Object/use | Current condition |
| --- | --- |
| Tepa fabric / Balam bandages | `appearance.body_style_id`, with `character_id` as fallback. |
| Brazier by Ascua | Eight encounters completed. |
| storm relic | Sixteen encounters and ownership of `palette:luna`. |
| Backpack | One encounter completed or the Jade palette equipped. |
| Arena medal | Ten real victories supplied by the caller. |
| Equipped Lantern | `aura:farol` possessed and `aura_id:farol` equipped. |

Conditions only select decoration. The visual layer doesn't read saves, doesn't grant rewards, and doesn't invent victories to fill a corner. If it does not receive an optional data, the object remains off. No prop covers text or an action in a narrow format.

## 8. Motion and FX

Story Mode navigation changes state directly. There is no global system of springy inputs, hover zoom, or tab transition duration that needs to be invented when centralizing. The life of the screen comes from the character, the place and the immediate response of the control.

To keep combat language up to date:

- Narrow, directional sparks on contact; light dust near the feet; small embers rising near the body.
- No expanding rings, closed waves, large glow balls or fiery frames to compete with the silhouette.
- The turn indicator uses diffuse ground glow and small readable rhombus; does not require an ornamental circle.
- Charge, Impact, Recovery and KO follow existing events and clocks. The style never advances damage or modifies results.
- Pause freezes presentation clocks. Reduced motion eliminates unnecessary particle emissions and camera motion; preserves state, focus and useful messages.

Current CombatFX figures are subsystem limits, not sizes for UI icons: 20 emitters, 320 reserved particles, maximum 24 per emitter, and approximate configured duration `.17–.74 s`. The reflected illumination is brief and dim. For new FX, reuse organic rules and validate mobile clarity before increasing quantity or brightness.

## 9. Product states and accessibility

Visual adaptation preserves the causes and actions of each state. Story Mode now distinguishes blocking, maximum reached, selection, chosen talent, practice without reward, retry and text save error.

For login, network, inventory, history and other future screens, reuse the same hierarchy: short title, concrete explanation and contextual action. It is an extension rule, not an assertion that StoryPanel implements authentication or reconnection.

- An unavailable action maintains readable label and reason. Do not communicate error only by fading the texture.
- Preserve keyboard states and visible focus in selectors, lists, dialogs and close buttons. An atlas does not replace control semantics.
- Decorative blocks use `MOUSE_FILTER_IGNORE` and `FOCUS_NONE`; They do not intercept scrolling or clicks.
- Contrast text against the already composed background, not just against the fallback hex. This audit does not certify contrast ratios.
- Keep long data in native text; test usernames, translations, large numbers, and complete requirements.
- Critical notices should not depend on an ellipsis or a mouse-only tooltip.

## 10. Extraction plan identified in the base

The registration of materials and places already exists. The first phase is to share the presentation before migrating pages:

1. Elevate semantic colors, families/sizes by role and observed measurements to a common source, preserving Story Mode values.
2. Keep `WorldVisuals` as access to surfaces, states, and illustrations, and the manifest as a source of regions and contexts.
3. Formalize open variants for companion list, statistical and technical queue; Share all your statuses, not just the normal background.
4. Extend that family to text input, open dropdown, list/table, prompt, empty state and dialog. Reuse existing oil material, seam/edge and bulb; Do not produce a new atlas before checking that it is missing.
5. Then migrate each screen with a native comparison against Story Mode, maintaining callbacks, data, focus, scroll and interaction limits.

### Exceptions to the base that should not be multiplied

- The redistribution commit uses a local `StyleBoxFlat` instead of the shared alias `dialog`.
- Closing `×` deletes only the normal background; other states come from the inherited belt. A future icon control must define them consistently.
- The chapter `OptionButton` shares the closed surface, but does not establish by itself the entire aesthetic of the open popup.
- The row dividers are native dim; The illustrated atlas separator exists, but is not required between each statistic.
- The focus of the Route marker is drawn locally; Ordinary buttons use a shared inner amber fill, with no outer outline.
- Fonts, spacing and colors are split between StoryPanel and the registry. Do not create a second palette while extracting.

### Real asset needs

**No new PNGs are needed to get started.** There are five environments, two atlases, and enough surface variants to build the common system. Later moves and routes already demonstrate reuse via context/tint.

Only commission additional art when there is a new composition that the current funds do not support, or a recognizable object that cannot be expressed with existing symbols/materials. A new mode does not automatically require another fund. The current need for consistent fonts is for packaging/licensing, not imaging.

A future asset must preserve paint, materials, light and useful space; lack embedded text; provide regions, margin, transparency where appropriate and provenance. Opaque backgrounds; objects and surfaces with real alpha. Load only the active place and keep the atlases as shared, without preloading all environments.

## 11. Criteria to accept each extension

Compare at least the seven formats already used by Story Mode: `1360×880`, `1224×792`, `1920×1080`, `768×1024`, `390×844`, `430×932`, `844×390`.

- The first glance identifies place, main figure or decision and available action.
- The typography, colors, material and their states come from the shared system; exceptions are justified.
- The scene retains its appearance, the characters retain a coherent scale and no pose is cut.
- Header, five tabs and footer do not overlap; the last row and the last requirement are reachable.
- Try normal, hover, down, focus, disabled, selected, empty, error, and long text, as appropriate for the screen.
- Inspect Normal Route and Boss, Ten Nodes on Phone, Workshop, Blocked Techniques, Selected Companion, and Full/Empty Legacy.
- Check pause and reduced movement where there is animation; preserve original watches and events.
- Confirm that objects respond to real data and that a decoration does not capture interaction.

The visual review complements the functional tests. An approved assertion does not by itself demonstrate contrast, absence of breaks, or coherence of the material.

## Verified references

- [StoryPanel: color and navigation](../scripts/ui/story_panel.gd#L25), [typography and layers](../scripts/ui/story_panel.gd#L220), [responsive](../scripts/ui/story_panel.gd#L318), [Path composition](../scripts/ui/story_panel.gd#L460).
- [WorldVisuals: materials and states](../scripts/ui/world_visuals.gd#L93), [WorldBackdrop](../scripts/ui/world_backdrop.gd#L25), [manifest](../data/ui_visual_manifest.json), [art direction](../assets/ui/ART-DIRECTION.md).
- Screenshots reviewed: [Desktop Route](story-world-desktop.png), [Mobile Route](story-world-mobile.png), [ten encounters](story-world-mobile-route.png), [boss](story-world-boss.png), [Workshop](story-world-workshop.png), [Legacy](story-world-legacy.png), [Shelter with Bruma](organic-fx/live/story-bruma-1360x880.png).
- [Current Organic FX](organic-fx/COMBAT-FX.md), [ArenaView Diffuse Shift](../scripts/arena_view.gd#L214).

The previous lines identify the inspected version; They may move during subsequent removal of the system. Scope and provenance notes: `work/visual-system/style-notes.md`.


## 12. Central contract implemented

The 10 section preserves the pre-migration diagnostics. The current implementation is based on these sources; themes should not be created per screen:

| Source | Responsibility |
| --- | --- |
| `data/game_visual_tokens.json` | Semantic palette, 4/8/12/16/24/32/48/64 spaces, font hierarchy, touch height, focus and transition duration. |
| `scripts/ui/game_visual_system.gd` | Shared theme, fonts by role, surfaces, open cards, bars, selectors, engraved icons, veils and section entry. |
| `data/ui_visual_manifest.json` + `world_visuals.gd` | Original regions, nine patches, states, location backgrounds, and item eligibility. |
| `world_backdrop.gd` | Distant background, illustrated environment, eligible objects and dark veil. Only loads the active environment. |
| `components/game_fighter_preview.gd` | Real figure with identity/cosmetics; Common resting chamber and scale between species, derived from the renderer presentation profiles. |
| `components/game_section_header.gd` / `game_badge.gd` | Header hierarchy and badges with semantic text and Story Mode material. |
| `components/game_modal.gd` | Single dialog: frame, overlay, title, closure, scroll, focus and return. `use_location_layout()` reuses the contract in an open illustrated section. |
| `components/game_overlay_focus.gd` | Tab/Shift-Tab within the active screen; respects open dropdowns and Escape without double actions. |
| `components/game_battle_result_panel.gd` | Reward frame, headline, explanation and XP; receives real values, without calculating rewards or directing animations. |

`Visuals.apply_button(control, role)` defines all states for `primary`, `secondary`, `danger`, `navigation`, `navigation_active` and `icon`. A closure uses `icon`; one list card use `apply_card_button`, not other strap. The selected state combines open background and amber line. Disabled preserves readable text. `apply_option` also themes the open dropdown; `apply_progress` distinguishes XP, own life and rival life within the same lane.

The Theme covers panels, tooltips, RichTextLabel, fields, lists, tabs, sliders, checks, scrollbars and menus. The small control icons are native cream/bronze markings with dark shadow and common weight; narrative insignia continue using the painted atlas. No other icon pack was introduced.

The sections provide place and accent: shelter for Menu/Token/Companions, workshop for creation/inventory/improvements, patio for Arena/Online, archive for memories and Legacy. Matchmaking reuses Online challengers; future classifications have recorded context, but this migration does not invent a classification that the server does not offer.

The common opening uses a fade of 0.18 s when movement is allowed. Hover, pressure and selection respond immediately through the material; there's no bouncing or decorative scaling to move touch targets. The renderer maintains its own clocks of actions and energy linked to the body. Size differences between species are not erased to fill out a card.

Arena and replays share top and bottom `Visuals.battle_veil`. The combat retains its frame and space of actions, with the illustration in blood behind the HUD. Replays show the setting, names, clothing, and events saved from the original match; Playing does not update identities or deliver rewards.

To add a screen: start with `Visuals.theme()`, choose context with `mount_background`, use shared roles and components; provide actual identity/ownership data; validate keyboard, scroll and narrow sizes. Register the screen to `tests/test_visual_screen_audit.gd` and `work/visual-system/review-screens.json`, and regenerate the [Report](VISUAL-SCREEN-AUDIT.md). Browser/system security controls are left out of this native Theme.

## 13. Menu Personal Shelters

At the user's request, the main menu stops overlaying an animated portrait and uses one everyday illustration per body. Preserves the materials, typography, and interaction states of Story Mode. The consistency between characters is limited to pictorial language; habitat, light, activity, camera distance and character side should clearly distinguish them. The composition of buttons can go to the right or left depending on the art. The mobile retains the focus of the character and puts the navigation below. See [the catalog and its screenshots](CHARACTER-REFUGES.md).

## 14. Contact and depth during combat

Arena, Story Mode and replays link the pair via `FighterView.set_combat_lane(limit, opponent)`. Guard separation remains stable; During an attack, the sprite can pass through the central boundary to visually reach the front third of the opponent's torso. The approach uses the same clock of anticipation, travel, impact and recovery. It never shifts combat root, changes species scale, or recalculates damage, logical range, or initiative.

The target is calculated from the noted neutral torso and the roots without advancement. It does not pursue the movement of the other attacker. The visual scope uses the annotated hand socket or, in packages without that annotation, the leading edge of the striking pose. This visual approach does not become anatomy or a hitbox. The height of the blow still belongs to the illustration; The feet are not sunk nor the character is deformed to match heights.

During travel/contact/recovery, the attacker is drawn in front of the opponent. Simultaneous contacts are ordered by presentation events and keep the centers of the bodies separate. Only the two drawing positions are exchanged; FX and HUD remain on top. Ties maintain a stable orientation. If a result interrupts an attack, the figure retains its horizontal position until the next combat, without teleporting back to its lane. Reduced motion maintains your poses and visual priority, without adding zoom.

Reproducible comparison: [Report](COMBAT-CONTACT.md). Scope, validation and limits in [COMBAT-CONTACT.md](COMBAT-CONTACT.md).


## 15. Persistent Illustrated Damage

The current damage authority is the character's entire artwork, not spots or streaks generated on top of its surface. The 23 bodies have a wounded family of 40 poses: 22 bodies with new art and Ascua with its three critical-v1 banks reused. Damaged and critical (grades 2 and 3) share that same family; 1 grade preserves clean art and fatigue poses. Don't advertise three different levels of art when they exist clean and wounded.

The wounds respect the paint, the material and the identity: torn clothes, tired or bruised faces and fatigued postures; chipped stone for stone bodies. Do not introduce blood, new equipment or floating vector marks. Cosmetic dyes and impact flashes maintain their independent functions. The status persists during moves, reactions, victories, and KOs; Healing does not restore items mid-battle.

Each bank retains a common scalar, cell 512, pivot 256/448, and density 1,5. Slouching does not authorize increasing the scale. The metadata corresponds to the actual wounded frame. Projected supports and inherited anchors are identified as approximate; in the absence of a notated hand the painted edge of the striking pose is permitted as a visual approximation, never as certified anatomy or logical scope.

Acceptance requires true alpha, transparent gaps and no halos on light and dark backgrounds, as well as native contact and continuity review. The [Report](ILLUSTRATED-DAMAGE.md) preserves technical comparisons and provenance; [report](ILLUSTRATED-DAMAGE.md) distinguishes the art review, the native pass (3832/0, 39 PNG) and the six headless suites (56 484/0). The native sample is not advertised as an animated tour of the 40 poses. This section replaces the historical description of procedural wear, without erasing its previous evidence. It does not modify rules or progression.

## 16. Painted HUD and combat closure

Arena, Story Mode and the presentation of Online share `game_combatant_hud.gd`: name, level and life on the painted reward material, with native figures and symmetrical bars. Menu occupies the top center; Arena flag, Story Mode shortcut, and redundant auto-attack explanation removed.

At the end, result and continuation form a group centered on a veil of the final scene. This overlap is intentional and replaces the old reward stripe underfoot. It does not relocate or rescale fighters, nor does it intervene in rewards. The back panels are drawn above the closure; damage numbers remain behind. Online interprets the winner from the user's side and preserves received XP/rating. Historical repetitions maintain their previous framing. [Review and tests](BATTLE-UI.md).


## Achievements: information before decoration

The tab formerly called Legacy is presented as Achievements. Archive preserves background and historical materials, but omits decorative objects and the empty emblem. Objectives, achievements and collection share existing cards, focus and typography. Chapter memories are secondary and their decisions are deployed on demand. [Report](ACHIEVEMENTS-UI.md).


## Path: decision hierarchy

The new Route prioritizes encounter status, name and action. The rival has a more compact reserve; the empty emblem and decorative objects are omitted. Strength, skill and techniques are consulted on demand. Footer with actions from 48 px high and up to 240 px wide; repeating is secondary when there is continuation. [Report](ROUTE-UI.md).


## Improvements: reading and confirmation

Points before introduction; prominent current value and secondary next value. Help on demand and brief confirmation when applying. Material training_card shared, four/two/one columns, shares 48 px height and width bounded. [Report](UPGRADES-UI.md).


## Moves: separate decisions

Techniques consume tokens; Talents consume elections. Show resource and effect before numerical details. Shared training_card material, three/two/one columns, 48 px actions and persistent focus. [Report](MOVES-UI.md).


## Story Mode Companions: informed selection

Separate query and activation with In use / Preview. Highlight identity, level and individual advancement; keep biography and optional skills. Portraits with a common camera, shared training_card material and compact actions. [Report](STORY-COMPANIONS-UI.md).


## Sliders: thickness and contrast

The shared style reserves 10 px thickness for the horizontal and vertical bars. Dark lane, gold fill and 32 px grabber; visible focus within the control. Settings maintains 48 px of interactive area. [Report](SLIDERS-UI.md).


## Sprite Accuracy · 21 September 2026

23 bodies use localized damage on the exact geometry of their healthy pose. The damage does not modify the tone, lighting or opacity of the intact areas. The scale of each body and the common origin are preserved. See [report and validation](SPRITE-PRECISION.md).


## Focus and performance · 21 September 2026

The shared focus uses an amber interior fill, with no stroke or out-of-control expansion. Preserve keyboard navigation. Lists suspend portraits outside the cropped area; A full opaque screen suspends the covering sand. Translucent dialogues and transitions preserve the background. [Changes and measurements](PERFORMANCE-UI.md).


## Clarity Review · 22 September 2026

This revision extends the existing system to make decisions easier to find. [Screen analysis](UX-REVIEW.md).

- `GameReadingSections` reuses typography and visual system navigation for help and drop-down summaries. Components only present text and states; They do not calculate rewards or change progress.
- The actions name their result and their cost when it exists: `Mejorar · 1 punto`, `Entrar con el navegador`, `Mi ruta`. The already active companion offers `Volver con…`.
- `OnlinePanel` divides My file into Attributes, Techniques, Talents and Style. Changing sections preserves the fighter's state, moves focus to the tab and returns to the top of the list; does not write to the server.
- The appearance selector is called `Conjunto visual…`. On mobile, the preview leaves more useful space for options; The foot supports several lines. Relative size of species and preview of locked content without equipping it is preserved.
- The modal keyboard help is displayed in windows of at least 600 px. The X and keyboard navigation are still available on the small ones.
- The disabled main action is not displayed during combat. In the mobile result, the ad and action remain on top of the silhouettes; the desk maintains its center.
- The colors, materials, internal focus contours and volume controls remain the same. No new images or exterior contours are incorporated.

Evidence: 42 states × 2 resolutions = 84 native captures, 153 capture checks without failures. 26 UI acceptance and local integration suites pass; The limitations of two older suites are detailed in the report. Disposable data and mock API, no changes to real accounts.


## Character Presence · 22 September 2026

The subsequent revision moderately expands the portraits of Training, Tab, Personalize mobile, selection and Story Mode/Online. Desktop combat supports up to 2.05 scale with 24 px floor below. Mobile preserves the horizontal boundary of two full animations. The species share a chamber and maintain their relative size; It is never scaled to the pixels of each pose. They don't change art, tones or game logic.

[Measurements, decisions and validation](CHARACTER-PRESENCE.md) · Latest mobile wall (`work/character-presence/after/wall-390x844.png`; not included) · Latest desktop wall (`work/character-presence/after/wall-1360x880.png`; not included).
