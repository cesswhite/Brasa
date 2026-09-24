# Reproducible development

## Requirements and paths

Godot 4.7.2 standard is the reference version of the project. Use `godot` in PATH or replace the command with your binary. Godot imports assets and rebuilds `.godot/`; that directory is not versioned.

```sh
godot --headless --editor --path . --import
# Short logic test, with a disposable save:
godot --headless --path . --script res://tests/test_core.gd
# Specific check for public edition without audio:
godot --headless --path . --script res://tests/test_public_source.gd
# Visual system regressions (structural checks; not visual rendering validation):
godot --headless --path . --script res://tests/test_game_visual_system.gd
```

Inspect each test before launching it and use its test profiles. Do not delete or migrate the user's real profile. To review screenshots you need a visible renderer; compare desktop (1360×880), vertical mobile (390×844) and a short/horizontal window. Do not attribute visual results to a headless execution.

## Local backend

Node 22+ and npm. From `backend/`:

```sh
npm ci
npm run build
npm run db:migrate
npm run db:seed
npm run account:create
npm run dev
```

Local commands use D1 at `.local/state`. The generator writes the test credential to a private file without printing it. See [backend/README.md](../backend/README.md) to use it. `npm run build` synchronizes catalogs: check the resulting diff.

```sh
# From backend/: local tests; no deployment
npm test
npm run catalog:check
```

Remote testing and administrative tools require a specific authorized environment. A refactoring request or dependency installation does not authorize remote operations. `wrangler.staging.jsonc` describes the owner's staging environment; create an independent configuration for a fork.

## Audio and checkout variants

The public version retains `data/audio_events.json`, the audio director and the manifest, but not the sound or video files. The audio system checks for available streams before loading paths; the public edition must continue to run silently when recordings are absent. Suites that verify physical samples, metadata or full playback require the authorized pack and must be identified as not applicable to the public checkout; do not create empty WAV files to make those tests pass.

## macOS Keychain

The native helper has source code at `native/macos/session_store.swift`. To recompile it on macOS use `native/macos/build.sh` with the development tools installed. Keychain persistence is specific to macOS; don't claim equivalent support on other systems without implementing and testing it.

## What to check according to the change

| Change | Relevant evidence |
| --- | --- |
| Rules/progression | Logic and migration tests; backend parity if it affects online |
| UI/layout | Component tests + real screenshots in various sizes |
| Sprites/wounds | Anchors, volume, tone, transparency and visible damage between poses |
| Auth/API | Identity, owner, revocation and validation tests |
| Persisting results | Idempotence, revision, concurrency and rollback |
| Documentation/license | Links, scope of permissions, skills references and provenance |

Select tests that cover the change. Report pre-existing failures; do not hide them or alter game balance merely to satisfy an old test.
