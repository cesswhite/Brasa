# Ascua: edges and separation of fighters

The two defects pointed out in the user screenshots were corrected. The previous visual approval did not detect them; Its historical evidence is preserved and this revision is added.

| Before | After |
| --- | --- |
| White line on corrupted variants of Ascua | Background debris removed from all four damage banks, 56 poses |
| Separation based only on centers | Each silhouette respects a common line of contact, including its rotation and the fallen pose |
| Long KO under the feet of the winner | The figure moves to its own side without moving the combat origin |

Cleaning uses user prior authorization to remove funds via code. Only the transparency outline changes: the interior, canvas, anatomy, pivot and scale are preserved. The character was not regenerated. The PNGs above are in `work/edge-spacing-fix/before/`.

The separation applies to Main and online/local replays. The framing is common for the two characters and stable due to screen size. Pose adjustment is a visual translation, never a change in size, statistic, motor range, or result. Shadows and attached effects follow the corrected figure. The actual rectangle of the corrupted variants is read from their metadata.

The old moving check on a generic rectangle of 166 units has been replaced with a check on the canonical painted height. The first camera reservation was excessive; was reduced after measuring all sequences. Mobile captures were reviewed with figures and separation space visible.

Validation: 23 bodies, both orientations, seven sizes, attacks and reactions, victory and KO; 185472 limits and stability checks without failures. Regression: Battle Layout 2139/0, Replay 821/0, Visual Continuity 2215/0, Animation 1288/0, Damage/Families 128/0, and Audio Replay 44/0. The captures are fixtures without games or personal accounts.

Fixed Victory and KO (`work/edge-spacing-fix/native/1360x780-victory-ko.png`; not included) · Fixed Attack (`work/edge-spacing-fix/native/1360x780-attack.png`; not included) · Mobile (`work/edge-spacing-fix/native/390x844-attack.png`; not included) · Edge Comparison (`work/edge-spacing-fix/edge-comparison.png`; not included).

Changes only to the client and its assets; They do not require Cloudflare modifications. Already opened game instances need to be restarted to load new textures and scripts.
