# Extension validation

Verified with Godot 4.7.2 on macOS on September 20 2026.

| Test | Checks | Failures |
| --- | ---: | ---: |
| Regression controls, training and compatibility | 185 | 0 |
| Engine, probabilities, signatures and states | 396 | 0 |
| Progression, migration, XP and saving | 563 | 0 |
| Sprites, alpha, anchors and transitions | 258 | 0 |
| Squad, selection and chips | 69 | 0 |
| **Total** | **1471** | **0** |

The `--smoke-test` integrated test also passed: roster, training, forced signing only in tests, combat, single reward, summary, history, token, rematch, surrender confirmation and cancellation, recharge and separate progress per character. Use a new test save inside `work/` on each run.

Reproducible seeds were tested with different time steps; damage limits and probabilities; repeated states, expiration and simultaneous periodic damage; slowness of a turn; surrender with active effects; signatures at the end or against an almost defeated rival; attempts to act after the result; XP after losing or surrendering; several levels with leftover XP; maximum level; very distant profiles; protection against corruption; backup and idempotent reward after reloading.

The final simulation contains **17 100 battles** between the nine characters at levels 1, 10, 25 and 50, plus level 1 battles against 4. Full results are in `balance.json` and the attached balance sheet report. Training remains at its core to isolate identities and growth; The test does not represent all possible training combinations.

The interface was reviewed in a real window: selection of the nine characters, arena, life and levels, summary of both participants, surrender, states and animations. A forced signature capture allowed the overlap of its title, damage and effect to be corrected. Long names are trimmed within their space and the tabs have scrolling.

The actual game was migrated to V2 and checked field by field: **Mugo, level 3, 65 XP, 2 points, 5 wins, 0 losses**, with Life training 8, Strength 7, Agility 4 and Speed 8. The previous copy is in `brasa_save.json.v1.bak`, next to the macOS save. No test battles consumed points or altered results of that match. The application was left open with Mugo ready to play.
