# Brasa audio realism review

21 September 2026. This revision replaces V1 after user feedback: sounds were perceived as frequencies and dragged metal. The range produced remains **Ascua + Patio de Faroles and the physical sounds shared**.

## Integrated shifting

- Light/heavy blows and guard with body, leather and cloth direction. The critic puts down the brass and uses brief physical contact.
- Movement of sleeves, treading and braking on land; a single friction per displacement. The Firm uses a shot different from ordinary releases and accompanies the body impact.
- Night courtyard atmosphere: wind, leaves, crickets and fire. The previous piece of music is preserved at a lower volume.
- All selected effects retain their original speed and pitch. `atempo` is retired; The hits/movements also do not change the pitch in playback. The old importer now directs the natural candidate processor.
- Weak shots and late contacts are ruled out. The setup gain has a ceiling of +12 dB and no integrated jack depends on reaching that ceiling to rescue it.
- Whooshes −4 dB, footsteps −3 dB, charge/release −4 dB, music −5 dB and ambient +3 dB with respect to V1. Removed re-release on burn ticks; initial application, contact and KO retain their feedback.

**51 active files in 22 families:** 20 of new generations, 30 previous originals reprocessed at natural speed and a piece of music preserved byte by byte. Downloaded **40 new shots in 10 generations** using ElevenLabs in Google Chrome. Observed balance: 44.692 → 44.175 credits (517); without purchasing credits or sharing in Explore. Discarded variants and all originals remain outside of playable banks, with hashes and provenance.

## Listen to the review

Complete New Combat (`audio-combat-demo.mp3`; not included) · Beats Before (`audio-contact-before.mp3`; not included) · Beats Now (`audio-contact-after.mp3`; not included) · [Report](AUDIO-ASSET-REVIEW.md).

The then/now reels contain four light and four heavy hits, separated by silence, at the file level and without additional normalization. The new demo was coded directly from Godot's Master during an entire fight; it is not an assembled sequence of isolated effects.

**Approval by ear is not declared.** This session allows you to measure and record the game, but not listen to its result. User feedback invalidates V1 as a sound reference; V2 measurements verify integrity, envelope, timing and levels, they do not alone prove naturalness, absence of accidental content or artistic taste.

## Validation of this review

| Check | Result |
| --- | ---: |
| AudioDirector | 352 checks, 0 faults |
| Replays / Online presentation | 44 checks, 0 faults |
| Two native fights, pause and reduced movement | 23 checks, 0 faults |
| Measured active files | 51/51, 0 errors, 0 validator warnings |

Clean Godot import. Both fights reproduce **38 body contacts**: neither is ruled out. Bookmark delivery to player: average 3,2/4,0 ms and maximum 8,3 ms; this does not measure device acoustic latency. There are no missing resources, no duplicates, and no events rejected for being late. Each run records 179 replays of 190 requests; the deletions are nine stomps per simultaneity limit, one stomp per cooldown, and one burn release per cooldown. The budget avoids accumulating movements; contact is maintained.

The two results and the event hash match each other and V1 (`01537ffe7d3b05658793cff31320342690874ecb7aa20f3a019529be2599ba4d`). No rules, probabilities, progression, user saves or backend are changed. The fixture uses Mugo20/Ascua12 and forces a Signature only within the harness, without disturbing normal play. Includes five techniques, Signature, 0/1/2 phases, burn, critical, miss, dodge, KO and actual defeat of the player.

| Capture | WAV Duration | LUFS-I | True peak (dBTP) |
| --- | ---: | ---: | ---: |
| normal_pause | 47.371 s | -26.5 | -6.4 |
| reduced_motion | 46.475 s | -26.5 | -6.9 |

The measurements correspond to the Godot Master, with General 85%, Music 70% and Effects 85% in the fixture. No clipping detected in the mix. Some generated fonts have full-scale samples, documented in their selection; This isolated fact does not approve or invalidate the bell. Retained phase sounds and stings are still subject to auditory review.

## Sources, backup and playback

- [Active origin](../assets/audio/SOURCE-MANIFEST.json), V2 session (`work/audio/revision-realism/generation-session.json`; not included), V2 selection (`work/audio/revision-realism/selections-v2.json`; not included).
- V1 Processing Diagnosis (`work/audio/audit/forensic-findings.md`; not included) and Independent Shock Comparison (`work/audio/audit/impact-v2-independent.md`; not included).
- Native validation (`work/audio/revision-realism/playtest/final/validation.json`; not included), mix and hashes (`work/audio/revision-realism/playtest/final/mix-provenance.json`; not included), event delivery (`work/audio/revision-realism/playtest/final/delivery-validation.json`; not included).
- Promotion plan and files (`work/audio/revision-realism/promotion-plan.json`; not included). Full backup: `work/audio/revision-realism/promotion-backups/20260921T171226464319Z-72651ee780f0/`. The V1 release is preserved in `revision-realism/before/reports/`.
- [Current Bible](AUDIO-BIBLE.md) and [reproduction catalog](../data/audio_events.json).

To update evidence: `python3 work/audio/measure_mix.py --playtest-dir work/audio/revision-realism/playtest/final` and `python3 work/audio/validate_assets.py --playtest-dir work/audio/revision-realism/playtest/final`. For other native capture, always use a new output directory.

The other characters' own bank of powers/reactions, Storm and the motives of other sections are still in the backlog. This hotfix fixes the existing package; does not present that backlog as produced.
