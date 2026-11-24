extends PanelContainer
class_name DialoguePanel
## Stardew-Style Dialogue & Cutscene Panel with Art Style 2 Portraits (4 emotions),
## Gifting, Hangout, Heart Events, Confession, Marriage Proposal & Wedding Ceremony,
## Spouse Daily Life Care/Dates, and 4-Arc 15-Chapter Multi-Beat Chronicles!

signal job_requested(job_dict: Dictionary)
signal gift_picker_requested(npc_id: String)

var active_npc_id: String = ""
var current_chapter: Dictionary = {}
var chapter_beat_idx: int = 0

var speaker_lbl: Label
var hearts_lbl: Label
var body_lbl: Label
var emo_lbl: Label
var portrait_rect: TextureRect
var actions_row: HFlowContainer
var choices_col: VBoxContainer
var cutscene_row: HBoxContainer
var next_beat_btn: Button

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
	custom_minimum_size = Vector2(880, 195)
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
	body_lbl.custom_minimum_size = Vector2(0, 62)
	left.add_child(body_lbl)

	choices_col = VBoxContainer.new()
	choices_col.visible = false
	left.add_child(choices_col)

	actions_row = HFlowContainer.new()
	actions_row.add_theme_constant_override("h_separation", 6)
	left.add_child(actions_row)

	btn_gift = _make_btn("มอบของขวัญ", func(): gift_picker_requested.emit(active_npc_id))
	btn_hangout = _make_btn("ชวน Hangout", _on_hangout)
	btn_event = _make_btn("อีเวนต์หัวใจ!", _on_heart_event)
	btn_confess = _make_btn("สารภาพรัก", _on_confess)
	btn_marry = _make_btn("ขอแต่งงาน!", _on_propose_marriage)
	btn_spouse_care = _make_btn("รับมื้อเช้าคู่รัก", _on_spouse_care)
	btn_spouse_date = _make_btn("เดตคู่สมรส", _on_spouse_date)
	btn_job = _make_btn("ทำพาร์ทไทม์", _on_npc_job)
	_make_btn("ปิด [Esc]", close_panel)

	cutscene_row = HBoxContainer.new()
	cutscene_row.visible = false
	left.add_child(cutscene_row)
	next_beat_btn = Button.new()
	next_beat_btn.text = "ต่อไป [Space] >"
	next_beat_btn.pressed.connect(advance_cutscene)
	cutscene_row.add_child(next_beat_btn)
	var close_cut := Button.new()
	close_cut.text = "ปิดฉาก"
	close_cut.pressed.connect(close_panel)
	cutscene_row.add_child(close_cut)

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
	current_chapter.clear()
	GameState.talked_ever[cid] = true
	var rel: Dictionary = GameState.relations.get(cid, {"xp": 0, "talked_today": false, "gifted_today": false})
	if not bool(rel.get("talked_today", false)):
		rel["talked_today"] = true
		GameState.relations[cid] = rel
		GameState.add_friendship(cid, 15)
		GameState.add_stat_xp({"charm": 2})

	visible = true
	choices_col.visible = false
	cutscene_row.visible = false
	actions_row.visible = true
	AudioManager.play_sfx("talk")

	var dlg: Dictionary = GameData.dialogues.get(cid, {})
	var emo := "neutral"
	var line := "สวัสดี! ยินดีที่ได้พบกันในหุบเขาต้นไม้โลกนะ"
	if GameState.spouse_id == cid:
		emo = "blush"
		line = GameState.format_text("อรุณสวัสดิ์ที่รัก {player}! การได้ใช้ชีวิตเคียงข้างเธอที่ {farm} คือความสุขที่สุดของฉันเลย มารับมื้อเช้าอุ่นๆ ได้เสมอนะ!")
	elif GameState.partners.has(cid):
		emo = "blush"
		line = GameState.format_text("ดีใจทุกครั้งที่ได้เจอเธอนะ {player}! พอความสัมพันธ์เราเต็ม 10 หัวใจ เรามาแต่งงานสร้างครอบครัวที่ {farm} กันนะ")
	else:
		var hr := GameState.time_min / 60.0
		var gr: Dictionary = dlg.get("greetings", {})
		if GameState.weather == "rainy":
			line = str(gr.get("rainy", line)); emo = "sad"
		elif hr >= 17.0:
			line = str(gr.get("evening", line)); emo = "happy"
		else:
			line = str(gr.get("morning", line)); emo = "happy" if GameState.get_hearts(cid) >= 6 else "neutral"
	_refresh_header_and_portrait(cid, emo)
	body_lbl.text = GameState.format_text(line)

