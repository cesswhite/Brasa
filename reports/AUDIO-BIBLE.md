# Brasa · Audio Bible

Date: 2026-09-21. Original address, derived from the inspected game and from `VISUAL-STYLE-BIBLE.md`. The current revision prioritizes **natural physical contact, air/fabric, recognizable ground and fire** after feedback of tones and drawn metal. The range remains **Ascua and Patio de Faroles**. The rest is an explicit backlog; a prompt is not equivalent to a delivered sound. ElevenLabs is operated on **Google Chrome**, with the user's session; Generations are not shared in Explore.

## 1. The same matter that is seen

Story Mode's stone, leather, worn fabric and wood define the sound. The visible brass does not require adding bells, resonances or metallic drags to the blows. The body and the ground come before the ornamentation. There is warmth from lanterns, open air and silence between gestures. Combat must be understood without looking at the numbers: preparation, movement, contact or evasion, consequence and return to rest.

There is no narrator's voice or added dialogue. Vocalizations are brief, selective efforts. Ascua weighs and breathes like living coal; it doesn't turn into a screaming human or a movie explosion. The signature is exceptional for its temporal form and texture, not for saturating the Master. Removed circular fire effects do not return as permanent buzzes or sound rings.

Common palette: dry leather, cotton fibers, dry weighted body blows, compacted earth, porous stone, small fire and wood. The blow has a recognizable attack and a natural fall; The air accompanies and leaves room for contact. Fire uses blowing, combustion and crackling of coal, without tonal sweep or hum of power. Avoid lasers, electronic interface sounds, shuffling metal, casino bells, comic cardboard, directionless mixed libraries, and generic epic music.

## 2. Inventory and authority

The complementary reports are part of this bible:

- `AUDIO-TECHNICAL-AUDIT.md`: files, players, buses, volume, clocks and limitations.
- `AUDIO-CHARACTERS-AND-COMBAT.md`: the companions 15, Ascua and Véspera; catalog of movements, reactions, signatures and real phases.
- `AUDIO-WORLD-MUSIC-UI.md`: Really rendered scenarios, menu contexts, music, UI and progression.
- `../../../work/audio/audit/*.json`: Tool-readable inventory.
- `../../../work/audio/production-plan.json`: production batch of the first slice, with complete prompts and parameters. The actual provenance and selected shots are recorded after downloading.
- `../../../work/audio/revision-realism/production-plan.json`: Address and Sources V2. The candidates and their technical preselection remain separate from the integration; revision V1 is preserved in `revision-realism/before/`.

Diagnostic before producing: nine synthesized tones in Main, no imported audio files, no music/ambience, no dedicated buses or persistent mix. The semantic intent of your calls is preserved; the doorbell is replaced. The signature tone is called in the ad and again in the impact; They should be two different layers, never two reproductions of the same gesture. Replays, including Online, require the same event consumer. `MoveVisualProfile` now offers bookmarks; audio should not depend on visible particles existing.

KEEP: rule events and movement times; fighter identity and cosmetics; visual layers; real navigation and confirmations. REWORK: repetition policy, cooldowns, priority, pause and volume. REPLACE: test tones. MISSING: all banks directed, music, atmosphere and most specific feedback. Do not modify damage, balance, RNG, progress, account, Worker or server log.

## 3. Body, archetype and setting

The body profile determines weight, breathing, footprint and tissue. The archetype determines power, signature and motive. The custom look remains the same identity: the audio doesn't infer metallic armor from a tint, invent accessories, or advertise unequipped cosmetics. The profiles of all the bodies and their proposals appear in the inventory of characters; basic foley sharing is deliberate, but it does not equate to having produced every identity bank.

There are two current combat arenas: `arena_faroles`, compact dry earth with terracotta; and `arena_tormenta`, wet slabs, water and wind. Eleven chapters reuse those locations. The narrative names of a garden or oven do not authorize a new acoustic if the real background remains the same. The audio must resolve the same background that renders the scene; a Replay without a chapter falls to Lanterns as the visual code.

CharacterAudioProfile conceptual format: id, body, weight, movement texture, power material, reaction density, signature cues, supported transformation cues, motif, per-event overrides. ArenaAudioProfile: id, surface, ambience, music, outdoor/interior character, stereo spread, gain, intro/results. Fields still without archive remain absent and silent; Never choose another character's power as a replacement.

## 4. Combat Grammar

