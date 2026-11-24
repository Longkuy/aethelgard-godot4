extends PanelContainer
class_name WorldMapModal
## Full-Screen Interactive Stardew-Style Valley Map ([M]) with Click-to-Warp
## to all 6 Houses, 5 Landmarks, Under-Root Ancient Ruins, and Live NPC Tracking!

signal warp_requested(scene_id: String, tile: Vector2i, label: String)

var world_ref: ValleyWorld
var map_canvas: Control
var info_lbl: Label
var pins: Array[Dictionary] = []

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(880, 560)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	add_child(vb)

	var top := HBoxContainer.new()
	vb.add_child(top)
	var title := Label.new()
	title.text = "แผนที่หุบเขาต้นไม้โลก (คลิกสถานที่เพื่อเดินทางวาร์ปทันที!)"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 17)
	top.add_child(title)

	var close_b := Button.new()
	close_b.text = "ปิด [M / Esc]"
	close_b.pressed.connect(func(): visible = false)
	top.add_child(close_b)

	map_canvas = Control.new()
	map_canvas.custom_minimum_size = Vector2(840, 470)
	map_canvas.draw.connect(_draw_map)
	map_canvas.gui_input.connect(_on_map_input)
	vb.add_child(map_canvas)

	info_lbl = Label.new()
	info_lbl.text = "คลิกอาคาร แลนด์มาร์ก หรือประตูโบราณสถานรากไม้โลกเพื่อวาร์ปทันที • คลิกจุดสีเหลืองเพื่อนำทางหาชาวเมือง"
	info_lbl.add_theme_font_size_override("font_size", 13)
	vb.add_child(info_lbl)

func open_map(world: ValleyWorld) -> void:
	world_ref = world
	_rebuild_pins()
	visible = true
	AudioManager.play_sfx("talk")
	map_canvas.queue_redraw()

func _tile_to_px(tx: float, ty: float) -> Vector2:
	var sz := map_canvas.size if map_canvas.size.x > 10 else Vector2(840, 470)
	return Vector2((tx / 84.0) * sz.x, (ty / 64.0) * sz.y)

func _rebuild_pins() -> void:
	pins.clear()
	for b in ValleyWorld.BUILDINGS:
		var dr: Vector2i = b["door"]
		pins.append({
			"kind": "warp", "scene": "outdoor", "tile": Vector2i(dr.x, dr.y + 1),
			"pos": _tile_to_px(float(b["x"]) + float(b["w"]) * 0.5, float(b["y"]) + float(b["h"]) * 0.5),
			"label": str(b["name_th"]), "color": Color("#b45309")
		})
	pins.append({
		"kind": "warp", "scene": "ruins_b1", "tile": Vector2i(10, 11),
		"pos": _tile_to_px(39.0, 27.0), "label": "โบราณสถานใต้รากไม้โลก (B1-B3)", "color": Color("#38bdf8")
	})
	pins.append({
		"kind": "warp", "scene": "outdoor", "tile": Vector2i(42, 46),
		"pos": _tile_to_px(42.0, 52.0), "label": "ทะเลสาบมุกศักดิ์สิทธิ์ (ตกปลา)", "color": Color("#0284c7")
	})
	for lm in GameData.landmarks:
		pins.append({
			"kind": "warp", "scene": "outdoor", "tile": Vector2i(int(lm["interactX"]), int(lm["interactY"])),
			"pos": _tile_to_px(float(lm["tx"]) + 2.5, float(lm["ty"]) + 2.0),
			"label": str(lm["name_th"]), "color": Color("#0f766e") if GameState.landmarks_built.has(lm["id"]) else Color("#78716c")
		})
	if world_ref:
		for cid in world_ref.npc_states.keys():
			var st: Dictionary = world_ref.npc_states[cid]
			var actor: CharacterActor = world_ref.npc_actors[cid]
			var tpos := actor.position / 32.0 if str(st["scene"]) == "outdoor" else Vector2(42, 31)
			pins.append({
				"kind": "npc", "cid": cid,
				"pos": _tile_to_px(tpos.x, tpos.y),
				"label": str(GameData.char_by_id.get(cid, {}).get("name_th", cid)), "color": Color("#facc15")
			})

func _on_map_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_rebuild_pins()
		for p in pins:
			if p["pos"].distance_to(event.position) < 20.0:
				info_lbl.text = "เป้าหมาย: %s (คลิกซ้ายเพื่อเดินทาง/นำทาง)" % p["label"]
				return
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_rebuild_pins()
		for p in pins:
			if p["pos"].distance_to(event.position) < 22.0:
				visible = false
				if p["kind"] == "npc":
					GameState.compass_npc_id = str(p["cid"])
					GameState.toast_requested.emit("ตั้งเข็มทิศนำทางไปยัง %s!" % p["label"])
				else:
					warp_requested.emit(str(p["scene"]), p["tile"], str(p["label"]))
				return

func _draw_map() -> void:
	if not world_ref: return
	var sz := map_canvas.size
	var cw := sz.x / 84.0
	var ch := sz.y / 64.0
	for y in range(64):
		for x in range(84):
			var t := world_ref.map_grid[y * 84 + x]
			var col := Color("#65a34e")
			if t == 8: col = Color("#2d5a27")
			elif t == 1: col = Color("#e2cfa8")
			elif t == 2: col = Color("#c99a5b")
			elif t == 3: col = Color("#2563eb")
			elif t == 4: col = Color("#9a5520")
			map_canvas.draw_rect(Rect2(x * cw, y * ch, ceilf(cw), ceilf(ch)), col)
	_rebuild_pins()
	var font := GameData.font_bold
	for p in pins:
		var r := 7.0 if p["kind"] == "npc" else 12.0
		map_canvas.draw_circle(p["pos"], r, p["color"])
		map_canvas.draw_arc(p["pos"], r, 0.0, TAU, 16, Color("#2b1608"), 2.0)
		if p["kind"] != "npc" and font:
			map_canvas.draw_string(font, p["pos"] + Vector2(-36, -15), str(p["label"]).left(14), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#fffbeb"))
	var p_tile := world_ref.player_actor.position / 32.0 if GameState.current_scene == "outdoor" else GameState.return_outdoor_pos / 32.0
	var pp := _tile_to_px(p_tile.x, p_tile.y)
	map_canvas.draw_circle(pp, 9.0, Color("#ef4444"))
	map_canvas.draw_arc(pp, 11.0, 0.0, TAU, 16, Color.WHITE, 2.5)
