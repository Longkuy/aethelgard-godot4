extends Node2D
## Main Game Orchestrator for Aethelgard: Echoes of the World Tree (Godot 4 Complete v7.0 Edition)

const TILE := 32.0

var world: ValleyWorld
var cam: Camera2D
var day_night_mod: CanvasModulate
var ui_layer: CanvasLayer

var title_overlay: ColorRect
var title_slot_box: HBoxContainer
var day_summary_overlay: ColorRect
var summary_lbl: Label

var zone_lbl: Label
var bgm_lbl: Label
var clock_lbl: Label
var gold_lbl: Label
var stats_lbl: Label
var prompt_panel: PanelContainer
var prompt_lbl: Label
var toast_panel: PanelContainer
var toast_lbl: Label
var home_edit_bar: PanelContainer

var dlg_panel: DialoguePanel
var mg_modal: MiniGameModal
var wm_modal: WorldMapModal
var uni_modal: UniversalModal
var cutscene_dir: CutsceneDirector

var _toast_timer: float = 0.0
var _bgm_check_t: float = 0.0
var _lantern_step_acc: float = 0.0

func _ready() -> void:
	world = ValleyWorld.new()
	add_child(world)

	day_night_mod = CanvasModulate.new()
	add_child(day_night_mod)

	cam = Camera2D.new()
	cam.enabled = true
	add_child(cam)

	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	_build_hud_and_modals()

	GameState.hud_updated.connect(_refresh_hud)
	GameState.toast_requested.connect(show_toast)
	GameState.cutscene_requested.connect(func(cs_id: String):
		if cutscene_dir and not cutscene_dir.is_playing:
			cutscene_dir.play_cutscene_by_id(cs_id, world, true)
	)
	_refresh_hud()
	_refresh_title_slots()

