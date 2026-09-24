# Brasa · Scale, transparency and localized damage

Updated 21 September 2026. Integrated corrections in the resources that the game loads.

[Report index](README.md) · Verification of production PNGs (`work/sprite-precision/verification-production.json`; not included) · Native captures (`work/sprite-precision/native`; not included)

## Review 2 · More visible wounds

The previous revision protected the color, but ruled out damage to the face and clothing by grouping them in too large regions. Compact areas within these regions are now selected and the local contrast of the abrasions, bruises and tears already illustrated is reinforced. A global filter is not added to the character.

Updated only 69 wounded atlases and their metadata. Healthy 69 atlases exactly retain their hashes from the previous revision. In 920 pairs, the alpha remains identical and the pixels outside the wounds are exactly preserved. The modified surface median is 12.12%; the maximum is 21.43%. The reinforcement is in the legibility of the marks, not in tinting a larger surface.

The interactive comparison now shows **healthy / injured from revision 1 / injured reinforced**. Revision 1 is preserved in `work/sprite-precision/revisions/v1/damage`.

Repeated validation after this update: 1,840 error-free frames; 14,985 damage checks without failures; 40,882 contact checks without failures; 3,832 native render checks without errors, with 39 new captures. The six general sheets and the native captures of Nima, Luma and Taro Roque were reviewed. Screenshots from this review (`work/sprite-precision/native-v2`; not included).

The remaining checks in the table below correspond to the first review. This update does not change the logic, ladders, games or progression rules.

## Result

23 bodies, including bosses and family appearances; 40 poses by body, with healthy and injured versions: **1,840 frames in 138 RGBA atlas**. Each cell retains 512 × 512 px, the origin (256, 448), and the density of 1.5 pixels per game unit.

The injured version of each pose now uses the exact geometry of the healthy version. **The alpha channel is identical on 920 pairs**, so taking damage cannot shrink or widen the drawing. Outside of local damage zones, RGBA values ​​are identical pixel-for-pixel: no global tint, desaturation, exposure, or opacity is applied for being injured.

The damage preserves details from previous wounded illustrations: they are recorded over their healthy pose, wide lighting variations are separated, and only local details of bumps, abrasions, and breaks are transferred. The result is painted on the PNGs. No wear shader or new floating layer is added at runtime. Damage levels, progression, and combat rules do not change.

## Scale and color between groups

Each set of poses is calibrated against its own character's original guard, with a uniform transformation around the ground point. The height of a crouched pose, a fall, or a jump is not forced to that of a standing pose. Volume differences between characters are preserved.

For example, Cora's guard in reactions measured 307 px compared to the 267 px of his original guard; now measures 267 px. That of Taro Sabio changes from 296 to 276 px. Also fixes lowering of Ónix in reactions. Breathing poses align with your guard.

The tones of each healthy group are calibrated using corresponding patches of their reference pose, preserving the textures. This adjustment is independent of damage: the healthy and injured versions receive exactly the same base calibration.

The correction is not equivalent to anatomically redrawing all the limbs of each pose. The drawings preserve their original gestures, foreshortenings and artistic variations; Correspondence analysis is not presented as an anatomical certification. The exact guarantees are healthy/wounded geometry, preservation of intact areas and real transparency.

## Transparency and provenance

- PNG with real alpha channel and completely transparent outer edges of each cell.
- Scale interpolation with premultiplied color to avoid resampling halos.
- Conservative cleaning of the neutral white border; The interior drawing is preserved and the silhouette is not eroded.
- The spawn test that returned a painted grid was discarded and never made into the game.
- Originals of all atlases and metadata preserved in `work/sprite-precision/originals`.
- Transformations, hashes and damage regions recorded in `work/sprite-precision`; updated metadata and manifest.
- Existing anatomical annotations are transformed with the drawing. The injured versions inherit only the annotations that the healthy pose already had, whose geometry they share.

## Validation

| Check | Result |
| --- | --- |
| RGBA, outer transparency, limits, hashes, alpha equality and keeping out of harm | 1,840 pictures; 0 errors |
| Full Illustrated Damage, Health Transition, Identity, and View Limits | 14,985 checks; 0 faults |
| Contact between fighters and continuity of the blow/KO | 40,882 checks; 0 faults; 1,933 cases |
| Native render of the 23 bodies | 3,832 checks; 0 faults; 39 PNG |
| Geometry, annotations and visual consistency | 2,213 checks; 0 faults |
| Families and damage states | 128 checks; 0 faults |

The six cast slides and representative native captures of Nima and Cora were inspected. 39 screenshots are available; no individual human review of the 1,840 illustrations is claimed.

Updated the touch test to check for shared annotations on the same geometry instead of rough projections onto another drawing. Also fixed an annotations fixture to refresh its render box after injecting a sample. It was not necessary to change the game logic.

The interactive viewer has local bindings and syntax checked. The built-in browser policy prevented it from opening automatically; Your interactions could not be verified with browser automation in this session. It can be opened manually from the link.

The tests use throwaway scenes; They do not open user games or write to the backend. If the game was open, you must close it and open it to discard the textures it keeps in memory.
