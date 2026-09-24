# Training: clarity and contextual help

The layout now groups character and training in a limited width block, with readable cards and more separation. The available points stand out next to the name; experience and cost take a backseat. Existing values ​​and progress rules are preserved.

[Report index](README.md).

| Before | After |
| --- | --- |
| Statistics spread across half a screen without clear grouping. | Centered composition, column up to 620 px, four cards with translucent background and spaces of 20 px. |
| Effects mixed with permanent explanatory phrases. | Current effect and calculated preview of next point; short explanation only when pressing `?`. One open explanation at a time. |
| Small and distant number of points. | Highlights, no-points status, and text explaining how to get them. Cost indicated only once. |
| Buttons disabled with no help usable. | Help remains active when points are exhausted; improve is still blocked when applicable. |
| Focus and hover little connected with the attribute. | Card and button material respond to hover/focus. The improvement focus uses color, without an outer white outline. |
| Few signs after improvement. | Value and preview are updated; confirmation of improvement and remaining points. Explicit warning if the change could not be saved. |
| Two narrow columns in mobile. | A column when 560 px are missing; 48 px buttons and help, keyboard scroll and scroll to the explanation when opening it. |
| Permanent instructional subtitle and footer. | Short title, without redundant instructions. The character maintains the proportions of the shared system. |

## Verification

- Documents/training: **756 checks, 0 failures in seven sizes**. Dropdown help, focus, text, limits, exact cost of a point, persistence in disposable files and keeping the campaign separate.
- Actual navigation from menu: **327 checks, 0 faults**.
- Eight native captures: with points, help, applied enhancement and without points, to 1360×880 and 390×844. They use Ónix for testing; Their numbers do not correspond to a real account.
- The preview calculations come from the same game statistics function. There are no new rules, rewards or balance changes.

Functional and native log (`work/training-ui/final.log`; not included) · Navigation log (`work/training-ui/navigation.log`; not included).

The comparison uses the capture provided by the user. The first automated attempt to capture the previous state found damage scripts in transition and is not used as evidence. The final screenshots were obtained without compilation or execution errors. No art was generated or modified for this task.
