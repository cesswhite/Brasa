extends SceneTree
const Story = preload("res://scripts/story_catalog.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Balance = preload("res://scripts/balance.gd")
const Battle = preload("res://scripts/combat_engine.gd")
const Rules = preload("res://scripts/combat_rules.gd")
var checks: int = 0
var failures: int = 0

func _init() -> void:
	_test_catalog()
	_test_allocations()
	_test_boss()
	_test_resistance_evidence()
	_test_hints()
	print("STORY COMBAT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("STORY COMBAT FAIL: " + message)

func _player(id: String = "luma", level: int = 1, allocations: Dictionary = {}) -> Dictionary:
	var definition: Dictionary = Catalog.definition(id)
	var result: Dictionary = {"character_id": id, "name": definition.name, "archetype": definition.archetype, "level": level, "allocations": allocations, "stats": definition.training_base.duplicate(true)}
	result["combat_stats"] = Story.stats_for(result)
	return result

func _run(player: Dictionary, rival: Dictionary, seed_value: int = 84, delta: float = 60.0, options: Dictionary = {}) -> Dictionary:
	var engine = Battle.new()
	engine.start(player, rival, seed_value, options)
	while engine.running:
		engine.advance(delta)
	return engine.summary()

func _test_catalog() -> void:
	check(Story.stages().size() == 8, "Eight encounters")
	check(Story.stage(-1).is_empty() and Story.stage(8).is_empty() and Story.opponent(8).is_empty(), "Invalid stage never repeats boss")
	var seen: Array[String] = []
	for index: int in range(8):
		var stage: Dictionary = Story.stage(index)
		check(not str(stage.id) in seen, "Unique stage ID")
		seen.append(str(stage.id))
		check(str(stage.profile).length() > 10 and str(stage.strength).length() > 10 and str(stage.weakness).length() > 10, "Preview explains identity")
		check(stage.kind == ("elite" if index in [3, 6] else ("boss" if index == 7 else "normal")), "Elite and boss route")
		check(int(stage.xp_win) >= int(stage.xp_loss) * 3 and int(stage.xp_loss) > 0, "Wins substantially reward more; losses positive")
		var rival: Dictionary = Story.opponent(index)
		check(rival.story_stage_id == stage.id and int(rival.story_stage_index) == index, "Opponent carries immutable stage identity")
		check(not Catalog.definition(str(rival.character_id)).is_empty(), "Existing atlas/canonical identity")
		for key: String in Balance.STAT_BOUNDS:
			var bounds: Array = Balance.STAT_BOUNDS[key]
			check(float(rival.combat_stats[key]) >= float(bounds[0]) and float(rival.combat_stats[key]) <= float(bounds[1]), "Declared stats use global bounds")
		var engine = Battle.new()
		engine.start(_player(), rival, index + 41)
		check(engine.snapshot().fighters.rival.runtime_stats == rival.combat_stats, "No hidden story multiplier")
	var copy: Array[Dictionary] = Story.stages()
	copy[0].stat_overrides.attack = 1000
	check(float(Story.opponent(0).combat_stats.attack) < 1000, "Catalog returns independent copies")
	var boss: Dictionary = Story.boss_definition()
	check(boss.id == "ascua" and boss.name == "Ascua" and boss.ability.id == "phase_shift", "Unique boss identity and ability")
	check(Story.opponent(7).story_boss_id == "ascua", "Boss identity survives canonical atlas")
	var boss_stats: Dictionary = Story.opponent(7).combat_stats.duplicate(true)
	boss_stats.erase("interval")
	check(boss.base_stats == boss_stats, "Boss definition publishes actual declared stats")
	check(float(Balance.SIGNATURE.chance) == 0.01, "Boss shares one-percent signature chance")

func _test_allocations() -> void:
	check(Story.allocations().size() == 8, "Manageable independent eight allocations")
	for id: String in Catalog.IDS:
		var profile: Dictionary = _player(id)
		var baseline: Dictionary = Catalog.stats_for(profile)
		check(Story.stats_for(profile) == baseline, "Fresh story retains archetype stats: " + id)
		profile.stats = {"life": 30, "strength": 30, "agility": 30, "speed": 30}
		check(Story.stats_for(profile) == baseline, "League training cannot inflate campaign: " + id)
		profile.level = 10
		check(float(Story.stats_for(profile).max_hp) > float(baseline.max_hp), "Archetype natural growth preserved")
	for choice: Dictionary in Story.allocations():
		var base: Dictionary = Story.stats_for(_player())
		var invested: Dictionary = {choice.key: 1}
		var profile: Dictionary = _player("luma", 1, invested)
		var before: Dictionary = profile.duplicate(true)
		var result: Dictionary = Story.stats_for(profile)
		check(is_equal_approx(float(result[choice.key]) - float(base[choice.key]), float(choice.increment)), "One point has stated increment: " + str(choice.key))
		for key: String in Balance.STAT_BOUNDS:
			if key != choice.key:
				check(is_equal_approx(float(result[key]), float(base[key])), "Allocation does not silently improve other stat")
		check(profile == before, "Stat derivation leaves source untouched")
		profile.allocations[choice.key] = 100000
		var capped: Dictionary = Story.stats_for(profile)
		profile.allocations[choice.key] = int(Story.CONFIG.allocation_cap)
		check(Story.stats_for(profile) == capped, "Allocation count capped")
		profile.allocations[choice.key] = -10
		check(Story.stats_for(profile) == base, "Negative investment cannot lower base")
		profile.allocations[choice.key] = INF
		check(Story.stats_for(profile) == base, "Non-finite investment ignored")
	check(Story.stats_for({"character_id": "unknown", "allocations": "bad"}) == Story.stats_for({"character_id": "nima"}), "Invalid direct inputs safe")

func _test_boss() -> void:
	var boss: Dictionary = Story.opponent(7)
	var original: Dictionary = boss.duplicate(true)
	for ratio: float in [1.0, 0.601, 0.6, 0.301, 0.3, 0.1]:
		var engine = Battle.new()
		engine.start(_player(), boss, 451, {"disable_signatures": true, "initial_hp": {"rival": float(boss.combat_stats.max_hp) * ratio}})
		var runtime: Dictionary = engine.snapshot().fighters.rival.runtime_stats
		check(is_equal_approx(float(runtime.attack), float(boss.combat_stats.attack) * (1.08 if ratio <= 0.6 else 1.0)), "Boss attack phase threshold exact")
		check(is_equal_approx(float(runtime.speed), float(boss.combat_stats.speed) * (1.15 if ratio <= 0.3 else 1.0)), "Boss speed phase threshold exact")
		check(float(runtime.defense) == float(boss.combat_stats.defense) and float(runtime.max_hp) == float(boss.combat_stats.max_hp), "Phases only change declared stats")
		var events: Array[Dictionary] = engine.advance(0.01)
		check(events.size() == 1 and events[0].ability_id == "phase_shift" and events[0].message.contains("Ascua"), "Initial phase is explicit in log")
	check(boss == original, "Boss source is immutable")
	var trained: Dictionary = _player("mugo", 12, {"max_hp": 7, "attack": 9, "speed": 5, "accuracy": 3})
	var fast: Dictionary = _run(trained, boss, 7651, 60.0)
	var slow: Dictionary = _run(trained, boss, 7651, 0.017)
	check(fast == slow, "Boss including phases reproduces with different delta")
	var phase_indices: Array[int] = []
	for event: Dictionary in fast.events:
		if event.type == "ability" and str(event.get("ability_id", "")) == "phase_shift":
			phase_indices.append(int(event.phase_index))
	check(phase_indices == [0, 1, 2], "Natural damage announces each phase exactly once")
	check(int(fast.metrics.rival.healing) == 0, "Boss has no healing loop")
	check(float(fast.duration) <= 60.0 and fast.winner in ["player", "rival"], "Boss is terminal under ordinary timeout")
	var engine = Battle.new()
	engine.start(trained, boss, 1, {"opening_time": 2.0, "disable_signatures": true})
	engine.advance(0.5)
	var pending: float = float(engine._fighters.rival.next_action)
	engine._damage("rival", float(boss.combat_stats.max_hp) * 0.71, "player")
	check(float(engine._fighters.rival.next_action) < pending and float(engine._fighters.rival.next_action) > engine.elapsed, "Phase speed accelerates pending action without instant attack")
	var signature: Dictionary = _run(_player(), boss, 841, 60.0, {"force_signature": ["rival"], "signature_turn": 1, "initial_hp": {"player": 1.0}})
	check(signature.winner == "rival" and int(signature.metrics.rival.signatures) == 1, "Boss final blow can be its unique signature")
	var signature_hit: bool = false
	var signature_debuff: bool = false
	for event: Dictionary in signature.events:
		if event.type == "attack" and str(event.side) == "rival":
			signature_hit = event.result == "signature" and bool(event.signature)
		if event.type == "status_applied" and str(event.source) == "rival":
			signature_debuff = event.effect == "attack_down" and int(event.duration) >= 1
	check(signature_hit and signature_debuff, "Lethal boss signature hits and applies its legal debuff")
	engine.start(trained, boss, 777, {"force_signature": ["rival"], "initial_statuses": {"player": [{"type": "burn", "duration": 3, "magnitude": 4.0}]}})
	engine.advance(0.4)
	var surrendered: Array[Dictionary] = engine.surrender()
	var frozen: Dictionary = engine.snapshot()
	check(surrendered.back().type == "finished" and not engine.running, "Boss surrender is immediate")
	check(engine.advance(60.0).is_empty() and engine.surrender().is_empty() and engine.snapshot() == frozen, "No phase/signature/DoT/actions after surrender")
	var capped_boss: Dictionary = boss.duplicate(true)
	capped_boss.combat_stats.attack = 150.0
	capped_boss.combat_stats.speed = 36.0
	engine.start(trained, capped_boss, 765, {"initial_hp": {"rival": 100.0}})
	check(engine.snapshot().fighters.rival.runtime_stats.attack == 150.0 and engine.snapshot().fighters.rival.runtime_stats.speed == 36.0, "Boss phases obey shared stat caps")
	engine.start(trained, boss, 877, {"disable_signatures": true, "initial_hp": {"rival": 100.0}, "initial_statuses": {"rival": [{"type": "slow", "magnitude": 0.25, "duration": 3}, {"type": "attack_down", "magnitude": 0.18, "duration": 3}]}})
	var weakened: Dictionary = engine.snapshot().fighters.rival.runtime_stats
	check(is_equal_approx(float(weakened.speed), float(boss.combat_stats.speed) * 1.15 * 0.75), "Slow still affects final boss phase")
	check(is_equal_approx(float(weakened.attack), float(boss.combat_stats.attack) * 1.08 * 0.82), "Attack debuff still affects final boss phase")
	var poison: Dictionary = {"type": "poison", "magnitude": 4.0, "duration": 3}
	var double_dot: Dictionary = _run(trained, boss, 772, 60.0, {"disable_signatures": true, "opening_time": 2.0, "initial_hp": {"player": 1.0, "rival": 1.0}, "initial_statuses": {"player": [poison], "rival": [poison]}})
	check(double_dot.reason == "dot" and double_dot.duration == 2.0, "Simultaneous DoT still terminates boss battle")
	check(int(double_dot.metrics.player.attacks) == 0 and int(double_dot.metrics.rival.attacks) == 0, "No attack or phase protection after simultaneous lethal DoT")

func _test_resistance_evidence() -> void:
	var target: Dictionary = _player()
	target.combat_stats.resistance = 0.5
	var engine = Battle.new()
	engine.start(_player("iria"), target, 91, {"disable_signatures": true})
	var spec: Dictionary = {"type": "poison", "magnitude": 3.0, "duration": 5}
	var rng := RandomNumberGenerator.new()
	var expected_prevented: int = 0
	var expected_shortened: int = 0
	for seed_value: int in range(1, 101):
		rng.seed = seed_value
		var roll: float = rng.randf()
		engine._rng.seed = seed_value
		var events: Array[Dictionary] = []
		var applied: bool = engine._apply_status("rival", "player", spec, 0.4, false, events)
		var resistance_only: bool = roll < 0.4 and roll >= Rules.status_chance(0.4, 0.5)
		if resistance_only: expected_prevented += 1
		if applied: expected_shortened += 5 - Rules.status_duration(5, 0.5)
		check(events.size() == 1 if applied or resistance_only else events.is_empty(), "Only real resistance prevention produces evidence")
		check(engine._rng.state == rng.state, "Resistance evidence consumes no extra RNG")
	check(int(engine._metrics.rival.statuses_prevented) == expected_prevented and expected_prevented > 0, "Prevention metric separates ordinary proc failures")
	check(int(engine._metrics.rival.status_turns_resisted) == expected_shortened, "Resistance-shortened turns accurately counted")

func _test_hints() -> void:
	check(Story.defeat_hint({}).is_empty() and Story.defeat_hint({"winner": "player"}).is_empty(), "No defeat advice after victory")
	check(Story.defeat_hint({"winner": "rival", "reason": "surrender"}).contains("progreso"), "Surrender hint is appropriate")
	var sample: Dictionary = {"winner": "rival", "metrics": {"player": {"attacks": 12, "misses": 5}, "rival": {}}}
	check(Story.defeat_hint(sample).contains("5 de 12"), "Miss hint cites real counts")
	sample.metrics.player = {"attacks": 10, "misses": 0, "turns_survived": 10}
	sample.metrics.rival = {"turns_survived": 14}
	check(Story.defeat_hint(sample).contains("14 veces"), "Speed hint uses actual actions")
	sample.metrics.rival = {"statuses_prevented": 3}
	check(Story.defeat_hint(sample).contains("redujo tus efectos"), "Resistance hint requires explicit evidence")
	sample.metrics.rival = {}
	check(not Story.defeat_hint(sample).contains("redujo tus efectos"), "No invented resistance claim from normal failed procs")
	sample.metrics.player.damage_taken = 180
	sample.events = [{"type": "status_tick", "target": "player", "damage": 35}]
	check(Story.defeat_hint(sample).contains("35 PV"), "Status hint cites logged damage")
	sample.events = []
	sample.metrics.player.damage_taken = 250
	sample.metrics.rival.hits = 6
	check(Story.defeat_hint(sample).contains("defensa o vida"), "Heavy real impacts trigger survival hint")
	var before: Dictionary = sample.duplicate(true)
	Story.defeat_hint(sample)
	check(sample == before, "Hint does not mutate battle summary")
