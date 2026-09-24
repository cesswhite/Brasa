# Focus and performance of Brasa

21 September 2026 Godot 4.7.2 Apple M1 Max

The outer focus contour that was cropped is eliminated and repeated work in animation, interface and presentation is reduced. The art of the frames preserves its painted material. Keyboard navigation retains a visible sign within the control.

| Area | Before | After |
| --- | --- | --- |
| Control focus | Light stroke expanded out of control, susceptible to clipping | Interior amber fill at 22%, retracted 4 px; no border. Shared by buttons, fields, selectors and tabs. Thickness token updated to zero. |
| Theme and materials | Deep copies of the entire log for small internal queries | Internal reading of cached record; public APIs still return defensive copies. |
| injured sprites | File queries and bank copies during each update | Validation when preparing for combat, bounded bank cache, copy of the necessary frame and reuse of the result while not changing the pose or damage level. |
| Textures and health | Intermediate healthy texture and recalculations for the same health | Single final assignment; Identical health updates end immediately. Explicit resolution calls continue to refresh the metadata. |
| combat HUD | Reconstruction of health, states and turns each frame | Update when combat produces events; independent clock. |
| Character lists | Cropped portraits continued to come alive | They are suspended when leaving the visible area and resumed when returning. |
| Hidden Arena | Animation and drawing under full opaque screens | Arena suspended and hidden while covered; It is restored upon closing. It is preserved during transitions and translucent dialogues. |
| Audio | Repeated pause and mix assignments | Pause and fade changes applied only when they change; Volume adjustments remain immediate. |
| Effects | Redrawn even without particles or active camera | Rest when there are no effects, pending markers or shake. The last cleaning redraw is preserved. |

## CPU measurement

Same program, hot caches, disposable profiles, headless execution. Medium; These figures do not measure FPS, GPU or the total time of a frame. They do not imply that the entire game is fifteen times faster.

| Operation | Before | After | Reduction |
| --- | ---: | ---: | ---: |
| Upgrade two wounded fighters | 392 µs | 26 µs | 93,4% |
| Build and style 100 buttons | 75,48 ms | 4,87 ms | 93,6% |
| Refresh the combat HUD | 56 µs | 28 µs | 50% |

Repeating the same health went from 382 µs to less than 1 µs on average; the median falls below the timer resolution. 1.200 animation and health samples, 20 button batches, and 1.000 HUD refreshments were measured.

Previous data (`work/performance-ui/baseline.json`; not included) · Post data (`work/performance-ui/after.json`; not included) · Measurement program (`work/performance-ui/benchmark.gd`; not included)

## Validation

24 suites passed, covering combat, contact, move clock, sequences, illustrated damage, effects, audio/pause, identity, story, customization, companions, theme and shelters. The new efficiency test verifies borderless focus, shared data protection, portrait pause/resume, and sand coverage.

The first run found overly aggressive overriding when editing sockets with the same texture; fixed by retaining the explicit refresh. The consistency suite passed again: 2.213 checks without failures. The original results and the final consolidation are kept separately.

Native auditing: 143 checks without failures, 74 captures (37 surfaces on desktop and mobile). Reviewed both visual walls and individual screenshots of Adjustments and Redistribute improvements. FPS was not measured in a long interactive session.

Final Results (`work/performance-ui/checks/final-results.json`; not included) · Desktop (`work/performance-ui/screens/wall-1360x880.png`; not included) · Mobile (`work/performance-ui/screens/wall-390x844.png`; not included)

Comparing scripts with the previous backup limits changes to ten presentation files and their caches. No combat rules, progression, user saves, backend or sprites were edited. Explicit preparation of damage banks remains the point of validation of file changes during a development session.
