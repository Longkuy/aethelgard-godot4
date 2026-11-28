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
signal replay_cutscene_requested(cs_dict: Dictionary, mode: String)
signal gift_chosen(npc_id: String, item_id: String)
signal hero_customized
signal enter_ruins_requested

var title_lbl: Label
var tabs_flow: HFlowContainer
var scroll: ScrollContainer
var list_vb: VBoxContainer
var _preview_canvas: Control
var _preview_dir: int = 2
var _preview_walk: bool = true
var _anim_t: float = 0.0

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(880, 575)
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
	if visible and _preview_canvas and is_instance_valid(_preview_canvas):
		_anim_t += delta * (8.5 if _preview_walk else 4.0)
		_preview_canvas.queue_redraw()

func _clear() -> void:
	_preview_canvas = null
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

func _add_section_label(txt: String) -> void:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color("#7c2d12"))
	list_vb.add_child(l)

func _randomize_hero() -> void:
	var opts: Dictionary = GameData.CREATOR_OPTIONS
	var races: Array = GameData.RACE_PERKS.keys()
	GameState.hero_custom["race_key"] = str(races[randi() % races.size()])
	GameState.hero_custom["build"] = str(opts["builds"][randi() % opts["builds"].size()]["id"])
	GameState.hero_custom["skin_hex"] = str(opts["skins"][randi() % opts["skins"].size()]["hex"])
	GameState.hero_custom["hair_style"] = str(opts["hair_styles"][randi() % opts["hair_styles"].size()]["id"])
	GameState.hero_custom["hair_hex"] = str(opts["hair_colors"][randi() % opts["hair_colors"].size()]["hex"])
	GameState.hero_custom["eye_style"] = str(opts["eye_styles"][randi() % opts["eye_styles"].size()]["id"])
	GameState.hero_custom["eye_hex"] = str(opts["eye_colors"][randi() % opts["eye_colors"].size()]["hex"])
	GameState.hero_custom["outfit_style"] = str(opts["outfit_styles"][randi() % opts["outfit_styles"].size()]["id"])
	GameState.hero_custom["shirt_hex"] = str(opts["shirt_colors"][randi() % opts["shirt_colors"].size()]["hex"])
	GameState.hero_custom["pants_hex"] = str(opts["pants_colors"][randi() % opts["pants_colors"].size()]["hex"])
	AudioManager.play_sfx("sparkle")
	hero_customized.emit()
	open_protagonist_creator("hero")

