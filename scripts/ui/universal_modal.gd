extends PanelContainer
class_name UniversalModal
## Unified Stardew-Style Tabbed Menu Modal for Godot 4:
## - creator: 8-Race / 16-Silhouette Protagonist Customizer + HSV & 7 Skin Tints + Live Shader Preview
## - saves: 3 Save Slots Manager + Audio & HD/Classic Sprite Sheet Switcher
## - jobs: 8 Part-Time Jobs (6 Specialized Minigames)
## - shop: Bag, 5 Town Shops, 12 Grid Furniture Items & 2nd Floor Starlight Loft Upgrade
## - craft: 11 Crafting & Cooking Recipes (including World Tree Wedding Ring!)
## - rels: 16 Characters Relationships & Marriage Tracker
## - quests: 10 Bulletin Quests, 15 Chronicles, 5 Landmarks, 12 Museum Relics & Ancient Ruins
## - mail: Mailbox Letters & Claimable Gifts

signal start_job_requested(job_dict: Dictionary)
signal play_chapter_requested(ch_dict: Dictionary)
signal gift_chosen(npc_id: String, item_id: String)
signal hero_customized
signal enter_ruins_requested

var title_lbl: Label
var tabs_flow: HFlowContainer
var scroll: ScrollContainer
var list_vb: VBoxContainer
var _preview_sprite: Sprite2D
var _preview_mat: ShaderMaterial
var _anim_t: float = 0.0

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(860, 560)
	var root_vb := VBoxContainer.new()
	root_vb.add_theme_constant_override("separation", 8)
	add_child(root_vb)

	var top := HBoxContainer.new()
	root_vb.add_child(top)
	title_lbl = Label.new()
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", 18)
	top.add_child(title_lbl)

	var close_b := Button.new()
	close_b.text = "ปิด [Esc]"
	close_b.pressed.connect(func(): visible = false)
	top.add_child(close_b)

	tabs_flow = HFlowContainer.new()
	tabs_flow.add_theme_constant_override("h_separation", 6)
	root_vb.add_child(tabs_flow)

	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vb.add_child(scroll)

	list_vb = VBoxContainer.new()
	list_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vb.add_theme_constant_override("separation", 6)
	scroll.add_child(list_vb)

func _process(delta: float) -> void:
	if visible and _preview_sprite and is_instance_valid(_preview_sprite):
		_anim_t += delta * 8.0
		_preview_sprite.frame_coords = Vector2i(int(_anim_t) % 9, 2)

func _clear() -> void:
	_preview_sprite = null
	for c in tabs_flow.get_children(): c.queue_free()
	for c in list_vb.get_children(): c.queue_free()
	visible = true

func _add_row(title: String, subtitle: String, btn_text: String = "", cb: Callable = Callable(), enabled: bool = true) -> void:
	var pc := PanelContainer.new()
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	pc.add_child(hb)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var l1 := Label.new(); l1.text = title; l1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var l2 := Label.new(); l2.text = subtitle; l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l2.add_theme_font_size_override("font_size", 12)
	l2.add_theme_color_override("font_color", Color("#5c3312"))
	vb.add_child(l1); vb.add_child(l2)
	hb.add_child(vb)
	if btn_text != "":
		var b := Button.new()
		b.text = btn_text
		b.disabled = not enabled
		if cb.is_valid(): b.pressed.connect(cb)
		hb.add_child(b)
	list_vb.add_child(pc)

