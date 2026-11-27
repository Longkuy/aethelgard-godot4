extends Control
class_name CutsceneDirector
## Full In-Engine Cinematic Cutscene Director for Aethelgard v7.0:
## Plays all 74 Cutscenes (27 Scene/Landmark/Festival/Boss/Family/Wedding Cutscenes +
## 32 Multi-Beat Heart Events + 15 Multi-Beat Story Chronicles) with Letterbox Bars,
## Live Multi-Actor Stage Blocking, Camera Focus, Character Hops/Emotes, 4-Emotion Portraits,
## Typewriter Text, Interactive Branching Choices, Skip [Tab], and Theater Replay!

signal cutscene_finished(cs_id: String)

const TILE := 32.0

var is_playing: bool = false
var current_cs: Dictionary = {}
var current_mode: String = "cutscene" # cutscene, heart_event, chronicle
var beat_idx: int = 0
var in_choice_phase: bool = false
var in_reply_phase: bool = false
var focus_world_pos: Vector2 = Vector2.ZERO

var _world: ValleyWorld
var _restore_scene_after: bool = false
var _saved_scene: String = "outdoor"
var _saved_player_pos: Vector2 = Vector2.ZERO
var _saved_npcs: Dictionary = {}

var _full_text: String = ""
var _shown_chars: float = 0.0

var top_bar: ColorRect
var bottom_bar: ColorRect
var title_lbl: Label
var sub_lbl: Label
var step_lbl: Label
var skip_btn: Button

var dialog_card: PanelContainer
var portrait_rect: TextureRect
var speaker_lbl: Label
var emo_badge_lbl: Label
var body_lbl: Label
var choices_vb: VBoxContainer
var next_btn: Button

func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	top_bar = ColorRect.new()
	top_bar.color = Color(0.03, 0.05, 0.10, 0.94)
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 74.0
	add_child(top_bar)

	var top_hb := HBoxContainer.new()
	top_hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top_hb.offset_left = 24.0; top_hb.offset_top = 12.0; top_hb.offset_right = -24.0; top_hb.offset_bottom = -12.0
	top_hb.add_theme_constant_override("separation", 14)
	top_bar.add_child(top_hb)

	var title_vb := VBoxContainer.new()
	title_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hb.add_child(title_vb)

	title_lbl = Label.new()
	title_lbl.add_theme_font_size_override("font_size", 19)
	title_lbl.add_theme_color_override("font_color", Color("#fde047"))
	title_vb.add_child(title_lbl)

	sub_lbl = Label.new()
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.add_theme_color_override("font_color", Color("#cbd5e1"))
	title_vb.add_child(sub_lbl)

	step_lbl = Label.new()
	step_lbl.add_theme_color_override("font_color", Color("#f8fafc"))
	top_hb.add_child(step_lbl)

	skip_btn = Button.new()
	skip_btn.text = "ข้ามฉาก [Tab]"
	skip_btn.pressed.connect(skip_cutscene)
	top_hb.add_child(skip_btn)

	bottom_bar = ColorRect.new()
	bottom_bar.color = Color(0.03, 0.05, 0.10, 0.94)
	bottom_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_bar.offset_top = -74.0
	add_child(bottom_bar)

	dialog_card = PanelContainer.new()
	dialog_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	dialog_card.offset_left = -470.0; dialog_card.offset_right = 470.0
	dialog_card.offset_top = -272.0; dialog_card.offset_bottom = -64.0
	dialog_card.custom_minimum_size = Vector2(940, 208)
	add_child(dialog_card)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	dialog_card.add_child(hb)

	var p_col := VBoxContainer.new()
	p_col.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_child(p_col)

	portrait_rect = TextureRect.new()
	portrait_rect.custom_minimum_size = Vector2(148, 148)
	portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	p_col.add_child(portrait_rect)

	emo_badge_lbl = Label.new()
	emo_badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emo_badge_lbl.add_theme_font_size_override("font_size", 12)
	p_col.add_child(emo_badge_lbl)

	var right_vb := VBoxContainer.new()
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vb.add_theme_constant_override("separation", 6)
	hb.add_child(right_vb)

	speaker_lbl = Label.new()
	speaker_lbl.add_theme_font_size_override("font_size", 17)
	speaker_lbl.add_theme_color_override("font_color", Color("#7c2d12"))
	right_vb.add_child(speaker_lbl)

	body_lbl = Label.new()
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.custom_minimum_size = Vector2(0, 68)
	right_vb.add_child(body_lbl)

	choices_vb = VBoxContainer.new()
	choices_vb.visible = false
	right_vb.add_child(choices_vb)

	var nav_hb := HBoxContainer.new()
	nav_hb.alignment = BoxContainer.ALIGNMENT_END
	right_vb.add_child(nav_hb)

	next_btn = Button.new()
	next_btn.text = "ต่อไป [Space / E] ▶"
	next_btn.pressed.connect(advance_or_reveal)
	nav_hb.add_child(next_btn)

