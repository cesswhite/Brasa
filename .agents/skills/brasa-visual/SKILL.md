---
name: brasa-visual
description: "Modify or review Brasa screens, components, sprites, wounds, and responsive character sizing using its established visual system."
---

# Improve Brasa UI and sprites

The repository root is `../../..` from this folder. Read `AGENTS.md` and `docs/LLM-GUIDE.md`; resolve the paths below against that root.

Read reports/VISUAL-STYLE-BIBLE.md and reports/VISUAL-SCREEN-AUDIT.md. Reuse GameVisualSystem, its tokens, and shared components rather than introducing a parallel theme. Preserve navigation, keyboard focus, pause, and reduced motion.

Keep characters prominent but moderately sized on desktop and mobile while preserving relative volume, anchors, and proportions. Wounds must be localized and perceptible without shifting whole-body hue, brightness, or opacity. Preserve actual transparency; a painted checkerboard is not an alpha channel.

For new assets, preserve identity and provenance. Previews must not change combat rules, ownership, or unlocks. Check locked, selected, hover, and focus states without clipped outlines.

Use targeted tests and native captures at 1360x880 and 390x844, plus a short window where layout is affected. Headless tests validate structure, not appearance. Read LICENSING.md before adding or redistributing media. Keep player-facing text in Spanish and reports in English; use Markdown reports rather than HTML galleries.
