# Audio technical audit Brasa

Date: 21 September 2026. Condition: **photograph prior to the implementation of the new audio**. The subsequent service is documented in AudioDirector · Implementation (`work/audio/audit/audio-director-implementation.md`; not included); The facts and hashes from this audit correspond to the previous code.

Brasa has nine procedural confirmation and combat tones, played by five reusable audio players. It does not contain audio files, music, environments, voices, a sound catalog or its own buses. The separation between engine and presentation allows this system to be replaced without changing damage, randomness, rewards or saves.

The first agreed vertical is **Ascua + lantern sand**. This report defines its technical integration; the Master Bible defines artistic direction, sound selection and production backlog. No audio was generated or played, the normal game was not opened, the network was not consulted, and no runtime or games were modified. Replacement assessments are decisions against the new objective, not the result of listening that was not performed.

## Scope and evidence

Existing scripts, scenes, settings, presentation metadata and tests were read. The inventory of audio extensions and resources `AudioBusLayout` covers the project, excluding `.godot`, backend, `node_modules`, and `.git`. Result: **0 audio files and 0 bus resources**. Tones exist only as PCM generated in memory. The project declares Godot 4.7 and the local executable reports **4.7.2.stable.official.ed1daf0bf**. No mobile devices, latency, loudness, voice consumption, or physical output were tested.

The hashes, routes, lines, parameters and structured inventory are in technical.json (`work/audio/audit/technical.json`; not included). References `[S01]`–`[S12]` refer to the index at the end. They are a snapshot of the sources when auditing, not a commitment that they will never change.

## Inventory and decision

`KEEP` retains a valid decision; `REWORK` changes an exploitable mechanism; `REPLACE` replaces the current content; `MISSING` identifies something required that does not exist. Not all gaps must occur before hearing the vertical.

| Existing item | Proven fact | Decision |
|---|---|---|
| Engine/presentation separation | The engine outputs data; Main plays sounds afterwards. There is no audio in the formulas. | **KEEP**. Maintain this border. |
| Generated tones | Nine `AudioStreamWAV`, one variant per ID; fundamental oscillator + second harmonic, envelope and sweep. | **REPLACE** as final content; They can remain as explicit development fallbacks. |
| Reused resources | PCM created on `_ready()`, not on every hit; five reused `AudioStreamPlayer`. | **KEEP** reuse; **REWORK** budgets, priorities and configuration. |
| Mix | All players at −10 dB, no bus assigned; Master default route. | **REWORK**. It is not equivalent to normalization or headroom testing. |
| Yes/no sound | Main boolean, not persisted; it only blocks new sounds. | **REWORK**. Centralized settings and effective mute. |
| Impact events | separate hit/critical/signature; miss and dodge share tone. | **REWORK**. Material, intensity and absorption must have meaning. |
| Visual markers | Steps, jumps, slides, loads, and recovery all have resolved times. | **KEEP** as temporary source; add independent audio consumer. |
| `sound_event` | Metadata present with `hit`, `heavy` or `dash`; is not consumed. | **REWORK**. Catalog allowed and explicit compatibility. |
| Practiced history | Re-encounter uses Main and current tones, without granting progress rewards. | **KEEP** the flow; distinguish it from reproduction of a record. |
| Historical and Online Replay | Both present events with `BattleReplayPanel`, without audio. | **MISSING** the parity of sound presentation. |
| Headless protection | `_play_sound` exits unplayed. `_make_sounds` does build PCM before. | **KEEP** the silent sink; Avoid unnecessary preparation in future tests. |
| Tests | There are visual tests of settings/clock/pause and fixtures that mute sound; not an audio suite. | **MISSING** contract testing, mixing and listening. |

### The nine current shades

All are built at 22.050 Hz, signed 16-bit samples, one sample per instant and no stereo configuration. The frequency base is a synthesis parameter, not a perceptual measurement. [S01:1763–1795]

