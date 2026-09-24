# Brasa · Screen inventory and audit

## Latest status 22 September 2026

The current hotfix covers **42 states, 84 native captures**, building on the 37 performance review views and adding Color, Effects, Style, and two online subsections. It includes help by topic, foldable summary, online file by sections, actions with explicit costs, more useful space on mobile and mobile result above the characters.

- [Analysis and changes per screen](UX-REVIEW.md).
- Desktop (`work/ux-review/after/wall-1360x880.png`; not included) · Mobile (`work/ux-review/after/wall-390x844.png`; not included) · Manifest (`work/ux-review/after/screens.json`; not included).
- Validation: **26 acceptance suites, 28,718 no-fail checks**, plus 153 no-fail capture checks. The limitations of two older suites and the comparison with the previous version are documented in the report.
- Disposable profiles; Online in memory without HTTP. It is not a production validation. The previous capture of Talents pointed to Techniques: it now shows the correct subsection and is notified in the comparator.

The following preserves the historical inventory for 20 from September and subsequent revisions; Their figures and scores are not a substitute for current evidence.

---

**The audited 37 surfaces already share the Story Mode visual family.** The release brings together final 74 desktop/mobile screenshots, previous 72 and a local comparison dashboard. The base had four isolated control families; The migration unifies materials, typography and composition, preserving existing rules and routes.

Date: 20 September 2026. This audit distinguishes the **pre-migration baseline** from the post-migration monitoring. Production files may change during work; Initial scores refer to screenshots and frozen sources, not a mobile version of the repository.

## Evidence and method

- Desktop wall, 36 states (`work/visual-system/before/wall-1360x880.png`; not included) and moving wall, 36 states (`work/visual-system/before/wall-390x844.png`; not included).
- 72 captures manifest (`work/visual-system/before/screens.json`; not included), native log (`work/visual-system/audit-native.log`; not included), previous sources (`work/visual-system/source-before/scripts/main.gd`; not included) and previous visual manifest (`work/visual-system/source-before/ui_visual_manifest.json`; not included).
- [Reusable Harness](../tests/test_visual_screen_audit.gd): **123 checks, 0 failures**, 72 screenshots and two walls. Captured resolutions: 1360×880 and 390×844. It does not imply visual coverage of all sizes of the other tests.
- Direct Godot rendering using SubViewport. Main uses new files in `work/visual-system/fixtures`; Story Mode uses an in-memory model and Online a mock without HTTP. No real profiles, browser, network, Cloudflare, or authentication are opened.
- The combat results use the real engine with synthetic starting HP to achieve victory and defeat. They are tagged fixtures, not a recording of natural games. Replays read those preserved events.
- Methodological difference: the base waited two frames and its results may show intermediate opacity during input. The final captures also wait **0.3 real seconds**; for the results they advance **1.2 seconds only the Node2D presentation**, keeping Main/engine manual and verifying that events and progress do not change, and then freeze. They require alpha ≥ .999 and record `settled_visuals` and the alpha value. No pose is forced or foundation replaced. It's a wall of settled UI, not a recording of natural animation; This difference should not be attributed to design improvement.
- Historical comparison gallery (removed from the public edition): fixed Story Mode reference, filters, Before/After and original-size zoom. Contains the base states 36 and the new independent state Settings: 74/74 After, without gaps. Settings doesn't have its own Before because its controls were inside Menu; This absence is explained without fabricating a catch.

The review groups hierarchy, color, typography, spacing, alignment, repetition, contrast and finishing into five axes scored from 0 to 4. Each point is worth five points of the total, which ranges from 0 to 100:

| Axis | What compares to Story Mode |
| --- | --- |
| M World | Illustrated place, light and connection of the character with the environment. |
| S Surfaces | Materials, controls, selection, focus and states of a common family. |
| T Typography | Narrative headline, legible body and consistent hierarchy. |
| C · Composition | Clear protagonist, grouping, air and priority of actions. |
| N · Navigation | Continuity between views, mobile access, scrolling and recognizable routes. |

0 = absent or contradictory; 1 = isolated color match; 2 = partial; 3 = mostly consistent with a specific difference; 4 = clear reference or equivalence. These are comparative design judgments, **not a certification of accessibility, performance or functional correctness**. A compact HUD can be kept even if it doesn't use all the Story Mode decoration. The focus and pulse states require their own testing, in addition to a static capture.

**KEEP** preserves the solution; **ADAPT** preserves structure and applies the shared family; **REDESIGN** recomposes priorities using existing data and art. No decisions authorize changes to economy, accounts, combat, or saves.

## Core Scored Inventory

The IDs match the harness and the PNGs: `ID-1360x880.png` / `ID-390x844.png`, in the base folder (`work/visual-system/before`; not included). The exact paths and fixture type are in `screens.json`. Each row includes the piece that should be shared, the reusable art, and the proposed intervention.

