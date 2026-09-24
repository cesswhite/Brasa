extends SceneTree
## Native visual fixture; it never starts Main, opens profiles or awards a battle.
## Default: require all23 packs. --bodies=ascua permits an explicitly partial pilot.
## --no-captures supports a headless geometry preflight. No importer runs here.
const Fighter = preload("res://scripts/fighter_view.gd")
const DamageArt = preload("res://scripts/damage_art.gd")
const Sequences = preload("res://scripts/fighter_animation_set.gd")
const Cosmetics = preload("res://scripts/cosmetic_catalog.gd")
const Families = preload("res://scripts/character_families.gd")
const Story = preload("res://scripts/story_catalog.gd")
const Moves = preload("res://scripts/move_catalog.gd")
const Layout = preload("res://scripts/ui/battle_layout.gd")
const Visuals = preload("res://scripts/ui/game_visual_system.gd")
const SIZES: Array[Vector2] = [Vector2(1360,880),Vector2(390,844)]
const POSES: Array[String] = ["guard","strike","reaction","ko"]
const POSE_LABELS := {"guard":"Guardia","strike":"Golpe","reaction":"Reacción","ko":"KO"}
var checks := 0
var failures := 0
var issues: Array[String] = []
var bodies: Array[String] = []
var output := ""
var no_captures := false
var explicit_subset := false
var terminal_contact_checks := 0
var unpaired_ko_samples := 0
var samples: Array[Dictionary] = []
var captures: Array[Dictionary] = []
var before: Dictionary = {}
var canvas: SubViewport
var stage: Node2D
var backdrop: TextureRect

func _init() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks+=1
	if ok: return
	failures+=1;issues.append(message)
	if issues.size()<=40: push_error("ILLUSTRATED VISUAL: "+message)

func _run() -> void:
	create_timer(180,true,false,true).timeout.connect(func(): push_error("ILLUSTRATED VISUAL timeout");quit(1))
	for arg: String in OS.get_cmdline_user_args():
		if arg=="--no-captures": no_captures=true
		if arg.begins_with("--capture-dir="): output=arg.trim_prefix("--capture-dir=")
		if arg.begins_with("--bodies="):
			explicit_subset=true
			for body: String in arg.trim_prefix("--bodies=").split(",",false): bodies.append(body)
	if not explicit_subset:
		for body: String in Sequences.BASE_TO_BODY.values(): bodies.append(body)
	if output.is_empty(): output=ProjectSettings.globalize_path("res://../../work/illustrated-damage/native")
	DirAccess.make_dir_recursive_absolute(output)
	check(not bodies.is_empty(),"at least one body requested")
	if not explicit_subset: check(bodies.size()==23,"full gate includes all23 bodies")
	for body: String in bodies:
		check(body in Sequences.BASE_TO_BODY.values() and DamageArt.prepare(body),"complete40-pose illustrated pack required: "+body)
	if not no_captures: check(DisplayServer.get_name()!="headless","native image capture requires a real renderer")
	if failures>0: _finish();return
	before=_hashes()
	canvas=SubViewport.new();canvas.size=Vector2i(SIZES[0]);canvas.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(canvas)
	backdrop=TextureRect.new();backdrop.texture=load("res://assets/arena-faroles-v2.png") as Texture2D
	backdrop.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;backdrop.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.size=SIZES[0];backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(backdrop)
	stage=Node2D.new();canvas.add_child(stage)
	for body: String in bodies:
		for view_size: Vector2 in SIZES:
			_resize(view_size)
			for facing: int in [1,-1]:
				for pose: String in POSES:
					_clear()
					var pair := _pair(body,view_size)
					var actor = pair.left if facing>0 else pair.right
					var other = pair.right if facing>0 else pair.left
					_present(actor,pose)
					_verify(pair,actor,other,body,pose,view_size)
					if body==bodies[0] and not no_captures:
						_context_labels(body,pose,view_size)
						await _capture("context-%s-%s-%dx%d-facing%d" % [body,pose,int(view_size.x),int(view_size.y),facing])
		if not no_captures: await _sheet(body)
	_clear()
	check(_hashes()==before,"runtime and source PNG/JSON hashes remain unchanged")
	if not no_captures: check(captures.size()==16+bodies.size(),"every body has an eight-pose sheet plus16 contextual pilot captures")
	_finish()

func _definition(body: String) -> Dictionary:
	if body=="ascua": return Story.boss_definition(1)
	if body=="vespera": return Story.boss_definition(2)
	return Cosmetics.body_definition(body)

func _resize(view_size: Vector2) -> void:
	canvas.size=Vector2i(view_size);backdrop.size=view_size

func _clear() -> void:
	for child: Node in stage.get_children(): child.free()