| ID | Base Hz | Duration s | Current use | Decision |
|---|---:|---:|---|---|
| `hit` | 130 | 0,11 | Normal impact and counterattack; also shield absorption | REPLACE |
| `critical` | 210 | 0,17 | Critical impact | REPLACE |
| `dodge` | 680 | 0,12 | Dodge and miss | REPLACE |
| `upgrade` | 760 | 0,15 | Enhance, customize, create, redistribute and activate sound | REPLACE |
| `start` | 420 | 0,30 | Start of combat and some chapter selections/changes | REPLACE |
| `win` | 660 | 0,50 | Won result | REPLACE |
| `lose` | 240 | 0,40 | Lost result | REPLACE |
| `ability` | 530 | 0,20 | Heal, shield, and any skill events | REPLACE |
| `signature` | 980 | 0,75 | Signature announcement **and** its impact | REPLACE and fix duplication |

Generation uses a single waveform per ID; there is no variation, panning, selection by partner, clothing/body, material or sand. No previous artistic audio needs to be deleted or converted.

## Current connections and specific gaps

| royal entry | Current sound presentation | Recommended integration |
|---|---|---|
| `move_started` | Silence | Schedule preparation, support and movement in phases. Never anticipate the confirmed impact. |
| `attack: hit / critical / signature` | One of three tones | Resolve impact from the result, material and absorption; critic/signature with controlled accent. |
| `attack: miss / dodge` | Same tone `dodge` | Maintain movement in air; dodge sound only for dodge. **No body impact** on both. |
| `attack` with `counter=true` | `hit` | Counterattack movement/response and contact confirmed, without inventing perfect parry. |
| `defensive_stance` | Silence | Discreet guard entry; not create a lock when activated. |
| `shield` and absorption in `attack` | `ability` when granting; `hit` when absorbing | Granting and contact with different shields. Total absorption should not promise body harm. |
| `heal` | `ability` | Own cue and limited by cadence. |
| `status_applied / tick / expired / resisted` | Silence | Application and ticks selected according to effect; not sound every particle or every text. |
| `ability: phase_shift` | `ability` | Ascua phase transition, supported by its actual definition and presentation. |
| `signature` | `signature` | Activation accent differentiated from impact; respect when the event arrives. |
| Normal or status lethal damage | No KO specific cue | Lethal impact/tick, cancellation of future actions and fall according to presentation. |
| `finished` | `win/lose`, after visual wait of 0,30 s unless surrender | A combat closure; Do not confuse timeout/surrender with a fatal blow. |
| Reward/XP/Unlock | Only some `upgrade`, no reward hierarchy | UI/progress from confirmation of the real operation, never from a replay. |
| Tabs, focus, return, error, closed, inventory | No shared routing | Small common UI vocabulary; Discreet error messages and blocked actions. |
| Music, environments, voices, steps, jump, landing, fabrics, energy, intro and cosmetics | No resources or routes | MISSING; produce by Bible priority and avoid permanent cosmetic loops. |

Sources: Main [S01:956–1087,1161–1216], engine [S03:290–612], rules [S04:25–51], Replay [S07:170–276], Online [S08:840–881]. The engine has guard, absorption and counterattack; **does not return a `parry` or `perfect_block` result**. Its attack results are hit, critical, signature, miss and dodge.

### Verified failures and risks

1. **The signature can duplicate the same sound.** The engine outputs `signature` and then `attack` resulting in `signature` at the same resolution. Main plays the tone on both handlers. If there are two free players, two copies of 0,75 s overlap. It is not a differentiated preparation and impact. [S03:364,401; S04:48; S01:1043,1087]
2. **Mute does not mute what is already playing.** Changes a boolean queried when requesting the next sound; It does not change Master or stop players. Reopening the application restores the initial value `true`. [S01:85,1223–1227,1788–1795]
3. **The pool loses non-hierarchical events.** When all five of its players are busy, `_play_sound` ends up unplayed and without registering a discard. UI/skill has the same opportunity to occupy a slot as signature/result. Effective saturation was not measured. [S01:1782–1795]
4. **Online and historical logs are silent.** They do not reach the Main helper. Do not confuse this gap with repeating a Story Mode encounter, which Main does execute. [S07; S08:840–866; S01:402–407]
5. **A metadata does not constitute an integration.** `sound_event` is only validated as a string of up to 80 characters; `heavy` and `dash` don't even exist in all nine shades. The future consumer must accept registered IDs, not interpret routes/URLs from events or appearances. [S05:15–59; S01:1764]
6. **There is no late audio policy.** Visuals receive `elapsed-event.time`; the impact sound is played in full when handling the event. Acceleration, batching of events, or long pauses require explicit discard/coalescence criteria. No specific audible gap was verified. [S01:1007–1043]
7. **Future settings may be lost if the current file is inadvertently expanded.** `_toggle_reduced_motion()` creates an empty `ConfigFile` and saves only its key. Adding volume to the same file without loading/shuffling first would cause this path to overwrite it. Today there are no persistent volumes that are being lost. [S01:1229–1234]