# --- 1. 8-RACE PROTAGONIST CREATOR ---
func open_protagonist_creator() -> void:
	_clear()
	title_lbl.text = "แต่งตัวเอก 8 เผ่าพันธุ์ & ปรับโทนสีชุด/ผิว 2.5D (Real-Time Shader)"
	var hc: Dictionary = GameState.hero_custom
	var rk := GameData.get_char_race_key(str(hc.get("base_id", "01_ren")))
	hc["race_key"] = rk
	var rinfo: Dictionary = GameData.RACE_PERKS.get(rk, GameData.RACE_PERKS["human"])

	var top_hb := HBoxContainer.new()
	top_hb.add_theme_constant_override("separation", 16)
	list_vb.add_child(top_hb)

	var prev_box := PanelContainer.new()
	prev_box.custom_minimum_size = Vector2(150, 150)
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(128, 128)
	prev_box.add_child(stage)
	_preview_sprite = Sprite2D.new()
	_preview_sprite.texture = GameData.get_walk_sheet(str(hc.get("base_id", "01_ren")), false)
	_preview_sprite.hframes = 9; _preview_sprite.vframes = 4
	_preview_sprite.position = Vector2(64, 68)
	_preview_sprite.scale = Vector2(2.0, 2.0)
	_preview_mat = ShaderMaterial.new()
	_preview_mat.shader = load("res://shaders/protagonist_recolor.gdshader") as Shader
	_preview_sprite.material = _preview_mat
	stage.add_child(_preview_sprite)
	_sync_preview_shader()
	top_hb.add_child(prev_box)

	var form := VBoxContainer.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hb.add_child(form)

	var name_in := LineEdit.new(); name_in.text = GameState.player_name; name_in.placeholder_text = "ชื่อตัวเอก"
	name_in.text_changed.connect(func(t: String): if t.strip_edges() != "": GameState.player_name = t.strip_edges())
	form.add_child(name_in)

	var farm_in := LineEdit.new(); farm_in.text = GameState.cottage_name; farm_in.placeholder_text = "ชื่อบ้านพัก/กระท่อม"
	farm_in.text_changed.connect(func(t: String): if t.strip_edges() != "": GameState.cottage_name = t.strip_edges())
	form.add_child(farm_in)

	var perk_lbl := Label.new()
	perk_lbl.text = "เผ่าปัจจุบัน: %s — %s" % [rinfo["name_th"], rinfo["perk_th"]]
	perk_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	perk_lbl.add_theme_color_override("font_color", Color("#14532d"))
	form.add_child(perk_lbl)

	# Hue / Sat / Skin controls
	var hue_sl := HSlider.new(); hue_sl.min_value = -180; hue_sl.max_value = 180; hue_sl.value = float(hc.get("hue", 0.0))
	var hue_lbl := Label.new(); hue_lbl.text = "เฉดสีชุด/ทรงผม (Hue): %d°" % int(hue_sl.value)
	hue_sl.value_changed.connect(func(v: float):
		GameState.hero_custom["hue"] = v
		hue_lbl.text = "เฉดสีชุด/ทรงผม (Hue): %d°" % int(v)
		_sync_preview_shader()
		hero_customized.emit()
	)
	list_vb.add_child(hue_lbl); list_vb.add_child(hue_sl)

	var sat_sl := HSlider.new(); sat_sl.min_value = 40; sat_sl.max_value = 170; sat_sl.value = float(hc.get("sat", 100.0))
	var sat_lbl := Label.new(); sat_lbl.text = "ความสดสี (Saturation): %d%%" % int(sat_sl.value)
	sat_sl.value_changed.connect(func(v: float):
		GameState.hero_custom["sat"] = v
		sat_lbl.text = "ความสดสี (Saturation): %d%%" % int(v)
		_sync_preview_shader()
		hero_customized.emit()
	)
	list_vb.add_child(sat_lbl); list_vb.add_child(sat_sl)

	var skin_row := HFlowContainer.new()
	var skins := ["none", "warm", "tan", "pale", "drow", "goblin", "aqua"]
	var skin_names := {"none": "สีผิวเดิม", "warm": "ขาวอมชมพู", "tan": "ผิวแทน", "pale": "ขาวจันทรา", "drow": "ดาร์กเอลฟ์", "goblin": "ทองก็อบลิน", "aqua": "ฟ้าสมุทร"}
	for sk in skins:
		var sb := Button.new(); sb.text = skin_names[sk]
		sb.pressed.connect(func():
			GameState.hero_custom["skin"] = sk
			_sync_preview_shader()
			hero_customized.emit()
		)
		skin_row.add_child(sb)
	list_vb.add_child(skin_row)

	var race_grid := GridContainer.new()
	race_grid.columns = 4
	for c in GameData.characters:
		var cid := str(c["id"])
		var b := Button.new()
		b.text = "%s (%s)" % [str(c["race_th"]), str(c["name_th"]).split(" ")[0]]
		b.pressed.connect(func():
			GameState.hero_custom["base_id"] = cid
			GameState.hero_custom["race_key"] = GameData.get_char_race_key(cid)
			hero_customized.emit()
			open_protagonist_creator()
		)
		race_grid.add_child(b)
	list_vb.add_child(race_grid)

	var done_b := Button.new(); done_b.text = "บันทึกรูปลักษณ์ตัวเอก"
	done_b.pressed.connect(func():
		GameState.save_slot(GameState.active_slot, true)
		hero_customized.emit()
		visible = false
	)
	list_vb.add_child(done_b)

