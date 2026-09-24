extends SceneTree
const Damage = preload("res://scripts/visual_damage_state.gd")
const Fighter = preload("res://scripts/fighter_view.gd")
const Families = preload("res://scripts/character_families.gd")
const Cosmetics = preload("res://scripts/cosmetic_catalog.gd")
const Story = preload("res://scripts/story_catalog.gd")
const Animations = preload("res://scripts/fighter_animation_set.gd")
var checks := 0
var failures := 0
func _init() -> void: run.call_deferred()
func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(label)
func run() -> void:
	var state := Damage.new(); state.configure("ascua")
	state.observe_health(0.65);state.advance(0.12, true)
	check(state.tier == 0 and state.target_tier == 1, "wear waits for hit reaction")
	state.advance(0.3, false);check(state.tier == 1, "worn follows hit")
	state.observe_health(0.39);state.advance(1, false);check(state.tier == 2, "damaged threshold")
	state.observe_health(0.9);state.advance(1, false);check(state.tier == 2, "healing does not restore torn cloth")
	state.observe_health(0);state.advance(0.1, true, true);check(state.tier == 3, "KO preserves critical wear")
	state.reset();check(state.tier == 0 and state.intensity == 0, "new battle resets transient damage")
	state.observe_health(NAN);check(state.target_tier == 0, "invalid health cannot stain character")
	for n: int in range(12):
		state.observe_health(0.65-float(n)*0.01);state.advance(0.1,true)
	check(state.tier == 1,"repeated hits cannot starve pending wear")
	state.observe_event({"presentation":{"hit_reaction":"knockdown"}})
	check(state.damage_type == "ground","ground damage reads nested presentation")
	for body: String in Damage.catalog().profiles:
		state.configure(body);check(not state.profile.is_empty() and not state.profile.blood_allowed, "material profile " + body)
	var owned := Cosmetics.default_owned()
	for id: String in Families.individuals():
		var entry := Families.individual(id)
		var look := Cosmetics.default_appearance(str(entry.base));look.body_style_id = id
		check(not Cosmetics.validate_appearance(look, owned, str(entry.base)).ok, "locked appearance rejected " + id)
		var unlocked := owned.duplicate();unlocked.append("body_style:" + id)
		check(Cosmetics.validate_appearance(look, unlocked, str(entry.base)).ok, "owned appearance accepted " + id)
		var definition := Cosmetics.body_definition(id)
		check(str(definition.id) == str(entry.base), "appearance keeps combat archetype " + id)
		var level := int(entry.story_introduction)
		var chapter := Story.chapter_for_level(level)
		var npc := Story.opponent(level - int(Story.chapter(chapter).start_level), chapter)
		check(npc.get("individual_id") == id and npc.appearance.body_style_id == id, "discovery precedes earned unlock " + id)
		var actor := Fighter.new();root.add_child(actor);actor.setup_character({"character_id":entry.base,"appearance":look});actor.set_process(false)
		check(actor._sequence_body == id, "individual runtime body " + id)
		for bank: String in ["base", "movement", "reactions"]:
			var pack := Animations.normalized_pack(id, bank)
			check(not pack.is_empty(), "complete animation bank " + id + "/" + bank)
		actor.set_health_ratio(0.1);actor._process(1.0)
		check(actor.damage_state.tier == 3, "individual receives critical damage")
		actor.play_move({"id":"fixture", "animation":"charge", "windup":0.3,"travel":0.2,"recovery":0.3})
		actor._process(0.4);check(actor.damage_state.tier == 3 and actor._sequence_body == id, "charge retains damaged identity")
		actor.fall();actor._process(1.0);check(actor.damage_state.tier == 3 and actor.get_animation_state().frame == "grounded", "damaged individual KO")
		actor.reset_pose();check(actor.damage_state.tier == 0, "next battle clean")
		actor.free()
	var boss := Story.boss_definition(1)
	var ascua := Fighter.new();root.add_child(ascua);ascua.setup_character(boss);ascua.set_process(false)
	ascua.set_health_ratio(0.1);ascua._process(1.0)
	check(ascua._sprite.texture is AtlasTexture and str(ascua._sprite.texture.atlas.resource_path).contains("/damage/"), "pilot loads baked critical cloth")
	ascua.motion_paused=true
	var frozen: Dictionary=ascua.damage_state.snapshot()
	ascua._process(2.0);check(ascua.damage_state.snapshot()==frozen,"pause freezes visual damage")
	ascua.motion_paused=false
	for kind: String in ["quick","heavy","charge","dash","jump"]:
		ascua.play_move({"id":"damage-fixture-"+kind,"animation_type":kind,"windup":0.3,"travel":0.2,"recovery":0.3})
		for time: float in [0.0,0.31,0.52,0.76]:
			ascua._action_time=time;ascua._update_pose()
			check(str(ascua._sprite.texture.atlas.resource_path).contains("/damage/illustrated-v2/ascua-") and bool(ascua.get_animation_state().damage_art),"illustrated art persists during "+kind)
		ascua._process(1.0)
	ascua.play_transformation("ember_core");ascua._process(1.0)
	check(ascua.damage_state.tier == 3 and ascua._form_id == "ember_core", "transformation keeps wear")
	ascua.resolve_battle(true);ascua._process(1.0);check(ascua.damage_state.tier == 3, "result keeps final wear")
	ascua.free()
	print("DAMAGE/FAMILIES: %d checks, %d failures" % [checks, failures]);quit(1 if failures else 0)