## Recommended architecture — not yet implemented

A single **AudioDirector** for the application session, with screen/arena and combat context. Main and `BattleReplayPanel` will be adapters of the same service; Online will reuse the repeat adapter. The director does not call the engine, does not reward, does not write identities or snapshots, and does not embed files in server events.

### Proposed API to agree before programming

```gdscript
# Proposed names; they do not exist in the audited game.
configure_context(arena_id: String, fighter_profiles: Dictionary,
                  session_context: Dictionary = {}) -> void
on_combat_event(event: Dictionary, presentation_time: float,
                event_index: int) -> void
advance(presentation_time: float) -> void
play_ui(event_id: String, context: Dictionary = {}) -> void
set_volumes(settings: Dictionary) -> void
set_paused(paused: bool) -> void
stop_session() -> void
```

`session_context` contains local session identifier, battle_id if exists, mode `live/replay/online/preview` and results policy. Profiles resolve **allowed local IDs**, not corrupt owner nodes or server-provided routes. The watch is delivered by the presenter: `combat.elapsed` live, `elapsed` on replay; `advance` dispatches expired markers once. Music/UI use real time and do not require a combat to progress.

The engine does not emit a unique ID per event: it adds turn, time and VP, and preserves order in `event_log`. Use stable registry index along with session/battle_id/side/action/marker; not just move_id or shift. Keep history intact. A new replay session allows you to hear it again; a duplicate event within a session does not play it again. [S03:625–633]

**Sound catalog:** Local semantic IDs, variant families, bus, gain, priority, maximum simultaneous, cooldown, maximum duration, queue policy, loop/one-shot, material and phase. Examples of future IDs: `movement.jump.takeoff`, `movement.jump.land`, `attack.swing.heavy`, `impact.body.light`, `impact.shield`, `signature.activate`, `signature.impact`, `status.burn`, `ascua.phase_change`, `ui.confirm`, `result.victory`. None are implemented yet.

**Variation selection:** Presentation-only RNG or session/event/actor hash; never consume the RNG of the combat or the global one used by gameplay. Avoid immediate repetition within a family; small pitch/gain variation limited by asset, deactivatable when identity changes. The choice must be reproducible for QA. Do not alter stats when changing appearance; The profile must distinguish the identity of the companion and visible material of the body equipped through known catalogs.

**Bookmarks:** Reuse timings from `MoveVisualProfile.resolve`, do not copy durations into each sound. Your board already solves windup/travel/recovery and allows support, takeoff, landing, sliding and loading. The FX scheduler provides useful cursor, WeakRef, limit and discard patterns per session. **Do not hang audio from `CombatFX._dispatch_markers`: FX is cleared in reduced motion.** Audio consumes metadata independently. Merge `landing` and `landing_debris` if they represent a single physical contact, so as not to duplicate the landing. [S05:7–90; S06:227–310]

**Hits and KO:** The `attack` result decides if there was contact, critical or absorption. Neither the marker nor the frame changes that truth. Cancel pending cues from the actor with PV ≤0 even if the cause is `status_tick`; allow the tail of the last impact and the final landing support. `finished` for surrender/time does not prove a fatal impact. Do not issue two KOs per lethal + finished tick. Signatures are separated by sound function, without duplicating the same sample. Loading can start with `move_started.signature`; do not move back the `signature` event that the engine issues when resolving the impact.

### Buses, pool and resources

Hierarchy proposal for the director:

```text
Master
├── Music
├── Ambience
├── SFX
│   ├── Combat
│   ├── Movement
│   └── UI
└── Voice  (activar cuando haya contenido vocal aprobado)
```

The Settings UI can display General, Music, Effects, Ambience, and Voices when content exists; SFX children allow mixing without multiplying sliders. Persist device preferences outside of Strength/XP profiles and preserve existing screen keys. `mute` must act on buses; Also try active queues, reopening and mode change.

