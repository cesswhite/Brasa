extends SceneTree
const Particles=preload("res://scripts/cosmetic_particles.gd")
const Cosmetics=preload("res://scripts/cosmetic_catalog.gd")
const Fighter=preload("res://scripts/fighter_view.gd")
const Characters=preload("res://scripts/character_catalog.gd")
const Editor=preload("res://scripts/ui/customization_panel.gd")
const Fixtures=preload("res://tests/test_customization_visuals.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1;push_error(label)
func _init():run.call_deferred()
func run():
 for slot:String in ["aura_id","trail_id"]:
  for effect:Dictionary in Cosmetics.items(slot):
   var sample=Particles.samples(effect,0.7,Vector2(0,-85),Vector2.ZERO,1,slot=="trail_id")
   check(sample==Particles.samples(effect,0.7,Vector2(0,-85),Vector2.ZERO,1,slot=="trail_id"),"Particle sampling is deterministic")
   check(sample.size()<=28,"Per-effect particle budget is bounded")
   if effect.id=="none":check(sample.is_empty(),"None draws no cosmetic particles")
   else:check(sample.size()>=8,"Each visible effect has readable density")
   for particle:Dictionary in sample:check(particle.at.is_finite() and particle.color.a>0 and particle.color.a<=1,"Particle state is finite and visible")
   var quiet=Particles.samples(effect,0.7,Vector2(0,-85),Vector2.ZERO,1,slot=="trail_id",1,true)
   check(quiet==Particles.samples(effect,9.4,Vector2(0,-85),Vector2.ZERO,1,slot=="trail_id",1,true) and quiet.size()<=5,"Reduced motion is sparse and completely static")
 var actor=Fighter.new();root.add_child(actor);actor.set_process(false)
 var descriptor=Characters.definition("onix");descriptor.appearance=Cosmetics.default_appearance("onix");descriptor.appearance.trail_id="cometa";descriptor.appearance.aura_id="petalos"
 actor.setup_character(descriptor)
 check(actor._cosmetic_layer.get_index()>actor._sprite.get_index(),"Particles render in front of opaque sprite art")
 actor.play_attack();actor._process(0.18)
 check(actor._cosmetic_trail_energy>0,"Attack starts particle trail")
 actor._process(0.40)
 check(actor._cosmetic_trail_energy>0 and not actor._trail.visible,"Particle trail remains after brief sprite ghost ends")
 actor.motion_paused=true
 var clock=actor._clock;var energy=actor._cosmetic_trail_energy
 actor._process(3)
 check(actor._clock==clock and actor._cosmetic_trail_energy==energy,"Pause freezes particle clock and decay")
 actor.motion_paused=false;actor._process(2)
 check(actor._cosmetic_trail_energy==0,"Trail decays fully in idle")
 actor.free()
 var panel=Editor.new();root.add_child(panel);panel.configure(Fixtures.MemoryIdentity.new(),"onix",false)
 panel.select_tab(2);panel._select_effect_section(1);panel._choose_item("trail_id","cometa")
 panel._actor.set_process(false);panel.set_process(false)
 check(panel._try_id=="cometa" and panel._actor._mode=="move","Locked trail immediately demonstrates movement")
 panel._actor._process(4);panel._process(2.3)
 check(panel._actor._mode=="move","Idle effect preview repeats its movement automatically")
 panel._actor._process(4);panel._actor.reduced_motion=true;panel._process(4)
 check(panel._actor._mode=="idle","Reduced motion does not trigger preview attacks")
 panel._try_back.pressed.emit()
 check(panel._draft.trail_id=="none" and panel._actor.appearance.trail_id=="none" and not panel._confirm.disabled,"Leaving locked preview restores actual ownership and save action")
 panel.free()
 print("COSMETIC EFFECTS: %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
