# Brasa Historical Guide

Preserved document of local delivery. Figures, tests, external routes and service status describe their date; queries README.md and the code for the current checkout status. Some `work/` files belong to the original environment and are not distributed.

# Brasa Liga de los Faroles

2D auto-battler for Mac: choose and train your companion, who fights automatically in an illustrated night market. The arena fills the window, with image-animated characters, opposing HUDs and controls over a transparent gradient. Includes fifteen customizable characters, five moves per character, a 100-encounter campaign, technique upgrades, talents, individual progression and the original league.

## Get the project from GitHub

```sh
git clone https://github.com/cesswhite/Brasa.git
cd Brasa
```

Import `project.godot` in Godot or use `Jugar.command` in macOS. The repository includes code, assets, backend, tests and documentation. Godot rebuilds your `.godot/` cache when you open it.

To work on the backend, see [backend/README.md](../backend/README.md). Its dependencies are installed with `npm ci` inside `backend/`; Credentials, secrets, local bases and personal items are not part of the repository. Clone the project does not publish or modify the existing Cloudflare server.

## Open and play

Requires **Godot 4.7.2 standard for Mac**, installed on `/Applications/Godot.app`.

1. Open **Play.command** with double click.
2. In a new game, choose combat base, name and appearance; press **Create Companion** to enter Story Mode and distribute your **3 starting points**.
3. Choose the encounter and press **Enter Battle**. In League, use **Enter Arena** or **Space**. The attacks are automatic.
4. When finished, open **Summary** to see both your experience and level improvements.
5. Train or change your partner. Each one retains their level, XP, points and results.

**In League, Train:** opens all four upgrades. **In Story Mode, Improvements:** allows points to be distributed among eight attributes. **Companions** (or **Team** in small windows): squad and selection. **Menu:** shelter with your fighter and access to Story Mode, Arena, Customize, Profile, Match History, Registration and How to play. **Menu → Settings:** Sound, Rhythm, Reduced motion and Full screen. **Esc:** close panels. **F11:** toggle full screen. **Rhythm ×2:** speed up playback, without changing the rules. Reading panels pause combat.

During the fight, the main button indicates **Automatic Combat** and the turn indicator identifies the acting character. Temporary effects appear next to each fighter; the entire log opens from Menu or Log when visible. **Surrender** remains separate and requires confirmation. The result, the XP of both and the level changes appear on the same arena; **Summary** retains full detail.

The layout adapts to desktop windows, tablet proportions, vertical and horizontal mobile. The background retains its proportion and is trimmed to cover the window; The controls maintain limited sizes. This release is still the local project for Mac, without an exported mobile package.

You can import `project.godot` into Godot and press **F5**. For **F6**, open `scenes/main.tscn`.

## Customize your companion

Open **Menu → Customize** or the **Companions** tab to edit name, body, palette, aura, trail, victory, and entry. Preview allows you to test combinations before **Save changes**; cancel preserves the previous. The combat base maintains its techniques and statistics even if you choose another body.

There are **31 options**: 15 bodies, 5 palettes, 4 auras, 3 trails, 2 wins and 2 entries, counting the variants original and without effect. Part is obtained by reaching level 10, winning 10/25 League battles or passing 8/20/50/100 Story Mode encounters. Inventory is shared, no purchases. Current atlases allow light tinting of the entire illustration; They do not have separate layers of clothing or hair.

Each archetype shares its name and appearance between League and Story, with stable ID, while both modes retain their independent progression. The previous names are preserved. The identity is stored separately in `<save>.identity.json`, with backup and atomic writing. New fights retain name, appearance, and events: **Match History → Watch Replays** shows that version of the companion without granting XP or changing progress.

The above identity is adapted to v2 to include the two cat bodies. Keep names, IDs, equipment and rewards; loading does not rewrite files and the next save preserves a v1 copy. [Compatibility and testing](../reports/CAT_IDENTITY_MIGRATION.md).