func play_cutscene_by_id(cs_id: String, world: ValleyWorld, restore_scene: bool = false) -> bool:
	if not GameData.cutscenes_v7.has(cs_id):
		return false
	play_cutscene_dict(GameData.cutscenes_v7[cs_id], "cutscene", world, restore_scene)
	return true

func play_cutscene_dict(cs_dict: Dictionary, mode: String, world: ValleyWorld, restore_scene: bool = false) -> void:
	_world = world
	current_cs = cs_dict.duplicate(true)
	current_mode = mode
	beat_idx = 0
	in_choice_phase = false
	in_reply_phase = false
	is_playing = true
	visible = true

	_saved_scene = GameState.current_scene
	_saved_player_pos = world.player_actor.position
	_saved_npcs.clear()
	for cid in world.npc_actors.keys():
		var a: CharacterActor = world.npc_actors[cid]
		var st: Dictionary = world.npc_states[cid]
		_saved_npcs[cid] = {"pos": a.position, "vis": a.visible, "scene": str(st["scene"]), "dir": a.dir_row}

	var target_sc := str(current_cs.get("stage_scene", GameState.current_scene))
	_restore_scene_after = restore_scene and (target_sc != _saved_scene)
	if target_sc != "" and target_sc != GameState.current_scene:
		GameState.current_scene = target_sc
		world.sync_npc_schedules()

	var ft: Array = current_cs.get("focus_tile", [])
	if ft.size() >= 2:
		focus_world_pos = Vector2((float(ft[0]) + 0.5) * TILE, (float(ft[1]) + 0.5) * TILE)
	else:
		focus_world_pos = world.player_actor.position

	# Stage cast actors smoothly walking into position around focus point!
	var cast_arr: Array = current_cs.get("cast", [])
	if cast_arr.is_empty() and current_cs.has("character_id"):
		cast_arr = [str(current_cs["character_id"])]
	var offsets := [Vector2(-42, -10), Vector2(42, -10), Vector2(-68, 14), Vector2(68, 14)]
	for i in range(cast_arr.size()):
		var cid := str(cast_arr[i])
		if world.npc_actors.has(cid):
			var act: CharacterActor = world.npc_actors[cid]
			var st2: Dictionary = world.npc_states[cid]
			st2["scene"] = GameState.current_scene
			act.visible = true
			var off: Vector2 = offsets[i % offsets.size()]
			var dest := focus_world_pos + off
			act.position = dest + Vector2(-28.0 if off.x < 0.0 else 28.0, 0.0)
			act.dir_row = 3 if off.x < 0.0 else 1
			var tw := create_tween()
			tw.tween_property(act, "position", dest, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var bzone := str(current_cs.get("bgm_zone", ""))
	if bzone != "":
		AudioManager.override_zone = bzone

	title_lbl.text = "🎬 " + GameState.format_text(str(current_cs.get("title_th", "ฉากเหตุการณ์")))
	sub_lbl.text = GameState.format_text(str(current_cs.get("subtitle_th", "")))
	_show_current_beat()

func _process(delta: float) -> void:
	if not is_playing:
		return
	if _shown_chars < float(_full_text.length()):
		_shown_chars = minf(float(_full_text.length()), _shown_chars + delta * 55.0)
		body_lbl.text = _full_text.left(int(_shown_chars))

func _show_current_beat() -> void:
	var beats: Array = current_cs.get("beats", [])
	if beats.is_empty() and current_cs.has("intro_th"):
		beats = [{"speaker": str(current_cs.get("character_id", "01_ren")), "emotion": "happy", "text": str(current_cs["intro_th"])}]
		current_cs["beats"] = beats

	if beat_idx >= beats.size():
		var chs: Array = current_cs.get("choices", [])
		if not chs.is_empty() and not in_choice_phase and not in_reply_phase:
			_open_choices(chs)
			return
		_finish_cutscene()
		return

	choices_vb.visible = false
	next_btn.visible = true
	var b: Dictionary = beats[beat_idx]
	var sp := str(b.get("speaker", current_cs.get("character_id", "01_ren")))
	var emo := str(b.get("emotion", "neutral"))
	var em_icon := str(b.get("emote", ""))
	var c: Dictionary = GameData.char_by_id.get(sp, {})
	speaker_lbl.text = "%s (%s)" % [c.get("name_th", sp), c.get("race_th", "ชาวเมือง")]
	step_lbl.text = "ฉาก %d / %d" % [beat_idx + 1, beats.size()]
	portrait_rect.texture = GameData.get_portrait(sp, emo)
	var emo_names := {"neutral": "ปกติ", "happy": "ยิ้มแย้ม", "blush": "เขินอาย", "sad": "กังวล"}
	emo_badge_lbl.text = str(emo_names.get(emo, "ปกติ"))
	_full_text = GameState.format_text(str(b.get("text", "")))
	_shown_chars = 0.0
	body_lbl.text = ""
	AudioManager.play_voice(sp)

	if _world and _world.npc_actors.has(sp):
		var act: CharacterActor = _world.npc_actors[sp]
		act.play_hop()
		act.interact_timer = 0.45
		if em_icon != "":
			act.show_emote(em_icon, 2.8)
		focus_world_pos = act.position

func _open_choices(chs: Array) -> void:
	in_choice_phase = true
	next_btn.visible = false
	choices_vb.visible = true
	for child in choices_vb.get_children():
		child.queue_free()
	for ch in chs:
		var choice_dict: Dictionary = ch
		var btn := Button.new()
		btn.text = "➤ " + GameState.format_text(str(choice_dict.get("text_th", "")))
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(func(): _select_choice(choice_dict))
		choices_vb.add_child(btn)

func _select_choice(ch: Dictionary) -> void:
	in_choice_phase = false
	in_reply_phase = true
	choices_vb.visible = false
	next_btn.visible = true
	_apply_choice_rewards(ch)
	var sp := str(ch.get("speaker", current_cs.get("character_id", "01_ren")))
	var emo := str(ch.get("emotion", "blush" if current_mode == "heart_event" else "happy"))
	var c: Dictionary = GameData.char_by_id.get(sp, {})
	speaker_lbl.text = "%s (%s)" % [c.get("name_th", sp), c.get("race_th", "")]
	portrait_rect.texture = GameData.get_portrait(sp, emo)
	_full_text = GameState.format_text(str(ch.get("reply_th", "ขอบคุณมากนะ!")))
	_shown_chars = float(_full_text.length())
	body_lbl.text = _full_text
	AudioManager.play_sfx("heart")
	if _world and _world.npc_actors.has(sp):
		var act: CharacterActor = _world.npc_actors[sp]
		act.play_hop()
		act.show_emote("💖", 2.5)

func _apply_choice_rewards(ch: Dictionary) -> void:
	if ch.has("stat") and typeof(ch["stat"]) == TYPE_DICTIONARY:
		GameState.add_stat_xp(ch["stat"])
	if ch.has("stat_delta") and typeof(ch["stat_delta"]) == TYPE_DICTIONARY:
		GameState.add_stat_xp(ch["stat_delta"])
	if current_mode == "heart_event" and current_cs.has("character_id"):
		GameState.add_friendship(str(current_cs["character_id"]), int(ch.get("friendship_delta", 40)))
	if ch.has("hearts") and typeof(ch["hearts"]) == TYPE_DICTIONARY:
		var hd: Dictionary = ch["hearts"]
		for cid in hd.keys():
			GameState.add_friendship(str(cid), int(hd[cid]))

func advance_or_reveal() -> void:
	if not is_playing or in_choice_phase:
		return
	if _shown_chars < float(_full_text.length()):
		_shown_chars = float(_full_text.length())
		body_lbl.text = _full_text
		return
	if in_reply_phase:
		_finish_cutscene()
		return
	beat_idx += 1
	_show_current_beat()

func skip_cutscene() -> void:
	if not is_playing:
		return
	var chs: Array = current_cs.get("choices", [])
	var cid := str(current_cs.get("id", ""))
	if not chs.is_empty() and not in_reply_phase and not GameState.watched_cutscenes.has(cid):
		_apply_choice_rewards(chs[0])
	_finish_cutscene()

func _finish_cutscene() -> void:
	var cid := str(current_cs.get("id", ""))
	if cid != "":
		GameState.watched_cutscenes[cid] = true
		if current_mode == "heart_event":
			GameState.played_events[cid] = true
		elif current_mode == "chronicle" and not GameState.chronicles_done.has(cid):
			GameState.chronicles_done[cid] = true
			var rew: Dictionary = current_cs.get("reward", {})
			if int(rew.get("gold", 0)) > 0:
				GameState.add_gold(int(rew["gold"]))
			if rew.has("item_id"):
				GameState.add_item(str(rew["item_id"]), 1)
			AudioManager.play_sfx("quest")

	if _world:
		if _restore_scene_after:
			GameState.current_scene = _saved_scene
			_world.player_actor.position = _saved_player_pos
		for npc_id in _saved_npcs.keys():
			if _world.npc_actors.has(npc_id):
				var sv: Dictionary = _saved_npcs[npc_id]
				var act: CharacterActor = _world.npc_actors[npc_id]
				act.position = sv["pos"]
				act.dir_row = int(sv["dir"])
				_world.npc_states[npc_id]["scene"] = str(sv["scene"])
				act.visible = (str(sv["scene"]) == GameState.current_scene)
		_world.sync_npc_schedules()

	AudioManager.override_zone = ""
	is_playing = false
	visible = false
	GameState.check_achievements()
	GameState.save_slot(GameState.active_slot, true)
	cutscene_finished.emit(cid)
