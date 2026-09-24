# Brasa on Cloudflare · 20 September 2026

**Workers Paid is active, purchased by the user and confirmed on Cloudflare.** The test server is published with a limit of **1.000 ms CPU per request**. 92 remote access and game checks, as well as five HTTPS checks, were repeated and passed. The `standard` model and limit were queried directly to Cloudflare upon final deployment.

Service: [brasa-api-staging.acessloop.workers.dev](https://brasa-api-staging.acessloop.workers.dev/health). The game already uses this HTTPS origin. [Structured evidence, versions, IDs and results](cloudflare-staging-validation.json).

## Verified post

| Resource | Status |
| --- | --- |
| Worker | `brasa-api-staging` |
| Final version with Paid | `99077f34-8895-4b12-98ee-a3b692d8596e` |
| Remote testing version with Paid | `3faaf02a-8427-4329-9ab8-7c8e50ef13ec` |
| Historical version of CPU measurements with Free | `ce9db916-5337-4c93-8724-fdaed84cca91` |
| Worker Code | Same bundle as the approved local suite; SHA-256 `d856f319739893b4147364ac781eb937626ae727b4f76dd5825034dcda1037b0` |
| Capacity | Model `standard`, maximum CPU per request `1000 ms`, confirmed by version API |
| D1 | `brasa-staging` `9b3299f9-1c43-417e-9b02-28842b8e05a5` |
| Migrations | `0001`–`0005`, applied and verified remotely |
| Catalog | 15 characters, 100 encounters, 31 cosmetics, 24 starters |
| Log sampling | 100 % during testing; restored to 10 % |
| Better Auth Secret | Generated in private temporary file, loaded and removed from disk; preserved between versions |

The first migration required an equivalent SQL write for three triggers: `SELECT RAISE(...) WHERE EXISTS(...)`. The remote path was rejecting `CASE ... END`; their ownership conditions did not change. Verified rollback of failed attempt before applying migrations. The fifth migration records the one-time delivery of Ónix and Bruma to existing accounts; The final seeding preserved their inventories of 24 items.

## Results

| Check | Result |
| --- | --- |
| Local backend of published revision | 365 tests, 0 errors or omissions; identical sources and bundle, without repeating the suite due to the change of plan |
| HTTPS after final publication | 5/5 - Health, Access, Device, JavaScript and Opt-Out 401 |
| Remote access | 32/32: WebAuthn registration, EC-signed login, device authorization and native session |
| Remote play | 60/60: Creation, Inventory, Permissions, Progress, Arena, Story Mode, Match History, Offline Defense and Revocation |
| Retries | Same creation and battle; without duplicating XP, history or defense |
| D1 Reconciliation | Four QA accounts in total; The last couple has one fighter per account, one Arena match and one Story Mode match |
| Access cleaning | Zero active testing sessions; both tokens revoked and removed from private file |

The two new accounts were administratively marked `is_test=1` before creating fighters. They do not participate in public matchmaking. Reconciliation found zero regular accounts and zero active sessions among the four QA accounts. The test WebAuthn private keys existed only in memory. The user's personal passkey is created on their own device.

The first test with Free was run with four migrations; then the fifth was applied. The new test with Paid was run with all five migrations and the CPU limit confirmed. 92 checks ended on 21 September 2026 at 03:48 UTC —20 September in Mexico City. After resampling to 10 %, the five HTTPS checks were repeated and the final version's model, limit, and secret binding were queried. Evidence of this execution (`work/cloudflare-paid/remote-verify.json`; not included).

The final version was created at 03:50:02 UTC. Another local job then updated the cosmetic catalog and rebuilt `dist/worker.js` at 03:52:36 UTC. Those later files are not part of this publication or its results; The report identifies the hash of the bundle actually validated and deployed. Comparison and dates (`work/cloudflare-paid/drift-investigation.json`; not included).

## CPU: historical measurement and current configuration

The following values correspond to the first run with **Free**. They were observed in the native `$workers.cpuTimeMs` columns of the Cloudflare dashboard, not in the wall duration of the application log. They are not measurements of the Paid plan:

| Operation | CPU |
| --- | --- |
| A/B Registration Nonce | 7 / 5 ms |
| A/B Registration Options | 46 / 15 ms |
| A/B Registration Verification | 29 / 35 ms |
| Rejection of the winner sent by the client | 15 ms |
| Original arena/retry | 81 / 12 ms |
| Original story/retry | 48 / 13 ms |

All eleven invocations ended with `outcome=ok`, including the intentional HTTP rejection 422. It's a small sample of two counts: it doesn't show a service percentile or identify which isolate was hot. Cloudflare supports occasional overages, but that does not guarantee sustained operation under the [10 ms Free limit](https://developers.cloudflare.com/workers/platform/limits/). Measurements and sanitized correlation (`work/cloudflare-deploy/CPU-OBSERVATION.md`; not included).

The code review did not find a small optimization with enough evidence to bring all routes below 10 ms. The Better Auth instance is already reused; changing your context handling or revocation to save CPU requires specific work and new validation. The user resolved the environment capacity by enabling Paid.

**Active Paid:** Plan minimum is **5 USD per account per month**, with possible additional usage charges; It is not a spending ceiling. Includes 10 million requests and 30 million monthly CPU milliseconds. [Official rates](https://developers.cloudflare.com/workers/platform/pricing/). The user made the purchase personally. The configured 1.000 ms limit controls each request, not the monthly amount.

The Cloudflare API confirmed the new limit and all expected HTTP states passed. No new CPU reading was obtained because the Observability panel remained unloaded after several attempts; This limitation is recorded and was not replaced by wall times. Paid execution observation (`work/cloudflare-paid/CPU-OBSERVATION.md`; not included). Functional verification does not constitute a sustained load test.

## Personal access to the test environment

Open `Jugar online.command` or **Online Arena** and press **Login in browser**. Create the account with a passkey, confirm on the device and press **Authorize this device** after comparing the code with Godot. When you return to the game, create a fighter. Story Mode is available even if there are no public rivals yet; QA accounts do not appear as rivals.

Online progress begins separately from local play. [Operating procedure](../backend/docs/DEPLOYMENT.md) · [Arena Contract](../backend/docs/ONLINE.md).