func _refresh_header_and_portrait(cid: String, emo: String) -> void:
	var c: Dictionary = GameData.char_by_id.get(cid, {})
	var h := GameState.get_hearts(cid)
	var status := " [คู่สมรส]" if GameState.spouse_id == cid else (" [คู่รัก]" if GameState.partners.has(cid) else "")
	speaker_lbl.text = "%s (%s)%s" % [c.get("name_th", cid), c.get("race_th", ""), status]
	hearts_lbl.text = "หัวใจ %d/10" % h
	portrait_rect.texture = GameData.get_portrait(cid, emo)
	var emo_map := {"neutral": "ปกติ", "happy": "ดีใจ", "blush": "เขินอาย", "sad": "เศร้า"}
	emo_lbl.text = emo_map.get(emo, "ปกติ")

	var rom := bool(c.get("romanceable", false))
	btn_event.visible = not _find_unlocked_event(cid).is_empty()
	btn_confess.visible = rom and (not GameState.partners.has(cid)) and GameState.spouse_id == "" and h >= 6
	btn_marry.visible = rom and GameState.partners.has(cid) and GameState.spouse_id == "" and h >= 9
	btn_spouse_care.visible = (GameState.spouse_id == cid) and (GameState.spouse_cared_day != GameState.day)
	btn_spouse_date.visible = (GameState.spouse_id == cid) and (GameState.spouse_dated_day != GameState.day)
	btn_job.visible = GameData.job_by_employer.has(cid)

func show_gift_reaction(cid: String, item_id: String) -> void:
	var it: Dictionary = GameData.item_by_id.get(item_id, {})
	var c: Dictionary = GameData.char_by_id.get(cid, {})
	if item_id == "item_world_tree_ring" and GameState.partners.has(cid) and GameState.spouse_id == "" and GameState.get_hearts(cid) >= 10:
		_on_propose_marriage()
		return
	GameState.add_item(item_id, -1)
	GameState.relations[cid]["gifted_today"] = true
	var loved: Array = c.get("gifts", {}).get("loved", [])
	var delta := 85 if (loved.has(it.get("name_th", "")) or item_id == "item_world_tree_ring") else 40
	GameState.add_friendship(cid, delta)
	AudioManager.play_sfx("heart")
	_refresh_header_and_portrait(cid, "blush" if delta >= 80 else "happy")
	body_lbl.text = "ขอบคุณสำหรับ '%s' มากๆ เลยนะ %s! (+%d แต้มหัวใจ)" % [it.get("name_th", item_id), GameState.player_name, delta]
	GameState.save_slot(GameState.active_slot, true)

func _on_hangout() -> void:
	var cost := GameState.get_stamina_cost(15)
	if GameState.stamina < cost:
		GameState.toast_requested.emit("พลังงานไม่พอสำหรับ Hangout!")
		return
	GameState.stamina -= cost
	GameState.time_min += 120.0
	var gain := GameState.add_friendship(active_npc_id, 40)
	GameState.add_stat_xp({"charm": 8})
	AudioManager.play_sfx("heart")
	_refresh_header_and_portrait(active_npc_id, "happy")
	body_lbl.text = "ใช้เวลาเดินเล่นพูดคุยด้วยกันอย่างอบอุ่น! (+%d แต้มหัวใจ)" % gain
	GameState.save_slot(GameState.active_slot, true)

