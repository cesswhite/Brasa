# Art by Brasa

The characters also use generated illustrations: three transparent sheets of eight poses each. See [sprites/PROMPTS.md](sprites/PROMPTS.md) for complete files and prompts.

## Courtyard of Lanterns — illustrated version

- File: `arena-faroles-v2.png`.
- Original image created for this project on September 20 2026.
- Build: ChatGPT built-in imaging tool (`image_gen`), no external API or CLI.
- The tool does not expose a verifiable model selector or identifier. Therefore, this image is not attributed to the name “ChatGPT Image 2.5”.
- Original resolution: 2172 × 724 pixels. Godot adapts it to the arena of 1264 × 414; the original illustration has not been cropped or overwritten.
- Fighters, impact effects, specks and light halos are drawn separately in real time. A soft dark layer maintains the readability of the HUD.
- The original procedural version is still included as a backup when the texture is missing.

## Prompt used

```text
Use case: stylized-concept.
Asset type: production background plate for an original 2D side-view auto battler, Brasa: Liga de los Faroles.
Create one beautiful, polished panoramic landscape illustration, approximately 3:1 aspect ratio, ideally 3072 x 1024. Full-bleed image, no frame, no lettering, no logo, no interface, no characters or creatures.
Scene: a magical desert town's night-market fighting courtyard under a deep blue-teal night sky. Original stepped adobe towers and rounded archways on the far left and far right, warm golden lamps in small windows, distant layered mountains, a delicate crescent moon. Market stalls with muted terracotta and sage-striped canopies on the outer edges. Carefully placed hanging amber lantern strings and a few fabric pennants frame the edges. A broad circular terracotta sand arena with a low stone rim fills the lower third of the picture, shown as a wide horizontal ellipse; its far edge at about 69% height, its center at 83% height, its near rim at 96% height. The central 40% of the width must remain uncluttered so game combatants can stand there with feet at 84% image height. A subtle faded sun motif engraved on the sand, very low contrast.
Composition: fixed side-view gameplay camera, very mild downward view of the floor, spacious and level. Keep top 27% dark and visually quiet for overlaid health bars and names, especially the top left and top right. Keep central midground at 42–69% height low-contrast dark teal to make warm-colored cartoon fighters readable. Detail and bright illumination belong on the outer quarters, not the fight area. Buildings should frame the arena rather than block it.
Art direction: handcrafted storybook game environment, refined gouache and cut-paper illustration, clear broad shapes with restrained dark outlines, matte textures and subtle grain, rich atmospheric depth, charming and cozy, professional indie game art. Match a palette of deep ink #102b30, desaturated teal #365a5e, amber #efb66f, warm sand #b17c58, soft sage and terracotta. The floor is warm and clearly readable, environment cool; lighting from lanterns is soft and restrained.
Constraints: entirely original visual world. No UI, no letters, no text, no watermark, no combatants, no figures, no huge foreground objects, no dramatic perspective tilt, no photorealism, no glossy 3D, no dense visual clutter. This must work as a real game backdrop.
```