func _actor(body: String, facing: int, at: Vector2, zoom: float):
	var actor := Fighter.new();stage.add_child(actor);actor.set_process(false)
	actor.setup_character(_definition(body),facing)
	actor.position=at;actor.scale=Vector2.ONE*zoom
	actor.reset_pose();actor.set_health_ratio(0.39);actor._process(1.0)
	return actor

func _pair(body: String, view_size: Vector2) -> Dictionary:
	var layout: Dictionary=Layout.calculate(view_size,true)
	var left = _actor(body,1,layout.player_at,float(layout.actor_scale))
	var right = _actor(body,-1,layout.rival_at,float(layout.actor_scale))
	var limit := (Vector2(layout.rival_at).x-Vector2(layout.player_at).x)/(2.0*float(layout.actor_scale))-6.0
	left.set_combat_lane(limit,right);right.set_combat_lane(limit,left)
	return {"left":left,"right":right,"layout":layout,"left_root":left.transform,"right_root":right.transform}

func _move(body: String, guard: bool) -> Dictionary:
	for move: Dictionary in Moves.moves_for(Families.base_body(body)):
		if (guard and move.type=="guard") or (not guard and not str(move.type) in ["guard","counter"]): return move
	# Some fighters do not choose guard in combat. This sheet explicitly probes
	# the common guard animation using Ascua's real definition, not a new ability.
	if guard:
		for move: Dictionary in Moves.moves_for("ascua"):
			if move.type=="guard": return move
	return {}

func _present(actor, pose: String) -> void:
	if pose in ["guard","strike","ko"]:
		var move := _move(str(actor.get_animation_state().body_id),pose=="guard")
		check(not move.is_empty(),"real presentation definition available for "+pose)
		if move.is_empty(): return
		actor.play_move(move,float(move.impact_delay))
		if pose=="ko":
			var last_x: float=actor._sprite.position.x
			var paired: bool=bool(actor.get_contact_state().paired)
			actor.set_health_ratio(0.0);actor.resolve_battle(false)
			if paired:
				terminal_contact_checks+=1
				check(absf(actor._sprite.position.x-last_x)<0.01,"%s/facing%d/paired: terminal illustrated frame retains the outgoing contact origin" % [str(actor.get_animation_state().body_id),actor.facing])
			else:
				# Unpaired specimen sheets have no opponent/contact translation to retain.
				# Their world root and full painted silhouette are checked by _sheet.
				unpaired_ko_samples+=1
			actor._process(1.2)
	else:
		actor.play_reaction({"result":"critical","damage":30,"target_hp":50.0,"animation_type":"heavy","presentation_elapsed":0.18})
		actor._process(0.04)

func _painted(actor) -> Rect2:
	var frame: Dictionary=actor._current_frame()
	var bounds:=Rect2(frame.bounds)
	var transform: Transform2D=actor._sprite.global_transform
	var result:=Rect2(transform*(bounds.position+actor._sprite.offset),Vector2.ZERO)
	for point: Vector2 in [Vector2(bounds.end.x,bounds.position.y),bounds.end,Vector2(bounds.position.x,bounds.end.y)]:
		result=result.expand(transform*(point+actor._sprite.offset))
	return result

func _verify(pair: Dictionary, actor, other, body: String, pose: String, view_size: Vector2) -> void:
	var label:="%s/%s/%s/facing%d" % [body,pose,str(view_size),actor.facing]
	var state: Dictionary=actor.get_animation_state()
	var rect:=_painted(actor)
	var target:=_painted(other)
	check(state.damage_art and state.body_id==body,label+": actual frame uses this body's illustrated pack")
	check(actor._sprite.texture==actor._current_frame().texture and state.source_path==actor._current_frame().source_path,label+": painted texture and geometry describe the same frame")
	check(pair.left.transform.is_equal_approx(pair.left_root) and pair.right.transform.is_equal_approx(pair.right_root),label+": roots/scales stay unchanged")
	check(is_equal_approx(float(actor._current_frame().scale),1.0/1.5),label+": shared physical pixel density stays fixed")
	check(Rect2(Vector2.ZERO,view_size).grow(1).encloses(rect) and Rect2(Vector2.ZERO,view_size).grow(1).encloses(target),label+": both illustrated silhouettes stay in viewport")
	check(not rect.intersects(pair.layout.primary) and not target.intersects(pair.layout.primary),label+": both silhouettes leave the CTA clear")
	var sample := {"body":body,"pose":pose,"size":[view_size.x,view_size.y],"facing":actor.facing,"bounds":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"target_bounds":[target.position.x,target.position.y,target.size.x,target.size.y],"frame":state.frame,"source_path":state.source_path,"root_scale":actor.scale.x,"draw_scale":[actor._sprite.scale.x,actor._sprite.scale.y],"tier":actor.damage_state.tier,"contact":actor.get_contact_state()}
	if pose=="strike":
		var gap:float=target.position.x-rect.end.x if actor.facing>0 else rect.position.x-target.end.x
		var penetration:=maxf(0.0,-gap)/maxf(1.0,target.size.x)
		sample["gap_world"]=gap/actor.scale.x;sample["overlap_fraction"]=penetration
		check(gap<=8.0*actor.scale.x and penetration<=0.80,label+": actual damaged opponent receives bounded visual contact")
		check(rect.position.y<target.end.y and rect.end.y>target.position.y,label+": contact overlaps the visible opponent vertically")
	if pose=="ko": check(state.frame=="grounded" and actor._mode=="fall",label+": KO settles in authored grounded pose")
	samples.append(sample)
	check(int(DamageArt.cache_info().count)<=6,label+": illustrated bank cache remains bounded")

