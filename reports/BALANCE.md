# Game balance audit — Brasa

Replayable Final Run: **17,100 battles** with all nine identities, their abilities, and their Signatures enabled. The levels tested are 1, 10, 25, and 50. Fighters use their initial training to isolate differences in character and growth.

## Results

- Average duration: **32.11 s**; median: **30.85 s**; percentiles 10–90: **21.30–44.74 s**.
- Signatures: **330** activations between 34,200 shares (**0.965%**). A single 1% Bernoulli is cast per combatant at the start, never once per attack.
- Hits: **85.5%** from normal attacks/Signature; critical: **11.4%** of impacts.
- Battles resolved by time limit: **0.58%**.
- Added wins for each character by level: **43.9–58.3%**; **0** pairs observed with 0% or 100%.
- A level 1 character defeated his level 4 identity in **8.2%** of 900 encounters. The strongest maintains an advantage, but victory is not guaranteed.

## Victories in front of the entire cast

Each figure is the rate as the left participant against the nine rivals. By level 1, 80 seeds were sampled by ordered pair; by levels 10, 25 and 50, 40. Symmetrical clashes are included.

| Character | Level 1 | Level 10 | Level 25 | Level 50 |
|---|---:|---:|---:|---:|
| Nima | 49.4% | 49.4% | 45.8% | 46.4% |
| Luma | 49.4% | 48.6% | 53.3% | 46.7% |
| Mugo | 48.9% | 49.7% | 49.7% | 56.9% |
| Sira | 45.4% | 45.3% | 49.7% | 47.2% |
| Iria | 43.9% | 45.3% | 46.7% | 51.7% |
| Duna | 56.2% | 51.7% | 51.9% | 48.3% |
| Kiro | 52.1% | 58.3% | 48.3% | 54.7% |
| Neris | 52.6% | 58.3% | 49.7% | 51.9% |
| Taro | 45.3% | 45.0% | 48.6% | 46.9% |

## Matrices by level

Row: player character. Column: rival. The cells indicate the player's winning percentage; Each pair uses different seeds.

### Level 1

| Player/rival | Nima | Luma | Mugo | Sira | Iria | Duna | Kiro | Neris | Taro |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Nima | 49% | 48% | 55% | 51% | 55% | 51% | 50% | 39% | 48% |
| Luma | 52% | 51% | 46% | 55% | 52% | 48% | 42% | 42% | 55% |
| Mugo | 52% | 49% | 48% | 75% | 51% | 21% | 49% | 42% | 52% |
| Sira | 48% | 41% | 30% | 54% | 40% | 56% | 48% | 44% | 49% |
| Iria | 36% | 36% | 54% | 42% | 49% | 39% | 57% | 32% | 49% |
| Duna | 60% | 54% | 75% | 50% | 61% | 40% | 51% | 60% | 55% |
| Kiro | 52% | 50% | 59% | 57% | 56% | 52% | 39% | 40% | 62% |
| Neris | 54% | 57% | 57% | 59% | 64% | 44% | 52% | 39% | 48% |
| Taro | 55% | 45% | 39% | 57% | 45% | 34% | 42% | 35% | 55% |

### Level 10

| Player/rival | Nima | Luma | Mugo | Sira | Iria | Duna | Kiro | Neris | Taro |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Nima | 50% | 50% | 42% | 57% | 50% | 65% | 32% | 40% | 57% |
| Luma | 65% | 48% | 52% | 48% | 70% | 38% | 38% | 48% | 32% |
| Mugo | 65% | 40% | 48% | 75% | 45% | 28% | 52% | 48% | 48% |
| Sira | 57% | 50% | 25% | 48% | 52% | 57% | 28% | 38% | 52% |
| Iria | 48% | 48% | 45% | 50% | 52% | 35% | 48% | 40% | 42% |
| Duna | 65% | 62% | 75% | 30% | 52% | 35% | 22% | 57% | 65% |
| Kiro | 68% | 60% | 57% | 60% | 68% | 62% | 48% | 45% | 57% |
| Neris | 57% | 52% | 70% | 57% | 45% | 55% | 55% | 60% | 72% |
| Taro | 50% | 35% | 42% | 60% | 50% | 40% | 38% | 48% | 42% |

