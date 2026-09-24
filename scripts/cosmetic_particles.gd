extends RefCounted
## Deterministic pigment particles shared by fighters and collection swatches.
## Presentation only: no random generator, clocks, ownership or gameplay state.
const Ink = preload("res://scripts/particle_ink.gd")

static func samples(effect: Dictionary, time: float, body: Vector2, feet: Vector2, facing: float = 1.0, trail: bool = false, strength: float = 1.0, reduced: bool = false) -> Array[Dictionary]:
 var result: Array[Dictionary] = []
 if str(effect.get("id", "none")) == "none" or strength <= 0.001: return result
 var shape: String = str(effect.get("shape", "spark"))
 var count: int = clampi(int(effect.get("particles", 18)), 8, 28)
 if reduced: count = 5
 var t: float = 0.35 if reduced else time
 var color := Color(str(effect.get("color", "efbd63")))
 for index: int in range(count):
  var seed: float = float(index) * 2.39996 + 0.37
  var life: float = fposmod(t / (1.6 + fposmod(seed, 1.1)) + seed, 1.0)
  var opacity: float = minf(1.0, sin(life * PI) * 1.4) * strength
  var side: float = -1.0 if index % 2 == 0 else 1.0
  var at: Vector2
  var direction := Vector2(sin(seed) * 0.3, -1.0)
  if trail:
   at = body + Vector2(-(12 + life * 65) * facing, sin(seed * 3.0) * 18 + life * 16)
   direction = Vector2(-facing, 0.15)
   opacity *= 1.0 - life * 0.65
  else:
   # Flank the silhouette and keep the face clear. No ring or central disc.
   at = Vector2(body.x + side * (28 + fposmod(seed * 17, 28)), feet.y - 8 - life * maxf(60, feet.y - body.y + 38))
   at.x += sin(seed + t * 1.3) * 8
   if shape in ["petal", "rain", "ash"]:
    at.y = body.y - 30 + life * maxf(55, feet.y - body.y + 15)
    direction = Vector2(0.25, 1)
   if shape == "mote": at.y += sin(t * 1.7 + seed) * 9
   if shape == "mist":
    at = feet + Vector2(sin(seed) * (35 + life * 18), -5 - life * 24)
  result.append({"at":at, "direction":direction, "shape":shape, "color":Color(color, opacity), "size":1.7 + fposmod(seed * 3.1, 1.1), "angle":seed + t * (0.4 if shape == "petal" else 0.15)})
 return result

static func paint(canvas: CanvasItem, particles: Array[Dictionary]) -> void:
 for p: Dictionary in particles:
  var at: Vector2 = p.at
  var color: Color = p.color
  var radius: float = float(p.size)
  match str(p.shape):
   "mist":
    Ink.mote(canvas, at, Vector2(radius * 13, radius * 6), Color(color, color.a * 0.24), sin(float(p.angle)) * 0.12)
   "mote":
    Ink.mote(canvas, at, Vector2.ONE * radius * 4, Color(color, color.a * 0.2))
    Ink.mote(canvas, at, Vector2.ONE * radius * 1.4, color)
    Ink.mote(canvas, at, Vector2.ONE * radius * 0.5, Color(1,1,0.8,color.a))
   "petal", "leaf", "crystal":
    Ink.mote(canvas, at, Vector2.ONE * radius * 3, Color(color, color.a * 0.16))
    canvas.draw_set_transform(at, float(p.angle))
    var points: PackedVector2Array
    if str(p.shape) == "crystal":
     points = PackedVector2Array([Vector2(-radius,0),Vector2(0,-radius*2.5),Vector2(radius,0),Vector2(0,radius*2.5)])
    else:
     # Rounded shoulders and a tapered tip distinguish petals/leaves from gems.
     points = PackedVector2Array([Vector2(-radius,0),Vector2(-radius*0.8,-radius),Vector2(0,-radius*1.8),Vector2(radius*0.8,-radius),Vector2(radius,0.3*radius),Vector2(radius*0.2,radius*1.8),Vector2(-radius*0.6,radius)])
    canvas.draw_colored_polygon(points,color)
    canvas.draw_line(Vector2(0,-radius),Vector2(0,radius),Color(1,0.95,0.8,color.a*0.6),0.6,true)
    canvas.draw_set_transform(Vector2.ZERO)
   "ash", "dust":
    Ink.mote(canvas, at, Vector2(radius*2.5,radius*1.7),Color(color,color.a*0.6),float(p.angle))
    Ink.mote(canvas, at, Vector2.ONE*radius*0.65,color)
   _:
    Ink.spark(canvas,at,p.direction,radius*0.8,color,10.0 if str(p.shape)=="rain" else 7.0)