func _sync_preview_shader() -> void:
	if not _preview_mat: return
	var hc: Dictionary = GameState.hero_custom
	_preview_mat.set_shader_parameter("hue_shift_deg", float(hc.get("hue", 0.0)))
	_preview_mat.set_shader_parameter("sat_mult", float(hc.get("sat", 100.0)) / 100.0)
	_preview_mat.set_shader_parameter("val_mult", float(hc.get("val", 100.0)) / 100.0)
	_preview_mat.set_shader_parameter("skin_mode", int(GameState.SKIN_MODES.get(str(hc.get("skin", "none")), 0)))

# --- 2. 3 SAVE SLOTS & AUDIO/HD SETTINGS ---
func open_save_slots_modal() -> void:
	_clear()
	title_lbl.text = "จัดการเซฟ 3 ช่อง (Save Slots 1-3) & ตั้งค่าเสียง BGM โซน / สไปรต์ HD"
	_add_row(
		"เพลงประกอบ BGM แยกตาม 7 โซน: %s" % AudioManager.get_current_bgm_title(),
		"สถานะเสียงปัจจุบัน: %s | โหมดสไปรต์: %s (เชื่อมครบทั้ง 284 ไฟล์สไปรต์!)" % ["เปิดเสียง" if AudioManager.audio_enabled else "ปิดเสียง", "HD 128px" if GameData.use_hd_sprites else "Classic 64px"],
		"สลับ HD/Classic",
		func():
			GameData.use_hd_sprites = not GameData.use_hd_sprites
			hero_customized.emit()
			open_save_slots_modal()
	)
	for n in [1, 2, 3]:
		var d := GameState.read_slot_summary(n)
		var cur := " [กำลังเล่นช่องนี้]" if GameState.active_slot == n else ""
		var desc := "ว่างเปล่า — พร้อมบันทึกเกม" if d.is_empty() else "ตัวเอก: %s (%s) • วันที่ %d • ทอง %d G • บ้านชั้น %d" % [d.get("player_name", "อาริน"), d.get("cottage_name", ""), int(d.get("day", 1)), int(d.get("gold", 0)), int(d.get("house_level", 1))]
		var pc := PanelContainer.new()
		var hb := HBoxContainer.new()
		pc.add_child(hb)
		var lb := Label.new(); lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lb.text = "ช่องเซฟที่ %d%s\n%s" % [n, cur, desc]
		hb.add_child(lb)
		var bs := Button.new(); bs.text = "เซฟทับ"; bs.pressed.connect(func(): GameState.save_slot(n, false); open_save_slots_modal())
		var bl := Button.new(); bl.text = "โหลด"; bl.disabled = d.is_empty(); bl.pressed.connect(func(): GameState.load_slot(n, true); hero_customized.emit(); visible = false)
		hb.add_child(bs); hb.add_child(bl)
		if not d.is_empty():
			var bd := Button.new(); bd.text = "ลบ"; bd.pressed.connect(func(): GameState.delete_slot(n); open_save_slots_modal())
			hb.add_child(bd)
		list_vb.add_child(pc)

# --- 3. PART-TIME JOBS ---
func open_jobs_modal() -> void:
	_clear()
	title_lbl.text = "งานพาร์ทไทม์ประจำเมือง 8 อาชีพ (เชื่อม 6 มินิเกมแยกสาย!)"
	for j in GameData.jobs:
		var done := GameState.worked_today.has(j["id"])
		var kind := MiniGameModal.get_job_minigame_kind(str(j["id"]))
		_add_row(
			"%s (%s) — ค่าจ้างพื้นฐาน %d G (Rank S x1.5!)" % [j["title_th"], kind, int(j["base_pay_gold"])],
			"%s • พลังงาน -%d" % [j["description_th"], int(j["energy_cost"])],
			"ทำแล้ววันนี้" if done else "เริ่มมินิเกม",
			func(): visible = false; start_job_requested.emit(j),
			not done
		)