| ID/display | Previous system | M/S/T/C/N → total | Inconsistency and proposed refactor | Decision |
| --- | --- | --- | --- | --- |
| `story-route` Route | StoryPanel + WorldBackdrop/WorldVisuals | 4/4/4/4/4 → 100 | Background reference, rival, strengths, route and CTA. Preserve journey/storm and pagination contexts. | KEEP |
| `story-upgrades` · Workshop | StoryPanel, workshop background | 4/4/4/4/4 → 100 | Reference of open attributes, impact and action; Reuse header and statistics rows. | KEEP |
| `story-respec` · Confirm redistribution | Story local dialog, flat panel | 3/2/3/3/4 → 75 | The inner box has another finish. Move it to the common dialog without changing confirmation or returning points. | ADAPT |
| `story-moves` Movements | StoryPanel, tinted workshop | 4/4/4/4/4 → 100 | Keep technique, purpose, risk, requirement and limited improvement; share readable rows with Online. | KEEP |
| `story-perks` · Talents | Moved section of Movements | 4/4/4/3/4 → 95 | Density calls for preserving scroll and distinction between available/chosen; Do not add ornamental cards for talent. | KEEP |
| `story-companions` · Shelter | StoryPanel, camp | 4/4/4/4/4 → 100 | Reference for list of companions, protagonist and biography; retain individual profiles. | KEEP |
| `story-legacy` · Pending legacy | StoryPanel, archive | 4/4/4/3/4 → 95 | Empty state already belongs to the file; retain explanation and access to campaigns. | KEEP |
| `story-legacy-complete` · Legacy earned | StoryPanel, archive + trophies | 4/4/4/4/4 → 100 | Achievement reference and frozen statistics; Do not recalculate memories from the current computer. | KEEP |
| `arena-idle` · Preparation | Main + ArenaView, flat buttons | 4/1/2/3/3 → 65 | World and figures work; header and actions do not share materials. Adapt HUD/buttons while preserving BattleLayout. | ADAPT |
| `menu` · Menu and original settings | Main document, flat grid | 1/1/2/1/3 → 40 | Large empty panel, destinations and settings have equal weight. Recompose as a refuge with character and main destination; separate Settings. | REDESIGN |
| `training` · League Training | Main document and four cards | 1/1/2/2/3 → 45 | Progress looks like an isolated form. Reuse workshop and attribute rows; retain the four League improvements. | REDESIGN |
| `profile` · League Sheet | RichTextLabel document | 1/1/2/2/3 → 45 | A lot of text without figure or card hierarchy. Share portrait, titles and statistics; remain available during combat in reading. | REDESIGN |
| `help` · Manual | Main Document | 1/1/2/3/3 → 50 | Functional reading with a foreign finish. Common reading dialogue, narrative titles and comfortable width; keep scroll. | ADAPT |
| `history-empty` · Empty history | Main Document | 1/1/2/1/3 → 40 | Flat space without context of memory. Reuse file and brief empty state; retain direct closure. | ADAPT |
| `log-empty` · Empty record | Main Document | 1/1/2/1/3 → 40 | Helpful explanation within a disproportionate panel. Use common document and compact empty state. | ADAPT |
| `roster` · Companions League | RosterPanel, flat local theme | 2/1/2/3/3 → 55 | Small art and dense token in front of the Shelter. Reuse camp, dominant portrait and common selection; preserve 15 profiles and mobile tab. | REDESIGN |
| `customization` · Customize | CustomizationPanel, local theme | 2/1/2/3/3 → 55 | Good figure/options axis, but it seems like another tool. Share workshop, tabs, fields, selection and notice; maintain inventory and validation. | ADAPT |
| `arena-active` · Combat | Main + ArenaView + FighterView + CombatFX | 4/1/2/3/3 → 65 | Silhouettes and FX belong to the world; controls and typography diverge. Adapt chrome without covering HUD, faces or clock. | ADAPT |
| `surrender` · Give up | Main document with two actions | 1/1/2/3/3 → 50 | Correct functional confirmation, foreign material. Common dialogue; retain safe option, pause and written consequences. | ADAPT |
| `result-victory` · Victory | Result on Arena in Main | 4/1/2/2/3 → 60 | Result and reward have little narrative presence. Shared header/badge, preserving figures and next action. | ADAPT |
| `result-defeat` · Defeat | Result on Arena in Main | 4/1/2/2/3 → 60 | Same hierarchy opportunity; preserve track, XP and retry without hiding information under decoration. | ADAPT |
| `summary` Summary | Main Document | 1/1/2/3/3 → 50 | Isolated text block. Reuse document and rows of figures, maintaining exact data of the completed combat. | ADAPT |
| `history` · Match history | Main Document | 1/1/2/2/3 → 45 | Keepsake list in a generic box. File + combat row + action View replay; preserve order and snapshots. | ADAPT |
| `log` · Registration with actions | Main Document | 1/1/2/3/3 → 50 | The reading is adequate; it only requires common material and hierarchy. Don't turn every event into a big card. | ADAPT |
| `replay` · Local repeat | BattleReplayPanel + ArenaView | 4/1/2/3/3 → 65 | The combat looks Brasa and the container does not. Share header, selector and transport; preserve clock, pause and historical reading. | ADAPT |
| `online-arena` · Online rivals | OnlinePanel, flat local theme | 1/1/2/2/3 → 45 | Small profile column and tool type list. Shared arena, portrait/rival row and CTA; preserve server authority. | REDESIGN |
| `online-story` · Online history | OnlinePanel, text panel | 1/1/2/2/3 → 45 | Route loses representation and context of Story Mode. Adapt your preview/route to remote data without simulating local progress. | REDESIGN |
| `online-profile` · My file | OnlinePanel, own controls | 1/1/2/2/3 → 45 | Scattered attributes and growth. Share file/workshop maintaining review and server errors. | REDESIGN |
| `online-perks` · Talents and style | Moved section of My file | 1/1/2/2/3 → 45 | Same concepts as Story Mode with another finish. Share rows, selection and confirmation; preserve limited elections. | ADAPT |
| `online-activity` · Activity | OnlinePanel, flat lists | 1/1/2/2/3 → 45 | Match history and offline results need the archive component family. Maintain remote origin, empty states and access to replay. | REDESIGN |
| `online-empty` · No rivals | OnlinePanel, message and update | 1/1/2/2/3 → 45 | Useful condition but disconnected from the patio. Arena context and common secondary action; do not invent rivals. | ADAPT |
| `online-create` · Create online fighter | OnlinePanel, selector/flat field | 2/1/2/2/3 → 50 | Figure and form have no place. Share creator/preview and controls, preserving explicit remote creation. | REDESIGN |
| `online-replay` · Online combat | BattleReplayPanel from Online | 4/1/2/3/3 → 65 | Same local replay refactor; do not reward when replaying or replaying events. | ADAPT |
| `online-login` · Access | OnlinePanel, centered text | 0/1/2/2/3 → 40 | You lose the world before entering. Shelter fund, header and CTA; preserve real access flow in browser. | REDESIGN |
| `online-device` · Authorize device | OnlinePanel Status | 0/1/2/2/3 → 40 | Code/wait are left in a void. Group instruction, code, state and cancel; do not hide expiration or rejection. | ADAPT |
| `creation` · First creation | CustomizationPanel from Main | 2/1/2/3/3 → 55 | Good preview but form separated from the world. Share workshop and controls; distinguish create from edit and preserve entry to Story Mode. | ADAPT |

