# Balance of the campaign of 100 encounters

Final setup: 100 encounters, eleven chapters, eleven bosses, and nine playable characters. The first sixteen IDs and their statistics are preserved, including level Nima 2. Character level is still limited to 50; the Story Mode encounter number reaches 100.

The final validation comprises **17,610 combats**: 13,135 in 108 campaigns with fixed priorities, 4,314 in 36 adaptive campaigns and 161 to reproduce and recover exactly the single lock of the fixed sample. They all use real CombatEngine and StoryProgression, with saving disabled and seeds registered. No real games were opened or modified.

| Politics | Ended campaigns | Medium combats | Observation |
|---|---:|---:|---|
| Four fixed priorities | 107/108 (99.1%) | 121.62 | Not redistributed during the campaign. |
| Explicit adaptation | 36/36 | 119.83 | Less complete initial priorities; redistribution after 3 or 6 defeats in a match. |

Adaptive samples are **not** presented as wins from a fixed distribution. The JSON records each priority change, its encounter, and the configuration revision. It is proof of the possibility of learning and changing strategies; not a causal experiment between two identical policies.

## Results by character and distribution

| Character | Completed | Combat average | Fighting range | Boss 100 on first try |
|---|---:|---:|---:|---:|
| Nima | 12/12 | 123.92 | 111–146 | 25.0% |
| Luma | 12/12 | 119.83 | 111–133 | 25.0% |
| Mugo | 12/12 | 125.50 | 113–137 | 33.3% |
| Sira | 12/12 | 108.42 | 102–119 | 66.7% |
| Iria | 12/12 | 121.92 | 113–132 | 25.0% |
| Duna | 11/12 | 132.25 | 118–153 | 25.0% |
| Kiro | 12/12 | 108.08 | 102–126 | 75.0% |
| Neris | 12/12 | 113.00 | 105–119 | 33.3% |
| Taro | 12/12 | 141.67 | 123–194 | 41.7% |

| Priority | Completed | Combat average | Average defeats | Unspent points at the end |
|---|---:|---:|---:|---:|
| Balanced | 27/27 | 130.93 | 30.93 | 0.00 |
| Offensive | 26/27 | 123.15 | 23.19 | 6.44 |
| Stamina | 27/27 | 115.48 | 15.48 | 1.67 |
| Rhythm | 27/27 | 116.93 | 16.93 | 0.00 |

Stamina works well in this sample, but it's not the best priority for all characters. Taro takes more attempts than average and that visible difference is preserved in the results. The four priorities legally assign points and maintain distinct decisions; Offense and pace include limited investment in Defense. Six own talents and three choices allow for differences even at the maximum level.

## Bosses and difficulty points

| meeting | Boss | First try won | Medium attempts upon arrival | Average character level |
|---|---|---:|---:|---:|
| 8 | Ascua | 54.6% | 2.05 | 10.58 |
| 16 | Véspera | 66.7% | 1.53 | 20.13 |
| 20 | Taro Jade Oath | 63.0% | 1.57 | 23.62 |
| 30 | Iria · Garden of echoes | 39.8% | 3.04 | 30.42 |
| 40 | Luma · The nine paths | 77.8% | 1.31 | 36.18 |
| 50 | Ascua · Heart of the Solstice | 53.7% | 2.21 | 41.69 |
| 60 | Duna · Strength of Return | 100.0% | 1.00 | 46.69 |
| 70 | Kiro Lightning Roar | 75.9% | 1.36 | 50.00 |
| 80 | Neris · Circle of the teachers | 54.6% | 2.43 | 50.00 |
| 90 | Sira · Edge of the stars | 57.4% | 1.78 | 50.00 |
| 100 | Véspera · The last eclipse | 38.9% | 2.91 | 50.00 |

Bosses 50 and 100 use announced phases and the same hit, damage, resistance, status, and Signature rules as the rest. Solstice's Ascua has 1.070 HP, 76 Attack, 120 Defense, and 23 Speed; his 5% Evasion and preparations for his blows leave opportunities. Final Véspera has 1.020 HP, 85 Attack, 100 Defense and 31 Speed; his Resistance is 28%, he does not heal, and his hard hits are visibly prepared.

The difficulty does not increase with each individual encounter. Boss 60 remains a respite—100% on the first attempt in this sample—while bosses 30, 50, and 100 are clear obstacles. Not all duels were adjusted to 50/50.

| Encounters with greater difficulty observed | First try won | Medium Attempts |
|---|---:|---:|
| 100 · Boss · Véspera · The last eclipse | 38.9% | 2.91 |
| 30 · Boss · Iria · Garden of Echoes | 39.8% | 3.04 |
| 3 · La muralla de ocre | 44.4% | 2.31 |
| 4 · Elite · El filo de cristal | 45.4% | 2.04 |
| 50 · Boss · Ascua · Solstice Heart | 53.7% | 2.21 |
| 8 · Boss · The last bluff | 54.6% | 2.05 |
| 80 · Boss · Neris · Teachers' Circle | 54.6% | 2.43 |
| 9 · The red gorge | 54.6% | 1.67 |
| 11 · The roots of iron | 56.5% | 1.81 |
| 90 · Boss · Sira · Star Edge | 57.4% | 1.78 |

