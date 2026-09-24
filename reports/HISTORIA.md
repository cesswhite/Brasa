# Story Mode Validation

This report corresponds to the first installment of chapter 1. The correction of the second rival at level 2 and the expansion to two chapters are documented in [CAPITULO-2.md](CAPITULO-2.md).
Implemented and verified with Godot 4.7.2 on macOS on September 20, 2026.

## Experience

The **Story Mode** button, next to Menu, opens the campaign choice. The nine companions start with their normal profile at level 1, regardless of their progress in the league. Each character retains their own route, level, XP, points, upgrades, defeats, retries, and badge.

The route has eight meetings and two elites. Each opponent uses explicit stats from the Story Mode catalog: speed and combos, armor and shields, criticals, poison and resistance, evasion and recovery, counterattacks, and a final boss. The preview shows character, level, profile, strength, weakness and skill. The rival profile remains identical between retries.

There are eight upgrade options, looking at current and next value: Life, Attack, Defense, Speed, Accuracy, Evasion, Critical, and Resistance. Decisions preserve the differences between archetypes. The campaign delivers three initial points, three per level and two per defeated elite. Natural growth remains unique to each character.

Defeats grant XP and do not reverse the route. Clues are based on the ratio of missed attacks, actions taken, damage taken, status damage, and resistance observed. Resistance is identified by the combat roll itself: an application that failed its base probability is not falsely presented as resisted.

**Ascua**, Keeper of the Last Lantern, uses the common engine. His ability announces the phases: 60% of life gains 8% of attack; 30% retains that attack and gains 15% speed. He does not regain life or gain invulnerability. Your signature maintains the roll of 1% per combat and the maximum of one activation; deals ×1.7 damage and reduces attack by 18% for three of the target's own actions.

When finished, the result preserves the sand. **Legacy** shows final level, statistics, differences from level one, battles, losses, retries and assignments, and awards the **Keeper of the Lanterns** badge. A new campaign with another character keeps the journey completed.

## Persistence and rules

Story Mode uses `brasa_save.json.story.json`; the league retains `brasa_save.json`. The new adapter validates version, mode, point budget, sequential path, and identity of each result before writing. Uses temporary file, atomic replacement and backup. Rewards are idempotent even after reloading. An invalid file is protected or recovered from a copy while preserving the original.

Rivals are defined in `story_catalog.gd`; There is no hidden difficulty multiplier for being in Story Mode. The engine's only new ability is a phased declared ability, used by Ascua. Normal combat retains its rules and sequence of rolls.

## Verification

| Suite | Checks | Failures |
| --- | ---: | ---: |
| Core and compatibility | 185 | 0 |
| league combat | 396 | 0 |
| League progression and saving | 563 | 0 |
| Sprites | 258 | 0 |
| League squad | 283 | 0 |
| Battle distribution | 2139 | 0 |
| Catalog, combat, phases and story tracks | 518 | 0 |
| Complete campaigns with the real adapter | 1575 | 0 |
| Progression and persistence of Story Mode | 217 | 0 |
| Story Mode Panel | 362 | 0 |
| Story Mode integration with the real interface | 85 | 0 |
| **Total** | **6581** | **0** |

He also passed the league's integrated tour (`--smoke-test`). Checked the read-only tab with combat paused, the retry countdown after surrender, the warning on an actual save failure, and the preservation of the panel when an action is not yet available.

Story tests cover selection, points, eight attributes, limits, win/loss/surrender XP, sequential advancement, elite rewards, boss, ending, standalone campaigns, reloading, corruption, save protection, unique reward, hints and phases. The integration walkthrough uses the actual interface and engine with test files; verifies that the league game remains identical byte for byte.

Seven viewport sizes have been reviewed: 1360×880, 1224×792, 1920×1080, 768×1024, 390×844, 430×932, and 844×390. Panel controls measure at least 48 px; the body has displacement. On mobile, the preview precedes the map. The tests test visible text, not just rectangles, and also use the actual theme of the application. The mobile review was done on native Godot viewports, not on physical devices.

The [balance audit](STORY_BALANCE.md) and [simulation data](story_balance.json) contain 20 197 fights: 432 of 432 campaigns reached the end, with an average of 13.42 fights and 5.42 defeats. The boss fell on the first try at 46.8%. Stamina was the most efficient priority of the four tested; the others also completed all the campaigns. The sample does not exhaust all possible distributions.

Reopened the actual game and left it full screen in the Story character choice. The league save was identical byte for byte: Mugo, level 3, 65 XP, 2 points, 5 wins and 0 losses. A campaign was not started nor was a character chosen by the player.

Screenshots of test profiles (scenarios forced to review results are not used as balancing evidence):

- [Path and preview](historia-ruta.png)
- [Mobile View](historia-movil.png)
- [Improvements](historia-mejoras.png)
- [Legacy](historia-legado.png)