## Surfaces and variants outside the 72 screenshots

| Surface | Coverage of this audit | Treatment |
| --- | --- | --- |
| Settings | At the base it was inside Menu. The migration separates it into `_show_settings()` with sound, rhythm, motion and full screen. New Capture ID `settings`. | ADAPT as a common modal, preserving the four behaviors. |
| control states | Code for normal, hover, pressed, selected, disabled and focus; existing independent sample book. Not every combination on every page was captured. | WorldVisuals/GameVisualSystem should be the only family. |
| Save locked/error, network error, retry, invalid name, inventory locked | Inventoried on your existing panels and tests; not forced all on the visual base. | Visible message next to your action; semantics and validation intact. |
| Tooltip, OptionButton and long lists | Source coverage; some lists were captured above and below. Not all dropdowns or scroll positions. | Shared typography, focus, contrast and touch areas. |
| Bosses, Chapter 100, Rewards, Pending Talents, and Previous Legacy | Existing specific fixtures and tests; the base only uses one route and one sample legacy. | Preserve content and semantic differentiation; reuse the same system. |
| Signature, Statuses, Floating Damage, Pause, KO and FX | Shared royal presentation, with own suites. A static capture does not validate your clocks. | KEEP behavior; only adapt chrome that does not invade figures/HUD. |
| Web access with passkey and device approval | `backend/web/index.html` inspection; without opening a browser or making requests. No native visual punctuation. | ADAPT web tokens in separate phase, preserving origin, nonce, verification and explicit approval. |
| System/Browser Passkey Dialog | Outside of the UI controlled by the game. | KEEP; Do not imitate or restyle system security interfaces. |

## Shared components and art

| Piece | Observed situation/action |
| --- | --- |
| WorldBackdrop + manifest | Story Mode already loads a place in blood, a legible veil and up to three objects without input. Extend contexts, do not duplicate backgrounds/veils on each screen. |
| WorldVisuals | Atlas of straps, panels, badges and states. Maintain clippings and texture cache; an auxiliary flat surface should not become another global factory. |
| GameVisualSystem and new components | The later foundation adds theme, header, preview, modal, badge and other components. Use them as adapters to existing authority, without replacing Story Mode with a reinterpretation. |
| FighterView / GameFighterPreview | Reuse real identity and cosmetics. The portrait is presentation; Do not write statistics or profiles when browsing. |
| BattleLayout, ArenaView, CombatFX | Keep scale/framing and clocks independent of migration controls. Concurrent geometry changes are reviewed by their owners. |
| Forms and lists | Name field, selector, attribute row, technique, talent, rival, history and prompt need common roles; preserve differences between League, Story Mode and Online. |

The seven frozen authority PNGs are `journey`, `storm`, `workshop`, `camp`, `archive`, `surfaces` and `props`, recorded in the manifest above. Arena and replay also reuse the combat scenarios and the real atlases of the fighters. **No art was generated or edited for this audit**. The walls are screenshots of a Godot composition, not modifications of the production PNGs.

You don't need a big frame around everything. Story Mode uses open space and separation for statistics and techniques; reserve straps/materials for navigation, actions and announcements. New views should repeat that decision, as well as their colors.

## Coverage of requested routes

37 IDs are **capture states**, not 37 products or new pages. The 16 named areas correspond to the following routes; Sharing a view does not imply duplicating a function.

