# Ónix and Bruma · data and balance

`onix` (Ónix, index 13) and `bruma` (Bruma, index 14) are added to the end of the roster: **15 playable companions**. Both are domestic cats with their own atlas. The definitions, techniques and talents of the previous 13 retain their exact text; Neither do the first 16 encounters, the 100 Story Mode pools, the formulas or the League and Story Mode progression schemes change. The identity sidecar does migrate from v1 to v2 to incorporate the new bodies, with [separate validation](CAT_IDENTITY_MIGRATION.md).

## Identity and values

Ónix is black, with yellow eyes: fast and evasive, with little health and armor. Bruma is gray, with greenish eyes: precise, calm and capable of protecting and responding. They are not recolors of another partner.

| Statistics | initial Ónix | Growth | initial Bruma | Growth |
|---|---:|---:|---:|---:|
| Life | 212 | 6.8 | 255 | 8 |
| Attack | 19 | 0.64 | 20 | 0.62 |
| Defense | 11 | 0.42 | 23 | 0.75 |
| Speed | 12 | 0.14 | 5.8 | 0.09 |
| Accuracy | 94% | 0.08 pp | 101% | 0.1 pp |
| Evasion | 20% | 0.07 pp | 10% | 0.05 pp |
| Critical | 13% | 0.07 pp | 11% | 0.07 pp |
| critical damage | 1.5× | 0.0025 | 1.55× | 0.0025 |
| Resistance | 6% | 0.1 pp | 18% | 0.15 pp |

Growth by level up to 20; then the 45% of that increment is applied up to the limit 50. Initial League Training (Life/Strength/Agility/Speed): Ónix 5/6/8/9; Bruma 7/6/5/6. Story Mode maintains its eight independent investments and existing budgets.

- **Ónix — Three Steps of Shadow:** Every third attempted attack does ×1.22 damage if it connects.
- **Bruma — Silence Response:** 20% respond to a hit received with a counterattack of ×0.42 damage.

Signatures: **Midnight Yellow** applies precision −16 points for 3 actions; **Still Fog** applies attack −20% by 3 actions. Both use ×1.6, guaranteed hit, and existing resistance rules. Arming is still one **1% roll per combatant per combat**, at most one execution.

## Techniques and talents

Each cat has five techniques, unlocked at levels **1/1/5/12/20**, and six talents from which a maximum of three can be chosen. Upgrades, tokens and redistribution follow the current rules.

| Companion | Technique | Type | Level | Base multiplier |
|---|---|---|---:|---:|
| Ónix | shadow touch | `quick` | 1 | 0.81× |
| Ónix | Forward career | `dash` | 1 | 0.9× |
| Ónix | Roof jump | `jump` | 5 | 1.08× |
| Ónix | Yellow flashing | `technique` | 12 | 0.81× |
| Ónix | roof fall | `heavy` | 20 | 1.24× |
| Bruma | Accurate touch | `quick` | 1 | 0.88× |
| Bruma | Listen patiently | `counter` | 1 | 0× |
| Bruma | Calm Weight | `heavy` | 5 | 1.25× |
| Bruma | clew guard | `guard` | 12 | 0× |
| Bruma | fog pass | `technique` | 20 | 0.87× |

Zero guards and responses means the stance doesn't hit immediately. Patient Listen reduces 22% damage and provides 42% reply ×0.55 during an action; Tangle Guard reduces 32% and heals 2.5% health. Flashing yellow has 55% to apply −8 precision points for two actions; Fog step, 50% to apply −12% attack by two actions. These states are resistible.

| Companion | Talent | Effect |
|---|---|---|
| Ónix | Roof pulse | His fast attacks gain +6% multiplier and 2 priority points. |
| Ónix | light step | Your runs and jumps earn 3 priority points and recover 0.025 s sooner. |
| Ónix | eyes in the night | Your attacks gain 2.5 precision points. |
| Ónix | silent jump | His jumps gain 3.5 critical points and 1.5 aerial evasion points. |
| Ónix | onyx temple | Reduces one 10% bonus damage from critical hits taken. |
| Ónix | last shadow | Under 35% health you gain 2.5 evasion points, within the limit. |
| Bruma | Serene retort | Their response stances earn 5 replica chance points. |
| Bruma | Firm leg | Your heavy hits earn +6% multiplier and 2 accuracy points. |
| Bruma | Green observation | Your attacks gain 2.5 precision points. |
| Bruma | Mindful rest | His guard heals 1 additional percentage point of health and recovers 0.025 s sooner. |
| Bruma | Fog Temple | Reduces one 10% bonus damage from critical hits taken. |
| Bruma | Gentle echo | The weakening of his technique lasts for one additional action, within the limit. |

## Verification

**721 domain checks, 0 failures.** Portable copies of previous saves were loaded with the 13 profiles, both cats were selected and trained, and the 15 profiles were reloaded. The previous ones remained the same; loading the files did not rewrite their bytes. Limits, IDs, ownership of techniques, deep copies, use of the five moves, determinism versus delta partitions and Single Signature were also verified.

The final simulation contains **6,768 combats**, with registered seeds: 4800 League duels (20 seeds per confrontation and per side, against 15 teammates in four levels) and 1968 campaign combats.

| Companion | League level 1 | Level 10 | Level 25 | Level 50 |
|---|---:|---:|---:|---:|
| Ónix | 50.3% | 51.7% | 48.7% | 44.8% |
| Bruma | 50.7% | 58.5% | 58.7% | 58.7% |

League compares profiles of the same level without training or talents. The lower rate of Ónix at high levels maintains its fragility; Bruma favors long trades. It is not intended that all crosses will have 50% wins.

**16/16 campaigns completed the 100 encounters**, two seeds per cat and per investment priority. The entire legal budget was spent, without redistribution or forced results. They all ended at hero level 50, between 113 and 152 combats.

| Fixed priority | Ónix: medium fights | Bruma: medium fights |
|---|---:|---:|
| balanced | 130.0 | 139.5 |
| aggressive | 123.0 | 121.0 |
| durable | 116.5 | 121.0 |
| time | 115.0 | 118.0 |

The biggest jam was 12 attempts on header 80 with Bruma balanced; header 100 required between 1 and 9. It is a limited sample and does not guarantee the same difficulty for any distribution. Natural use of **the ten new techniques** was recorded, with no unused techniques.

Average duration: 29.75 s; 17 time tiebreakers. There were 118 Signature executions (0.87% per combatant position); This observed frequency does not change the configured 1% roll and a fight may end before it is executed.

Full sources: [data and seeds](cat_roster_balance.json), [validation and hashes](cat_roster_validation.json), [domain proof](../tests/test_cat_roster.gd), [simulator](../tests/simulate_cat_roster.gd). The catalog, engine and progression hashes remain the same at the end of the simulation.

Only fixtures or profiles in memory were used. No real games were accessed. Art, visual integration and export of the online catalog belong to separate verifications; This report does not claim that Cloudflare is published.
