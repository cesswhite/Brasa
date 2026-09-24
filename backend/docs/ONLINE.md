# Authoritative Arena and Story Mode

> Deployment results below are historical records from September 2026. They do not establish current service availability or authorize operations on the owner’s account. Use isolated local resources or your own authorized environment.

The service is published in [staging](https://brasa-api-staging.acessloop.workers.dev/health). User activated Workers Paid, confirmed on Cloudflare. The new Arena and Story remote test passed **60/60 checks**, preceded by **32/32 access**, with two new QA accounts separate from regular players and sessions revoked upon completion. The final version is `99077f34-8895-4b12-98ee-a3b692d8596e`, with CPU limit of 1000 ms per request and `0.1` sampling. [Cloudflare Status and Measurements](../../reports/CLOUDFLARE-STAGING.md).

## Flow and limits of this version

Godot preserves local League and Story Mode, with its current files and systems. "Arena online" opens a new remote profile, authenticated by passkey and device authorization. No statistics or client possessions are imported. The same remote fighter shares XP, level, investment, techniques, talents, and cosmetics between Arena and 100 Story matches.

The existing automatic combat is maintained: the player chooses fighter, build, style and rival; one request resolves the entire combat. The server controls both combatants and Godot presents its events. This version **does not implement manual attack selection or surrender during active combat**. There is no partially resolved game to resume: a confirmed challenge has a terminal outcome. Closing the animation does not cancel the result or grant additional prizes.

Arena's opponents belong to other accounts. No filler bots or spontaneous combat are created in the background. Offline defense occurs when another player requests a challenge. Validation administrative accounts (`accounts.is_test=1`) can only view and challenge each other; the client cannot activate that flag.

## HTTP contract

Authentication: session bearer obtained by the flow documented in [AUTH.md](AUTH.md). Game Routes do not accept the browser cookie as an authority. HTTPS in staging; Explicit loopback only for local tests. JSON bodies up to 8192 bytes, unknown keys rejected, UUIDs and revisions validated. Response format: `{ "data": ... }`; errors: `{ "error": { "code", "message" }, "request_id" }`.

Every remote mutation requires `Idempotency-Key: UUID`. Reusing it with the same body returns the result of the operation; a different body returns 409. Receipts do not expire in this version. The legacy local tool retains its headless create/PATCH contract.

| Route | Function and body |
| --- | --- |
| `GET /health` | D1/catalog and engine version availability, no credential. |
| `GET /v1/me` | Internal session identity. |
| `GET /v1/game/catalog` | Characters, investment rules, techniques, talents, styles, chapters and metadata of 100 encounters. |
| `GET /v1/catalog`, `/v1/owned` | Versioned cosmetic catalog and own inventory. |
| `GET /v1/fighters`, `/v1/fighters/:id` | Own fighters with progress, revisions, rating and visual descriptor. |
| `POST /v1/fighters` | `{archetype_id, display_name}`; a fighter by archetype and account. |
| `PATCH /v1/fighters/:id` | `{expected_revision, display_name?, appearance?}`; uses `fighter.revision`, not the progress revision. |
| `POST /v1/fighters/:id/allocate` | `{expected_revision, stat, amount}`; consumes only available points and rejects batches that exceed the maximum. |
| `POST /v1/fighters/:id/ai` | `{expected_revision, style}`; seven validated styles. |
| `POST /v1/fighters/:id/upgrade-move` | `{expected_revision, move_id}`; Unlocked technique, points and maximum of two upgrades. |
| `POST /v1/fighters/:id/perk` | `{expected_revision, perk_id}`; archetype talent, no duplicates, maximum of three. |
| `POST /v1/fighters/:id/respec` | `{expected_revision}`; returns points invested from statistics, techniques and talents. |
| `GET /v1/arena/opponents?fighter_id=UUID` | Up to six real rivals close in power and rating; honest empty state. |
| `POST /v1/battles` | `{fighter_id, opponent_id}`; Complete Arena combat. |
| `GET /v1/story?fighter_id=UUID` | Next meeting and chapters. |
| `POST /v1/story/battles` | `{fighter_id, story_level?}`; by default next encounter; repeating one passed is practice without XP. |
| `GET /v1/battles/:id` | Result, snapshots, seed and events; only its participants. |
| `GET /v1/history?fighter_id=UUID&cursor=...` | Up to 20 summaries and stable cursor; Events are downloaded when the fight opens. |
| `GET /v1/arena/offline-results` | Summary of unseen results and up to 20 notices. |
| `POST /v1/arena/offline-results/ack` | `{ids:[UUID...]}`; mark up to 50 own notices. Does not grant rewards. |

Build mutations use `fighter.progression_revision`. Before 409 the token is reloaded; no new revision is invented or an obsolete intent is automatically resubmitted. In case of timeout/incomplete JSON, the client keeps the same operation key in memory. If the application is closed, the history and profile recover what was confirmed; the session and temporary queue are not written in plain text.

## Engine, versions and reproduction

`battle-engine/` does not know HTTP, D1, UI, or sessions. The catalog is exported from Godot, and real combat corpus checks PCG, float32 numbers, events and states against the 4.7.2 binary. Formulas are not recalculated on the online screen. The 64 bit seed is generated with `crypto.getRandomValues` and transported as a decimal string so as not to lose JSON precision.

Each match stores engine/catalog version, both descriptors, seed, result and sequenced events. Triggers prevent updating or deleting the combat log. Changing name, appearance, points or style later does not change that record. Replay uses stored events, without rerolling or awarding XP. For an exact simulation of an old version, its code and catalog must be preserved; Updating the engine does not convert historical results to the new version.

Parity and benchmark: [battle-engine/README.md](../battle-engine/README.md). Signature remains at approximately 1% **per fighter/combat**, separate from ordinary criticals.

## Commit, racing and anti-abuse

`game_operations` has uniqueness per account/key and intent hash. The server reads profiles, simulates and builds a transaction D1 `batch`: receipt → immutable combat → progress of both → reward book → cosmetics earned → defensive notice. All writes depend on the same mutation ID. The receipt is only inserted if the reviews and daily counters used to calculate prizes are still valid. A run recalculates with fresh data up to three times; if persisted returns 409 retryable. An SQL error rolls back the entire batch.

XP and rating are independent. The parameters are in `src/game/config.js`: cooldown of three seconds, 45 new mutations per minute/account, three battles with rating per couple of accounts/day, XP of the couple exhausted after ten, first five defenses with full XP and up to twenty reduced, defensive cap of 1200 XP and active Arena of 12000 XP daily. Story XP does not consume the Arena cap. Even if the XP runs out, the result and its history are preserved. The couple limit covers all fighters on both accounts.

Matchmaking power derives from stats, techniques, and talents; does not modify the damage. Indexed queries take candidates above and below one's own power and consider rating. The allowed range is 0.45–2.2 relative power. The game retains its level cap 50 and canonical growth/unlock rules. Story Mode milestone rewards and cosmetics are only credited by the server.

Limits per account and partner reduce repetition and ordinary farming. They do not constitute detection of colluded accounts or verification of human identity. No Redis, queues, cron or an LLM service for AI were added.

## Data

Ordered migrations:

1. `0001_identity.sql`: Accounts, local credentials, identity/appearance/progress, catalog, inventory, and historical identity snapshots.
2. `0002_auth.sql`: Better Auth, passkeys, device codes, nonces and authentication limits.
3. `0003_online_arena.sql`: rating/style/power, operations, combat, progress book, warnings and game limits.
4. `0004_validation_accounts.sql`: Administrative separation of test accounts.
5. `0005_starter_expansions.sql`: Record of initial expansions delivered, to not replace a revoked grant when reseeding the catalog. Applied remotely after the original smoke, before final publication; the [deployment log](DEPLOYMENT.md) distinguishes what is validated in each version.

JSON documents store bounded build values or immutable snapshots/events; Relationships, ownership, ratings, receipts and rewards remain normalized. Old profiles with zero power are recalculated in batches up to 32 when querying rivals. Local Godot files and your identity are not automatically synchronized with D1.

## Operation

The local configuration and the staging configuration are different files. Do not publish `AUTH_MODE=local_dev`. The Better Auth credential only resides in the Worker's secret binding; Godot contains the public URL. Structured logs store ID, path, method, state and wall duration, not sessions/bodies or credentials.

Node and local V8 benchmarks do not represent CPU billed by Cloudflare. The measurements of the original smoke in Free gave 81 ms for Arena and 48 ms for Story Mode, in addition to several accesses above the [10 ms of that plan](https://developers.cloudflare.com/workers/platform/limits/). The user subsequently activated Workers Paid; Free samples are preserved as historical evidence. The CPU limit per request is not a monthly billing cap. The package of that version occupied 676.79 compressed KiB. The functional replay on Paid passed 32/32 access checks and 60/60 game checks. No new CPU was obtained per invocation because Observability did not load in Chrome; This is not a load test. See [Cloudflare report](../../reports/CLOUDFLARE-STAGING.md).
