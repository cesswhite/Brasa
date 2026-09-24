# Online arena staging on Cloudflare

Implemented Workers+D1, Better Auth/passkeys, In-Browser Godot Authorization, 15 Persistent Archetypes, Automatic Asynchronous Arena, 100 Encounter Story Mode, Shared Online Progression, AI Styles, Techniques, Talents, Cosmetics, Match History, Replay, and Defensive Summary. The results are decided and saved on the server; Godot introduces them.

The server is published to [Cloudflare staging](https://brasa-api-staging.acessloop.workers.dev/health), with five migrations applied to D1. Remote testing confirmed access, combat, Story Mode and revocation. **User activated Workers Paid**, confirmed as current plan on Cloudflare. Replay under Paid passed **32/32 access checks and 60/60 Arena, Story Mode and revocation checks**. [Cloudflare Log and Measurements](CLOUDFLARE-STAGING.md) · [Deployment](../backend/docs/DEPLOYMENT.md).

## Current verification in Paid

Smoke ended on 21 September 2026 at 03:48 UTC — September 20 in Mexico City — on version `3faaf02a-8427-4329-9ab8-7c8e50ef13ec`. The final release is **`99077f34-8895-4b12-98ee-a3b692d8596e`**, with the same bundle and secret, `limits.cpu_ms: 1000` and sampling `0.1`. The package occupies 676.79 compressed KiB; your startup 102 ms are not CPU per request.

| Validation in Paid | Result |
| --- | --- |
| HTTPS and final remote configuration | 5/5 endpoints; Versioning API confirms `standard` and `cpu_ms: 1000`. |
| Registration, WebAuthn login and Godot authorization | 32/32 checks. |
| Arena, Story Mode, retries and revocation | 60/60 checks. |
| New accounts from this run | 2 QA isolated, 1 fighter and 24 cosmetics per account; 0 sessions. |
| Fights of this execution | 1 Arena and 1 Story Mode. |
| accumulated D1 | 4 QA accounts, 0 ordinary accounts and 0 QA sessions. |
| Run Settings | Paid, 1000 ms CPU per request; It is not a monthly budget. |

The reports are in `work/cloudflare-paid/`. No new CPU reading was obtained per invocation in Paid because the Observability panel did not load in Chrome. The expected HTTP states did check with Paid and the configured limit. No load test was performed. Available local evidence remains 365/365; It was not repeated by changing only the deployment configuration.

## Evidence prior to plan change

Testing ended on 21 September 2026 at 03:27 UTC — September 20 in Mexico City — on version `ce9db916-5337-4c93-8724-fdaed84cca91`. This version identifies smoke and CPU measurements. The version that closed that publication is `0f3491e2-c017-402e-a39d-5ea7dff1aec0`, with the same bundle, the fifth migration applied and sampling `0.1`. The secret was preserved without rotation.

| Validation | Result |
| --- | --- |
| Complete backend: engine, auth, D1, authority and concurrency | 365 final tests, 0 failures; 360/360 before smoke. |
| Remote migrations | All five, from `0001_identity` to `0005_starter_expansions`, applied; catalog reseeded and expansion registered `cats-v1`. |
| HTTPS, health, origin, cache, UI and 401 | 5/5 checks, repeated with 5/5 upon final publication. |
| Registration, WebAuthn login and Godot authorization | 32/32 checks. |
| Remote Arena and Story Mode, retries and revocation | 60/60 checks. |
| Final D1 reconciliation | 2 isolated QA accounts, 24 cosmetics—including Ónix and Bruma—and 1 fighter each, 1 Arena and 1 Story; 0 sessions and 0 ordinary players. |
| Published catalog | 31 cosmetics, 24 starters, 15 characters and 100 encounters. |
| Published package | 676.79 KiB tablets. |
| Cloudflare Free Historical CPU | 9 of 11 critical invocations exceed 10 ms; Arena 81 ms and Story Mode 48 ms. They all ended with `outcome=ok`; [detail and operating status](CLOUDFLARE-STAGING.md). |

The logs and reports for this publication are in `work/cloudflare-deploy/` from the root of the workspace. The reports contain statuses and IDs, without credentials. Test accounts do not appear as rivals of ordinary players.

## Historical evidence of integration

The following results are from the local Arena delivery prior to deployment. They are preserved as evidence of that review; **they are not repeated tests during this publication**.

| Historical validation | Result |
| --- | --- |
| Godot API / Native UI / HTTP vs Worker+D1 / Main | 27 / 787 / 32 / 25 checks, 0 failures. |
| Identity regression/battle/campaign interface | 80 / 2139 / 337 checks, 0 failures. |
| Engine parity | 274 reference bouts; 626375 identical numeric fields. |
| Simulation | 10000 fighting; average 2.73 ms and p95 4.08 ms on local Node. |
| Existing saves in that delivery | 7 files identical byte for byte to your baseline. |

The historical logs, hashes and 57 captures are in `work/online/final/manifest.json` and `work/online-audit/validation.json`. The tests use isolated fixtures. The Node benchmark does not represent Cloudflare's billed CPU.

## In-game access

1. Open `Jugar online.command` or **Online Arena** from the menu.
2. Press **Sign in to browser**. The game opens a page with your device code.
3. On the first visit, type **Account name**, press **Create account with passkey** and confirm with the device's fingerprint, face or PIN. If you already have an account, use **Enter with my passkey**.
4. Compare the browser code with Godot and press **Authorize this device**.
5. Get back in the game; will pick up the session automatically. Choose combat base, type **Name of your fighter** and press **Create fighter**.
6. In **Story**, use **Enter Encounter**. In Arena, **Update rivals** and **Challenge** when there are other players.

The [web shortcut](https://brasa-api-staging.acessloop.workers.dev/auth) allows you to create or start an account; To connect Godot you must start and approve the code from the game. The personal password is created by the user. Remote progress starts over and is saved on the server; statistics from local games do not matter. Godot's session remains in memory.

This version retains the automatic fights. Does not add manual attack selection or surrender during an active fight. It does not invent rivals when there are no other players and it does not simulate spontaneous fights in the background. Local modes continue to work offline.

[Full Contract](../backend/docs/ONLINE.md) · [Pre-Audit](../backend/docs/ARCHITECTURE-AUDIT.md) · [Authentication](../backend/docs/AUTH.md)
