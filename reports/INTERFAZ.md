# Immersive combat interface

Validated with Godot 4.7.2 on macOS on September 20 2026.

The sand covers the entire window with the original illustrated background and larger sprites. A lower gradient integrates the main action, secondary controls and surrender. Facing HUDs show name, level, and life; Each wrestler's activity is noted by text and emphasis on the ground. The states are placed next to the characters, the record can be opened on demand and the result preserves the combat scene.

Training, equipment, tab, history, registration, help, audio and rhythm are still available. The panels pause the simulation; surrender requires confirming. The engine, rewards, and balance data have not been changed.

| final test | Checks | Failures |
| --- | ---: | ---: |
| Regression controls, training and compatibility | 185 | 0 |
| Engine, probabilities, signatures and states | 396 | 0 |
| Progression, migration, XP and saving | 563 | 0 |
| Sprites, transparency, anchors and transitions | 258 | 0 |
| Adaptable squad, selection and files | 283 | 0 |
| Battle distribution, controls, results and signature cycle | 2139 | 0 |
| **Total project suites** | **3824** | **0** |

The integrated test also passed: roster, training panel, improvement, signature, combat, unique reward, summary, history, record, rematch, cancellation and surrender confirmation, and reload. All tests use saves separate from the actual game.

Seven viewport sizes were verified: **1360×880, 1224×792, 1920×1080, 768×1024, 390×844, 430×932, and 844×390**. Checks include actual limits of controls, absence of overlaps, accessibility of Equipment and Summary after a fight, pause in documents and preservation of the seed, combat status and progress when resizing. Resizing during character entry cancels the previous scrolling and applies the new positions.

An additional test of the arena rendering passed **144 checks** with GPU: no-warp coverage, impact and particle coordinates, shift indicator and backing background. Native captures of rest, combat, result, menu, training and surrender were reviewed, in addition to a forced signature exclusively for visual review. Movable sizes were simulated in Godot viewports; no physical mobile devices were tested.

Added regressions for a signature that ends the fight and for two consecutive signatures: the result closes the banner and the replacement cancels the previous animation, preventing the record from reappearing under a signature still visible.

The real app was reopened and the training panel and F11 were checked. It was left open full screen with **Mugo, level 3, 65 XP and 2 points**, ready to play. The actual save is byte-for-byte identical to the file before this reopening; no points were spent or test battles played in that match.

Screenshots of the interface with test games:

- [Desktop Combat](interfaz-escritorio.png)
- [Combat in mobile format](interfaz-movil.png)
- [Result in landscape format](interfaz-horizontal.png)
- [Signature Strike](interfaz-firma.png)
