extends Node2D
class_name CharacterActor
## Reusable 2.5D HD-2D Character Actor:
## - For all 16 Town NPCs: Renders their authentic 284-file Sprite Sheets (walk_9x4, idle_6x4, interact_8x4).
## - For the Player: True Modular Procedural Character Creator Renderer (8 Races with Anatomy,
##   3 Body Builds, 8 Skin Tones, 8 Hairstyles x 10 Colors, 4 Eye Styles x 8 Colors, 6 Outfit Styles,
##   8 Layered Accessories, Outfit Auras & Starlight Mount [V])!

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
var name_label: Label
var badge_label: Label
var emote_label: Label

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.centered = true
	sprite.position = Vector2(0, -22)
	sprite.visible = not is_player
	add_child(sprite)

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
		if sprite:
			sprite.visible = false
	else:
		if sprite:
			sprite.visible = true
		if name_label:
			name_label.text = display_name
		_apply_frame()
	queue_redraw()

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
	if not is_player:
		if sprite:
			sprite.position.y = -22.0 + hop_y
		if badge_label:
			var bday := GameData.is_npc_birthday(char_id, GameState.get_season_index(), GameState.get_day_of_season())
			badge_label.text = ("🎂" + badge_text) if bday else badge_text
			badge_label.position.y = -84.0 + sin(Time.get_ticks_msec() / 240.0 + position.x) * 2.5
		_apply_frame()
	queue_redraw()

func _apply_frame() -> void:
	if not sprite or is_player:
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
		row = 2
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
	if not is_player:
		return
	var now_s := Time.get_ticks_msec() / 1000.0
	var mounted := GameState.mount_active and GameState.current_scene == "outdoor"
	if mounted:
		var face := -1.0 if dir_row == 1 else 1.0
		var gallop := sin(now_s * 14.0) * 3.0 if anim_mode == "walk" else 0.0
		draw_circle(Vector2(0, -4), 22.0 + sin(now_s * 5.0) * 2.0, Color(1.0, 0.92, 0.42, 0.22))
		draw_rect(Rect2(-15, -15, 30, 13), Color("#fef3c7"))
		draw_rect(Rect2(-15, -15, 30, 13), Color("#f59e0b"), false, 1.8)
		draw_circle(Vector2(face * 15.0, -19.0), 6.5, Color("#fffbeb"))
		draw_line(Vector2(face * 17.0, -24.0), Vector2(face * 23.0, -31.0), Color("#fde047"), 2.5)
		draw_line(Vector2(-10, -2), Vector2(-10 + gallop, 6), Color("#d97706"), 3.0)
		draw_line(Vector2(10, -2), Vector2(10 - gallop, 6), Color("#d97706"), 3.0)
		draw_line(Vector2(-face * 15.0, -11.0), Vector2(-face * 22.0, -6.0 + gallop * 0.5), Color("#facc15"), 3.0)
	if GameState.night_lantern_on:
		draw_circle(Vector2(0, -14), 56.0 + sin(now_s * 4.5) * 4.0, Color(1.0, 0.85, 0.35, 0.16))
		draw_circle(Vector2(10, -16), 5.0, Color(1.0, 0.94, 0.55, 0.9))

	var hop_y := -absf(sin((_hop_t / 0.36) * PI)) * 12.0 if _hop_t > 0.0 else 0.0
	var mount_y := (-8.0 + sin(anim_t * 2.4) * 2.0) if mounted else 0.0
	draw_custom_character(self, GameState.hero_custom, dir_row, anim_mode, anim_t, hop_y + mount_y, GameState.equipped_accessory, GameState.equipped_outfit)

