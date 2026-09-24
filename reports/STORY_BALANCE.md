# Story: Progression and Combat Audit

This report corresponds to the first installment of chapter 1. The correction of the second rival at level 2 and the expansion to two chapters are documented in [CAPITULO-2.md](CAPITULO-2.md).
The final sample contains **20,197 battles and 432 complete campaigns**, spread across the nine characters and four upgrade priorities. The 432 campaigns reached Ascua and defeated him. The average was **13.42 fights and 5.42 defeats**; the 90 percentile was 17 combats and the maximum observed, 20. The boss fell on the first try in **46.8%** of the campaigns.

## Method

Used Godot 4.7.2 and the real engine with fixed seeds: 11.520 single encounters (9 characters × 4 styles × 8 encounters × 40 seeds), 2.880 level controls 1 and 432 campaigns (12 by character and style combination). The campaigns added other 5.797 combats. The distributions persist between matches: there is no free reallocation of points. When an attribute limit is reached, the next priority of the same style is moved to.

The isolated matrix assumes that all previous fights were won. Complete campaigns incorporate XP from each defeat before retry, the character's own growth, and new level points and milestones. The simulation has a security break from 40 combats; no campaign reached it. Does not read or write saved. An additional test runs through the 36 combinations with StoryProgression real and saved disabled to verify that the engine, rewards, and progression results match this audit.

## Route and initial level

The following figures are the player's wins upon arrival with XP from previous wins, without adding losses. The player has 3 starting points, 3 per level and 2 for each elite surpassed. The player levels are 1, 2, 4, 5, 6, 7, 8, and 9; the rivals are level 1, 3, 4, 5, 7, 8, 9 and 12.

| meeting | Rival profile | Medium | Balance | Aggression | Stamina | Rhythm | Level control 1 |
|---|---|---:|---:|---:|---:|---:|---:|
| 1 Luma | Balance and adaptation | 74.8% | 77.5% | 77.2% | 81.7% | 62.8% | 81.7% |
| 2 Nima | Speed and combos | 74.6% | 71.9% | 76.1% | 77.5% | 72.8% | 36.1% |
| 3 Duna | Armor and shields | 35.8% | 34.7% | 37.2% | 41.4% | 29.7% | 0.0% |
| 4 · Sira · Elite | Accuracy and critical | 41.5% | 34.7% | 46.4% | 49.4% | 35.3% | 0.0% |
| 5 Iria | Poison and resistance | 39.0% | 32.5% | 38.9% | 53.1% | 31.4% | 0.0% |
| 6 Neris | Evasion and unique recovery | 42.8% | 31.1% | 40.6% | 58.3% | 41.1% | 0.0% |
| 7 · Taro · Elite | Life and counterattacks | 19.5% | 8.6% | 16.9% | 41.9% | 10.6% | 0.0% |
| 8 Ascua Boss | Progressive pressure and phases | 12.7% | 4.7% | 6.9% | 33.3% | 5.8% | 0.0% |

The first fight retains normal Luma stats; The three free points allow a moderate initial advantage. The 1 level controls use those three points in the Balance pattern. They did not win any of the 3–8 encounters in the 360 encounter samples: the starting character cannot comfortably navigate the route without upgrading. An observed 0% does not prove mathematical impossibility.

The difficulty is not a uniform percentage increase. Sira is a crit threat with low defense; Iria needs time to accumulate poison; Neris dodges and recovers only once; Taro hold on and reply. The probability of winning may increase slightly when changing opponents due to the improvements received and matchups.

## Campaigns by character

| Character | Completed | Medium combats | Average defeats | Boss on the first try |
|---|---:|---:|---:|---:|
| Nima | 48/48 | 13.25 | 5.25 | 41.7% |
| Luma | 48/48 | 14.04 | 6.04 | 31.2% |
| Mugo | 48/48 | 14.17 | 6.17 | 56.2% |
| Sira | 48/48 | 13.29 | 5.29 | 50.0% |
| Iria | 48/48 | 13.50 | 5.50 | 47.9% |
| Duna | 48/48 | 12.83 | 4.83 | 39.6% |
| Kiro | 48/48 | 12.06 | 4.06 | 56.2% |
| Neris | 48/48 | 12.88 | 4.88 | 56.2% |
| Taro | 48/48 | 14.75 | 6.75 | 41.7% |

