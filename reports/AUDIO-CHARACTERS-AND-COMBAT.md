# Audio: Characters and Combat — Current Code Audit

Date: 21 September 2026. Scope: engine reading, catalogues, presentation and reproduction; no generation, runtime changes, profile execution or extensive testing. **Profiles are proposed sound direction; rules and trigger points are made from the code.** This document complements the architecture and overall audio inventory of the main task.

The exported catalog was checked against the current SHA-256 from its eight sources: they all match. Contains **15 companions, 75 playable techniques, two boss bodies with ten own techniques and eleven boss encounters**. There are five techniques per identity; playable unlocks in levels 1, 1, 5, 12 and 20 and six talent options per companion. The attached JSON preserves the complete 85 definitions, talents, parameters, profiles, and references. [scripts/character_catalog.gd:5](../scripts/character_catalog.gd#L5) · [scripts/move_catalog.gd:5](../scripts/move_catalog.gd#L5)

Auditable data: characters-combat.json (`work/audio/audit/characters-combat.json`; not included). Catalog hash: `6f8007bd7059b142b166e630455449d180a7ceffb2c0ff2e0307799f1eea86e1`. There were no new matches executed or modified saves for this report.

## Physical identity and powers

The appearance can choose a body other than the playable archetype. The future sound selection should compose **visible body movement/material/voice** and **combat descriptor technique/signature/power**; never identify him by personal name. Ascua can arrive as character_id=mugo with its own story_boss_id/visual, and Véspera as sira. A replay preserves its historical identities and appearances, not the current ones in the inventory. [scripts/fighter_view.gd:144](../scripts/fighter_view.gd#L144) · [scripts/battle_identity.gd:6](../scripts/battle_identity.gd#L6) · [scripts/story_catalog.gd:220](../scripts/story_catalog.gd#L220)

The first nine records do not include `species`/`biography`; their species here come from the sprite documentation. **Duna is an armadillo, not a turtle**. The titles “jade”, “moon” or “mist” inspire timbre; they don't test a water mechanic, magic, or an additional weapon.

## Proposed CharacterAudioProfiles

Each profile retains a dry and close base. Sound weight is communicated by transient, material and movement, not by increasing volume according to level/statistics. Motifs and vocalizations are proposed to be produced, not existing files. A full song per character is not required.

### Nima (`nima`)

**Identity:** Desert lynx. **Movement:** Light and dry supports; feline short races, jumping and charging. **Attack/weight:** Hair brush and short air; third attempt accented only when it connects; Light/medium, no tanky bass. **Material:** Fur and body contact; soil grain in independent layer.

**Energy:** Sand as thematic texture; real slow in Signature. **Voice:** Short feline exhalations, middle register, without words. **Motif:** Three dry percussion accents.

**Actual Skill:** Three Step (`combo`): Every third attack does ×1.3 damage if it connects. **Signature:** Sand Kite: Accurate hit ×1.6 and rival speed −22% for 3 turns.

**Five techniques:** Quick strike (`nima_zarpazo`, quick); sand step (`nima_arena`, dash); dune jump (`nima_salto`, jump); Feline Stalking (`nima_acecho`, counter); Desert Comet (`nima_cometa`, charge).

**Sound signature:** Sand comet: own motif in anticipation of Signature; physical impact + strange accent on contact; separate slow if status_applied . **Transformation:** N/A: No active transformation registered. Signature's transform_* adds no new form or power.

Sources: [scripts/character_catalog.gd:19](../scripts/character_catalog.gd#L19) · [scripts/move_catalog.gd:43](../scripts/move_catalog.gd#L43) · [assets/sprites/PROMPTS.md:9](../assets/sprites/PROMPTS.md).

### Luma (`luma`)

**Identity:** Axolotl. **Movement:** Smooth supports, fluid movement and contained jumping. **Attack/weight:** Soft palm with firm body; focus gesture clearly separated from damage; Half round. **Material:** Amphibious skin; avoid permanent splashing on dry ground.

**Energy:** Water/backwater as timbral color; real precision, weakening and healing. **Voice:** Soft breathing and short effort in the middle register. **Motif:** Two fluid notes and soft wood resonance.

**Actual Skill:** Learn from the River (`adapt`): Upon failure, gain 10 accuracy points for 2 turns. **Signature:** Moon Tide: True Strike ×1.6 and rival precision −15 points during 3 turns.

**Five techniques:** River palm (`luma_palma`, quick); Eye of the Backwater (`luma_enfoque`, technique); Contained Wave (`luma_ola`, heavy); Water Arc (`luma_arco`, jump); Protective haven (`luma_remanso`, guard).

**Sound Signature:** Moontide: own motif in anticipation of Signature; physical impact + strange accent on contact; separate accuracy_down if status_applied . **Transformation:** N/A: No active transformation registered. Signature's transform_* adds no new form or power.

Sources: [scripts/character_catalog.gd:30](../scripts/character_catalog.gd#L30) · [scripts/move_catalog.gd:112](../scripts/move_catalog.gd#L112) · [assets/sprites/PROMPTS.md:10](../assets/sprites/PROMPTS.md).

### Mugo (`mugo`)

**Identity:** Stone golem. **Movement:** Heavy support, slow withdrawal and friction loading start. **Attack/weight:** Dense stone strike, short mineral joint, localized gravel fall; Heavy, wide transient and controlled tail. **Material:** Stone/jade; no metal sword.

**Energy:** Mineral resonance; no fire ability or playable transformation. **Voice:** Low body resonance without dialogue or continuous roar. **Reason:** Slow stone pulse and low drum.

**Actual Skill:** Quarry Heart (`fortify`): Reduces the additional damage from critical hits received by 45%. **Signature:** Mountain Embrace: True Strike ×1.6 and opponent attack −20% for 3 turns.

**Five techniques:** Jade Knuckle (`mugo_nudillo`, quick); patient wall (`mugo_muro`, guard); Open the crack (`mugo_grieta`, heavy); Mountain Pass (`mugo_montana`, charge); Stone Echo (`mugo_eco`, counter).

**Sound signature:** Mountain hug: own motif in anticipation of Signature; physical impact + strange accent on contact; separate attack_down if status_applied . **Transformation:** N/A: No active transformation registered. Signature's transform_* adds no new form or power.

Sources: [scripts/character_catalog.gd:41](../scripts/character_catalog.gd#L41) · [scripts/move_catalog.gd:189](../scripts/move_catalog.gd#L189) · [assets/sprites/PROMPTS.md:11](../assets/sprites/PROMPTS.md).

### Sira (`sira`)

**Identity:** Duelist mantis. **Movement:** Precise dry supports; articulated dash and jump. **Attack/Weight:** Natural forearm short cut with chitin snap; Light and incisive; critical adds edge, not explosion. **Material:** Chitin and natural arm blade, not carried sword.

**Energy:** Crystal/obsidian as chime; real critical penetration. **Voice:** Minimal effort airy, no robotic voice. **Reason:** Short high notes on precise pulse.

**Actual Ability:** Perfect Rift (`precision`): Your criticals ignore the opponent's defense's 45%. **Signature:** Obsidian Flash: True Strike ×1.6 and rival defense −25% for 3 turns.

**Five techniques:** Jade needle (`sira_aguja`, quick); flush cut (`sira_corte`, dash); Break the glass (`sira_vidrio`, heavy); Crescent (`sira_media_luna`, jump); Replica of the blade (`sira_replica`, counter).

**Sound signature:** Obsidian flash: own motif in anticipation of Signature; physical impact + strange accent on contact; separate defense_down if status_applied . **Transformation:** N/A: No active transformation registered. Signature's transform_* adds no new form or power.

Sources: [scripts/character_catalog.gd:52](../scripts/character_catalog.gd#L52) · [scripts/move_catalog.gd:260](../scripts/move_catalog.gd#L260) · [assets/sprites/PERSONAJES-V3.md:9](../assets/sprites/PERSONAJES-V3.md).

### Iria (`iria`)

**Identity:** Botanical frog. **Movement:** Discreet wet supports; jump and rooted posture. **Attack/Weight:** Organic punch and blade friction; application of poison separate from the blow; Light/medium cushioned. **Material:** Skin/leaf; without attributing rain to each attack.

**Energy:** Poison and healing reduction; short vegetable texture without continuous bubbling. **Voice:** Short amphibian exhalation, medium-low register. **Motif:** Wooden seeds/percussions and two suspended notes.

**Actual Ability:** Secret Garden (`poison`): 35% on poison connection: 3 × Attack / 19 HP for 3 turns, up to 2 charges. **Signature:** Midnight Blossom: True Strike ×1.6 and opponent healing −40% for 4 turns.

**Five Techniques:** Blade Fist (`iria_hoja`, quick); bitter spore (`iria_espora`, technique); Mist Jump (`iria_bruma`, jump); Firm Roots (`iria_raices`, guard); Cutting sap (`iria_savia`, heavy).

**Sound signature:** Midnight flower: own motif in anticipation of Signature; physical impact + strange accent on contact; separate healing_down if status_applied . **Transformation:** N/A: No active transformation registered. Signature's transform_* adds no new form or power.

Sources: [scripts/character_catalog.gd:63](../scripts/character_catalog.gd#L63) · [scripts/move_catalog.gd:327](../scripts/move_catalog.gd#L327) · [assets/sprites/PERSONAJES-V3.md:10](../assets/sprites/PERSONAJES-V3.md).

### Duna (`duna`)

**Identity:** Guardian armadillo. **Movement:** Firm support, defensive collection, rolling/charging and braking. **Attack/weight:** Plates with matte blow and short touch, shield with differentiated resonance; Heavy/compact. **Material:** Armadillo plates; not turtle shell or metal anvil.

**Energy:** Periodic and slow shield; without invulnerability. **Voice:** Short low effort and restrained breathing. **Reason:** Two stable wood/stone pulses.

**Actual Skill:** Courtyard Wall (`shield`): Every 4 turn gains a shield of 12 HP that lasts up to 3 turns. **Signature:** Guardian's Seal: True Strike ×1.6 and rival speed −25% for 3 turns.

**Five techniques:** Plate hit (`duna_placa`, quick); closeshell(`duna_caparazon`, guard); Dune roll (`duna_rodar`, charge); Quarry hammer (`duna_cantera`, heavy); Sand return (`duna_retorno`, counter).

**Sound signature:** Guardian's seal: own reason in anticipation of Signature; physical impact + strange accent on contact; separate slow if status_applied . **Transformation:** N/A: No active transformation registered. Signature's transform_* adds no new form or power.

Sources: [scripts/character_catalog.gd:74](../scripts/character_catalog.gd#L74) · [scripts/move_catalog.gd:417](../scripts/move_catalog.gd#L417) · [assets/sprites/PERSONAJES-V3.md:11](../assets/sprites/PERSONAJES-V3.md).

### Kiro (`kiro`)

**Identity:** Wild boar. **Movement:** Powerful supports; hammer, ram and drop with weight. **Attack/weight:** Dense body and harsh lunging air; Heavy and rough, no gunshots or explosions. **Material:** Fur/body and fangs as identity, not new weapon.

**Energy:** Fury according to life lost; real burn only when applied. **Voice:** Boar snorts, short roar reserved for Firma. **Reason:** Severe percussion that narrows the pulse as the pressure increases.

**Actual Ability:** Last Ember (`berserk`): Its damage increases based on the life lost, up to an additional 40%. **Signature:** Furnace Roar: True Strike ×1.6 and burn 4 HP for 3 turns.

**Five techniques:** Fang Fist (`kiro_colmillo`, quick); Copper hammer (`kiro_martillo`, heavy); Red Ram (`kiro_ariete`, charge); Fan the ember (`kiro_brasa`, technique); Wild Boar Fall (`kiro_caida`, jump).

**Sound signature:** Roar of the oven: own motive in anticipation of Signature; physical impact + strange accent on contact; separate burn if status_applied . **Transformation:** N/A: No active transformation registered. Signature's transform_* adds no new form or power.

Sources: [scripts/character_catalog.gd:85](../scripts/character_catalog.gd#L85) · [scripts/move_catalog.gd:492](../scripts/move_catalog.gd#L492) · [assets/sprites/PERSONAJES-V3.md:12](../assets/sprites/PERSONAJES-V3.md).

### Neris (`neris`)

**Identity:** White Heron. **Movement:** Fine supports; running and flying/jumping with feather touch. **Attack/weight:** Fine stroke, wing air and smooth entry; Light/medium; legible landing without golem weight. **Material:** Feather and fine support; water only in magic texture or appropriate soil.

**Energy:** Comeback/healing and precision reduction; water as a motive, not a projectile. **Voice:** Very short air exhalation, avoid frequent squawking. **Reason:** Two notes of encouragement with ascending response when healing.

**Actual Ability:** Another Spring (`comeback`): Once per combat, dropping below 35% health heals one 16% of your maximum health. **Signature:** River Eclipse: True Strike ×1.6 and rival attack −22% during 3 turns.

**Five techniques:** Wing tip (`neris_ala`, quick); follow the flow (`neris_corriente`, dash); Serene Flight (`neris_vuelo`, jump); Lake Veil (`neris_velo`, technique); Feather Shelter (`neris_refugio`, guard).

**Sound signature:** Eclipse of the river: own motif in anticipation of Signature; physical impact + strange accent on contact; separate attack_down if status_applied . **Transformation:** N/A: No active transformation registered. Signature's transform_* adds no new form or power.

Sources: [scripts/character_catalog.gd:96](../scripts/character_catalog.gd#L96) · [scripts/move_catalog.gd:563](../scripts/move_catalog.gd#L563) · [assets/sprites/PERSONAJES-V3.md:13](../assets/sprites/PERSONAJES-V3.md).

### Taro (`taro`)

**Identity:** Badger. **Movement:** Stable low base, guard and retort with small advance. **Attack/weight:** Compact body punch, hair brush and dry response; Compact medium/heavy. **Material:** Fur and soil; brief bell only as motif, not metal armor.

**Energy:** Jade/bell as Signature; real bleeding without sound gore. **Voice:** Low register effort, very brief. **Reason:** Call and response on wood percussion.

**Actual Ability:** Jade Echo (`counter`): 24% respond to a hit received with a counterattack of ×0.45 damage. **Signature:** Cannon Bell: Accurate hit ×1.6 and bleed 4 HP for 3 turns.

**Five techniques:** Earth fist (`taro_puno`, quick); Badger Wait (`taro_espera`, counter); jade guard (`taro_jade`, guard); Fatigue Hit (`taro_cansancio`, heavy); Cross the threshold (`taro_umbral`, charge).

**Sound signature:** Cannon bell: own motif in anticipation of Signature; physical impact + strange accent on contact; separate bleed if status_applied . **Transformation:** N/A: No active transformation registered. Signature's transform_* adds no new form or power.

Sources: [scripts/character_catalog.gd:107](../scripts/character_catalog.gd#L107) · [scripts/move_catalog.gd:635](../scripts/move_catalog.gd#L635) · [assets/sprites/PERSONAJES-V3.md:14](../assets/sprites/PERSONAJES-V3.md).

### Balam (`balam`)

**Identity:** Jaguar. **Movement:** Silent stalk, charge with powerful release and jump. **Attack/weight:** Claw/paw and contained air, dense feline impact; Medium/heavy athletic. **Material:** Fur/paw, without sword or electricity.

**Energy:** Night as a timbre color; Real accuracy and reduced defense. **Voice:** Short jaguar exhale/grunt, do not roar with each blow. **Reason:** Spaced pulse with severe drop when releasing load.

**Actual Ability:** Look Between the Blades (`precision`): Your criticals ignore the 30% of the opponent's defense. **Signature:** Spotted Night: 1% per combat, one time: accurate hit ×1.65 and rival defense −20% during 3 target actions.

**Five techniques:** Contained Claw (`balam_garra`, quick); Jaguar Weight (`balam_roca`, heavy); Mount Rush (`balam_emboscada`, charge); Patient stalking (`balam_acecho`, technique); Speckled drop (`balam_salto`, jump).

**Sound signature:** Speckled night: own motive in anticipation of Signature; physical impact + strange accent on contact; separate defense_down if status_applied . **Transformation:** N/A: No active transformation registered. Signature's transform_* adds no new form or power.

Sources: [scripts/character_catalog.gd:118](../scripts/character_catalog.gd#L118) · [scripts/move_catalog.gd:858](../scripts/move_catalog.gd#L858).

### Tepa (`tepa`)

**Identity:** Teporingo. **Movement:** Very light supports, repeated takeoff and landing, cross runs. **Attack/weight:** Paw brush and fast air, no cartoonish hiss; Light, strong attacks conserve body size. **Material:** Short fur and separate granular soil.

**Energy:** Sun/dust as a reason; Real slow without automatic fire magic. **Voice:** Small airy effort, not childish voice or high-pitched squeak. **Motif:** Four soft wood accents.

**Actual Skill:** Four Jumps (`combo`): Every fourth attempted attack does ×1.3 damage if it connects. **Signature:** Sun Leap: 1% per combat, one time: accurate hit ×1.55 and rival speed −22% during 3 target actions.

**Five techniques:** Quick paw (`tepa_patita`, quick); Zacatón jump (`tepa_zacaton`, jump); cross dash (`tepa_carrera`, dash); Volcano Jump (`tepa_volcan`, jump); Trail dust (`tepa_polvo`, technique).

**Sound signature:** Salto del sol: own motif in anticipation of Signature; physical impact + strange accent on contact; separate slow if status_applied . **Transformation:** N/A: No active transformation registered. Signature's transform_* adds no new form or power.

Sources: [scripts/character_catalog.gd:178](../scripts/character_catalog.gd#L178) · [scripts/move_catalog.gd:934](../scripts/move_catalog.gd#L934).

### Xuna (`xuna`)

**Identity:** Xoloitzcuintle. **Movement:** Firm guard, moderate heavy step and contained charge. **Attack/weight:** Dry, close body contact, stable breathing; Medium/compact resistant. **Material:** Skin and body contact; race does not imply stone armor.

**Energy:** Brasa persistent apply burn; Faro reduces healing, not self-healing. **Voice:** Serene canine breathing and short effort, without repetitive barking. **Reason:** Stable low pulse with small warm accent.

**Actual skill:** Serenity of the Path (`fortify`): Reduces the additional damage from criticals received by one 30%. **Signature:** Beacon of the way: 1% per combat, one time: accurate hit ×1.6 and opponent healing −35% during 4 target actions.

**Five techniques:** Serene Fang (`xuna_colmillo`, quick); Threshold Guard (`xuna_umbral`, guard); persistent Brasa (`xuna_brasa`, technique); stone step (`xuna_piedra`, heavy); Wake charge (`xuna_vigilia`, charge).

**Sound signature:** Lighthouse on the road: own reason in anticipation of Signature; physical impact + strange accent on contact; separate healing_down if status_applied . **Transformation:** N/A: No active transformation registered. Signature's transform_* adds no new form or power.

Sources: [scripts/character_catalog.gd:239](../scripts/character_catalog.gd#L239) · [scripts/move_catalog.gd:1498](../scripts/move_catalog.gd#L1498).

### Copal (`copal`)

**Identity:** Cacomixtle. **Movement:** Quick feints, dash, jump and wait before responding. **Attack/weight:** Light hair rub and short side whoosh; Light/medium stretch. **Material:** Fur and tail; do not sound each tail oscillation.

**Energy:** Shadow/moon as motif; reduction in actual precision and replica. **Voice:** Small, dry exhalation, not piercing squeak. **Reason:** Two asymmetrical accents and short answer.

**Actual ability:** Cross-branch response (`counter`): 20% to respond to a hit received with a counterattack of ×0.4 damage. **Signature:** Moon Round: 1% per combat, one time: accurate hit ×1.6 and rival precision −14 points during 3 target actions.

**Five techniques:** Ring feint (`copal_finta`, quick); Branch Step (`copal_rama`, dash); cacomixtle wait (`copal_espera`, counter); Restless Shadow (`copal_distraccion`, technique); Branch bypass (`copal_rodeo`, jump).

**Sound signature:** Round of the moon: own motif in anticipation of Signature; physical impact + strange accent on contact; separate accuracy_down if status_applied . **Transformation:** N/A: No active transformation registered. Signature's transform_* adds no new form or power.

Sources: [scripts/character_catalog.gd:299](../scripts/character_catalog.gd#L299) · [scripts/move_catalog.gd:1093](../scripts/move_catalog.gd#L1093).

### Ónix (`onix`)

**Identity:** Black domestic cat, yellow eyes. **Movement:** Very light steps, roof dash and agile jump. **Attack/weight:** Short leg, fine whoosh and third attempt with restrained accent; Light/fragile; heavy should not sound like Mugo. **Material:** Fur/paw; no undocumented rattle.

**Energy:** Shadow/midnight as doorbell; Real reduced rival accuracy. **Voice:** Short feline exhalation, optional reserved meow of result. **Reason:** Three very short notes with a dry finish.

**Actual Ability:** Three Steps of Shadow (`combo`): Every third attempted attack does ×1.22 damage if it connects. **Signature:** Yellow Midnight: 1% per combat, one time: accurate hit ×1.6 and rival precision −16 points during 3 target actions.

**Five techniques:** Shadow rubbing (`onix_roce`, quick); Eaves Dash (`onix_alero`, dash); Roof jump (`onix_tejadillo`, jump); Yellow flashing (`onix_parpadeo`, technique); Rooftop fall (`onix_azotea`, heavy).

**Sound Signature:** Yellow Midnight: own motif in anticipation of Signature; physical impact + strange accent on contact; separate accuracy_down if status_applied . **Transformation:** N/A: No active transformation registered. Signature's transform_* adds no new form or power.

Sources: [scripts/character_catalog.gd:360](../scripts/character_catalog.gd#L360) · [scripts/move_catalog.gd:1167](../scripts/move_catalog.gd#L1167).

### Bruma (`bruma`)

**Identity:** Gray domestic cat, greenish eyes. **Movement:** Serene support, listening/guarding and punctual response. **Attack/weight:** Firm leg and brief air of response; Balanced compact medium. **Material:** Fur/paw; no undocumented bell or cape.

**Energy:** Fog as a motif; Reduced attack and small actual guard healing. **Voice:** Soft feline breathing; short medium effort. **Reason:** Question-answer of two muffled notes.

**Actual Ability:** Silence Response (`counter`): 20% to respond to a hit received with a counterattack of ×0.42 damage. **Signature:** Fog Stillness: 1% per combat, one time: accurate hit ×1.6 and rival attack −20% during 3 target actions.

**Five techniques:** True touch (`bruma_tacto`, quick); Listen patient (`bruma_escucha`, counter); Weight of Calm (`bruma_peso`, heavy); Clew Guard (`bruma_ovillo`, guard); Fog pass (`bruma_niebla`, technique).

**Sound Signature:** Stillness of fog: own motive in anticipation of Signature; physical impact + strange accent on contact; separate attack_down if status_applied . **Transformation:** N/A: No active transformation registered. Signature's transform_* adds no new form or power.

Sources: [scripts/character_catalog.gd:423](../scripts/character_catalog.gd#L423) · [scripts/move_catalog.gd:1245](../scripts/move_catalog.gd#L1245).

### Ascua (`ascua` boss)

**Identity:** Guardian with volcanic armor and ignited core. **Movement:** Heavy mineral step, braking charge and crater jump. **Attack/weight:** Hot stone/matte copper plus localized spark, not explosion; Very heavy but controlled mix. **Material:** Volcanic armor, mineral joints and core; ember layer only where it appears.

**Energy:** Burn on Brazier Charge; two real phases; ember_core visual. **Voice:** Severe body resonance and brief non-verbal effort. **Motif:** Serious mineral pulse with three-note lantern motif.

**Actual Skill:** Lantern Core (`phase_shift`): Above health 60%: Normal combat. To 60%: attack +8%. To 30%: keep that attack and speed +15%. No healing or invulnerability. **Signature:** The night on: 1% per combat, only once: accurate hit ×1.7 and rival attack −18% during 3 actions of the target.

**Five techniques:** Copper Claw (`ascua_cobre`, quick); Fist of the Forge (`ascua_forja`, heavy); Brazier charge (`ascua_brasero`, charge); Closed Obsidian (`ascua_obsidiana`, guard); Crater Strike (`ascua_crater`, jump).

**Sound signature:** The night on: own motif in anticipation of Signature; physical impact + strange accent on contact; separate attack_down if status_applied . **Transformation:** Mineral/energy sequence .72 s; core bed to visual end (maximum 8 s), separate phases and shape.

Sources: [scripts/story_catalog.gd:220](../scripts/story_catalog.gd#L220) · [scripts/move_catalog.gd:709](../scripts/move_catalog.gd#L709).

### Véspera (`vespera` boss)

**Identity:** Moon moth. **Movement:** Fine steps, fast movement, orbital jump and evasive waiting. **Attack/weight:** Wing air/fine powder, defined fast contact; Light/medium; not make its impact weak by having wings. **Material:** Wing/light chitin; no heavy metal or permanent levitation.

**Power:** Eclipse reduces precision; two real phases, with no recorded transformed form. **Voice:** Mild mid-register breath, not permanent mosquito humming. **Motif:** Short musical circular figure with wind pulse.

**Actual Skill:** Gale Dance (`phase_shift`): Above health 60%: Normal combat. To 60%: speed +10%. To 30%: keep that speed and attack +8%. No healing or invulnerability. **Signature:** Eclipse Dust: 1% per combat, one time: accurate hit ×1.65 and rival precision −12 points during 4 own actions; resistance can shorten its duration.

**Five techniques:** Moondust Touch (`vespera_polvo`, quick); Gale Pass (`vespera_vendaval`, dash); lunar orbit (`vespera_orbita`, jump); Eclipse Veil (`vespera_eclipse`, technique); Moon Wait (`vespera_luna`, counter).

**Sound signature:** Eclipse dust: own motive in anticipation of Signature; physical impact + strange accent on contact; separate accuracy_down if status_applied . **Transformation:** N/A: No active transformation registered. Signature's transform_* adds no new form or power.

Sources: [scripts/story_catalog.gd:220](../scripts/story_catalog.gd#L220) · [scripts/move_catalog.gd:787](../scripts/move_catalog.gd#L787).

## Event map and synchronization

Automatic attacks have setup, movement, and recovery; The engine decides the result and the client presents. `move_started.move` contains the solved technique (includes improvements), `impact_delay=windup+travel` and `duration` its total duration. Use those values ​​per event, not highlight them from the current catalog. modern `attack` carries move_id; the legacy delay of .21 s from Main only applies to events without that ID. [scripts/combat_engine.gd:241](../scripts/combat_engine.gd#L241) · [scripts/main.gd:1010](../scripts/main.gd#L1010)

| Family | Windup / travel / recovery base, seconds | Contact and treatment |
|---|---|---|

| `charge` | 0.40 / 0.15 / 0.34 | Impact conditional on the result; base values, technique/improvements can change them |

| `counter` | 0.10 / 0.00 / 0.18 | Stance, not blow; base values, technique/improvements can change them |

| `dash` | 0.05 / 0.13 / 0.17 | Impact conditional on the result; base values, technique/improvements can change them |

| `guard` | 0.12 / 0.00 / 0.22 | Stance, not blow; base values, technique/improvements can change them |

| `heavy` | 0.36 / 0.11 / 0.30 | Impact conditional on the result; base values, technique/improvements can change them |

| `jump` | 0.15 / 0.30 / 0.23 | Impact conditional on the result; base values, technique/improvements can change them |

| `quick` | 0.07 / 0.08 / 0.13 | Impact conditional on the result; base values, technique/improvements can change them |

| `technique` | 0.18 / 0.12 / 0.21 | Impact conditional on the result; base values, technique/improvements can change them |

| Signature | .34 / .16 / .35 | Contact +.50; once it was armed |

| Automatic replica | .05 / .08 / .15 | Contact +.13, guaranteed and non-critical |

Source: [scripts/move_catalog.gd:20](../scripts/move_catalog.gd#L20) and [scripts/combat_engine.gd:425](../scripts/combat_engine.gd#L425). Priority and speed modify the cadence; They do not convert one technique into another nor justify altering tone of voice.

- **`battle.enter`** — `presentation lifecycle / validated snapshot`. When loading actors/sand; Don't wait for the first hit. Intro/ambiance and musical bed; Separate confirm UI. **Limit:** There is no engine battle_started event; local boot and Replay.restart are integration points. [scripts/main.gd:886](../scripts/main.gd#L886)

- **`move.anticipation`** — `move_started`. event.time; move.windup/travel/recovery resolved. Body, preparation and power if applicable; Identifiable signature before contact. **Limit:** Save move per action/ID. Same move_id is repeated: do not deduplicate by ID only. [scripts/combat_engine.gd:272](../scripts/combat_engine.gd#L272)

- **`move.foot`** — `presentation marker left_foot_impact/right_foot_impact`. phase.start + phase.duration*at. Body support + floor; choose variant without combat RNG. **Limit:** The same landing page can have a footer/debris marker: one physical entry, limited layers. [scripts/move_visual_profile.gd:14](../scripts/move_visual_profile.gd#L14)

- **`move.charge`** — `marker charge_start / attached_fx_start`. Home windup; attached_fx to 25% of the windup. Short preparation, possible energy bed; leave in travel/terminal/cancellation. **Limit:** Heavy also uses charge_start per presentation; It does not imply new loading mechanics or manual control. [scripts/move_visual_profile.gd:25](../scripts/move_visual_profile.gd#L25)

- **`move.dash_slide`** — `marker slide_start/dash_start/slide_end`. travel 0; braking recovery .18. Air/body and ground friction, short tail. **Limit:** Charge/Signature include dash visual; Do not count them as a second technique. [scripts/move_visual_profile.gd:31](../scripts/move_visual_profile.gd#L31)

- **`move.jump`** — `marker jump_takeoff/landing`. Takeoff windup .60; landing recovery .40. Takeoff, short air and landing by weight/ground. **Limit:** Attack hit comes before attack; landing doesn't hurt. No mechanical failed landing. [scripts/move_visual_profile.gd:41](../scripts/move_visual_profile.gd#L41)

- **`combat.contact`** — `attack result=hit`. event.time = start + impact_delay. Exit whoosh + target physical/material hit; selective voice. **Limit:** Do not use fixed delay .21 s in modern attacks or replay anticipation. [scripts/combat_engine.gd:401](../scripts/combat_engine.gd#L401)

- **`combat.miss`** — `attack result=miss`. event.time. Whoosh without hit or voice of harm. **Limit:** Do not confuse precision failure with dodging; today Main uses the same tone. [scripts/combat_rules.gd:33](../scripts/combat_rules.gd#L33)

- **`combat.dodge`** — `attack result=dodge`. event.time. Body avoidance and passing whoosh; without hit. **Limit:** Real probability already resolved; not another audio evasion roll. [scripts/combat_rules.gd:33](../scripts/combat_rules.gd#L33)

- **`combat.critical`** — `attack result=critical`. Contact, along with the visual hit-stop. Base hit + short critical accent with priority. **Limit:** Does not double base hit or invent critical in Signature/counter. The audio queue continues during hit-stop. [scripts/fighter_animation_set.gd:105](../scripts/fighter_animation_set.gd#L105)

- **`combat.guard_enter`** — `defensive_stance`. Move guard/counter resolution (windup, travel=0). Discreet protective posture/support. **Limit:** No offensive hit. Guard/counter may still fail as a subsequent response; no parry guaranteed. [scripts/combat_engine.gd:328](../scripts/combat_engine.gd#L328)

- **`combat.guard_contact`** — `attack con postura defensiva vigente del objetivo`. Same contact; relate defensive_stance/stance_expired by side. Impact cushioning matte layer; maintain audible damage. **Limit:** No result=block or perfect block event. attack.absorbed only measures shield, NOT guard reduction. [scripts/combat_engine.gd:516](../scripts/combat_engine.gd#L516)

- **`combat.shield`** — `shield / status_applied(effect=shield) / attack.absorbed>0`. Entry upon granting; absorption on contact. A proportional shield input and short response, no false pain at zero damage. **Limit:** Grant casts ability+status_applied+shield: group. No explicit shield_break; do not infer breakage without evidence. [scripts/combat_engine.gd:479](../scripts/combat_engine.gd#L479)

- **`combat.counter`** — `move_started counter=true → attack counter=true,result=hit`. Scheduled reaction .05 windup + .08 travel = .13 s. Replica preparation and precise contact; response accent. **Limit:** No result=counter. Counter stance without damage is preparation; Guaranteed subsequent replication without critical or replica chain. [scripts/combat_engine.gd:425](../scripts/combat_engine.gd#L425)

- **`combat.ability`** — `ability (combo/adapt/fortify/precision/poison/shield/comeback/counter/stance/phase_shift/stun)`. Depending on the event, sometimes before attack or heal/status. Accent of identity grouped with material action. **Limit:** Berserk uses continuous modifier/attack text, not new event per tick. Do not emit audio for each reading of the status. [scripts/combat_engine.gd:485](../scripts/combat_engine.gd#L485)

- **`combat.status_apply`** — `status_applied`. Confirmed application only. Short entry of poison, ember, debuff or buff. **Limit:** Do not ring because a technique can apply it. source may differ from side/target. [scripts/combat_engine.gd:446](../scripts/combat_engine.gd#L446)

- **`combat.status_resist`** — `status_resisted / status_applied.turns_resisted`. A base roll prevented by reduced resistance/duration. Faint and distinguishable response, without great blocking. **Limit:** Absence of state does not test resistance: the base roll may fail. [scripts/combat_engine.gd:455](../scripts/combat_engine.gd#L455)

- **`combat.status_tick`** — `status_tick poison/burn/bleed`. Initiation of affected own action; no wall loop. Brief status pulse, selective damage/vowel; KO if target_hp<=0. **Limit:** DoT pierces shield/guard; do not attack or phantom punch. simultaneous ticks possible. [scripts/combat_engine.gd:500](../scripts/combat_engine.gd#L500)

- **`combat.heal`** — `heal amount>0`. Confirmed event. Short organic/clean promotion, no hit. **Limit:** Do not announce positive healing if amount=0; avoid duplicating ability comeback and heal. [scripts/combat_engine.gd:490](../scripts/combat_engine.gd#L490)

- **`combat.status_end`** — `status_expired / stance_expired`. Confirmed event. Normally silence; soft exit only if there was persistent bed. **Limit:** No hit or reward; clean loops from the corresponding state. [scripts/combat_engine.gd:122](../scripts/combat_engine.gd#L122)

- **`reaction.body`** — `FighterAnimationSet.reaction_for + FighterView.play_reaction`. Immediate contact; Animation may be deferred upon completion of outgoing attack. Voice cuts to harm; drop/friction to actual reaction marker. **Limit:** KO/miss/dodge take priority. Missing reaction marker channel for fall/getup: do not follow only attack time. [scripts/fighter_view.gd:629](../scripts/fighter_view.gd#L629)

- **`reaction.knockdown_ko`** — `Reacción visual knockdown/ko; target_hp<=0 / finished`. Knockdown .92 s; KO .66 s; grounded is last stretch. Final blow/fall/support; KO closing different from an ordinary hit. **Limit:** No new stun status: Signature knockdown is presentation. No public body-ground marker yet. [scripts/fighter_animation_set.gd:41](../scripts/fighter_animation_set.gd#L41)

- **`fighter.low_hp`** — `Snapshot/event HP ratio + FighterView health state`. Crossing the threshold, not every frame. Optional closely spaced breathing; without depending on audio to inform. **Limit:** Pose low_health <.28; no semantic event low_health. Skills Neris .35, phases .60/.30 are other thresholds. [scripts/fighter_view.gd:609](../scripts/fighter_view.gd#L609)

- **`boss.phase`** — `ability ability_id=phase_shift,phase_index`. 0 at startup; 1/2 after crossing .60/.30 alive. Musical change and power resonance to the new index. **Limit:** If a blow jumps both thresholds, only the final phase is reached; do not reproduce skipped phase. [scripts/combat_engine.gd:575](../scripts/combat_engine.gd#L575)

- **`fighter.form`** — `play_transformation ember_core aceptada, Ascua visible`. Delayed visual input if attacking; clip .72, lifetime8. Preparation→core→peak→stable; output when finishing shape/change scene. **Limit:** Ascua only. Do not change stats. Signature and phase events can request it while already active: do not restart loop/intro. [scripts/fighter_view.gd:678](../scripts/fighter_view.gd#L678)

- **`combat.signature`** — `move_started.signature / signature / attack.signature`. Anticipation on move_started, accent on contact +.50. Rare character motif; who shoots must have priority. **Limit:** signature and attack are two records of the same hit: one sound package, not two complete Signatures. 1%/fighter; may die sooner. [scripts/combat_engine.gd:257](../scripts/combat_engine.gd#L257)

- **`combat.finished`** — `finished reason normal/timeout/surrender`. Authoritative terminal; local result arrives after .30 s of presentation unless surrender. Win/lose closure from the viewer's perspective; stop charges/voice/combat loops. **Limit:** Surrender and timeout can have HP>0: do not invent fatal impact. Saved prize is not repeated when listening to replay. [scripts/main.gd:1161](../scripts/main.gd#L1161)

## What exists and what is missing to synchronize it well

**Available movement markers:** left/right support, takeoff, landing, glide start/end, step back, charge, sticky FX, dash, hit continuation, and end recovery. They are pure metadata calculated on the phases. `sound_event` exists in MoveVisualProfile, but there is no audio consumer. CombatFX retains its own cursor, age and deduplication; **do not connect audio to `_draw`, particle number, or its debug history**: reduced_motion skips those FXs and their markers. Audio must share definitions and maintain its own life cycle. [scripts/move_visual_profile.gd:7](../scripts/move_visual_profile.gd#L7) · [scripts/move_visual_profile.gd:78](../scripts/move_visual_profile.gd#L78) · [scripts/combat_fx.gd:227](../scripts/combat_fx.gd#L227)

**Reactions:** light .28 s, body .36, heavy .48, critical .55, knockback .60, knockdown .92, getup .48, KO .66 and victory .62. Head/low/airborne/guard/status/stagger are also configurable display variants, not damage zones or new rules. A hit during a salient attack retains its timing and differs the reaction pose; KO interrupts her. Fall→ground→rise markers are missing from the reaction actually shown: calculating them only from `attack.time` would sound before the delayed fall. [scripts/fighter_animation_set.gd:29](../scripts/fighter_animation_set.gd#L29) · [scripts/fighter_view.gd:629](../scripts/fighter_view.gd#L629)

**Guard, shield and counterattack:** guard reduces direct damage; a shield absorbs HP and declares it in `absorbed`. Neither one guarantees immunity, nor is there `result=block`, parry, perfect block or defense input window. The counter of the technique list prepares a posture without damage; the subsequent automatic replica issues its own preparation and contact. Signature's takedowns are animation, not mechanical stuns; `stun` is supported by the engine but no base technique/signature from the audited catalog applies it. [scripts/combat_engine.gd:511](../scripts/combat_engine.gd#L511) · [scripts/combat_engine.gd:434](../scripts/combat_engine.gd#L434) · [scripts/combat_engine.gd:244](../scripts/combat_engine.gd#L244)

**States/particles:** distinguish heal, poison, burn, bleed, shield and debuffs, without voicing each speck. DoT occurs at the start of actions and passes through guard/shield; can end a battle. Impact powder/stone_debris is emitted today upon impact, not a body marker touching the ground; Do not use it as a drop landing test. There is no physical collision or engine surface table: the ground material is presentation context by sand. [scripts/combat_engine.gd:500](../scripts/combat_engine.gd#L500) · [scripts/combat_fx.gd:203](../scripts/combat_fx.gd#L203) · [scripts/combat_fx.gd:274](../scripts/combat_fx.gd#L274)

## Signature, transformation and bosses

**Signature:** Bernoulli of 1% by combatant upon initiation; shift chosen between 2–5, maximum consumption once. It may not be executed if it falls earlier. Guaranteed hit, no additional crit, multiplier allowed 1.4–1.8 and true status; resistance can shorten duration. Anticipation from `move_started.signature`; contact from `signature` + `attack.signature` grouped together. The internal option force_signature is only for fixtures, it never changes the published probability. [scripts/balance.gd:19](../scripts/balance.gd#L19) · [scripts/combat_engine.gd:61](../scripts/combat_engine.gd#L61) · [scripts/combat_rules.gd:25](../scripts/combat_rules.gd#L25)

**Only active form:** Ascua `ember_core`, input .72 s and maximum visual life 8 s; `visual_only=true`, without modifiers or new techniques. Main/Replay is requested in phase>0 or Signature; if the actor is attacking, the entry is deferred to idle. Your life timer runs from the request. A repeat request while active returns true, but does not reset form: the audio should not repeat the entire upload. Notifications/status of effective, stable input and output are required to avoid loop leakage or mismatch with a delayed input. Do not rewrite the clock or the motor. [scripts/fighter_animation_set.gd:47](../scripts/fighter_animation_set.gd#L47) · [scripts/fighter_view.gd:678](../scripts/fighter_view.gd#L678) · [scripts/fighter_view.gd:413](../scripts/fighter_view.gd#L413)

**Proposed sequence of Ascua:** mineral/body joint → warm pulse → contained rising resonance → core dry peak → short and stable ember bed → soft shutdown. An attack during that form retains its base and may add a light layer of core. No layer should announce extra damage by visual form. For the other 16 bodies, the transform_start/peak/transformed_idle poses within Signature are their premium emote; They do not justify a transformation loop or a new state of power.

**True phases:** Ascua: Brasa serene (>60%); Furnace Live (≤60%, attack +8%); Last ember (≤30%, preserves +8% and speed +15%). Véspera: Moon breeze; Gale Wings (≤60%, speed +10%); Eye of the Storm (≤30%, conserves speed and attack +8%). None are cured or become invulnerable. Phase 0 is announced at startup; only the new index reached is output and no phase is announced after HP≤0. Véspera has game phases, **no visual form recorded**. Transition audio does apply; not a complete body transformation. [scripts/story_catalog.gd:237](../scripts/story_catalog.gd#L237) · [scripts/combat_engine.gd:575](../scripts/combat_engine.gd#L575)

| global meeting | Identity/title | audited power | Background |
|---|---|---|---|

| 8 | Ascua | Lantern core (`phase_shift`) | arena-faroles-v2.png |

| 16 | Véspera | Gale Dance (`phase_shift`) | arena-tormenta-v3.png |

| 20 | Taro Jade Oath | Jade Echo (`counter`) | arena-faroles-v2.png |

| 30 | Iria · Garden of echoes | Secret Garden (`poison`) | arena-faroles-v2.png |

| 40 | Luma · The nine paths | Learn from the river (`adapt`) | arena-tormenta-v3.png |

| 50 | Ascua · Heart of the Solstice | Lantern core (`phase_shift`) | arena-faroles-v2.png |

| 60 | Duna · Strength of Return | Courtyard wall (`shield`) | arena-tormenta-v3.png |

| 70 | Kiro Lightning Roar | Last Ember (`berserk`) | arena-tormenta-v3.png |

| 80 | Neris · Circle of the teachers | Another spring (`comeback`) | arena-faroles-v2.png |

| 90 | Sira · Edge of the stars | Perfect Crack (`precision`) | arena-tormenta-v3.png |

| 100 | Véspera · The last eclipse | Gale Dance (`phase_shift`) | arena-tormenta-v3.png |

20/30/40/60/70/80/90 bosses reuse their playable identity with declared profile and complete techniques; do not invent phases for them. 50/100 milestones reuse Ascua/Véspera with higher stats and improved techniques; they merit a milestone musical intro/closing and a variation of the motif, not eleven foreign libraries. [scripts/story_catalog.gd:220](../scripts/story_catalog.gd#L220) · [scripts/campaign_config.gd:48](../scripts/campaign_config.gd#L48)

## Live, local, online and replay

**Local League/Story Mode:** Main advances engine with delta and dispatches events; a combat modal pause engine, actors and FX. Pace ×2 uses Engine.time_scale=2. Hits use age `combat.elapsed-event.time`. The audio needs a session clock and must discard already expired transients in catch-up. Hit-stop freezes presentation only; let the tail sound. Normalize music/voice pitch separately from the interval between actions. [scripts/main.gd:936](../scripts/main.gd#L936) · [scripts/main.gd:1218](../scripts/main.gd#L1218)

**Asynchronous online:** the server simulates everything before challenging; saves events ordered with `event_seq`, snapshot, engine/catalog version and result. OnlinePanel opens **the same BattleReplayPanel**, not a new fight in Main. A record can be viewed as defender: win/loss should use viewing_side, not assume player. Neither hearing nor repeating gives XP. [backend/src/game/battles.js:62](../backend/src/game/battles.js#L62) · [backend/src/game/battles.js:68](../backend/src/game/battles.js#L68) · [scripts/ui/online_panel.gd:840](../scripts/ui/online_panel.gd#L840)

**Replay:** time and cursor ordered; pause, restart, log change and shutdown should stop/clear your audio. The proposed key is battle_id + replay generation + event_seq (online) or array index (local) + side + marker. `time` only is not unique: DoT/counter/Signature can share time. Never write audio IDs to the log or regenerate combat. Invalid/legacy snapshots without events do not get fabricated audio. [scripts/ui/battle_replay_panel.gd:208](../scripts/ui/battle_replay_panel.gd#L208) · [scripts/ui/battle_replay_panel.gd:178](../scripts/ui/battle_replay_panel.gd#L178) · [scripts/battle_identity.gd:23](../scripts/battle_identity.gd#L23)

## Existing audio findings relevant to combat

- **REPLACE** — Main synthesizes 9 mono tones: hit,critical,dodge,upgrade,start,win,lose,ability,signature; 5 AudioStreamPlayers at -10dB. [scripts/main.gd:1763](../scripts/main.gd#L1763)

- **REWORK** — Signature contact currently calls the same .75s tone in both signature and attack handlers, normally overlapping; ability+heal/shield can similarly stack. [scripts/main.gd:1077](../scripts/main.gd#L1077) · [scripts/main.gd:1010](../scripts/main.gd#L1010) · [scripts/main.gd:1045](../scripts/main.gd#L1045)

- **MISSING** — ReplayPanel does not play audio. Online battle display is this same ReplayPanel after server simulation; no direct online Main combat audio path. [scripts/ui/battle_replay_panel.gd:224](../scripts/ui/battle_replay_panel.gd#L224) · [scripts/ui/online_panel.gd:840](../scripts/ui/online_panel.gd#L840)

- **KEEP** — Immutable recorded descriptors/events and shared pure move markers are suitable semantic inputs; sound_event metadata exists but is not consumed. [scripts/battle_identity.gd:23](../scripts/battle_identity.gd#L23) · [scripts/move_visual_profile.gd:52](../scripts/move_visual_profile.gd#L52)

When replacing tones, group Signature + Impact, Skill + Shield, and Skill + Heal into controlled packages; do not chain a long file for each event. Maintain separation whoosh/result: Main today plays dodge also in miss. The effects should not depend exclusively on reduced_motion or music volume. The complete bus/UI/configuration inventory belongs to the main task architecture document.

## Recommended vertical test: Ascua + Lantern Court

**A specific identity: Ascua, boss not selectable. An arena: Patio de Lanterns**, `last_lantern`, encounter 8, background `res://assets/arena-faroles-v2.png`. Only body with registered active transformation; Five complete techniques include quick/heavy/charge/jump/guard, burn, phases, signature and charge with dash/slide. Mineral identity and core share vocabulary with the lantern environment. Do not introduce Mugo as “transformable” to artificially comply with the example. If the target is restricted to a selectable, the actual transformation is left out: none of the 15 have it.

Five techniques of the test: Copper Claw (quick), Forge Fist (heavy), Brazier Charge (charge + possible burn), Closed Obsidian (guard) and Crater Strike (jump). The rival receives the shared contact/reaction packet; it does not require producing a second sound identity.

**Coverage:** confirmation/entry; patio atmosphere and music; body/feet; quick/heavy/charge; dash and slide scrolling within loading; jump and landing; contact/miss/dodge/critical; guard; damage/knockdown/KO; two phases; visual form; Signature; victory/defeat. **A/N for Ascua:** standalone dash technique, counterattack, parry/perfect block, healing, HP shield, and new transformed attacks. There is also no knockdown that mechanically prevents actions. Do not generate assets to fake them.

**Proposed sand, pending global map:** Exterior stone with fine dust and distant lantern embers; contained night air; short open reflection. Artistic inference of the setting, not existing physical attribute. Music with a mineral pulse and a common warm motif; increase one layer per phase, short Signature/KO duck and boss closure. Do not incorporate public, machinery or water by inertia.

**Post validation:** a natural session with fixed seed and real events for general pacing; rare branches through explicit fixtures/replays of the same kit. Signature, critical, dodge and both outcomes are not guaranteed together in a fight; use internal test controls without touching normal 1%. Check ×1/×2, pause, shutdown mid-load, catch-up/restart, reduced_motion, local and online replay. Listen for separate contact and landing; never a blow at miss, nor a fatal blow invented when surrendering/timeout. This audit did not run those tests or generate audio.

**Exit criterion before the rest of the squad:** identify quick/heavy/Signature and hit/miss without looking; guard other than shield; feet and friction in its phase; transformation aligned to its actual input; final KO; pauses without orphan loops; no new reward for replay. Then extend profiles without changing rules or historical records.

## Complete P0/P1 backlog (not generated)

The JSON includes **118 briefs and 416 requested variants**: shared foley/contacts, identity of the 17 bodies, Signature of each one, strong preparation when your kit has it, actual states and form/phases of Ascua/Véspera. Each entry sets usage, duration, one-shot/loop, material, environment, dryness, intensity, tonal element, variations, timing, exclusions and prompt in English. They are pending, not deliverables already produced. Backlog extracted (`work/audio/audit/characters-combat-backlog.json`; not included).

The Audio Bible of the main task concretizes the Faroles soil as compact earth/terracotta and the initial production of transformation as a brief gesture and queue, without a permanent bed. Those decisions take precedence over the preliminary surface/loop options described in the audit. The diagnosis of the nine tones corresponds to the snapshot prior to the integration of AudioDirector; the code is integrated later, into a separate task.
