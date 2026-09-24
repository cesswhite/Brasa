# Balance of Balam, Tepa, Xuna and Copal

The extension adds four identities to the end of the catalog: **Balam (jaguar), Tepa (teporingo), Xuna (xoloitzcuintle) and Copal (cacomixtle)**. Xoloitzcuintle identifies a Mexican breed of dog. 0–8 indexes, original definitions, first 16 encounters, and all campaign pools retain their previous content.

**Final result: 48/48 complete campaigns and 14,082 simulated combats**, without modifying the real saves. The mastery test adds **816 checks, 0 failures**. The input data is registered with SHA-256 in [mexican_roster_balance.json](mexican_roster_balance.json).

## Method

- League: 8,320 duels at hero levels 1, 10, 25 and 50, against the 13 identities, without training or talents. Each pair uses 20 seeds and is tested on both sides. Identity facing itself is also part of the exhibition.
- Story: four characters × four investment priorities × three seeds = 48 natural paths of 100 encounters. The actual progression adapter is used, including XP for defeats, limits, milestones, five techniques, upgrades, and selecting three talents from six.
- Priorities are maintained throughout the journey; Available legal points are spent and no redeployment, dummy rewards, Forced Signature, XP replay, or manual move selection are used. Each encounter is limited to 24 attempts and each campaign to 500 combats.
- `tests/simulate_mexican_roster.gd` contains the seeds, priorities and reproducible commands. Saving is disabled on your memory adapter. Persistence testing uses separate test directories; the portable baseline is at `tests/fixtures/roster-before-mexican.json`.

## League at the same level

Percentage of victories over all rivals; each cell contains 520 duels. Specialties and matchups remain different: 50% is not required against each opponent.

| Character | Level 1 | Level 10 | Level 25 | Level 50 | Total |
|---|---:|---:|---:|---:|---:|
| Balam | 60.4% | 54.6% | 57.5% | 57.1% | 57.4% |
| Tepa | 41.2% | 50.6% | 48.7% | 50.2% | 47.6% |
| Xuna | 55.6% | 40.0% | 49.8% | 44.2% | 47.4% |
| Copal | 50.0% | 46.5% | 53.8% | 61.2% | 52.9% |

The first trial found Balam too strong at all levels, Copal especially strong at the beginning, and Xuna weak before having its full repertoire. Only its bases and growths were adjusted. Tepa retains its initial values. The second pass fixed the data before the final sample; They do not change engine constants, old characters or enemies from Story Mode.

## Natural campaigns

Each character and priority cell contains three paths. “Losses” is the average number of attempts lost; wins for a full campaign are always 100.

| Character | Priority | Complete | Medium combats | Fighting range | Average defeats |
|---|---|---:|---:|---:|---:|
| Balam | Balance | 3/3 | 118.7 | 117–120 | 18.7 |
| Balam | Attack | 3/3 | 112.0 | 111–113 | 12.0 |
| Balam | Stamina | 3/3 | 108.7 | 105–111 | 8.7 |
| Balam | Mobility | 3/3 | 112.7 | 111–116 | 12.7 |
| Tepa | Balance | 3/3 | 128.7 | 125–134 | 28.7 |
| Tepa | Attack | 3/3 | 122.7 | 120–127 | 22.7 |
| Tepa | Stamina | 3/3 | 119.3 | 114–124 | 19.3 |
| Tepa | Mobility | 3/3 | 113.0 | 110–116 | 13.0 |
| Xuna | Balance | 3/3 | 134.3 | 126–144 | 34.3 |
| Xuna | Attack | 3/3 | 118.7 | 117–120 | 18.7 |
| Xuna | Stamina | 3/3 | 116.3 | 115–118 | 16.3 |
| Xuna | Mobility | 3/3 | 121.7 | 116–125 | 21.7 |
| Copal | Balance | 3/3 | 126.3 | 124–128 | 26.3 |
| Copal | Attack | 3/3 | 128.0 | 122–138 | 28.0 |
| Copal | Stamina | 3/3 | 116.3 | 112–125 | 16.3 |
| Copal | Mobility | 3/3 | 123.3 | 117–127 | 23.3 |

The 48 campaigns added **5,762 combats and 962 defeats**: average 120.04, range 105–144. The biggest jam in the same stage was **24 attempts**, with Copal, attack priority, repetition 3, encounter 100. No case required changing characters or redistributing investment.

Priorities are repeated sequences, not attribute multipliers:

- Balance: health, attack, defense, speed, precision, evasion, critical and resistance.
- Attack: attack, attack, life, speed, critical, accuracy, defense and life.
- Stamina: health, defense, life, attack, speed, evasion and precision.
- Mobility: speed, precision, evasion, attack, life, critical and defense.

Talents and technique upgrade order also vary by priority. The JSON preserves each final assignment, its three talents and the levels of the techniques; builds with fictitious points or different budgets are not compared.

## Bosses and difficulty levels

The rate corresponds to the first attempt of each boss; The hero's level is measured after solving that encounter.