| Requested area | Existing route/native evidence |
| --- | --- |
| sand | Main: preparation and combat; `arena-idle`, `arena-active`. |
| Online Arena | Online, Arena tab: `online-arena`, `online-empty`. |
| Main Menu | HomePanel: `menu`. |
| Character Creation | Customizer in creation mode: `creation`; remote create: `online-create`. |
| Fighter Profile | Local tab `profile` and remote tab `online-profile`. |
| Upgrades | Train League `training`, Workshop/Hits/Story Mode Talents and My Online File. Each mode retains its own rules. |
| Companions | `roster` League List and `story-companions` Story Mode Shelter. |
| Legacy | `story-legacy`, `story-legacy-complete`; Memories preserve their historical data. |
| Settings | Standalone document `settings`; Before, its controls were part of the Menu. |
| Battle Results | `result-victory`, `result-defeat`, `summary`; Online presents your response summary within the panel. |
| Matchmaking | List of rivals/challenges within Arena Online; there is no separate queue to capture. |
| Leaderboards | **There is no classification screen or endpoint.** `sections.leaderboards` only reserves a visual alias for possible later use. It does not count as an implemented or validated area. |
| Inventory | List of owned/locked cosmetics from `customization`; there is no additional inventory page. |
| Cosmetics | Selection/equipment in `customization`, also reused by Online. |
| Story | Route, workshop, techniques, talents, shelter and legacy of StoryPanel; `online-story` for the remote path. |
| boss | Type of encounter within Story: preview, badge, rival and combat; It is not a separate page. |

## Review of sources after migrations

Main, Home, Personalization, Online, Companions, Story Mode and Replay use `GameVisualSystem.theme()`. The controls go through their shared roles; Headers, previews, badges, results, and documents use the common components. The review did not find another default Button/Panel factory outside of the Story Mode family. Also corrected were the Online color aliases, the unused flat style helper in Main, and the help path **Menu → Settings → Reduced Movement**.

`StyleBoxEmpty` open panels, reading veil, palette swatches, health/XP semantic bars, and focus outlines are deliberate decisions. They are not classified as pending screens because they are simple. Some numerical font sizes adapted to the space persist, but they use common families; They are not a demonstrated visual defect on their own. The static review is complemented by the screenshots: it does not replace the test of cropping, scrolling, focus or interaction states.

Native Online access is captured with an in-memory API. This pass **does not deploy or test web security**, passkeys, D1, network, sessions, accounts or classifications. The authorization web page and the secure system dialog are external surfaces to the native array. Their existence does not allow us to attribute functional validation to them from an offline capture.

The capture_final.py (`work/visual-system/capture_final.py`; not included) tool prepares the global capture after freezing fonts and art. SHA-256 inventory of scripts/data/scenes, configuration, original assets and fixtures before and after; any change during execution invalidates the evidence. Excludes backend, reports and import files. Checks 37 IDs for two resolutions, real PNG files, isolation and settled results. Without `--run` it only creates an inventory and does not open Godot. The hashes test the limit of this execution; they do not attribute concurrent art changes that occurred before freezing it to visual migration.

## Tests that accompany each family

| Family | Existing tests that should be preserved when migrating |
| --- | --- |
| Foundation/materials | [test_game_visual_system.gd](../tests/test_game_visual_system.gd), [test_game_components.gd](../tests/test_game_components.gd), [test_world_visuals.gd](../tests/test_world_visuals.gd), [test_world_surfaces.gd](../tests/test_world_surfaces.gd). |
| Story Mode | [test_story_panel.gd](../tests/test_story_panel.gd), [test_story_world_visuals.gd](../tests/test_story_world_visuals.gd), [test_story_campaign_ui.gd](../tests/test_story_campaign_ui.gd), [test_story_chapter_integration.gd](../tests/test_story_chapter_integration.gd), [test_campaign100_integration.gd](../tests/test_campaign100_integration.gd), [test_story_integration.gd](../tests/test_story_integration.gd). |
| Main/Arena/results | [test_battle_layout.gd](../tests/test_battle_layout.gd), [test_identity_integration.gd](../tests/test_identity_integration.gd), [test_identity_edges.gd](../tests/test_identity_edges.gd), [test_core.gd](../tests/test_core.gd). |
| Companions/creation/identity | [test_roster.gd](../tests/test_roster.gd), [test_customization_visuals.gd](../tests/test_customization_visuals.gd), [test_cat_roster_ui.gd](../tests/test_cat_roster_ui.gd), [test_mexican_roster_ui.gd](../tests/test_mexican_roster_ui.gd), [test_fighter_identity.gd](../tests/test_fighter_identity.gd). |
| Online | [test_online_ui.gd](../tests/test_online_ui.gd), [test_online_integration.gd](../tests/test_online_integration.gd). API/Worker tests with HTTP are another phase; They are not run to capture this offline audit. |
| Replay/animation/FX | [test_animation_sequences_visual.gd](../tests/test_animation_sequences_visual.gd), [test_status_ko_presentation.gd](../tests/test_status_ko_presentation.gd), [test_move_clock.gd](../tests/test_move_clock.gd), [test_move_presentation.gd](../tests/test_move_presentation.gd), [test_organic_fx.gd](../tests/test_organic_fx.gd). |
| New sequential audit | [test_visual_screen_audit.gd](../tests/test_visual_screen_audit.gd), [test_visual_menu_navigation.gd](../tests/test_visual_menu_navigation.gd) and [test_visual_documents.gd](../tests/test_visual_documents.gd). |

This list identifies available coverage, it does not claim that all such suites have been re-run to draft the inventory. Each migration must run the relevant tests and record their results separately.

## Migration tracking