func _build_hud_and_modals() -> void:
	# Top-Left HUD
	var tl := PanelContainer.new()
	tl.position = Vector2(12, 12)
	tl.custom_minimum_size = Vector2(288, 0)
	var tl_vb := VBoxContainer.new()
	tl.add_child(tl_vb)
	bgm_lbl = Label.new(); bgm_lbl.add_theme_font_size_override("font_size", 12)
	bgm_lbl.add_theme_color_override("font_color", Color("#9a3412"))
	zone_lbl = Label.new(); zone_lbl.add_theme_font_size_override("font_size", 15)
	tl_vb.add_child(bgm_lbl); tl_vb.add_child(zone_lbl)

	var tl_btns := HFlowContainer.new()
	tl_btns.add_theme_constant_override("h_separation", 4)
	var b_map := Button.new(); b_map.text = "แผนที่ [M]"; b_map.pressed.connect(func(): wm_modal.open_map(world))
	var b_story := Button.new(); b_story.text = "พงศาวดาร"; b_story.pressed.connect(func(): uni_modal.open_quests_and_town_modal("story"))
	var b_thtr := Button.new(); b_thtr.text = "🎬 คัตซีน (75)"; b_thtr.pressed.connect(func(): uni_modal.open_quests_and_town_modal("theater"))
	var b_cal := Button.new(); b_cal.text = "📅 ปฏิทิน/รางวัล"; b_cal.pressed.connect(func(): uni_modal.open_quests_and_town_modal("calendar"))
	tl_btns.add_child(b_map); tl_btns.add_child(b_story); tl_btns.add_child(b_thtr); tl_btns.add_child(b_cal)
	tl_vb.add_child(tl_btns)
	ui_layer.add_child(tl)

	# Top-Right HUD
	var tr := PanelContainer.new()
	tr.position = Vector2(952, 12)
	tr.custom_minimum_size = Vector2(316, 0)
	var tr_vb := VBoxContainer.new()
	tr.add_child(tr_vb)
	clock_lbl = Label.new()
	gold_lbl = Label.new()
	stats_lbl = Label.new(); stats_lbl.add_theme_font_size_override("font_size", 12)
	tr_vb.add_child(clock_lbl); tr_vb.add_child(gold_lbl); tr_vb.add_child(stats_lbl)

	var tr_grid := GridContainer.new(); tr_grid.columns = 3
	var b_skip := Button.new(); b_skip.text = "+2 ชม."; b_skip.pressed.connect(func(): _advance_hours(2.0))
	var b_wea := Button.new(); b_wea.text = "อากาศ"; b_wea.pressed.connect(func():
		GameState.weather = "rainy" if GameState.weather == "sunny" else "sunny"
		world.sync_npc_schedules()
		show_toast("เปลี่ยนสภาพอากาศเป็น: %s" % GameState.weather)
	)
	var b_cust := Button.new(); b_cust.text = "👒 แต่งตัว/ชุด"; b_cust.pressed.connect(func(): uni_modal.open_protagonist_creator("hero"))
	var b_aud := Button.new(); b_aud.text = "เสียง BGM"; b_aud.pressed.connect(func():
		AudioManager.audio_enabled = not AudioManager.audio_enabled
		show_toast("เสียงเพลง BGM: %s" % ("เปิด" if AudioManager.audio_enabled else "ปิด"))
	)
	var b_save := Button.new(); b_save.text = "เซฟ 3 ช่อง"; b_save.pressed.connect(func(): uni_modal.open_save_slots_modal())
	var b_ruins := Button.new(); b_ruins.text = "บอส/ดันเจี้ยน"; b_ruins.pressed.connect(func(): _change_scene("ruins_b1", Vector2i(10, 11), true))
	for b in [b_skip, b_wea, b_cust, b_aud, b_save, b_ruins]:
		tr_grid.add_child(b)
	tr_vb.add_child(tr_grid)
	ui_layer.add_child(tr)

	# Home Grid Edit Bar ([H])
	home_edit_bar = PanelContainer.new()
	home_edit_bar.position = Vector2(308, 12)
	home_edit_bar.visible = false
	var heb_hb := HBoxContainer.new()
	home_edit_bar.add_child(heb_hb)
	var heb_lbl := Label.new(); heb_lbl.text = "โหมดวางเฟอร์นิเจอร์บนตาราง [H]: คลิกซ้ายวาง • คลิกขวาเก็บ • [R] หมุน"
	var b_rot := Button.new(); b_rot.text = "หมุน [R]"; b_rot.pressed.connect(func(): GameState.selected_decor_rot = (GameState.selected_decor_rot + 1) % 2)
	var b_cat := Button.new(); b_cat.text = "เลือกของ/ชั้น 2"; b_cat.pressed.connect(func(): uni_modal.open_shop_modal("decor"))
	var b_end := Button.new(); b_end.text = "เสร็จ [H]"; b_end.pressed.connect(func(): GameState.home_edit_mode = false; home_edit_bar.visible = false)
	heb_hb.add_child(heb_lbl); heb_hb.add_child(b_rot); heb_hb.add_child(b_cat); heb_hb.add_child(b_end)
	ui_layer.add_child(home_edit_bar)

	# Bottom Hotbar (1..9 + [F] Sacred Light!)
	var hb_panel := PanelContainer.new()
	hb_panel.position = Vector2(145, 654)
	var hb_row := HBoxContainer.new()
	hb_row.add_theme_constant_override("separation", 5)
	hb_panel.add_child(hb_row)
	var bar_defs := [
		["1.งานเสริม", func(): uni_modal.open_jobs_modal()],
		["2.ร้าน/ตลาดมืด", func(): uni_modal.open_shop_modal("decor" if GameState.current_scene.begins_with("farmhouse") else "bag")],
		["3.คราฟต์", func(): uni_modal.open_craft_modal()],
		["4.ครอบครัว/คู่รัก", func(): uni_modal.open_relationships_modal()],
		["5.เควสต์/เมือง", func(): uni_modal.open_quests_and_town_modal("quests")],
		["6.จดหมาย", func(): uni_modal.open_mailbox_modal()],
		["7.สัตว์เลี้ยง [P]", _pet_companion],
		["8.แสงชำระ [F]", func(): world.trigger_sacred_pulse()],
		["9.ตะเกียง [9]", _toggle_lantern]
	]
	for bd in bar_defs:
		var b := Button.new(); b.text = bd[0]; b.pressed.connect(bd[1])
		hb_row.add_child(b)
	ui_layer.add_child(hb_panel)

	# Context Prompt & Toast
	prompt_panel = PanelContainer.new()
	prompt_panel.position = Vector2(430, 602)
	prompt_panel.visible = false
	prompt_lbl = Label.new()
	prompt_panel.add_child(prompt_lbl)
	ui_layer.add_child(prompt_panel)

	toast_panel = PanelContainer.new()
	toast_panel.position = Vector2(340, 16)
	toast_panel.visible = false
	toast_lbl = Label.new()
	toast_panel.add_child(toast_lbl)
	ui_layer.add_child(toast_panel)

	# Center Modals
	dlg_panel = DialoguePanel.new()
	dlg_panel.position = Vector2(200, 442)
	dlg_panel.job_requested.connect(_start_job)
	dlg_panel.gift_picker_requested.connect(func(cid: String): uni_modal.open_gift_picker(cid))
	dlg_panel.heart_event_cutscene_requested.connect(func(ev: Dictionary):
		cutscene_dir.play_cutscene_dict(ev, "heart_event", world, true)
	)
	dlg_panel.confession_cutscene_requested.connect(_play_confession_cutscene)
	dlg_panel.wedding_cutscene_requested.connect(_play_wedding_cutscene)
	ui_layer.add_child(dlg_panel)

	mg_modal = MiniGameModal.new()
	mg_modal.position = Vector2(360, 140)
	mg_modal.minigame_finished.connect(_on_minigame_finished)
	ui_layer.add_child(mg_modal)

	wm_modal = WorldMapModal.new()
	wm_modal.position = Vector2(200, 75)
	wm_modal.warp_requested.connect(func(sc: String, t: Vector2i, lbl: String):
		_change_scene(sc, t, sc != "outdoor")
		show_toast("เดินทางไปยัง %s!" % lbl)
	)
	ui_layer.add_child(wm_modal)

	# Day Summary Overlay
	day_summary_overlay = ColorRect.new()
	day_summary_overlay.color = Color(0.05, 0.07, 0.14, 0.92)
	day_summary_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	day_summary_overlay.visible = false
	var sum_card := PanelContainer.new()
	sum_card.position = Vector2(380, 200)
	sum_card.custom_minimum_size = Vector2(520, 280)
	var sum_vb := VBoxContainer.new()
	sum_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	sum_card.add_child(sum_vb)
	summary_lbl = Label.new(); summary_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var b_next_day := Button.new(); b_next_day.text = "ตื่นรับเช้าวันใหม่!"
	b_next_day.pressed.connect(func():
		day_summary_overlay.visible = false
		GameState.start_next_morning()
		world.sync_npc_schedules()
	)
	sum_vb.add_child(summary_lbl); sum_vb.add_child(b_next_day)
	day_summary_overlay.add_child(sum_card)
	ui_layer.add_child(day_summary_overlay)

	# Title Screen Overlay (3 Save Slots + 8-Race Customizer!)
	title_overlay = ColorRect.new()
	title_overlay.color = Color(0.06, 0.12, 0.09, 0.94)
	title_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var t_card := PanelContainer.new()
	t_card.position = Vector2(230, 88)
	t_card.custom_minimum_size = Vector2(820, 524)
	var t_vb := VBoxContainer.new()
	t_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	t_vb.add_theme_constant_override("separation", 12)
	t_card.add_child(t_vb)

	var t_head := Label.new()
	t_head.text = "AETHELGARD: ECHOES OF THE WORLD TREE\nGodot 4 Complete Edition (v7.0 — 284 Sprites • All Systems • 75 Cutscenes)"
	t_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_head.add_theme_font_size_override("font_size", 22)
	t_vb.add_child(t_head)

	var t_sub := Label.new()
	t_sub.text = "แต่งตัวเอก 8 เผ่า + หมวก/ปีก/ชุดพิเศษ • 6 มินิเกม • แต่งงาน & เลี้ยงลูก 3 วัย • แต่งบ้านตาราง & ชั้น 2 • ดันเจี้ยนเสาแสง & บอส B4 • เทศกาล & โรงละครคัตซีน 75 ฉาก!"
	t_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t_vb.add_child(t_sub)

	title_slot_box = HBoxContainer.new()
	title_slot_box.alignment = BoxContainer.ALIGNMENT_CENTER
	title_slot_box.add_theme_constant_override("separation", 10)
	t_vb.add_child(title_slot_box)

	var pet_hb := HBoxContainer.new(); pet_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	for pk in [["cat", "โมจิ (แมวส้ม)"], ["dog", "โคริ (ชิบะป่า)"], ["fairy", "ลูมิ (ภูตแสง)"]]:
		var pb := Button.new(); pb.text = "สัตว์เลี้ยง: " + pk[1]
		pb.pressed.connect(func(): GameState.pet_kind = pk[0]; world.pet_actor.refresh_pet(); show_toast("เลือกคู่หู: " + pk[1]))
		pet_hb.add_child(pb)
	t_vb.add_child(pet_hb)

	var start_hb := HBoxContainer.new(); start_hb.alignment = BoxContainer.ALIGNMENT_CENTER; start_hb.add_theme_constant_override("separation", 12)
	var b_cr := Button.new(); b_cr.text = "👒 แต่งตัวเอก 8 เผ่า & ตู้เสื้อผ้า"; b_cr.pressed.connect(func(): uni_modal.open_protagonist_creator("hero"))
	var b_play := Button.new(); b_play.text = "🎬 เข้าสู่เอเธลการ์ด (เริ่มเล่น!)"
	b_play.pressed.connect(func():
		GameState.started = true
		title_overlay.visible = false
		world.player_actor.refresh_appearance()
		world.sync_npc_schedules()
		GameState.save_slot(GameState.active_slot, true)
		_sync_bgm_zone()
		if not GameState.watched_cutscenes.has("cs_opening_arrival"):
			cutscene_dir.play_cutscene_by_id("cs_opening_arrival", world, false)
		else:
			show_toast("ยินดีต้อนรับ %s สู่ %s! (ช่องเซฟ %d)" % [GameState.player_name, GameState.cottage_name, GameState.active_slot])
	)
	start_hb.add_child(b_cr); start_hb.add_child(b_play)
	t_vb.add_child(start_hb)
	title_overlay.add_child(t_card)
	ui_layer.add_child(title_overlay)

	uni_modal = UniversalModal.new()
	uni_modal.position = Vector2(200, 70)
	uni_modal.start_job_requested.connect(_start_job)
	uni_modal.play_chapter_requested.connect(func(ch: Dictionary): cutscene_dir.play_cutscene_dict(ch, "chronicle", world, true))
	uni_modal.replay_cutscene_requested.connect(func(cs_d: Dictionary, mode: String): cutscene_dir.play_cutscene_dict(cs_d, mode, world, true))
	uni_modal.gift_chosen.connect(func(cid: String, iid: String): dlg_panel.show_gift_reaction(cid, iid))
	uni_modal.hero_customized.connect(func():
		world.player_actor.refresh_appearance()
		for a in world.npc_actors.values(): a.refresh_appearance()
		if world.child_actor: world.child_actor.refresh_child()
		_refresh_hud()
		_refresh_title_slots()
	)
	uni_modal.enter_ruins_requested.connect(func(): _change_scene("ruins_b1", Vector2i(10, 11), true))
	ui_layer.add_child(uni_modal)

	cutscene_dir = CutsceneDirector.new()
	cutscene_dir.cutscene_finished.connect(func(_id: String):
		_sync_bgm_zone()
		_refresh_hud()
	)
	ui_layer.add_child(cutscene_dir)

