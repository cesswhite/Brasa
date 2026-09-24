# Access with passkey and device code

> Deployment results below are historical records from September 2026. They do not establish current service availability or authorize operations on the owner’s account. Use isolated local resources or your own authorized environment.

Implementation fixed to `better-auth 1.7.5` and `@better-auth/passkey 1.7.5`, with native D1. The browser performs WebAuthn; Godot receives an opaque session for device authorization. Passwords, anonymous accounts, SMTP, OAuth providers, and local game imports are not enabled.

User activated **Workers Paid**, confirmed as current plan on Cloudflare. Access was rechecked in [staging](https://brasa-api-staging.acessloop.workers.dev/auth): **32/32 remote registration, login and device authorization checks**, followed by **60/60 game and revocation**, with `limits.cpu_ms: 1000`. The final version is `99077f34-8895-4b12-98ee-a3b692d8596e`, with the same bundle and secret, and sampling `0.1`. The [Cloudflare report](../../reports/CLOUDFLARE-STAGING.md) records the evidence and distinguishes the historical Free measurements from the new Paid functional verification.

## Sign in from Godot

1. Open `Jugar online.command` or **Online Arena** from the menu and press **Sign in in browser**.
2. On the first visit, write **Account name**, press **Create account with passkey** and confirm with the fingerprint, face or PIN requested by your device. If the account already exists, press **Enter with my passkey**.
3. Compare the browser code with Godot and press **Authorize this device**. Creating the account or logging in does not in itself authorize the game.
4. Return to Godot; The session is automatically collected. Choose the combat base, type **Name of your fighter** and press **Create fighter**.
5. You can enter **Story Mode** even if there are no public rivals. Arena shows only other available players; QA accounts remain separate.

Opening `/auth` directly allows you to manage access, but does not connect Godot without the code launched from the game. The personal passkey is created by the user on their device; the panel offers **Add a second passkey**. Online progress is saved on the server and the local game does not matter.

## Settings

The online environment requires:

```json
{
  "compatibility_date": "2026-07-08",
  "compatibility_flags": ["nodejs_compat"],
  "vars": {
    "AUTH_MODE": "better_auth",
    "BETTER_AUTH_URL": "https://brasa-api-staging.acessloop.workers.dev"
  }
}
```

`BETTER_AUTH_SECRET` is provided via a secret binding, generated with at least 32 random bytes; It is never saved to the repository or delivered to the game. Binding D1 is called `DB`. Apply versioned migrations and seed the catalog before admitting users. `0002_auth.sql` contains the Better Auth schema, account links, registration nonces, and request limits.

`AUTH_MODE=local_dev` keeps the old adapter exclusively in loopback. `brasa_local_*` tokens are not online credentials. Node support is also required when loading the new bundle in local development. An absent or weak configuration returns 503; a source other than the configured one returns 403.

In `worker.js`, call `handleAuthRequest(request, env)` before `authenticate`; a non-null response already corresponds to the access service. `authenticate` returns `{account_id, auth_user_id}` in Better Auth mode and retains `{account_id}` in local mode.

## Browser

`GET /auth` shows creation and login. `GET /device?user_code=ABCDEFGH` displays the code received from the game and separate buttons to authorize or reject. Opening the page or logging in does not approve the request.

1. `POST /api/auth/registration/nonce` receives `{name}` and returns a five-minute signed context.
2. The client obtains the registration options and runs WebAuthn. The server verifies challenge, origin, RP ID and user verification.
3. Only after a valid ceremony is the nonce consumed once and the user created. By storing the passkey and creating your session, a D1 batch creates a game account and the initial inventory of the canonical catalog - 24 cosmetics in this version - idempotently.

The email column required by the Better Auth schema uses an internal identifier `UUID@passkey.brasa.invalid`; It does not identify a real address, is not considered verified, and does not enable recovery or linking by mail. Game UUIDs are bound to the authenticating user; no name provided by the client identifies another account.

The page allows you to add a second passkey. The server requires a session created in the last five minutes to add credentials. There is no public deletion of passkeys or recovery for a shared administrative secret. Without a passkey available there is no recovery implemented; A synchronized passkey or second credential must be maintained.

## Godot Contract

| Operation | Request | Response |
|---|---|---|
| Request code | `POST /api/auth/device/code`, `{client_id:"brasa-godot"}` | `device_code`, `user_code`, `verification_uri`, `verification_uri_complete`, `expires_in:600`, `interval:5` |
| Check authorization | `POST /api/auth/device/token`, `{grant_type:"urn:ietf:params:oauth:grant-type:device_code",device_code,client_id:"brasa-godot"}` | `access_token`, `token_type:"Bearer"`, `expires_in`, `scope:""` |
| Use API | `Authorization: Bearer <access_token>` | Existing `/v1/*` contract |
| Disconnect | `POST /api/auth/sign-out`, body `{}`, bearer | Revoke that session |

Device errors are HTTP 400 with `{error,error_description}`: `authorization_pending`, `slow_down`, `expired_token`, `access_denied`, `invalid_grant` or `invalid_request`. Respect the interval; on `slow_down`, increase it by at least five seconds. Canceling the flow discards late responses. Do not log codes or tokens. `client_id` is public; It only identifies the application and does not serve as a password.

Godot must validate HTTPS, host and path of the verification URL before opening it; You should not follow API call redirects. On macOS, the bearer is saved to Keychain using the `native/macos` signed helper; is validated against `/api/auth/get-session` before the account is restored. The local presentation file does not contain credentials. On platforms without a secure adapter the bearer remains only in memory. Cookies are not required in Godot. This flow returns a Better Auth session, not an OAuth JWT or an OAuth refresh token.

## Controls

- Exact RP ID and origin, secure cookies, preserved origin/CSRF checks and page CSP without external scripts.
- The game API requires bearer: a browser cookie alone does not allow game actions to be executed; a valid cookie also does not rescue an invalid bearer.
- The plugin requests `userVerification:"required"`. Additionally, both server callbacks reject `userVerified=false`: version 1.7.5 checks internally with `requireUserVerification:false`, so asking the browser alone would be insufficient.
- The signed nonce is consumed by comparison and update in D1. Credential IDs have a unique index. A game account is not granted without a stored passkey.
- The HTTP wrapper enforces atomic limits on D1, per Cloudflare IP per minute: five registrations, ten device codes, thirty token polls, and sixty general requests. Returns 429 and `Retry-After:60`. The Better Auth in-memory limiter is disabled because the wrapper protects exposed routes, including custom endpoints.
- `user_id` is rejected in the public device request. An approved code can only be redeemed once; the session that claims the code must be the one that approves it.
- The provider's logs emit a generic mark, without credentials, bodies or exceptions that could contain them. Access responses are not cached.

## Testing and performance

`node scripts/build.mjs --auth-only` rebuilds only the Worker used by isolated authentication tests. `node --test tests/auth.test.mjs` verifies eight groups with signed WebAuthn responses and a real temporary D1 database: registration, biometrics/mandatory PIN, origin, nonces, double redemption, user isolation, rejection/expiration, revocation, second passkey, recent session, persistence, and concurrent limits. It does not use a bypass endpoint or seeded sessions to start the test.

Result of initial access delivery: **8 tests passed, 0 failures**, log `work/identity/auth-tests.log` from the root of the workspace. The complete suite that includes the access tests passed **360/360** before the remote smoke (`work/cloudflare-deploy/npm-test-final.log`) and **365/365** after incorporating the fifth migration (`work/cloudflare-deploy/npm-test-release.log`). The tests use their own temporary files and do not access the game or personal credentials.

Wrangler `4.110.0` and Miniflare `4.20260708.1` remain fixed. Specific overrides: `undici 7.29.0` and `sharp 0.35.4`; `npm audit` terminates without alerts at `work/identity/auth-npm-audit.json`.

The first measurement with the local workerd V8 profiler is preserved in `work/identity/auth-local-profile.json`. Found approximately 1.9–4.5 ms active in hot authenticated API, 5 ms in device code, 16.7 ms in passkey registration and 39 ms between nonce/first access options. These are local samples with instrumentation, **no Cloudflare-billed CPU or 10 ms Free limit compliance testing**. Subsequent remote measurement confirmed access requests above that limit; see actual results below. Cryptographic security was not reduced to alter those values. The user later activated Workers Paid.

The second measurement separates both requests and is persisted in `work/identity/auth-local-profile-warm.json`. First nonce: 4.94 ms; first options: 27.77 ms. In 20 hot samples by operation:

| Operation | Local median | p95 of the local sample |
|---|---:|---:|
| Nonce | 3.20 ms | 3.87 ms |
| WebAuthn Options | 4.67 ms | 6.16 ms |
| Check registration | 8.47 ms | 10.72 ms |

The initial spike mainly comes from option initialization; the hot check is also close to the limit and some samples exceed it. The small sample from a local machine does not represent p95 of the deployed service. The profiling script now saves the separate measurement in the `*-warm.json` file and keeps the initial capture as a reference.

## Historical CPU in Workers Free

Before enabling Paid, smoke build `ce9db916-5337-4c93-8724-fdaed84cca91` produced the following CPU samples per request across the two QA accounts. These are Cloudflare measurements, different from the wall duration in application logs and local profiles above.

| Operation | Account A | Account B |
| --- | ---: | ---: |
| Registration Nonce | 7 ms | 5 ms |
| WebAuthn Registration Options | 46 ms | 15 ms |
| Registration verification | 29 ms | 35 ms |

The consolidated log contains 11 critical authentication and combat invocations, 9 above 10 ms. They all ended with `outcome=ok`, including deliberate HTTP rejection 422 of a request declaring the winner. The test obtained the expected HTTP states, but these samples do not allow announcing stability with the limit of [10 ms of the Free plan](https://developers.cloudflare.com/workers/platform/limits/). Arena and Story Mode also surpassed it: 81 ms and 48 ms, respectively. A limited review found no small demonstrated change to warrant compliance. The user subsequently purchased [Workers Paid, from 5 USD per month plus applicable additional usage](https://developers.cloudflare.com/workers/platform/pricing/), and this was confirmed to be the current plan. Cryptographic security has not been reduced. The [Cloudflare report](../../reports/CLOUDFLARE-STAGING.md) preserves the evidence. Version `0f3491e2-c017-402e-a39d-5ea7dff1aec0` closed that validation with the same bundle and secret, and sampling restored to `0.1`. The subsequent functional test on Paid passed 32/32 access checks and 60/60 game checks. A new CPU reading was not obtained per invocation because the Observability panel did not load; The values ​​in this table remain exclusively historical. No load test was performed. The configured Paid limit of 1000 ms is per request and is not a monthly billing cap.

## Remote testing in two phases

The run on Paid ended on 21 September 2026 at 03:48 UTC with **32/32 access checks and game 60/60**, in version `3faaf02a-8427-4329-9ab8-7c8e50ef13ec`. Their two new QA accounts ended with one fighter, 24 cosmetics, and zero sessions each; They saved one Arena match and one Story Mode match. D1 now contains four cumulative QA accounts and zero ordinary accounts; There are no QA sessions left. The reports are in `work/cloudflare-paid/remote-provision.json`, `remote-verify.json` and `remote-db-reconciliation.json`.

The previous test on Free also passed 32/32 and 60/60; its reports remain in `work/cloudflare-deploy/`. They are separate runs, with different QA accounts.

`tests/remote-smoke.mjs` is not part of `npm test` and does not make any requests without `--allow-remote`. Only accepts the fixed staging origin. Run it only after authorization from the person responsible for the deployment:

```sh
node tests/remote-smoke.mjs --allow-remote --phase provision --credentials .local/staging-smoke.json
```

The first phase creates two accounts identified `QA Brasa A/B`, registers passkeys, verifies a login EC signature, completes device authorization, and saves exclusively their bearers and IDs in a file 0600. Private keys remain in memory and are discarded. The browser session is closed. **Does not yet create fighters or combats.**

The administrator must mark those two accounts `is_test=1` using D1 and then run:

```sh
node tests/remote-smoke.mjs --allow-remote --phase verify --credentials .local/staging-smoke.json
```

The second phase requires that `/v1/me` confirms `is_test` on both accounts and that they have no previous fighters. Check profiles, cosmetic changes, assignment, real Arena and Story, idempotent retries, offline defense, immutable history, and revocation. It does not force winners or award XP through remote fixtures. Upon completion, revoke both bearers and delete them from the file; If you are unable to confirm a revocation, you retain the private credential for administrative intervention. Reports and logs contain states/IDs, never tokens or keys.

`tests/auth-remote-smoke.test.mjs` tests the two phases against a temporary D1 database by intercepting all `fetch` before importing the script: **no request for that test reaches staging**. It also verifies that an account without the test flag cannot continue. The local workflow passed: log `work/identity/auth-remote-harness.log`.

## Official sources consulted

- [Better Auth: native D1 support](https://better-auth.com/blog/1-5).
- [Better Auth: passkeys, sessionless registration and callbacks](https://better-auth.com/docs/plugins/passkey).
- [Better Auth: device authorization](https://better-auth.com/docs/plugins/device-authorization).
- [Better Auth: bearer](https://better-auth.com/docs/plugins/bearer).
- [Better Auth: security and origin verification](https://better-auth.com/docs/reference/security).
- [Cloudflare: Transactions with D1.batch](https://developers.cloudflare.com/d1/worker-api/d1-database/#batch).
- [Cloudflare: Node compatibility](https://developers.cloudflare.com/workers/runtime-apis/nodejs/).
- [Cloudflare: limits and CPU](https://developers.cloudflare.com/workers/platform/limits/).

The APIs and user verification checking were also checked against the installed code of the pinned versions. `scripts/auth-schema.mjs` prints the generated SQL for review; it does not overwrite additional tables in the migration or touch remote D1.


### Current entry experience (21 September 2026)

One primary action per screen, with no required account name or email. The fighter's name is chosen later in the game. Explicit confirmation of the device code remains mandatory. Canceling the prompt returns to Continue without alert. Recovery and second passkey are on secondary routes; Adding another credential preserves the requirement for a recent session and the same owner.

`/auth/art/` serves the verified copies of the background, Nima, shared materials and tokens. The CSP allows these styles only from the same origin. The Keychain helper must be included and signed within the macOS distribution; the current binary serves the development environment. Signing out first writes a local non-restore flag so that a wipe failure does not reactivate a session. Local metrics: categories and times, without tokens or identifiers.

See `reports/AUTH-EXPERIENCE.md` and `work/auth-experience` for tests and screenshots with fixtures.