### Level 25

| Player/rival | Nima | Luma | Mugo | Sira | Iria | Duna | Kiro | Neris | Taro |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Nima | 45% | 38% | 42% | 62% | 52% | 52% | 42% | 38% | 40% |
| Luma | 60% | 48% | 40% | 62% | 62% | 62% | 55% | 40% | 50% |
| Mugo | 57% | 50% | 35% | 62% | 38% | 50% | 50% | 45% | 60% |
| Sira | 57% | 48% | 40% | 57% | 40% | 55% | 35% | 68% | 48% |
| Iria | 55% | 52% | 28% | 50% | 45% | 50% | 48% | 45% | 48% |
| Duna | 70% | 45% | 70% | 40% | 48% | 52% | 38% | 50% | 55% |
| Kiro | 50% | 40% | 57% | 60% | 55% | 45% | 45% | 30% | 52% |
| Neris | 52% | 35% | 52% | 55% | 55% | 55% | 45% | 52% | 45% |
| Taro | 48% | 42% | 52% | 50% | 68% | 38% | 42% | 48% | 50% |

### Level 50

| Player/rival | Nima | Luma | Mugo | Sira | Iria | Duna | Kiro | Neris | Taro |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Nima | 48% | 35% | 32% | 52% | 57% | 48% | 45% | 57% | 42% |
| Luma | 40% | 50% | 38% | 57% | 42% | 48% | 48% | 52% | 45% |
| Mugo | 60% | 72% | 50% | 72% | 57% | 48% | 40% | 50% | 62% |
| Sira | 48% | 52% | 28% | 48% | 55% | 57% | 55% | 50% | 32% |
| Iria | 48% | 42% | 57% | 60% | 60% | 35% | 48% | 52% | 62% |
| Duna | 40% | 60% | 60% | 38% | 42% | 52% | 32% | 50% | 60% |
| Kiro | 57% | 52% | 40% | 52% | 65% | 65% | 50% | 52% | 57% |
| Neris | 60% | 40% | 55% | 55% | 55% | 45% | 57% | 45% | 55% |
| Taro | 48% | 42% | 40% | 50% | 60% | 48% | 42% | 38% | 55% |

## Audited rules

- Hit between 62% and 96%, critical between 3% and 32%; Random damage limited to ±8%. Defense reduces with diminishing returns and levels have limited additional influence.
- Each Signature is used at most once, does not combo critical, always hits, multiplies damage between 1.4 and 1.8, and applies a temporary status. Its programming between own actions 2–5 performs approximately 1% of incidence in complete encounters.
- The states last actions of the affected person; an application during an action does not immediately consume a turn. Slowness recalculates the pending time and affects even the duration of a single action. Poison, burn, and bleed ignore shields; their magnitudes and accumulations have explicit limits.
- If both combatants receive periodic damage at the same instant, both damage is resolved before checking the outcome. If both fall, a replayable draw decides the winner and is recorded in the fight history.
- The surrender ends immediately. It advances no effects, generates no subsequent attacks, and produces a single result; the engine never grants experience directly.
- The summary preserves original participants, metrics, end states, and events. Base statistics are never altered by temporary states.

## Verified Balance Changes

Reduced Duna's starting advantage, made Iria's poison grow with its Attack, and adjusted the curves of Neris, Mugo, Nima, Kiro, and Duna. The last run left all aggregates by identity and level within the interval 43.9–58.3%, without aiming for each individual pair to end in 50/50.

## Play

From the Brasa folder:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_combat_v2.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/simulate_balance.gd
```

The simulation writes `reports/balance.json`. To iterate over level 1, `-- --quick` is supported; `--output=/ruta/reporte.json` choose a different file.

## Scope

They are estimates from finite samples, not guarantees of exact probabilities. Not observing a 0% does not prove that all pairs have identical difficulty. The test covers natural growth up to the maximum level, not all possible distributions of training points. Games interrupted or surrendered before the scheduled action may end without consuming a drawn Signature. Progression, migration, and protection against duplicate rewards have separate tests.
