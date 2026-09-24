Arena: turn and impact effects without rings

The focus of the shift uses two diffuse pigment spots, low and slightly off-center, using ParticleInk.mote. It retains the small rhombus to distinguish the shift also by shape. The impact leaves only the existing particles, drawn as soft little sparks with ParticleInk.spark; no longer creates or draws the expanding ring.

Reduced Motion clears the particles and updates the shift focus immediately, with static light and diamond. The visual clock does not advance. The backgrounds, their perspective transformation, lanterns, stars and decoration were not changed.

Checks: arena_view.gd parser no errors; test_battle_layout.gd passed 2139 checks, 0 failures, in seven sizes and idle/combat/result states. The test uses its isolated routes within work/immersive; Production Main was not opened and no assets were imported.

Exact previous copy: arena-before.gd. Diff: arena-changes.patch. Log: test_battle_layout.log.
