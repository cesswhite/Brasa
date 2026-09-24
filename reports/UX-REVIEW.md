# Brasa Clarity and Usability Review

22 September 2026. Changes applied to the game.

The review is based on the **37 most recent views** on desktop and mobile. I added five detail states to cover Color, Effects, Style and the new online subsections: **42 states and 84 final native captures**. The changes focus on understanding what to do, finding each option, and reading only the necessary detail.

The menu, illustrated identity, brass/leather materials and volume controls already had a useful foundation. They were preserved. The main improvements are in the help by topic, the online sheet by sections, mobile distribution, actions with explicit cost and combat results.

[Report index](README.md) · Desk wall (`work/ux-review/after/wall-1360x880.png`; not included) · Mobile wall (`work/ux-review/after/wall-390x844.png`; not included)

## Screen analysis

**Before** describe the problem or reason for maintaining vision. **Then** distinguishes new changes from functions that already existed and were verified. The five additional snapshots are not presented as five newly created functions.

| Screen | Before / diagnosis | After/decision applied |
|---|---|---|
| Main menu | The Story action already dominates and the secondary options are grouped together. Adding more text would once again compete with the landscape. | **Preserved.** I retain the hierarchy, character background and Start/Continue story based on their progress. |
| Settings | Rhythm ×1 / ×2 did not clearly explain what was accelerating. The sliders already have readable track, padding and value. | **Adjusted.** The option is called Quick Combat and displays its multiplier. I keep the sliders visible and simplify the subtitle. |
| How to play | The manual required you to scroll through a wall of text to find an answer. | **Redesigned.** Four steps to get started, followed by drop-down topics. All the detailed explanation is still available when opening each topic. |
| Create your first companion | On mobile, the preview left little room to choose and read the options. | **Tweaked.** Shared editor balances preview and list height. The Create Partner button and name are preserved. |
| League Training | Improving did not indicate the cost in the action itself. The cards and contextual help already organized the information well. | **Tweaked.** Every action says Improve · 1 period. I keep available points, values, and help next to each attribute. |
| Partner's file | The attributes were interactive, but there was no indication that they could be queried. | **Adjusted.** A brief prompt invites you to tap an attribute. The number grid is preserved and View growth to consult the next level. |
| Choose partner | Using a… was ambiguous when that companion was already active. | **Adjusted.** Return with… appears for the active partner; for another follow Use a…. The selection maintains its progress and preview. |
| Customize Body | On mobile, the top area left few visible options and the combination selector did not clearly name its visual range. | **Tweaked.** More useful height to choose from, preview provided and visual set selector…. The lower notices can occupy several lines. |
| Customize · Color and skins | The same distribution reduced the sample space and unlocking conditions. | **Adjusted.** The new space distribution also applies to Color. The large samples, the Skins section and the test of options blocked without being able to equip them remain. |
| Customize · Effects | The explanation under the options was cut into narrow windows. | **Tweaked.** Help adjusts to multiple lines and there is more room for Auras/Trails. Your previews and unlock requirements are preserved. |
| Customize Entry and victory | On mobile the demo and the options competed for height. | **Adjusted.** I redistribute that space and keep Entry/Victory, Repeat, autoplay, and the explanation of when each animation is used. |
| Arena · Preparation | Entering the arena already signals the main action; Menu and HUD are separate. | **Preserved.** I preserve that structure, the identity of the fighters and their life bars. |
| Arena Combat | The big Auto Combat disabled button felt like an available action and distracted from the fight. | **Adjusted.** Hides during fight. Usable actions remain; the main button returns when there is a decision to make. |
| Give up | The confirmation could explain the state of the fight sooner and concentrate the consequences. | **Adjusted.** I indicate that combat is paused and summarize what happens when you surrender, keeping both decisions and XP information. |
| Result · Victory | In mobile the central block covered part of the fighters. | **Adjusted.** I place result and action above their silhouettes on mobile; The whole maintains horizontal centering. The central composition is maintained on the desktop. |
| Result · Defeat | The same overlap affected the reading of the defeat and the next step. | **Adjusted.** The same rule clears the characters and keeps the result linked to the corresponding action. |
| Combat summary | A long block of text mixed result, experience and statistics; showed changes in level even if they were the same. | **Redesigned.** Result first, information about each fighter in foldable sections and direct access to View combat actions. The levels only show a rise when it occurred. |
| Empty history | A large, almost empty dialog suggested scrolling and offered no direct next step. | **Tweaked.** More compact dialogue with Return to Arena. Close the history without starting a surprise fight. |
| Empty record | The absence of combat actions was presented in an unnecessarily high container. | **Adjusted.** Compact empty state, explanation and Return to sand. The instruction to scroll without content is removed. |
| League Story Mode | Reading dialogs had too much desktop width and a scroll instruction even when it wasn't needed. | **Adjusted.** Reading width limited to 800 px and without the universal indication. Tickets and access to replays are preserved. |
| Combat actions | The spacing between lines made the record longer than necessary. | **Adjusted.** One line per action, minor separation and subtitle explaining turn order. Events are not deleted. |
| Local repeat | Memories of the Arena was less identifiable than the name of the show; The initial text talked about implementation. | **Adjusted.** Title Replays and notice No new rewards. I keep play, pause, restart and the saved appearance of the fight. |
| Story Mode · Route | Current was an ambiguous label for returning to character progress; the moving foot used The league as an implicit verb. | **Adjusted.** The access is called My Route and the mobile exit is called Back. I keep the opponent, the map and the Enter / Repeat action depending on the encounter. |
| Story Mode · Improvements | The attribute comparison took up too much space and +1 required deducing what was spent. | **Adjusted.** Current value → next in a line, explanation By reversing 1 dot and Improve button · 1 dot. A false comparison is not drawn when reaching the limit. |
| Story Mode · Redistribute | The confirmation already shows the recovered resources and offers Cancel/Redistribute. | **Preserved.** I retain the confirmation and its consequences. It benefits from simplified navigation and hidden keyboard help on mobile. |
| Story Mode · Techniques | On mobile, Strikes did not describe well a view that also contains Talents. | **Adjusted.** The tab is called Techniques and retains its two subsections, costs and on-demand details. |
| Story Mode · Talents | The previous screenshot labeled Talents showed the end of Techniques; It did not allow you to review the real screen. | **Verified.** I correct the screenshot navigation and check Talents: available choices, active talents, action and help. I do not attribute the change in content to a non-existent visual improvement. |
| Story Mode · Companions | The composition already prioritizes the active companion and his route; the mobile exit could be named better. | **Adjusted.** I keep the summary, individual progress and selection. I unify the exit as Return and maintain the action of continuing the campaign. |
| Achievements · To be achieved | An imported test match could show 8/8 encounters without a recorded chapter closure, which seemed counterintuitive. | **Adjusted.** When that record is missing, the card explains it. I keep To be achieved / Achieved / Collection, advance and next objective; I do not invent an achievement. |
| Achievements · Completed chapter | The view already distinguishes what has been achieved in the next chapter; the output used the ambiguous Story Mode label. | **Adjusted.** I keep achievements, progress and Start chapter. I simplify the output navigation and verify that it is differentiated from the pending state. |
| Online Arena | The header took up too much space and Desafiar did not identify the rival. The explanation could be confused with a live invitation. | **Adjusted.** Compact and contextual header, Challenge... and explanation of automatic combat against the other player's fighter, even if you are offline. |
| Online · Story Mode | Identity and navigation displaced the next mobile meeting too much. | **Tweaked.** Shared header frees up space; The title indicates Online Story Mode and preserves encounter, difficulty and action of entering. |
| Online · Attributes | The card accumulated attributes, techniques, talents and style in a single extensive list. | **Redesigned.** I divide the sheet into four sections. Attributes shows the available points and the cost; The cards group value, effect and action. |
| Online · Techniques | The techniques were buried after the attributes of the token. | **Redesigned.** Accessed directly from Techniques. Keep tokens, required level, grade and upgrade action on each card. |
| Online · Talents | You had to go through the entire file to find the talent decisions. | **Redesigned.** Independent Talents section, number of elections and Chosen status visible. Focus and scrolling return to the beginning when changing sections. |
| Online · Combat style | The style was at the end of the sheet and was described in technical language. | **Redesigned.** Own section that explains how the fighter fights when challenged. The active choice is visually distinguished. |
| Online · Activity | The notification recognition action was not very explicit and the header competed with the activity. | **Adjusted.** Online Activity title, compact header and Mark as Viewed button. I keep existing rewards and events. |
| Online · No rivals | The empty state already explained the absence of rivals, but it occupied the same oversized header. | **Adjusted.** I keep the explanation and Update Rivals within the new compact header. Rivals are not made to fill the screen. |
| Online · Create fighter | The navigation of modes competed with the task of creation. | **Adjusted.** Title Create online fighter and mode tabs hidden while filling out form; return to existing fighter is preserved. |
| Online · Repetition and result | The initial replay text described technical details and may not correspond to automatic playback. | **Adjusted.** Neutral message Replay · No new rewards, valid on both pausing and auto-starting. I keep the controls and the result received. |
| Online · Log in | Continue I didn't anticipate the browser would open. | **Adjusted.** The action says Enter with the browser and explains that it is used to enter and save online progress. |
| Online · Authorize device | It was necessary to clearly separate what is done in the browser from what happens when returning to the game. | **Adjusted.** Two steps: confirm the code in the browser and return to the game. The session is opened upon authorization; Reopening the browser or canceling is still available. |

