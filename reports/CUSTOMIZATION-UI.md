# Your companion · Compact controls and expanded view

## Hierarchy and proportions

| Before | After |
| --- | --- |
| Cancel and Save took up the full width of the footer. | Buttons up to 132 and 200 px, aligned to the right, with 12 px between them. The touch area and keyboard focus are preserved. |
| The figure increase had a fixed limit of 1,90 even if there was space left over. | The figure takes advantage of the space of its common chamber. Each body maintains its physical proportions; heights are not equal. |
| “Combinations…” took up the entire row and did not explain its function. | “Apply style…” occupies a bounded row next to “Random”. When you open it, "Color, effects and gestures" appears; The help explains that it preserves body and name. |
| Text near the ends of the selector and its arrow. | Own interior margins for the text and space reserved for the arrow, using the same shared materials. |
| "Randomly" had a generic explanation. | He explains that he tests the body, colors and effects of the collection; They are only saved when confirming. |

Presentation change in `customization_panel.gd`. Painted styles, standalone draft, unlock requirements, and existing actions are maintained. On mobile, the frame limited by the available space is preserved; The extension takes special advantage of the large windows.

## Verification

- Layout and behavior: **2432 checks, 0 failures**, seven sizes, create/edit, draft, cancel, confirm, locked cosmetics, and random selection.
- Settings: **61289 checks, 0 failures**. The 21 appearances share an action camera in three sizes; rest, hit, entry and victory are cycled through to check limits and absence of scale changes during each animation.
- Focus and closing of windows: **74 checks, 0 failures**.
- Integrated captures from Main: **13 checks, 0 failures**, desktop and mobile.
- Additional native captures: Ónix, Mugo, Tepa and Nima; open selector. Captures are local or memory fixtures and do not modify user games.

[Report index](README.md). Original logs, metrics and PNG: `work/customization-ui/`.
