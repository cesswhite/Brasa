extends SceneTree
## Exercises real StoryProgression with engine summaries. Saves are disabled in this fixture.
const Story = preload("res://scripts/story_catalog.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Balance = preload("res://scripts/balance.gd")
const Battle = preload("res://scripts/combat_engine.gd")
const Audit = preload("res://tests/simulate_story.gd")
class MemoryCampaign extends "res://scripts/story_progression.gd":
	func save() -> bool:
		last_save_ok = true
		return true
var checks: int = 0
var failures: int = 0

func _init() -> void:
	for hero_index: int in range(Catalog.IDS.size()):
		var id: String = Catalog.IDS[hero_index]
		for build_index: int in range(Audit.BUILDS.size()):
			var build: String = str(Audit.BUILDS.keys()[build_index])
			var priorities: Array = Audit.BUILDS[build]
			var progression = MemoryCampaign.new()
			check(progression.select_character(id), "Fresh campaign selects " + id)
			var count: int = 0
			var cursor: int = 0
			var previous_loss_xp: Dictionary = {}
			while not progression.is_complete() and count < 40:
				while int(progression.data.points) > 0:
					var allocated: bool = false
					for trial: int in range(priorities.size()):
						var key: String = str(priorities[cursor % priorities.size()])
						cursor += 1
						if progression.upgrade(key):
							allocated = true
							break
					if not allocated: break
				var engine = Battle.new()
				engine.start(progression.active_combatant(), progression.make_rival(), 821000000 + hero_index * 1000000 + build_index * 100000 + count)
				engine.advance(60.0)
				var stage_before: int = progression.current_stage()
				var result: Dictionary = progression.reward_match(engine.summary())
				check(bool(result.get("accepted", false)), "Real engine result accepted for stage and character")
				var won: bool = engine.winner == "player"
				check(progression.current_stage() == stage_before + (1 if won else 0), "Only victory advances actual campaign")
				var expected_xp: int = int(Story.stage(stage_before).xp_win if won else Story.stage(stage_before).xp_loss)
				if won:
					check(int(result.xp_gained) == expected_xp, "First-clear victory awards the declared stage XP")
				else:
					check(int(result.xp_gained) > 0 and int(result.xp_gained) <= expected_xp, "Defeat grants bounded positive XP")
					if previous_loss_xp.has(stage_before):
						check(int(result.xp_gained) <= int(previous_loss_xp[stage_before]), "Repeated defeats never increase farming rewards")
					previous_loss_xp[stage_before] = int(result.xp_gained)
				count += 1
			check(progression.is_complete() and int(progression.data.matches) == count, "Actual campaign terminates: " + id + "/" + build)
			check(count >= 8 and count <= 40 and int(progression.data.level) > 1, "Completion requires progression with bounded sampled retries")
			check(str(progression.data.badge) == str(Story.CONFIG.badge) and progression.make_rival().is_empty(), "Boss completion grants badge and has no hidden next fight")
	print("STORY CAMPAIGN: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("STORY CAMPAIGN FAIL: " + message)
