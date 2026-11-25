extends Node2D
class_name ChildActor
## Post-Marriage Child Actor with 3 Growth Stages:
## Stage 1 (days 0..2): Glowing World-Tree Cradle inside farmhouse
## Stage 2 (days 3..5): Toddler walking playfully inside farmhouse / loft
## Stage 3 (days 6+): Young Explorer walking inside farmhouse & visiting World Tree Plaza on sunny afternoons!

var sprite: Sprite2D
var name_label: Label
var _anim_t: float = 0.0
var _patrol_t: float = 0.0
var _dir_row: int = 2
var active_scene: String = "farmhouse"
var home_anchor: Vector2 = Vector2(7.5 * 32.0, 6.5 * 32.0)

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.centered = true
	sprite.position = Vector2(0, -14)
	add_child(sprite)

	name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(-52, -52)
	name_label.size = Vector2(104, 18)
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color("#fde68a"))
	name_label.add_theme_color_override("font_outline_color", Color("#0f172a"))
	name_label.add_theme_constant_override("outline_size", 4)
	add_child(name_label)

	refresh_child()

func refresh_child() -> void:
	var born := bool(GameState.child_data.get("born", false))
	if not born:
		visible = false
		return
	var stg := int(GameState.child_data.get("stage", 1))
	var cname := str(GameState.child_data.get("name", "ลูมิน่า"))
	var hr := GameState.time_min / 60.0
	if stg >= 3 and GameState.weather == "sunny" and hr >= 11.0 and hr <= 16.5:
		active_scene = "outdoor"
		home_anchor = Vector2(41.2 * 32.0, 30.8 * 32.0)
	elif GameState.house_level >= 2 and hr >= 20.0 and stg >= 2:
		active_scene = "farmhouse_upstairs"
		home_anchor = Vector2(6.5 * 32.0, 6.2 * 32.0)
	else:
		active_scene = "farmhouse"
		home_anchor = Vector2(4.8 * 32.0, 4.6 * 32.0) if stg == 1 else Vector2(7.5 * 32.0, 6.6 * 32.0)

	position = home_anchor
	visible = (GameState.current_scene == active_scene)
	if name_label:
		var tag := "👶 " if stg == 1 else ("🌱 " if stg == 2 else "🧭 ")
		name_label.text = tag + cname
	if sprite:
		sprite.visible = (stg >= 2)
		if stg >= 2:
			var base_cid := GameState.spouse_id if GameState.spouse_id != "" else str(GameState.hero_custom.get("base_id", "01_ren"))
			var tex := GameData.get_walk_sheet(base_cid)
			if tex:
				sprite.texture = tex
				sprite.hframes = 9
				sprite.vframes = 4
				var cell_w := float(tex.get_width()) / 9.0
				var mul := 0.62 if stg == 2 else 0.74
				var sc := (64.0 / maxf(1.0, cell_w)) * mul
				sprite.scale = Vector2(sc, sc)
				sprite.position = Vector2(0, -14.0 if stg == 2 else -17.0)
	queue_redraw()

func update_child(delta: float) -> void:
	if not bool(GameState.child_data.get("born", false)):
		visible = false
		return
	visible = (GameState.current_scene == active_scene)
	if not visible:
		return
	var stg := int(GameState.child_data.get("stage", 1))
	_patrol_t += delta
	if stg == 1:
		position = home_anchor
	else:
		var rad := 26.0 if stg == 2 else 42.0
		var target := home_anchor + Vector2(sin(_patrol_t * 1.1) * rad, cos(_patrol_t * 0.8) * (rad * 0.45))
		var diff := target - position
		var moving := diff.length() > 2.0
		if moving:
			position += diff.normalized() * minf(diff.length(), 42.0 * delta)
			_dir_row = 1 if diff.x < 0.0 else 3
			_anim_t += delta * 9.5
		else:
			_dir_row = 2
			_anim_t += delta * 4.0
		if sprite and sprite.texture:
			sprite.frame_coords = Vector2i(int(_anim_t) % 9, _dir_row)
	queue_redraw()

func _draw() -> void:
	var stg := int(GameState.child_data.get("stage", 1))
	if stg == 1:
		var glow := 0.25 + sin(Time.get_ticks_msec() / 400.0) * 0.08
		draw_circle(Vector2(0, -6), 20.0, Color(1.0, 0.92, 0.45, glow))
		draw_rect(Rect2(-14, -14, 28, 18), Color("#78350f"))
		draw_rect(Rect2(-14, -14, 28, 18), Color("#fde047"), false, 2.0)
		draw_rect(Rect2(-10, -11, 20, 12), Color("#fbcfe8"))
		draw_circle(Vector2(-3, -6), 4.5, Color("#fed7aa"))
	else:
		draw_circle(Vector2(0, 2), 8.0, Color(0, 0, 0, 0.24))
		if stg >= 3:
			draw_rect(Rect2(-9, -36, 18, 3), Color("#eab308"))
			draw_rect(Rect2(-5, -40, 10, 4), Color("#facc15"))