func _find_unlocked_event(cid: String) -> Dictionary:
	var h := GameState.get_hearts(cid)
	for ev in GameData.heart_events:
		if str(ev["character_id"]) == cid and not GameState.played_events.has(ev["id"]) and h >= int(ev["hearts_required"]):
			return ev
	return {}

func _on_heart_event() -> void:
	var ev := _find_unlocked_event(active_npc_id)
	if ev.is_empty(): return
	actions_row.visible = false
	choices_col.visible = true
	for ch in choices_col.get_children(): ch.queue_free()
	body_lbl.text = GameState.format_text(str(ev["intro_th"]))
	for choice in ev["choices"]:
		var b := Button.new()
		b.text = "> " + str(choice["text_th"])
		b.pressed.connect(func():
			GameState.played_events[ev["id"]] = true
			GameState.add_friendship(active_npc_id, int(choice.get("friendship_delta", 35)))
			GameState.add_stat_xp(choice.get("stat_delta", {}))
			choices_col.visible = false
			actions_row.visible = true
			AudioManager.play_sfx("quest")
			_refresh_header_and_portrait(active_npc_id, "blush")
			body_lbl.text = GameState.format_text(str(choice["reply_th"]))
			GameState.save_slot(GameState.active_slot, true)
		)
		choices_col.add_child(b)

func _on_confess() -> void:
	GameState.partners[active_npc_id] = true
	GameState.add_friendship(active_npc_id, 120)
	GameState.add_stat_xp({"charm": 15, "courage": 15})
	AudioManager.play_sfx("quest")
	_refresh_header_and_portrait(active_npc_id, "blush")
	body_lbl.text = "ฉันก็รักเธอเหมือนกัน %s! พอความสัมพันธ์เราเต็ม 10 หัวใจ นำ 'แหวนสายใยรากไม้โลก' มาขอแต่งงานกับฉันนะ!" % GameState.player_name
	GameState.save_slot(GameState.active_slot, true)

func _on_propose_marriage() -> void:
	if GameState.get_hearts(active_npc_id) < 10:
		GameState.toast_requested.emit("ต้องมีหัวใจเต็ม 10 ดวงก่อนถึงจะขอแต่งงานได้!")
		return
	if int(GameState.inventory.get("item_world_tree_ring", 0)) <= 0:
		GameState.toast_requested.emit("ต้องมี 'แหวนสายใยรากไม้โลก' ก่อน! (คราฟต์ที่โต๊ะคราฟต์ ซื้อที่ร้านพิป หรือเก็บจากชั้น B3 โบราณสถาน)")
		return
	GameState.add_item("item_world_tree_ring", -1)
	GameState.spouse_id = active_npc_id
	GameState.wedding_day = GameState.day
	GameState.add_gold(500)
	GameState.add_stat_xp({"charm": 25, "courage": 25})
	AudioManager.override_zone = "wedding"
	AudioManager.play_sfx("wedding")
	var sp_name := str(GameData.char_by_id.get(active_npc_id, {}).get("name_th", active_npc_id))
	play_chapter({
		"id": "wedding_" + active_npc_id,
		"title_th": "พิธีวิวาห์ใต้ต้นไม้โลก",
		"beats": [
			{"speaker": "16_bram", "emotion": "happy", "text": "ฮ่าๆๆ! วันนี้ชาวเมืองทั้ง 8 เผ่ามารวมตัวกันอวยพรพิธีวิวาห์ของ {player} และ " + sp_name + " ใต้ต้นไม้โลกสีทอง!"},
			{"speaker": active_npc_id, "emotion": "blush", "text": "{player}... ขอบคุณที่สวมแหวนวงนี้ให้ฉันนะ จากนี้ไปเรามาใช้ชีวิตคู่ด้วยกันที่ {farm} ตลอดไปเลยนะ! (+500G ขวัญถุงวิวาห์)"}
		]
	})
	GameState.save_slot(GameState.active_slot, true)

