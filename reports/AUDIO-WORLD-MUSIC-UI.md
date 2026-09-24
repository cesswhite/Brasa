# Brasa — world, music and interface audit

Read-only audit performed on 21 September 2026, before generating audio. The cue names, BPMs, layers and parameters that follow are **proposals**, not existing assets or listening results. The general direction and the first production cut are set by `AUDIO-BIBLE.md`; This report specifies their real places and actions.

The complete inventory, with 27 sources and their SHA-256, map of 11 chapters, integration points and generation prompts, is in `../../../work/audio/audit/world-ui.json`. No game was opened, no browser was used, and no audio was generated during this audit.

## 1. What exists now

`main.gd:1763` synthesizes nine sine and second harmonic tones in memory: hit, critical, dodge, upgrade, start, win, lose, ability and signature. They are mono WAV of 22.050 Hz and 16 bits, 0,11 to 0,75 s. Five `AudioStreamPlayer` to −10 dB play the first free voice, per Master; If all of them are occupied, the new sound is discarded. There are no variations or priorities. `_play_sound`, line 1788, also omits headless sound.

The search for sources found no music, environments or WAV/OGG/MP3/FLAC/Opus files in `assets`, nor other players or a bus layout. Online, Replay, and UI components do not play audio. Settings only changes `sound_enabled`: prevents future calls, does not stop already audible queues and does not persist the value. The reduced motion preference is saved, but it is another function (`main.gd:1223–1240`).

| Decision | Elements |
| --- | --- |
| KEEP | Combat times/events; transaction results; user signals; identity and appearance; Replay clock; generations and idempotence Online. |
| REWORK | The same `start` to choose a partner, start a chapter and fight; `upgrade` to train, talents, techniques, respec, appearance and activate sound; politics of voices and silence. |
| REPLACE | Ring of the provisional nine tones. Preserving its useful semantic points does not require preserving its beeps. |
| MISSING | Music, Ambience, Surfaces, UI Hierarchy and Rewards, Replay/Online Parity, Central Director, Mixing, and Persistent Controls. |

The firm reproduces the same tone today in the announcement (`main.gd:1087`) and in the impact (`1043`). The new direction must distinguish anticipation and contact, with a single reproduction of each gesture; Do not repeat a complete release twice.

## 2. Real and material places

The final seven illustrations and their code selection were visually inspected. The language is warm, tangible paint: stitched leather, fabric, wood, muted bronze, stone, earth, amber lanterns and deep petrol blue. The music must leave the same air as the visual composition. You don't need interface electronics, trailer fanfare, or a continuous fire cape.

| Place | Visible evidence | Proposed sound translation |
| --- | --- | --- |
| Lantern Arena | Orange circular compact earth/terracotta patio; stone borders, adobe city, awnings, pennants, palms, moon and distant water. | Dry, granular contact, night air, occasional fabric. Without stadium or invented applause. |
| Storm Arena | Wet slabs, mountain arches and temples, visible lake and waterfalls, moonlit clouds and lanterns. | Firm stone with minimal humidity, distant water and open air. No mud, deep splashes, continuous rain or automatic thunder. |
| Journey Route | Stone path/terrace between mountains, side trees, banners and distant waterfalls at sunset. | Valley air and distant water, theme of calm march. Trees do not create a new forest arena. |
| Storm/Late Route | Ruins, roots, wet ground and mountain fog; Later chapters reuse that paint with dye. | Suspended variation of the same trip. Do not produce another biome for the title of each encounter. |
| Workshop / Techniques / Creation | Sheltered training yard, leather bags, wooden benches, fabrics and lanterns. | Dull rope and fabric/wood feel. You don't see a forge in operation: no hammers or ambient machinery. |
| Shelter / Companions / Menu | Tents, earthy ground, lanterns and kitchen embers next to a kettle. | Calm air, cloth and small fire, not roar of fire. |
| Legacy/Story Mode | Stone arches, fabrics, chest and opening to the outside. | Silence of a ventilated room, sober music. No haunted cave, voices or choir. |

Decorative items appear based on the player's actual status. Do not trigger sound every time you rebuild a lantern, medal, blindfold, or brazier. The shelter's ember loop is justified by its painting; An unlocked prop does not by itself require a new emitter.

### Chapters and bosses

The authoritative source is `campaign_config.gd:15` (`CHAPTERS`), not the narrative quest name:

