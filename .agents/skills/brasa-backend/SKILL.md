---
name: brasa-backend
description: "Implement or fix Brasa APIs, authentication, persistence, or its authoritative online engine on Cloudflare Workers and D1."
---

# Maintain the Brasa backend

The repository root is `../../..` from this folder. Read `AGENTS.md` and `docs/LLM-GUIDE.md`; resolve the paths below against that root.

Read backend/README.md and the relevant contract in backend/docs/AUTH.md or backend/docs/ONLINE.md. Derive identity from a validated session and scope operations to the owner. Use parameterized queries, revisions, transactions, and idempotent results. Do not rewrite migrations already applied to other databases.

For combat changes, read backend/battle-engine/README.md and verify parity. Keep tokens out of logs, presentation JSON, and executables. Passkeys and device authorization depend on Better Auth and consistent origins/RP IDs; do not claim a biometric ceremony completed without evidence.

Test with Miniflare, isolated databases, and documented local scripts. backend/wrangler.staging.jsonc and historical reports refer to the owner's environment and do not authorize remote operations. For an explicitly requested independent deployment, configure the target resources/secrets and verify the enabled flows.

Review generated catalog changes after building. Report code, tests, migrations, and local/remote state separately. Keep developer documentation in English and player-facing authentication copy in Spanish.
