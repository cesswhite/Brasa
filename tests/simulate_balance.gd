extends SceneTree
## Seeded aggregate audit. Default: 16,200 roster matches + 900 upset matches.
## Optional --quick for tuning; --output=/absolute/report.json controls the report.
const Battle = preload("res://scripts/combat_engine.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
var _total: int = 0
var _seconds: float = 0.0
var _signatures: int = 0
var _criticals: int = 0
var _hits: int = 0
var _attacks: int = 0
var _timeouts: int = 0
var _durations: Array[float] = []

func _init() -> void:
	var quick: bool = OS.get_cmdline_user_args().has("--quick")
	var output: String = "res://reports/balance.json"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	var levels: Array[int] = [1]
	if not quick:
		levels.append_array([10, 25, 50])
	var matrices: Array[Dictionary] = []
	var min_aggregate: float = 1.0
	var max_aggregate: float = 0.0
	var impossible_pairs: int = 0
	var started: int = Time.get_ticks_msec()
	for level: int in levels:
		var repeats: int = 30 if quick else (80 if level == 1 else 40)
		var matrix: Array = []
		var row_rates: Array = []
		for left: int in range(Catalog.IDS.size()):
			var row: Array = []
			var row_wins: int = 0
			for right: int in range(Catalog.IDS.size()):
				var wins: int = 0
				var player: Dictionary = _profile(Catalog.IDS[left], level)
				var rival: Dictionary = _profile(Catalog.IDS[right], level)
				for repetition: int in range(repeats):
					var seed_value: int = level * 10000000 + left * 100000 + right * 1000 + repetition + 1
					var result: Dictionary = _simulate(player, rival, seed_value)
					if result.winner == "player": wins += 1
				row.append(float(wins) / repeats)
				row_wins += wins
				if left != right and (wins == 0 or wins == repeats): impossible_pairs += 1
			var rate: float = float(row_wins) / float(repeats * Catalog.IDS.size())
			min_aggregate = minf(min_aggregate, rate)
			max_aggregate = maxf(max_aggregate, rate)
			row_rates.append(rate)
			matrix.append(row)
			print("L%d %s: %.1f%%" % [level, Catalog.IDS[left], rate * 100.0])
		matrices.append({"level": level, "repeats_per_pair": repeats, "ids": Catalog.IDS, "win_matrix": matrix, "row_win_rates": row_rates})
	var upsets: Dictionary = {}
	var upset_total: int = 0
	var upset_count: int = 0
	for id: String in Catalog.IDS:
		var weaker_wins: int = 0
		var repeats: int = 30 if quick else 100
		for repetition: int in range(repeats):
			var result: Dictionary = _simulate(_profile(id, 1), _profile(id, 4), 710000000 + Catalog.IDS.find(id) * 1000 + repetition)
			if result.winner == "player": weaker_wins += 1
		upsets[id] = float(weaker_wins) / repeats
		upset_count += weaker_wins
		upset_total += repeats
	_durations.sort()
	var incidence: float = float(_signatures) / float(_total * 2)
	var report: Dictionary = {
		"matches": _total, "elapsed_real_seconds": float(Time.get_ticks_msec() - started) / 1000.0,
		"mean_battle_seconds": _seconds / _total, "median_battle_seconds": _durations[_durations.size() / 2],
		"p10_seconds": _durations[int(_durations.size() * 0.10)], "p90_seconds": _durations[int(_durations.size() * 0.90)],
		"signature_activations": _signatures, "signature_incidence_per_fighter_battle": incidence,
		"critical_rate_per_hit": float(_criticals) / maxi(1, _hits), "hit_rate": float(_hits) / maxi(1, _attacks),
		"timeout_rate": float(_timeouts) / _total, "matrices": matrices,
		"aggregate_min": min_aggregate, "aggregate_max": max_aggregate, "sampled_extreme_pairs": impossible_pairs,
		"weaker_level_1_vs_4_win_rate": float(upset_count) / maxi(1, upset_total), "upsets_by_character": upsets,
		"notes": "Each ordered pair is sampled independently with fixed seeds. An observed 0% is a finite-sample result, not proof that victory is impossible. Signatures use one 1% Bernoulli per fighter at battle start. Training is kept at archetype base to isolate roster and natural growth.",
	}
	var file: FileAccess = FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("Could not write balance report: " + output)
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("SIMULATION: %d matches; mean %.2fs; signatures %.3f%%; weak L1 vs L4 %.1f%%; aggregates %.1f–%.1f%%; extremes %d; report %s" % [_total, report.mean_battle_seconds, incidence * 100, report.weaker_level_1_vs_4_win_rate * 100, min_aggregate * 100, max_aggregate * 100, impossible_pairs, output])
	quit(0)

func _profile(id: String, level: int) -> Dictionary:
	var definition: Dictionary = Catalog.definition(id)
	return {"character_id": id, "name": definition.name, "level": level, "stats": definition.training_base.duplicate(true)}

func _simulate(player: Dictionary, rival: Dictionary, seed_value: int) -> Dictionary:
	var engine = Battle.new()
	engine.start(player, rival, seed_value)
	engine.advance(60.0)
	var result: Dictionary = engine.summary()
	_total += 1
	_seconds += float(result.duration)
	_durations.append(float(result.duration))
	if result.reason == "timeout": _timeouts += 1
	for side: String in Battle.SIDES:
		_signatures += int(result.metrics[side].signatures)
		_criticals += int(result.metrics[side].criticals)
		_hits += int(result.metrics[side].hits)
		_attacks += int(result.metrics[side].attacks)
	return result
