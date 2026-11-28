extends PanelContainer
class_name DialoguePanel
## Stardew-Style Dialogue Panel (v7.0) with 100% Unique 16-Character Lines (Heart Tiers,
## Greetings, Spouse & Child Lines, 4-Tier Gift Reactions, x2 Birthday Bonus),
## and full handoff to CutsceneDirector for Heart Events, Confession & Grand Wedding!

signal job_requested(job_dict: Dictionary)
signal gift_picker_requested(npc_id: String)
signal heart_event_cutscene_requested(ev_dict: Dictionary)
signal confession_cutscene_requested(npc_id: String)
signal wedding_cutscene_requested(npc_id: String)
signal hangout_cutscene_requested(npc_id: String, spot_dict: Dictionary)

var active_npc_id: String = ""

var speaker_lbl: Label
var hearts_lbl: Label
var body_lbl: Label
var emo_lbl: Label
var portrait_rect: TextureRect
var actions_row: HFlowContainer
var hangout_row: HFlowContainer

var btn_tier_talk: Button
var btn_gift: Button
var btn_hangout: Button
var btn_event: Button
var btn_confess: Button
var btn_marry: Button
var btn_spouse_care: Button
var btn_spouse_date: Button
var btn_job: Button

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(880, 198)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	add_child(hb)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 6)
	hb.add_child(left)

	var header := HBoxContainer.new()
	left.add_child(header)
	speaker_lbl = Label.new()
	speaker_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speaker_lbl.add_theme_font_size_override("font_size", 16)
	header.add_child(speaker_lbl)

	hearts_lbl = Label.new()
	hearts_lbl.add_theme_color_override("font_color", Color("#be185d"))
	header.add_child(hearts_lbl)

	body_lbl = Label.new()
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.custom_minimum_size = Vector2(0, 66)
	left.add_child(body_lbl)

	hangout_row = HFlowContainer.new()
	hangout_row.add_theme_constant_override("h_separation", 6)
	hangout_row.visible = false
	left.add_child(hangout_row)

	actions_row = HFlowContainer.new()
	actions_row.add_theme_constant_override("h_separation", 6)
	left.add_child(actions_row)

	btn_tier_talk = _make_btn("ชวนคุยเรื่องในใจ", _on_deep_talk)
	btn_gift = _make_btn("มอบของขวัญ", func(): gift_picker_requested.emit(active_npc_id))
	btn_hangout = _make_btn("ชวน Hangout", _on_hangout)
	btn_event = _make_btn("🎬 อีเวนต์หัวใจ!", _on_heart_event)
	btn_confess = _make_btn("💕 สารภาพรัก", _on_confess)
	btn_marry = _make_btn("💍 ขอแต่งงาน!", _on_propose_marriage)
	btn_spouse_care = _make_btn("🥐 มื้อเช้าคู่รัก", _on_spouse_care)
	btn_spouse_date = _make_btn("🌠 เดตคู่สมรส", _on_spouse_date)
	btn_job = _make_btn("ทำพาร์ทไทม์", _on_npc_job)
	_make_btn("ปิด [Esc]", close_panel)

	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_child(right)

	portrait_rect = TextureRect.new()
	portrait_rect.custom_minimum_size = Vector2(138, 138)
	portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	right.add_child(portrait_rect)

	emo_lbl = Label.new()
	emo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emo_lbl.add_theme_font_size_override("font_size", 12)
	right.add_child(emo_lbl)