| real action | Before/movement | Resolution | Consequence |
| --- | --- | --- | --- |
| Fast | short plant + short whoosh | light body if there is damage | selective light reaction |
| Heavy | weave and tension; Ascua carbon content | dense body | weight/recoil reaction |
| Load | pressure + a friction in `slide_start` | heavy impact if hit | stop does not replay drag |
| Jump | boost on `jump_takeoff`, air on trip | authorized contact | ground in `landing`, no duplication `right_foot_impact` simultaneous |
| Guard | plant/clothing when adopting posture | dry contact only if resolution justifies it | never tag guard as parry perfect |
| shield | defense preparation | distinct absorption of damage | if damage and absorption coexist, weaker defensive layer |
| Replica | `move_started(counter=true)` | real replica attack | without inventing "perfect block" |
| Dodge | air and target displacement | no body/impact | neither correct nor critical |
| Failure | conserves attacker movement | no hit and no dodge reward | contact silence |
| Critical | same attack | body + brief dry leather/body contact | no bronze or tonal glue; high priority, not disproportionate volume |
| Signature | own short advertisement | different signature accent, only once | space in music, real reaction/KO |
| Burn | dim initial ignition | ticks retain their visual feedback without repeating `ascua_release` | lethal tick preserves knockdown/KO |
| Transformation | Ascua `phase_shift`, index > 0 | ignition gesture of its core | short queue, no permanent loop |
| KO | retains last impact | differentiated fall after movement | ground and resolution; do not multiply KO per attack + finished |

The times come from `move.windup/travel/recovery` and `MoveVisualProfile.resolve().markers`; Don't hardcode a parallel animation clock for damage. Select clean attack gestures and short natural tail; trim only the edges without activity. Do not speed up a shot to make it fit or truncate an active queue to meet a duration. A displacement friction; your visual markers can continue to exist without another audio layer. If a frame receives multiple delayed events, discard outdated motion markers instead of playing a burst. Consumption identity per session + event index + marker. Do not change received events or add audio paths to server contracts.

The audio follows its own presentation clock in Main and Replay. The pause stops new programming and pauses loads linked to an action; the musical/ambient beds and short queues continue. Resuming does not recover lost sounds. The visual hitstop and reduced motion do not stop the audio. ×2 should speed up marker triggering, not turn the music up an octave. Closing a replay or starting another session clears queues and voices from the previous context.

Ascua has actual `ember_core` from 0.72 s / 8 s visuals, without new stats. Other bodies possess signature poses but no registered transformation. Do not produce new forms. The signature probability is decided at the start of the fight (1% per combatant); QA uses controlled fixtures/seeds, it does not modify the probability of production. Counter/parry of Ascua: not applicable. Their loads do have dash locomotion, without adding a new technique.

## 5. Music and atmosphere

Common proposed motif “Lantern”: 1–♭3–5–2, voiced with warm plucked string, leather/wood percussion, and muffled brass. It is a suggested original composition, not a claim that the musical model will return exact notes. The manifest distinguishes generated music and subsequent editing.

Lanterns: 96 BPM, D minor, contained tension and night air. Storm: the same language with low bowed string, stone/air and tighter pulse. Shelter, Preparation, Workshop, and Legacy menus are variations on the family, not completely different songs per tab. Bosses add density and motif of identity; Véspera is the final boss, Ascua returns in the 50 encounter. The world inventory details the entire map, including intros, loops, and endings.

A continuous, natural environmental bed without invasive events: outside air, sheets/fabric and discreet wick. Faroles does not have an invented crowd; Storm does not use indoor rain. The music and atmosphere change with a smooth crossfade and do not restart by rebuilding a panel. The revision reduces the music and makes the place more present; The instrumental motif should not occupy the space of a beat. Music below contact and notices; duck of 3–6 dB of 300–800 ms in signature, phase and result. Don't duck on every heavy hit. Avoid melting KO queues within the following ad.

Source loops are not assumed to be perfect: extremes are inspected, edited to stable loops with compatible aliasing/equalization, and double-checked. Save source and edit. Do not play a song with a crescendo and abrupt ending to repeat without sound work.

## 6. Interface and progression

A leather/wood/brass tactile click links all visual system screens. Short, faint navigation; confirmation once on a valid action; errors with a lower note/muffled gesture. Keyboard and mouse focus use the same semantics. No sounds when rebuilding widgets, polling login or receiving unchanged status. Disabled buttons remain silent. Global UI in the center, without combat panning.

Upgrade, Recruitment, Level Up, Encounter Completed, Boss Defeated, and Cosmetic Confirmed trigger after valid and current local commit or online response. Accounting animations do not produce a sound for each point of XP. Victory/defeat preserves the background of the combat and a short resolution of the same family. The backlog separates these notices; the first slice includes confirmation and results, it does not presume to have finished the entire UI.

## 7. Mixing and implementation