# --- 1. TRUE MODULAR CHARACTER CREATOR + LAYERED WARDROBE & ACCESSORIES ---
func open_protagonist_creator(subtab: String = "hero") -> void:
	_clear()
	title_lbl.text = "🎨 สร้างตัวละครของตัวเอง (8 เผ่า • ทรงผม • ดวงตา • ชุด) & ตู้เสื้อผ้า (มี %d G)" % GameState.gold
	for tb in [["hero", "🧬 สร้างรูปลักษณ์ตัวเอก"], ["wardrobe", "👒 หมวก/ปีก/ผ้าคลุม & ออร่าชุด"]]:
		var b := Button.new(); b.text = tb[1]
		b.pressed.connect(func(): open_protagonist_creator(tb[0]))
		tabs_flow.add_child(b)

	var hc: Dictionary = GameState.hero_custom
	var rk := str(hc.get("race_key", "human"))
	var rinfo: Dictionary = GameData.RACE_PERKS.get(rk, GameData.RACE_PERKS["human"])

	var top_hb := HBoxContainer.new()
	top_hb.add_theme_constant_override("separation", 16)
	list_vb.add_child(top_hb)

	# Live Rotating Procedural Character Stage (2.7x zoom!)
	var prev_vb := VBoxContainer.new()
	var prev_box := PanelContainer.new()
	prev_box.custom_minimum_size = Vector2(180, 178)
	_preview_canvas = Control.new()
	_preview_canvas.custom_minimum_size = Vector2(158, 156)
	_preview_canvas.draw.connect(func():
		_preview_canvas.draw_rect(Rect2(Vector2.ZERO, _preview_canvas.size), Color("#1e293b"))
		_preview_canvas.draw_circle(Vector2(79, 134), 34.0, Color(0, 0, 0, 0.3))
		_preview_canvas.draw_set_transform(Vector2(79, 134), 0.0, Vector2(2.6, 2.6))
		CharacterActor.draw_custom_character(_preview_canvas, GameState.hero_custom, _preview_dir, "walk" if _preview_walk else "idle", _anim_t, 0.0, GameState.equipped_accessory, GameState.equipped_outfit)
		_preview_canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	)
	prev_box.add_child(_preview_canvas)
	prev_vb.add_child(prev_box)

	var p_ctrl := HBoxContainer.new()
	p_ctrl.alignment = BoxContainer.ALIGNMENT_CENTER
	var b_rot_l := Button.new(); b_rot_l.text = "◀ หมุน"
	b_rot_l.pressed.connect(func(): _preview_dir = (_preview_dir + 1) % 4)
	var b_walk := Button.new(); b_walk.text = "เดิน/ยืน"
	b_walk.pressed.connect(func(): _preview_walk = not _preview_walk)
	var b_rnd := Button.new(); b_rnd.text = "🎲 สุ่ม"
	b_rnd.pressed.connect(_randomize_hero)
	p_ctrl.add_child(b_rot_l); p_ctrl.add_child(b_walk); p_ctrl.add_child(b_rnd)
	prev_vb.add_child(p_ctrl)
	top_hb.add_child(prev_vb)

	var form := VBoxContainer.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hb.add_child(form)

	var name_in := LineEdit.new(); name_in.text = GameState.player_name; name_in.placeholder_text = "ชื่อตัวเอก"
	name_in.text_changed.connect(func(t: String): if t.strip_edges() != "": GameState.player_name = t.strip_edges())
	form.add_child(name_in)

	var farm_in := LineEdit.new(); farm_in.text = GameState.cottage_name; farm_in.placeholder_text = "ชื่อบ้านพัก/ฐานทัพนักผจญภัย"
	farm_in.text_changed.connect(func(t: String): if t.strip_edges() != "": GameState.cottage_name = t.strip_edges())
	form.add_child(farm_in)

	var acc_def := GameData.get_accessory_def(GameState.equipped_accessory)
	var out_def := GameData.get_outfit_def(GameState.equipped_outfit)
	var perk_lbl := Label.new()
	perk_lbl.text = "%s %s — %s\nสวมใส่อยู่: %s | %s" % [rinfo["icon"], rinfo["name_th"], rinfo["perk_th"], acc_def["name_th"], out_def["name_th"]]
	perk_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	perk_lbl.add_theme_color_override("font_color", Color("#14532d"))
	form.add_child(perk_lbl)

	if subtab == "wardrobe":
		for a in GameData.ACCESSORIES:
			var aid := str(a["id"])
			var owned := GameState.owned_accessories.has(aid)
			var eq := (GameState.equipped_accessory == aid)
			var price := GameState.get_buy_price(int(a["price"]))
			_add_row(
				"👒 %s %s" % [a["name_th"], "[สวมใส่อยู่]" if eq else ("[มีแล้ว]" if owned else "")],
				str(a["desc_th"]),
				"สวมใส่อยู่" if eq else ("สวมใส่" if owned else ("ซื้อ %dG" % price)),
				func():
					if not owned:
						if GameState.gold < price:
							GameState.toast_requested.emit("เงินไม่พอซื้อเครื่องประดับชิ้นนี้!")
							return
						GameState.gold -= price
						GameState.owned_accessories[aid] = true
						AudioManager.play_sfx("coin")
					GameState.equipped_accessory = aid
					GameState.check_achievements()
					GameState.save_slot(GameState.active_slot, true)
					hero_customized.emit()
					open_protagonist_creator("wardrobe"),
				not eq
			)
		for o in GameData.OUTFIT_THEMES:
			var oid := str(o["id"])
			var owned2 := GameState.owned_outfits.has(oid)
			var eq2 := (GameState.equipped_outfit == oid)
			var price2 := GameState.get_buy_price(int(o["price"]))
			_add_row(
				"✨ %s %s" % [o["name_th"], "[สวมใส่อยู่]" if eq2 else ("[มีแล้ว]" if owned2 else "")],
				"ออร่าประกายแสงพิเศษรอบตัวละคร",
				"สวมใส่อยู่" if eq2 else ("สวมใส่" if owned2 else ("ซื้อ %dG" % price2)),
				func():
					if not owned2:
						if GameState.gold < price2:
							GameState.toast_requested.emit("เงินไม่พอซื้อออร่าชุดนี้!")
							return
						GameState.gold -= price2
						GameState.owned_outfits[oid] = true
						AudioManager.play_sfx("coin")
					GameState.equipped_outfit = oid
					GameState.check_achievements()
					GameState.save_slot(GameState.active_slot, true)
					hero_customized.emit()
					open_protagonist_creator("wardrobe"),
				not eq2
			)
		return

	var opts: Dictionary = GameData.CREATOR_OPTIONS

	# 1. Race (8 Races with Real Anatomy!)
	_add_section_label("1. เผ่าพันธุ์ (8 เผ่า — เปลี่ยนหู/ปีก/หาง/เครา & ความสามารถพิเศษจริง!)")
	var r_row := HFlowContainer.new()
	for rkey in GameData.RACE_PERKS.keys():
		var rd: Dictionary = GameData.RACE_PERKS[rkey]
		var rb := Button.new()
		rb.text = "%s %s%s" % [rd["icon"], str(rd["name_th"]).split(" ")[0], " ✓" if rk == rkey else ""]
		rb.pressed.connect(func():
			GameState.hero_custom["race_key"] = rkey
			hero_customized.emit()
			open_protagonist_creator("hero")
		)
		r_row.add_child(rb)
	list_vb.add_child(r_row)

	# 2. Body Build & Skin Tone
	_add_section_label("2. รูปร่าง (Build) & สีผิว (8 โทนสี)")
	var b_row := HFlowContainer.new()
	for bd in opts["builds"]:
		var bid := str(bd["id"])
		var bb := Button.new(); bb.text = str(bd["name_th"]) + (" ✓" if str(hc.get("build", "normal")) == bid else "")
		bb.pressed.connect(func(): GameState.hero_custom["build"] = bid; hero_customized.emit(); open_protagonist_creator("hero"))
		b_row.add_child(bb)
	list_vb.add_child(b_row)

	var sk_row := HFlowContainer.new()
	for sk in opts["skins"]:
		var shex := str(sk["hex"])
		var sb := Button.new(); sb.text = str(sk["name_th"]) + (" ✓" if str(hc.get("skin_hex", "")) == shex else "")
		sb.pressed.connect(func(): GameState.hero_custom["skin_hex"] = shex; hero_customized.emit(); open_protagonist_creator("hero"))
		sk_row.add_child(sb)
	list_vb.add_child(sk_row)

	# 3. Hair Style (8) & Hair Color (10)
	_add_section_label("3. ทรงผม (8 ทรง) & สีผม (10 สี)")
	var hs_row := HFlowContainer.new()
	for hs in opts["hair_styles"]:
		var hsid := str(hs["id"])
		var hb := Button.new(); hb.text = str(hs["name_th"]) + (" ✓" if str(hc.get("hair_style", "")) == hsid else "")
		hb.pressed.connect(func(): GameState.hero_custom["hair_style"] = hsid; hero_customized.emit(); open_protagonist_creator("hero"))
		hs_row.add_child(hb)
	list_vb.add_child(hs_row)

	var hc_row := HFlowContainer.new()
	for hcol in opts["hair_colors"]:
		var hhex := str(hcol["hex"])
		var cb := Button.new(); cb.text = str(hcol["name_th"]) + (" ✓" if str(hc.get("hair_hex", "")) == hhex else "")
		cb.pressed.connect(func(): GameState.hero_custom["hair_hex"] = hhex; hero_customized.emit(); open_protagonist_creator("hero"))
		hc_row.add_child(cb)
	list_vb.add_child(hc_row)

	# 4. Eye Style (4) & Eye Color (8)
	_add_section_label("4. ทรงดวงตา (4 แบบ) & สีตา (8 สี)")
	var es_row := HFlowContainer.new()
	for es in opts["eye_styles"]:
		var esid := str(es["id"])
		var eb := Button.new(); eb.text = str(es["name_th"]) + (" ✓" if str(hc.get("eye_style", "")) == esid else "")
		eb.pressed.connect(func(): GameState.hero_custom["eye_style"] = esid; hero_customized.emit(); open_protagonist_creator("hero"))
		es_row.add_child(eb)
	list_vb.add_child(es_row)

	var ec_row := HFlowContainer.new()
	for ecol in opts["eye_colors"]:
		var ehex := str(ecol["hex"])
		var ecb := Button.new(); ecb.text = str(ecol["name_th"]) + (" ✓" if str(hc.get("eye_hex", "")) == ehex else "")
		ecb.pressed.connect(func(): GameState.hero_custom["eye_hex"] = ehex; hero_customized.emit(); open_protagonist_creator("hero"))
		ec_row.add_child(ecb)
	list_vb.add_child(ec_row)

	# 5. Outfit Style (6), Shirt Color (8) & Pants Color (6)
	_add_section_label("5. สไตล์ชุด (6 แบบ), สีเสื้อ (8 สี) & สีกางเกง (6 สี)")
	var os_row := HFlowContainer.new()
	for osd in opts["outfit_styles"]:
		var osid := str(osd["id"])
		var ob := Button.new(); ob.text = str(osd["name_th"]) + (" ✓" if str(hc.get("outfit_style", "")) == osid else "")
		ob.pressed.connect(func(): GameState.hero_custom["outfit_style"] = osid; hero_customized.emit(); open_protagonist_creator("hero"))
		os_row.add_child(ob)
	list_vb.add_child(os_row)

	var sc_row := HFlowContainer.new()
	for scol in opts["shirt_colors"]:
		var shx := str(scol["hex"])
		var scb := Button.new(); scb.text = "เสื้อ:" + str(scol["name_th"]) + (" ✓" if str(hc.get("shirt_hex", "")) == shx else "")
		scb.pressed.connect(func(): GameState.hero_custom["shirt_hex"] = shx; hero_customized.emit(); open_protagonist_creator("hero"))
		sc_row.add_child(scb)
	list_vb.add_child(sc_row)

	var pc_row := HFlowContainer.new()
	for pcol in opts["pants_colors"]:
		var phx := str(pcol["hex"])
		var pcb := Button.new(); pcb.text = "กางเกง:" + str(pcol["name_th"]) + (" ✓" if str(hc.get("pants_hex", "")) == phx else "")
		pcb.pressed.connect(func(): GameState.hero_custom["pants_hex"] = phx; hero_customized.emit(); open_protagonist_creator("hero"))
		pc_row.add_child(pcb)
	list_vb.add_child(pc_row)

	var done_b := Button.new(); done_b.text = "✅ บันทึกตัวละครและออกผจญภัย!"
	done_b.pressed.connect(func():
		GameState.save_slot(GameState.active_slot, true)
		hero_customized.emit()
		visible = false
	)
	list_vb.add_child(done_b)

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
			GameState.save_settings()
			hero_customized.emit()
			open_save_slots_modal()
	)
	var vol_box := VBoxContainer.new()
	var bgm_l := Label.new(); bgm_l.text = "🎵 ระดับเสียงเพลง BGM: %d%%" % int(AudioManager.bgm_volume * 100.0)
	var bgm_s := HSlider.new(); bgm_s.min_value = 0.0; bgm_s.max_value = 100.0; bgm_s.value = AudioManager.bgm_volume * 100.0
	bgm_s.value_changed.connect(func(v: float): AudioManager.bgm_volume = v / 100.0; bgm_l.text = "🎵 ระดับเสียงเพลง BGM: %d%%" % int(v); GameState.save_settings())
	var sfx_l := Label.new(); sfx_l.text = "🔊 ระดับเสียงเอฟเฟกต์/บรรยากาศ (SFX): %d%%" % int(AudioManager.sfx_volume * 100.0)
	var sfx_s := HSlider.new(); sfx_s.min_value = 0.0; sfx_s.max_value = 100.0; sfx_s.value = AudioManager.sfx_volume * 100.0
	sfx_s.value_changed.connect(func(v: float): AudioManager.sfx_volume = v / 100.0; sfx_l.text = "🔊 ระดับเสียงเอฟเฟกต์/บรรยากาศ (SFX): %d%%" % int(v); GameState.save_settings())
	vol_box.add_child(bgm_l); vol_box.add_child(bgm_s); vol_box.add_child(sfx_l); vol_box.add_child(sfx_s)
	list_vb.add_child(vol_box)
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

