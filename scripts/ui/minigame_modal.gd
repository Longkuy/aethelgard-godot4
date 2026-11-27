extends PanelContainer
class_name MiniGameModal
## Implements all 6 Specialized Interactive Minigames natively in Godot 4:
## 1. forge_heat (Smithy & Bakery Heat Gauge)
## 2. order_rush (Tavern & Shop Live Item Order Matching)
## 3. rune_memory (Herbalist & Archive Simon Rune Sequence)
## 4. sky_dash (Courier & Patrol Lane Catch/Dodge)
## 5. stardew_fish (Stardew Tension-Bar Fishing!)
## 6. rhythm_stage (4-Lane Musical Concert [D][F][J][K]!)

signal minigame_finished(context_mode: String, payload: Variant, score: int, max_score: int)

var active: bool = false
var kind: String = "forge_heat"
var context_mode: String = "job"
var payload: Variant = null
var score: int = 0
var max_score: int = 8
var hold_down: bool = false
var state_data: Dictionary = {}

var title_lbl: Label
var sub_lbl: Label
var status_lbl: Label
var arena: Control
var btn_row: HBoxContainer
var action_btn: Button

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(560, 410)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	add_child(vb)

	title_lbl = Label.new()
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 18)
	vb.add_child(title_lbl)

	sub_lbl = Label.new()
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub_lbl.add_theme_font_size_override("font_size", 13)
	vb.add_child(sub_lbl)

	status_lbl = Label.new()
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.add_theme_color_override("font_color", Color("#14532d"))
	vb.add_child(status_lbl)

	arena = Control.new()
	arena.custom_minimum_size = Vector2(480, 210)
	arena.draw.connect(_draw_arena)
	arena.gui_input.connect(_on_arena_input)
	vb.add_child(arena)

	btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 6)
	vb.add_child(btn_row)

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 10)
	vb.add_child(bottom)

	action_btn = Button.new()
	action_btn.text = "กดจังหวะ! [Space]"
	action_btn.button_down.connect(func():
		hold_down = true
		if kind == "forge_heat": _hit_forge()
	)
	action_btn.button_up.connect(func(): hold_down = false)
	bottom.add_child(action_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "ยกเลิก [Esc]"
	cancel_btn.pressed.connect(stop_minigame)
	bottom.add_child(cancel_btn)

static func get_job_minigame_kind(job_id: String) -> String:
	match job_id:
		"job_smithy", "job_bakery": return "forge_heat"
		"job_tavern", "job_shop": return "order_rush"
		"job_herbalist", "job_archives": return "rune_memory"
		"job_courier", "job_patrol": return "sky_dash"
	return "forge_heat"

func start_minigame(mg_kind: String, ctx_mode: String, data_payload: Variant = null) -> void:
	kind = mg_kind
	context_mode = ctx_mode
	payload = data_payload
	active = true
	hold_down = false
	visible = true
	for c in btn_row.get_children():
		c.queue_free()
	action_btn.visible = true

	match kind:
		"forge_heat":
			score = 0; max_score = 8
			state_data = {"round": 1, "total": 4, "pos": 0.1, "dir": 1.0, "speed": 1.25, "center": 0.52}
			title_lbl.text = "มินิเกมสายช่าง & เตาอบ: คุมเกจความร้อนสีทอง!"
			sub_lbl.text = "กด [Space] หรือปุ่มด้านล่างเมื่อเข็มอยู่ในโซนสีทอง (4 รอบ)"
			action_btn.text = "ตีค้อน / อบแป้ง! [Space]"
		"order_rush":
			var pool := ["item_honey_croissant", "item_honey_ale", "item_hearty_stew", "item_roasted_coffee", "item_emerald_tea", "item_apple_pie"]
			score = 0; max_score = 10
			state_data = {"pool": pool, "round": 1, "total": 5, "time_left": 22.0, "target": pool[randi() % pool.size()], "npc": GameData.characters[randi() % GameData.characters.size()]}
			title_lbl.text = "มินิเกมสายบริการ: เสิร์ฟด่วนออเดอร์ชาวเมือง!"
			sub_lbl.text = "คลิกไอเทมให้ตรงกับออเดอร์ที่ลูกค้าสั่งให้ทันเวลา!"
			action_btn.visible = false
			for i in pool.size():
				var iid: String = pool[i]
				var b := Button.new()
				b.text = str(GameData.item_by_id.get(iid, {}).get("name_th", iid)).left(10)
				b.pressed.connect(func(): _pick_order(iid))
				btn_row.add_child(b)
		"rune_memory":
			score = 0; max_score = 6
			var names := ["ใบไม้", "วารี", "เพลิง", "จันทรา", "สุริยัน", "สายลม"]
			var seq := [randi() % 6, randi() % 6, randi() % 6]
			state_data = {"names": names, "round": 1, "total": 3, "seq": seq, "idx": 0, "showing": true, "show_pos": -1, "timer": 0.55}
			title_lbl.text = "มินิเกมสายปัญญา: จดจำลำดับรูน & สมุนไพรเวท!"
			sub_lbl.text = "ดูลำดับรูนที่สว่างขึ้น แล้วคลิกทวนลำดับให้ถูกต้อง!"
			action_btn.visible = false
			for i in range(6):
				var b := Button.new()
				b.text = "%d.%s" % [i + 1, names[i]]
				b.pressed.connect(func(): _press_rune(i))
				btn_row.add_child(b)
		"sky_dash":
			score = 0; max_score = 100
			state_data = {"px": 240.0, "time_left": 14.0, "spawn_t": 0.35, "objs": []}
			title_lbl.text = "มินิเกมสายความกล้า: วิ่งส่งพัสดุ & หลบหิน!"
			sub_lbl.text = "กด [A/D] หรือลูกศรซ้าย-ขวา เก็บซองสีทอง (+20) และหลบก้อนหิน (-15)!"
			action_btn.visible = false
			var bl := Button.new(); bl.text = "< ซ้าย [A]"; bl.pressed.connect(func(): state_data["px"] = maxf(32.0, float(state_data["px"]) - 48.0)); btn_row.add_child(bl)
			var br := Button.new(); br.text = "ขวา [D] >"; br.pressed.connect(func(): state_data["px"] = minf(448.0, float(state_data["px"]) + 48.0)); btn_row.add_child(br)
		"stardew_fish":
			var mer := str(GameState.hero_custom.get("race_key", "human")) == "merfolk"
			score = 35; max_score = 100
			state_data = {"fish_y": 100.0, "fish_target": 55.0, "fish_t": 0.6, "bar_y": 110.0, "bar_vy": 0.0, "bar_h": 72.0 if mer else 54.0, "prog": 35.0, "elapsed": 0.0}
			title_lbl.text = "ตกปลาทะเลสาบมุก (Stardew Tension Bar!)"
			sub_lbl.text = "กดค้าง [Space] หรือปุ่มด้านล่างเพื่อยกแถบสีเขียวขึ้น เลี้ยงให้ตรงตัวปลาจนเต็ม 100%!"
			action_btn.text = "กดค้างเพื่อดึงเบ็ด! [Hold Space]"
		"rhythm_stage":
			score = 0; max_score = 24
			var notes: Array = []
			for i in range(12):
				notes.append({"lane": (i * 3 + (i % 2)) % 4, "y": -25.0 - i * 64.0, "done": false})
			state_data = {"notes": notes, "combo": 0}
			title_lbl.text = "มินิเกมสายดนตรี: คอนเสิร์ตประสานเสียง 4 เลน!"
			sub_lbl.text = "กดปุ่ม [D] [F] [J] [K] หรือคลิกแป้นด้านล่างเมื่อลูกแก้วดนตรีถึงเส้นสีทอง!"
			action_btn.visible = false
			var keys := ["D", "F", "J", "K"]
			for li in range(4):
				var b := Button.new()
				b.text = "เลน %s" % keys[li]
				b.pressed.connect(func(): _hit_rhythm_lane(li))
				btn_row.add_child(b)

func stop_minigame() -> void:
	active = false
	visible = false

func _finish_now() -> void:
	var sc := score
	var mx := max_score
	var cm := context_mode
	var pl = payload
	stop_minigame()
	minigame_finished.emit(cm, pl, sc, mx)

func _hit_forge() -> void:
	var dist := absf(float(state_data["pos"]) - float(state_data["center"]))
	AudioManager.play_sfx("anvil")
	if dist <= 0.06:
		score += 2; AudioManager.play_sfx("sparkle")
	elif dist <= 0.15:
		score += 1
	else:
		AudioManager.play_sfx("miss")
	if int(state_data["round"]) >= int(state_data["total"]):
		_finish_now()
	else:
		state_data["round"] = int(state_data["round"]) + 1
		state_data["speed"] = float(state_data["speed"]) + 0.28
		state_data["center"] = 0.25 + randf() * 0.5

func _pick_order(iid: String) -> void:
	if iid == str(state_data["target"]):
		score += 2; AudioManager.play_sfx("coin")
	else:
		AudioManager.play_sfx("miss")
	if int(state_data["round"]) >= int(state_data["total"]):
		_finish_now()
	else:
		var pool: Array = state_data["pool"]
		state_data["round"] = int(state_data["round"]) + 1
		state_data["target"] = pool[randi() % pool.size()]
		state_data["npc"] = GameData.characters[randi() % GameData.characters.size()]

func _press_rune(idx: int) -> void:
	if bool(state_data["showing"]): return
	var seq: Array = state_data["seq"]
	var pos := int(state_data["idx"])
	AudioManager.add_tone(392.0 + idx * 65.0, 0.14, 0.15)
	if int(seq[pos]) == idx:
		pos += 1
		state_data["idx"] = pos
		if pos >= seq.size():
			score += 2; AudioManager.play_sfx("sparkle")
			_next_rune_round()
	else:
		AudioManager.play_sfx("miss")
		_next_rune_round()

func _next_rune_round() -> void:
	if int(state_data["round"]) >= int(state_data["total"]):
		_finish_now()
		return
	var nr := int(state_data["round"]) + 1
	var nseq: Array = []
	for _i in range(2 + nr):
		nseq.append(randi() % 6)
	state_data["round"] = nr
	state_data["seq"] = nseq
	state_data["idx"] = 0
	state_data["showing"] = true
	state_data["show_pos"] = -1
	state_data["timer"] = 0.55

func _hit_rhythm_lane(lane_idx: int) -> void:
	var hit_y := 172.0
	var notes: Array = state_data["notes"]
	for n in notes:
		if not bool(n["done"]) and int(n["lane"]) == lane_idx and absf(float(n["y"]) - hit_y) <= 34.0:
			n["done"] = true
			AudioManager.add_tone(392.0 + lane_idx * 98.0, 0.16, 0.15, 0.0, true)
			score += 2 if absf(float(n["y"]) - hit_y) <= 15.0 else 1
			state_data["combo"] = int(state_data["combo"]) + 1
			return
	state_data["combo"] = 0
	AudioManager.play_sfx("miss")

func _on_arena_input(event: InputEvent) -> void:
	if not active: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		hold_down = event.pressed
		if event.pressed and kind == "forge_heat":
			_hit_forge()

func _unhandled_input(event: InputEvent) -> void:
	if not active: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			stop_minigame()
			get_viewport().set_input_as_handled()
		elif kind == "forge_heat" and event.physical_keycode in [KEY_SPACE, KEY_E, KEY_ENTER]:
			_hit_forge()
			get_viewport().set_input_as_handled()
		elif kind == "rhythm_stage":
			var idx := [KEY_D, KEY_F, KEY_J, KEY_K].find(event.physical_keycode)
			if idx >= 0:
				_hit_rhythm_lane(idx)
				get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not active: return
	var w := arena.size.x if arena.size.x > 10 else 480.0
	match kind:
		"forge_heat":
			var p := float(state_data["pos"]) + float(state_data["dir"]) * float(state_data["speed"]) * delta
			if p >= 0.95: p = 0.95; state_data["dir"] = -1.0
			elif p <= 0.05: p = 0.05; state_data["dir"] = 1.0
			state_data["pos"] = p
			status_lbl.text = "รอบที่ %d/%d • คะแนน: %d/%d" % [int(state_data["round"]), int(state_data["total"]), score, max_score]
		"order_rush":
			state_data["time_left"] = float(state_data["time_left"]) - delta
			status_lbl.text = "ออเดอร์ %d/%d • เวลา %.1fs • คะแนน: %d/%d" % [int(state_data["round"]), int(state_data["total"]), float(state_data["time_left"]), score, max_score]
			if float(state_data["time_left"]) <= 0.0:
				_finish_now(); return
		"rune_memory":
			status_lbl.text = "รอบที่ %d/%d • คะแนน: %d/%d" % [int(state_data["round"]), int(state_data["total"]), score, max_score]
			if bool(state_data["showing"]):
				state_data["timer"] = float(state_data["timer"]) - delta
				if float(state_data["timer"]) <= 0.0:
					var sp := int(state_data["show_pos"]) + 1
					var seq: Array = state_data["seq"]
					if sp >= seq.size():
						state_data["showing"] = false
						state_data["show_pos"] = -1
					else:
						state_data["show_pos"] = sp
						AudioManager.add_tone(392.0 + int(seq[sp]) * 65.0, 0.2, 0.14)
						state_data["timer"] = 0.58
		"sky_dash":
			state_data["time_left"] = float(state_data["time_left"]) - delta
			if Input.is_action_pressed("move_left"): state_data["px"] = maxf(28.0, float(state_data["px"]) - 250.0 * delta)
			if Input.is_action_pressed("move_right"): state_data["px"] = minf(w - 28.0, float(state_data["px"]) + 250.0 * delta)
			state_data["spawn_t"] = float(state_data["spawn_t"]) - delta
			var objs: Array = state_data["objs"]
			if float(state_data["spawn_t"]) <= 0.0:
				state_data["spawn_t"] = 0.36
				objs.append({"x": 30.0 + randf() * (w - 60.0), "y": -10.0, "good": randf() < 0.7})
			for i in range(objs.size() - 1, -1, -1):
				var o: Dictionary = objs[i]
				o["y"] = float(o["y"]) + 150.0 * delta
				if Vector2(float(o["x"]), float(o["y"])).distance_to(Vector2(float(state_data["px"]), 175.0)) < 26.0:
					if bool(o["good"]): score += 20; AudioManager.play_sfx("coin")
					else: score = maxi(0, score - 15); AudioManager.play_sfx("miss")
					objs.remove_at(i)
				elif float(o["y"]) > 220.0:
					objs.remove_at(i)
			status_lbl.text = "เวลา %.1fs • คะแนนสะสม: %d (เป้า S: 85+)" % [float(state_data["time_left"]), score]
			if float(state_data["time_left"]) <= 0.0:
				_finish_now(); return
		"stardew_fish":
			state_data["elapsed"] = float(state_data["elapsed"]) + delta
			state_data["fish_t"] = float(state_data["fish_t"]) - delta
			if float(state_data["fish_t"]) <= 0.0:
				state_data["fish_t"] = 0.6 + randf() * 0.8
				state_data["fish_target"] = 22.0 + randf() * 155.0
			state_data["fish_y"] = lerpf(float(state_data["fish_y"]), float(state_data["fish_target"]), 3.4 * delta)
			var thrust := -330.0 if (hold_down or Input.is_action_pressed("interact")) else 280.0
			var bvy := clampf(float(state_data["bar_vy"]) + thrust * delta, -200.0, 200.0)
			var by := float(state_data["bar_y"]) + bvy * delta
			var bh := float(state_data["bar_h"])
			if by < 12.0: by = 12.0; bvy = 0.0
			if by + bh > 196.0: by = 196.0 - bh; bvy = 0.0
			state_data["bar_vy"] = bvy; state_data["bar_y"] = by
			var fy := float(state_data["fish_y"])
			var inside := fy >= by - 6.0 and fy <= by + bh + 6.0
			var pr := clampf(float(state_data["prog"]) + (26.0 if inside else -17.0) * delta, 0.0, 100.0)
			state_data["prog"] = pr
			score = int(round(pr))
			status_lbl.text = "ความคืบหน้าจับปลา: %d%%" % score
			if pr >= 100.0 or pr <= 0.0 or float(state_data["elapsed"]) >= 20.0:
				_finish_now(); return
		"rhythm_stage":
			var left := 0
			for n in state_data["notes"]:
				if bool(n["done"]): continue
				n["y"] = float(n["y"]) + 135.0 * delta
				if float(n["y"]) > 205.0:
					n["done"] = true
					state_data["combo"] = 0
				else:
					left += 1
			status_lbl.text = "คะแนนดนตรี: %d/%d • Combo x%d" % [score, max_score, int(state_data["combo"])]
			if left == 0:
				_finish_now(); return
	arena.queue_redraw()

func _draw_arena() -> void:
	var sz := arena.size
	arena.draw_rect(Rect2(Vector2.ZERO, sz), Color("#0f172a"))
	var font := GameData.font_bold
	match kind:
		"forge_heat":
			var tx := 36.0; var tw := sz.x - 72.0; var ty := 115.0
			arena.draw_rect(Rect2(tx, ty, tw, 36), Color("#1e293b"))
			var c := float(state_data["center"])
			arena.draw_rect(Rect2(tx + (c - 0.15) * tw, ty, 0.30 * tw, 36), Color(0.13, 0.77, 0.37, 0.5))
			arena.draw_rect(Rect2(tx + (c - 0.06) * tw, ty, 0.12 * tw, 36), Color("#facc15"))
			var nx := tx + float(state_data["pos"]) * tw
			arena.draw_rect(Rect2(nx - 4, ty - 6, 8, 48), Color.WHITE)
		"order_rush":
			var npc: Dictionary = state_data["npc"]
			var ptex := GameData.get_portrait(str(npc["id"]), "happy")
			if ptex:
				arena.draw_texture_rect(ptex, Rect2(44, 34, 128, 128), false)
			arena.draw_rect(Rect2(196, 48, 260, 100), Color("#fffbeb"))
			var iid := str(state_data["target"])
			var itex := GameData.get_item_icon(iid)
			if itex:
				arena.draw_texture_rect(itex, Rect2(210, 74, 44, 44), false)
			if font:
				arena.draw_string(font, Vector2(210, 70), "%s ขอสั่ง:" % str(npc["name_th"]), HORIZONTAL_ALIGNMENT_LEFT, 230, 13, Color("#4c230a"))
				arena.draw_string(font, Vector2(262, 102), str(GameData.item_by_id.get(iid, {}).get("name_th", iid)), HORIZONTAL_ALIGNMENT_LEFT, 185, 15, Color("#b45309"))
		"rune_memory":
			var seq: Array = state_data["seq"]
			var lit_rune := int(seq[int(state_data["show_pos"])]) if (bool(state_data["showing"]) and int(state_data["show_pos"]) >= 0) else -1
			var cols := [Color("#22c55e"), Color("#38bdf8"), Color("#f97316"), Color("#c084fc"), Color("#facc15"), Color("#f472b6")]
			for i in range(6):
				var r := Rect2(48 + (i % 3) * 140, 22 + (i / 3) * 86, 118, 72)
				arena.draw_rect(r, cols[i] if lit_rune == i else Color("#1e293b"))
				arena.draw_rect(r, Color.WHITE if lit_rune == i else cols[i], false, 2.5)
				if font:
					arena.draw_string(font, r.position + Vector2(16, 42), "%d. %s" % [i + 1, state_data["names"][i]], HORIZONTAL_ALIGNMENT_LEFT, 96, 14, Color("#0f172a") if lit_rune == i else Color.WHITE)
		"sky_dash":
			arena.draw_rect(Rect2(0, 182, sz.x, 28), Color("#14532d"))
			var ptex2 := GameData.get_walk_sheet(str(GameState.hero_custom.get("base_id", "01_ren")), false)
			var px := float(state_data["px"])
			if ptex2:
				arena.draw_texture_rect_region(ptex2, Rect2(px - 22, 144, 44, 44), Rect2(0, 128, 64, 64))
			else:
				arena.draw_circle(Vector2(px, 172), 14.0, Color("#fde047"))
			var good_tex := GameData.get_item_icon("item_starfall_crystal", false)
			for o in state_data["objs"]:
				var op := Vector2(float(o["x"]), float(o["y"]))
				if bool(o["good"]) and good_tex:
					arena.draw_texture_rect(good_tex, Rect2(op.x - 13, op.y - 13, 26, 26), false)
				else:
					arena.draw_circle(op, 11.0, Color("#34d399") if bool(o["good"]) else Color("#ef4444"))
					if not bool(o["good"]):
						arena.draw_circle(op + Vector2(-3, -3), 4.0, Color("#7f1d1d"))
		"stardew_fish":
			var cx := sz.x * 0.5 - 32.0
			arena.draw_rect(Rect2(cx, 12, 52, 184), Color("#0c4a6e"))
			arena.draw_rect(Rect2(cx + 4, float(state_data["bar_y"]), 44, float(state_data["bar_h"])), Color(0.29, 0.87, 0.5, 0.8))
			var fish_tex := GameData.get_item_icon("item_grilled_salmon", false)
			if fish_tex:
				arena.draw_texture_rect(fish_tex, Rect2(cx + 12, float(state_data["fish_y"]) - 14, 28, 28), false)
			else:
				arena.draw_circle(Vector2(cx + 26, float(state_data["fish_y"])), 9.0, Color("#fde047"))
			var ph := (float(state_data["prog"]) / 100.0) * 184.0
			arena.draw_rect(Rect2(cx + 68, 12, 20, 184), Color("#1e293b"))
			arena.draw_rect(Rect2(cx + 70, 12 + 184.0 - ph, 16, ph), Color("#22c55e"))
		"rhythm_stage":
			var cols := [Color("#f43f5e"), Color("#facc15"), Color("#38bdf8"), Color("#a855f7")]
			for li in range(4):
				var lx := 82.0 + li * 88.0
				arena.draw_rect(Rect2(lx, 10, 68, 188), Color(1, 1, 1, 0.18), false, 1.5)
				arena.draw_rect(Rect2(lx, 160, 68, 22), Color(1.0, 0.85, 0.2, 0.25))
			for n in state_data["notes"]:
				if bool(n["done"]): continue
				var lane := int(n["lane"])
				arena.draw_circle(Vector2(82.0 + lane * 88.0 + 34.0, float(n["y"])), 13.0, cols[lane])