Starting point to validate, **not already measured capacity**: 12 Combat slots (two reservable for important events), four Movement, two UI and two Voice; maximum 20 one-shots, plus two Music and two Ambience for crossfades. First delete a redundant step or an overdue minor event; protect critical hit, KO and important confirmation. Avoid hard cuts with short fades, respect priorities and expose request/play/discard counters. The vertical will decide whether these limits are reduced; Do not reserve memory of non-existent voices.

Prepare and cache only the families necessary for the two actors and the current arena, with limited cache between contexts. No `load()` per frame, per-hit PCM generation, or unlimited deduplication history growth. `AudioStreamPlayer` is enough for UI/music and the first vertical; Optional positioning using `AudioStreamPlayer2D` should have smooth panning and stable desktop/mobile boundaries. Do not use viewport size to change perceived volume. The actor's visual anchor can inform position; it does not create one emitter per particle.

### Clocks and states

| Situation | Current fact | Proposed policy |
|---|---|---|
| ×1 / ×2 | Main changes `Engine.time_scale`; It does not configure pitch or audio speed. | Preserve identity/pitch; schedule against the presentation clock. Coalesce minor supporting sounds if density at ×2 requires it. Measure native output. |
| hitstop | Freeze pose; The action clock keeps ticking. Does not play audio. | Let impact/reverb finish. Do not pause all buses due to visual freezing. |
| Manners during combat | Stop advancing motor and pause actors/FX; audio players remain unchanged. | Stop new combat cues; pause/fade only action loops. UI available; short tails end; atmosphere/music continue or fade according to the Bible. |
| Resume | There is no current sound scheduler. | Continue from conserved time; Don't download a burst of expired cues. |
| Replay pause/restart/close | Visual pause/clear; not audio. | Keep watch when pausing; on restart/shutdown cancel session, loops, queues and associations. Do not cut UI outside of replay. |
| Reduced movement | Just change actors, arena and FX. | Maintain audio meaning and volume. Its markers do not depend on the existence of particles. |
| late event | Full tone is triggered when handled. | Tolerance window per class: discard late steps; don't hoard old one-shots; keep current result once. Measure before setting definitive thresholds. |
| Result/history | Rewards are confirmed before visual delay; replay does not reward. | Stinger associated with presentation, reward cue only to new confirmed operation. Never reactivate unlocks from history. |

Sources of current behavior: [S01:936–969,1161–1239; S07:178–222; S09:376–386,428,673–675]. `set_paused` should not change `SceneTree.paused`, motor speed or `reduced_motion`.

## Proposed import, sound and mix

Preserve lossless originals, their licenses/origin and a manifest with hash, semantic ID, variation, channels, frequency, duration, loop and measurement. Generation and subsequent treatment will be explicit steps after the Bible; This audit does not produce audio.

For vertical: good quality WAV originals; 48 kHz/24-bit work preference when the source allows it, without pretending resolution it does not have. Export short one-shots to budget-friendly WAV PCM and import with playable settings; music/long atmosphere can use Ogg Vorbis after validating loop and cost in Godot 4.7.2. Inspect the actual import options when having files. Do not convert by extension or assume that an MP3 has a seamless loop. Jumpsuit for contact/steps; stereo only if it provides space. Record loop points and attack/tail times.

**Provisional measurement targets**, not current audio values: sources with true peak ≤−3 dBTP; final mix capture ≤−1 dBTP; Reference combat music around −20 LUFS-I (±2), adjusted against SFX by listening. 0,1–0,3 s sounds require comparing transient, energy and perceived level, not blindly normalizing them with built-in LUFS. No LUFS, true peak or clipping of the current synthesizer has been measured.

Take the normal impact as relative reference 0 dB; start steps/fabrics 6–10 dB below and UI 8–12 dB below; critical around +1 dB and signature +2 dB as initial limits, differentiated mainly by material/transient. They are design relationships to calibrate, not absolute gains to apply without measuring. Avoid duplicating body/bass on two coincident layers. Leave room in Master and check stereo/mono and mobile sum.

Soft music ducking, central and reversible only in signature, phase change, KO, boss presentation or major reward: starting point 2–4 dB, attack 30–60 ms and recovery 250–600 ms. Don't duck on every shot. A single handler composes overlapping motifs and restores the level; never several competitive tweens on the same bus. Discreet and stable environment; Cosmetics only have a cue if there is a relevant perceptible moment, not for each aura drawn.

## Implementation and acceptance plan

