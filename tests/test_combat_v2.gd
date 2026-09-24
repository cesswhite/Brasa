extends SceneTree
const Battle = preload("res://scripts/combat_engine.gd")
const Rules = preload("res://scripts/combat_rules.gd")
const Effects = preload("res://scripts/status_effects.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Balance = preload("res://scripts/balance.gd")
var checks: int = 0
var failures: int = 0

func _init() -> void:
	_test_rules()
	_test_effects()
	_test_reproducibility()
	_test_slow_scheduler()
	_test_terminal_cases()
	_test_signatures()
	_test_abilities()
	print("COMBAT V2: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("COMBAT FAIL: " + message)

func fighter(id: String = "luma", level: int = 1) -> Dictionary:
	var definition: Dictionary = Catalog.definition(id)
	var profile: Dictionary = {"character_id": id, "level": level, "name": definition.name, "stats": definition.training_base.duplicate(true)}
	profile["combat_stats"] = Catalog.stats_for(profile)
	return profile

func simulate(player: Dictionary, rival: Dictionary, seed_value: int = 51, step: float = 60.0, options: Dictionary = {}) -> Dictionary:
	var engine = Battle.new()
	engine.start(player, rival, seed_value, options)
	while engine.running:
		engine.advance(step)
	return engine.summary()

func _test_rules() -> void:
	check(is_equal_approx(Rules.hit_chance({"accuracy": 2.0}, {"evasion": 0.0}), float(Balance.COMBAT.hit_max)), "Accuracy never certain")
	check(is_equal_approx(Rules.hit_chance({"accuracy": -1.0}, {"evasion": 1.0}), float(Balance.COMBAT.hit_min)), "Evasion never makes attacks impossible")
	check(Rules.critical_chance({"crit_chance": 8.0}) == float(Balance.COMBAT.crit_max), "Crit global cap")
	check(Rules.critical_chance({"crit_chance": -8.0}) == float(Balance.COMBAT.crit_min), "Crit global minimum")
	check(Rules.damage_preview({"attack": -80.0}, {"defense": 200.0}) == 1.0, "Negative attack never heals or produces negative damage")
	check(Rules.damage_preview({"attack": 0.0}, {"defense": 0.0}) == 1.0, "Zero attack has minimum damage")
	check(Rules.damage_preview({"attack": 22.0}, {"defense": 100.0}) < Rules.damage_preview({"attack": 22.0}, {"defense": 20.0}), "Defense reduces damage")
	check(Rules.damage_preview({"attack": 22.0}, {"defense": 20.0}, 8, 1) > Rules.damage_preview({"attack": 22.0}, {"defense": 20.0}, 1, 1), "Bounded level scaling")
	check(Rules.status_chance(0.4, 0.5) < Rules.status_chance(0.4, 0.0), "Resistance reduces status chance")
	check(Rules.status_duration(5, 0.5) < Rules.status_duration(5, 0.0), "Resistance shortens duration")
	check(Rules.status_duration(1, 1.0) == 1, "Guaranteed signature keeps at least one turn")
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var base: Dictionary = fighter().combat_stats
	var preview: float = Rules.damage_preview(base, base)
	for index: int in range(100):
		var roll: Dictionary = Rules.roll_attack(base, base, rng, {"signature": true, "modifier": 1.6})
		check(roll.result == "signature" and not bool(roll.critical), "Signature does not miss or combine critical")
		check(float(roll.damage) >= floorf(preview * 1.6 * 0.92) and float(roll.damage) <= ceilf(preview * 1.6 * 1.08), "Damage variance is bounded ±8%")

func _test_effects() -> void:
	var effects: Array = []
	Effects.apply(effects, {"type": "attack_down", "magnitude": 0.2, "duration": 2}, "rival", 0, 250.0)
	var base: Dictionary = fighter().combat_stats
	var original: Dictionary = base.duplicate(true)
	check(Effects.runtime_stats(base, effects).attack < base.attack and base == original, "Temporary stats never mutate base")
	check(Effects.expire_after_action(effects, 0).is_empty() and effects[0].remaining_turns == 2, "Fresh status skips application action")
	check(Effects.expire_after_action(effects, 1).is_empty() and effects[0].remaining_turns == 1, "Status loses one owner action")
	check(Effects.expire_after_action(effects, 2).size() == 1 and effects.is_empty(), "Status expires exactly on duration")
	var poison: Dictionary = {"type": "poison", "magnitude": 3, "duration": 3, "stacking": "intensity", "max_stacks": 2}
	Effects.apply(effects, poison, "rival", 0, 250)
	Effects.apply(effects, poison, "rival", 1, 250)
	Effects.apply(effects, poison, "rival", 2, 250)
	check(effects.size() == 1 and effects[0].stacks == 2 and effects[0].magnitude == 6, "Intensity stacking has explicit stack cap")
	check(Effects.dots(effects, 2).is_empty() and Effects.dots(effects, 3).size() == 1, "Dot does not tick on application action")
	Effects.apply(effects, {"type": "poison", "magnitude": 1, "duration": 1, "stacking": "ignore"}, "player", 3, 250)
	check(effects[0].magnitude == 6 and effects[0].source == "rival", "Ignore stacking preserves existing state")
	Effects.apply(effects, {"type": "poison", "magnitude": 2, "duration": 1, "stacking": "replace"}, "player", 3, 250)
	check(effects[0].magnitude == 2 and effects[0].remaining_turns == 1, "Replace stacking replaces magnitude and duration")
	effects.clear()
	Effects.apply(effects, {"type": "shield", "magnitude": 20, "duration": 3}, "player", 0, 250)
	var absorbed: Dictionary = Effects.absorb(effects, 10)
	check(absorbed.absorbed == 10 and absorbed.remaining == 0 and Effects.shield_total(effects) == 10, "Shield absorbs real damage")
	absorbed = Effects.absorb(effects, 15)
	check(absorbed.absorbed == 10 and absorbed.remaining == 5 and effects.is_empty(), "Consumed shield disappears")
	Effects.apply(effects, {"type": "healing_down", "magnitude": 0.4, "duration": 2}, "rival", 0, 250)
	check(is_equal_approx(Effects.healing_multiplier(effects), 0.6), "Healing reduction meaningful")
	Effects.apply(effects, {"type": "slow", "magnitude": 0.2, "duration": 2}, "rival", 0, 250)
	check(Effects.runtime_stats(base, effects).interval > base.interval, "Slow increases attack interval")
	check(Effects.apply(effects, {"type": "unknown", "duration": 1}, "player", 0, 250).is_empty(), "Unsupported effect rejected safely")

func _test_reproducibility() -> void:
	var player: Dictionary = fighter("iria", 7)
	var rival: Dictionary = fighter("taro", 9)
	var original: Dictionary = player.duplicate(true)
	var a: Dictionary = simulate(player, rival, 1567, 0.016)
	var b: Dictionary = simulate(player, rival, 1567, 13.0)
	check(a == b, "Whole battle including events and ID independent of delta")
	check(a != simulate(player, rival, 7651), "Another seed changes combat")
	check(player == original, "Battle does not mutate caller descriptor")
	check(a.has_all(["battle_id", "winner", "loser", "reason", "duration", "turns", "player", "rival", "metrics", "terminal_state", "events"]), "Summary contract complete")
	for event: Dictionary in a.events:
		check(event.has_all(["type", "message", "turn", "time", "player_hp", "rival_hp"]), "Every event has readable authoritative context")
	var extreme: Dictionary = simulate(fighter("nima", 1), fighter("mugo", 50), 1009)
	check(float(extreme.duration) <= 60 and extreme.winner in ["player", "rival"], "Extreme levels resolve without invalid state")
	var legacy: Dictionary = {"life": 6, "strength": 6, "agility": 6, "speed": 6}
	check(simulate(legacy, legacy).winner in ["player", "rival"], "Legacy 4-stat inputs remain playable")

func _test_terminal_cases() -> void:
	var engine = Battle.new()
	engine.start(fighter(), fighter(), 23)
	check(engine.summary().is_empty(), "No terminal summary before battle ends")
	check(engine.advance(0).is_empty() and engine.advance(-1).is_empty() and engine.elapsed == 0, "Invalid deltas cannot advance battle")
	engine.advance(60)
	var terminal: Dictionary = engine.summary()
	check(engine.advance(100).is_empty() and engine.surrender().is_empty(), "No attacks or duplicate finish after completion")
	check(engine.summary() == terminal, "Terminal state immutable")
	terminal.metrics.player.damage_dealt = -99
	check(engine.summary().metrics.player.damage_dealt >= 0, "Returned summary is detached")
	var poison: Dictionary = {"type": "poison", "magnitude": 5, "duration": 3}
	engine.start(fighter(), fighter(), 99, {"opening_time": 2, "initial_hp": {"player": 1, "rival": 1}, "initial_statuses": {"player": [poison], "rival": [poison]}})
	var events: Array[Dictionary] = engine.advance(2)
	check(engine.player_hp == 0 and engine.rival_hp == 0 and engine.summary().reason == "dot", "Simultaneous DoTs damage both fighters before terminal resolution")
	var ticks: int = 0
	var finished: int = 0
	for event: Dictionary in events:
		if event.type == "status_tick": ticks += 1
		if event.type == "finished": finished += 1
	check(ticks == 2 and finished == 1, "Simultaneous DoT has two ticks and one winner event")
	engine.start(fighter(), fighter(), 73, {"initial_statuses": {"player": [poison]}})
	engine.advance(0.5)
	var hp_before: float = engine.player_hp
	events = engine.surrender("player")
	check(not engine.running and engine.winner == "rival" and engine.summary().reason == "surrender", "Surrender resolves immediately with correct opposing winner")
	check(engine.elapsed == 0.5 and engine.player_hp == hp_before, "Surrender neither advances effects nor damage")
	check(engine.advance(50).is_empty() and engine.surrender("rival").is_empty(), "Terminal surrender cannot be overwritten")
	var low_damage: Dictionary = fighter()
	low_damage.combat_stats.attack = -10
	low_damage.combat_stats.max_hp = 2000
	low_damage.ability = {"id": "none"}
	var timeout: Dictionary = simulate(low_damage, low_damage, 79, 60, {"disable_signatures": true})
	check(timeout.reason == "timeout" and timeout.duration == 60, "Minimum damage battles time out at sixty seconds")
	for event: Dictionary in timeout.events:
		if event.type == "attack": check(event.damage >= 0 and event.target_hp >= 0, "No negative damage or HP in malformed-stat battle")

func _test_slow_scheduler() -> void:
	var control = Battle.new()
	var slowed = Battle.new()
	for engine in [control, slowed]:
		engine.start(fighter(), fighter(), 3311, {"opening_time": 2.0, "disable_signatures": true})
		engine.advance(0.5)
	var status_events: Array[Dictionary] = []
	slowed._apply_status("player", "rival", {"type": "slow", "magnitude": 0.25, "duration": 1}, 1.0, true, status_events)
	check(float(slowed._fighters.player.next_action) > float(control._fighters.player.next_action), "One-action slow delays already scheduled next action")
	var scheduled: float = float(slowed._fighters.player.next_action)
	slowed.advance(scheduled - slowed.elapsed + 0.00001)
	check(Effects.has_type(slowed.snapshot().fighters.player.statuses,"slow"),"One-action slow remains during the delayed move's anticipation")
	slowed.advance(float(slowed._fighters.player.impact_at)-slowed.elapsed+0.00001)
	check(not Effects.has_type(slowed.snapshot().fighters.player.statuses, "slow"), "One-action slow expires after the delayed action")
	var repeat = Battle.new()
	repeat.start(fighter(), fighter(), 3311, {"opening_time": 2.0, "disable_signatures": true})
	repeat.advance(0.5)
	repeat._apply_status("player", "rival", {"type": "slow", "magnitude": 0.25, "duration": 1}, 1.0, true, status_events)
	while repeat.running: repeat.advance(0.016)
	while slowed.running: slowed.advance(60)
	check(repeat.summary() == slowed.summary(), "Rescheduled slow remains independent of delta")

func _test_signatures() -> void:
	for definition: Dictionary in Catalog.all_definitions():
		var result: Dictionary = simulate(fighter(definition.id), fighter("mugo"), 510, 60, {"force_signature": ["player", "rival"], "signature_turn": 2})
		check(result.metrics.player.signatures == 1 and result.metrics.rival.signatures == 1, "%s: at most one signature for each side" % definition.id)
		var applied_after_signature: bool = false
		var signature_seen: bool = false
		for event: Dictionary in result.events:
			if event.type == "signature" and event.side == "player": signature_seen = true
			if signature_seen and event.type == "status_applied" and event.source == "player" and event.side == "rival": applied_after_signature = true
		check(applied_after_signature, "%s signature applies a mandatory temporary effect" % definition.id)
	var engine = Battle.new()
	engine.start(fighter("nima"), fighter("mugo"), 711, {"initial_hp": {"rival": 1}, "force_signature": ["player"], "signature_turn": 1, "opening_time": 2})
	var events: Array[Dictionary] = engine.advance(60)
	check(engine.winner == "player" and engine.summary().metrics.player.signatures == 1, "Signature can finish a nearly defeated fighter")
	check(engine.snapshot().fighters.rival.statuses.size() >= 1, "Lethal signature still applies its documented debuff")
	check(events.back().type == "finished" and engine.advance(1).is_empty(), "Final-turn signature emits no late actions")
	engine.start(fighter(), fighter(), 183, {"force_signature": ["player", "rival"], "signature_turn": 1, "opening_time": 60})
	engine.advance(60)
	check(engine.summary().reason == "timeout" and engine.summary().duration == 60, "Signatures on final scheduled action respect timeout")
	check(engine.summary().metrics.player.signatures == 0 and engine.summary().metrics.rival.signatures == 0, "Signatures beginning at timeout cannot deal damage before their animation impact")
	engine.start(fighter(),fighter(),183,{"force_signature":["player","rival"],"signature_turn":1,"opening_time":59.5})
	engine.advance(60)
	check(engine.summary().metrics.player.signatures==1 and engine.summary().metrics.rival.signatures==1,"Signatures whose impacts reach the exact deadline each execute once")

func _test_abilities() -> void:
	var seen: Dictionary = {}
	for definition: Dictionary in Catalog.all_definitions():
		var result: Dictionary = simulate(fighter(definition.id), fighter("mugo"), 910, 60, {"disable_signatures": true})
		seen[definition.ability.id] = true
		check(float(result.duration) > 0 and float(result.duration) <= 60, "%s distinct ability resolves safely" % definition.id)
		if definition.ability.id == "comeback": check(result.metrics.player.healing > 0, "Comeback produces actual healing")
		if definition.ability.id == "shield": check(result.metrics.player.absorbed > 0, "Defender shield absorbs real damage")
		if definition.ability.id == "counter": check(result.metrics.player.counters > 0, "Counter ability produces retaliations")
		if definition.ability.id == "poison": check(result.metrics.player.statuses_applied > 0, "Poison specialist applies statuses")
	check(seen.size() == 9, "Nine distinct ability dispatch types")