| Step | Before | After / evidence | Status |
| --- | --- | --- | --- |
| Main menu | 40/100; flat document that mixed destinations and settings. | Desktop (`work/visual-system/after/menu/menu-1360x880.png`; not included), mobile (`work/visual-system/after/menu/menu-390x844.png`; not included): Blood Haven, Dominant Companion, Narrative Title, Main Story, and Common Materials. Comparison with reference: 4/4/4/4/4 → 100/100. | Approved appearance and navigation. Focus leak to HUD was fixed: cycling between Close and destinations enabled. Native Test (`work/visual-system/menu-navigation-native.log`; not included): **294 checks, 0 failures** in 1360×880, 390×844 and 844×390. |
| sand | 65/100; good scene with flat chrome. | Later captures at `work/visual-system/after/arena`; separate controls review of concurrent changes at actor scale. | Migration approved and fixed in the final global matrix; this audit does not change BattleLayout. |
| Online | 40–50/100 in panels; 65/100 in replay. | Desk wall (`work/visual-system/online-final/wall-1360x880.png`; not included), moving wall (`work/visual-system/online-final/wall-390x844.png`; not included). Twenty catches reviewed; patio, workshop and archive, narrative titles and common controls. Panels of this phase: 4/4/4/3/4 → 95/100. The replay of these captures, prior to their final common migration, scored 4/3/2/4/4 → 85/100; that value does not describe the updated Replay, scored in the final matrix below. | Approved. No clipping or overlapping; the partial rows correspond to the scroll. Story Mode's empty fallback was replaced with a compact landmark `09`. Owner Validation (`work/visual-system/online-migration-results.json`; not included): Native 815/0 in seven sizes, 147/0 additional cases, and 33/0 matrix. They do not add up as independent tests of the entire application. |
| League tab | 45/100; document without figure or place. | Desktop (`work/visual-system/after/profile/profile-1360x880.png`; not included), mobile (`work/visual-system/after/profile/profile-390x844.png`; not included): refuge, protagonist and separate reading. 4/4/4/3/4 → 95/100. | Approved; The nine statistics, skill, signature and scroll reading are preserved. |
| League Training | 45/100; Four cards on a generic panel. | Desktop (`work/visual-system/after/training/training-1360x880.png`; not included), mobile (`work/visual-system/after/training/training-390x844.png`; not included): workshop, figure, and four League upgrades. 4/4/3/4/4 → 95/100. | Approved after correcting the minimum width retained. Native token/training test (`work/visual-system/documents-native.log`; not included): **637 checks, 0 failures** in seven sizes; Same headless result. Includes four hitboxes/tags/values, scroll, and a persistent upgrade per fixture without altering Story or XP/level. |
| Creation / Customize | 55/100; form from another family. | Mobile creation (`work/visual-system/after/creation/creation-390x844.png`; not included), desktop editor (`work/visual-system/after/creation/customization-1360x880.png`; not included). Workshop, open lists, selection and actions of a common family; mobile framing corrected. 4/4/4/3/4 → 95/100. | Approved phase. The `after/all` matrix already contains the full mobile subtitle “Your name. Your style. Your story." and the current frame. |
| Results | 60/100; result with little narrative presence. | Desktop victory (`work/visual-system/after/results/result-victory-1360x880.png`; not included), mobile defeat (`work/visual-system/after/results/result-defeat-390x844.png`; not included): material panel, clear title and reward, with figures and CTA preserved. 4/4/4/3/4 → 95/100. | Final approval after correcting the panel overlap with the seated pose. The `after/all` matrix shows the panel under the figures on the desktop; previous phase captures are preserved as such. |

Sequence applied in stages: menu → Arena/HUD/results → Online → creation/customization → tab/training → Companions → documents/legacies/settings. Story Mode remains for reference and only its component exceptions are corrected. Each step should compare two sizes with the same fixture, check focus/scroll and check that the path returns to the expected location before moving forward.

The menu test goes through the real destinations with an offline spy for the Online action, checks Tab and Shift-Tab, movement to focus, controls of at least 48 px, exclusion of actions during combat, access to Paused Tab, Escape and byte-by-byte conservation of League and Story Mode. It does not activate full screen or save preferences. The score 100 expresses equivalence to this visual reference in the revised scope; does not claim that there is no future improvement.

## Final Scored Matrix

Scores are based on the two sizes reviewed. They are comparative and deliberately non-automatic: they go from 90 to 100; dense documents, empty state space and scroll navigation explain concrete differences. **37/37 revised statuses, no visual blocking pending.** Row breaks at the edge of a scrollable zone and card role abbreviations do not mean that the entire tile is inaccessible.