func _play_confession_cutscene(cid: String) -> void:
	var cname := str(GameData.char_by_id.get(cid, {}).get("name_th", cid))
	var cs := {
		"id": "cs_confession",
		"title_th": "คำสารภาพรักใต้สายลมต้นไม้โลก",
		"subtitle_th": "{player} & " + cname + " ตกลงคบหาดูใจกันอย่างเป็นทางการ",
		"stage_scene": GameState.current_scene,
		"bgm_zone": "wedding",
		"cast": [cid, "03_lilian"],
		"beats": [
			{"speaker": cid, "emotion": "blush", "emote": "💖", "text": "{player}... ขอบคุณที่พูดความรู้สึกในใจออกมานะ ฉันเองก็หลงรักเธอมาตลอดเหมือนกัน!"},
			{"speaker": "03_lilian", "emotion": "happy", "emote": "🌸", "text": "ยินดีด้วยนะจ๊ะทั้งสองคน! เมื่อความผูกพันเต็ม 10 หัวใจ อย่าลืมนำ 'แหวนสายใยรากไม้โลก' มาจัดพิธีวิวาห์นะจ๊ะ!"}
		]
	}
	cutscene_dir.play_cutscene_dict(cs, "cutscene", world, false)

func _play_wedding_cutscene(cid: String) -> void:
	var cname := str(GameData.char_by_id.get(cid, {}).get("name_th", cid))
	var cs := {
		"id": "cs_wedding",
		"title_th": "พิธีวิวาห์ศักดิ์สิทธิ์ใต้ต้นไม้โลก",
		"subtitle_th": "งานแต่งงานของ {player} & " + cname,
		"stage_scene": "outdoor",
		"focus_tile": [42, 29],
		"bgm_zone": "wedding",
		"cast": [cid, "16_bram", "09_celeste", "03_lilian"],
		"beats": [
			{"speaker": "16_bram", "emotion": "happy", "emote": "🔔", "text": "ฮ่าๆๆ! วันนี้ชาวเมืองทั้งแปดเผ่ามารวมตัวกันอวยพรพิธีวิวาห์อันแสนอบอุ่นของ {player} และ " + cname + " ใต้ต้นไม้โลกสีทอง!"},
			{"speaker": "09_celeste", "emotion": "happy", "emote": "🎻", "text": "ขอให้ท่วงทำนองไวโอลินและแสงอรุณแห่งรากไม้โลกคุ้มครองคู่บ่าวสาวให้ครองรักกันชั่วนิรันดร์ค่ะ!"},
			{"speaker": cid, "emotion": "blush", "emote": "💍", "text": "ขอบคุณที่สวมแหวนวงนี้ให้ฉันนะ {player}... จากนี้ไปเรามาสร้างครอบครัวที่อบอุ่นด้วยกันที่ {farm} ตลอดไปเลยนะ! (+500G & ปลดล็อกชุดวิวาห์!)"}
		]
	}
	cutscene_dir.play_cutscene_dict(cs, "cutscene", world, true)

