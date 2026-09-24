# Brasa · 100 campaign encounters and techniques

Local validation of September 20 2026, Godot 4.7.2 for macOS.

## Delivery

The Story grows to **100 encounters in 11 chapters**. The first 16 retain their identities and order, including Nima in the 2 encounter. The league maintains its own save and progression. There are nine companions and special versions of Ascua and Véspera; each has five techniques defined in data, in addition to their original skill and Signature Strike.

The character starts with two techniques and unlocks the others at character levels 5, 12, and 20. The techniques have separate preparation, movement, impact and recovery: loads retreat before advancing, jumps describe different trajectories and defensive postures allow probabilistic responses. The engine applies damage on contact and uses common combat limits and formulas. The AI ​​considers health, statuses, cooldowns, speed, and previous actions.

Ten Story Mode milestones grant tokens to improve the five techniques up to two grades. Encounters 10, 30, and 50 offer a talent choice from six character-bound options. Attribute points are three per level up to 20 and two afterward; The migration preserves the points earned in previous games.

The map shows global advancement, next boss, rewards and known rivals. Normal matches can choose opponents from a stable pool during each campaign; The bosses retain their identity. Encounters 50 and 100 have special versions of Ascua and Véspera with announced phases. The preview screen presents styles, strengths, weaknesses, moves and skills; The clues after losing use the data from that fight.

Successful encounters can be replayed as practice without additional XP or rewards. Route defeats give less XP than victories and reduce your reward when repeated. **Redistribute upgrades** returns only resources already spent, allows you to change strategies, and requires confirmation within the game. Maintains level, XP and advancement; The legacies save the configuration with which each chapter was defeated.

The reduced motion option eliminates shifting, flares, and particles while maintaining poses and timing. Rhythm ×2 synchronize simulation and animation; the panels pause both.

## Checked Compatibility

- Story v3 reads v1/v2 without writing when opening or advancing chapters. Before the first write it saves a permanent copy of the previous format, plus regular backup and atomic replacement.
- A recent copy of the v2 live game passed **11 checks** for migration, resources, original files, backup and reload. The actual game was kept out of testing.
- The final application was reopened and Sira was visually verified at level 15, with 205 XP, three points and ten matches passed. The screen recognized four techniques, two tokens, and one talent choice available from the previous milestones.
- The SHA-256 hashes of the actual League and Story Mode files were identical before and after reopening and browsing the update.
- The Signature Strike retains one 1% roll per fighter at the beginning of each match and a maximum of one execution. The new techniques do not repeat that roll.

## Automatic tests

**21 suites, 18,498 checks and zero failures**, plus 11 checks from the actual copy. The details and hashes of the scripts are in [campaign100_validation.json](campaign100_validation.json).

Verified rules, techniques and talents, probabilities and statuses, synchronization on contact, counterattacks that match other preparation, pause and speed ×2, reduced animation, migrations and malformed data, persistence, league, roster, sprites, unique rewards, surrender, chapter progression and legacy, complete campaign, replay and redistribution.

The interface tests cover seven sizes and states of rest, combat and result. **39 native screenshots** were generated: 35 of the Story panel, three of the main scene and a movement sheet. Captures and testing of the 1–100 flow use independent matches and controlled wins to test transitions; balance is measured separately with natural combats.

## Balance

**17,610 fights** were executed in the final validation:

| Exercise | Fighting | Result |
| --- | ---: | --- |
| Nine characters × four fixed builds × three repetitions | 13,135 | 107 of 108 campaigns completed within the limit of 24 attempts per encounter. |
| Nine characters × four builds with redeployment after getting stuck | 4,314 | 36 of 36 campaigns completed. |
| Exact reproduction of the only lock and recovery with redistribution | 161 | Duna offensive reached the same block as the 100 encounter; the balanced build finished eight fights later, conserving XP and path. |

All nine characters and four strategies had completed campaigns. The boss 50 was beaten on the first try at around 54% of the fixed sample and the final boss at 39%. The fights lasted around 31 simulation seconds on average. These results limit the behavior of the seeds and strategies measured; They do not guarantee that every point distribution will expire in a fixed number of attempts.

The [balance report](CAMPAIGN100_BALANCE.md) documents settings, curves, characters, movements, and measurement limits. Playable data is in [fixed campaigns](campaign100_balance.json), [adaptive campaigns](campaign100_adaptation.json), and [lockdown recovery](campaign100_recovery.json). The simulator uses the real engine and rewards, with reproducible seeds and saving disabled.

## Captures

### final route

![91–100 Story Mode Encounters](campana100-ruta.png)

### Fight against the final boss

![Sira vs. final version of Véspera](campana100-batalla.png)

### Preparation, movement, contact and recovery

![Poses of charges, movements, jumps, strong blows, guard and fast attacks](campana100-movimientos.png)

Also included are [Final Chapter Legacy](campana100-legado.png) and [portrait talents](campana100-movil.png).

## Play

The [README](../README.md) contains instructions for opening the project and running the tests. The catalogs `move_catalog.gd`, `campaign_config.gd` and `story_catalog.gd` centralize techniques, curves, milestones, variants and chapters. Simulations and tests live in `tests/`; Modifying this data allows you to expand the campaign while preserving the common engine.