func open_guild_modal() -> void:
	open_shop_modal("guild")

# --- 4. SHOPS, BAG, ADVENTURER'S GUILD, NIGHT MARKET, 12 GRID FURNITURE & 2ND FLOOR LOFT ---
func open_shop_modal(tab: String = "bag") -> void:
	_clear()
	title_lbl.text = "กิลด์นักผจญภัย ร้านค้า กระเป๋า ตลาดกลางคืน & แต่งบ้าน (มีเงิน %d G)" % GameState.gold
	var tabs := [["guild", "⚔️ กิลด์นักผจญภัย [Q]"], ["bag", "กระเป๋า"], ["decor", "แต่งบ้าน & ชั้น 2"], ["nightmarket", "🏮 ตลาดกลางคืน"], ["shop", "ร้านชำ"], ["bakery", "ขนมปัง"], ["tavern", "โรงเตี๊ยม"], ["cottage", "สมุนไพร"], ["smithy", "ตีเหล็ก"]]
	for t in tabs:
		var b := Button.new(); b.text = t[1]
		b.pressed.connect(func(): open_shop_modal(t[0]))
		tabs_flow.add_child(b)

	if tab == "guild":
		var rinfo := GameData.get_guild_rank_info(GameState.guild_xp)
		var tot_bonus := int(rinfo["gold_bonus_pct"]) + (20 if GameState.has_guild_charm else 0)
		_add_row(
			"⚔️ กิลด์นักผจญภัยเอเธลการ์ด — แรงก์ปัจจุบัน: Rank %s (%s)" % [str(rinfo["rank"]), str(rinfo["title_th"])],
			"Guild XP: %d • พิชิตภารกิจแล้ว: %d ครั้ง • โบนัสทองภารกิจกิลด์: +%d%% (รีเฟรชภารกิจใหม่ทุกเช้า!)" % [GameState.guild_xp, GameState.guild_completed, tot_bonus]
		)
		for gb in GameData.GUILD_BOUNTIES:
			var bid := str(gb["id"])
			var st := str(GameState.guild_bounties_state.get(bid, "open"))
			var prog := GameState.get_guild_bounty_progress(gb)
			var can_claim := bool(prog["done"])
			var pay_est := int(round(float(gb["gold"]) * (1.0 + float(tot_bonus) / 100.0)))
			var st_tag := " [สำเร็จแล้ว]" if st == "completed" else (" [กำลังทำ — %s]" % str(prog["text"]) if st == "accepted" else "")
			_add_row(
				"[Rank %s] ⚔️ %s%s" % [str(gb["rank"]), str(gb["title_th"]), st_tag],
				"%s • รางวัล: %d G + %d Guild XP" % [str(gb["desc_th"]), pay_est, int(gb["guild_xp"])],
				"สำเร็จแล้ว" if st == "completed" else ("ส่งรับรางวัล!" if st == "accepted" else "รับภารกิจ"),
				func():
					if st == "open":
						GameState.accept_guild_bounty(bid)
					elif st == "accepted":
						GameState.claim_guild_bounty(bid)
					open_shop_modal("guild"),
				st == "open" or (st == "accepted" and can_claim)
			)
		_add_section_label("🏆 คลังอุปกรณ์นักผจญภัย & สมบัติระดับตำนาน (Endgame Armory)")
		_add_row(
			"🎖️ เครื่องรางกิลด์ทองคำ (โบนัสทองภารกิจกิลด์ +20% ถาวร!) %s" % ("[สวมใส่อยู่!]" if GameState.has_guild_charm else ""),
			"ตราเกียรติยศของกิลด์นักผจญภัย เพิ่มเงินรางวัลจากทุกภารกิจกิลด์ +20% ถาวร!",
			"มีแล้ว" if GameState.has_guild_charm else "ซื้อ 400G",
			func():
				if GameState.gold < 400:
					GameState.toast_requested.emit("เงินไม่พอซื้อเครื่องรางกิลด์ (400 G)!")
					return
				GameState.gold -= 400
				GameState.has_guild_charm = true
				AudioManager.play_sfx("quest")
				GameState.save_slot(GameState.active_slot, true)
				open_shop_modal("guild"),
			not GameState.has_guild_charm
		)
		_add_row(
			"🦄 อาชาแสงดารา (Starlight Mount — กด [V] ขี่กลางแจ้งเร็วขึ้น +45%!) %s" % ("[เป็นเจ้าของแล้ว!]" if GameState.has_starlight_mount else ""),
			"สัตว์ขี่ในตำนานแห่งหุบเขาเอเธลการ์ด เปล่งประกายสีทองและวิ่งเร็วขึ้น +45% ทั่วแผนที่!",
			"พร้อมขี่ [V]" if GameState.has_starlight_mount else "ซื้อ 2,500G",
			func():
				if GameState.gold < 2500:
					GameState.toast_requested.emit("เงินไม่พอซื้ออาชาแสงดารา (2,500 G)!")
					return
				GameState.gold -= 2500
				GameState.has_starlight_mount = true
				GameState.mount_active = true
				AudioManager.play_sfx("quest")
				GameState.check_achievements()
				GameState.save_slot(GameState.active_slot, true)
				hero_customized.emit()
				open_shop_modal("guild"),
			not GameState.has_starlight_mount
		)
		_add_row(
			"🏆 อนุสาวรีย์ทองคำ 8 เผ่าพันธุ์ (Golden Monument — โบนัส XP สเตตัส +15% ถาวร!) %s" % ("[สร้างเสร็จแล้ว!]" if GameState.monument_built else ""),
			"สร้างอนุสาวรีย์ทองคำกลางจัตุรัสต้นไม้โลก รับโบนัส XP สเตตัสชีวิตทั้ง 4 ด้าน +15% ถาวร & ปลดล็อกรางวัลระดับตำนาน!",
			"สร้างแล้ว" if GameState.monument_built else "สร้าง 5,000G",
			func():
				if GameState.gold < 5000:
					GameState.toast_requested.emit("เงินไม่พอสร้างอนุสาวรีย์ทองคำ (5,000 G)!")
					return
				GameState.gold -= 5000
				GameState.monument_built = true
				AudioManager.play_sfx("quest")
				GameState.check_achievements()
				GameState.save_slot(GameState.active_slot, true)
				open_shop_modal("guild"),
			not GameState.monument_built
		)
	elif tab == "bag":
		if GameState.sell_bonus_pct > 0:
			_add_row("🏛️ พรพิพิธภัณฑ์ทำงานอยู่!", "ขายไอเทมทุกชิ้นได้ราคาเพิ่มขึ้น +%d%% ถาวร!" % GameState.sell_bonus_pct)
		if GameState.inventory.is_empty():
			_add_row("กระเป๋าว่างเปล่า", "เดินเก็บจุดประกายของป่า ตกปลา หรือซื้อสินค้าจากร้านค้าได้เลย!")
		for iid in GameState.inventory.keys():
			var qty := int(GameState.inventory[iid])
			var it: Dictionary = GameData.item_by_id.get(iid, {})
			var en := int(it.get("energy_restore", 0))
			var sp := GameState.get_sell_price(int(it.get("sell_price", 20)))
			var sub := "%s (ขายได้ %d G)" % [it.get("description_th", ""), sp]
			_add_row(
				"%s x%d" % [it.get("name_th", iid), qty],
				sub,
				("กิน +%d⚡" % en) if en > 0 else ("ขาย +%dG" % sp),
				func():
					if en > 0:
						GameState.add_item(iid, -1)
						GameState.stamina = mini(GameState.get_max_stamina(), GameState.stamina + en)
						AudioManager.play_sfx("heart")
					else:
						GameState.add_item(iid, -1)
						GameState.add_gold(sp)
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
			var dprice := GameState.get_buy_price(int(d["price"]))
			_add_row(
				"%s (ขนาด %dx%d ช่อง) %s" % [d["label"], int(d["w"]), int(d["h"]), "[เป็นเจ้าของแล้ว]" if owned else ""],
				"โบนัส: %s (กด [H] ในบ้านเพื่อคลิกวาง/หมุน [R] บนช่องตาราง!)" % d["perk_th"],
				"เลือกเตรียมวาง" if owned else ("ซื้อ %dG" % dprice),
				func():
					if not owned:
						if GameState.gold < dprice:
							GameState.toast_requested.emit("เงินไม่พอซื้อเฟอร์นิเจอร์ชิ้นนี้!")
							return
						GameState.gold -= dprice
						GameState.decor_owned[did] = true
						AudioManager.play_sfx("coin")
					GameState.selected_decor_id = did
					if GameState.current_scene in ["farmhouse", "farmhouse_upstairs"]:
						GameState.home_edit_mode = true
						visible = false
					else:
						open_shop_modal("decor")
			)
	elif tab == "nightmarket":
		var built := GameState.landmarks_built.has("lm_nightmarket")
		var hr := GameState.time_min / 60.0
		var open_now := built and (hr >= 18.0 or hr < 0.5)
		var wknd := ((GameState.day - 1) % 7) in [4, 5, 6]
		_add_row(
			"🏮 ตลาดนัดกลางคืนรากไม้ (Moonlit Night Market — เปิด 18:00–24:00 น.)",
			("สถานะ: เปิดขายคึกคัก! %s" % ("[ศุกร์-อาทิตย์ ลดพิเศษ 25%!]" if wknd else "")) if open_now else ("ต้องบูรณะ 'ตลาดนัดกลางคืนรากไม้' ก่อน!" if not built else "ขณะนี้ยังไม่ถึงเวลา 18:00 น. (กด +2 ชม. เพื่อรอเวลาค่ำได้นะ!)")
		)
		for iid in GameData.night_market_stock:
			var it2: Dictionary = GameData.item_by_id.get(str(iid), {})
			if it2.is_empty(): continue
			var nm_price := GameState.get_buy_price(int(it2.get("price", 200)), true)
			_add_row(
				"🌙 %s (มี: %d)" % [it2.get("name_th", iid), int(GameState.inventory.get(str(iid), 0))],
				str(it2.get("description_th", "")),
				"ซื้อ %dG" % nm_price,
				func():
					if GameState.gold < nm_price:
						GameState.toast_requested.emit("เงินไม่พอ!")
						return
					GameState.gold -= nm_price
					GameState.add_item(str(iid), 1)
					AudioManager.play_sfx("coin")
					open_shop_modal("nightmarket"),
				open_now
			)
	else:
		for it in GameData.items:
			if str(it.get("shop_id", "")) != tab: continue
			var iid := str(it["id"])
			var price := GameState.get_buy_price(int(it["price"]))
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
				GameState.check_achievements()
				AudioManager.play_sfx("sparkle")
				open_craft_modal(),
			ok and GameState.stamina >= 6
		)