func _toggle_lantern() -> void:
	GameState.night_lantern_on = not GameState.night_lantern_on
	AudioManager.play_sfx("sparkle")
	show_toast("🏮 ตะเกียงส่องทาง: %s" % ("เปิดสว่าง" if GameState.night_lantern_on else "ปิด"))

func _refresh_title_slots() -> void:
	if not title_slot_box: return
	for c in title_slot_box.get_children(): c.queue_free()
	for n in [1, 2, 3]:
		var d := GameState.read_slot_summary(n)
		var b := Button.new()
		b.custom_minimum_size = Vector2(225, 76)
		var sel := " [เลือกอยู่]" if GameState.active_slot == n else ""
		b.text = ("ช่องเซฟ %d%s\nว่าง — เริ่มเกมใหม่" % [n, sel]) if d.is_empty() else ("ช่องเซฟ %d%s: %s\nวันที่ %d • %d G" % [n, sel, d.get("player_name", "อาริน"), int(d.get("day", 1)), int(d.get("gold", 0))])
		b.pressed.connect(func():
			GameState.load_slot(n, false)
			world.player_actor.refresh_appearance()
			_refresh_title_slots()
		)
		title_slot_box.add_child(b)

func show_toast(msg: String) -> void:
	toast_lbl.text = msg
	toast_panel.visible = true
	_toast_timer = 3.2

func _refresh_hud() -> void:
	var hh := int(GameState.time_min) / 60
	var mm := int(GameState.time_min) % 60
	var fest_tag := " 🎉เทศกาล!" if GameData.FESTIVALS.has(GameState.get_day_of_season()) else ""
	clock_lbl.text = "%s วันที่ %d %s%s • %02d:%02d (%s)" % [GameState.get_weekday_name(), GameState.get_day_of_season(), GameState.get_season_name(), fest_tag, hh, mm, GameState.weather]
	gold_lbl.text = "ทอง: %d G  |  พลังงาน: %d/%d  |  %s" % [GameState.gold, GameState.stamina, GameState.get_max_stamina(), GameState.player_name]
	stats_lbl.text = "เสน่ห์ Lv.%d | ฝีมือ Lv.%d | ปัญญา Lv.%d | ความกล้า Lv.%d" % [
		GameState.get_stat_level("charm"), GameState.get_stat_level("craft"),
		GameState.get_stat_level("wisdom"), GameState.get_stat_level("courage")
	]
	bgm_lbl.text = "BGM: " + AudioManager.get_current_bgm_title()
	zone_lbl.text = _get_zone_title()

func _get_zone_title() -> String:
	var sc := GameState.current_scene
	if sc == "outdoor":
		var t := world.player_actor.position / TILE
		if t.x < 26 and t.y < 28: return GameState.cottage_name
		if t.x > 62: return "ย่านช่างเหล็กศิลาเพลิง"
		if t.x > 50 and t.y < 34: return "ย่านตลาด & โรงเตี๊ยม"
		if t.y > 45: return "ทะเลสาบมุกศักดิ์สิทธิ์"
		return "จัตุรัสต้นไม้โลก"
	if GameData.RUINS_FLOORS.has(sc):
		return str(GameData.RUINS_FLOORS[sc]["name_th"])
	return str(ValleyWorld.INDOORS.get(sc, {}).get("name_th", sc))

func _sync_bgm_zone() -> void:
	var sc := GameState.current_scene
	var z := "plaza"
	if sc.begins_with("ruins_"): z = "ruins"
	elif sc.begins_with("farmhouse"): z = "home"
	elif sc in ["tavern", "bakery", "shop"]: z = "tavern"
	elif sc == "smithy": z = "smithy"
	elif sc == "cottage": z = "nature"
	else:
		var t := world.player_actor.position / TILE
		if t.x < 26 and t.y < 26: z = "home"
		elif t.x > 62 and t.y < 36: z = "smithy"
		elif t.x > 50 and t.y < 34: z = "tavern"
		elif t.y > 43: z = "nature"
	AudioManager.set_zone(z)
	if bgm_lbl:
		bgm_lbl.text = "BGM: " + AudioManager.get_current_bgm_title()

func _change_scene(scene_id: String, spawn_tile: Vector2i, save_return: bool = false) -> void:
	if save_return and GameState.current_scene == "outdoor":
		GameState.return_outdoor_pos = world.player_actor.position + Vector2(0, 18)
	GameState.home_edit_mode = false
	home_edit_bar.visible = false
	world.clear_click_move()
	GameState.current_scene = scene_id
	world.player_actor.position = (Vector2(spawn_tile) + Vector2(0.5, 0.5)) * TILE
	world.pet_actor.position = world.player_actor.position + Vector2(-20, 8)
	if scene_id == "tavern" and GameState.time_min >= 19.0 * 60.0:
		GameState.visited_tavern_night = true
	world.sync_npc_schedules()
	AudioManager.play_sfx("door")
	_sync_bgm_zone()
	_refresh_hud()

	var entry_cs_map := {
		"farmhouse": "cs_enter_farmhouse",
		"farmhouse_upstairs": "cs_enter_loft",
		"shop": "cs_enter_shop",
		"bakery": "cs_enter_bakery",
		"tavern": "cs_enter_tavern",
		"smithy": "cs_enter_smithy",
		"cottage": "cs_enter_cottage",
		"ruins_b1": "cs_enter_ruins_b1",
		"ruins_b2": "cs_enter_ruins_b2",
		"ruins_b3": "cs_enter_ruins_b3",
		"ruins_b4": "cs_enter_ruins_b4"
	}
	if entry_cs_map.has(scene_id):
		var csid := str(entry_cs_map[scene_id])
		if not GameState.watched_cutscenes.has(csid) and GameData.cutscenes_v7.has(csid):
			cutscene_dir.play_cutscene_by_id(csid, world, false)

func _advance_hours(hrs: float) -> void:
	GameState.time_min += hrs * 60.0
	if GameState.time_min >= 24.0 * 60.0:
		_open_day_summary()
	else:
		world.sync_npc_schedules()
		_refresh_hud()