## Recovery of the stopped case

Duna’s offensive build, campaign seed `15311002`, stopped at encounter 100 after reaching the audit limit of 24 attempts. Its 153 battles and final allocation were reproduced exactly. The `respec_build()` API refunded only previously earned resources and preserved level, XP, route and legacies. The balanced priority completed the remaining battle in 8 additional attempts.

This case is preserved as a fixed policy limit; it is not hidden or counted as a victory without redistribution. All identities and 36 character/priority combinations managed to complete at least one of their three fixed replicas.

## Techniques, rhythm and rare events

Average combat duration: **31.12 seconds**. 174 matches reached the limit of 60 seconds (1.3%); the tiebreaker still uses the remaining life ratio. Signature incidence per combatant and game: **0.967%**, compatible with the single run of 1%. Nima's final combo fix counts offensive attempts and not guard stances.

| Identity | Techniques available and used | Actions with techniques |
|---|---:|---:|
| Ascua | 5/5 | 10,469 |
| Duna | 5/5 | 77,701 |
| Iria | 5/5 | 67,140 |
| Kiro | 5/5 | 49,066 |
| Luma | 5/5 | 87,631 |
| Mugo | 5/5 | 69,747 |
| Neris | 5/5 | 89,588 |
| Nima | 5/5 | 64,856 |
| Sira | 5/5 | 50,067 |
| Taro | 5/5 | 73,569 |
| Wait | 5/5 | 13,197 |

| Type | Observed uses |
|---|---:|
| charge | 41,147 |
| counter | 23,592 |
| dash | 49,866 |
| guard | 28,397 |
| heavy | 94,573 |
| jump | 61,969 |
| quick | 318,014 |
| technique | 35,473 |

None of the normal technical 55 of the eleven identities went unused. The statistics include players and rivals; The number of uses or victories associated with a technique do not alone prove its superiority. The AI ​​considers health, statuses, cooldowns, repetition, and stated preferences. The Firms remain outside their normal selection.

## Progression and configuration

- Attribute Points: 3 upon reaching character levels 2–20; 2 upon reaching 21–50. The four elites from the first sixteen matches retain their 2 points. The new elites grant XP, without inflating the attribute budget.
- Technique sheets in the matches 5, 10, 20, 30, 40, 50, 60, 70, 80 and 90. Five techniques, two maximum improvements per technique and cost of one token.
- Talents in 10, 30 and 50: choose three of six character-specific options. Redistribution allows decisions to be changed later.
- Technique unlocks at character levels 1, 1, 5, 12, and 20. The bosses show their five known techniques.
- Defeats retain positive and decreasing XP per repetition; surrendering preserves your reduction and short wait. Practicing overdue encounters grants zero XP and no additional milestones.
- New rivals use different investment budgets, style limits and distributions. Some boxes have a small set of stable identities per character and campaign seed; bosses are never drawn.
- v1/v2 saves are normalized in memory, without advancing chapters or writing during a normal load. The first writing preserves the permanent copy of its version. Points earned with the previous curve are respected through credit limited to their possible historical progress.
- Legacies save profile upon beating the boss, including the 100 encounter. Training or redeploying afterwards does not change that result. Configuration reviews and your history allow you to reinvest without deleting legacies.

Completed fixed campaigns reached character level 50. This leaves technique upgrades from encounters 80 and 90 and character adaptation as post-base growth decisions, without increasing the level cap or introducing hidden bonuses.

## Files and playback

- [Fixed sample: 108 campaigns](campaign100_balance.json)
- [Adaptive sample: 36 campaigns](campaign100_adaptation.json)
- [Lock Playback and Recovery](campaign100_recovery.json)
- [Exported catalog: encounters, techniques and talents](campaign100_catalog.json)

```sh
BRASA_GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
"$BRASA_GODOT" --headless --path outputs/Brasa --script res://tests/simulate_campaign100.gd -- --runs=3
"$BRASA_GODOT" --headless --path outputs/Brasa --script res://tests/simulate_campaign100.gd -- --runs=1 --adaptive --output=res://reports/campaign100_adaptation.json
"$BRASA_GODOT" --headless --path outputs/Brasa --script res://tests/simulate_campaign_recovery.gd
```

The JSONs contain seeds, final distributions, picks, attempts per encounter, technique metrics, and combat source hashes. The 24 attempts per encounter limit is an audit protection, not a probabilistic guarantee. Three replicas per character/priority and one adaptive are finite samples; they do not test all possible inversions or sequences.

Final domain validation: `test_campaign100.gd` 2.117 checks; `test_story_progression.gd` 217; `test_story_chapters.gd` 299; `test_story_campaign.gd` 1.796. All without errors. The engine, interface, and general regression suites are recorded separately in the main report.