func _on_spouse_care() -> void:
	GameState.spouse_cared_day = GameState.day
	GameState.add_item("item_honey_croissant", 1)
	GameState.stamina = mini(GameState.get_max_stamina(), GameState.stamina + 25)
	GameState.add_stat_xp({"charm": 8, "courage": 5})
	AudioManager.play_sfx("heart")
	_refresh_header_and_portrait(active_npc_id, "happy")
	body_lbl.text = "ฉันทำครัวซองต์เนยน้ำผึ้งอุ่นๆ เตรียมไว้ให้ที่รักแล้วจ้ะ กินให้อิ่มแล้วสู้ๆ กับวันนี้นะ! (+25 พลังงาน +1 ครัวซองต์)"
	GameState.save_slot(GameState.active_slot, true)

func _on_spouse_date() -> void:
	GameState.spouse_dated_day = GameState.day
	GameState.stamina = GameState.get_max_stamina()
	GameState.time_min += 120.0
	GameState.add_friendship(active_npc_id, 50)
	GameState.add_stat_xp({"charm": 12, "wisdom": 8})
	AudioManager.override_zone = "wedding"
	AudioManager.play_sfx("wedding")
	_refresh_header_and_portrait(active_npc_id, "blush")
	body_lbl.text = "คุณและคู่สมรสนั่งอิงแอบชมหมู่ดาวเหนือหุบเขาต้นไม้โลกอย่างแสนหวาน พลังงานฟื้นเต็มเปี่ยม 100%!"
	GameState.save_slot(GameState.active_slot, true)

func _on_npc_job() -> void:
	if GameData.job_by_employer.has(active_npc_id):
		var j: Dictionary = GameData.job_by_employer[active_npc_id]
		close_panel()
		job_requested.emit(j)

func play_chapter(ch: Dictionary) -> void:
	current_chapter = ch
	chapter_beat_idx = 0
	visible = true
	actions_row.visible = false
	choices_col.visible = false
	cutscene_row.visible = true
	_render_beat()

func _render_beat() -> void:
	var beats: Array = current_chapter.get("beats", [])
	if chapter_beat_idx >= beats.size():
		if not str(current_chapter.get("id", "")).begins_with("wedding_"):
			var cid := str(current_chapter.get("id", ""))
			if cid != "" and not GameState.chronicles_done.has(cid):
				GameState.chronicles_done[cid] = true
				var rew: Dictionary = current_chapter.get("reward", {})
				GameState.add_gold(int(rew.get("gold", 150)))
				if rew.has("item_id"):
					GameState.add_item(str(rew["item_id"]), 1)
				AudioManager.play_sfx("quest")
				GameState.save_slot(GameState.active_slot, true)
		close_panel()
		return
	var b: Dictionary = beats[chapter_beat_idx]
	var sp := str(b.get("speaker", "01_ren"))
	var c: Dictionary = GameData.char_by_id.get(sp, {})
	speaker_lbl.text = "%s — %s" % [current_chapter.get("title_th", ""), c.get("name_th", sp)]
	hearts_lbl.text = "ฉาก %d/%d" % [chapter_beat_idx + 1, beats.size()]
	portrait_rect.texture = GameData.get_portrait(sp, str(b.get("emotion", "neutral")))
	body_lbl.text = GameState.format_text(str(b.get("text", "")))

func advance_cutscene() -> void:
	if current_chapter.is_empty(): return
	chapter_beat_idx += 1
	AudioManager.play_sfx("talk")
	_render_beat()

func close_panel() -> void:
	visible = false
	active_npc_id = ""
	current_chapter.clear()
	if AudioManager.override_zone == "wedding":
		AudioManager.override_zone = ""
