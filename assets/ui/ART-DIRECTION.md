# Brasa · surfaces and places of Story Mode

2D digital painting with brush texture, worn materials and legible silhouettes. Warm light from lanterns, petrol blue shadows, stone/ocher/copper, wood and fabrics. The initial Route looks towards the lantern path; Storm uses roots, iron, moss and wet rock. Workshop, shelter and archive are different places within the same world.

All five backgrounds contain empty space useful for native controls and characters. They are not full screens. Current sprites are drawn separately and retain their name, appearance, and animation. Numbers, XP, chapters, recommendations and tags are still Godot text.

`shared/surfaces-v1.png` contains eight isolated surfaces: two buttons, two frames, three medallions, and a separator. `shared/props-v1.png` contains six items: Tepa's blue uniform and yellow belt, Balam's jade bandages, Ascua's brazier, storm relic, used backpack, and Arena medal. Actual regions, not an assumed grid, are used to avoid clipping objects.

The `data/ui_visual_manifest.json` record defines contexts, styles, regions and decoration conditions. Its objects are decorative, not controls, not achievement checks, and not progression logic. Funds are loaded on demand. The surface atlas is scaled once by Godot and reused.

Seven images were generated with the built-in tool `image_gen`, preserving the original PNGs and alpha channel. The tool did not offer explicit “2.5” selector; it was not changed to an API or CLI. The complete prompts, destinations and hashes are in [GENERATION-PROMPTS.json](GENERATION-PROMPTS.json).

Implementation sources: [StyleBoxTexture / nine-patch](https://docs.godotengine.org/en/4.6/classes/class_styleboxtexture.html). The behavior is also validated with Godot 4.7.2 installed and native captures.