# --- 4. SHOPS, BAG, 12 GRID FURNITURE & 2ND FLOOR LOFT ---
func open_shop_modal(tab: String = "bag") -> void:
	_clear()
	title_lbl.text = "ร้านค้า กระเป๋า เฟอร์นิเจอร์ตาราง & ต่อเติมชั้น 2 (มีเงิน %d G)" % GameState.gold
	var tabs := [["bag", "กระเป๋า"], ["decor", "แต่งบ้านตาราง & ชั้น 2"], ["shop", "ร้านชำ"], ["bakery", "ขนมปัง"], ["tavern", "โรงเตี๊ยม"], ["cottage", "สมุนไพร"], ["smithy", "ตีเหล็ก"]]
	for t in tabs:
		var b := Button.new(); b.text = t[1]
		b.pressed.connect(func(): open_shop_modal(t[0]))
		tabs_flow.add_child(b)

	if tab == "bag":
		if GameState.inventory.is_empty():
			_add_row("กระเป๋าว่างเปล่า", "เดินเก็บจุดประกายของป่า ตกปลา หรือซื้อสินค้าจากร้านค้าได้เลย!")
		for iid in GameState.inventory.keys():
			var qty := int(GameState.inventory[iid])
			var it: Dictionary = GameData.item_by_id.get(iid, {})
			var en := int(it.get("energy_restore", 0))
			var sub := "%s (ขายได้ %d G)" % [it.get("description_th", ""), int(it.get("sell_price", 20))]
			_add_row(
				"%s x%d" % [it.get("name_th", iid), qty],
				sub,
				("กิน +%d⚡" % en) if en > 0 else ("ขาย +%dG" % int(it.get("sell_price", 20))),
				func():
					if en > 0:
						GameState.add_item(iid, -1)
						GameState.stamina = mini(GameState.get_max_stamina(), GameState.stamina + en)
						AudioManager.play_sfx("heart")
					else:
						GameState.add_item(iid, -1)
						GameState.add_gold(int(it.get("sell_price", 20)))
						AudioManager.play_sfx("coin")
					open_shop_modal("bag")
			)
	elif tab == "decor":
		_add_row(
			"ขยายต่อเติมชั้น 2: ห้องใต้หลังคาชมดาว (Starlight Loft 14x10) %s" % ("[สร้างเสร็จแล้ว!]" if GameState.house_level >= 2 else ""),
			"ปลดล็อกบันไดขึ้นชั้น 2 ในบ้าน พลังงานสูงสุด +15 และเรือนหอชมดาวกับคู่สมรส (ใช้ 600G + ไม้โอ๊กเนื้อแข็ง x2)",
			"พร้อมใช้งาน" if GameState.house_level >= 2 else "ต่อเติม 600G",
			func(): if GameState.upgrade_second_floor(): open_shop_modal("decor"),
			GameState.house_level < 2
		)
		for d in GameData.HOME_DECOR:
			var did := str(d["id"])
			var owned := GameState.decor_owned.has(did)
			_add_row(
				"%s (ขนาด %dx%d ช่อง) %s" % [d["label"], int(d["w"]), int(d["h"]), "[เป็นเจ้าของแล้ว]" if owned else ""],
				"โบนัส: %s (กด [H] ในบ้านเพื่อคลิกวาง/หมุน [R] บนช่องตาราง!)" % d["perk_th"],
				"เลือกเตรียมวาง" if owned else ("ซื้อ %dG" % int(d["price"])),
				func():
					if not owned:
						if GameState.gold < int(d["price"]):
							GameState.toast_requested.emit("เงินไม่พอซื้อเฟอร์นิเจอร์ชิ้นนี้!")
							return
						GameState.gold -= int(d["price"])
						GameState.decor_owned[did] = true
						AudioManager.play_sfx("coin")
					GameState.selected_decor_id = did
					if GameState.current_scene in ["farmhouse", "farmhouse_upstairs"]:
						GameState.home_edit_mode = true
						visible = false
					else:
						open_shop_modal("decor")
			)
	else:
		for it in GameData.items:
			if str(it.get("shop_id", "")) != tab: continue
			var iid := str(it["id"])
			var price := int(it["price"])
			_add_row(
				"%s (มีในกระเป๋า: %d)" % [it["name_th"], int(GameState.inventory.get(iid, 0))],
				str(it.get("description_th", "")),
				"ซื้อ %dG" % price,
				func():
					if GameState.gold < price:
						GameState.toast_requested.emit("เงินไม่พอ!")
						return
					GameState.gold -= price
					GameState.add_item(iid, 1)
					AudioManager.play_sfx("coin")
					open_shop_modal(tab)
			)