| Chapter | Encounters | combat background | Closing manager |
| --- | --- | --- | --- |
| 1 · The path of lanterns | 1–8 | Lanterns | Ascua |
| 2 · The passing of the storm | 9–16 | Storm | Véspera |
| 3 · The Oath of the Bridge | 17–20 | Lanterns | Taro Jade Oath |
| 4 · The garden of echoes | 21–30 | Lanterns | Iria · Garden of echoes |
| 5 · The intertwined paths | 31–40 | Storm | Luma · The nine paths |
| 6 · The Solstice Furnace | 41–50 | Lanterns | Ascua · Heart of the Solstice |
| 7 · The faces of the return | 51–60 | Storm | Duna · Strength of Return |
| 8 · The lightning school | 61–70 | Storm | Kiro Lightning Roar |
| 9 · The circle of the masters | 71–80 | Lanterns | Neris · Circle of the teachers |
| 10 · The Eve of the Stars | 81–90 | Storm | Sira · Edge of the stars |
| 11 · The last eclipse | 91–100 | Storm | Véspera · The last eclipse |

**Véspera is the final boss.** Ascua reappears in 50. Its phases are in `story_catalog.gd:220`: Ascua goes to Living Furnace to 60% and Last Ember to 30%; Véspera a Wings of the Gale and Eye of the Storm. They already arrive as `ability_id: phase_shift` and `phase_index`, consumed by Main and Replay. A musical layer can respond to those events without creating new rules.

There is an important distinction: Route uses `journey` in chapter 1, `storm` in 2 and `route_late` after (`story_panel.gd:367`); The combat follows the previous table (`main.gd:432`). Online shows Storm in its menu, but Replay resolves to `snapshot.rival.story_chapter_id`, with chapter 1 as the default (`battle_replay_panel.gd:170`). An online fight without this information shows **Blanking**. The acoustic profile must follow the truly resolved background; the visual scenery is not changed in this task.

## 3. ArenaAudioProposed profiles

| Field | `arena_faroles` | `arena_tormenta` |
| --- | --- | --- |
| Resolution | `arena-faroles-v2.png`, also real fallback | `arena-tormenta-v3.png` |
| Music | `mus_battle_faroles`, 96 BPM | `mus_battle_tormenta`, 120 BPM |
| Environment | `amb_faroles_air`; very occasional fabric | `amb_storm_water` + `amb_mountain_air` |
| ground | `earth_packed_dry` | `stone_wet` |
| Space | Dry exterior; slight edge reflection, starting decay 0,3 s | Exterior with stone; short scattered reflections, starting decay 0,55 s |
| Public | None initially | None |
| Optional accents | Fabric; almost inaudible wick | Isolated drop under arc, uncommon |
| Home | One-stop pickup, without slowing down the engine | One-stop pickup, without slowing down the engine |
| Result | Low bed and a sting; air remains | Low bed and a sting; water/air remain |

Reverb values are listening points, not stage measurements. Dry Foley separated from shipping space; Focused and dry UI off the reverb bus. Two combat surfaces are enough: six initial step variants and three ground contact/landing variants. The body provides weight, fabric and reaction through another layer, coordinated with the character inventory. Do not duplicate body and footprint when generating the surface bench. Static workshop/shelter previews do not require looping steps.

## 4. Musical map and kinship

Proposed **Lantern** motif: 1–♭3–5–2, D–F–A–E in D minor; lunar response 2–5–♭3–1. It is an original cell to direct listening, not a promise that a generator will obey the notes exactly. Master Bible sets Lanterns to 96 BPM; this inventory is already aligned. The other speeds are proposals after the first cut.

Warm plucked string, bowed bass support, leather and wood percussion, round brass and flute breath connect the whole family. Registration, density and silence distinguish refuge, patio, mountain and boss. No ritual authenticity is attributed to a real culture nor is a song copied. Roster fauna does not require switching to a national stereotype when selecting a cosmetic body.

