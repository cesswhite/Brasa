# Brasa — audio asset technical review

Generated: 2026-09-21T17:16:36.978072+00:00.

**Technical measurements; human listening review pending.** This report does not claim that the takes are approved through listening, that they do not contain accidental speech, or that the timbre/mix is ​​appropriate.

## Actual Godot mix demo

Selected playtest: `work/audio/revision-realism/playtest/final`.

The original delivery included a Master demo (47.371 s). The audio is excluded from this public edition.

It is a native capture of the Master bus using AudioEffectRecord, exported to MP3 for delivery. It is not a new synthesis nor a montage of results. The two test runs retain their actual outcome; The delivery demo is one audio file, not two tracks concatenated.

Playtest evidence: **23 checks, 0 failures**. Identical event hash between runs: **yes**. This verifies the combat record, not that the waveforms are identical.

| Take | Combat(s) | Actual run time (s) | Integrated LUFS | True peak (dBTP) |
| --- | ---: | ---: | ---: | ---: |
| Normal · Settings pause | 44.086 | 47.784 | -26.5 | -6.4 |
| Reduced movement | 44.086 | 46.899 | -26.5 | -6.9 |

LUFS and true peak are taken from the existing FFmpeg summary of each **WAV Master**, not from the delivery MP3 or from a human listen. Running time includes presentation/break; it does not replace the decoded duration of the file.

Registered fixture: `Real Mugo20 vs Ascua12, force_signature=rival turn2 only in this tool; no balance or production probability change`. The signature is enforced only on this proof; it does not change the probability of production or the balance.

**Listening pending:** recording, measuring and passing tests does not certify timbre, intelligibility, subjective balance or musical quality.

The original development gallery allowed offline comparison of variants. Its individual players did not simulate buses; the Master demo recorded the actual mix. That gallery and the audio are excluded from the public edition. The validator does not modify sources or production assets.

Coverage: **51 metered destinations**, integrated 51, 51 variants provided in 22 groups. 0 are missing expected destinations. There are 0 files with technical errors and 0 with flags to review.

The generation can continue: Missing is not a formatting error. Generated means that the ledger declares a take; Measured adds measurement of the final destination. Pendinglisten is independent: measuring does not equal listening.

## Method and limits

- ffprobe identifies the first audio stream; ffmpeg/astats measures decoded samples per channel, duration, sample peak, RMS and residual mean/DC.
- In variants, peak/RMS are dBFS, not LUFS or true peak; Master metrics are documented separately. No hard threshold is applied to the RMS: different gestures have different envelopes. The spread between variants is shown for a controlled auditory comparison.
- A residual mean from a short transient may be waveform asymmetry. Between 0,001 and 0,01 is informational; above 0,01 calls for review, does not prove an audible defect.
- A shortened gesture may last less than the prompt. It is not rejected because of that difference. OGG compression should not be confused with shortening a gesture or changing timing.
- Each embedded loop is decoded from the final file, including OGG. The last→first sample difference, the relationship with close derivatives and RMS of the first/last 250 ms are measured. The warnings are heuristic: they do not check tempo, musical structure, or a perceptually perfect union.
- Only local destinations are opened under outputs/Brasa/assets/audio. SHA-256 is checked against the ledger, plus size/date/hash changes during measurement. No URLs are read and nothing is normalized, cropped or re-encoded.

Plan Snapshot: `a2ff97f1cd07249acf638394b106026bf31137b2fb27758338353eaf33a81d9c`. Ledger snapshot: `1bafa52f7e2e77ea8e0710a6ebbe32b8819f0b648d36d1b45f62a80ae9e71b01`.
Entries changed while validating: **no**.

Complete data: `work/audio/asset-validation.json`. Repeat with `python3 work/audio/validate_assets.py --playtest-dir RUTA` for the folder indicated in the Master evidence.

## Status by group