# --- 6. RELATIONSHIPS, MARRIAGE & 3-STAGE CHILD FAMILY SYSTEM ---
func open_relationships_modal() -> void:
	_clear()
	title_lbl.text = "สมุดความสัมพันธ์ 16 ตัวละคร • ชีวิตคู่สมรส & ทายาทต้นไม้โลก"

	if GameState.spouse_id != "":
		var sp_name := str(GameData.char_by_id.get(GameState.spouse_id, {}).get("name_th", GameState.spouse_id))
		var born := bool(GameState.child_data.get("born", false))
		if not born:
			_add_row(
				"💒 ครอบครัวของคุณกับ %s" % sp_name,
				"หลังแต่งงานครบ 3 วัน ดอกตูมทายาทแห่งต้นไม้โลกจะถือกำเนิดขึ้นเอง หรือกดอธิษฐานขอพรรับขวัญทายาทได้ทันที!",
				"🌸 อธิษฐานรับทายาท!",
				func():
					visible = false
					GameState.trigger_child_birth()
					hero_customized.emit()
			)
		else:
			var stg := int(GameState.child_data.get("stage", 1))
			var stg_names := {1: "วัยทารกในเปลไม้เรืองแสง", 2: "วัยเดินเตาะแตะในบ้าน", 3: "วัยนักสำรวจตัวน้อยชมเมือง"}
			var child_box := HBoxContainer.new()
			var cname_in := LineEdit.new()
			cname_in.text = str(GameState.child_data.get("name", "ลูมิน่า"))
			cname_in.custom_minimum_size = Vector2(220, 0)
			cname_in.text_changed.connect(func(nt: String):
				if nt.strip_edges() != "":
					GameState.child_data["name"] = nt.strip_edges()
					hero_customized.emit()
			)
			var clbl := Label.new(); clbl.text = "👶 ตั้งชื่อลูกน้อย: "
			child_box.add_child(clbl); child_box.add_child(cname_in)
			list_vb.add_child(child_box)

			var cared := (int(GameState.child_data.get("cared_day", 0)) == GameState.day)
			_add_row(
				"👶 ลูกน้อย '%s' (%s • อายุ %d วัน)" % [GameState.child_data.get("name", "ลูมิน่า"), stg_names.get(stg, ""), int(GameState.child_data.get("days_old", 0))],
				"คู่สมรส: %s • ลูกจะเติบโตจาก วัยเปล -> วัยเตาะแตะ (3 วัน) -> วัยนักสำรวจชมเมือง (6 วัน)!",
				"ดูแลแล้ววันนี้" if cared else "อุ้ม/เล่นกับลูก (+18⚡)",
				func():
					var msg := GameState.interact_with_child()
					if msg != "":
						GameState.toast_requested.emit(msg)
					open_relationships_modal(),
				not cared
			)

	for c in GameData.characters:
		var cid := str(c["id"])
		var h := GameState.get_hearts(cid)
		var tag := " [คู่สมรส]" if GameState.spouse_id == cid else (" [คู่รัก]" if GameState.partners.has(cid) else "")
		var bd: Dictionary = GameData.NPC_BIRTHDAYS.get(cid, {"season": 0, "day": 1})
		var bd_txt := "🎂 วันเกิด: วันที่ %d %s" % [int(bd["day"]), GameState.SEASONS[int(bd["season"])]]
		_add_row(
			"%s (%s)%s — หัวใจ %d/10" % [c["name_th"], c["race_th"], tag, h],
			"%s • ของโปรด: %s" % [bd_txt, ", ".join(c.get("gifts", {}).get("loved", []))],
			"ตั้งเข็มทิศ",
			func():
				GameState.compass_npc_id = cid
				visible = false
				GameState.toast_requested.emit("กำลังนำทางไปยัง %s!" % c["name_th"])
		)