## Applied criteria

- The actions tell their result: Enter with the navigator, Improve · 1 point, My route and Return with the active companion.
- Help and summaries use drop-down sections. Detailed information is preserved, but no longer dominates the first reading.
- The online file separates four decisions; Navigating between them does not perform writes or consume resources.
- On mobile, more height is reserved for options. The explanations below wrap the text and do not use ellipses.
- Visible focus is preserved through the inner material and native keyboard controls. No outer contours are added.
- During combat the large no-action button disappears. When finished, the decision returns along with the result; On mobile it remains on the silhouettes.
- Existing images and materials are used. No sprites, tones, wounds, relative scales, balance, save or backend are changed.

## Validation and limits

- **26 acceptance suites: 28,718 checks, 0 failures.** Includes navigation, pause/audio, locked customization, upgrade costs, documents, Story Mode and online UI. Results (`work/ux-review/checks/results.json`; not included).
- **153 catch checks, 0 failures; 84 native captures** to 1360×880 and 390×844. Clarity testing also covers 844×390. Manifest (`work/ux-review/after/screens.json`; not included) · Native Log (`work/ux-review/native-audit.log`; not included).
- Screenshots are rendered in Godot with disposable profiles and test data. Online uses in-memory responses, without HTTP: This review does not test the deployed service or an actual session.
- Combat results use synthetic starting HP for victory and defeat. The presentation lets itself settle; It does not present itself as a natural departure.
- Before corresponds to `work/performance-ui/screens`; Those catches are not replaced. The previous view labeled Talents was incorrect, and is reported in the comparator. The five added states do not have an equivalent Before.
- In exploratory testing, the old `test_story_campaign_ui.gd` gave 28 failures from 566 checks; copying scripts prior to these changes produced exactly the same errors 28. `test_story_chapter_integration.gd` timed out and is not counted as passed. These are pending limitations of those old suites; the current Route, Upgrades, Techniques, Achievements, and Story Mode panel suites do pass. Previous Comparison (`work/ux-review/baseline-campaign.log`; not included) · Exploratory Run (`work/ux-review/checks.log`; not included).
- There has been no player testing or accessibility certification. Captures allow you to check presentation; Interaction tests verify the described behavior.

## Implementation

The refactoring remains in the presentation layer. `GameReadingSections` is the shared component for folding documents. `OnlinePanel` splits its rendering by subsection, reusing existing actions. `BattleLayout` reserves the moving result space. Other changes are limited to content, layout and navigation.

Open Brasa (`/Users/cess/Jugar%20Brasa.command`; not included) uses the updated project.