static func draw_custom_character(canvas: CanvasItem, hc: Dictionary, d_row: int, mode: String, at: float, off_y: float, acc_id: String, outfit_id: String) -> void:
	var now_s := Time.get_ticks_msec() / 1000.0
	var rk := str(hc.get("race_key", "human"))
	var build := str(hc.get("build", "normal"))
	var skin := Color(str(hc.get("skin_hex", "#fde2cf")))
	var hair := Color(str(hc.get("hair_hex", "#6b3e26")))
	var hair_hi := hair.lightened(0.22)
	var hair_style := str(hc.get("hair_style", "short_spiky"))
	var eye_col := Color(str(hc.get("eye_hex", "#0284c7")))
	var eye_style := str(hc.get("eye_style", "round"))
	var outfit_style := str(hc.get("outfit_style", "adventurer"))
	var shirt := Color(str(hc.get("shirt_hex", "#15803d")))
	var pants := Color(str(hc.get("pants_hex", "#5c3312")))
	var outline := Color("#1e1b4b")

	var bw := 0.86 if build == "slim" else (1.16 if build == "sturdy" else 1.0)
	if rk == "dwarf":
		bw *= 1.12
	var stride := sin(at * 1.4) * 4.0 if mode == "walk" else 0.0
	var bob := absf(sin(at * 1.4)) * -2.2 if mode == "walk" else sin(at * 0.7) * 0.8
	var oy := off_y + bob
	var face_x := -1.0 if d_row == 1 else (1.0 if d_row == 3 else 0.0)

	# 1. Outfit Aura Ring
	var out_def: Dictionary = GameData.get_outfit_def(outfit_id)
	var aura_hex := str(out_def.get("aura", ""))
	if aura_hex != "":
		var ac := Color(aura_hex)
		ac.a = 0.25 + sin(now_s * 3.2) * 0.07
		canvas.draw_arc(Vector2(0, 1 + off_y), 15.0, 0.0, TAU, 24, ac, 2.2)

	# 2. Race Back Features (Avian Wings / Beastkin Tail) + Back Accessories
	if rk == "avian":
		var wf := sin(now_s * 6.5) * 3.5
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(-3, -24 + oy), Vector2(-21, -34 + oy - wf), Vector2(-18, -14 + oy)]), Color("#f8fafc"))
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(3, -24 + oy), Vector2(21, -34 + oy - wf), Vector2(18, -14 + oy)]), Color("#f8fafc"))
	elif rk == "beastkin":
		var sway := sin(now_s * 5.0 + stride * 0.4) * 4.0
		canvas.draw_line(Vector2(-face_x * 4.0, -11 + oy), Vector2(-face_x * 13.0 + sway, -18 + oy), hair, 4.5)
		canvas.draw_circle(Vector2(-face_x * 13.0 + sway, -18 + oy), 3.2, hair_hi)

	if acc_id == "acc_fairy_wings":
		var flap := sin(now_s * 9.0) * 4.0
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(-2, -24 + oy), Vector2(-20 - flap, -36 + oy), Vector2(-16 - flap * 0.5, -14 + oy)]), Color(0.55, 0.92, 1.0, 0.72))
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(2, -24 + oy), Vector2(20 + flap, -36 + oy), Vector2(16 + flap * 0.5, -14 + oy)]), Color(0.55, 0.92, 1.0, 0.72))
	elif acc_id == "acc_crimson_cape":
		var sway2 := sin(now_s * 4.5) * 3.0
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(-8 * bw, -28 + oy), Vector2(8 * bw, -28 + oy), Vector2(13 + sway2, -6 + oy), Vector2(-13 + sway2, -6 + oy)]), Color("#991b1b"))
		canvas.draw_line(Vector2(-8 * bw, -28 + oy), Vector2(8 * bw, -28 + oy), Color("#fde047"), 2.0)

	# 3. Back Long Hair Layer
	if hair_style in ["long_flow", "wild_mane", "braid"]:
		canvas.draw_rect(Rect2(-10, -40 + oy, 20, 24), hair)
	elif hair_style == "ponytail":
		canvas.draw_circle(Vector2(-face_x * 9.0, -34 + oy), 5.5, hair)
		canvas.draw_rect(Rect2(-face_x * 10.0 - 3, -34 + oy, 6, 14), hair)
	elif hair_style == "twin_tails":
		canvas.draw_rect(Rect2(-14, -37 + oy, 5, 17), hair)
		canvas.draw_rect(Rect2(9, -37 + oy, 5, 17), hair)

	# 4. Legs & Boots
	var lx1 := -4.5 * bw + (stride * 0.5 if d_row in [1, 3] else 0.0)
	var lx2 := 4.5 * bw - (stride * 0.5 if d_row in [1, 3] else 0.0)
	var ly1 := -10.0 + oy + (stride * 0.4 if d_row in [0, 2] else 0.0)
	var ly2 := -10.0 + oy - (stride * 0.4 if d_row in [0, 2] else 0.0)
	canvas.draw_rect(Rect2(lx1 - 2.6, ly1, 5.2, 9.0), pants)
	canvas.draw_rect(Rect2(lx2 - 2.6, ly2, 5.2, 9.0), pants)
	canvas.draw_rect(Rect2(lx1 - 3.0, ly1 + 6.5, 6.0, 3.8), Color("#3b1e0a"))
	canvas.draw_rect(Rect2(lx2 - 3.0, ly2 + 6.5, 6.0, 3.8), Color("#3b1e0a"))

	# 5. Torso & Custom Outfit Style
	var tw := 15.0 * bw
	var th := 16.0
	var torso_r := Rect2(-tw * 0.5, -26.0 + oy, tw, th)
	canvas.draw_rect(torso_r, shirt)
	canvas.draw_rect(torso_r, outline, false, 1.2)
	match outfit_style:
		"adventurer":
			canvas.draw_rect(Rect2(-tw * 0.5, -14.0 + oy, tw, 3.0), Color("#78350f"))
			canvas.draw_rect(Rect2(-2.0, -14.5 + oy, 4.0, 4.0), Color("#facc15"))
			canvas.draw_line(Vector2(-tw * 0.45, -25.0 + oy), Vector2(tw * 0.45, -13.0 + oy), Color("#92400e"), 2.0)
		"knight":
			canvas.draw_rect(Rect2(-tw * 0.45, -25.0 + oy, tw * 0.9, 10.0), Color("#cbd5e1"))
			canvas.draw_rect(Rect2(-tw * 0.55, -26.5 + oy, 5.0, 5.0), Color("#94a3b8"))
			canvas.draw_rect(Rect2(tw * 0.55 - 5.0, -26.5 + oy, 5.0, 5.0), Color("#94a3b8"))
		"mage":
			canvas.draw_rect(Rect2(-tw * 0.55, -13.0 + oy, tw * 1.1, 7.0), shirt.darkened(0.15))
			canvas.draw_line(Vector2(0, -25.0 + oy), Vector2(0, -7.0 + oy), Color("#fde047"), 2.2)
		"bard":
			canvas.draw_line(Vector2(-tw * 0.5, -24.0 + oy), Vector2(tw * 0.5, -24.0 + oy), Color("#f43f5e"), 3.2)
			canvas.draw_line(Vector2(3.0, -23.0 + oy), Vector2(6.0, -14.0 + oy), Color("#f43f5e"), 2.5)
		"royal":
			canvas.draw_rect(Rect2(-tw * 0.5, -25.0 + oy, tw, 3.0), Color("#fde047"))
			canvas.draw_circle(Vector2(0, -20.0 + oy), 2.8, Color("#ef4444"))
		_:
			canvas.draw_rect(Rect2(-tw * 0.25, -26.0 + oy, tw * 0.5, 4.0), Color("#fef3c7"))
	if rk == "vampire":
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(-9 * bw, -26 + oy), Vector2(-12 * bw, -33 + oy), Vector2(-4 * bw, -27 + oy)]), Color("#1e1b4b"))
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(9 * bw, -26 + oy), Vector2(12 * bw, -33 + oy), Vector2(4 * bw, -27 + oy)]), Color("#1e1b4b"))

	# 6. Arms & Hands
	var arm_swing := -stride * 0.55 if mode == "walk" else (sin(at * 2.5) * 5.0 if mode == "interact" else 0.0)
	canvas.draw_rect(Rect2(-tw * 0.5 - 3.6, -24.5 + oy + arm_swing, 3.8, 10.5), shirt.darkened(0.1))
	canvas.draw_rect(Rect2(tw * 0.5 - 0.2, -24.5 + oy - arm_swing, 3.8, 10.5), shirt.darkened(0.1))
	canvas.draw_circle(Vector2(-tw * 0.5 - 1.8, -13.5 + oy + arm_swing), 2.3, skin)
	canvas.draw_circle(Vector2(tw * 0.5 + 1.8, -13.5 + oy - arm_swing), 2.3, skin)

	# 7. Head + Race Ears / Beard
	var head_c := Vector2(0, -35.5 + oy)
	if rk == "elf":
		canvas.draw_colored_polygon(PackedVector2Array([head_c + Vector2(-9, -1), head_c + Vector2(-16, -4), head_c + Vector2(-9, 3)]), skin)
		canvas.draw_colored_polygon(PackedVector2Array([head_c + Vector2(9, -1), head_c + Vector2(16, -4), head_c + Vector2(9, 3)]), skin)
	elif rk == "goblin":
		canvas.draw_colored_polygon(PackedVector2Array([head_c + Vector2(-9, 0), head_c + Vector2(-17, 2), head_c + Vector2(-9, 4)]), skin)
		canvas.draw_colored_polygon(PackedVector2Array([head_c + Vector2(9, 0), head_c + Vector2(17, 2), head_c + Vector2(9, 4)]), skin)
	elif rk == "merfolk":
		canvas.draw_colored_polygon(PackedVector2Array([head_c + Vector2(-9, -2), head_c + Vector2(-15, -5), head_c + Vector2(-14, 3), head_c + Vector2(-9, 3)]), Color("#38bdf8"))
		canvas.draw_colored_polygon(PackedVector2Array([head_c + Vector2(9, -2), head_c + Vector2(15, -5), head_c + Vector2(14, 3), head_c + Vector2(9, 3)]), Color("#38bdf8"))

	canvas.draw_circle(head_c, 10.2, skin)
	canvas.draw_arc(head_c, 10.2, 0.0, TAU, 20, outline, 1.1)

	if rk == "beastkin":
		canvas.draw_colored_polygon(PackedVector2Array([head_c + Vector2(-8, -7), head_c + Vector2(-11, -16), head_c + Vector2(-2, -10)]), hair)
		canvas.draw_colored_polygon(PackedVector2Array([head_c + Vector2(8, -7), head_c + Vector2(11, -16), head_c + Vector2(2, -10)]), hair)
		canvas.draw_colored_polygon(PackedVector2Array([head_c + Vector2(-7, -8), head_c + Vector2(-9, -13), head_c + Vector2(-4, -10)]), Color("#fda4af"))
		canvas.draw_colored_polygon(PackedVector2Array([head_c + Vector2(7, -8), head_c + Vector2(9, -13), head_c + Vector2(4, -10)]), Color("#fda4af"))

	# 8. Facial Features (Front/Left/Right)
	if d_row != 0:
		var ex_off := face_x * 2.8
		var e_l := head_c + Vector2(-3.8 + ex_off, 0.2)
		var e_r := head_c + Vector2(3.8 + ex_off, 0.2)
		match eye_style:
			"round":
				canvas.draw_circle(e_l, 2.3, eye_col); canvas.draw_circle(e_r, 2.3, eye_col)
				canvas.draw_circle(e_l + Vector2(-0.6, -0.7), 0.8, Color.WHITE)
				canvas.draw_circle(e_r + Vector2(-0.6, -0.7), 0.8, Color.WHITE)
			"sharp":
				canvas.draw_rect(Rect2(e_l.x - 2.3, e_l.y - 1.3, 4.6, 2.6), eye_col)
				canvas.draw_rect(Rect2(e_r.x - 2.3, e_r.y - 1.3, 4.6, 2.6), eye_col)
				canvas.draw_line(e_l + Vector2(-2.6, -1.8), e_l + Vector2(2.4, -0.8), outline, 1.3)
				canvas.draw_line(e_r + Vector2(-2.4, -0.8), e_r + Vector2(2.6, -1.8), outline, 1.3)
			"gentle":
				canvas.draw_circle(e_l, 2.0, eye_col); canvas.draw_circle(e_r, 2.0, eye_col)
				canvas.draw_arc(e_l, 2.5, PI, TAU, 8, outline, 1.1)
				canvas.draw_arc(e_r, 2.5, PI, TAU, 8, outline, 1.1)
			"mystic":
				canvas.draw_circle(e_l, 2.4, eye_col); canvas.draw_circle(e_r, 2.4, eye_col)
				canvas.draw_circle(e_l, 1.0, Color("#fef08a"))
				canvas.draw_circle(e_r, 1.0, Color("#fef08a"))
		# Blush & Smile
		canvas.draw_circle(head_c + Vector2(-6.0 + ex_off, 3.0), 1.6, Color(0.98, 0.55, 0.62, 0.45))
		canvas.draw_circle(head_c + Vector2(6.0 + ex_off, 3.0), 1.6, Color(0.98, 0.55, 0.62, 0.45))
		canvas.draw_line(head_c + Vector2(-2.0 + ex_off, 5.2), head_c + Vector2(2.0 + ex_off, 5.2), Color("#9a3412"), 1.2)
		if rk == "dwarf":
			canvas.draw_colored_polygon(PackedVector2Array([head_c + Vector2(-7, 4), head_c + Vector2(7, 4), head_c + Vector2(5, 13), head_c + Vector2(0, 15), head_c + Vector2(-5, 13)]), hair)

	# 9. Front Hair Styles (8 distinct silhouettes)
	var htop := head_c + Vector2(0, -5.0)
	canvas.draw_arc(head_c, 10.6, PI, TAU, 16, hair, 5.5)
	match hair_style:
		"short_spiky":
			for sx in [-6, -2, 2, 6]:
				canvas.draw_colored_polygon(PackedVector2Array([htop + Vector2(sx - 3, 1), htop + Vector2(sx, -8), htop + Vector2(sx + 3, 1)]), hair)
		"long_flow":
			canvas.draw_rect(Rect2(head_c.x - 11.2, head_c.y - 6.0, 3.8, 16.0), hair)
			canvas.draw_rect(Rect2(head_c.x + 7.4, head_c.y - 6.0, 3.8, 16.0), hair)
			canvas.draw_rect(Rect2(head_c.x - 8.0, head_c.y - 9.5, 16.0, 5.0), hair)
		"bob_cut":
			canvas.draw_rect(Rect2(head_c.x - 11.5, head_c.y - 5.0, 4.2, 12.0), hair)
			canvas.draw_rect(Rect2(head_c.x + 7.3, head_c.y - 5.0, 4.2, 12.0), hair)
			canvas.draw_rect(Rect2(head_c.x - 8.5, head_c.y - 9.5, 17.0, 5.2), hair)
		"braid":
			canvas.draw_rect(Rect2(head_c.x - 9.0, head_c.y - 9.5, 18.0, 5.0), hair)
			for bi in range(4):
				canvas.draw_circle(head_c + Vector2(8.5, 2.0 + bi * 4.2), 2.8, hair)
		"wild_mane":
			for sx in [-8, -4, 0, 4, 8]:
				canvas.draw_colored_polygon(PackedVector2Array([htop + Vector2(sx - 3, 2), htop + Vector2(sx * 1.2, -9), htop + Vector2(sx + 3, 2)]), hair)
		"noble_part":
			canvas.draw_colored_polygon(PackedVector2Array([head_c + Vector2(-10, -4), head_c + Vector2(-4, -11), head_c + Vector2(10, -5), head_c + Vector2(6, -1)]), hair)
		_:
			canvas.draw_rect(Rect2(head_c.x - 8.5, head_c.y - 9.5, 17.0, 5.0), hair)
	canvas.draw_line(head_c + Vector2(-5, -8.5), head_c + Vector2(3, -8.5), hair_hi, 1.8)

	# 10. Layered Head Accessories
	var hy := -46.5 + oy
	match acc_id:
		"acc_straw_hat":
			canvas.draw_rect(Rect2(-13, hy + 2, 26, 4), Color("#eab308"))
			canvas.draw_rect(Rect2(-8, hy - 5, 16, 7), Color("#facc15"))
			canvas.draw_rect(Rect2(-8, hy, 16, 2), Color("#dc2626"))
		"acc_flower_crown":
			canvas.draw_line(Vector2(-9, hy + 2), Vector2(9, hy + 2), Color("#16a34a"), 3.0)
			canvas.draw_circle(Vector2(-6, hy + 1), 3.0, Color("#f472b6"))
			canvas.draw_circle(Vector2(0, hy), 3.2, Color("#fde047"))
			canvas.draw_circle(Vector2(6, hy + 1), 3.0, Color("#38bdf8"))
		"acc_witch_hat":
			canvas.draw_rect(Rect2(-13, hy + 2, 26, 3), Color("#1e1b4b"))
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-8, hy + 2), Vector2(8, hy + 2), Vector2(2, hy - 13)]), Color("#312e81"))
			canvas.draw_circle(Vector2(0, hy - 1), 2.3, Color("#fde047"))
		"acc_wedding_veil":
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-9, hy + 1), Vector2(9, hy + 1), Vector2(13, hy + 18), Vector2(-13, hy + 18)]), Color(1.0, 1.0, 1.0, 0.55))
			canvas.draw_line(Vector2(-8, hy + 1), Vector2(8, hy + 1), Color("#fef08a"), 2.5)
			canvas.draw_circle(Vector2(0, hy), 2.8, Color("#f472b6"))
		"acc_royal_crown":
			canvas.draw_colored_polygon(PackedVector2Array([
				Vector2(-9, hy + 3), Vector2(-9, hy - 5), Vector2(-4, hy - 1),
				Vector2(0, hy - 7), Vector2(4, hy - 1), Vector2(9, hy - 5), Vector2(9, hy + 3)
			]), Color("#facc15"))
			canvas.draw_circle(Vector2(0, hy - 1), 2.2, Color("#ef4444"))