func open_gift_picker(npc_id: String) -> void:
	_clear()
	var c: Dictionary = GameData.char_by_id.get(npc_id, {})
	var bday := GameData.is_npc_birthday(npc_id, GameState.get_season_index(), GameState.get_day_of_season())
	title_lbl.text = "เลือกของขวัญมอบให้ %s%s" % [c.get("name_th", npc_id), " (🎂 วันเกิด x2 แต้มหัวใจ!)" if bday else ""]
	for iid in GameState.inventory.keys():
		var it: Dictionary = GameData.item_by_id.get(iid, {})
		_add_row(
			"%s x%d" % [it.get("name_th", iid), int(GameState.inventory[iid])],
			str(it.get("description_th", "")),
			"มอบชิ้นนี้",
			func(): visible = false; gift_chosen.emit(npc_id, iid)
		)

# --- 7. QUESTS, CHRONICLES, LANDMARKS, MUSEUM, RUINS B1-B4, CALENDAR, ACHIEVEMENTS & THEATER ---
func open_quests_and_town_modal(tab: String = "quests") -> void:
	_clear()
	title_lbl.text = "ศูนย์กลางหุบเขา: เควสต์ • พงศาวดาร • บูรณะเมือง • บอส B4 • เทศกาล • โรงละครคัตซีน"
	var all_tabs := [
		["quests", "เควสต์ (10)"],
		["story", "พงศาวดาร (15)"],
		["landmarks", "บูรณะเมือง (5)"],
		["museum", "พิพิธภัณฑ์ (12)"],
		["ruins", "ดันเจี้ยน & บอส B4"],
		["calendar", "📅 ปฏิทิน/เทศกาล"],
		["achieve", "🏆 รางวัล (26)"],
		["theater", "🎬 โรงละครคัตซีน (75)"]
	]
	for t in all_tabs:
		var b := Button.new(); b.text = t[1]; b.pressed.connect(func(): open_quests_and_town_modal(t[0])); tabs_flow.add_child(b)

	if tab == "quests":
		for q in GameData.quests:
			var qid := str(q["id"])
			var st := str(GameState.quests_state.get(qid, "open"))
			var prog := GameState.get_quest_progress(q)
			var can_submit := bool(prog["done"])
			_add_row(
				"%s [%s] — %s" % [q["title"], st, str(prog["text"])],
				"%s • รางวัล: %d G" % [q["desc"], int(q.get("reward", {}).get("gold", 150))],
				"สำเร็จแล้ว" if st == "completed" else ("ส่งเควสต์!" if st == "accepted" else "รับเควสต์"),
				func():
					if st == "open":
						GameState.quests_state[qid] = "accepted"
						AudioManager.play_sfx("talk")
					elif st == "accepted":
						visible = false
						GameState.complete_quest(q)
						return
					open_quests_and_town_modal("quests"),
				st == "open" or (st == "accepted" and can_submit)
			)
	elif tab == "story":
		for ch in GameData.chapters:
			var chid := str(ch["id"])
			var done := GameState.chronicles_done.has(chid)
			var unlocked := done or GameState.is_chapter_unlocked(ch)
			_add_row(
				"%s %s" % [ch["title_th"], "[ผ่านแล้ว]" if done else ("" if unlocked else "🔒")],
				"%s • เงื่อนไข: %s" % [str(ch.get("subtitle_th", "")), str(ch.get("unlock_hint_th", ""))],
				"ชมซ้ำ" if done else ("เล่นคัตซีน!" if unlocked else "ยังไม่ปลดล็อก"),
				func(): visible = false; play_chapter_requested.emit(ch),
				unlocked
			)
	elif tab == "landmarks":
		for lm in GameData.landmarks:
			var lmid := str(lm["id"])
			var built := GameState.landmarks_built.has(lmid)
			var chk := GameState.can_build_landmark(lm)
			_add_row(
				"%s %s" % [lm["name_th"], "[สร้างแล้ว]" if built else ""],
				"%s\nต้องการ: %s" % [lm["summary_th"], str(chk["req_text"])],
				"สร้างแล้ว" if built else "บูรณะ & ชมคัตซีน!",
				func():
					visible = false
					if not GameState.build_landmark(lmid):
						open_quests_and_town_modal("landmarks"),
				(not built) and bool(chk["ok"])
			)
	elif tab == "museum":
		var cnt := GameState.museum_donated.size()
		_add_row(
			"🏛️ ความคืบหน้าพิพิธภัณฑ์: บริจาคแล้ว %d / 12 ชิ้น %s" % [cnt, "(โบนัสขายของ +20% ทำงาน!)" if GameState.sell_bonus_pct > 0 else ""],
			"รางวัลสะสมครบ 3 / 6 / 9 / 12 ชิ้น รับทองคำ สเตตัส หัวใจชาวเมือง และโบนัสขายสินค้าแพงขึ้น +20% ถาวร!"
		)
		for m in GameData.museum_collection:
			var iid := str(m["item_id"])
			var done := GameState.museum_donated.has(iid)
			var have := int(GameState.inventory.get(iid, 0))
			_add_row(
				"%s %s" % [GameData.item_by_id.get(iid, {}).get("name_th", iid), "[จัดแสดงแล้ว]" if done else ("(มี %d)" % have)],
				str(m["lore_th"]),
				"บริจาคแล้ว" if done else "บริจาค (+60G)",
				func():
					visible = false
					if GameState.donate_museum_item(iid) and GameState.museum_donated.size() < 12:
						open_quests_and_town_modal("museum"),
				(not done) and have > 0
			)
	elif tab == "ruins":
		_add_row(
			"🔦 โบราณสถานใต้รากไม้โลก ชั้น B1–B4 & ศึกชำระล้างบอสผู้พิทักษ์!",
			"กด [E] หมุนเสาปริซึมสะท้อนแสงเปิดผนึก • กด [F] ปล่อยคลื่นแสงศักดิ์สิทธิ์ชำระล้างภูตหมอกเงามืดและบอสชั้น B4!",
			"วาร์ปเข้าชั้น B1!",
			func(): visible = false; enter_ruins_requested.emit()
		)
		for fid in ["ruins_b1", "ruins_b2", "ruins_b3", "ruins_b4"]:
			var fl: Dictionary = GameData.RUINS_FLOORS[fid]
			var rs: Dictionary = GameState.ruins_state[fid]
			var extra := (" • บอสผู้พิทักษ์: %s" % ("ชำระล้างสำเร็จ! 👑" if GameState.boss_purified else ("HP %d/%d" % [GameState.boss_hp, GameState.boss_max_hp]))) if fid == "ruins_b4" else ""
			_add_row(
				str(fl["name_th"]),
				"เสาแสง: %s • หีบสมบัติ: %s%s" % ["ปลดผนึกแล้ว!" if bool(rs["solved"]) else "รอการไขปริศนา", "เปิดแล้ว" if bool(rs["chest_opened"]) else ("+%dG" % int(fl["chest"]["gold"])), extra]
			)
	elif tab == "calendar":
		var dos := GameState.get_day_of_season()
		if GameData.FESTIVALS.has(dos):
			var fest: Dictionary = GameData.FESTIVALS[dos]
			var joined := (GameState.festival_joined_day == GameState.day)
			_add_row(
				"🎉 วันนี้มีเทศกาลประจำฤดู: %s!" % str(fest["name_th"]),
				str(fest["desc_th"]),
				"ร่วมงานแล้ว" if joined else "🎬 เข้าร่วมเทศกาล!",
				func():
					visible = false
					GameState.join_today_festival(),
				not joined
			)
		for dkey in [7, 14, 21, 28]:
			var f: Dictionary = GameData.FESTIVALS[dkey]
			_add_row("วันที่ %d ของทุกฤดู — %s" % [dkey, str(f["name_th"])], str(f["desc_th"]))
		for c in GameData.characters:
			var cid := str(c["id"])
			var bd2: Dictionary = GameData.NPC_BIRTHDAYS.get(cid, {"season": 0, "day": 1})
			var is_today := GameData.is_npc_birthday(cid, GameState.get_season_index(), dos)
			_add_row(
				"🎂 วันที่ %d %s — วันเกิดของ %s %s" % [int(bd2["day"]), GameState.SEASONS[int(bd2["season"])], c["name_th"], "[วันนี้!!]" if is_today else ""],
				"มอบของขวัญในวันเกิดรับแต้มหัวใจ x2 เท่า!"
			)
	elif tab == "achieve":
		_add_row("🏆 ความสำเร็จที่ปลดล็อกแล้ว: %d / %d รายการ" % [GameState.achievements_unlocked.size(), GameData.ACHIEVEMENTS.size()], "ทำกิจกรรมในหุบเขาเพื่อสะสมถ้วยรางวัลเกียรติยศให้ครบ 100%!")
		for a in GameData.ACHIEVEMENTS:
			var aid := str(a["id"])
			var unl := GameState.achievements_unlocked.has(aid)
			var prog_txt := GameState.get_achievement_progress(aid)
			_add_row(
				"%s %s %s" % ["🏆" if unl else "⬜", str(a["title_th"]), prog_txt],
				str(a["desc_th"])
			)
	elif tab == "theater":
		var total_cs := GameData.cutscenes_v7.size() + GameData.heart_events.size() + GameData.chapters.size()
		_add_row(
			"🎬 โรงละครคัตซีนเอเธลการ์ด (ปลดล็อกแล้ว %d / %d ฉาก)" % [GameState.watched_cutscenes.size(), total_cs],
			"เฉพาะฉากที่เล่นผ่านและปลดล็อกแล้วเท่านั้นจึงจะรับชมซ้ำ (Replay Mode) ได้ — ป้องกันสปอยล์เนื้อเรื่อง!"
		)
		for csid in GameData.cutscenes_v7.keys():
			var cs: Dictionary = GameData.cutscenes_v7[csid]
			var seen := GameState.watched_cutscenes.has(str(csid))
			_add_row(
				"🎬 [ฉากเมือง/เหตุการณ์] %s %s" % [GameState.format_text(str(cs["title_th"])), "✓" if seen else "🔒"],
				GameState.format_text(str(cs.get("subtitle_th", ""))) if seen else "เล่นเนื้อเรื่องหรือเข้าฉากนี้ในเกมเพื่อปลดล็อกคัตซีน!",
				"ชมซ้ำ" if seen else "ยังไม่ปลดล็อก",
				func(): visible = false; replay_cutscene_requested.emit(cs, "cutscene"),
				seen
			)
		for hev in GameData.heart_events:
			var hid := str(hev["id"])
			var seen2 := GameState.played_events.has(hid) or GameState.watched_cutscenes.has(hid)
			var npc_n := str(GameData.char_by_id.get(str(hev["character_id"]), {}).get("name_th", ""))
			_add_row(
				"💖 [อีเวนต์หัวใจ %d❤️ %s] %s %s" % [int(hev["hearts_required"]), npc_n, str(hev["title_th"]) if seen2 else "???", "✓" if seen2 else "🔒"],
				str(hev.get("subtitle_th", "")) if seen2 else "สานสัมพันธ์กับ %s ให้ถึง %d หัวใจเพื่อปลดล็อก!" % [npc_n, int(hev["hearts_required"])],
				"ชมซ้ำ" if seen2 else "ยังไม่ปลดล็อก",
				func(): visible = false; replay_cutscene_requested.emit(hev, "heart_event"),
				seen2
			)
		for ch2 in GameData.chapters:
			var chid2 := str(ch2["id"])
			var seen3 := GameState.chronicles_done.has(chid2) or GameState.watched_cutscenes.has(chid2)
			_add_row(
				"📜 [พงศาวดาร] %s %s" % [str(ch2["title_th"]), "✓" if seen3 else "🔒"],
				str(ch2.get("subtitle_th", "")) if seen3 else str(ch2.get("unlock_hint_th", "ผ่านเงื่อนไขพงศาวดารเพื่อปลดล็อก")),
				"ชมซ้ำ" if seen3 else "ยังไม่ปลดล็อก",
				func(): visible = false; replay_cutscene_requested.emit(ch2, "chronicle"),
				seen3
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
