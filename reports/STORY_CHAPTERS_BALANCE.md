# Chapter 2 and correction of level 2

The original route preserves its eight meetings and identifiers. Nima, the second rival, now displays **level 2**. The new **Chapter 2 · The Passage of the Storm** is unlocked after Ascua and is started by an explicit action. Character level, XP, points and upgrades continue; the first legacy is archived.

## Final natural audit

**3,182 combats** were executed with real CombatEngine and StoryProgression, without access to saves: 108 campaigns of both chapters (9 characters × 4 priorities × 3 seeds) and 360 combats to isolate the level adjustment of Nima. **108/108 campaigns completed both chapters**. Each chapter had a safe limit of 40 combats; none came close to that limit.

| Result | Chapter 1 | Chapter 2 |
|---|---:|---:|
| Medium combats | 13.24 | 12.89 |
| Observed combat range | 9–19 | 8–19 |
| Average defeats | 5.24 | 4.89 |
| Maximum losses observed | 11 | 11 |
| Average level upon completion | 11.61 | 21.71 |
| Final Level Rank | 11–13 | 20–23 |
| Boss on the first try | 56.48% | 63.89% |

Priorities are maintained throughout the campaign: there is no reallocation of points when changing opponents or starting chapter 2. The new points are invested in the next priority attribute; If it is at the maximum, continue with the next one. Defeats grant the actual XP for the encounter before retrying.

## Four viable strategies

| Priority | Completed campaigns | Medium combats in chapter 2 | Maximum defeats | Véspera on first try |
|---|---:|---:|---:|---:|
| Balance | 27/27 | 14.59 | 11 | 70.37% |
| Aggression | 27/27 | 13.96 | 9 | 40.74% |
| Stamina | 27/27 | 9.89 | 6 | 74.07% |
| Rhythm | 27/27 | 13.11 | 11 | 70.37% |

- Balance: life, attack, defense, speed, precision, evasion, critical, resistance.
- Aggression: Attack, Attack, Life, Critical, Speed, Accuracy.
- Stamina: health, defense, life, evasion, attack, speed.
- Rhythm: speed, precision, evasion, attack, life, critical.

Stamina is still more efficient in this sample. All priorities complete the route with the nine characters, but that does not imply equivalence between all possible casts. Three seeds per combination allow detecting large blockages and checking the rate of progression; the rates for each small cell are not exact probabilities.

## Dimensioned setting of Véspera

| Parameter/result | First sample | Final version |
|---|---:|---:|
| Life | 730 | 780 |
| Attack | 48 | 52 |
| First try won | 88.89% | 63.89% |
| Medium combats of the chapter | 12.51 | 12.89 |
| Completed campaigns | 108/108 | 108/108 |

The comparison uses the same seeds, priorities and characters. Only Véspera's health and attack have been increased so that the boss retains difficulty after the previous elite. There were no more balance iterations.

Véspera is 23 level: 780 HP, 52 Attack, 30 Defense, 20 Speed, 106% Accuracy, Evasion 22%, critical 18%, critical damage ×1.70 and resistance 30%. His light armor remains a weakness. 60% health gains 10% speed; 30% retains that speed and adds a 8% attack. Its phases use the existing dispatcher; there is no healing, invulnerability, hidden probability or new rules.

His signature Eclipse Dust preserves the normal 1% roll per combat, is used at most once, hits with ×1.65, and reduces the opponent's accuracy 12 points for four target actions; resistance can shorten the duration.

The other rivals in the chapter are Kiro (13), Iria (14), Mugo (16), Nima elite (17), Taro (18), Duna (20) and Sira elite (21). Their profiles distinguish attack, poison, stamina, speed, responses, armor and criticals. Victories give 340–680 XP; defeats, 95–180 XP. Elite milestones retain two additional points.

## Nima fix

The same 180 seeds were compared by version, with the nine 2 level characters and six points distributed. Only the level of Nima was changed in the comparison; the other statistics remained fixed. Player win rate changed from **80.56%** vs. Nima at level 3 to **82.22%** vs. Nima at level 2: **+1.67 points percentages**. The fix does not introduce a large jump in difficulty or change IDs or saved games.

In the entire sample, the average duration was **31.09 seconds**, the incidence of signatures **0.959%** per combatant and game, and there were **62** outcomes per time limit.

## Compatibility and testing

SAVE_VERSION becomes 2. A valid v1 save is only normalized in memory as chapter 1: it is not rewritten on load, the character is not reset, and the second chapter does not start. The first v2 write from the v1 file preserves a permanent copy of `.v1.bak` in addition to `.bak`; a pre-existing valid v1 copy is never replaced.

`start_next_chapter()` freezes the previous legacy and preserves level, XP, points, stats, assignments, and upgrade history. Resets only the route and local counters of the new chapter. If it fails to save, it restores the previous state to prevent a dummy transition. Rewards check character, chapter, ID, and local encounter index. The log of processed rewards remains valid between chapters.

- `tests/test_story_chapters.gd`: **299 checks, 0 failures**. Includes v1 migration, permanent copies, rollback, preservation and reading of the two legacies, chapters per character, rejection of old results and erased growth, limits and Véspera rules.
- `tests/test_story_progression.gd`: **217 checks, 0 failures**, verified after the format change.
- `tests/simulate_story_chapters.gd`: The bounded natural audit described here.

Play the same sample from the project folder:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_story_chapters.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/simulate_story_chapters.gd -- --quick
```

Complete data: [story_chapters_balance.json](story_chapters_balance.json). The original calibration from the first chapter remains as a history report in STORY_BALANCE.md.
