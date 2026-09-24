# Cloudflare testing environment

> Deployment results below are historical records from September 2026. They do not establish current service availability or authorize operations on the owner’s account. Use isolated local resources or your own authorized environment.

Status: **published in staging, with Workers Paid enabled by user** in [brasa-api-staging.acessloop.workers.dev](https://brasa-api-staging.acessloop.workers.dev/health). Wrangler authorization is configured. D1 `brasa-staging` (`9b3299f9-1c43-417e-9b02-28842b8e05a5`) has all five migrations applied: `0001_identity.sql`, `0002_auth.sql`, `0003_online_arena.sql`, `0004_validation_accounts.sql` and `0005_starter_expansions.sql`.

The user signed up for **Workers Paid** and was confirmed in Cloudflare as a current plan. The new remote test ended on **21 September 2026 at 03:48 UTC** —20 September in Mexico City— on version `3faaf02a-8427-4329-9ab8-7c8e50ef13ec`: **32/32 access checks and 60/60 game and revocation**.

The **final released version is `99077f34-8895-4b12-98ee-a3b692d8596e`**, with the same bundle and secret, CPU limit of `1000` ms per request and log sampling restored to `0.1`. Test and final versions remotely confirmed `usage_model: standard` and `limits.cpu_ms: 1000`; `work/cloudflare-paid/version-settings-final.json` preserves the final query. The package occupies 676.79 compressed KiB; The final startup 102 ms are not CPU per request.

| Checking in Paid | Result |
| --- | --- |
| HTTPS over final version | 5/5: Health, Login, Device, JavaScript, and unauthenticated rejection (401); `https-probes-final.json`. |
| Registration, WebAuthn login, and device authorization | 32/32. |
| Arena, Story Mode, progress, retries, history, defense and revocation | 60/60. |
| Accounts of this execution | 2 new QA accounts, with 1 fighter, 24 cosmetics and 0 sessions each. |
| Fights of this execution | 1 Arena and 1 Story Mode, with results persisted by the server. |
| Cumulative D1 Reconciliation | 4 QA accounts, 0 ordinary accounts and 0 QA sessions. |
| CPU per request configured | 1000 ms; It is a performance limit, not a monthly billing limit. |

The reports for this run are in `work/cloudflare-paid/remote-provision.json`, `remote-verify.json` and `remote-db-reconciliation.json`. Changing plans and settings preserves the app and your data. The local reference suite remains 365/365; It was not repeated by only changing the deployment configuration.

Later local changes to two aura descriptions and their generated bundle are not included in this publication. The [report](../../reports/CLOUDFLARE-STAGING.md) distinguishes its dates and hashes from the deployed snapshot.

Expected HTTP states were checked under Paid and its configured limit. **No new CPU reading obtained per invocation on Paid**: The Chrome Observability panel did not load during review attempts. The test is also not a load test. Free measurements are preserved below as historical evidence and are not presented as Paid values. The [Cloudflare report](../../reports/CLOUDFLARE-STAGING.md) preserves versions, evidence, and this limitation.

## Verification before plan change

The original smoke ended on 21 September 2026 at 03:27 UTC on version `ce9db916-5337-4c93-8724-fdaed84cca91`. Version `0f3491e2-c017-402e-a39d-5ea7dff1aec0` closed that publication with the same bundle, the fifth migration and sampling `0.1`. The following data is historical.

| Check | Result |
| --- | --- |
| Final pre-publication local suite | 365 tests, 0 failures, after incorporating the fifth migration. The smoke version had passed 360/360. |
| HTTPS, health, origin, cache, UI and rejection without credential | 5/5 before the smoke and 5/5 repeated on the final version. |
| Registration, WebAuthn login, and device authorization | 32/32. |
| Arena, Story Mode, progress, retries, history, defense and revocation | 60/60. |
| Final D1 reconciliation | 5 migrations, expansion `cats-v1`, 2 QA accounts with `is_test=1`, 24 cosmetics — including Ónix and Bruma — and 1 account fighter, 1 Arena combat and 1 Story Mode; 0 sessions and 0 ordinary players. |
| Published catalog | 31 cosmetics, 24 starter items; 15 characters and 100 encounters. |

Cosmetic catalog logical hash/API: `728f17d468b127d7d019e8513939e322ea6b5b03caa56f0dd27973697f99e43e`. The reports without credentials are in `work/cloudflare-deploy/https-probes-final.json`, `remote-provision.json`, `remote-verify.json` and `remote-db-reconciliation-final.json`, from the root of the workspace. `npm-test-release.log` records the final local suite of 365 tests; `npm-test-final.log` preserves the 360 before the smoke. These figures describe that verified revision; they do not automatically validate subsequent local changes.

## Update existing staging

The Worker and D1 already exist. Preserve the database UUID and authentication secret. Do not repeat `d1 create` or generate another key for an ordinary update. From `backend/`:

```sh
npx wrangler whoami
npm test
npm run catalog:check
npx wrangler d1 migrations apply DB --remote --config wrangler.staging.jsonc
npx wrangler deploy --dry-run --config wrangler.staging.jsonc
npx wrangler deploy --config wrangler.staging.jsonc
```

Before deploying, review new migrations and synchronize the catalog if it changed. The original remote test was run with the first four migrations. `0005_starter_expansions.sql` was then applied to remote D1 and the catalog was reseeded with correct 35 statements, including expansion register `cats-v1`. This fifth migration records delivered inventory expansions and must be applied before running the new version of `catalogSQL()`.

To seed the catalog, export `catalogSQL()` from `scripts/admin.mjs` to a temporary file and run it with `wrangler d1 execute DB --remote --config wrangler.staging.jsonc --file ARCHIVO.sql`. The new version grants free one-time bodies of Ónix and Bruma to existing accounts; Its registration prevents replacement after a revocation. It does not replenish other cosmetics or grant progress rewards. Do not seed users, sessions or client progress.

### Secrets and observability

The first deployment received `BETTER_AUTH_SECRET` using `wrangler deploy --secrets-file`, with a private file outside the repository, permissions 0600 and 48 cryptographic random bytes. The temporary file was deleted upon completion. The value only remains as the secret binding of the Worker and is not delivered to Godot.

Ordinary updates use `wrangler deploy --config wrangler.staging.jsonc` - they inherit the existing secret. Do not rerun the generator from the first deployment or rotate it without a specific need. `AUTH_MODE=better_auth`, the exact HTTPS origin, and `nodejs_compat` remain configured.

`head_sampling_rate: 1.0` was temporarily used in the Paid test; the final version `99077f34-8895-4b12-98ee-a3b692d8596e` restored `0.1` and retains `limits.cpu_ms: 1000`. Application logs save path, method, status, ID, and wall duration; the latter does not measure CPU. No bodies or credentials are logged. There are no queues, cron, Durable Objects or auxiliary Workers.

### Migration Compatibility

The first remote application of `0001_identity.sql` failed with `incomplete input`; It was found that the transaction had been reversed and there were no game tables. The remote path sends the complete SQL to the D1 API. Three triggers that used `SELECT CASE WHEN EXISTS (...) THEN RAISE(...) END` were rewritten as `SELECT RAISE(...) WHERE EXISTS (...)`, preserving conditions and errors. All four migrations were then applied correctly.

The Wrangler local splitter already accepted the old SQL; The failure is not attributed to that parser. `tests/migrations.test.mjs` checks migrations, ownership, rollback, and immutability. `work/cloudflare-deploy/migrations.log` retains the successful remote result.

## Provision another environment

Use a separate name, configuration, and database. First verify the account with `wrangler whoami` and the databases with `wrangler d1 list`. If a new authorization is necessary, the flow used was:

```sh
npx wrangler login --browser=false --use-keyring --scopes account:read user:read workers_scripts:write workers_tail:read d1:write
```

The OAuth credential is kept encrypted with the macOS keychain. Create D1 only if it does not exist, copy the returned UUID to that environment's configuration, apply all your migrations, and seed the canonical catalog. The first Worker requires a cryptographic secret of at least 32 bytes, supplied by a temporary private file or by the secrets mechanism supported by Wrangler. Do not include the value in project files, printed arguments, or client settings.

## Repeat remote test

`tests/remote-smoke.mjs` requires opt-in and a new credentials file for each run:

```sh
node tests/remote-smoke.mjs --allow-remote --phase provision --credentials .local/staging-smoke-NUEVA-EJECUCION.json
# Administratively mark only the two account_ids printed as is_test=1.
node tests/remote-smoke.mjs --allow-remote --phase verify --credentials .local/staging-smoke-NUEVA-EJECUCION.json
```

The file is created with 0600 permissions and does not contain WebAuthn private keys. Phase `verify` requires the server to confirm the test flag before creating fighters. When finished, revoke the sessions and remove the bearers from the file. QA accounts are separated from ordinary rivals. The user creates their personal passkey on their own device, following [access from Godot](AUTH.md#sign-in-from-godot).

Review actual CPU logging and combat in Cloudflare after relevant changes. A correct result from `npm test`, a dry-run or a local benchmark does not replace that measurement. The user activated [Workers Paid, from 5 USD per month plus applicable additional usage](https://developers.cloudflare.com/workers/platform/pricing/). The `limits.cpu_ms` limit limits CPU per request: it is not a monthly budget or billing cap.

Sources: [Wrangler D1 and migrations](https://developers.cloudflare.com/workers/wrangler/commands/d1/), [CPU limits and measurement methods](https://developers.cloudflare.com/workers/platform/limits/), [Workers Logs](https://developers.cloudflare.com/workers/observability/logs/workers-logs/).
