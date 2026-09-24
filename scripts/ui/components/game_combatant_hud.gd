extends Panel
## Painted, responsive combat identity. Values are supplied by the battle owner.
const Visuals=preload("res://scripts/ui/game_visual_system.gd")
var name_label:Label
var level_label:Label
var hp_label:Label
var bar:ProgressBar
var rival:=false
func _init():
 theme=Visuals.theme()
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_theme_stylebox_override("panel",Visuals.panel("reward",0))
 set_meta("game_component","combatant_hud")
 name_label=_label("title","text_primary")
 level_label=_label("caption","current")
 hp_label=_label("secondary","text_primary")
 bar=ProgressBar.new();bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;bar.step=.01
 Visuals.apply_progress(bar,"health");add_child(bar)
 bar.value_changed.connect(func(_value):refresh_health())
 resized.connect(_layout)
func _label(role:String,tone:String)->Label:
 var label=Label.new();Visuals.apply_label(label,role,tone)
 label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 label.clip_text=true;label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 add_child(label);return label
func configure(is_rival:bool):
 rival=is_rival
 Visuals.apply_progress(bar,"rival" if rival else "health")
 bar.fill_mode=ProgressBar.FILL_END_TO_BEGIN if rival else ProgressBar.FILL_BEGIN_TO_END
 _layout()
func refresh_health():
 hp_label.text="%d / %d" % [ceili(bar.value),ceili(bar.max_value)]
 hp_label.tooltip_text=hp_label.text+" de vida"
func _layout():
 if bar==null:return
 var narrow=size.x<220
 var tight=size.y<104
 var pad=12.0 if narrow else 20.0
 var width=maxf(0,size.x-pad*2)
 for label:Label in [name_label,level_label,hp_label]:
  label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT if rival else HORIZONTAL_ALIGNMENT_LEFT
 name_label.add_theme_font_size_override("font_size",18 if narrow or tight else 26)
 name_label.position=Vector2(pad,8);name_label.size=Vector2(width,26 if narrow or tight else 34)
 level_label.position=Vector2(pad,35 if narrow or tight else 43);level_label.size=Vector2(width,18)
 level_label.add_theme_font_size_override("font_size",11 if narrow else 12)
 bar.position=Vector2(pad,57 if narrow else (53 if tight else 62));bar.size=Vector2(width,12)
 hp_label.position=Vector2(pad,72 if narrow else (67 if tight else 78));hp_label.size=Vector2(width,22)
 hp_label.add_theme_font_size_override("font_size",12 if narrow else 14)