# --- 5. CRAFTING ---
func open_craft_modal() -> void:
	_clear()
	title_lbl.text = "โต๊ะทำอาหาร คราฟต์ของขวัญ & ตีแหวนแต่งงาน (11 สูตร)"
	for r in GameData.CRAFT_RECIPES:
		var ing: Dictionary = r["ingredients"]
		var parts: Array[String] = []
		var ok := true
		for iid in ing.keys():
			var req := int(ing[iid])
			var have := int(GameState.inventory.get(iid, 0))
			if have < req: ok = false
			parts.append("%s (%d/%d)" % [GameData.item_by_id.get(iid, {}).get("name_th", iid), have, req])
		_add_row(
			str(r["name_th"]),
			"วัตถุดิบ: " + " + ".join(parts),
			"สร้าง (-6⚡)",
			func():
				for iid in ing.keys():
					GameState.add_item(iid, -int(ing[iid]))
				GameState.add_item(str(r["out_id"]), 1)
				GameState.stamina = maxi(0, GameState.stamina - 6)
				if str(GameState.hero_custom.get("race_key", "")) == "beastkin":
					GameState.stamina = mini(GameState.get_max_stamina(), GameState.stamina + 8)
				GameState.crafted_count += 1
				GameState.add_stat_xp(r["stat"])
				AudioManager.play_sfx("sparkle")
				open_craft_modal(),
			ok and GameState.stamina >= 6
		)

# --- 6. RELATIONSHIPS & GIFT PICKER ---
func open_relationships_modal() -> void:
	_clear()
	title_lbl.text = "สมุดความสัมพันธ์ 16 ตัวละคร & ชีวิตคู่สมรส"
	for c in GameData.characters:
		var cid := str(c["id"])
		var h := GameState.get_hearts(cid)
		var tag := " [คู่สมรส]" if GameState.spouse_id == cid else (" [คู่รัก]" if GameState.partners.has(cid) else "")
		_add_row(
			"%s (%s)%s — หัวใจ %d/10" % [c["name_th"], c["race_th"], tag, h],
			"ของโปรด: " + ", ".join(c.get("gifts", {}).get("loved", [])),
			"ตั้งเข็มทิศ",
			func():
				GameState.compass_npc_id = cid
				visible = false
				GameState.toast_requested.emit("กำลังนำทางไปยัง %s!" % c["name_th"])
		)

func open_gift_picker(npc_id: String) -> void:
	_clear()
	var c: Dictionary = GameData.char_by_id.get(npc_id, {})
	title_lbl.text = "เลือกของขวัญมอบให้ %s" % c.get("name_th", npc_id)
	for iid in GameState.inventory.keys():
		var it: Dictionary = GameData.item_by_id.get(iid, {})
		_add_row(
			"%s x%d" % [it.get("name_th", iid), int(GameState.inventory[iid])],
			str(it.get("description_th", "")),
			"มอบชิ้นนี้",
			func(): visible = false; gift_chosen.emit(npc_id, iid)
		)

