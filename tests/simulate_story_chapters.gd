extends SceneTree
## Bounded natural campaign audit through both chapters, no save files opened.
const Story = preload("res://scripts/story_catalog.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Battle = preload("res://scripts/combat_engine.gd")
const Audit = preload("res://tests/simulate_story.gd")
class MemoryCampaign extends "res://scripts/story_progression.gd":
	func save() -> bool:
		last_save_ok = true
		return true
var matches: int = 0
var seconds: float = 0.0
var signatures: int = 0
var timeouts: int = 0

func _init() -> void:
	var repetitions: int = 3 if OS.get_cmdline_user_args().has("--quick") else 8
	var output: String = "res://reports/story_chapters_balance.json"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	var rows: Array[Dictionary] = []
	var started: int = Time.get_ticks_msec()
	for hero_index: int in range(Catalog.IDS.size()):
		var id: String = Catalog.IDS[hero_index]
		for build_index: int in range(Audit.BUILDS.size()):
			var build: String = str(Audit.BUILDS.keys()[build_index])
			var priorities: Array = Audit.BUILDS[build]
			var runs: Array[Dictionary] = []
			for repetition: int in range(repetitions):
				var profile = MemoryCampaign.new()
				profile.select_character(id)
				var cursor: int = 0
				var total_battles: int = 0
				var chapter_results: Array[Dictionary] = []
				for chapter: int in [1, 2]:
					var first_try_wins: Array[bool] = []
					var attempted: Array[int] = []
					var losses_by_stage: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0]
					var starting_level: int = int(profile.data.level)
					while not profile.is_complete() and int(profile.data.matches) < 40:
						while int(profile.data.points) > 0:
							var allocated: bool = false
							for trial: int in range(priorities.size()):
								var key: String = str(priorities[cursor % priorities.size()])
								cursor += 1
								if profile.upgrade(key):
									allocated = true
									break
								if not allocated: break
						var stage: int = profile.current_stage()
						var result: Dictionary = _fight(profile.active_combatant(), profile.make_rival(), 933000000 + hero_index * 1000000 + build_index * 100000 + repetition * 1000 + total_battles)
						var won: bool = result.winner == "player"
						if not stage in attempted:
							attempted.append(stage)
							first_try_wins.append(won)
						if not won: losses_by_stage[stage] += 1
						var reward: Dictionary = profile.reward_match(result)
						if not bool(reward.accepted):
							push_error("Natural engine reward rejected")
							quit(1)
							return
						total_battles += 1
					chapter_results.append({"chapter": chapter, "completed": profile.is_complete(), "battles": int(profile.data.matches), "defeats": int(profile.data.losses), "starting_level": starting_level, "final_level": int(profile.data.level), "stage_reached": profile.current_stage(), "losses_by_stage": losses_by_stage, "first_try_wins": first_try_wins})
					if not profile.is_complete(): break
					if chapter == 1 and not profile.start_next_chapter():
						push_error("Natural campaign could not advance chapter")
						quit(1)
						return
				runs.append({"repetition": repetition, "chapters": chapter_results, "total_battles": total_battles})
			rows.append({"character_id": id, "build": build, "runs": runs})
			var completed: int = 0
			var mean_second: float = 0.0
			for run: Dictionary in runs:
				if run.chapters.size() == 2:
					if bool(run.chapters[1].completed): completed += 1
					mean_second += float(run.chapters[1].battles)
			print("CHAPTERS %s/%s: %d/%d completed; second %.1f battles" % [id, build, completed, repetitions, mean_second / repetitions])
	var paired: Dictionary = _second_opponent_audit(20 if repetitions == 3 else 50)
	var report: Dictionary = {"matches": matches, "campaigns": Catalog.IDS.size() * Audit.BUILDS.size() * repetitions, "repetitions_per_hero_build": repetitions, "builds": Audit.BUILDS, "rows": rows, "second_opponent_correction": paired, "mean_battle_seconds": seconds / maxi(1, matches), "signature_incidence": float(signatures) / maxi(1, matches * 2), "timeouts": timeouts, "elapsed_real_seconds": float(Time.get_ticks_msec() - started) / 1000.0, "notes": "Real CombatEngine + StoryProgression, save disabled. All nine heroes and four fixed allocation priorities. No respec or training reset between chapters. Each chapter has a safety cutoff at 40 battles. Same seeds compare original Nima level3 against corrected level2; all other stats held fixed. Finite samples are estimates, not guarantees."}
	var file: FileAccess = FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("Could not write chapter report")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("CHAPTER AUDIT: %d matches, %.2fs mean, %.3f%% signatures. %s" % [matches, report.mean_battle_seconds, float(report.signature_incidence) * 100.0, output])
	quit(0)

func _fight(player: Dictionary, rival: Dictionary, seed_value: int) -> Dictionary:
	var engine = Battle.new()
	engine.start(player, rival, seed_value)
	engine.advance(60.0)
	var result: Dictionary = engine.summary()
	matches += 1
	seconds += float(result.duration)
	signatures += int(result.metrics.player.signatures) + int(result.metrics.rival.signatures)
	if result.reason == "timeout": timeouts += 1
	return result

func _second_opponent_audit(repetitions: int) -> Dictionary:
	var old_wins: int = 0
	var corrected_wins: int = 0
	for index: int in range(Catalog.IDS.size()):
		var id: String = Catalog.IDS[index]
		var definition: Dictionary = Catalog.definition(id)
		var player: Dictionary = {"character_id": id, "name": definition.name, "level": 2, "stats": definition.training_base.duplicate(true), "allocations": {"max_hp": 1, "attack": 1, "defense": 1, "speed": 1, "accuracy": 1, "evasion": 1}}
		player["combat_stats"] = Story.stats_for(player)
		var corrected: Dictionary = Story.opponent(1)
		var old: Dictionary = corrected.duplicate(true)
		old.level = 3
		for repetition: int in range(repetitions):
			var seed_value: int = 945000000 + index * 1000 + repetition
			if _fight(player, old, seed_value).winner == "player": old_wins += 1
			if _fight(player, corrected, seed_value).winner == "player": corrected_wins += 1
	return {"matches_per_version": Catalog.IDS.size() * repetitions, "old_nima_level": 3, "corrected_nima_level": 2, "old_player_win_rate": float(old_wins) / (Catalog.IDS.size() * repetitions), "corrected_player_win_rate": float(corrected_wins) / (Catalog.IDS.size() * repetitions)}
