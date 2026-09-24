extends SceneTree
## Natural campaigns: all rewards and legal choices through StoryProgression.
## No saves opened; deterministic run seeds and combat seeds are recorded.
const Story = preload("res://scripts/story_catalog.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Moves = preload("res://scripts/move_catalog.gd")
const Battle = preload("res://scripts/combat_engine.gd")
const Config = preload("res://scripts/campaign_config.gd")
const Audit = preload("res://tests/simulate_story.gd")
class MemoryCampaign extends "res://scripts/story_progression.gd":
	func save() -> bool:
		last_save_ok = true
		return true
const PERK_ORDER: Dictionary = {"balanced": [0,2,4], "aggressive": [1,2,5], "durable": [0,3,4], "tempo": [1,3,5]}
const MOVE_TYPES: Dictionary = {"balanced": ["quick","technique","jump","dash","counter","heavy","charge","guard"], "aggressive": ["heavy","charge","jump","quick","dash","technique","counter","guard"], "durable": ["counter","guard","technique","heavy","quick","charge","jump","dash"], "tempo": ["dash","jump","quick","technique","counter","heavy","charge","guard"]}
const BUILDS: Dictionary = {"balanced": ["max_hp","attack","defense","speed","accuracy","evasion","crit_chance","resistance"], "aggressive": ["attack","attack","max_hp","speed","crit_chance","accuracy","defense","max_hp"], "durable": ["max_hp","defense","max_hp","attack","speed","evasion","accuracy"], "tempo": ["speed","accuracy","evasion","attack","max_hp","crit_chance","defense"]}
var adaptive: bool = false
var matches: int = 0
var seconds: float = 0.0
var signatures: int = 0
var timeouts: int = 0
var stages: Dictionary = {}
var move_usage: Dictionary = {}
var moves_available: Dictionary = {}
var move_wins: Dictionary = {}
var perk_usage: Dictionary = {}

func _init() -> void:
	var repetitions: int = 3
	var output: String = "res://reports/campaign100_balance.json"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--runs="): repetitions = maxi(1, int(arg.trim_prefix("--runs=")))
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		if arg == "--adaptive": adaptive = true
	var rows: Array[Dictionary] = []
	var started: int = Time.get_ticks_msec()
	var initial_hashes: Dictionary = _source_hashes()
	var completed: int = 0
	for hero_index: int in range(Catalog.IDS.size()):
		var id: String = Catalog.IDS[hero_index]
		for build_index: int in range(BUILDS.size()):
			var build: String = str(BUILDS.keys()[build_index])
			var runs: Array[Dictionary] = []
			for repetition: int in range(repetitions):
				var p = MemoryCampaign.new()
				p.select_character(id)
				p.data.run_seed = 14810000 + hero_index * 100000 + build_index * 1000 + repetition
				var cursor: int = 0
				var current_priorities: Array = Audit.BUILDS[build].duplicate() if adaptive else BUILDS[build].duplicate()
				var current_build: String = build
				var redistributions: Array[Dictionary] = []
				var fights: int = 0
				var losses: int = 0
				var stage_runs: Array[Dictionary] = []
				while not bool(p.campaign_completion().completed) and fights < 500:
					if p.is_complete() and not p.start_next_chapter(): break
					var global_level: int = p.global_level()
					var stage_fights: int = 0
					var stage_won: bool = false
					var starting_level: int = int(p.data.level)
					while not stage_won and stage_fights < Config.MAX_STAGE_ATTEMPTS:
						if adaptive and stage_fights in [3, 6]:
							var next_build: String = build if redistributions.is_empty() else "durable" if current_build != "durable" else "balanced"
							if p.respec_build():
								current_build = next_build
								current_priorities = BUILDS[current_build].duplicate()
								cursor = 0
								redistributions.append({"story_level": global_level, "after_defeats": stage_fights, "build": current_build, "revision": int(p.data.build_revision)})
						cursor = _spend(p, current_build, cursor, current_priorities)
						var player: Dictionary = p.active_combatant()
						var rival: Dictionary = p.make_rival()
						var seed_value: int = 951000000 + hero_index * 1000000 + build_index * 100000 + repetition * 10000 + fights
						var engine = Battle.new()
						engine.start(player, rival, seed_value)
						engine.advance(60.0)
						var result: Dictionary = engine.summary()
						stage_won = str(result.winner) == "player"
						_record(global_level, result, stage_fights == 0)
						var reward: Dictionary = p.reward_match(result)
						if not bool(reward.accepted):
							push_error("Natural result rejected at %d for %s" % [global_level,id])
							quit(1)
							return
						fights += 1
						stage_fights += 1
						if not stage_won: losses += 1
					stage_runs.append({"level": global_level, "won": stage_won, "fights": stage_fights, "starting_hero_level": starting_level, "ending_hero_level": int(p.data.level)})
					if not stage_won: break
				var done: bool = bool(p.campaign_completion().completed)
				if done: completed += 1
				runs.append({"run_seed": int(p.data.run_seed), "repetition": repetition, "completed": done, "fights": fights, "losses": losses, "cleared": int(p.campaign_completion().defeated), "final_hero_level": int(p.data.level), "unspent_points": int(p.data.points), "allocations": p.data.allocations.duplicate(), "move_upgrades": p.data.move_upgrades.duplicate(), "perks": p.data.perks.duplicate(), "final_build": current_build, "redistributions": redistributions, "stages": stage_runs})
			var wins: int = 0
			var count: int = 0
			var cleared: int = 0
			for run: Dictionary in runs:
				if bool(run.completed): wins += 1
				count += int(run.fights)
				cleared += int(run.cleared)
			print("CAMPAIGN100 %s/%s %d/%d completed; %.1f fights; cleared %.1f" % [id,build,wins,repetitions,float(count)/repetitions,float(cleared)/repetitions])
			rows.append({"character_id": id, "build": build, "runs": runs})
	var report: Dictionary = {"matches": matches, "campaigns": Catalog.IDS.size()*BUILDS.size()*repetitions, "completed": completed, "repetitions_per_cell": repetitions, "rows": rows, "stages": stages, "move_usage": move_usage, "moves_available": moves_available, "move_wins": move_wins, "perk_usage": perk_usage, "mean_battle_seconds": seconds / maxi(1,matches), "signature_incidence": float(signatures)/maxi(1,matches*2), "timeouts": timeouts, "elapsed_seconds": float(Time.get_ticks_msec()-started)/1000.0, "builds": BUILDS, "adaptive": adaptive, "initial_builds": Audit.BUILDS if adaptive else BUILDS, "source_hashes": initial_hashes, "source_changed_during_run": initial_hashes != _source_hashes(), "max_attempts_per_stage": Config.MAX_STAGE_ATTEMPTS, "notes": "Adaptive stress starts from the earlier sparse priorities, redistributes after 3/6 defeats on a stage to declared campaign priorities, and records every change." if adaptive else "Four fixed legal allocation priorities, six character-specific perk options with three slots; no respec. Save disabled, actual engine and reward validation. Run pool and combat seeds deterministic. Move wins describe association, not a causal isolated effectiveness test."}
	var file: FileAccess = FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write balance report")
		quit(1)
		return
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("CAMPAIGN100 AUDIT: %d/%d completed, %d fights, %.2fs mean. %s" % [completed,report.campaigns,matches,report.mean_battle_seconds,output])
	quit()

func _spend(p: RefCounted, build: String, cursor: int, priorities: Array) -> int:
	while int(p.data.points) > 0:
		var spent: bool = false
		for trial: int in range(priorities.size()):
			var key: String = str(priorities[cursor % priorities.size()])
			cursor += 1
			if p.upgrade(key):
				spent = true
				break
		if not spent: break
	var perks: Array[Dictionary] = Moves.perks_for(str(p.active_id))
	for index: int in PERK_ORDER[build]:
		if int(p.data.perk_points) > 0 and index < perks.size() and not str(perks[index].id) in p.data.perks: p.choose_perk(str(perks[index].id))
	for kind: String in MOVE_TYPES[build]:
		for move: Dictionary in Moves.unlocked_moves(str(p.active_id), int(p.data.level)):
			if str(move.type) == kind:
				while p.can_upgrade_move(str(move.id)): p.upgrade_move(str(move.id))
	return cursor

func _record(level: int, result: Dictionary, first: bool) -> void:
	matches += 1
	seconds += float(result.duration)
	signatures += int(result.metrics.player.signatures) + int(result.metrics.rival.signatures)
	if result.reason == "timeout": timeouts += 1
	var key: String = str(level)
	if not stages.has(key): stages[key] = {"fights":0,"wins":0,"first_attempts":0,"first_wins":0,"hero_level_sum":0,"duration_sum":0.0,"timeouts":0,"opponents":{}}
	var stage: Dictionary = stages[key]
	stage.fights += 1
	stage.wins += 1 if result.winner == "player" else 0
	stage.first_attempts += 1 if first else 0
	stage.first_wins += 1 if first and result.winner == "player" else 0
	stage.hero_level_sum += int(result.player.level)
	stage.duration_sum += float(result.duration)
	stage.timeouts += 1 if result.reason == "timeout" else 0
	var opponent_id: String = str(result.rival.character_id)
	stage.opponents[opponent_id] = int(stage.opponents.get(opponent_id,0))+1
	for side: String in ["player","rival"]:
		var hero: String = str(result[side].get("story_boss_id", result[side].character_id))
		for move: Dictionary in result[side].get("moves",[]):
			var move_id: String = str(move.id)
			moves_available[move_id] = int(moves_available.get(move_id,0))+1
		for move_id: String in result.metrics[side].get("move_uses",{}):
			move_usage[move_id] = int(move_usage.get(move_id,0)) + int(result.metrics[side].move_uses[move_id])
			if result.winner == side: move_wins[move_id] = int(move_wins.get(move_id,0))+1
		for perk_id: String in result[side].get("perks",[]): perk_usage[hero+":"+perk_id] = int(perk_usage.get(hero+":"+perk_id,0))+1

func _source_hashes() -> Dictionary:
	var result: Dictionary = {}
	for path: String in ["combat_engine.gd","move_catalog.gd","combat_rules.gd","status_effects.gd","story_catalog.gd","story_progression.gd","campaign_config.gd"]:
		result[path] = FileAccess.get_sha256("res://scripts/" + path)
	return result
