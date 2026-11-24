extends Node2D
class_name PetActor
## 4x4 2.5D Pet Companion Actor (Mochi Cat, Kori Dog, Lumi Fairy) with smooth follow AI.

var kind: String = "cat"
var dir_row: int = 2
var hop_t: float = 0.0
var moving: bool = false
var sprite: Sprite2D

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.centered = true
	sprite.position = Vector2(0, -16)
	add_child(sprite)
	refresh_pet()

func refresh_pet() -> void:
	kind = GameState.pet_kind
	var tex := GameData.get_pet_sheet(kind)
	if tex and sprite:
		sprite.texture = tex
		sprite.hframes = 4
		sprite.vframes = 4
		var cell_w := float(tex.get_width()) / 4.0
		var sc := 44.0 / maxf(1.0, cell_w)
		sprite.scale = Vector2(sc, sc)

func follow_target(target_pos: Vector2, delta: float) -> void:
	if kind != GameState.pet_kind:
		refresh_pet()
	var diff := (target_pos + Vector2(-20, 8)) - position
	var dist := diff.length()
	if dist > 26.0:
		var spd := minf(185.0, dist * 3.8) * delta
		position += diff.normalized() * spd
		if absf(diff.x) > absf(diff.y):
			dir_row = 1 if diff.x < 0.0 else 3
		else:
			dir_row = 0 if diff.y < 0.0 else 2
		moving = true
		hop_t += delta * 9.5
	else:
		moving = false
		hop_t += delta * 3.0

	if sprite and sprite.texture:
		var col := (int(hop_t) % 4) if (moving or kind == "fairy") else 0
		sprite.frame_coords = Vector2i(col, clampi(dir_row, 0, 3))
		sprite.position.y = -16.0 + (sin(Time.get_ticks_msec() / 220.0) * 3.0 if kind == "fairy" else 0.0)
