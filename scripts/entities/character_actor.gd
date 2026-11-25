extends Node2D
class_name CharacterActor
## Reusable 2.5D HD-2D Character Sprite Actor for Player & all 16 Town NPCs.
## Supports walk_9x4, idle_6x4, interact_8x4, HD/Classic sheets, GPU Protagonist Recolor Shader,
## Visible Layered Accessories (Hats/Crowns/Veil/Wings/Cape), Outfit Aura, and Cutscene Emotes/Hops!

var char_id: String = "01_ren"
var display_name: String = ""
var is_player: bool = false
var dir_row: int = 2 # 0=up, 1=left, 2=down, 3=right
var anim_mode: String = "idle" # walk, idle, interact
var anim_t: float = 0.0
var interact_timer: float = 0.0
var badge_text: String = ""
var emote_text: String = ""
var emote_timer: float = 0.0
var _hop_t: float = 0.0

var sprite: Sprite2D
var overlay_drawer: Node2D
var name_label: Label
var badge_label: Label
var emote_label: Label
var _shader_mat: ShaderMaterial

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.centered = true
	sprite.position = Vector2(0, -22)
	add_child(sprite)

	overlay_drawer = Node2D.new()
	overlay_drawer.draw.connect(_draw_head_accessory)
	add_child(overlay_drawer)

	if is_player:
		var sh := load("res://shaders/protagonist_recolor.gdshader") as Shader
		if sh:
			_shader_mat = ShaderMaterial.new()
			_shader_mat.shader = sh
			sprite.material = _shader_mat

	if not is_player:
		name_label = Label.new()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.position = Vector2(-56, -68)
		name_label.size = Vector2(112, 18)
		name_label.add_theme_font_size_override("font_size", 11)
		name_label.add_theme_color_override("font_color", Color("#fef3c7"))
		name_label.add_theme_color_override("font_outline_color", Color("#0f172a"))
		name_label.add_theme_constant_override("outline_size", 4)
		add_child(name_label)

		badge_label = Label.new()
		badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_label.position = Vector2(-30, -84)
		badge_label.size = Vector2(60, 18)
		badge_label.add_theme_font_size_override("font_size", 13)
		add_child(badge_label)

	emote_label = Label.new()
	emote_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emote_label.position = Vector2(-32, -96)
	emote_label.size = Vector2(64, 24)
	emote_label.add_theme_font_size_override("font_size", 18)
	emote_label.visible = false
	add_child(emote_label)

	refresh_appearance()

func show_emote(em: String, duration: float = 2.4) -> void:
	emote_text = em
	emote_timer = duration
	if emote_label:
		emote_label.text = em
		emote_label.visible = (em != "")

func play_hop() -> void:
	_hop_t = 0.36

func refresh_appearance() -> void:
	if is_player:
		var hc: Dictionary = GameState.hero_custom
		char_id = str(hc.get("base_id", "01_ren"))
		var out_def: Dictionary = GameData.get_outfit_def(GameState.equipped_outfit)
		var hue_off := float(out_def.get("hue", 0.0)) if GameState.equipped_outfit != "outfit_traveler" else 0.0
		var sat_mul := (float(hc.get("sat", 100.0)) / 100.0) * (float(out_def.get("sat", 100.0)) / 100.0)
		var val_mul := (float(hc.get("val", 100.0)) / 100.0) * (float(out_def.get("val", 100.0)) / 100.0)
		if _shader_mat:
			_shader_mat.set_shader_parameter("hue_shift_deg", float(hc.get("hue", 0.0)) + hue_off)
			_shader_mat.set_shader_parameter("sat_mult", sat_mul)
			_shader_mat.set_shader_parameter("val_mult", val_mul)
			_shader_mat.set_shader_parameter("skin_mode", int(GameState.SKIN_MODES.get(str(hc.get("skin", "none")), 0)))
	elif name_label:
		name_label.text = display_name
	_apply_frame()
	queue_redraw()
	if overlay_drawer:
		overlay_drawer.queue_redraw()

