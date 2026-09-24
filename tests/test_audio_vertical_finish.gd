extends "res://tools/audio_vertical_slice.gd"
## Gate-only subprocess: executes the real finalization path without recording,
## rendering, creating fighters, or accessing user preferences.
func _run() -> void:
	var input_path:=""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--input="): input_path=arg.trim_prefix("--input=")
	if input_path.is_empty() or not FileAccess.file_exists(input_path):
		push_error("Gate fixture input required")
		quit(2)
		return
	var input: Variant=JSON.parse_string(FileAccess.get_file_as_string(input_path))
	if not input is Dictionary:
		quit(2)
		return
	folder=input_path.get_base_dir()
	section_mode=str(input.get("mode","all"))
	observations.assign(input.get("records",[]))
	var missing: Array[String]=[]
	_finish(missing)