| ID | Before | M/S/T/C/N → After | Final observation |
| --- | --- | --- | --- |
| `story-route` | 100 | 4/4/4/4/4 → **100** | Preserved reference: complete rival, weakness and next action; route and mobile tab by scroll. |
| `story-upgrades` | 100 | 4/4/4/4/4 → **100** | Open workshop, clear points/impact/action; The attributes continue by scroll. |
| `story-respec` | 75 | 3/4/4/4/4 → **95** | Brief confirmation and safe actions within the neutral modal; the place is dimmed. |
| `story-moves` | 100 | 4/4/4/3/4 → **95** | common family; techniques and six talents maintain a considerable density. |
| `story-perks` | 95 | 4/4/4/3/4 → **95** | Moved section of Coups; legible requirements, risks and improvements, not everything fits at once. |
| `story-companions` | 100 | 4/4/4/4/4 → **100** | Shelter with main character, biography and miniatures contained. |
| `story-legacy` | 95 | 4/4/4/3/4 → **95** | Clear file and chapter; the empty state preserves a large area. |
| `story-legacy-complete` | 100 | 4/4/4/3/4 → **95** | Next chapter and differentiated memory; Detailed legacy requires mobile scrolling. |
| `arena-idle` | 65 | 4/4/4/3/4 → **95** | HUD and stocks already share a family; The mobile preserves a large space of sand between information and figures. |
| `menu` | 40 | 4/4/4/4/4 → **100** | Refuge, companion and main destiny form a common hierarchy with Story Mode. |
| `settings` | Inside Menu | 4/4/4/3/4 → **95** | Four clear controls with selection/focus; the modal leaves ample bottom air. |
| `training` | 45 | 4/4/3/4/4 → **95** | Shared workshop and figure; The four statistics preserve a compact typographical hierarchy. |
| `profile` | 45 | 4/4/4/3/4 → **95** | Clear character and context; extensive tab and subsequent statistics by scrolling. |
| `help` | 50 | 4/4/3/3/4 → **90** | Shared material and headline; long read with uniform weight body. |
| `history-empty` | 40 | 4/4/4/3/3 → **90** | Clear file; Ample free space and generic scroll footer even without registrations. |
| `log-empty` | 40 | 4/4/4/3/3 → **90** | Absence of explicit actions; Broad modal and generic footer even with little text. |
| `roster` | 55 | 4/4/4/3/4 → **95** | Collection and token share Shelter; some roles are abbreviated into moving cards. |
| `customization` | 55 | 4/4/4/3/4 → **95** | Workshop, portrait and equipment united; many visible options require scrolling. |
| `arena-active` | 65 | 4/4/4/3/4 → **95** | HUD, scene and actions belong to the same world; ample reserve for mobile movement. |
| `surrender` | 50 | 3/4/4/4/4 → **95** | Clear confirmation and two differentiated actions; the scene is grayed out for reading. |
| `result-victory` | 60 | 4/4/4/3/4 → **95** | Panel under the figures: free head and fist; next action repeated on desktop panel and footer. |
| `result-defeat` | 60 | 4/4/4/3/4 → **95** | Clear defeat, reward and CTA; Free rival celebration and next message repeated in the footer. |
| `summary` | 50 | 4/4/3/3/4 → **90** | Exact data in common document; hierarchy of the body and air retain a shapeless appearance. |
| `history` | 45 | 4/4/4/3/4 → **95** | File with common identity, outcome and action; two memories leave a lot of air. |
| `log` | 50 | 4/4/3/3/4 → **90** | Legible and continuous record; Deliberate uniform typography for events. |
| `replay` | 65 | 4/4/4/3/4 → **95** | Shared title, selector and transport; large central reservation for the sequence. |
| `online-arena` | 45 | 4/4/4/3/4 → **95** | Rival, context and challenge follow Route; account header adds mobile density. |
| `online-story` | 45 | 4/4/4/3/4 → **95** | 09 milestone legible and clear action; preview limited to remote fixture data. |
| `online-profile` | 45 | 4/4/4/3/4 → **95** | Shared portrait and workshop; Statistics continue under the mobile first viewport. |
| `online-perks` | 45 | 4/4/4/3/4 → **95** | Techniques/talents/style use open ranks; long content per scroll. |
| `online-activity` | 45 | 4/4/3/3/4 → **90** | Consistent file and clear actions; dense summary. Pluralization was corrected before final capture. |
| `online-empty` | 45 | 4/4/4/3/4 → **95** | Sincere absence of rivals and an action; The patio maintains ample free space. |
| `online-create` | 50 | 4/4/4/3/4 → **95** | Character and form in the workshop; Return action continues under mobile scroll. |
| `online-replay` | 65 | 4/4/4/3/4 → **95** | Same materials, text and transport as local viewer; scene reserved for movement. |
| `online-login` | 40 | 4/4/4/3/4 → **95** | Readable access and unique CTA within the courtyard; large environmental space. |
| `online-device` | 40 | 4/4/4/3/4 → **95** | Code, status and cancellation visible; denser instruction block than Route. |
| `creation` | 55 | 4/4/4/3/4 → **95** | Differentiated name/base/figure/style; dense configuration on mobile. |

## Validation and limit of final evidence

- 74 captures + two walls (`work/visual-system/after/all/screens.json`; not included), native log (`work/visual-system/audit-final-native.log`; not included): **143 checks, 0 failures**. All results have alpha 1 and settled presentation.
- Visual Review Record (`work/visual-system/final-visual-review.json`; not included) and independent reviews of Main (`work/visual-system/final-main-review.md`; not included), Story Mode (`work/visual-system/final-story-review.md`; not included), Online (`work/visual-system/final-online-review.md`; not included) and documents/Replay (`work/visual-system/final-document-review.md`; not included).
- Capture hashes (`work/visual-system/final-native-provenance.json`; not included): 50 source files, 229 art files and five stable fixtures before/after. Imported cache window (`work/visual-system/import-cache-window.json`; not included): None of 388 files were written during capture. They are tests of that interval, not a prohibition on further changes to other tasks.
- Consolidated regression (`work/visual-system/final-validation/results.json`; not included): **27 suites, 17 447 checks, 0 failures**, with relevant retests already incorporated. Partial executions on this page are not added back together. The new regression result tests painted silhouettes settled in seven sizes: 1950/0.
- Board check (`work/visual-system/review-test.log`; not included): **63 checks, 0 failures**. Includes filters, fixed reference, zoom 1:1, focus on close, no moving overflow and hashes of the 146 copies. Upload as local file: zero HTTP requests and zero browser errors. Eight tests of the tools check font selection, explicit absence, and packaging limits.
- Preservation (`work/visual-system/preservation-final.json`; not included): Preserved backgrounds/materials and rule modules. The sprite sequences adjusted by the parallel task belong to another work; They are not presented as art generated or edited by this UI migration.