func _label(text: String, at: Vector2, width: float, compact: bool=false) -> void:
	var label:=Label.new();label.text=text;label.position=at;label.size=Vector2(width,42);label.clip_text=true
	Visuals.apply_label(label,"secondary" if compact else "card","text_primary");stage.add_child(label)

func _context_labels(body: String, pose: String, view_size: Vector2) -> void:
	var compact:=view_size.x<600
	var layout: Dictionary=Layout.calculate(view_size,true)
	var pad:=16.0 if compact else 32.0
	_label("PRUEBA VISUAL · "+body,Vector2(pad,18),view_size.x-pad*2,compact)
	_label(str(POSE_LABELS[pose])+" · pack ilustrado · sin partida",Vector2(pad,58),view_size.x-pad*2,true)
	var footer:=Label.new();footer.text="MUESTRA DE ANIMACIÓN";footer.position=layout.primary.position;footer.size=layout.primary.size;footer.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;footer.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	Visuals.apply_label(footer,"label","text_secondary");stage.add_child(footer)

func _sheet(body: String) -> void:
	_clear();_resize(Vector2(1360,880))
	_label(body+" · familia ilustrada compartida en daño2/3",Vector2(28,18),1304)
	_label("MUESTRA DE CLIPS · guardia común no implica habilidad nueva · escala corporal fija",Vector2(28,56),1304,true)
	for row: int in range(2):
		var facing:=1 if row==0 else -1
		for column: int in range(POSES.size()):
			var at:=Vector2(170+340*column,390+400*row)
			var actor = _actor(body,facing,at,1.0)
			var home: Transform2D=actor.transform
			_present(actor,POSES[column])
			check(actor.transform.is_equal_approx(home),body+": sheet does not resize individual poses")
			check(Rect2(Vector2.ZERO,Vector2(1360,880)).grow(1).encloses(_painted(actor)),body+": sheet retains full illustrated silhouette")
			_label(str(POSE_LABELS[POSES[column]])+" · "+("→" if facing>0 else "←"),Vector2(column*340+28,104+400*row),284,true)
	await _capture("sheet-"+body)

func _capture(name: String) -> void:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var path:=output.path_join(name+".png")
	var image:=canvas.get_texture().get_image()
	check(image!=null and not image.is_empty(),name+": native renderer returned pixels")
	if image==null or image.is_empty(): return
	var error:=image.save_png(path)
	check(error==OK,name+": capture saved")
	if error==OK: captures.append({"path":path,"sha256":FileAccess.get_sha256(path),"size":[image.get_width(),image.get_height()]})

func _hashes() -> Dictionary:
	var result: Dictionary={}
	for script: String in ["scripts/fighter_view.gd","scripts/damage_art.gd","scripts/fighter_animation_set.gd","scripts/ui/battle_layout.gd","scripts/combat_engine.gd","scripts/progression.gd","scripts/story_progression.gd"]:
		result[script]=FileAccess.get_sha256("res://"+script)
	for body: String in bodies:
		for bank: String in DamageArt.BANKS:
			for extension: String in ["png","json"]:
				var path:=DamageArt.ROOT+body+"-"+bank+"."+extension
				result[path]=FileAccess.get_sha256(path)
	return result

func _finish() -> void:
	var file:=FileAccess.open(output.path_join("validation.json"),FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify({"checks":checks,"failures":failures,"issues":issues,"bodies":bodies,"full_roster":not explicit_subset,"renderer":DisplayServer.get_name(),"native_captures":not no_captures,"captures":captures,"samples":samples,"terminal_contact_checks":terminal_contact_checks,"unpaired_ko_samples":unpaired_ko_samples,"sources_before":before,"sources_after":_hashes() if not before.is_empty() else {},"cache":DamageArt.cache_info(),"profile_files_opened":false,"scope":"visual clip fixture; no simulated victories or new guard abilities"},"\t")+"\n")
	print("ILLUSTRATED VISUAL: %d checks, %d failures; %d bodies; %d PNG" % [checks,failures,bodies.size(),captures.size()])
	quit(0 if failures==0 else 1)