| meeting | Victory on the first try | Hero level (min–max) | Medium Attempts |
|---|---:|---:|---:|
| 8 | 52.1% | 11–12 | 2.04 |
| 16 | 66.7% | 20–23 | 1.44 |
| 20 | 64.6% | 24–26 | 1.60 |
| 30 | 54.2% | 30–32 | 2.65 |
| 40 | 83.3% | 36–38 | 1.19 |
| 50 | 54.2% | 42–43 | 2.17 |
| 60 | 100.0% | 47–48 | 1.00 |
| 70 | 89.6% | 50–50 | 1.10 |
| 80 | 43.8% | 50–50 | 2.19 |
| 90 | 58.3% | 50–50 | 1.77 |
| 100 | 39.6% | 50–50 | 3.35 |

Encounters with lower rate on the first attempt (includes elites and common rivals):

| meeting | First attempt | Fights / victories |
|---|---:|---:|
| 4 | 35.4% | 102 / 48 |
| 100 | 39.6% | 161 / 48 |
| 11 | 41.7% | 104 / 48 |
| 3 | 43.8% | 102 / 48 |
| 80 | 43.8% | 105 / 48 |
| 9 | 50.0% | 79 / 48 |
| 8 | 52.1% | 98 / 48 |
| 30 | 54.2% | 127 / 48 |

## Techniques, skills and Signatures

| Character | Skill | Signature (1% per combat, once) |
|---|---|---|
| Balam | Look Between the Leaves: His critics ignore the 30% of the opposing defense. | Spotted Night: Accurate hit ×1.65 and rival defense −20% during 3 target actions. |
| Tepa | Four Jumps: Every fourth attack attempt does ×1.3 damage if it connects. | Sun Leap: Accurate hit ×1.55 and rival speed −22% during 3 target actions. |
| Xuna | Serenity of the Path: Reduces the additional damage from critical hits received by 30%. | Beacon of the way: accurate hit ×1.6 and opponent healing −35% during 4 target actions. |
| Copal | Cross-Branch Response: 20% respond to a hit received with a counterattack of ×0.4 damage. | Moon Round: Accurate hit ×1.6 and rival precision −14 points during 3 target actions. |

The AI used **20/20 new techniques**. The following count excludes Signatures and automatic replicas; a guard counts as a chosen technique, even if it gives up an attack.

| Character | Uses by technique |
|---|---|
| Balam | Claw contained: 34,165; Jaguar Weight: 15,434; Mount Rush: 7,753; Patient stalking: 5,246; Speckled Drop: 6,503 |
| Tepa | Fleeting paw: 40,981; Zacatón jump: 17,013; Cross Stroke: 16,889; Volcano Jump: 7,589; Trail Dust: 6,189 |
| Xuna | Serene Fang: 55,586; Threshold guard: 6,865; persistent Brasa: 11,971; Stone Step: 13,497; Wake Upload: 7,962 |
| Copal | Ringed Feint: 44,327; Passage between branches: 23,419; cacomixtle wait: 5,611; Restless Shadow: 8,203; Branch detour: 8,473 |

The average duration of the set was **30.22 s**; 67 matches (0.48%) reached the normal tiebreaker of 60 s. 297 Signatures were executed: **1.055% per participant**. This figure measures Signatures executed, not just armed: a combat can end before the activation turn. The arming probability remains exactly at the central Bernoulli roll of 1%.

## Compatibility and sample limits

- The new IDs occupy the indexes 9–12: `balam`, `tepa`, `xuna`, `copal`. No previous index is moved.
- Old character definitions are preserved byte-by-byte. Data from previous movements is preserved, with the closing comma necessary to add entries; The resolved values ​​of all your techniques and talents are compared exactly against the baseline.
- All four use existing skill categories with their own names and parameters; No other dispatcher is added nor is the Signature roll changed. Its five techniques follow the unlocks 1, 1, 5, 12 and 20, the two upgrade levels and the usual limits.
- The test reloads old profiles from League v2 and Story Mode v3, checks that the read does not write the files, adds the four profiles and returns to the original progress and its Legacy without altering them. The points, talents, techniques, selection and redistribution of the four are checked in test files.
- The tests run matches with different time steps and compare full summaries; They verify the use of the twenty techniques and a real Signature of each identity, always accurate, with its debuff declared and without actions after the end.
- The League measures bases without training. The campaigns cover four fixed priorities and three seeds per combination; They do not represent all random assignments, pairings, or sequences. The results show viability and useful differences, not invulnerability or absence of difficulty peaks.

## Playback

```sh
./Godot --headless --path outputs/Brasa --script tests/test_mexican_roster.gd
./Godot --headless --path outputs/Brasa --script tests/simulate_mexican_roster.gd
```

Replace `./Godot` with the installed executable. Validated with Godot 4.7.2. The JSON report records the complete final definitions, results per pair, path of each campaign, builds, uses of techniques and hashes of the six domain sources that fed the simulation.
