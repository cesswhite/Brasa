---
name: brasa-game
description: "Modify Brasa combat, Story Mode, progression, or identity while preserving save contracts and online parity when relevant."
---

# Change Brasa game logic

The repository root is `../../..` from this folder. Read `AGENTS.md` and `docs/LLM-GUIDE.md`; resolve the paths below against that root.

Locate the contract in scripts/combat_engine.gd, combat_rules.gd, progression.gd, or story_progression.gd before editing main.gd. Preserve character IDs and save schemas; test migrations with fixtures without rewriting real saves.

If a rule affects online play, read backend/battle-engine/README.md and inspect the port and exported catalog. Preserve RNG consumption order and numerical precision. A visual change does not justify rebalancing, and client-submitted results are not authoritative.

Run relevant checks from docs/DEVELOPMENT.md and report actual results. Historical suites do not validate the current revision. Do not deploy or use staging for a local task.
