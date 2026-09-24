extends SceneTree
const Harness=preload("res://tools/audio_vertical_slice.gd")
var checks:=0
var failures:=0
func _init() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(message)
func _run() -> void:
	var expected: Array[String]=["normal_pause","reduced_motion"]
	check(Harness.expected_sections("all")==expected,"All selects both typed section IDs")
	check(Harness.expected_sections("normal")==["normal_pause"],"Normal selects only its section")
	check(Harness.expected_sections("reduced")==["reduced_motion"],"Reduced selects only its section")
	check(Harness.expected_sections("invalid").is_empty(),"Unknown section is not accepted")
	var absent: Array[Dictionary]=[]
	check(Harness.completion_problems(absent,expected).size()==2,"No completed sections cannot pass")
	var empty_script:=GDScript.new()
	check(not Harness.fixture_problem(empty_script).is_empty(),"Uncompiled fixture is rejected")
	var wrong_script:=GDScript.new()
	wrong_script.source_code="extends RefCounted\n"
	check(wrong_script.reload()==OK,"Compile safe missing-class fixture")
	check(not Harness.fixture_problem(wrong_script).is_empty(),"Missing inner Main fixture is rejected")
	check(Harness.fixture_problem(load("res://tests/test_identity_integration.gd")).is_empty(),"Actual Main fixture compiles")
	var folder:=ProjectSettings.globalize_path("res://../../work/audio/harness-gate/%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(folder)
	var records: Array[Dictionary]=[]
	var coverage: Dictionary={"ascua_moves":["ascua_cobre","ascua_forja","ascua_brasero","ascua_obsidiana","ascua_crater"],"signature":1,"phases":[1,2],"ko":true,"burn":1,"results":["critical","dodge"]}
	for id: String in expected:
		var path:=folder.path_join(id+".wav")
		var wave:=AudioStreamWAV.new()
		wave.format=AudioStreamWAV.FORMAT_16_BITS
		wave.mix_rate=8000
		var samples:=PackedByteArray()
		samples.resize(16000)
		wave.data=samples
		check(wave.save_to_wav(path)==OK,"Write explicit synthetic gate fixture, not an audio-quality recording")
		var trace_path:=folder.path_join(id+".json")
		var trace:=FileAccess.open(trace_path,FileAccess.WRITE)
		trace.store_string(JSON.stringify({"section":id,"event_hash":"test-fixture-hash","events":[{"type":"finished"}]}))
		trace.close()
		records.append({"id":id,"coverage":coverage.duplicate(true),"duration":1.0,"wave_seconds":1.0,"wav":path,"trace":trace_path,"event_hash":"test-fixture-hash"})
	check(Harness.completion_problems(records,expected).is_empty(),"Both structurally complete recordings pass gate")
	var partial: Array[Dictionary]=[records[0]]
	check(not Harness.completion_problems(partial,expected).is_empty(),"One completed section cannot stand in for two")
	var duplicate: Array[Dictionary]=[records[0],records[0]]
	check(not Harness.completion_problems(duplicate,expected).is_empty(),"Duplicated section cannot stand in for missing section")
	for key: String in ["coverage","duration","wave_seconds","wav","trace","event_hash"]:
		var malformed: Array[Dictionary]=records.duplicate(true)
		malformed[0].erase(key)
		check(not Harness.completion_problems(malformed,expected).is_empty(),"Missing "+key+" cannot pass")
	var no_ko: Array[Dictionary]=records.duplicate(true)
	no_ko[0].coverage.ko=false
	check(not Harness.completion_problems(no_ko,expected).is_empty(),"Missing measured KO cannot pass")
	var stale: Array[Dictionary]=records.duplicate(true)
	stale[0].event_hash="other-run"
	check(not Harness.completion_problems(stale,expected).is_empty(),"Stale trace cannot certify new run")
	var truncated: Array[Dictionary]=records.duplicate(true)
	truncated[0].wave_seconds=0.25
	check(not Harness.completion_problems(truncated,expected).is_empty(),"Truncated recording cannot pass")
	for mode: String in ["all","normal","reduced","missing"]:
		var chosen: Array[Dictionary]=[]
		for record: Dictionary in records:
			if mode!="missing" and str(record.id) in Harness.expected_sections(mode): chosen.append(record)
		var child_folder:=folder.path_join("finish-"+mode)
		DirAccess.make_dir_recursive_absolute(child_folder)
		var input_path:=child_folder.path_join("input.json")
		var input:=FileAccess.open(input_path,FileAccess.WRITE)
		input.store_string(JSON.stringify({"mode":"all" if mode=="missing" else mode,"records":chosen}))
		input.close()
		var output: Array=[]
		var exit_code:=OS.execute(OS.get_executable_path(),["--headless","--path",ProjectSettings.globalize_path("res://"),"--script","res://tests/test_audio_vertical_finish.gd","--","--input="+input_path],output,true)
		check(exit_code==(1 if mode=="missing" else 0),"Actual _finish exits with correct code for "+mode)
		var validation_path:=child_folder.path_join("validation.json")
		check(FileAccess.file_exists(validation_path),"Actual _finish writes validation for "+mode)
		var validation: Variant=JSON.parse_string(FileAccess.get_file_as_string(validation_path)) if FileAccess.file_exists(validation_path) else null
		check(validation is Dictionary and bool(validation.get("complete",false))==(mode!="missing"),"Actual _finish reports success/failure honestly for "+mode)
		check(validation is Dictionary and int(validation.get("checks",0))>0,"Actual _finish reaches checks for "+mode)
		if mode!="missing":
			check(validation is Dictionary and int(validation.get("failures",-1))==0 and validation.get("expected_sections")==Harness.expected_sections(mode),"Actual _finish validates selected sections for "+mode)
	print("AUDIO VERTICAL GATE: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
