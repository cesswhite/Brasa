# Brasa · Size and presence of the characters

22 September 2026. UI/UX post-review adjustment.

The characters gain presence in the views where they looked small. The scale adapts to the available space; a common chamber between species is preserved so that Mugo remains bulkier than Tepa or Ónix. No image or its tone is modified.

| View | Before | After |
|---|---|---|
| Customize on mobile | Preview 332 px height to 390×844 | 371 px; the redundant subtitle is removed to recover space and the options and actions are maintained |
| Mobile training | Up to 155 px for portrait | Up to 205 px; moderate growth depending on available height |
| Mobile tab | Up to 260 px | Up to 280 px |
| Story Mode Rival | 180 mobile px / 300 desktop px | 224 mobile px / 350 desktop px |
| Story Mode Companion | 280 mobile px / 360 desktop px | 300 mobile px / 390 desktop px |
| Selection tab | 320 mobile px / 400 desktop px | 340 mobile px / 430 desktop px |
| Companion cards | 24 px inner horizontal margin on portrait | 12 px, preserving the common security space between species |
| Online rival | 188 mobile px / 350 desktop px | 220 mobile px / 390 desktop px |
| Desktop combat | Maximum scale 1.8 | Maximum 2.05, limited by width and height; floor 24 px lower to conserve space relative to the HUD |
| Vertical mobile combat | Frame limited by width for two fighters | The safe limit of full animations is maintained: zooming in further would crop poses. Individual previews do increase |

The measurements in the table are reserved spaces, not an identical height forced on each body. In Customize to 390×844, the measured resting visible heights are approximately 148 px for Nima, 177 for Mugo, 132 for Tepa and 139 for Ónix. They share exactly the same camera scale. In very low windows the compact framing is preserved.

## Check

- 11 suites pass: Portrait Framing, Components, Customization, Selection, Story Companions, Route, Documents, Battle Layout and UI, Online and Fighter Contact.
- The frame tests all bodies and the Rest, Strike, Entry and Victory actions at 390×844, 1360×880 and 1920×1080: **61,240 checks without failures**. Verify that the camera does not change during the action and that the silhouette remains within its space.
- Combat contact: **1,933 cases of paired movements, 40,882 checks without failures** in seven sizes. Fixed HUD spacing for Ascua large poses.
- 11 suite results (`work/character-presence/results.json`; not included).
- Moving wall updated (`work/character-presence/after/wall-390x844.png`; not included) · Desk wall updated (`work/character-presence/after/wall-1360x880.png`; not included).
- Native captures with disposable profiles and simulated online. No real games are used or modified.

Customize on mobile (`work/character-presence/after/customization-390x844.png`; not included) · Training on mobile (`work/character-presence/after/training-390x844.png`; not included) · Arena on desktop (`work/character-presence/after/arena-idle-1360x880.png`; not included)