The average level upon completion was 11.66. Retries give positive XP, they do not rewind the route or remove points. Victories provide between 120 and 300 XP; the defeats, between 40 and 85. Surrender has its minor reward and short wait, and is not part of these simulated campaigns.

## Upgrade Styles

| Style | Repeated priority | Completed | Medium combats | Boss on the first try |
|---|---|---:|---:|---:|
| Balance | Life, Attack, Defense, Speed, Accuracy, Evasion, Critical, Stamina | 108/108 | 14.77 | 33.3% |
| Aggression | Attack, Attack, Life, Critical, Speed, Accuracy | 108/108 | 13.30 | 38.0% |
| Stamina | Life, defense, life, evasion, attack, speed | 108/108 | 11.19 | 77.8% |
| Rhythm | Speed, Accuracy, Evasion, Attack, Life, Critical | 108/108 | 14.43 | 38.0% |

| Character | Balance: fighting | Aggression: fighting | Stamina: combat | Rhythm: fighting |
|---|---:|---:|---:|---:|
| Nima | 15.67 | 13.00 | 10.58 | 13.75 |
| Luma | 15.75 | 14.17 | 10.67 | 15.58 |
| Mugo | 15.83 | 13.67 | 13.00 | 14.17 |
| Sira | 14.50 | 13.75 | 11.08 | 13.83 |
| Iria | 14.00 | 13.08 | 11.00 | 15.92 |
| Duna | 13.08 | 13.25 | 10.75 | 14.25 |
| Kiro | 13.42 | 11.17 | 10.83 | 12.83 |
| Neris | 14.33 | 12.58 | 10.42 | 14.17 |
| Taro | 16.33 | 15.00 | 12.33 | 15.33 |

Stamina is the most efficient strategy in this sample, especially against Ascua. It continues to suffer defeats on the route and the other three strategies also complete all campaigns with a limited number of retries. Equivalence is not promised between all distributions: spending all the points on an attribute that is not relevant to an encounter can greatly delay progress. These four patterns are a practical sample; They do not exhaust the possible distributions nor do they replace player observations.

## Ascua and shared rules

Ascua uses a unique volcanic guardian atlas (`ascua-v3.png`). This visual update preserves the measured balance. His public stats are 550 HP, 38 Attack, 48 Defense, 6 Speed, 97% Accuracy, 6% Evasion, 13% Critical, Critical Damage ×1.55 and resistance 35%. Level 12 falls into the same level bound setting as any character.

- Above Health 60%: Starting stats.
- At 60% or less: attack +8%.
- At 30% or less: Conserve that attack and gain speed +15%.

Phases are announced upon crossing the threshold and also appear in the execution statistics. Velocity preserves progress already made towards the next action. Negative statuses still work, global limits are still in effect, and the boss has no healing, invulnerability, or out-of-turn attacks.

The Burning Night uses the same 1% roll per combatant per game, activates at most once and hits with ×1.7 without crit combo. Applies −18% attack for three target actions. The hit follows the ordinary variation of ±8%. The base signature roll for the boss is not altered.

Across the audit: average duration **30.37 s**, percentiles 10–90 **19.73–42.98 s**, **86** time limits (**0.43%**) and incidence of signatures **1.013%** per combatant and game. Early level checks against late opponents are also part of these durations.

## Clues and checks

Defeat tracks use actual counts: misses on attempts, actions on both sides, status damage recorded, damage per hit, and outcome per time. Resistance is only mentioned when it shortened a duration or when the same roll would have applied the effect without resistance and prevented it with it. It does not consume an additional roll or confuse a normal skill failure with resistance.

- `tests/test_story_combat.gd`: 518 checks on catalog, attribute independence, limits, phases, states, lethal signatures, surrender, simultaneous DoT, seeds/delta and tracks.
- `tests/test_story_campaign.gd`: 1.575 checks, 36 campaigns with the actual adapter and a save-to-memory implementation only.
- `tests/simulate_story.gd`: Generates the complete data for this audit.
- `reports/story_balance.json`: All sample cells and results by character/style.

Play from project folder:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_story_combat.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_story_campaign.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/simulate_story.gd
```