func update_actor(delta: float, moving: bool, sprinting: bool = false) -> void:
	if _hop_t > 0.0:
		_hop_t = maxf(0.0, _hop_t - delta)
	if emote_timer > 0.0:
		emote_timer = maxf(0.0, emote_timer - delta)
		if emote_label:
			emote_label.visible = true
			emote_label.position.y = -96.0 - sin((2.4 - emote_timer) * 6.0) * 4.0
		if emote_timer <= 0.0 and emote_label:
			emote_label.visible = false

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

	var hop_y := -absf(sin((_hop_t / 0.36) * PI)) * 12.0 if _hop_t > 0.0 else 0.0
	if sprite:
		sprite.position.y = -22.0 + hop_y
	if overlay_drawer:
		overlay_drawer.position.y = hop_y
		overlay_drawer.queue_redraw()

	if badge_label:
		var bday := GameData.is_npc_birthday(char_id, GameState.get_season_index(), GameState.get_day_of_season())
		badge_label.text = ("🎂" + badge_text) if bday else badge_text
		badge_label.position.y = -84.0 + sin(Time.get_ticks_msec() / 240.0 + position.x) * 2.5
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
	draw_circle(Vector2(0, 3), 11.0, Color(0, 0, 0, 0.26))
	if is_player:
		var now_s := Time.get_ticks_msec() / 1000.0
		if GameState.night_lantern_on:
			draw_circle(Vector2(0, -14), 56.0 + sin(now_s * 4.5) * 4.0, Color(1.0, 0.85, 0.35, 0.16))
			draw_circle(Vector2(10, -16), 5.0, Color(1.0, 0.94, 0.55, 0.9))
		var out_def: Dictionary = GameData.get_outfit_def(GameState.equipped_outfit)
		var aura_hex := str(out_def.get("aura", ""))
		if aura_hex != "":
			var ac := Color(aura_hex)
			ac.a = 0.22 + sin(now_s * 3.2) * 0.06
			draw_arc(Vector2(0, 2), 14.0, 0.0, TAU, 24, ac, 2.2)
		var acc := GameState.equipped_accessory
		if acc == "acc_fairy_wings":
			var flap := sin(now_s * 9.0) * 4.0
			draw_colored_polygon(PackedVector2Array([Vector2(-2, -24), Vector2(-20 - flap, -36), Vector2(-16 - flap * 0.5, -14)]), Color(0.55, 0.92, 1.0, 0.72))
			draw_colored_polygon(PackedVector2Array([Vector2(2, -24), Vector2(20 + flap, -36), Vector2(16 + flap * 0.5, -14)]), Color(0.55, 0.92, 1.0, 0.72))
			draw_colored_polygon(PackedVector2Array([Vector2(-2, -22), Vector2(-14, -30), Vector2(-11, -17)]), Color(1.0, 0.95, 0.55, 0.55))
			draw_colored_polygon(PackedVector2Array([Vector2(2, -22), Vector2(14, -30), Vector2(11, -17)]), Color(1.0, 0.95, 0.55, 0.55))
		elif acc == "acc_crimson_cape":
			var sway := sin(now_s * 4.5) * 3.0
			draw_colored_polygon(PackedVector2Array([Vector2(-7, -28), Vector2(7, -28), Vector2(12 + sway, -6), Vector2(-12 + sway, -6)]), Color("#991b1b"))
			draw_line(Vector2(-7, -28), Vector2(7, -28), Color("#fde047"), 2.0)

func _draw_head_accessory() -> void:
	if not is_player:
		return
	var acc := GameState.equipped_accessory
	if acc in ["", "acc_none", "acc_fairy_wings", "acc_crimson_cape"]:
		return
	var bob := sin(anim_t * 2.0) * 1.2 if anim_mode == "walk" else 0.0
	var hy := -46.0 + bob
	match acc:
		"acc_straw_hat":
			overlay_drawer.draw_rect(Rect2(-13, hy + 2, 26, 4), Color("#eab308"))
			overlay_drawer.draw_rect(Rect2(-8, hy - 5, 16, 7), Color("#facc15"))
			overlay_drawer.draw_rect(Rect2(-8, hy, 16, 2), Color("#dc2626"))
		"acc_flower_crown":
			overlay_drawer.draw_line(Vector2(-9, hy + 2), Vector2(9, hy + 2), Color("#16a34a"), 3.0)
			overlay_drawer.draw_circle(Vector2(-6, hy + 1), 3.0, Color("#f472b6"))
			overlay_drawer.draw_circle(Vector2(0, hy), 3.2, Color("#fde047"))
			overlay_drawer.draw_circle(Vector2(6, hy + 1), 3.0, Color("#38bdf8"))
		"acc_witch_hat":
			overlay_drawer.draw_rect(Rect2(-13, hy + 2, 26, 3), Color("#1e1b4b"))
			overlay_drawer.draw_colored_polygon(PackedVector2Array([Vector2(-8, hy + 2), Vector2(8, hy + 2), Vector2(2, hy - 13)]), Color("#312e81"))
			overlay_drawer.draw_circle(Vector2(0, hy - 1), 2.3, Color("#fde047"))
		"acc_wedding_veil":
			overlay_drawer.draw_colored_polygon(PackedVector2Array([Vector2(-9, hy + 1), Vector2(9, hy + 1), Vector2(13, hy + 18), Vector2(-13, hy + 18)]), Color(1.0, 1.0, 1.0, 0.55))
			overlay_drawer.draw_line(Vector2(-8, hy + 1), Vector2(8, hy + 1), Color("#fef08a"), 2.5)
			overlay_drawer.draw_circle(Vector2(0, hy), 2.8, Color("#f472b6"))
		"acc_royal_crown":
			overlay_drawer.draw_colored_polygon(PackedVector2Array([
				Vector2(-9, hy + 3), Vector2(-9, hy - 5), Vector2(-4, hy - 1),
				Vector2(0, hy - 7), Vector2(4, hy - 1), Vector2(9, hy - 5), Vector2(9, hy + 3)
			]), Color("#facc15"))
			overlay_drawer.draw_circle(Vector2(0, hy - 1), 2.2, Color("#ef4444"))