**Online Arena** is published on a [Cloudflare test server](https://brasa-api-staging.acessloop.workers.dev/auth), with passkeys, persistent fighters, rivals from other accounts, history and defensive results. Arena and Online Story share progression; local saves remain independent. Access, Arena and Story passed remote testing. The user activated Workers Paid, confirmed in Cloudflare, and the remote check was successfully repeated under that plan: 32 access checks and 60 game and revocation checks.

To enter, open `Jugar online.command` or **Online Arena** in the menu and press **Login in browser**. Use **Create account with passkey** or **Enter with my passkey**, confirm on your device, compare the code and press **Authorize this device**. When you return to the game you will be able to create your fighter. **Story Mode** allows you to play even if there are no public rivals yet. See [access steps](../backend/docs/AUTH.md#sign-in-from-godot) and [Cloudflare status](../reports/CLOUDFLARE-STAGING.md). Local customization is documented in [CUSTOMIZATION](../reports/PERSONALIZACION.md).

## Story Mode 100 encounters

Story Mode uses illustrated settings: lantern path, storm yard, training workshop, shelter, and legacy archive. The opponent dominates the preview, encounters form a connected path, and controls retain native text. Small belongings and keepsakes appear based on appearance and progress. The [visual report](../reports/UI-WORLD.md) brings together the comparison, captures and validation; [art direction and prompts](../assets/ui/ART-DIRECTION.md) documents the seven new images.

Story is also the visual authority of the entire game. Menu, Arena, Online, crafting, tokens, upgrades, companions, results, replays and settings all reuse `GameVisualSystem`, its tokens and components. Check out the [visual bible](../reports/VISUAL-STYLE-BIBLE.md), [screen audit](../reports/VISUAL-SCREEN-AUDIT.md), and [Report](../reports/VISUAL-SCREEN-AUDIT.md). The wall data are local fixtures; screens preserve the actual identity, progress, and server flows.

Open **Story Mode**, next to Menu. Each companion begins an independent campaign at level 1, with their normal statistics, three points and two techniques. The league retains its own progression.

The path contains **100 encounters in 11 chapters**. The first two maintain their eight matches, Ascua and Véspera; Nima remains at level 2. The third chapter covers encounters 17–20 and the other ten each. There are bosses in 8, 16, 20, 30, 40, **50**, 60, 70, 80, 90 and **100**, plus elites among them. Ascua returns as Heart of the Solstice in 50; Véspera closes the campaign as The Last Eclipse.

The map distinguishes **Story encounter** and **character level**, allows you to consult chapters and shows the next boss and reward. Previews explain style, strengths, weaknesses, techniques and skill. Some normal matches choose between compatible rivals; The choice is preserved during that campaign, also when reopening the game or retrying. Bosses have a fixed identity.

**Upgrades** offers eight attributes: Life, Attack, Defense, Speed, Accuracy, Evasion, Critical and Resistance. Going up to level 20 grants three points per level; then two. The elites from the first two chapters retain their two additional points. Previous games maintain all the points they had already earned.

**Moves** explains the character's five techniques and their risks. Start with two and unlock the others at character levels **5, 12 and 20**. The encounter sheets **5, 10, 20, 30, 40, 50, 60, 70, 80 and 90** allow you to improve techniques by up to two degrees. The encounters **10, 30 and 50** grant a choice of talent: you can choose three of six options linked to the character.

In **Upgrades → Redistribute Upgrades** you can recover the points, tokens and choices you already spent to develop another strategy. Requires confirmation within the game; preserves level, XP, route and chapter history. It does not create new resources.

Victories give more XP than defeats. Complete defeats allow you to continue improving and generate a track based on failures, pace, criticals or states of that fight. Giving up and repeating defeats reduce the reward. You can replay beaten encounters as **practice without additional XP or rewards**.

Each chapter closure remains in **Legacy**, with statistics, decisions and insignia. The transition to the next chapter is explicit. Bosses obey the same rules and limits; Special boss phases are described and announced during combat.

Story Mode is saved in `~/Library/Application Support/BrasaLiga/brasa_save.json.story.json`. The v3 format reads the v1/v2 formats without writing when opening them or advancing chapters. Before the first write it retains a permanent copy of `.v1.bak` or `.v2.bak`, in addition to the usual backup and atomic write. The tests use separate copies and files.

## Audio · first stage

The first directed bank covers **Ascua and Patio de Faroles** with 51 selected files from ElevenLabs: movement, contact, guard, critical, charcoal, transformation, Signature, KO, results, confirmation, atmosphere and original music. Shared physical sounds also accompany the other fighters; his own powers and the other environments remain in the production plan. Sounds are triggered by actual combat events and markers, also in replays and Online Arena. The realism overhaul replaces contact, motion and environment, preserves the natural speed of the recordings and reduces friction and layers of fire.

**Menu → Settings** allows you to save the General, Music and Effects volumes. Mute preserves those values. Pause stops new sound actions, and Reduced Motion preserves the audio. The mix separates music, environment, movement, touch, UI and reactions, with variations and priorities.

Check out the [bible and audio plan](../reports/AUDIO-BIBLE.md), [delivery and validation](../reports/AUDIO-DELIVERY.md), and [Report](../reports/AUDIO-ASSET-REVIEW.md). Technical measurements do not replace a hearing check; The production of the rest of the squad is documented for the next stage.

## Techniques and animation

Each technique has damage, accuracy, priority, critical, statuses, cooldown, readiness, shift, cooldown, risk, and unlock data. Automatic selection considers health, relative speed, statuses, cooldowns and previous moves, with random variation.

Quick blows serve to maintain pressure; the strong have long anticipation and recovery. Loads move backwards before they move forward. Jumps use different trajectories and advantages. Defensive postures can reduce damage and provoke probabilistic responses. The original abilities are still active; The Signature Strike is independent of normal techniques.

The engine sends preparation and impact separately: damage is applied on contact. Aftershocks can be animated alongside another attack without clearing their buildup. **Rhythm ×2** accelerates simulation and animation together. **Menu → Settings → Reduced motion** preserves poses and times without movement, flashes or particles. Open the menu pause both fighters and the fight.

All fifteen companions and both bosses now have anticipation, attack, follow-up, and recovery sequences, with different reactions for quick hits, heavy hits, critical hits, charges, and signatures. The KO begins in the lethal event, also by poison or burn. Dust, trails and impacts are composed as independent effects. Ascua has a temporary visual transformation. The [animation report](../reports/ANIMATION-SEQUENCES.md) includes the video, the first 480 additional frames, their prompts, and the checks. With the two cats, the team adds **544 additional poses on 34 benches**; the extension is documented in [GATOS.md](../reports/GATOS.md).

Charges, impacts, auras, and inputs now use **organic particles**: embers, motes, and dust that follow the pose and break off with movement. The light is integrated into the silhouette and the energy circles stop showing. [Comparison and validation](../reports/EFECTOS-ORGANICOS.md).

## Fifteen ways to fight

| Companion | Identity | Advantage and trade-off |
| --- | --- | --- |
| Nima | Speed and combos | Press with your sequence; It has little defense. |
| Luma | Balance and adaptation | Improves accuracy after failure; It does not have an explosive specialty. |
| Mugo | Tough tank | Holds and cushions criticals; attack slowly. |
| Sira | Critics | His critics cut through part of the defense; withstands few blows. |
| Iria | Poison | Accumulates wear; It takes time and has low direct damage. |
| Duna | Shields | Blocks damage periodically; It exerts little initial pressure. |
| Kiro | Risk and fury | Gain damage upon losing life; can fail at the decisive moment. |
| Neris | Recovery | Heals once when HP drops; healing may be weakened. |
| Taro | Counterattacks | Punishes attacks received; its replicas are probabilistic. |
| Balam Jaguar | stalking and charges | Punishes with strong and critical hits; You need to prepare your attacks. |
| Tepa · Teporingo | Jumps and speed | Change trajectory and press quickly; It has little life and defense. |
| Xuna · Xoloitzcuintle | Guard and wear | Resists critical and maintains burns; takes time to impose its rhythm. |
| Copal · Cacomixtle | Feints and retorts | Combine displacement, deception and counterattacks; Your answers are not guaranteed. |
| Ónix · Black cat | Speed and evasion | Press with combos and dodges; It has little life and defense. |
| Bruma · Gray cat | Precision and counterattacks | Maintains rhythm and responds to blows; has less evasion. |

The nine original companions retain their own appearances: Nima is a lynx; Luma, an axolotl; Mugo, a golem; Sira, a mantis; Iria, a botanical frog; Duna, an armadillo; Kiro, a wild boar; Neris, a heron; and Taro, a badger. Ascua has a unique volcanic guardian design with horns, tail and amber core. Véspera, the boss of the second chapter, is a lunar moth with indigo and silver wings.

Balam, Tepa, Xuna and Copal add four animals linked to Mexico, with their own illustrations, five techniques, six talent options and an individual Signature Strike. They are available from **Companions** in the league and **Story Mode → Companions** to start independent campaigns. Previous games retain their active characters and their progress. Art, prompts and references are in [assets/sprites/FAUNA-MEXICANA.md](../assets/sprites/FAUNA-MEXICANA.md).

**Ónix**, black cat with yellow eyes, and **Bruma**, gray cat with greenish eyes, each have five techniques, six talents, and 40 illustrated poses. They are chosen in League and Story Mode and retain individual progression. Its designs, tests and prompts are in [reports/GATOS.md](../reports/GATOS.md).

Each character retains their eight original PNG poses with transparency: Rest, Breath, Prepare, Punch, Impact, Dodge, Victory, and Defeat. **32 poses per body** are added, distributed in two transparent atlases, for the **17 bodies** in the game. Skills and progress retain their original identity. The sequences and their origin are in [assets/sprites/sequences/manifest.json](../assets/sprites/sequences/manifest.json). The seven original designs and their prompts are in [assets/sprites/PERSONAJES-V3.md](../assets/sprites/PERSONAJES-V3.md); the first three atlases, in [assets/sprites/PROMPTS.md](../assets/sprites/PROMPTS.md); the background and its origin, in [assets/ARTE.md](../assets/ARTE.md).

## Statistics, probabilities and effects

Stats come from a single definition per character: base level one, self-growth, and acquired training. Fight effects modify a temporary copy. Training retains four controls, capped at 30 per value: Life adds 20 HP; Strength adds attack 1.5; Agility improves evasion and critical; Speed ​​shortens the interval between actions.

| Statistics | Effect and limits |
| --- | --- |
| Life | 100–2000 PV. Recovers when starting a fight. |
| Attack | 5–150 before defense and modifiers. Normal variation of ±8%. |
| Defense | 0–160. Damage received × `100 / (100 + defensa)`. |
| Speed | 1–36. Interval `2.4 / (1 + velocidad × 0.035)` seconds. |
| Accuracy | He faces evasion. Final probability of hitting between 62% and 96%. |
| Evasion | 0–30%; reduces the chance of being hit. |
| Critical | 3–32% when connecting. It is calculated separately from the success. |
| critical damage | Multiplier ×1.2–×2.1; It is not combined with the signature. |
| Resistance | 0–50%; reduces application or duration of negative states. |

Luck is not included: it would double other probabilities without offering a different decision. An internal power value helps match rivals and never multiplies damage. Levels add gradual growth; after level 20 the 45% of normal growth is applied. Rivals look for each other close to the level and power of the active partner.

Each fighter has their own skill and a separate **Signature Blow**: a single **1% roll is made at the beginning of each fight**, never a roll per attack. If it comes out, it is scheduled for one of its first actions. It can only occur once, always connects, deals approximately **×1.6** normal damage, and applies a debuff with explicit duration. Resistance can shorten the signature, but not cancel it. A fight that ends before the planned action may prevent it from being seen.

States include type, magnitude, source, duration, remaining turns, and accumulation rule. The time of a state is measured in **actions of the affected character**. Repeated applications refresh, replace or build intensity depending on your definition; limits and expiration are applied in the common module. Life, shields, and remaining turns appear in the arena; Record explains the events.

The combat ends when life is exhausted or by surrender. At **60 seconds** whoever retains the greatest proportion of life wins. Exact ties are resolved reproducibly with combat RNG. The best numbers maintain a statistical advantage, with occasionally unexpected results.

## Experience and surrender in the league

`55 + (nivel − 1) × 25` XP is required to upload. Excess XP is conserved and each level awards **2 points** in addition to the character's particular growth. The maximum level is **50**; Subsequent experience continues to count for your career.

At level one, the base rewards are **40 XP for victory**, **25 for defeat** and **8 for surrender**. They increase one 16% from the base value per level. Very short games and repetitions reduce the corresponding reward. The winner by surrender receives a normal victory; whoever abandons receives **at least 1 XP**. A short four-second pause after surrendering limits XP gain through instant surrenders. Rivals also retain XP and level up in profiles separate from the player's roster.

**Surrender** requires confirmation. While you decide, the simulation is paused. Upon confirmation, the engine terminates immediately: there are no subsequent attacks or duplicate rewards. The history distinguishes surrender from a normal defeat and updates wins, losses and streaks.

## League saving and compatibility

The automatic local save is located at:

```text
~/Library/Application Support/BrasaLiga/brasa_save.json
```

The 2 version saves the squad, active teammate, rivals, history and reward controls. Migrate the previous version keeping name, level, XP, training, points and results, and create a backup before writing. Use temporary writing and atomic replacement. A file that is corrupt or of an unknown version is protected to prevent overwriting progress that cannot be interpreted.

Local modes require no account, internet or purchases. Arena online requires connection and an account with a passkey; The duels are asynchronous and automatic, without simultaneous connection of the participants. Cosmetics do not alter statistics.

## Architecture and testing

| File | Responsibility |
| --- | --- |
| `scripts/balance.gd` | Curves, probabilities, caps, XP and global constants. |
| `scripts/move_catalog.gd` | Techniques, unlocks, grades, talents and selection weights. |
| `scripts/campaign_config.gd` | Chapters, budgets, variants, bosses, rewards and milestones. |
| `scripts/character_catalog.gd` | Fifteen definitions, aids and calculation of statistics/power. |
| `scripts/combat_rules.gd` | Common hit, critical and damage calculations. |
| `scripts/status_effects.gd` | Temporary effects, accumulation, resistance and expiration. |
| `scripts/combat_engine.gd` | Authoritative state, initiative, RNG with seed, events and summary. |
| `scripts/progression.gd` | Squad, rivals, training, XP, history, migration and saving. |
| `scripts/main.gd` | Arena, flow, panels, feedback and audio. |
| `scripts/ui/battle_layout.gd` | Adaptive layout of the HUD, characters, controls and results. |
| `scripts/story_catalog.gd` | Chapters, routes, rival profiles, attributes, bosses and combat-based tracks. |
| `scripts/story_progression.gd` | Campaigns, chapter transitions, legacies, points, XP, retries and Story migration. |
| `scripts/ui/story_panel.gd` | Route, preview, improvements, campaign choice and legacy. |
| `scripts/ui/world_visuals.gd` | Registration of environments, reusable surfaces and decorative conditions. |
| `scripts/ui/world_backdrop.gd` | On-demand background, ambient objects and contrast; no game logic. |
| `data/ui_visual_manifest.json` | Asset IDs, atlas regions, nine segments, themes and props. |
| `scripts/ui/roster_panel.gd` | Selection and files generated from the catalog. |
| `scripts/fighter_view.gd` | Atlas, poses, anchors, orientation and visual variants. |
| `scripts/fighter_animation_set.gd` | Phased sequences, reactions, visual transformations and atlas cache. |
| `scripts/combat_fx.gd` | Impacts, dust, contrails, energy and brief camera movement. |
| `data/combat_fx.json` | Regions and duration of the eight transparent effects. |
| `scripts/fighter_identity.gd` | Shared identity, cosmetic inventory, migration and independent save. |
| `scripts/cosmetic_catalog.gd` | Categories, options, compatibility and requirements; canonical export JSON. |
| `scripts/ui/customization_panel.gd` | Visual creator and editor with draft, preview and confirmation. |
| `scripts/battle_identity.gd` | Historical name and appearance along with combat events. |
| `scripts/identity_api.gd` | Optional local API adapter, no auto-sync. |
| `scripts/arena_view.gd` | Background, lights and particles. |

The final customization regression passes **22.816 checks on 24 suites, without failures**, plus the **UI_SMOKE_PASS** walkthrough. Native, identity, and local service testing are detailed in [CUSTOMIZATION](../reports/PERSONALIZACION.md).

The tests use separate files; never the actual game. From this folder, with Godot installed:

```sh
BRASA_GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
"$BRASA_GODOT" --headless --path . --script res://tests/test_fighter_identity.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_identity_integration.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_identity_edges.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_customization_visuals.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_core.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_sprites.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_distinct_sprites.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_roster.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_mexican_roster.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_mexican_roster_ui.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_cat_roster.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_cat_roster_ui.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_cat_identity_migration.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_battle_layout.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_story_integration.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_story_progression.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_story_combat.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_story_campaign.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_story_panel.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_progression_v2.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_combat_v2.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_moves.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_move_presentation.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_move_clock.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_animation_sequences.gd -- --require-roster
"$BRASA_GODOT" --headless --path . --script res://tests/test_combat_fx.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_status_ko_presentation.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_campaign100.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_campaign100_integration.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_story_campaign_ui.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_story_chapter_integration.gd
"$BRASA_GODOT" --headless --path . --script res://tests/simulate_campaign100.gd
"$BRASA_GODOT" --headless --path . --script res://tests/simulate_mexican_roster.gd
"$BRASA_GODOT" --headless --path . --script res://tests/simulate_cat_roster.gd
"$BRASA_GODOT" --headless --path . -- --smoke-test
"$BRASA_GODOT" --headless --path . --script res://tests/simulate_balance.gd
"$BRASA_GODOT" --headless --path . --script res://tests/simulate_story.gd
```

`--smoke-test` tours roster, training, forced trial signing, combat, unique reward, summary, history, record, rematch, canceled/confirmed surrender and reload. Its save is in `work/ui_smoke_save_<sesión>.json`, outside the player's game. Also supports `--save-path=/ruta/absoluta/archivo.json`. Remove `--headless` to view it in the window.

The engine accepts an optional seed to reproduce errors without depending on the frame rate. The force signature options are intended for testing only; Normal games use catalog probability. Simulations and their report are included along with tests to remeasure the balance when modifying data.

The expansion to thirteen characters and its validation are in [reports/FAUNA-MEXICANA.md](../reports/FAUNA-MEXICANA.md), and its balance is in [reports/MEXICAN_ROSTER_BALANCE.md](../reports/MEXICAN_ROSTER_BALANCE.md). The validation of the 100 encounters with the nine original characters is in [reports/CAMPANA-100.md](../reports/CAMPANA-100.md), with integration, migration, movement and capture tests.

The reports [VALIDATION](../reports/VALIDACION.md), [INTERFACE](../reports/INTERFAZ.md), [STORY](../reports/HISTORIA.md), [STORY_BALANCE](../reports/STORY_BALANCE.md) and [CHAPTER-2](../reports/CAPITULO-2.md) document previous deliveries; Its combat results precede the five-technique system. The art and its prompts are still documented in [CHARACTERS](../reports/PERSONAJES.md) and [assets/CAPITULO-2.md](../assets/CAPITULO-2.md).