func _open_day_summary() -> void:
	dlg_panel.close_panel()
	uni_modal.visible = false
	wm_modal.visible = false
	summary_lbl.text = "สรุปผลจบวันที่ %d (%s)\n\nรายได้วันนี้: +%d G\nแต้มหัวใจที่เพิ่ม: +%d\nXP สเตตัสชีวิต: +%d\nไอเทมที่ได้รับ: %d ชิ้น" % [
		GameState.get_day_of_season(), GameState.get_season_name(),
		int(GameState.daily_log["gold"]), int(GameState.daily_log["hearts"]),
		int(GameState.daily_log["stats"]), int(GameState.daily_log["items"])
	]
	day_summary_overlay.visible = true

func _pet_companion() -> void:
	AudioManager.play_sfx("heart")
	if not GameState.pet_petted_today:
		GameState.pet_petted_today = true
		GameState.stamina = mini(GameState.get_max_stamina(), GameState.stamina + 10)
		GameState.add_stat_xp({"charm": 5})
		show_toast("ลูบหัวคู่หูสัตว์เลี้ยง! ฟื้นพลังงาน +10 & เสน่ห์ +5")
	else:
		show_toast("คู่หูสัตว์เลี้ยงดูมีความสุขมาก!")

func _start_job(job: Dictionary) -> void:
	var cost := GameState.get_stamina_cost(int(job["energy_cost"]))
	if GameState.stamina < cost:
		show_toast("พลังงานไม่พอสำหรับงานนี้! (ต้องการ %d)" % cost)
		return
	mg_modal.start_minigame(MiniGameModal.get_job_minigame_kind(str(job["id"])), "job", job)

func _on_minigame_finished(ctx_mode: String, pl: Variant, sc: int, mx: int) -> void:
	if ctx_mode == "job" and typeof(pl) == TYPE_DICTIONARY:
		var job: Dictionary = pl
		GameState.stamina = maxi(0, GameState.stamina - GameState.get_stamina_cost(int(job["energy_cost"])))
		var ratio := float(sc) / float(maxi(1, mx))
		var rank := "S" if ratio >= 0.8 else ("A" if ratio >= 0.5 else "B")
		var mult := 1.5 if rank == "S" else (1.2 if rank == "A" else 1.0)
		var pay := int(round(float(job["base_pay_gold"]) * mult))
		GameState.add_gold(pay)
		GameState.worked_today[job["id"]] = true
		GameState.total_shifts += 1
		if rank == "S": GameState.s_rank_jobs += 1
		GameState.add_stat_xp(job.get("stat_gains", {}))
		if job.has("bonus_item_id") and (rank == "S" or randf() < 0.4):
			GameState.add_item(str(job["bonus_item_id"]), 1)
		_advance_hours(float(job.get("duration_hours", 2)))
		AudioManager.play_sfx("quest" if rank == "S" else "coin")
		GameState.save_slot(GameState.active_slot, true)
		show_toast("[Rank %s] จบงาน %s! รับ +%d G" % [rank, job["title_th"], pay])
	elif ctx_mode == "fish":
		GameState.stamina = maxi(0, GameState.stamina - GameState.get_stamina_cost(8))
		if sc >= 100:
			var catches := ["item_grilled_salmon", "item_glowing_shell", "item_sea_pearl", "item_aqua_crystal", "item_ancient_tablet"]
			var cid: String = catches[randi() % catches.size()]
			GameState.add_item(cid, 1)
			GameState.fish_caught += 1
			GameState.add_stat_xp({"craft": 5, "wisdom": 3})
			AudioManager.play_sfx("sparkle")
			show_toast("ตกปลาสำเร็จ! ได้รับ '%s'" % GameData.item_by_id.get(cid, {}).get("name_th", cid))
		else:
			show_toast("ปลาหลุดเบ็ดไปซะแล้ว ลองใหม่นะ!")
	elif ctx_mode == "concert":
		for c in GameData.characters:
			GameState.add_friendship(str(c["id"]), 15)
		GameState.stamina = mini(GameState.get_max_stamina(), GameState.stamina + 25)
		GameState.add_stat_xp({"charm": 12})
		AudioManager.play_sfx("concert")
		show_toast("จบมินิคอนเสิร์ต 4 เลน! ชาวเมืองทุกคน +15 แต้มหัวใจ & ฟื้นพลังงาน +25!")

func _is_ui_blocking() -> bool:
	return (not GameState.started) or title_overlay.visible or day_summary_overlay.visible or dlg_panel.visible or mg_modal.visible or wm_modal.visible or uni_modal.visible or (cutscene_dir != null and cutscene_dir.is_playing)

