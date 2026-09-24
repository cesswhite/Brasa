extends SceneTree
## Seeded campaign audit, with four fixed allocation strategies across all nine heroes.
## Does not open any save. --quick reduces samples; --output= controls JSON destination.
const Story = preload("res://scripts/story_catalog.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Balance = preload("res://scripts/balance.gd")
const Battle = preload("res://scripts/combat_engine.gd")
class MemoryCampaign extends "res://scripts/story_progression.gd":
	func save() -> bool:
		last_save_ok = true
		return true
const BUILDS: Dictionary = {
	"balanced": ["max_hp", "attack", "defense", "speed", "accuracy", "evasion", "crit_chance", "resistance"],
	"aggressive": ["attack", "attack", "max_hp", "crit_chance", "speed", "accuracy"],
	"durable": ["max_hp", "defense", "max_hp", "evasion", "attack", "speed"],
	"tempo": ["speed", "accuracy", "evasion", "attack", "max_hp", "crit_chance"],
}
var _matches: int = 0
var _seconds: float = 0.0
var _timeouts: int = 0
var _signatures: int = 0
var _durations: Array[float] = []

func _init() -> void:
	var quick: bool = OS.get_cmdline_user_args().has("--quick")
	var output: String = "res://reports/story_balance.json"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	var started: int = Time.get_ticks_msec()
	var encounter_samples: int = 10 if quick else 40
	var campaign_samples: int = 3 if quick else 12
	var encounter_rows: Array[Dictionary] = []
	var campaigns: Array[Dictionary] = []
	var nominal_levels: Array[int] = []
	var total_experience: int = 0
	var elite_points: int = 0
	var fresh_wins: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0]
	for stage_index: int in range(8):
		var level: int = _level_for(total_experience)
		nominal_levels.append(level)
		var points: int = int(Story.CONFIG.initial_points) + (level - 1) * int(Story.CONFIG.points_per_level) + elite_points
		var stage_wins: int = 0
		for hero_index: int in range(Catalog.IDS.size()):
			var id: String = Catalog.IDS[hero_index]
			for build_index: int in range(BUILDS.size()):
				var build: String = str(BUILDS.keys()[build_index])
				var player: Dictionary = _profile(id, level, points, build)
				var wins: int = 0
				for repetition: int in range(encounter_samples):
					var seed_value: int = 811000000 + stage_index * 1000000 + hero_index * 10000 + build_index * 100 + repetition
					var result: Dictionary = _fight(player, Story.opponent(stage_index), seed_value)
					if result.winner == "player": wins += 1
				stage_wins += wins
				encounter_rows.append({"stage_index": stage_index, "character_id": id, "build": build, "level": level, "points": points, "wins": wins, "matches": encounter_samples, "win_rate": float(wins) / encounter_samples})
			for repetition: int in range(encounter_samples):
				var result: Dictionary = _fight(_profile(id, 1, 3, "balanced"), Story.opponent(stage_index), 815000000 + stage_index * 100000 + hero_index * 1000 + repetition)
				if result.winner == "player": fresh_wins[stage_index] += 1
		print("STORY stage %d nominal L%d: %.1f%%; fresh L1: %.1f%%" % [stage_index + 1, level, 100.0 * stage_wins / float(Catalog.IDS.size() * BUILDS.size() * encounter_samples), 100.0 * fresh_wins[stage_index] / float(Catalog.IDS.size() * encounter_samples)])
		total_experience += int(Story.stage(stage_index).xp_win)
		if Story.stage(stage_index).kind == "elite": elite_points += int(Story.CONFIG.elite_points)
	for hero_index: int in range(Catalog.IDS.size()):
		var id: String = Catalog.IDS[hero_index]
		for build_index: int in range(BUILDS.size()):
			var build: String = str(BUILDS.keys()[build_index])
			var completed: int = 0
			var battle_counts: Array[int] = []
			var completion_levels: Array[int] = []
			var losses_per_stage: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0]
			var stage_reached: Array[int] = []
			var first_attempts: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0]
			var first_attempt_wins: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0]
			for repetition: int in range(campaign_samples):
				var progression = MemoryCampaign.new()
				progression.select_character(id)
				var count: int = 0
				var cursor: int = 0
				var attempted: Array[int] = []
				while not progression.is_complete() and count < 40:
					var priorities: Array = BUILDS[build]
					while int(progression.data.points) > 0:
						var allocated: bool = false
						for trial: int in range(priorities.size()):
							var key: String = str(priorities[cursor % priorities.size()])
							cursor += 1
							if progression.upgrade(key):
								allocated = true
								break
						if not allocated: break
					var stage_index: int = progression.current_stage()
					var seed_value: int = 821000000 + hero_index * 1000000 + build_index * 100000 + repetition * 1000 + count
					var result: Dictionary = _fight(progression.active_combatant(), progression.make_rival(), seed_value)
					if not stage_index in attempted:
						attempted.append(stage_index)
						first_attempts[stage_index] += 1
						if result.winner == "player": first_attempt_wins[stage_index] += 1
					var reward: Dictionary = progression.reward_match(result)
					if not bool(reward.accepted):
						push_error("Historical chapter audit received an invalid result")
						quit(1)
						return
					if result.winner != "player": losses_per_stage[stage_index] += 1
					count += 1
				if progression.is_complete(): completed += 1
				battle_counts.append(count)
				completion_levels.append(int(progression.data.level))
				stage_reached.append(progression.current_stage())
			var average: float = _mean_ints(battle_counts)
			campaigns.append({"character_id": id, "build": build, "campaigns": campaign_samples, "completed": completed, "completion_rate": float(completed) / campaign_samples, "battle_counts": battle_counts, "mean_battles": average, "mean_defeats": average - 8.0 if completed == campaign_samples else -1.0, "mean_completion_level": _mean_ints(completion_levels), "losses_by_stage": losses_per_stage, "stage_reached": stage_reached, "first_attempts_by_stage": first_attempts, "first_attempt_wins_by_stage": first_attempt_wins, "boss_first_try_rate": float(first_attempt_wins[7]) / maxi(1, first_attempts[7])})
			print("CAMPAIGN %s %s: %d/%d complete, %.1f battles" % [id, build, completed, campaign_samples, average])
	_durations.sort()
	var report: Dictionary = {"matches": _matches, "encounter_samples_per_hero_build_stage": encounter_samples, "campaign_samples_per_hero_build": campaign_samples, "builds": BUILDS, "nominal_levels": nominal_levels, "fresh_level_1_wins_by_stage": fresh_wins, "fresh_matches_per_stage": Catalog.IDS.size() * encounter_samples, "encounters": encounter_rows, "campaigns": campaigns, "mean_battle_seconds": _seconds / maxi(1, _matches), "p10_seconds": _durations[int(_durations.size() * 0.1)], "p90_seconds": _durations[int(_durations.size() * 0.9)], "timeouts": _timeouts, "signatures": _signatures, "signature_incidence": float(_signatures) / maxi(1, _matches * 2), "elapsed_real_seconds": float(Time.get_ticks_msec() - started) / 1000.0, "notes": "Four fixed allocation priorities, no respec, legal caps, normal combat RNG and signatures. Encounter matrix assumes victories only; campaigns use actual StoryProgression for bounded loss XP, unlocks, allocation history and rewards, with a 40-battle audit cutoff. No move tokens or perks are spent in this isolated first-chapter baseline. No save files accessed. Finite sample probabilities are estimates, not guarantees."}
	var file: FileAccess = FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("Could not write story report: " + output)
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("STORY SIMULATION: %d matches, %.2fs mean, signatures %.3f%%. Report %s" % [_matches, report.mean_battle_seconds, float(report.signature_incidence) * 100.0, output])
	quit(0)