| ID/use | BPM | Instrumentation and pulse | Proposed loop | intro/end |
| --- | --- | --- | --- | --- |
| `mus_home` · menu, shelter, companions, settings | 80 | Warm stroke, soft bow, sparse wood, dull bronze; wide breathing. | 48 compasses, 144 s | 1 compass / tail of 3 s |
| `mus_route_journey` · Path 1 | 96 | Plucked and wooden flute, faint hand drum; walking suggested. | 64, 160 s | 1 / 3 s |
| `mus_route_storm` · Path 2 and later | 96 | Journey arrangement with air and harmonics, plus suspension. | 64, 160 s | 1 / 3 s |
| `mus_workshop` · train, techniques, create, customize | 80 | Home arrangement, off attacks and patient repetition. | 32, 96 s | 1 / 3 s |
| `mus_archive` · Legacy, history | 80 | Home arrangement with a mid-time feel, very scarce bronze. | 32, 96 s | 1 / 3 s |
| `mus_battle_faroles` · normal combat | 96 | Hand/dry wood, plucked low string, short responses to the motif. | 64, 160 s | 1 / 3 s |
| `mus_battle_tormenta` · normal combat | 120 | More agile hollow wood, harmonics and airy phrases, without treble carpet. | 64, 128 s | 1 / 3 s |
| `mus_boss_ascua` · meetings 8/50 | 104 | Belted bass drum, bow and low brass; threats with pauses. | 64, 147,69 s | 1 / 3 s |
| `mus_boss_vespera` · meetings 16/100 | 120 | Airy flute, harmonics, circular pulse, contrast of registers. | 64, 128 s | 1 / 3 s |

There are **nine logical beds**, with derived arrangements; not nine disconnected compositions. Chapters 3–11 do not require a new track by name. Elites and roster bosses use the arena bed with contained pressure; Their particular motifs can be added when character profiles are approved. Ascua and Véspera do have their own identity. The 100 encounter adds a serious Farol response to the lunar array; it does not recycle the normal fanfare as the end of the campaign.

Five variants planned: Lantern Elite, Storm Elite, Ascua Pressure, Véspera Pressure, and Eclipse Final Fix. The same pressure layer becomes faint in phase 1 and more present in phase 2. Generate after the approved parent. Two independent generations are not automatically synchronized stems: check tempo, harmony, phrases and samples; If they don't fit, use an alternative full arrangement and crossfade safely.

Five resolutions: normal victory 2,4 s; defeat 1,6 s; tie 1,6 s; chapter completed 4 s; campaign completed 6 s. Choose **one** per result. Higher rewards replace the normal sting. Defeat preserves dignity and allows for positive XP and retry; no mockery or alarm. The tie is only used when the data actually identifies it and respects `viewing_side`.

Music retains position when refreshing or switching between screens in the same family. Opening Settings above combat lowers the bed, it does not start Home from scratch. Musical layers can enter the next measure; contacts, KOs and actions do not wait for that beat. ×2 does not speed up or change the music/voice pitch. Selecting a boss in Route allows for light tension, not its full introduction every time you navigate.

## 5. UI: Intent vs Confirmation

All new cues are absent today. The table identifies where there are already useful signals/returns and where a semantic event is missing; does not propose that style visual helpers play sound.