The first pass passed the functional checks, but visual review detected that the desktop result was hiding a raised head/fist. It is kept in first-pass-result-overlap (`work/visual-system/first-pass-result-overlap/review-status.json`; not included). The panel was scrolled between feet and actions, revised to original size, and the entire global matrix was repeated. Online Activity also corrected the match for "1 combat 1 victory." The final evidence is the second accepted matrix; no visual approval is attributed to the rejected pass.

The PNGs on the board are byte-by-byte copies. The HTML allows fixed Story Mode reference, filter by section, desktop/mobile, Before/After and zoom 1:1. It does not generate images, it does not interpolate an absent phase and it does not make HTTP requests when opened as a local file. Security web access and Leaderboards are explicitly left out of the implemented/revised set, according to the coverage table.

## Repeat an isolated capture

From the root of the workspace, with native Godot:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path outputs/Brasa \
  --script res://tests/test_visual_screen_audit.gd -- \
  --only=main-menu \
  --capture-dir=/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/work/visual-system/after/menu
```

`main-menu` is alias of `menu`. Lists such as `--only=arena-idle,arena-active,result-victory,result-defeat` or `--only=settings,training,profile` are supported. Without a filter it goes through all the screens. The filter avoids initializing foreign phases; The menu does not require combat or online creation. Each run uses new disposable files. Save the following migrations in your own `after` folders; **do not overwrite the frozen database**. Subsequent product captures and current sources do not convert previous captures into new code results.

## Closure: access, families and attrition

Revised access with shared Story Mode materials: desktop (`work/auth-experience/native/1360x880-login.png`; not included), mobile (`work/auth-experience/native/390x844-login.png`; not included), [report](AUTH-EXPERIENCE.md). WebAuthn browser validation: 13 scenarios; session and Keychain: 16/0.

The historical families and damage review contained three family comparisons and 23 native damage references. See [range, capture and evidence](DAMAGE-AND-FAMILIES.md). They are visual fixtures and do not represent user accounts or inventories.

## Post fix: borders and brawler crossing

User detected white border on Ascua damaged and overlapping when attacking or falling. Both defects invalidate that part of the previous review. [Correction and screenshots verified](ASCENDING-EDGE-CLEARANCE-FIX.md): Four banks cleared and presentation limits shared on Main and Replay, desktop/mobile and double KO.

## Menu: habitats and daily life

The previous capture of `menu` is replaced by this [Report](CHARACTER-REFUGES.md), with [detail and validation](CHARACTER-REFUGES.md). Twenty-one active illustrations, without animated figure or superimposed props; hierarchy in three groups and composition adapted to the character. The first proposal for backgrounds was discarded for repeating valley, vegetation and pose. The second preserves individual identity and differentiates habitats, lighting, actions and frames. The new wall retains native desktop/mobile captures and access to full art; the previous global wall remains historical evidence of the other screens.

## Contact: proximity and overlap of the attacker

The central limit of the edge correction also retracted the extended arm and produced blows in the air. This limit is adapted exclusively for the couple in combat, conserving chamber, root, species scale and Story Mode materials. The attacker advances towards the opponent's neutral torso, occupies the foreground and recovers his position when finished. The movement is preserved if a KO interrupts the action.

| Surface | Classification | Checked change |
| --- | --- | --- |
| Arena and Story Mode in combat | ADAPT | Closest contact; forward attacker; guard and framing preserved. |
| Arena/Online Replays | ADAPT | Same renderer, zoom and depth with recorded events. |
| Portraits and selection without a partner | KEEP | They do not incorporate contact advance. |

[scope and validation](COMBAT-CONTACT.md). Screenshots of this setting are presentation fixtures, independent of the UI history wall.


### Menu header simplification

The menu now starts directly with “Start Story” or “Continue Story”, depending on the progress of the selected character. Redundant header, level, and labels have been removed, and the primary focus uses the tone of the material without a white outline. [Report](CHARACTER-REFUGES.md); native fonts in `work/menu-cleanup/`. This review replaces previous screenshots of the menu only.


## Training: cards and contextual help

The League training screen has limited layout, highlights, numerical preview, cards with drop-down help and clear statuses without points. [Report](TRAINING-UI.md) and [validation](TRAINING-UI.md): 756 checks in seven sizes, plus navigation 327; without errors. This review replaces previous training evidence.


## Customize: Compact Actions and Shared Scale

Cancel and Save are aligned to the right; Apply Style and Random occupy a bounded row. Companion view takes advantage of space without normalizing sizes across species. [Report](CUSTOMIZATION-UI.md) and [verification detail](CUSTOMIZATION-UI.md). This hotfix replaces only the previous Customize evidence.


## Color and skins: samples, collection and tests

Color includes twelve palettes with large samples and the six family skins. Locked tests separate from draft, explicit return and actual requirements. [Report](COLOR-SKINS.md) and [verification / online scope](COLOR-SKINS.md). This hotfix updates Customize and retains its compact controls; the new color catalog is not yet published on Cloudflare.


## Illustrated damage: face, clothing and posture

The previous implementation of surface wear is replaced by a complete wounded sprite family in the 23 bodies: 920 poses, 69 PNG/JSON pairs; 22 newly illustrated bodies and Ascua reused from critical-v1. Grades 2 and 3 share the wounded art, while grade 1 retains clean and fatigue. Story Mode material, environments and interface remain for reference.

| Surface | Classification | Evidence and limit |
| --- | --- | --- |
| Arena and Story Mode in combat | ADAPT | Replacing the complete painting with wounded art of the same body and pose; final native pass 3832/0; 39 PNG. |
| Local and Online Replays | ADAPT | Same renderer and saved events; They do not generate rewards. Health and condition minimum parity checked in illustrated damage suite. |
| Portraits, catalog and selection | KEEP | No harm is forced to show an appearance; clean art and physical scale are preserved. |
| Previous art, sources and documents | Historical KEEP | The previous shader and its screenshots do not credit the new library. |

[Scope and provenance](ILLUSTRATED-DAMAGE.md). The historical gallery, removed from this edition, showed technical crops from production PNGs rather than gameplay screenshots. Alpha/scale checks do not certify anatomical sockets: projected supports are still stated as approximate and the contact may use the painted edge. The closure registers 3832/0 in native Godot and six headless suites with 56 484/0 (including the strict gate 14 977/0). 23 four-clip sheets in two orientations and 16 contexts were reviewed; Complete new originals are inspected separately. The first pass 3878/46 is preserved as a failure of a fixture assertion applied to KO without a partner; the art and runtime did not change to resolve it. The final 39 PNGs are identical to the revised ones. No HTML Dashboard Browser QA is claimed.


## Effects: readable particles and blocking test

Auras and Trails feature visual samples, seven new effects, and independent inventory preview. Visible layer over the sprite, trail fading, auto demo, and reduced motion. [Report](EFFECTS-UI.md) and [online validation/scope](EFFECTS-UI.md). This hotfix updates Effects; retains Color and Skins from previous revision. The new catalog remains unpublished on Cloudflare.


## Style: context and demonstrations

Entry/Victory, eight examples, description cards, optional autoplay and unequipped test. [Report](STYLE-UI.md), [scope and validation](STYLE-UI.md). Preserves previous changes to colors, skins and effects. Local Catalog v5; new styles pending online publication.


## Combat: Painted HUD and centered result

Arena and Story Mode remove flagging, Story Mode access, and redundant attack explanation. Menu centered; Reusable HUD and veiled central result/continuation. Online shares HUD and result from the user's perspective. Historical repetitions maintain their coordinates. [validation](BATTLE-UI.md). The result is intentionally superimposed on the final scene; replaces the old requirement to keep the silhouette out of the advertisement. No changes to rules or servers.


## Companions: scale, attributes and progress

Cards with common camera and individual XP; expanded main view; current attributes separate from optional growth and Skills and Profile. Less redundant text and compact Personalize. Selection, names and profiles unchanged. [Validation](ROSTER-UI.md). Gallery profiles are memory fixtures.


## Tab: compact reading

Grid of attributes, skills on cards and explanations on demand. Same framing as the partner; League/Story Mode and pause values ​​preserved. [Verification](PROFILE-UI.md). Replaces the previous extensive document.


## Achievements: goals, memories and collection

Replaces Legacy: 17 character recognitions derived from saved progress, advance objectives, optional chapter memories, and shared inventory cosmetics. Removed empty emblem, decorative items, and redundant chapter selectors. [Scope and verification](ACHIEVEMENTS-UI.md). No prizes awarded or save or backend changes.


## Route: encounter, map and actions

Route simplifies introduction, preserves details in a drop-down menu, and separates repeat from continue with compact buttons. No changes in progression. [Verification](ROUTE-UI.md).


## Improvements: attributes and decisions

Eight attributes on cards, current value and real improvement, maximum and no points states, optional aids and compact actions. [Verification](UPGRADES-UI.md).


## Movements: techniques and talents

Techniques and talents in separate sections, summarized benefits, optional exact details and compact actions. [Verification](MOVES-UI.md).


## Story Mode Companions: selection and progress

Expanded view, compact tab, optional details, character progress, and start/continue actions. [Verification](STORY-COMPANIONS-UI.md).


## Settings: visible sliders

Volume bars with real thickness, contrast and filled handles. [Validation](SLIDERS-UI.md).


## Sprite Accuracy · 21 September 2026

23 bodies use localized damage on the exact geometry of their healthy pose. The damage does not modify the tone, lighting or opacity of the intact areas. The scale of each body and the common origin are preserved. See [report and validation](SPRITE-PRECISION.md).


## Contourless focus and performance September 21 2026

Native audit: 37 surfaces on 1360×880 and 390×844 (74 traps, 143 checks without failures). Disposable profiles; It is not server data. Reviewed both visual walls and individual screenshots for Adjustments and Redistribute improvements. Focus remains within the controls and the volume rails remain visible.

- Desk Wall (`work/performance-ui/screens/wall-1360x880.png`; not included)
- Moving Wall (`work/performance-ui/screens/wall-390x844.png`; not included)
- [Changes, tests and measurements](PERFORMANCE-UI.md)


## Character Presence · 22 September 2026

The subsequent revision moderately expands the portraits of Training, Tab, Personalize mobile, selection and Story Mode/Online. Desktop combat supports up to 2.05 scale with 24 px floor below. Mobile preserves the horizontal boundary of two full animations. The species share a chamber and maintain their relative size; It is never scaled to the pixels of each pose. They don't change art, tones or game logic.

[Measurements, decisions and validation](CHARACTER-PRESENCE.md) · Latest mobile wall (`work/character-presence/after/wall-390x844.png`; not included) · Latest desktop wall (`work/character-presence/after/wall-1360x880.png`; not included).
