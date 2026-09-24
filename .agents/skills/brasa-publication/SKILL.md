---
name: brasa-publication
description: "Prepare Brasa publications or visibility changes and review asset rights, Git history, and documentation for contributors and LLMs."
---

# Publish Brasa with clear licensing

The repository root is `../../..` from this folder. Read `AGENTS.md` and `docs/LLM-GUIDE.md`; resolve the paths below against that root.

Read LICENSING.md, THIRD_PARTY_NOTICES.md, and docs/PUBLICATION.md. Preserve MIT for original code and the PCG/Godot notices. Do not extend MIT to artwork, characters, or audio without the rights holder's instruction and sufficient rights.

Inspect both files and history before publishing. The public repository has a separate history without audio/video. Deleting a file from the latest commit does not remove it from history. Preserve the private backup and do not publish its branches or objects through push --mirror/--all.

Exclude secrets, databases, profiles, and binaries containing credentials. Check paths and rights for new media. Do not redistribute ElevenLabs audio as standalone files, Git LFS objects, or release assets without the applicable permission; attribution is not a substitute for a license.

Update English README, Markdown reports, skills, and instructions when workflows change. Do not restore removed HTML galleries. Preserve the application's Spanish localization. Use the owner's authenticated access within the specific authorization; do not infer permission to change visibility. Verify repository, visibility, branch, and remote commit before reporting completion. Publishing source is not deploying the game.
