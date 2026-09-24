# Character profile · Attributes and details on demand

| Before | After |
| --- | --- |
| Large block of text with large separations. | Nine grid attributes and two skill cards. |
| Current values, growth, formulas and ranges together. | Current default values; Optional growth and detail when selecting an attribute. |
| Decimals without visual meaning. | Trailing zeros are removed: 19, 94%, 1.5×. The detail retains the precision of the original format. |
| Biography and rules always exposed. | Drop-down sections “Profile and style” and “How it progresses”. |
| Hit Chance Repeated signature. | The actual description of the skill is kept only once. |
| Temporary status text in the subtitle. | Brief role; temporary explanation in optional rules. |

The size, framing and scale of the character are preserved. The tab uses the existing preview component and the same responsive geometry. Materials, typography and focus come from the shared visual system. The text has a maximum width of 720 px; On narrow screens the grid becomes two columns and the skills become one.

## Verification

- **1260 native checks, 0 faults**, in seven sizes (1360×880, 1224×792, 1920×1080, 768×1024, 390×844, 430×932 and 844×390). Includes Training regression, real attributes, touch areas, card limits, focus scrolling, dropdown formulas, and profile immutability when querying.
- **86 identity checks, 0 failures**.
- **94 Story Mode checks, 0 failures**: campaign values, pause when consulting the record and persistence/existing rewards. Updated the old expectation of the Story button: access was hidden in the combat preview. The first pass of this suite preserves those seven expectation failures in `work/profile-ui/story.log`; the final pass is at `story-final.log`.

28 token captures with disposable profiles; Training's eight additional captures are from his regression. Personal saves, combat rules, and backend are not changed. The Story non-combat upgrade tab retains its previous navigation.

[Report index](README.md).