func _level_for(experience: int) -> int:
	var level: int = 1
	var remaining: int = experience
	while level < Balance.MAX_LEVEL and remaining >= Balance.xp_for_level(level):
		remaining -= Balance.xp_for_level(level)
		level += 1
	return level

func _profile(id: String, level: int, points: int, build: String) -> Dictionary:
	var definition: Dictionary = Catalog.definition(id)
	var result: Dictionary = {"character_id": id, "name": definition.name, "level": level, "stats": definition.training_base.duplicate(true), "allocations": {}}
	_add_points(result, points, build, 0)
	result["combat_stats"] = Story.stats_for(result)
	return result

func _add_points(result: Dictionary, points: int, build: String, starting_cursor: int) -> Dictionary:
	var priorities: Array = BUILDS[build]
	var cursor: int = starting_cursor
	var spent: int = 0
	for point: int in range(points):
		var allocated: bool = false
		for trial: int in range(priorities.size()):
			var key: String = str(priorities[cursor % priorities.size()])
			cursor += 1
			if int(result.allocations.get(key, 0)) >= int(Story.CONFIG.allocation_cap): continue
			var before: float = float(Story.stats_for(result)[key])
			result.allocations[key] = int(result.allocations.get(key, 0)) + 1
			if float(Story.stats_for(result)[key]) > before:
				allocated = true
				spent += 1
				break
			result.allocations[key] = int(result.allocations[key]) - 1
		if not allocated: break
	return {"spent": spent, "cursor": cursor}

func _fight(player: Dictionary, rival: Dictionary, seed_value: int) -> Dictionary:
	var engine = Battle.new()
	engine.start(player, rival, seed_value)
	engine.advance(60.0)
	var result: Dictionary = engine.summary()
	_matches += 1
	_seconds += float(result.duration)
	_durations.append(float(result.duration))
	if str(result.reason) == "timeout": _timeouts += 1
	_signatures += int(result.metrics.player.signatures) + int(result.metrics.rival.signatures)
	return result

func _mean_ints(values: Array[int]) -> float:
	var total: int = 0
	for value: int in values: total += value
	return float(total) / maxi(1, values.size())
