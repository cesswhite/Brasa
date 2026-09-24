# Brasa · Liga de los Faroles

A 2D auto-battler built with Godot. Choose a companion, develop their abilities, and progress through Story Mode or Arena. The game combines illustrated characters, individual progression, and an optional Cloudflare Workers + D1 backend.

**Game language: Spanish.** The game interface and dialogue are in Spanish; repository documentation is in English.

**Original code: MIT. Artwork and game identity: all applicable rights reserved.** The public edition excludes audio and video files. Read [the licensing scope](LICENSING.md) before reusing content.

## Run the game

Reference version: **Godot 4.7.2 standard**. Development was validated on macOS. The interface adapts to desktop and mobile layouts, but this repository does not include an exported mobile app.

```sh
git clone https://github.com/cesswhite/Brasa.git
cd Brasa
# If Godot is on PATH:
godot --editor --path .
```

Alternatively, import `project.godot` in Godot and press **F5**. On macOS, `Jugar.command` expects Godot at `/Applications/Godot.app`.

Create a companion and enter Story Mode. Battles resolve automatically; train and customize your companion between encounters. Save files live outside the repository in the `BrasaLiga` user directory.

### Audio in the public edition

Audio files and videos are excluded because of the provider's distribution restrictions. The audio system and its catalog remain available; missing recordings are skipped. Tests that require the complete audio pack need authorized assets. See [development](docs/DEVELOPMENT.md) and [third-party notices](THIRD_PARTY_NOTICES.md). The owner's local project and private backup retain the original audio.

## Documentation

- [Development and testing](docs/DEVELOPMENT.md)
- [Project map for LLMs](docs/LLM-GUIDE.md)
- [Agent instructions](AGENTS.md) and [local skills](SKILLS.md)
- [Contributing](CONTRIBUTING.md) and [security](SECURITY.md)
- [Backend setup and API](backend/README.md)
- [Historical game guide](docs/GAME-GUIDE.md)
- [Technical reports and verification records](reports/README.md)

Reports record historical evidence, not a guarantee that the current revision passes every past test. References to the original workstation's `work/` directory describe artifacts not included here. Development-only HTML galleries have been removed; Markdown reports and referenced screenshots remain.

## Online play and Cloudflare

The backend implements asynchronous Arena and online Story Mode with sessions, passkeys, and authoritative results. References to the owner's staging service remain for context; availability and access are not guaranteed. Cloning this repository does not authorize administration, load testing, migrations, or deployments against that account.

Use the **local backend** for development. For your own deployment, provision your own resources and secrets, configure origins, RP IDs and bindings, and follow [deployment documentation](backend/docs/DEPLOYMENT.md). Resource IDs are not credentials. Never put secrets in `data/online_config.json` or the game executable.

## Licensing

[MIT covers original code and technical documentation](LICENSE), subject to the [artwork, audio, and third-party exceptions](LICENSING.md). Preserve [third-party notices](THIRD_PARTY_NOTICES.md). Public availability does not grant an open license to Brasa's characters, artwork, or audio.
