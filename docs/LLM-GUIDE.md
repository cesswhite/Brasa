# Context map for another LLM

Start with [AGENTS.md](../AGENTS.md). This file routes to code and contracts; current checkout data takes precedence over historical reports.

| Task | Entry and sources |
| --- | --- |
| Navigation/screens | `scripts/main.gd`, `scripts/ui/`, `scenes/main.tscn` |
| Visual system | `scripts/ui/game_visual_system.gd`, `scripts/ui/components/`, `data/game_visual_tokens.json`, [visual bible](../reports/VISUAL-STYLE-BIBLE.md) |
| Characters and scale | `scripts/fighter_view.gd`, `scripts/character_visual_profile.gd`, `scripts/fighter_animation_set.gd` |
| Wounds | `scripts/damage_art.gd`, `scripts/visual_damage_state.gd` |
| Rules and combat | `scripts/combat_engine.gd`, `scripts/combat_rules.gd`, `scripts/move_catalog.gd` |
| Progression/Story Mode | `scripts/progression.gd`, `scripts/story_progression.gd`, `scripts/story_catalog.gd`, `scripts/story_achievements.gd` |
| Identity/cosmetics | `scripts/fighter_identity.gd`, `scripts/cosmetic_catalog.gd`, `scripts/battle_identity.gd` |
| Audio | `scripts/audio/audio_director.gd`, `data/audio_events.json`, [restrictions](../LICENSING.md) |
| Online client | `scripts/online_api.gd`, `scripts/identity_api.gd`, `scripts/online_session_store.gd` |
| Worker/identity | `backend/src/`, [auth](../backend/docs/AUTH.md), [online contract](../backend/docs/ONLINE.md) |
| Authoritative engine | `backend/battle-engine/`, [contract and parity](../backend/battle-engine/README.md) |
| Tests | `tests/`, `backend/tests/`, [guide](DEVELOPMENT.md) |

## Contracts that you should not infer

- Cloning this repository does not authorize access to the maintainer's personal Cloudflare account. Documented staging is a real remote service.
- A name or ID submitted by the client does not demonstrate ownership. Online results are calculated on the server.
- Keep local and online profiles separate; local saves are not trusted server progress.
- A past test recorded in `reports/` does not validate new changes. Identify the revision, test, and environment used.
- The missing audio files are intentional in the public edition; do not republish the private pack to fix a test.
- MIT does not cover art/audio or replace third party licenses.

## Workflow

Load only the relevant context; inspect tests and consumers before changing contracts. Keep APIs/migrations unless the task asks to change them. Verify the implementation with relevant tests and, if the UI changes, with screenshots. Report changes, evidence, and limitations without claiming deployments or biometric confirmations that did not occur.

[Skills](../SKILLS.md) have paths relative to the repo root and do not depend on a personal Codex installation. Any LLM that can read files can follow a skill’s `SKILL.md` even if it doesn't have auto discovery.
