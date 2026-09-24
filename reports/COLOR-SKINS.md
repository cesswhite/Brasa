# Color and skins · Collection and appearance tests

## Interaction and hierarchy

| Before | After |
| --- | --- |
| A color point of 10 × 10 px. | Samples of three shades of 56 px height, name and status; visible selection without depending only on color. |
| Five palettes. | Twelve palettes: Cempasúchil, Turquoise, Grana, Cocoa, Ivory, Copper and Amethyst are added. |
| The appearances of family were mixed with all the bodies. | Within Color, a Colors / Skins selector brings together the six special skins already drawn. The Body list retains your options. |
| The variants were miniatures that were not very descriptive. | Cards with figure, name and requirement; three columns on large screens, two on medium screens and compact rows of skins on mobile. Shared framing and the difference in volume are preserved. |
| Choosing a locked item only produced a warning. | It can be tested on the companion with its requirement visible, without disturbing the draft or inventory. Save is disabled and Return restores the selection. The controller also rejects saving a locked preview. |
| The list returned to the top when choosing. | Preserves scrolling and focus when selecting; section changes have a valid keyboard destination. |
| Long footer instructions. | Short instructions; Expanded description when hovering over an option. The compact buttons from the previous revision are retained. |

The swatches represent the shades of each palette. The result on the character is shown with its real renderer: it preserves the illustration and its transparency. No sprites were generated or existing skins replaced.

## New colors and unlocks

| Palette | Requirement |
| --- | --- |
| Cempasuchil | Level 2 with one fighter |
| Turquoise | Level 3 with one fighter |
| Grana | Story Mode encounter 4 |
| Cocoa | 3 League victories with a fighter |
| Ivory | Level 6 with one fighter |
| Copper | Story Mode encounter 12 |
| Amethyst | 8 League victories with a fighter |

Original, Jade and Nightfall remain available from the beginning; Luna and Tinta maintain their requirements. Existing inventory receives rewards through its regular progress check, without restarting identities or games.

The skins retain their existing requirements: Roque / Cora / Ámbar at encounters 21 / 22 / 23, and Sabino / Pedernal / Nieve at 61 / 62 / 63. They are awarded automatically upon passing those encounters. Trying them here does not grant ownership. They are cosmetic and do not increase statistics.

## Validation and scope

- **3133 interface checks, 0 failures:** seven sizes, colors and skins, creation and editing, locked test, return, non-overlapping requirements and draft preservation. It is also verified that the twelve palettes alter the pigment and exactly preserve the alpha of the sprite.
- **1032 identity checks, 0 failures:** throwaway games, exact encounter unlocks, no early rewards, persistence, subsequent reads, and write failures.
- **74 focus checks, 0 faults.**
- **11 local server tests, 0 bugs:** families, new palettes and identity operations. All seven colors are validated before/at their threshold; The server refuses to equip unpossessed options and retains statistics.
- Cosmetic catalog version 3 exported and synchronized with the generated copy from the backend. **Not published on Cloudflare:** The seven new colors require publishing that catalog to unlock and equip them online. All six skins already had server integration.

Fixtures use in-memory profiles or test files. No personal games or remote data were modified. [Report index](README.md); logs, PNG and metrics in `work/color-skins/`. The screenshots of `editor/` correspond to the final state with the short help; `final/` contains the functional matrix, preceding only that text wrap.