# --- 7. QUESTS, CHRONICLES, LANDMARKS, MUSEUM & ANCIENT RUINS ---
func open_quests_and_town_modal(tab: String = "quests") -> void:
	_clear()
	title_lbl.text = "เควสต์ เนื้อเรื่อง 4 สาย บูรณะเมือง & โบราณสถานรากไม้โลก"
	for t in [["quests", "เควสต์ (10)"], ["story", "พงศาวดาร (15 บท)"], ["landmarks", "บูรณะเมือง (5)"], ["museum", "พิพิธภัณฑ์ (12)"], ["ruins", "โบราณสถาน B1-B3"]]:
		var b := Button.new(); b.text = t[1]; b.pressed.connect(func(): open_quests_and_town_modal(t[0])); tabs_flow.add_child(b)

	if tab == "quests":
		for q in GameData.quests:
			var qid := str(q["id"])
			var st := str(GameState.quests_state.get(qid, "open"))
			_add_row(
				"%s [%s]" % [q["title"], st],
				"%s • รางวัล: %d G" % [q["desc"], int(q.get("reward", {}).get("gold", 150))],
				"สำเร็จแล้ว" if st == "completed" else ("ส่งเควสต์" if st == "accepted" else "รับเควสต์"),
				func():
					if st == "open":
						GameState.quests_state[qid] = "accepted"
						AudioManager.play_sfx("talk")
					elif st == "accepted":
						GameState.quests_state[qid] = "completed"
						GameState.add_gold(int(q.get("reward", {}).get("gold", 150)))
						AudioManager.play_sfx("quest")
					open_quests_and_town_modal("quests"),
				st != "completed"
			)
	elif tab == "story":
		for ch in GameData.chapters:
			var chid := str(ch["id"])
			var done := GameState.chronicles_done.has(chid)
			_add_row(
				"%s %s" % [ch["title_th"], "[ผ่านแล้ว]" if done else ""],
				str(ch.get("subtitle_th", "")),
				"ย้อนดู" if done else "เล่นเนื้อเรื่อง",
				func(): visible = false; play_chapter_requested.emit(ch)
			)
	elif tab == "landmarks":
		for lm in GameData.landmarks:
			var lmid := str(lm["id"])
			var built := GameState.landmarks_built.has(lmid)
			_add_row(
				"%s %s" % [lm["name_th"], "[สร้างแล้ว]" if built else ""],
				"%s (ค่าสร้าง %d G)" % [lm["summary_th"], int(lm["gold_cost"])],
				"สร้างแล้ว" if built else ("บูรณะ %dG" % int(lm["gold_cost"])),
				func():
					if GameState.gold < int(lm["gold_cost"]):
						GameState.toast_requested.emit("เงินไม่พอสำหรับบูรณะแลนด์มาร์ก!")
						return
					GameState.gold -= int(lm["gold_cost"])
					GameState.landmarks_built[lmid] = true
					AudioManager.play_sfx("build")
					open_quests_and_town_modal("landmarks"),
				not built
			)
	elif tab == "museum":
		for m in GameData.museum_collection:
			var iid := str(m["item_id"])
			var done := GameState.museum_donated.has(iid)
			var have := int(GameState.inventory.get(iid, 0))
			_add_row(
				"%s %s" % [GameData.item_by_id.get(iid, {}).get("name_th", iid), "[จัดแสดงแล้ว]" if done else ("(มี %d)" % have)],
				str(m["lore_th"]),
				"บริจาคแล้ว" if done else "บริจาค (+60G)",
				func():
					GameState.add_item(iid, -1)
					GameState.museum_donated[iid] = true
					GameState.add_gold(60)
					AudioManager.play_sfx("sparkle")
					open_quests_and_town_modal("museum"),
				(not done) and have > 0
			)
	elif tab == "ruins":
		_add_row(
			"ลงสำรวจโบราณสถานใต้รากไม้โลก (ชั้น B1 - B3)",
			"หมุนเสาปริซึมสะท้อนลำแสงมานาให้ชนแท่นรับแสงครบทุกจุด เพื่อปลดล็อกหีบสมบัติบรรพกาลและแหวนสายใยรากไม้โลก!",
			"วาร์ปเข้าชั้น B1!",
			func(): visible = false; enter_ruins_requested.emit()
		)
		for fid in ["ruins_b1", "ruins_b2", "ruins_b3"]:
			var fl: Dictionary = GameData.RUINS_FLOORS[fid]
			var rs: Dictionary = GameState.ruins_state[fid]
			_add_row(
				str(fl["name_th"]),
				"สถานะเสาแสง: %s • หีบสมบัติ: %s" % ["ปลดผนึกแล้ว!" if bool(rs["solved"]) else "รอการแก้ไข", "เปิดรับแล้ว" if bool(rs["chest_opened"]) else ("+%dG" % int(fl["chest"]["gold"]))]
			)

func open_mailbox_modal() -> void:
	_clear()
	title_lbl.text = "ตู้จดหมายหน้าบ้านพัก"
	for m in GameState.mailbox:
		var claimed := bool(m.get("claimed", false))
		_add_row(
			"%s (จาก: %s)" % [m["title"], m["sender"]],
			str(m["body"]),
			"รับแล้ว" if claimed else "รับของขวัญ",
			func():
				m["claimed"] = true
				if m.has("gift_id") and str(m["gift_id"]) != "":
					GameState.add_item(str(m["gift_id"]), 1)
				if int(m.get("gold", 0)) > 0:
					GameState.add_gold(int(m["gold"]))
				AudioManager.play_sfx("coin")
				open_mailbox_modal(),
			not claimed
		)
