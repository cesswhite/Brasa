# Brasa: Asynchronous Arena Pre-Audit

This document preserves the state before Arena was deployed. The current deployment and availability is recorded in [Online Arena](../../reports/ARENA-ONLINE.md) and [Cloudflare Deployment](DEPLOYMENT.md). The following findings are historical.

Date: 20 September 2026. The code was inspected before modifying the service. The baseline and save hashes are in `work/online-audit/before.json`, outside the distributable project.

## Checked map

| Area | Actual status and decision |
| --- | --- |
| Godot and organization | Godot 4.7.2, GL Compatibility; `project.godot` starts `scenes/main.tscn`. No autoloads. Separate scripts from graphical resources and backend excluded with `.gdignore`. |
| Characters | `scripts/character_catalog.gd`: 13 canonical definitions with base stats, growth, skill, signature, and visual references. |
| Fighters | `progression.gd` and `story_progression.gd` save profiles per archetype. `fighter_identity.gd` adds separate ID, name, and appearance. A local ID does not certify remote ownership. |
| Statistics | `character_catalog.gd:stats_for`, `story_catalog.gd:stats_for` and `balance.gd` distinguish base, growth, investment and limits. Do not trust `combat_stats` sent by customers. |
| Movements | `move_catalog.gd` centralizes techniques, unlocks, upgrades and talents. `combat_rules.gd` contains shared formulas; `status_effects.gd` manages effects. |
| Engine | `combat_engine.gd` is a RefCounted with no UI or rewards, with setup/hit/recovery clock, events, and immutable terminal result. It is a candidate for porting and cross testing. |
| Random | The engine concentrates RandomNumberGenerator; catalog/creation of opponents have other local RNGs. The server will choose the seed and will not support client testing options. The PCG/randf sequence should be verified against the binary, not assumed. |
| Animation | `main.gd:_handle_event`, `fighter_view.gd` and `arena_view.gd` transform events into poses, motion, sound and HUD. They remain in Godot. |
| Status | Main calls `combat.advance` and queries `snapshot`; This is a visual model, not a full resumable serialization. Arena will retain the autobattler model: challenging is the intention; the server resolves the fight. |
| XP and levels | They are currently granted in `progression.reward_match`/`story_progression.reward_match`. Online requires calculation and atomic confirmation in D1. Never call those local rewards for a remote result. |
| Story Mode | 100 encounters and 11 chapters, defined in `story_catalog.gd`/`campaign_config.gd`; rivals, talents, techniques and phases share the engine. The local campaign is preserved and its definitions are exported to the server. |
| Persistence | League, Story Mode and Identity use separate files and local migrations. Backend: accounts, local_sessions, fighters, identity, progress, appearance, catalog, inventory and snapshots. There are no online battles or ratings yet. |
| Network | `identity_api.gd` only allows loopback, manual token in memory and one request at a time. Main does not instantiate it. An HTTPS layer, session loop, idempotent cancellation and recovery is needed. |
| Backend | `backend/src/worker.js`, ESM and D1; Wrangler 4.110.0, Miniflare 4.20260708.1, esbuild 0.28.2. Installed node 22.23.1. `wrangler.jsonc` configuration exclusively local. |
| Auth | The current adapter rejects any non-local hosts. Better Auth is not installed in the baseline. Evaluate documentation and compatibility before choosing browser/device flow. |
| Authority in UI | Main decides when to run engine and when to give rewards; the formulas are outside the UI. The new remote display will consume server snapshots/events and profiles. |
| Incompatible data | The API returns `archetype_id` and nested progress; the renderer needs a descriptor with `character_id`, name, level and appearance. The server must produce it. Main rebuilds rivals by skipping appearance: do not use that route for real rivals. |
| Tests | 24 regression suites, identity/renderer/HTTP suites, 15 D1 tests and combat/campaign simulators. Add parity between runtimes, authority, races, retries and disconnection. |
| Risks | RNG/float/rounding, divergence between two engines, saving partial results, crafting rivals when there are no users, loading unverifiable local progress, losing rival cosmetics, and providing answers after logging out. |
| cloudflare | The Chrome session shows the chosen account, without existing Workers and subdomain `acessloop.workers.dev`. Wrangler is not authenticated. The first deployment will be a separate testing service; A plan is not contracted nor production data is reused. |

## Deployment sequence

1. Freeze baseline, export canonical definitions and build real combat corpus. Porting rules/engine with parity testing and explicit versioning; keep all animations local.
2. Integrate appropriate first-party authentication for browser and public client, with revocable sessions, server validation, and limits. Keep the local environment independent.
3. Add authoritative profile and relational migrations: rating, history, AI, progression and idempotent operations. Remote accounts start with progress credited by the server; existing saves remain available locally.
4. Create a vertical Arena circuit: account → persistent fighter → rivals from other users → challenge → immutable snapshots → server simulation → atomic update of both profiles → history and defensive results. Don't invent a manual turn system that the game doesn't have.
5. Reuse Story Mode definitions with the same engine and authoritative profile when the previous circuit passes testing. Unlocks, investment of points and build changes express intentions, never final values.
6. Connect Godot over HTTPS: independent login, authorization, real listing, event presentation, profile, history and offline summary. In the event of a timeout, keep the same operation key and consult the result.
7. Test D1 with races, replays, failures and limits; run simulator and affected regressions. Prepare configuration and reviewable migrations before authorizing Wrangler and publishing the test environment.

## Invariants

Cosmetics do not change power. No client grants XP, points, levels, moves, cosmetics, rating or victories. Battles copy authoritative data and versions; subsequent modifications do not change the result. Dependent writes are conditional on the same operation within a transactional batch D1. Arena rivals are real tiles and the empty state does not contain disguised bots. There are no spontaneous fights running in the background.

Reference: [D1 batch and transactions](https://developers.cloudflare.com/d1/worker-api/d1-database/), [Wrangler and environments](https://developers.cloudflare.com/workers/wrangler/configuration/), [Wrangler authorization](https://developers.cloudflare.com/workers/wrangler/commands/general/). The instructions are also checked against `--help` of the installed version.