func _make_btn(txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.pressed.connect(cb)
	actions_row.add_child(b)
	return b

func open_npc_dialogue(cid: String) -> void:
	active_npc_id = cid
	if GameState.compass_npc_id == cid:
		GameState.compass_npc_id = ""
	GameState.talked_ever[cid] = true
	var rel: Dictionary = GameState.relations.get(cid, {"xp": 0, "talked_today": false, "gifted_today": false})
	if not bool(rel.get("talked_today", false)):
		rel["talked_today"] = true
		GameState.relations[cid] = rel
		GameState.add_friendship(cid, 18)
		GameState.add_stat_xp({"charm": 2})
		GameState.record_guild_action("talk_npcs", 1)
	GameState.check_achievements()

	visible = true
	hangout_row.visible = false
	actions_row.visible = true
	AudioManager.play_voice(cid)

	var dlg: Dictionary = GameData.dialogues.get(cid, {})
	var emo := "neutral"
	var line := "สวัสดี! ยินดีที่ได้พบกันในหุบเขาต้นไม้โลกนะ"
	if GameState.spouse_id == cid:
		emo = "blush"
		if bool(GameState.child_data.get("born", false)) and dlg.has("child_line") and randf() < 0.45:
			line = str(dlg["child_line"])
		else:
			var sp_arr: Array = dlg.get("spouse_lines", [])
			line = str(sp_arr[GameState.day % sp_arr.size()]) if not sp_arr.is_empty() else "อรุณสวัสดิ์ที่รัก {player}!"
	else:
		var hr := GameState.time_min / 60.0
		var gr: Dictionary = dlg.get("greetings", {})
		if GameState.weather == "rainy":
			line = str(gr.get("rainy", line)); emo = "neutral"
		elif hr >= 17.0:
			line = str(gr.get("evening", line)); emo = "happy"
		else:
			line = str(gr.get("morning", line)); emo = "happy" if GameState.get_hearts(cid) >= 5 else "neutral"

	var bday := GameData.is_npc_birthday(cid, GameState.get_season_index(), GameState.get_day_of_season())
	if bday:
		line = "🎂 [วันนี้เป็นวันเกิดของฉัน!] " + line
		emo = "happy"
	_refresh_header_and_portrait(cid, emo)
	body_lbl.text = GameState.format_text(line)

func _on_deep_talk() -> void:
	var dlg: Dictionary = GameData.dialogues.get(active_npc_id, {})
	var ht: Dictionary = dlg.get("heart_tiers", {})
	var h := GameState.get_hearts(active_npc_id)
	var key := "9_10" if h >= 9 else ("6_8" if h >= 6 else ("3_5" if h >= 3 else "0_2"))
	var emo := "blush" if h >= 6 else ("happy" if h >= 3 else "neutral")
	if bool(GameState.child_data.get("born", false)) and GameState.spouse_id == active_npc_id and dlg.has("child_line"):
		body_lbl.text = GameState.format_text(str(dlg["child_line"]))
		_refresh_header_and_portrait(active_npc_id, "happy")
		return
	body_lbl.text = GameState.format_text(str(ht.get(key, "ดีใจที่ได้พูดคุยกันวันนี้นะ {player}!")))
	AudioManager.play_voice(active_npc_id)
	_refresh_header_and_portrait(active_npc_id, emo)

func _refresh_header_and_portrait(cid: String, emo: String) -> void:
	var c: Dictionary = GameData.char_by_id.get(cid, {})
	var h := GameState.get_hearts(cid)
	var bday := GameData.is_npc_birthday(cid, GameState.get_season_index(), GameState.get_day_of_season())
	var status := " [คู่สมรส]" if GameState.spouse_id == cid else (" [คู่รัก]" if GameState.partners.has(cid) else "")
	if bday:
		status += " 🎂วันเกิด!"
	speaker_lbl.text = "%s (%s)%s" % [c.get("name_th", cid), c.get("race_th", ""), status]
	hearts_lbl.text = "หัวใจ %d/10" % h
	portrait_rect.texture = GameData.get_portrait(cid, emo)
	var emo_map := {"neutral": "ปกติ", "happy": "ดีใจ", "blush": "เขินอาย", "sad": "เศร้า"}
	emo_lbl.text = str(emo_map.get(emo, "ปกติ"))

	var rel: Dictionary = GameState.relations.get(cid, {})
	var gifted_now := bool(rel.get("gifted_today", false))
	btn_gift.disabled = gifted_now
	btn_gift.text = "ให้ของขวัญแล้ววันนี้" if gifted_now else "มอบของขวัญ"
	var hung_now := GameState.hangout_today.has(cid)
	btn_hangout.disabled = hung_now
	btn_hangout.text = "ชวนเที่ยวแล้ววันนี้" if hung_now else "ชวน Hangout"
	var rom := bool(c.get("romanceable", false))
	btn_event.visible = not _find_unlocked_event(cid).is_empty()
	btn_confess.visible = rom and (not GameState.partners.has(cid)) and GameState.spouse_id == "" and h >= 6
	btn_marry.visible = rom and GameState.partners.has(cid) and GameState.spouse_id == "" and h >= 9
	btn_spouse_care.visible = (GameState.spouse_id == cid) and (GameState.spouse_cared_day != GameState.day)
	btn_spouse_date.visible = (GameState.spouse_id == cid) and (GameState.spouse_dated_day != GameState.day)
	btn_job.visible = GameData.job_by_employer.has(cid)

func show_gift_reaction(cid: String, item_id: String) -> void:
	active_npc_id = cid
	visible = true
	hangout_row.visible = false
	actions_row.visible = true
	if bool(GameState.relations.get(cid, {}).get("gifted_today", false)) and item_id != "item_world_tree_ring":
		GameState.toast_requested.emit("วันนี้มอบของขวัญให้คนนี้ไปแล้ว พรุ่งนี้ค่อยมามอบใหม่นะ!")
		return
	var it: Dictionary = GameData.item_by_id.get(item_id, {})
	var c: Dictionary = GameData.char_by_id.get(cid, {})
	if item_id == "item_world_tree_ring" and GameState.partners.has(cid) and GameState.spouse_id == "" and GameState.get_hearts(cid) >= 10:
		_on_propose_marriage()
		return
	GameState.add_item(item_id, -1)
	GameState.relations[cid]["gifted_today"] = true

	var gifts_cfg: Dictionary = c.get("gifts", {})
	var loved: Array = gifts_cfg.get("loved", [])
	var liked: Array = gifts_cfg.get("liked", [])
	var disliked: Array = gifts_cfg.get("disliked", [])
	var iname := str(it.get("name_th", item_id))

	var tier := "neutral"
	var base_pts := 35
	var emo := "happy"
	if loved.has(iname) or item_id == "item_world_tree_ring":
		tier = "loved"; base_pts = 90; emo = "blush"
	elif liked.has(iname):
		tier = "liked"; base_pts = 55; emo = "happy"
	elif disliked.has(iname):
		tier = "disliked"; base_pts = -15; emo = "sad"

	var bday := GameData.is_npc_birthday(cid, GameState.get_season_index(), GameState.get_day_of_season())
	if bday and base_pts > 0:
		base_pts *= 2

	var gain := GameState.add_friendship(cid, base_pts)
	AudioManager.play_sfx("heart" if gain > 0 else "miss")
	var dlg: Dictionary = GameData.dialogues.get(cid, {})
	var react_line := str(dlg.get("gift_reactions", {}).get(tier, "ขอบคุณสำหรับของขวัญนะ {player}!"))
	_refresh_header_and_portrait(cid, emo)
	var bday_tag := " [🎂 โบนัสวันเกิด x2!]" if (bday and gain > 0) else ""
	body_lbl.text = "%s\n(%s: %+d แต้มหัวใจ%s)" % [GameState.format_text(react_line), iname, gain, bday_tag]
	GameState.check_achievements()
	GameState.save_slot(GameState.active_slot, true)

func _on_hangout() -> void:
	if GameState.hangout_today.has(active_npc_id):
		GameState.toast_requested.emit("วันนี้ชวนคนนี้ไป Hangout แล้ว พรุ่งนี้ค่อยชวนใหม่นะ!")
		return
	var cost := GameState.get_stamina_cost(15)
	if GameState.stamina < cost:
		GameState.toast_requested.emit("พลังงานไม่พอสำหรับ Hangout! (ต้องการ %d⚡)" % cost)
		return
	actions_row.visible = false
	hangout_row.visible = true
	for ch in hangout_row.get_children():
		ch.queue_free()
	body_lbl.text = "เลือกสถานที่ที่จะชวนไป Hangout ด้วยกัน (-%d⚡, ใช้เวลา 2 ชม.):" % cost
	var spots := GameData.hangout_spots if not GameData.hangout_spots.is_empty() else [
		{"id": "spot_lake", "name_th": "ทะเลสาบมุกศักดิ์สิทธิ์", "scene": "outdoor", "x": 42, "y": 48},
		{"id": "spot_tavern", "name_th": "โรงเตี๊ยมตะเกียงมอส", "scene": "tavern", "x": 9, "y": 7},
		{"id": "spot_tree", "name_th": "ใต้ร่มต้นไม้โลก", "scene": "outdoor", "x": 42, "y": 30}
	]
	for sp in spots:
		var sp_dict: Dictionary = sp
		var b := Button.new()
		b.text = "📍 " + str(sp_dict.get("name_th", sp_dict.get("title_th", "จุดชมวิว")))
		b.pressed.connect(func():
			var cid := active_npc_id
			GameState.hangout_today[cid] = true
			GameState.stamina -= cost
			GameState.time_min = minf(23.75 * 60.0, GameState.time_min + 120.0)
			GameState.add_friendship(cid, 45)
			GameState.add_stat_xp({"charm": 10})
			AudioManager.play_sfx("heart")
			GameState.check_achievements()
			GameState.save_slot(GameState.active_slot, true)
			close_panel()
			hangout_cutscene_requested.emit(cid, sp_dict)
		)
		hangout_row.add_child(b)
	var b_back := Button.new()
	b_back.text = "ยกเลิก"
	b_back.pressed.connect(func(): hangout_row.visible = false; actions_row.visible = true)
	hangout_row.add_child(b_back)

func _find_unlocked_event(cid: String) -> Dictionary:
	var h := GameState.get_hearts(cid)
	for ev in GameData.heart_events:
		if str(ev["character_id"]) == cid and not GameState.played_events.has(ev["id"]) and h >= int(ev["hearts_required"]):
			return ev
	return {}

func _on_heart_event() -> void:
	var ev := _find_unlocked_event(active_npc_id)
	if ev.is_empty():
		return
	close_panel()
	heart_event_cutscene_requested.emit(ev)

func _on_confess() -> void:
	var cid := active_npc_id
	GameState.partners[cid] = true
	GameState.add_friendship(cid, 120)
	GameState.add_stat_xp({"charm": 15, "courage": 15})
	GameState.check_achievements()
	GameState.save_slot(GameState.active_slot, true)
	close_panel()
	confession_cutscene_requested.emit(cid)

func _on_propose_marriage() -> void:
	var cid := active_npc_id
	if GameState.get_hearts(cid) < 10:
		GameState.toast_requested.emit("ต้องมีหัวใจเต็ม 10 ดวงก่อนถึงจะขอแต่งงานได้!")
		return
	if int(GameState.inventory.get("item_world_tree_ring", 0)) <= 0:
		GameState.toast_requested.emit("ต้องมี 'แหวนสายใยรากไม้โลก' ก่อน! (คราฟต์ที่โต๊ะคราฟต์ ตลาดกลางคืน หรือชั้น B3 โบราณสถาน)")
		return
	GameState.add_item("item_world_tree_ring", -1)
	GameState.spouse_id = cid
	GameState.wedding_day = GameState.day
	GameState.owned_accessories["acc_wedding_veil"] = true
	GameState.owned_outfits["outfit_wedding"] = true
	GameState.add_gold(500)
	GameState.add_stat_xp({"charm": 25, "courage": 25})
	AudioManager.play_sfx("wedding")
	GameState.check_achievements()
	GameState.save_slot(GameState.active_slot, true)
	close_panel()
	wedding_cutscene_requested.emit(cid)

func _on_spouse_care() -> void:
	GameState.spouse_cared_day = GameState.day
	GameState.add_item("item_honey_croissant", 1)
	GameState.stamina = mini(GameState.get_max_stamina(), GameState.stamina + 25)
	GameState.add_stat_xp({"charm": 8, "courage": 5})
	AudioManager.play_sfx("heart")
	var dlg: Dictionary = GameData.dialogues.get(active_npc_id, {})
	var sp_arr: Array = dlg.get("spouse_lines", [])
	var msg := str(sp_arr[0]) if not sp_arr.is_empty() else "ฉันทำมื้อเช้าอุ่นๆ เตรียมไว้ให้ที่รักแล้วจ้ะ!"
	_refresh_header_and_portrait(active_npc_id, "happy")
	body_lbl.text = "%s\n(+25⚡ พลังงาน & +1 ครัวซองต์เนยน้ำผึ้ง)" % GameState.format_text(msg)
	GameState.save_slot(GameState.active_slot, true)

func _on_spouse_date() -> void:
	GameState.spouse_dated_day = GameState.day
	GameState.stamina = GameState.get_max_stamina()
	GameState.time_min = minf(23.75 * 60.0, GameState.time_min + 120.0)
	GameState.add_friendship(active_npc_id, 50)
	GameState.add_stat_xp({"charm": 12, "wisdom": 8})
	AudioManager.play_sfx("wedding")
	_refresh_header_and_portrait(active_npc_id, "blush")
	body_lbl.text = "คุณและคู่สมรสนั่งอิงแอบชมหมู่ดาวเหนือหุบเขาต้นไม้โลกอย่างแสนหวาน พลังงานฟื้นเต็มเปี่ยม 100%!"
	GameState.save_slot(GameState.active_slot, true)

func _on_npc_job() -> void:
	if GameData.job_by_employer.has(active_npc_id):
		var j: Dictionary = GameData.job_by_employer[active_npc_id]
		close_panel()
		job_requested.emit(j)

func close_panel() -> void:
	visible = false
	active_npc_id = ""
