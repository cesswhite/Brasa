extends SceneTree
## Packaging regression for the public source edition (no reserved audio pack).
const Director = preload("res://scripts/audio/audio_director.gd")
var failures := 0
var checks := 0

func _init() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PUBLIC SOURCE: " + message)

func _run() -> void:
	var audio := Director.new()
	root.add_child(audio)
	audio.setup("", false)
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/audio_events.json"))
	check(not catalog.get("cues", {}).is_empty(), "Production cue contract remains available")
	for cue: String in catalog.get("cues", {}):
		check(audio._available_paths(cue).is_empty(), "Public package has no reserved recording: " + cue)
	for event: String in catalog.get("ui_aliases", {}):
		audio.play_ui(event, {"operation_id": "public-source-" + event})
	var state: Dictionary = audio.debug_state()
	check(not state.missing.is_empty(), "Missing recordings are diagnosed")
	check(state.voices.is_empty(), "No voice plays a missing recording")
	check(int(state.cache_entries) == 0, "No fabricated stream is cached")
	audio.stop_session()
	audio.queue_free()
	await process_frame
	print("PUBLIC SOURCE: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