Central AudioDirector and event manifest, profiles as data. Buses: Master; Music; Ambience; SFX as parent of Combat, Movement, UI and Voice. No long global reverbs. Bounded pool, priorities and cooldowns by event/source. The director selects variants avoiding immediate repetition, with independently presented RNG. Combat and Movement tone fixed to 1.0 in this patch; impact gain ±0.5 dB and motion slight variation. Music/tonal UI without randomizing notes.

Master maintains headroom. Prepare sources at 48 kHz PCM16 mono; beds in OGG stereo. File peak target ≤ −3 dBFS, minimum fades and envelope preservation. Measure DC before correcting: averaging an asymmetric transient does not prove a defect. The positive readiness gain has a ceiling of **+12 dB**; a weak source is not rescued by amplifying noise. For shocks, preselection requires source peak ≥ −18 dBFS and brief contact identifiable by the envelope; It still requires listening.

Playback gains keep contact ahead: UI −18 dB; fast/heavy air −17/−15; footprints −18; light/heavy body −8/−6; load/release Ascua −19/−17; environment −19; music −20. They are catalog adjustments, not measurements of a final capture. The critical accent is additive to −10 dB, physical and brief. Master retains a single `Brasa Master Safety`: +7 dB pre-gain stage and limiter with nominal ceiling −1 dB, along with the user's fader and mute. The nominal ceiling does not replace the true peak measurement of each capture.

Persistent Master/Music/SFX controls; Ambience and Voice within the mix with appropriate option if there are actual banks. Mute preserves values. Use the modal and shared styles of Story Mode, focus and accessible labels. The configuration is its own preferences file; Do not alter the user's progress when opening Settings or during tests.

Subtle stereo localization (left/right depending on combatant); priority KO/signature > critical/contact > power > movement > decoration. Cut or reject low priority sounds under clipping, never block the thread. Search used banks; Do not load the full 17 profiles by entering the menu. Release context and queues when closing Replay. Tolerate pending files without error or surprise synthetic tones.

## 8. Production and first slice

The plan covers contact, defense, movement, Ascua identity (charge, release, signature, phase and reaction), KO, start, results, confirmation, atmosphere and music. Revision V2 replaces families that do not meet the physical address. The integrated revision contains 51 files: 20 of new generations, original 30 reprocessed at natural speed and a preserved piece of music. The chosen variants and the two native captures appear in AUDIO-DELIVERY.md; The number of downloads or candidates does not count as delivery. The backlog expands variation when the acoustic character is approved. Don't pretend that pitch changes are original variants.

Order: P0 readability → P1 identity and KO/signature → P2 place/music → P3 essential confirmation → P4 left for after listening and review. The plan includes English prompts descriptive by source, duration, material, dryness, intensity and exclusions; no repository or private data is sent to ElevenLabs. Music is created in the music tool of the same Chrome session, not as ambient noise disguised as a song.

Each download must record group, exact prompt, chosen duration, variant, source file, hash, credits observed when available, edition and destination. Reject/re-edit takes with long intros, accidental vocals, multiple hits when one was requested, invasive queues, or out-of-world ringing. The number of candidates delivered by the website is documented; do not assume fixed number per generation.

Originals and separate hashes of each edition are preserved. Current policy uses `process_natural.py`: **original speed and pitch, no `atempo`, no time stretching, and no rescue normalization above +12 dB**. The processor retains the attack and the active queue; a duration limit rejects a shot that is too long, it does not compress it. The environment maintains stereo and only supports a small, documented circular overlap. The music is not sped up to force BPM or loop. Previous editions with time compression remain as historical evidence, not a recipe for V2.

Discontinuity, energy, and envelope measurements guide selection and do not endorse musical realism or naturalness. Integrated provenance: `../assets/audio/SOURCE-MANIFEST.json`; historical measurements: [audio asset review](AUDIO-ASSET-REVIEW.md). `measure_mix.py --playtest-dir RUTA` measures the WAVs of that capture and links its demo using hashes; `validate_assets.py --playtest-dir RUTA` incorporated that same evidence into the report and the now-removed development gallery. The historical default path is preserved and a new revision should indicate its explicit folder.

## 9. inspection door

Before spawning: inventory, profiles, music map, combat/UI events, transformations/bosses, and backlog present. After: import, load test, semantic routing test (miss/dodge/absorb/critical/signature/KO), real offline session with fixture, Replay and Online Replay without mutations, pause/×2/reduced movement and volume changes. Verify lack of clipping, tails, density, cuts, repeat and loops with a real mix capture.

Peak/RMS measurements and waveform captures are not a substitute for auditory judgment. The validation report should distinguish automated testing, Godot playback, and human listening, and make any limits explicit. Deliver a reproducible demo with real ElevenLabs sources and session progress, without touching the user's games. Only after reviewing this slice does it proceed to produce the rest of the cast.
