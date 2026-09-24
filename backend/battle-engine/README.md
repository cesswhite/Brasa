# Authoritative Engine Brasa v1

Ported from the installed Godot `4.7.2.stable.official.ed1daf0bf`, without modifying the GDScript engine or the saves. It does not use HTTP, D1, system clock or global random. The module does not grant rewards.

## API

`index.js` exports:

- `gameCatalog`, `ENGINE_VERSION`, `CATALOG_VERSION`, `RNG_VERSION`.
- `buildCombatant(dto)`: Receives `character_id`, `level`, `allocations`, `move_upgrades`, `perks`, `ai_config` and optional metadata `fighter_id`, `owner_id`, `identity`, `appearance`. Calculates stats from the eight Story Mode attribute allocations and legal techniques. Ignores derived stats, skills and techniques supplied by the DTO. Validates shapes and limits; service must check owner, points/tokens budget, rewards and revisions.
- `statsForProfile(profile)`, `xpForLevel(level)`, `pointsForLevel(level)`, `getStatOptions()`, `getUnlockedMoves(id,level)`, `getPerks(id)`, `resolveMove(id,moveId,tier,perks)`.
- `getStoryStage(globalLevel)`, `getStoryOpponent(globalLevel)`: copy of exported encounter; outside 1–100 returns `null`.
- `validateAiConfig(raw)`: returns `{style,weights}` or throws error. Styles: balanced/aggressive/defensive/fast/counter/risky/unpredictable. Each optional weight corresponds to a known type and is between 0.25 and 4. Presets only alter weights; balanced retains Godot's AI.
- `simulateBattle(player,rival,seedString,options={})`: **trusted** descriptors, complete result with `events`, `metrics`, `winner`, `reason`, `duration`, `turns`, `player`, `rival`, `seed`, versions and `final_state`/`terminal_state`. Each event maintains its order in the array and the simulated `time`. `options.battle_id` must contain the ID assigned by the service.
- `BattleEngine`: `start/advance/surrender/snapshot/summary` internal interface for corpus and tools.

Full descriptors and test options are not allowable payloads directly from HTTP. In particular, `combat_stats`, `ability`, `moves`, `force_signature`, `initial_hp`, `initial_statuses`, `opening_time` and `surrender_at` allow internal test cases to be prepared and should never be exposed as client input.

`include_states:true` adds visual snapshots to each event. The default value is false; normal playback uses events and the final result. Full snapshots significantly increase the payload. No other compact format was implemented in this delivery.

The seed is a uint64 decimal string, with no leading zeros except `"0"`. The server generates an unpredictable seed; PCG then allows the combat to be replayed. The string `"0"` represents a deterministic seed in this module, while local `CombatEngine.start(...,0)` uses `randomize()`; combat corpora use nonzero seeds. Never transport uint64 using a JSON number.

## Catalog and rules

`../data/game-catalog.json` retains 15 characters, 75 playable techniques, 90 talent options, 10 boss techniques, and 100 encounters, chapters, bosses, budgets, XP, attributes, statuses, and AI constants. Saves SHA-256 of the eight source GDScript files. The same `catalog_version` versions the combat and progress values; its SHA-256 identifies the exported bytes.

Encounters 17–100 use the actual descriptors exported with `run_seed=0`. Variations, weaknesses, techniques, talents, assignments and bosses are preserved; Godot's hash was not ported to change the pool character per campaign. Saves and local pools remain intact.

Mitigation, variance±8%, crit, guards, shields, simultaneous DoT, hit/recovery times, actions under stun, slow and initiative reset, skills, phases, delayed counterattacks, and terminal surrender are retained. Signature eligibility is rolled once per fighter at 1%; It is not 1% per attack. Running Signature also preserves the normal selection that Godot makes before replacing it: that RNG consumption matters for parity.

PCG32 comes from M. E. O'Neill's algorithm (Apache-2.0); the float32 adaptation corresponds to Godot (MIT). See [PCG](https://github.com/godotengine/godot/blob/ed1daf0bf/thirdparty/misc/pcg.cpp), [RandomPCG](https://github.com/godotengine/godot/blob/ed1daf0bf/core/math/random_pcg.h) and [RandomNumberGenerator](https://github.com/godotengine/godot/blob/ed1daf0bf/core/math/random_number_generator.h). `Math.random()` is not used.

## Reproduction of the checks

From the root of the Godot project:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts/export_game_catalog.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/export_engine_corpus.gd
node --test backend/tests/engine-*.test.mjs
node backend/tests/engine-benchmark.mjs 10000 /ruta/absoluta/benchmark.json
```

The reference is compressed in `backend/tests/fixtures/engine-godot.json.gz`. The exporter saves full numerical precision and the test verifies its link to the catalog hash. Events are compared field by field, excluding only `message`, which is localized text. All numbers are compared with exact equality.

There are no new dependencies. Fixtures and simulators are not imported from production; `index.js` imports only the catalog and pure modules.