| Group | Integrated / planned | Measurements | Peak dBFS | RMS dBFS | Status |
| --- | ---: | ---: | --- | --- | --- |
| Light Strike (`impact_light`) | 2 / 2 | 2 | -3.0…-3.0 | -27.5…-24.3 | Generated, Measured, Pending Listen |
| Heavy Strike (`impact_heavy`) | 4 / 4 | 4 | -3.0…-3.0 | -23.9…-19.5 | Generated, Measured, Pending Listen |
| Critical accent (`critical_accent`) | 1 / 1 | 1 | -3.0…-3.0 | -23.8…-23.8 | Generated, Measured, Pending Listen |
| Defended contact (`guard`) | 1 / 1 | 1 | -3.0…-3.0 | -17.3…-17.3 | Generated, Measured, Pending Listen |
| Dodge (`dodge`) | 4 / 4 | 4 | -3.0…-3.0 | -21.7…-18.1 | Generated, Measured, Pending Listen |
| Fast Air (`whoosh_quick`) | 2 / 2 | 2 | -3.0…-3.0 | -17.5…-13.9 | Generated, Measured, Pending Listen |
| Heavy Air (`whoosh_heavy`) | 3 / 3 | 3 | -3.0…-3.0 | -18.1…-15.9 | Generated, Measured, Pending Listen |
| Ground Footprint (`footstep_earth`) | 1 / 1 | 1 | -3.0…-3.0 | -24.0…-24.0 | Generated, Measured, Pending Listen |
| Landslide (`slide_earth`) | 1 / 1 | 1 | -3.0…-3.0 | -19.2…-19.2 | Generated, Measured, Pending Listen |
| Ground landing (`landing_earth`) | 4 / 4 | 4 | -3.0…-3.0 | -23.1…-18.8 | Generated, Measured, Pending Listen |
| Ascua · preparation (`ascua_charge`) | 4 / 4 | 4 | -3.0…-3.0 | -26.4…-20.0 | Generated, Measured, Pending Listen |
| Ascua release (`ascua_release`) | 3 / 3 | 3 | -3.0…-3.0 | -18.2…-15.4 | Generated, Measured, Pending Listen |
| Ascua · phase change (`ascua_transform`) | 3 / 3 | 3 | -3.0…-3.0 | -30.3…-19.6 | Generated, Measured, Pending Listen |
| Ascua · reaction (`ascua_reaction`) | 3 / 3 | 3 | -3.0…-3.0 | -19.4…-18.9 | Generated, Measured, Pending Listen |
| Final Fall (`ko_ground`) | 3 / 3 | 3 | -3.0…-3.0 | -27.6…-24.3 | Generated, Measured, Pending Listen |
| Confirmation (`ui_confirm`) | 4 / 4 | 4 | -3.0…-3.0 | -30.3…-24.9 | Generated, Measured, Pending Listen |
| Combat Start (`fight_intro`) | 1 / 1 | 1 | -3.0…-3.0 | -19.6…-19.6 | Generated, Measured, Pending Listen |
| Victory (`victory`) | 2 / 2 | 2 | -3.0…-3.0 | -20.9…-20.7 | Generated, Measured, Pending Listen |
| Defeat (`defeat`) | 2 / 2 | 2 | -3.0…-3.0 | -19.4…-18.4 | Generated, Measured, Pending Listen |
| Lanterns · atmosphere (`faroles_ambience`) | 1 / 1 | 1 | -3.0…-3.0 | -25.5…-25.5 | Generated, Measured, Pending Listen |
| Lanterns · music (`faroles_music`) | 1 / 1 | 1 | -3.5…-3.5 | -24.6…-24.6 | Generated, Measured, Pending Listen |
| Ascua · signature (`ascua_signature`) | 1 / 1 | 1 | -3.0…-3.0 | -16.2…-16.2 | Generated, Measured, Pending Listen |

## Technical findings

No technical errors or revision indicators were detected in the available destinations. Listening is still pending.

## Listen what's missing

Compare the variants with the same player settings; check material and character, single gesture, accidental voice/music, useful transient, tail, repetition rate and clarity. In music/ambience, listen to at least two turns of the loop and its entry/exit. Then check in the actual Godot mix: the page does not play buses, ducking, priorities or game concurrency.

This validator does not create narration or montage reel: it links the integrated shots and, when it exists, the Master demo previously registered by Godot.