func _find_interaction() -> Dictionary:
	var p := world.player_actor.position
	var sc := GameState.current_scene
	if world.child_actor and world.child_actor.visible and world.child_actor.position.distance_to(p) < 48.0:
		return {"kind": "child", "label": "กด [E] อุ้ม/เล่นกับลูกน้อย '%s'" % str(GameState.child_data.get("name", "ลูมิน่า"))}
	for cid in world.npc_actors.keys():
		var a: CharacterActor = world.npc_actors[cid]
		if a.visible and a.position.distance_to(p) < 52.0:
			return {"kind": "npc", "cid": cid, "label": "กด [E] พูดคุยกับ " + str(GameData.char_by_id[cid]["name_th"])}

	if sc == "outdoor":
		if GameData.FESTIVALS.has(GameState.get_day_of_season()) and GameState.festival_joined_day != GameState.day and p.distance_to(Vector2(42.5 * TILE, 31.0 * TILE)) < 68.0:
			var fdef: Dictionary = GameData.FESTIVALS[GameState.get_day_of_season()]
			return {"kind": "festival", "label": "กด [E] 🎉 เข้าร่วม " + str(fdef["name_th"])}
		if p.distance_to(Vector2(39.5 * TILE, 27.5 * TILE)) < 48.0:
			return {"kind": "enter_ruins", "label": "กด [E] ลงสู่โบราณสถานใต้รากไม้โลก (ชั้น B1–B4)"}
		if p.distance_to(Vector2(20.5 * TILE, 15.5 * TILE)) < 42.0:
			return {"kind": "mail", "label": "กด [E] เปิดตู้จดหมาย"}
		if p.distance_to(Vector2(45.5 * TILE, 29.5 * TILE)) < 44.0:
			return {"kind": "quests", "label": "กด [E] เปิดกระดานเควสต์"}
		if p.distance_to(Vector2(42.5 * TILE, 28.5 * TILE)) < 54.0:
			return {"kind": "story", "label": "กด [E] เปิดพงศาวดาร & โรงละครคัตซีน"}
		for b in ValleyWorld.BUILDINGS:
			var dp := (Vector2(b["door"]) + Vector2(0.5, 0.3)) * TILE
			if p.distance_to(dp) < 40.0:
				return {"kind": "enter_bldg", "id": b["id"], "label": "กด [E] เข้าสู่ " + str(b["name_th"])}
		for lm in GameData.landmarks:
			var lp := Vector2(float(lm["interactX"]) * TILE, float(lm["interactY"]) * TILE)
			if p.distance_to(lp) < 54.0:
				return {"kind": "landmark", "id": lm["id"], "label": "กด [E] " + str(lm["name_th"])}
		for fs in GameState.forage_spots:
			if bool(fs.get("collected", false)): continue
			var fp := Vector2((int(fs["tx"]) + 0.5) * TILE, (int(fs["ty"]) + 0.5) * TILE)
			if p.distance_to(fp) < 38.0:
				return {"kind": "forage", "spot": fs, "label": "กด [E] เก็บของป่าเรืองแสง"}
		if world.is_near_water(p):
			return {"kind": "fish", "label": "กด [E] เหวี่ยงเบ็ดตกปลา Stardew"}

	elif GameData.RUINS_FLOORS.has(sc):
		var fl: Dictionary = GameData.RUINS_FLOORS[sc]
		var rs: Dictionary = GameState.ruins_state[sc]
		if sc == "ruins_b4" and not GameState.boss_purified:
			var bt: Vector2i = fl.get("boss_tile", Vector2i(11, 6))
			var bp := Vector2((bt.x + 0.5) * TILE, (bt.y + 0.5) * TILE)
			if p.distance_to(bp) < 155.0:
				return {"kind": "boss_purify", "label": "กด [F] หรือ [E] ปล่อยคลื่นแสงศักดิ์สิทธิ์ชำระล้างบอสผู้พิทักษ์!"}
		var eu: Dictionary = fl["exit_up"]
		if p.distance_to(Vector2((int(eu["x"]) + 0.5) * TILE, (int(eu["y"]) + 0.5) * TILE)) < 42.0:
			return {"kind": "ruins_up", "to": str(eu["to"]), "label": "กด [E] ขึ้นบันไดกลับ"}
		var sd: Dictionary = fl["stairs_down"]
		if not sd.is_empty() and p.distance_to(Vector2((int(sd["x"]) + 0.5) * TILE, (int(sd["y"]) + 0.5) * TILE)) < 44.0:
			return {"kind": "ruins_down", "to": str(sd["to"]), "solved": bool(rs["solved"]), "label": "กด [E] ลงสู่ชั้นถัดไป" if bool(rs["solved"]) else "ผนึกเสาแสงยังไม่เปิด"}
		var ch: Dictionary = fl["chest"]
		if not bool(rs["chest_opened"]) and p.distance_to(Vector2((int(ch["x"]) + 0.5) * TILE, (int(ch["y"]) + 0.5) * TILE)) < 46.0:
			var can_open := bool(rs["solved"]) and (sc != "ruins_b4" or GameState.boss_purified)
			return {"kind": "ruins_chest", "label": "กด [E] เปิดหีบสมบัติบรรพกาล!" if can_open else "ต้องปลดผนึกเสาแสง/ชำระล้างบอสก่อน"}
		for pi in range(fl["pillars"].size()):
			var pl: Dictionary = fl["pillars"][pi]
			if p.distance_to(Vector2((int(pl["x"]) + 0.5) * TILE, (int(pl["y"]) + 0.5) * TILE)) < 48.0:
				return {"kind": "ruins_pillar", "idx": pi, "label": "กด [E] หมุนเสาปริซึมสะท้อนแสง #%d" % (pi + 1)}
		var mined: Dictionary = rs.get("mined_day", {})
		for oi in range(fl["ores"].size()):
			if int(mined.get(str(oi), -1)) == GameState.day: continue
			var ore: Dictionary = fl["ores"][oi]
			if p.distance_to(Vector2((int(ore["x"]) + 0.5) * TILE, (int(ore["y"]) + 0.5) * TILE)) < 44.0:
				return {"kind": "ruins_ore", "idx": oi, "item_id": str(ore["item_id"]), "label": "กด [E] สกัดแร่มานาโบราณ"}
	else:
		var rm: Dictionary = ValleyWorld.INDOORS.get(sc, ValleyWorld.INDOORS["farmhouse"])
		var ex: Vector2i = rm["exit"]
		if p.distance_to((Vector2(ex) + Vector2(0.5, 0.5)) * TILE) < 40.0:
			return {"kind": "exit_indoor", "label": "กด [E] ลงบันไดกลับชั้น 1" if sc == "farmhouse_upstairs" else "กด [E] ออกไปข้างนอก"}
		if sc == "farmhouse" and GameState.house_level >= 2 and p.distance_to(Vector2(14.0 * TILE, 3.0 * TILE)) < 48.0:
			return {"kind": "stairs_up", "label": "กด [E] ขึ้นสู่ชั้น 2 ห้องใต้หลังคาชมดาว"}
		if sc in ["farmhouse", "farmhouse_upstairs"]:
			if p.distance_to(Vector2(3.0 * TILE, 4.5 * TILE)) < 54.0:
				return {"kind": "sleep", "label": "กด [E] เข้านอน & สรุปผลประจำวัน"}
			if sc == "farmhouse" and p.distance_to(Vector2(6.0 * TILE, 9.0 * TILE)) < 52.0:
				return {"kind": "craft", "label": "กด [E] เปิดโต๊ะคราฟต์ & ตีแหวนแต่งงาน"}
			for pl in GameState.decor_placed:
				if str(pl["scene"]) != sc: continue
				var d := GameState.get_decor_def(str(pl["id"]))
				var act := str(d.get("action", ""))
				if act != "":
					var dc := Vector2((float(pl["x"]) + float(pl["w"]) * 0.5) * TILE, (float(pl["y"]) + float(pl["h"]) * 0.5) * TILE)
					if p.distance_to(dc) < 52.0:
						return {"kind": "decor_act", "act": act, "label": "กด [E] ใช้งาน " + str(d["label"])}
	return {}

