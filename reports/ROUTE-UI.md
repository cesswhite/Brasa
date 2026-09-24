# Story Mode · A clearer route

| Before | After |
| --- | --- |
| Opponent's name and title repeated, emblem empty, practice texts duplicated. | Encounter and status, a name, level and a brief explanation. |
| All combat details exposed. | “Knowing your rival” displays strength, weakness, skill and techniques. |
| Rival up to 470 px and extensive introduction. | Reserve 300 px in desktop, 180 in stacked view and 160 in low window. Its proportion is preserved. |
| Brand and XP competed with the immediate decision. | Chapter, character, level and points available; XP is still in its progress views. |
| Selector repeated the entire title of the chapter. | Compact chapter and encounter range selector; map and a single progress bar. |
| Repeat took up almost the entire foot and continuing required searching for another tab. | Compact buttons: repeat as secondary action and continue as primary, aligned to the right. |
| Decorative objects on the map. | Landscape and materials are preserved, objects superimposed on Route are omitted. |

## Actions

The current combat has its usual enter or retry action. When consulting previous encounters, “Repeat” appears next to “Continue history”: repeat broadcasts the practice of the selected encounter; continue returns to the current encounter. If the chapter is completed, continue requests the next one using the existing driver. After the last chapter it leads to Achievements.

Future encounters show “Blocked” and an action to return to the current campaign. Timeouts and save protection still apply. Replays retain the caveat that they do not provide XP or rewards.

Buttons retain 48 px touch height; They have bounded widths of up to 240 px. On the phone, the labels (“Repeat 30”, “Continue”) are shortened to avoid cuts and overlaps. The foot remains accessible when moving.

## Verification

- **1498 native checks, 0 failures**, seven sizes and 28 screenshots: current encounter, open help, blocked encounter and chapter passed. Validated limits and separation of buttons, readable text, optional details, separate repeat/continue events, protected save and immutable profiles.
- **436 StoryPanel checks, 0 failures**. Updated the expectation for the old tag “Character Lv.” level"; navigation, maps, cooldowns and chapters preserved.
- **94 Story Mode integration checks, 0 failures**. Persistence and existing rewards.

Gallery data is fixtures in memory. No changes were made to personal items, balance, rewards or backend. Reuse existing art and materials. [Report index](README.md).