1. **Close Bible and interfaces.** Use Ascua + arena_lanterns, your real `phase_shift` and `ember_core`, the only transformation currently registered. Do not extrapolate transformations to the entire squad or Parry. [S10:246–257; S11:47]
2. **Director, buses, catalog and settings without changing the engine.** Implement silent sink for tests, allowed metadata, limits and previous API. Migrate the toggle while preserving screen preferences; do not migrate/rewrite progress.
3. **Connect presentation in Main and repetition.** Route each event and marker with index/clock once. Online uses that same consumer. Remove the equivalent procedural call when activating a new cue, avoiding two simultaneous systems.
4. **Integrate Bible-approved vertical resources.** Preparation, contact, step, charge, phase, KO and environment with few useful variants; Minimal UI. Listen before multiplying by characters or arenas.
5. **Approve contracts, performance and mixing.** Only then expand roster families and music/contexts, reusing coherent materials.

Proposed tests — **none were executed as part of this audit**:

| Group | Verification that must be demonstrated |
|---|---|
| Events and semantics | Signature activates/impacts once; miss does not produce contact; coherent full/partial shield; counter only when it exists; no invented parry. |
| Clock | 20/60/120 Simulated FPS, ×1/×2 and batch arrival: markers once, stable order, explicit late discards. |
| Pause/KO | Hitstop leaves tails; modal pause future cues; summarizes without burst; lethal tick cancels pending load/steps; shutdown/restart invalidates previous session. |
| Replay/Online | Same semantic list for the same live/replay record; reproducible variants; snapshots and immutable events; no repeated XP/unlocks. |
| Variations | standalone RNG; no immediate repetition when there are alternatives; pitch/gain within limits; rejected invalids. |
| Pool/cache | Level of players, loops and queue; proven priority; no file reading per frame; stable memory after 100 combat/context changes. |
| Settings | Volumes persist, mute affects existing sounds, `reduced_motion` preserves audio and other preferences; non-finite/out-of-range values ​​sanitized. |
| Integrity | Same seed produces the same events, HP, winner and rewards with audio on/off; hashes of snapshots/fixture games without alteration by presentation. |
| Resources | Files decode, frequency/channels/duration/loops match manifest; no clipping; non-existent variant uses explicit fallback and diagnostics. |
| native/listener | Vertical on desktop and real mobile, headphones and speaker, mono/stereo, low volume; measure latency/true peak and judge material, fatigue, critical/signature clarity and seamless loop. |

Existing visual fixtures that deactivate sound and headless guard do not certify these criteria. Your clock and pause tests are reusable regressions: `test_animation_sequences.gd`, `test_visual_fx_markers.gd`, `test_status_ko_presentation.gd`, `test_visual_history_settings.gd`. No auditory validation is attributed to its results.

## Local Source Index

| Ref | File and read points |
|---|---|
| S01 | [main.gd](../scripts/main.gd): 85–91,150–169,287,380–424,883,934–1087,1161–1239,1289,1468–1488,1763–1795 |
| S02 | [project.godot](../project.godot): 4–7,26–27; [main.tscn](../scenes/main.tscn) |
| S03 | [combat_engine.gd](../scripts/combat_engine.gd): 290–328,344–442,455–507,581,605–633 |
| S04 | [combat_rules.gd](../scripts/combat_rules.gd): 25–51,63–67 |
| S05 | [move_visual_profile.gd](../scripts/move_visual_profile.gd): 3–90 |
| S06 | [combat_fx.gd](../scripts/combat_fx.gd): 227–310 |
| S07 | [battle_replay_panel.gd](../scripts/ui/battle_replay_panel.gd): 170–276 |
| S08 | [online_panel.gd](../scripts/ui/online_panel.gd): 840–881 |
| S09 | [fighter_view.gd](../scripts/fighter_view.gd): 376–386,428,673–688 |
| S10 | [story_catalog.gd](../scripts/story_catalog.gd): 246–257 |
| S11 | [fighter_animation_set.gd](../scripts/fighter_animation_set.gd): 45–59 |
| S12 | [test_animation_sequences.gd](../tests/test_animation_sequences.gd), [test_visual_fx_markers.gd](../tests/test_visual_fx_markers.gd), [test_status_ko_presentation.gd](../tests/test_status_ko_presentation.gd), [test_visual_history_settings.gd](../tests/test_visual_history_settings.gd) |
