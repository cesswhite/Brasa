# Brasa · game service

Cloudflare Worker + D1 for identity, passkey authentication, persistent fighters, asynchronous Arena, 100 Story Mode matches, progression, rating, history and defensive results.

Godot presents the events saved by the server. The combat retains the automatic format of the game: you choose fighter, build, strategy and rival. Arena and Story Mode online share a profile. Local League and Story Mode are still available and local saves are not imported as trusted online progress.

**Note for forks:** the following paragraph is historical evidence from September of 2026, not a guarantee of availability or permission to operate the service. Use your own resources for your deployment.

[Cloudflare staging](https://brasa-api-staging.acessloop.workers.dev/health) is published and has passed remote access, Arena, and Story Mode verification. The user activated Workers Paid, confirmed as a current plan on Cloudflare. The replay passed 32/32 access checks and 60/60 game and revocation checks, with CPU limit of 1000 ms per request. This limit is not a monthly budget or a billing cap. [Status, tests and measurements](../reports/CLOUDFLARE-STAGING.md).

## Documentation

- [Previous audit and plan](docs/ARCHITECTURE-AUDIT.md).
- [API, persistence, concurrency and online reach](docs/ONLINE.md).
- [Authentication, sessions and passkeys](docs/AUTH.md).
- [Deterministic engine, corpus and simulations](battle-engine/README.md).
- [Staging deployment and validation](docs/DEPLOYMENT.md).

## Local development

Node 22 or later. From this directory:

```sh
npm ci
npm run build
npm run db:migrate
npm run db:seed
npm run account:create
npm run dev
```

`wrangler.jsonc` keeps `AUTH_MODE=local_dev`, loopback `127.0.0.1:8787` and independent D1 in `.local/state`. No Cloudflare session required. `account:create` generates a seven-day development credential; writes the token to a file with permissions 0600 and stores only its hash in D1. Does not print the token. To renew the same account, use `npm run account:create -- --account UUID`.

```sh
npm run api -- --credential .local/credentials/ARCHIVO.json --path /v1/fighters
npm run token:revoke -- --credential .local/credentials/ARCHIVO.json
```

The `inventory:grant` tool and local credentials never operate on the remote database. Test fixtures use temporary databases and do not touch `.local/state` or Godot saves.

## Play online

1. Open `Jugar online.command` from Brasa or **Online Arena** in the game menu.
2. Press **Login to browser** and use **Create account with passkey** on your first visit, or **Enter with my passkey** if you already have an account. Confirm with your device.
3. Compare the code with Godot and press **Authorize this device**.
4. Return to the game, choose combat base and name, and press **Create fighter**. You can start **Story** even if there are no public rivals yet.

The personal passkey is created by the user on their device. The game token remains in memory; logging out revokes it. The [web shortcut](https://brasa-api-staging.acessloop.workers.dev/auth) does not connect Godot without starting and approving its code. The [full flow](docs/AUTH.md#sign-in-from-godot) explains each step.

The public URL is at `data/online_config.json` in the game. D1, the secret and the results of the deployment are documented in [DEPLOYMENT.md](docs/DEPLOYMENT.md).

## Reproducible validation

```sh
npm test
npm run catalog:check
node tests/engine-benchmark.mjs
npx wrangler deploy --dry-run --config wrangler.staging.jsonc
```

The suite includes numerical parity with Godot, passkeys with real cryptographic signatures, per-account authorization, idempotent operations, revision checks, concurrency races, rollback, immutable snapshots, and reward limits. Remote testing is explicit and separates validation accounts from ordinary matchmaking.

The backend and its dependencies are excluded from Godot using `.gdignore`. `.local`, `.wrangler`, `dist`, `node_modules`, and secrets are excluded using `.gitignore`. Do not place secrets in `online_config.json` or the executable.