func _execute_interaction() -> void:
	var ctx := _find_interaction()
	if ctx.is_empty(): return
	match str(ctx["kind"]):
		"child":
			var cmsg := GameState.interact_with_child()
			if cmsg != "": show_toast(cmsg)
		"festival":
			GameState.join_today_festival()
		"npc": dlg_panel.open_npc_dialogue(str(ctx["cid"]))
		"enter_ruins": _change_scene("ruins_b1", Vector2i(10, 11), true)
		"mail": uni_modal.open_mailbox_modal()
		"quests": uni_modal.open_quests_and_town_modal("quests")
		"story": uni_modal.open_quests_and_town_modal("story")
		"enter_bldg":
			var bid := str(ctx["id"])
			_change_scene(bid, ValleyWorld.INDOORS[bid]["spawn"], true)
		"landmark":
			var lmid := str(ctx["id"])
			if not GameState.landmarks_built.has(lmid):
				uni_modal.open_quests_and_town_modal("landmarks")
			elif lmid == "lm_stage":
				mg_modal.start_minigame("rhythm_stage", "concert", null)
			elif lmid == "lm_museum":
				uni_modal.open_quests_and_town_modal("museum")
			elif lmid == "lm_nightmarket":
				uni_modal.open_shop_modal("nightmarket")
			elif lmid == "lm_observatory":
				GameState.meteor_shower_tonight = true
				GameState.add_stat_xp({"wisdom": 10})
				AudioManager.play_sfx("sparkle")
				show_toast("🔭 ส่องกล้องดูดาวสำเร็จ! (+10 ปัญญา & คืนนี้จะมีฝนดาวตก!)")
			else:
				GameState.stamina = GameState.get_max_stamina()
				AudioManager.play_sfx("sparkle")
				show_toast("♨️ แช่บ่อน้ำพุร้อนรากไม้! ฟื้นพลังงานเต็ม 100%")
		"forage":
			var sp: Dictionary = ctx["spot"]
			sp["collected"] = true
			var qty := 2 if (str(GameState.hero_custom.get("race_key", "")) == "elf" and randf() < 0.35) else 1
			GameState.add_item(str(sp["item_id"]), qty)
			GameState.foraged_count += qty
			world.player_actor.interact_timer = 0.4
			GameState.check_achievements()
			AudioManager.play_sfx("sparkle")
			show_toast("เก็บ '%s' x%d สำเร็จ!" % [GameData.item_by_id.get(str(sp["item_id"]), {}).get("name_th", ""), qty])
		"fish":
			mg_modal.start_minigame("stardew_fish", "fish", null)
		"boss_purify":
			world.trigger_sacred_pulse()
		"ruins_up":
			var target_to := str(ctx["to"])
			if target_to == "outdoor": _change_scene("outdoor", Vector2i(39, 28), false)
			else: _change_scene(target_to, Vector2i(10, 3), false)
		"ruins_down":
			if bool(ctx["solved"]):
				var next_sc := str(ctx["to"])
				var sp_t: Vector2i = GameData.RUINS_FLOORS[next_sc]["spawn"]
				_change_scene(next_sc, sp_t, false)
			else:
				show_toast("หมุนเสาปริซึมให้ลำแสงชนแท่นรับแสงครบก่อน!")
		"ruins_pillar":
			GameState.rotate_ruins_pillar(GameState.current_scene, int(ctx["idx"]))
			GameState.check_achievements()
		"ruins_chest":
			var rs: Dictionary = GameState.ruins_state[GameState.current_scene]
			if not bool(rs["solved"]) or (GameState.current_scene == "ruins_b4" and not GameState.boss_purified):
				show_toast("ต้องไขปริศนาเสาแสงและชำระล้างผู้พิทักษ์ให้สำเร็จก่อน!")
				return
			rs["chest_opened"] = true
			var ch: Dictionary = GameData.RUINS_FLOORS[GameState.current_scene]["chest"]
			GameState.add_gold(int(ch["gold"]))
			for iid in ch["items"].keys():
				GameState.add_item(str(iid), int(ch["items"][iid]))
			AudioManager.play_sfx("quest")
			GameState.check_achievements()
			GameState.save_slot(GameState.active_slot, true)
			show_toast("เปิดหีบสมบัติบรรพกาล! รับ +%d G และไอเทมโบราณ!" % int(ch["gold"]))
		"ruins_ore":
			var rs2: Dictionary = GameState.ruins_state[GameState.current_scene]
			rs2["mined_day"][str(ctx["idx"])] = GameState.day
			var oqty := 2 if str(GameState.hero_custom.get("race_key", "")) == "dwarf" else 1
			GameState.add_item(str(ctx["item_id"]), oqty)
			AudioManager.play_sfx("anvil")
			show_toast("สกัดแร่มานาสำเร็จ x%d!" % oqty)
		"exit_indoor":
			if GameState.current_scene == "farmhouse_upstairs": _change_scene("farmhouse", Vector2i(13, 3), false)
			else: _change_scene("outdoor", Vector2i(int(GameState.return_outdoor_pos.x / TILE), int(GameState.return_outdoor_pos.y / TILE)), false)
		"stairs_up":
			_change_scene("farmhouse_upstairs", Vector2i(11, 7), false)
		"sleep":
			_open_day_summary()
		"craft":
			uni_modal.open_craft_modal()
		"decor_act":
			var act := str(ctx["act"])
			if act == "mirror": uni_modal.open_protagonist_creator("wardrobe")
			elif act == "music": mg_modal.start_minigame("rhythm_stage", "concert", null)
			else:
				GameState.stamina = mini(GameState.get_max_stamina(), GameState.stamina + 12)
				AudioManager.play_sfx("sparkle")
				show_toast("ผ่อนคลายกับเฟอร์นิเจอร์ในบ้าน (+12 พลังงาน!)")

