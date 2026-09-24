# Mexican fauna in Brasa

**Four new characters; 13 playable in total.** Each one has five techniques, six talent options - you can choose three - and eight poses with transparency.

| Character | Inspiration | Style |
|---|---|---|
| Balam | jaguar | Stalking, charges and crits. |
| Tepa | Teporingo | Jumps, speed and evasion. |
| Xuna | Xoloitzcuintle, Mexican breed of dog | Resistance, guard and wear. |
| Copal | Cacomixtle | Feints, movements and counterattacks. |

![Gallery of the four companions](companeros-mexicanos.png)

The four atlases were generated with the native imaging tool. Each final file is identical, byte-for-byte, to its generated source and preserves eight RGBA poses of 1774 × 887. Tepa hit anatomy corrected based on user observation; His eight poses and the result within the combat were reviewed. It was also verified that full tails and limbs remain visible on the tiles and the moving arena.

![Tepa bug fix](tepa-golpe-corregido.png)

The [art report](../assets/sprites/FAUNA-MEXICANA.md), [full prompts](../assets/sprites/fauna-mexicana-prompts.md), and [sources and hashes manifest](../assets/sprites/fauna-mexicana-origen.json) preserve the provenance of the final four atlases.

## Final validation

| Check | Result |
|---|---:|
| 22 domain, interface, combat and campaign suites | 22.707 checks; 0 faults |
| Interface Smoke | PASS |
| 3 suites with native rendering | 5.167 checks; 0 faults |
| Persistence on isolated copies of current saves | 318 checks; 0 faults |
| Native review captures | 40 PNG: 6 combat/gallery, 23 sprites, 11 tokens/roster |

The main 23 logs include the 22 suites and the smoke. Native tests recheck behavior with rendering; their figures are presented separately. The gallery, the corrected hit, the eight poses of Tepa and Copal, combat and mobile token of Copal, and the horizontal roster have been revised. The [structured results](fauna-mexicana-validation.json) records each log and its hash, captures, art and balance sources.

## Balance and progress

The final simulation completed **48/48 campaigns of 100 encounters**, with four priorities and three seeds per character: **14.082 combats**, of which 8.320 are League duels and 5.762 are Story Mode duels. The twenty new techniques were used. The average was 120,04 combats per campaign and 30,22 seconds per combat. The [balance report](MEXICAN_ROSTER_BALANCE.md) details stats, bosses, builds, and sample limits; all six hashes from your sources match the final code.

The new IDs are added after the existing nine. The old definitions, the first 16 encounters and the campaign pools are preserved. Persistence tests check the selection of the four characters, their separate profiles in League and Story Mode, and returning to existing profiles and Legacies without losing fields. The 318 checks were run on isolated copies; was not repeated in preparing this document.

The application was reopened and the two actual saves retained exactly the same bytes, verified by SHA-256 before and after. No profile was reset.