| Action | Current hook | Observed Audio/Proposed Integration |
| --- | --- | --- |
| Menu, open/close modal | `home_panel.gd:71`; `game_modal.gd:104,117`; `main.gd:1292,1364` | No sound. Short fabric when opening, low return when closing; once per transition. |
| Tab, path, chapter, Legacy | `story_panel.gd:198,573,579,988` | No sound. Very faint navigation only if a deliberate selection changes. Configure, restore focus and rebuild are silent. |
| Choose partner | `main.gd:374,1269` | `start` after selection. Replace with partner selection, not combat announcement. |
| Local Stat | `main.gd:382,878` | `upgrade` if returns success. Adjustment click smaller than a technique or talent. |
| Technique/talent/local respec | `main.gd:391,396,409` | All `upgrade`. Firmer technique/talent; respec only confirmation, not level award. |
| Result/level/unlock | `main.gd:1161,303`; `story_progression.gd:434,572` | Win/lose only. `level_before/after`, `level_ups`, `moves_unlocked`, `cosmetics_unlocked` already exist: emit a confirmed group, without a sound per XP point. |
| New chapter/file | `main.gd:418`; `story_panel.gd:988` | Start reuses start. Completing for the first time deserves sting; see file does not grant another prize. |
| Color, body, effects, style | `customization_panel.gd:344,358` | Silent eraser. Slight fabric when changing; Appearance does not mean new power. |
| Random/preset | `customization_panel.gd:389,407` | A draft change: one cue, not six per slots. |
| Confirm identity/create | `customization_panel.gd:429`; `main.gd:269`; `online_panel.gd:929` | The confirmed signal is intent. Success only after saving identity and required progress, or valid remote response. Create can currently chain start+upgrade; unify in a gesture. |
| Cancel/error/name | `customization_panel.gd:422,436` | Small return; buffered new error; silent name writing. Repeating the layout of the error does not reproduce it. |
| Online challenger | `online_panel.gd:472,746` | Real DTO and selection now available. Click when choosing; empty list and failed challenge do not announce combat. |
| Enhancement/AI/Talent/Remote | `online_panel.gd:750–820` | No sound. `_mutate` after `_current(stamp)` and `response.ok` is the reliable limit; dedupe per operation/revision. |
| Enter with browser | `online_panel.gd:253,289`; `online_api.gd:103` | Continue minimum; an entry when the session goes from invalid to valid. Poll, WAIT, pending and slow_down are silent. No "security" sound in native passkey. |
| Cancel/logout | `online_panel.gd:275,897,970` | Discreet return. Cancellation is not error; deleting local session is not equivalent to confirming remote revocation. |
| Pending/retry/network error | `online_panel.gd:777,820,943,968` | Silence during hold/countdown; single notice in the event of a new failure. A response discarded by generation produces no sound. |
| Activity while you were away | `online_panel.gd:658,770` | A faint warning for a new, non-empty batch. ACK does not earn XP; no fanfare for every row or refresh. |
| Play/online history | `online_panel.gd:840,874`; `battle_replay_panel.gd:170–226` | All silent currently. Same combat audio by time/rate; never new reward events when viewing a saved match. |
| Reduced sound/speed/motion | `main.gd:1218–1240,1468` | Only activate sound plays upgrade. Buses/volumes are missing; no tick per slider frame. Reduced movement and silence are different preferences. |

The UI should be dry, focused and more discreet than a punch. Navigation 40–90 ms, select 80–160 ms, confirm 180–300 ms; leather/wood/bronze, no beeps. Pointer hover off by default. Deliberate keyboard focus can share navigation; the programmatic focus no. Disabled buttons are silent; a blocked item that accepts interaction to explain requirement can deliver a cushioned blow.

The proposed 16 families include browse, select, confirm, return, open, lock, error, stat, build, equip in preview, level, technique unlocked, cosmetic unlocked, creation, account entry and offline batch. Common cues have 2–3 variants. The reward notices for 0,65–1,4 s share the reason and are grouped together to avoid simultaneous melodies.

## 6. Integration and QA requirements

Main has `_dispatch_events` (`955`), Replay `_apply_event` (`226`) and an explicit clock/index. A central consumer can cover both without touching the motor or changing saved events. The sand profile derives from the resolved bottom, the identity of the descriptor and the result of its perspective. A single conductor controls the music bed so that an overlay does not create another independent player.

In Replay, restart/close invalidates generation and cancels queues; do not burst past events when selecting. Playing the ending again may have its cinematic sting, but never the sound of a newly granted level/cosmetic. Online uses the same panel, retains server authority, and doesn't touch local XP. Signatures and phases use existing events; not shooting music from particles or inventing probabilities or changes of state.

Mixing and delivery follow the master bible: readable physical audio, bassy and mono-friendly ambiences, tracks with headroom, UI off arena reverb. Duck/volume values ​​are listening goals, not measurements of non-existent jacks. Try pause, close, ×2, reduced movement, two loops, vocal limit and total silence on all routes. Test with isolated fixtures; do not authenticate or modify a real account.

The JSON backlog contains **49 logical IDs**: 9 beds, 5 variants, 5 stings, 8 environments, 6 surface families and UI 16. Each row includes usage, duration, loop, description, intensity, material, place/character when applicable, variants, dryness/reverb, key, exclusions, and ElevenLabs prompt. Music adds BPM, mode, motif, instrument, intro/outro, and parent dependency. Variants and intro/final files increase the total deliverables; They are not 49 final files nor a command to generate them all.

First approve Lanterns + physical combat of a fighter + result and the same Replay. Then complete identity, boss, Storm, navigation and progression according to Bible priorities. Save original shot, exact prompt, provenance, hash and measured parameters; reject accidental voice, foreign timbre, multiple gestures when one is requested, invasive transients or loops that do not close. Exact notes, BPM and stem synchronization are verified, not assumed due to being in a prompt.