func _unhandled_input(event: InputEvent) -> void:
	if not GameState.started: return
	if cutscene_dir and cutscene_dir.is_playing:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.is_action_pressed("skip_cutscene") or event.physical_keycode == KEY_ESCAPE:
				cutscene_dir.skip_cutscene()
			elif event.is_action_pressed("interact"):
				cutscene_dir.advance_or_reveal()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			if GameState.home_edit_mode: GameState.home_edit_mode = false; home_edit_bar.visible = false
			elif wm_modal.visible: wm_modal.visible = false
			elif uni_modal.visible: uni_modal.visible = false
			elif dlg_panel.visible: dlg_panel.close_panel()
			return
		if event.is_action_pressed("open_map") and not mg_modal.visible:
			if wm_modal.visible: wm_modal.visible = false
			else: wm_modal.open_map(world)
			return
		if event.is_action_pressed("home_edit") and GameState.current_scene in ["farmhouse", "farmhouse_upstairs"]:
			GameState.home_edit_mode = not GameState.home_edit_mode
			home_edit_bar.visible = GameState.home_edit_mode
			return
		if GameState.home_edit_mode and event.is_action_pressed("rotate_decor"):
			GameState.selected_decor_rot = (GameState.selected_decor_rot + 1) % 2
			return
		if _is_ui_blocking():
			return
		if event.is_action_pressed("pet_companion"):
			_pet_companion()
		elif event.is_action_pressed("sacred_pulse"):
			world.trigger_sacred_pulse()
		elif event.is_action_pressed("toggle_lantern"):
			_toggle_lantern()
		elif event.is_action_pressed("interact"):
			_execute_interaction()

	if event is InputEventMouseButton and event.pressed:
		var wpos := get_global_mouse_position()
		if GameState.home_edit_mode:
			var tx := int(floor(wpos.x / TILE))
			var ty := int(floor(wpos.y / TILE))
			if event.button_index == MOUSE_BUTTON_LEFT:
				GameState.place_decor_on_grid(GameState.selected_decor_id, GameState.current_scene, tx, ty, GameState.selected_decor_rot)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				GameState.remove_decor_at_tile(GameState.current_scene, tx, ty)
		elif not _is_ui_blocking() and event.button_index == MOUSE_BUTTON_LEFT:
			var vpos := get_viewport().get_mouse_position()
			if vpos.y > 95.0 and vpos.y < 645.0:
				world.set_click_move_target(wpos)

func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			toast_panel.visible = false

	var mpos := get_global_mouse_position()
	world.hover_tile = Vector2i(int(floor(mpos.x / TILE)), int(floor(mpos.y / TILE)))

	var cs_active := (cutscene_dir != null and cutscene_dir.is_playing)

	if GameState.started and not _is_ui_blocking() and not GameState.home_edit_mode:
		var prev_hr := int(GameState.time_min) / 60
		GameState.time_min += delta * 1.5
		if GameState.time_min >= 24.0 * 60.0:
			_open_day_summary()
		elif int(GameState.time_min) / 60 != prev_hr:
			world.sync_npc_schedules()
			_refresh_hud()

		var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if dir.length() > 0.05:
			world.clear_click_move()
		elif world.has_click_target:
			var to_click := world.click_target - world.player_actor.position
			if to_click.length() < 8.0:
				world.clear_click_move()
			else:
				dir = to_click.normalized()

		var moving := dir.length() > 0.05
		var sprinting := Input.is_action_pressed("sprint")
		if moving:
			dir = dir.normalized()
			var avian_mult := 1.12 if str(GameState.hero_custom.get("race_key", "")) == "avian" else 1.0
			var spd := (205.0 if sprinting else 135.0) * avian_mult * delta
			var nx := Vector2(world.player_actor.position.x + dir.x * spd, world.player_actor.position.y)
			var ny := Vector2(world.player_actor.position.x, world.player_actor.position.y + dir.y * spd)
			var moved_ok := false
			if not world.is_point_blocked(nx): world.player_actor.position.x = nx.x; moved_ok = true
			if not world.is_point_blocked(ny): world.player_actor.position.y = ny.y; moved_ok = true
			if not moved_ok and world.has_click_target:
				world.clear_click_move()
			if absf(dir.x) > absf(dir.y):
				world.player_actor.dir_row = 1 if dir.x < 0.0 else 3
			else:
				world.player_actor.dir_row = 0 if dir.y < 0.0 else 2
			if GameState.night_lantern_on and GameState.current_scene == "outdoor" and (GameState.time_min >= 18.0 * 60.0 or GameState.time_min < 6.0 * 60.0):
				_lantern_step_acc += spd
				if _lantern_step_acc >= 96.0:
					_lantern_step_acc = 0.0
					GameState.night_lantern_steps += 1
		world.player_actor.update_actor(delta, moving, sprinting)

		var near := _find_interaction()
		prompt_panel.visible = not near.is_empty()
		if not near.is_empty():
			prompt_lbl.text = str(near["label"])
	else:
		prompt_panel.visible = false
		world.player_actor.update_actor(delta, false, false)

	world.update_world(delta, cs_active)

	# Camera Zoom & Clamp + Smooth Cutscene Focus + Day/Night Lighting
	var z := 1.65 if GameState.current_scene == "outdoor" else (2.0 if GameState.current_scene.begins_with("ruins_") else 2.15)
	if cs_active:
		z = maxf(z, 1.95)
	cam.zoom = Vector2(z, z)
	var focus_pt := cutscene_dir.focus_world_pos if cs_active else world.player_actor.position
	var bounds := world.get_scene_pixel_bounds()
	var half_vp := (get_viewport_rect().size * 0.5) / z
	var cx := bounds.x * 0.5 if bounds.x <= half_vp.x * 2.0 else clampf(focus_pt.x, half_vp.x, bounds.x - half_vp.x)
	var cy := bounds.y * 0.5 if bounds.y <= half_vp.y * 2.0 else clampf(focus_pt.y, half_vp.y, bounds.y - half_vp.y)
	cam.position = cam.position.lerp(Vector2(cx, cy), minf(1.0, delta * 8.0)) if cs_active else Vector2(cx, cy)

	var hr := GameState.time_min / 60.0
	if GameState.current_scene == "outdoor":
		if hr >= 19.5 or hr < 5.5:
			day_night_mod.color = Color(0.58, 0.64, 0.88, 1.0)
		elif hr >= 17.0 and hr < 19.5:
			day_night_mod.color = Color(0.98, 0.84, 0.72, 1.0)
		else:
			day_night_mod.color = Color.WHITE
	else:
		day_night_mod.color = Color.WHITE

	_bgm_check_t += delta
	if _bgm_check_t >= 1.0:
		_bgm_check_t = 0.0
		_sync_bgm_zone()
		_refresh_hud()
