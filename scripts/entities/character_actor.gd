extends Node2D
class_name CharacterActor
## Reusable 2.5D HD-2D Character Sprite Actor for Player & all 16 Town NPCs.
## Supports walk_9x4, idle_6x4, interact_8x4, HD/Classic sheets, and GPU Protagonist Recolor Shader.

var char_id: String = "01_ren"
var display_name: String = ""
var is_player: bool = false
var dir_row: int = 2 # 0=up, 1=left, 2=down, 3=right
var anim_mode: String = "idle" # walk, idle, interact
var anim_t: float = 0.0
var interact_timer: float = 0.0
var badge_text: String = ""

var sprite: Sprite2D
var name_label: Label
var badge_label: Label
var _shader_mat: ShaderMaterial

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.centered = true
	sprite.position = Vector2(0, -22)
	add_child(sprite)

	if is_player:
		var sh := load("res://shaders/protagonist_recolor.gdshader") as Shader
		if sh:
			_shader_mat = ShaderMaterial.new()
			_shader_mat.shader = sh
			sprite.material = _shader_mat

	if not is_player:
		name_label = Label.new()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.position = Vector2(-56, -66)
		name_label.size = Vector2(112, 18)
		name_label.add_theme_font_size_override("font_size", 11)
		name_label.add_theme_color_override("font_color", Color("#fef3c7"))
		name_label.add_theme_color_override("font_outline_color", Color("#0f172a"))
		name_label.add_theme_constant_override("outline_size", 4)
		add_child(name_label)

		badge_label = Label.new()
		badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_label.position = Vector2(-30, -82)
		badge_label.size = Vector2(60, 18)
		badge_label.add_theme_font_size_override("font_size", 13)
		add_child(badge_label)

	refresh_appearance()

func refresh_appearance() -> void:
	if is_player:
		var hc: Dictionary = GameState.hero_custom
		char_id = str(hc.get("base_id", "01_ren"))
		if _shader_mat:
			_shader_mat.set_shader_parameter("hue_shift_deg", float(hc.get("hue", 0.0)))
			_shader_mat.set_shader_parameter("sat_mult", float(hc.get("sat", 100.0)) / 100.0)
			_shader_mat.set_shader_parameter("val_mult", float(hc.get("val", 100.0)) / 100.0)
			_shader_mat.set_shader_parameter("skin_mode", int(GameState.SKIN_MODES.get(str(hc.get("skin", "none")), 0)))
	elif name_label:
		name_label.text = display_name
	_apply_frame()

func update_actor(delta: float, moving: bool, sprinting: bool = false) -> void:
	if interact_timer > 0.0:
		interact_timer -= delta
		anim_mode = "interact"
		anim_t += delta * 9.0
	elif moving:
		anim_mode = "walk"
		anim_t += delta * (12.5 if sprinting else 9.0)
	else:
		if anim_mode != "interact" or is_player:
			anim_mode = "idle"
		anim_t += delta * 4.5
	if badge_label:
		badge_label.text = badge_text
		badge_label.position.y = -82.0 + sin(Time.get_ticks_msec() / 240.0 + position.x) * 2.5
	_apply_frame()
	queue_redraw()

func _apply_frame() -> void:
	if not sprite:
		return
	var tex: Texture2D
	var cols := 6
	var row := clampi(dir_row, 0, 3)
	if anim_mode == "walk":
		tex = GameData.get_walk_sheet(char_id)
		cols = 9
	elif anim_mode == "interact":
		tex = GameData.get_interact_sheet(char_id)
		cols = 8
		row = 1 if is_player else 2
	else:
		tex = GameData.get_idle_sheet(char_id)
		cols = 6
	if tex == null:
		tex = GameData.get_walk_sheet(char_id)
		cols = 9
	if tex == null:
		return
	sprite.texture = tex
	sprite.hframes = cols
	sprite.vframes = 4
	var cell_w := float(tex.get_width()) / float(cols)
	var scale_f := 64.0 / maxf(1.0, cell_w)
	sprite.scale = Vector2(scale_f, scale_f)
	sprite.frame_coords = Vector2i(int(anim_t) % cols, row)

func _draw() -> void:
	draw_circle(Vector2(0, 3), 11.0, Color(0, 0, 0, 0.25))
