# Brasa · agent instructions

Read [README.md](README.md), [docs/LLM-GUIDE.md](docs/LLM-GUIDE.md), and the relevant subsystem before editing. Local skills: [SKILLS.md](SKILLS.md).

## Language and scope

Write documentation, reports, skills, and agent instructions in English. The game UI, dialogue, and player-facing authentication flow remain in Spanish. Preserve exact identifiers, file paths, character names, and quoted localization values.

Godot/GDScript presents the game; Workers/D1 calculates and persists online results. Preserve server authority, owner-scoped authorization, idempotency, and migration contracts.

## Verification and publication

- Use the commands in `docs/DEVELOPMENT.md` with disposable profiles/databases. Do not alter user saves to validate a change.
- Reports are dated evidence. Distinguish local tests, native captures, remote tests, and actual deployments.
- A coding request does not authorize operations on the owner's Cloudflare account. Honor an explicit authorization already granted without requesting the same approval again.
- Original code and technical documentation are MIT-licensed; artwork/audio rights are reserved, and PCG/Godot retain their notices. Read `LICENSING.md` and `THIRD_PARTY_NOTICES.md`.
- The public edition intentionally excludes audio and videos. Do not retrieve them from private history or upload them through Git LFS, releases, or CI without distribution rights.
- Keep secrets, credentials, profiles, local databases, node_modules, and caches out of Git. Configure the target environment instead of copying remote IDs by default.
- Keep public documentation in Markdown. Use `reports/README.md` to locate reports; development-only HTML galleries have been removed. The backend authentication HTML remains part of the application.

## Characters and UX

Preserve relative size by species and body volume, consistent anchors, and real transparency. Wounds must be visible and localized without changing the entire body's hue, brightness, or opacity. Keep characters readable and moderately sized on mobile and desktop. Avoid clipped focus outlines; retain an accessible focus indicator integrated with the button.

# Brasa visual authority

The approved Story Mode is the visual authority for this game. Read `reports/VISUAL-STYLE-BIBLE.md` and `reports/VISUAL-SCREEN-AUDIT.md` before changing a screen.

- Reuse `scripts/ui/game_visual_system.gd`, `data/game_visual_tokens.json`, the `WorldVisuals` material registry and `WorldBackdrop` layers. Extend their named roles when a feature needs a new state; do not introduce another local Theme, font stack or unrelated button/panel family.
- Use shared components in `scripts/ui/components/` for fighter presentation, section headers, badges and modals. Keep game logic, network actions, identity and progression outside visual components.
- Different locations may supply a background, contextual accent and eligible props. All inherit Story's painted bronze/leather materials, typography, legibility overlays and interaction states.
- Environmental memories must use the manifest's eligibility rules, never random rewards or fabricated ownership. Preserve the complete fighter appearance in previews and records.
- Keep text native and readable, keyboard focus visible, controls accessible in narrow/short windows, and decorative nodes non-interactive. Respect pause and reduced motion. Do not restore circular fire/energy FX.
- Migrate one screen at a time after the shared system exists. Compare native desktop/mobile captures with Story, validate navigation and real interaction states, then update the screenshot evidence and Markdown screen audit. Clearly distinguish fixtures from live/server data.
- Do not modify gameplay balance, user saves or backend state for a visual change. Validate with disposable test profiles.
