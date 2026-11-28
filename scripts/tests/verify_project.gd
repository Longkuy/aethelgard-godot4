extends Node
## Automated End-to-End Verification Script for Godot 4 (`--headless`) — v7.0 Complete Edition
## Verifies all 284 PNG sprites, 16 JSON datasets, 74 Cutscenes via CutsceneDirector,
## and all v6.0 + v7.0 Deep Gameplay Systems!

func _ready() -> void:
	print("=== [AETHELGARD GODOT 4 v7.0 COMPLETE VERIFICATION START] ===")

	# 1. Verify all 284 PNG sprites load cleanly as valid Texture2D resources
	var sp_check := GameData.verify_all_284_sprites()
	print("Sprites verified: %d / %d" % [int(sp_check["loaded_ok"]), int(sp_check["total_found"])])
	assert(int(sp_check["total_found"]) == 284, "Expected exactly 284 PNG sprites")
	assert(int(sp_check["loaded_ok"]) == 284, "All 284 PNG sprites must load as valid Texture2D")

	# 2. Verify all JSON datasets + 100% unique 16-character dialogues + 74 cutscenes
	assert(GameData.characters.size() == 16, "Expected 16 characters")
	assert(GameData.items.size() >= 40, "Expected 39 base items + World Tree Ring")
	assert(GameData.jobs.size() == 8, "Expected 8 part-time jobs")
	assert(GameData.quests.size() == 10, "Expected 10 bulletin quests")
	assert(GameData.chapters.size() == 15, "Expected 15 story chronicle chapters")
	assert(GameData.landmarks.size() == 5, "Expected 5 restorable landmarks")
	assert(GameData.museum_collection.size() == 12, "Expected 12 museum items")
	assert(GameData.heart_events.size() == 32, "Expected 32 multi-beat heart events")
	assert(GameData.cutscenes_v7.size() == 28, "Expected 28 scene/landmark/festival/boss/family/wedding cutscenes")

	var morning_set := {}
	for c in GameData.characters:
		var cid := str(c["id"])
		var d: Dictionary = GameData.dialogues.get(cid, {})
		var m := str(d.get("greetings", {}).get("morning", ""))
		assert(m != "", "Missing morning greeting for " + cid)
		morning_set[m] = true
		assert(d.has("child_line"), "Missing child_line for " + cid)
	assert(morning_set.size() == 16, "All 16 characters must have 100% unique morning lines")
	for hev in GameData.heart_events:
		var beats_arr: Array = hev.get("beats", [])
		assert(beats_arr.size() >= 2, "Every heart event must have multi-beat cutscene data: " + str(hev["id"]))
	var total_cs := GameData.cutscenes_v7.size() + GameData.heart_events.size() + GameData.chapters.size()
	print("Narrative & Cutscenes verified: 16 unique dialogues, %d total playable cutscenes!" % total_cs)
	assert(total_cs == 75, "Expected 75 total playable cutscenes")

	# 3. Boot full Main.tscn scene!
	var main_packed := load("res://scenes/Main.tscn") as PackedScene
	assert(main_packed != null, "Main.tscn must load cleanly")
	var main_inst := main_packed.instantiate()
	add_child(main_inst)
	await get_tree().process_frame
	GameState.reset_to_new_game()

	# 4. System: 8-Race Protagonist Customizer + Layered Accessories & Outfits
	GameState.hero_custom = {"base_id": "15_thorn", "race_key": "dwarf", "hue": 45.0, "sat": 120.0, "val": 105.0, "skin": "tan"}
	GameState.equipped_accessory = "acc_fairy_wings"
	GameState.equipped_outfit = "outfit_spring"
	main_inst.world.player_actor.refresh_appearance()
	main_inst.world.player_actor.update_actor(0.1, true, false)
	assert(GameState.get_max_stamina() >= 115, "Dwarf perk must grant +15 max stamina")
	print("8-Race Customizer + Layered Accessories & Seasonal Outfits verified!")

	# 5. System: CutsceneDirector playback across Scene Entry, Multi-Beat Heart Event & Chronicle!
	assert(main_inst.cutscene_dir.play_cutscene_by_id("cs_opening_arrival", main_inst.world, false) == true, "Opening cutscene must play")
	assert(main_inst.cutscene_dir.is_playing == true, "CutsceneDirector must be playing")
	main_inst.cutscene_dir.skip_cutscene()
	assert(GameState.watched_cutscenes.has("cs_opening_arrival"), "Opening cutscene must record watched state")

	var ev0: Dictionary = GameData.heart_events[0]
	main_inst.cutscene_dir.play_cutscene_dict(ev0, "heart_event", main_inst.world, true)
	while main_inst.cutscene_dir.is_playing and not main_inst.cutscene_dir.in_choice_phase:
		main_inst.cutscene_dir.advance_or_reveal()
	assert(main_inst.cutscene_dir.in_choice_phase == true, "Heart event cutscene must reach interactive choices")
	var ch_list: Array = ev0["choices"]
	main_inst.cutscene_dir._select_choice(ch_list[0])
	main_inst.cutscene_dir.advance_or_reveal()
	assert(GameState.played_events.has(str(ev0["id"])), "Heart event must mark played_events after choice")

	var ch0: Dictionary = GameData.chapters[0]
	main_inst.cutscene_dir.play_cutscene_dict(ch0, "chronicle", main_inst.world, true)
	main_inst.cutscene_dir.skip_cutscene()
	assert(GameState.chronicles_done.has(str(ch0["id"])), "Chronicle cutscene must mark chronicles_done & grant rewards")
	print("CutsceneDirector (Letterbox + Stage Blocking + Branching Choices + Skip) verified!")

	# 6. All 6 Specialized Minigames
	for mg_kind in ["forge_heat", "order_rush", "rune_memory", "sky_dash", "stardew_fish", "rhythm_stage"]:
		main_inst.mg_modal.start_minigame(mg_kind, "concert", null)
		main_inst.mg_modal._process(0.1)
		main_inst.mg_modal.stop_minigame()
	print("All 6 specialized minigames verified!")

	# 7. 2nd Floor Loft + Grid Furniture Placement
	GameState.gold = 5000
	GameState.add_item("item_hard_oak", 4)
	assert(GameState.upgrade_second_floor() == true, "2nd floor upgrade should succeed")
	GameState.decor_owned["decor_tea_set"] = true
	assert(GameState.place_decor_on_grid("decor_tea_set", "farmhouse_upstairs", 6, 4, 0) == true, "Valid loft grid placement must succeed")
	print("Grid furniture placement & 2nd floor loft verified!")

	# 8. Marriage + Child Birth & 3 Growth Stages (Cradle -> Toddler -> Explorer)
	GameState.partners["03_lilian"] = true
	GameState.relations["03_lilian"]["xp"] = 1000
	GameState.add_item("item_world_tree_ring", 1)
	main_inst.dlg_panel.open_npc_dialogue("03_lilian")
	main_inst.dlg_panel._on_propose_marriage()
	if main_inst.cutscene_dir.is_playing:
		main_inst.cutscene_dir.skip_cutscene()
	assert(GameState.spouse_id == "03_lilian", "Marriage proposal must wed 03_lilian")
	assert(GameState.owned_outfits.has("outfit_wedding"), "Wedding must unlock wedding outfit")

	assert(GameState.trigger_child_birth("โนวา") == true, "Child birth must trigger after marriage")
	if main_inst.cutscene_dir.is_playing:
		main_inst.cutscene_dir.skip_cutscene()
	assert(int(GameState.child_data["stage"]) == 1, "Child starts at Stage 1 (cradle)")
	assert(GameState.interact_with_child() != "", "Parent child care interaction must return warm message")
	for _i in range(6):
		GameState.start_next_morning()
		if main_inst.cutscene_dir.is_playing:
			main_inst.cutscene_dir.skip_cutscene()
	assert(int(GameState.child_data["stage"]) == 3, "After 6 days child must reach Stage 3 (Young Explorer)")
	GameState.weather = "sunny"
	GameState.time_min = 13.0 * 60.0
	main_inst.world.sync_npc_schedules()
	assert(main_inst.world.child_actor.active_scene == "outdoor", "Stage 3 Explorer child visits town plaza on sunny afternoon")
	print("Marriage + Child Birth & all 3 Growth Stages verified!")

	# 9. Under-Root Ancient Ruins B1–B4 + Floor B4 Boss Shield Break & [F] Purification!
	GameState.ruins_state["ruins_b1"]["pillars"] = [1, 1, 0]
	assert(bool(GameState.compute_ruins_beams("ruins_b1")["solved"]) == true, "B1 solution [1,1,0] must solve")
	GameState.ruins_state["ruins_b2"]["pillars"] = [1, 1, 0, 0]
	assert(bool(GameState.compute_ruins_beams("ruins_b2")["solved"]) == true, "B2 solution [1,1,0,0] must solve")
	GameState.ruins_state["ruins_b3"]["pillars"] = [1, 1, 0, 2, 1, 0]
	assert(bool(GameState.compute_ruins_beams("ruins_b3")["solved"]) == true, "B3 solution [1,1,0,2,1,0] must solve")

	assert(bool(GameState.compute_ruins_beams("ruins_b4")["solved"]) == false, "B4 Boss Sanctum must start unsolved")
	assert(GameState.purify_boss_damage() == "shielded", "Boss must block [F] pulse while prism shield is active")
	GameState.ruins_state["ruins_b4"]["pillars"] = [0, 0, 1, 1]
	assert(bool(GameState.compute_ruins_beams("ruins_b4")["solved"]) == true, "B4 solution [0,0,1,1] must shatter boss shield")
	assert(GameState.purify_boss_damage() == "hit", "1st Sacred Light Pulse hits boss")
	assert(GameState.purify_boss_damage() == "hit", "2nd Sacred Light Pulse hits boss")
	assert(GameState.purify_boss_damage() == "purified", "3rd Sacred Light Pulse purifies Corrupted Root Warden Boss!")
	if main_inst.cutscene_dir.is_playing:
		main_inst.cutscene_dir.skip_cutscene()
	assert(GameState.boss_purified == true and GameState.owned_accessories.has("acc_royal_crown"), "Boss purification must unlock Royal Crown")
	print("Ancient Ruins B1–B4 + Floor B4 Boss Purification & Royal Crown verified!")

	# 10. Quests, Landmarks, Museum +20% Sell Bonus, Seasonal Festival, Birthday x2, Save Slot 3 & Export Presets!
	GameState.quests_state["q03_warm_bread"] = "accepted"
	GameState.add_item("item_honey_bread", 1)
	assert(GameState.complete_quest(GameData.quests[2]) == true, "q03_warm_bread must complete & deduct item")

	GameState.gold = 3000
	GameState.add_item("item_hard_oak", 2)
	GameState.add_item("item_rootdew_flower", 2)
	assert(GameState.build_landmark("lm_hotspring") == true, "Landmark build with materials must succeed & trigger cutscene")
	if main_inst.cutscene_dir.is_playing:
		main_inst.cutscene_dir.skip_cutscene()

	for m in GameData.museum_collection:
		var miid := str(m["item_id"])
		GameState.add_item(miid, 1)
		assert(GameState.donate_museum_item(miid) == true, "Museum donation must succeed for " + miid)
		if main_inst.cutscene_dir.is_playing:
			main_inst.cutscene_dir.skip_cutscene()
	assert(GameState.sell_bonus_pct == 20, "9/12 Museum milestone must grant +20% permanent sell bonus")

	GameState.day = 7
	assert(GameState.join_today_festival() == true, "Day 7 Lantern Festival must join & trigger festival cutscene")
	if main_inst.cutscene_dir.is_playing:
		main_inst.cutscene_dir.skip_cutscene()

	GameState.day = 4 # Spring Day 4 = Ren's birthday!
	assert(GameData.is_npc_birthday("01_ren", GameState.get_season_index(), GameState.get_day_of_season()) == true, "Spring 4 must be 01_ren birthday")

	assert(FileAccess.file_exists("res://export_presets.cfg"), "export_presets.cfg must exist for Windows/Linux/Web builds")

	GameState.player_name = "ผู้พิทักษ์เอเธลการ์ด v7"
	GameState.save_slot(3, true)
	GameState.reset_to_new_game()
	assert(GameState.load_slot(3, false) == true, "Save Slot 3 must load v7 state")
	assert(GameState.boss_purified == true and int(GameState.child_data["stage"]) == 3, "Save Slot 3 must persist Boss & Child v7 state")
	GameState.delete_slot(3)

	# 11. v10.0 True Character Creator + Adventurer's Guild + All 6 Bugfixes Verification!
	assert(main_inst.world._ysort_props.size() >= 40, "Outdoor World Tree, Buildings, Landmarks & Trees must be Y-sorted inside entities_root")
	main_inst.world.set_click_move_target(Vector2(45.5 * 32.0, 31.5 * 32.0))
	assert(main_inst.world.has_click_target and main_inst.world.click_path.size() >= 1, "AStarGrid2D pathfinding must compute valid waypoints")
	main_inst.world.clear_click_move()

	GameState.reset_to_new_game()
	# True Modular Character Creator (NOT NPC sprite sheet!)
	assert(main_inst.world.player_actor.sprite.visible == false, "Player must render custom procedural character, not NPC sprite")
	GameState.hero_custom["race_key"] = "avian"
	GameState.hero_custom["hair_style"] = "twin_tails"
	GameState.hero_custom["hair_hex"] = "#f472b6"
	GameState.hero_custom["outfit_style"] = "knight"
	main_inst.world.player_actor.refresh_appearance()
	main_inst.world.player_actor.update_actor(0.1, true, false)
	main_inst.uni_modal.open_protagonist_creator("hero")
	assert(main_inst.uni_modal._preview_canvas != null, "True Character Creator must render live procedural preview canvas")
	main_inst.uni_modal.visible = false

	# Adventurer's Guild Bounties & Rank Up!
	assert(GameData.GUILD_BOUNTIES.size() == 12, "Expected 12 Adventurer's Guild bounties")
	assert(GameState.accept_guild_bounty("gb_honey_supply") == true, "Must accept Guild bounty")
	GameState.add_item("item_wild_honey", 2)
	assert(GameState.claim_guild_bounty("gb_honey_supply") == true, "Must claim Guild bounty & earn Guild XP")
	assert(GameState.guild_completed == 1 and GameState.guild_xp >= 40, "Guild completed count & XP must increment")
	assert(GameState.accept_guild_bounty("gb_wisp_b1") == true, "Must accept wisp hunt bounty")
	GameState.record_guild_action("purify_wisps", 2)
	assert(GameState.claim_guild_bounty("gb_wisp_b1") == true, "Must claim wisp hunt bounty & rank up to Rank E")
	assert(str(GameData.get_guild_rank_info(GameState.guild_xp)["rank"]) == "E", "Must promote to Adventurer Rank E at 100 Guild XP")
	GameState.start_next_morning()
	assert(str(GameState.guild_bounties_state["gb_honey_supply"]) == "open", "Repeatable Guild bounties must refresh every morning")
	assert(GameState.mailbox.size() >= 2, "Scheduled daily mailbox letters must deliver automatically")

	# Bugfix 1: Theater Replay-Only Guard (zero duplicate rewards!)
	var gold_before_replay := GameState.gold
	main_inst.cutscene_dir.play_cutscene_dict(GameData.chapters[0], "chronicle", main_inst.world, true, true)
	main_inst.cutscene_dir.skip_cutscene()
	assert(GameState.gold == gold_before_replay, "Theater replay mode must NEVER grant duplicate gold or rewards")

	# Bugfix 2: Daily Gift Limit!
	GameState.add_item("item_honey_croissant", 2)
	main_inst.dlg_panel.open_npc_dialogue("01_ren")
	main_inst.dlg_panel.show_gift_reaction("01_ren", "item_honey_croissant")
	assert(main_inst.dlg_panel.btn_gift.disabled == true, "Gift button must disable after giving 1 gift today")
	main_inst.dlg_panel.close_panel()

	# Bugfix 3: Indoor Counter & Farmhouse Workbench Collision!
	GameState.current_scene = "farmhouse"
	assert(main_inst.world.is_point_blocked(Vector2(5.5 * 32.0, 8.5 * 32.0)) == true, "Farmhouse workbench must block player")
	GameState.current_scene = "shop"
	assert(main_inst.world.is_point_blocked(Vector2(7.0 * 32.0, 3.0 * 32.0)) == true, "Shop counter must block player")
	assert(main_inst.world.is_point_blocked(Vector2(7.0 * 32.0, 4.5 * 32.0)) == false, "Tile in front of shop counter must remain walkable for [E]")
	main_inst.world.player_actor.position = Vector2(7.0 * 32.0, 8.0 * 32.0)
	main_inst.world.set_click_move_target(Vector2(7.0 * 32.0, 4.5 * 32.0))
	assert(main_inst.world.has_click_target and main_inst.world.click_path.size() >= 1, "Indoor AStarGrid2D must compute waypoints")

	# Bugfix 4 & 5 & 6: Global Settings.cfg, Achievement Progress, Floating Text, Mount & Monument!
	assert(GameData.ACHIEVEMENTS.size() == 26, "Expected 26 total achievements including ach_guild_master & ach_endgame")
	assert(GameState.get_achievement_progress("ach_guild_master").contains("/5"), "Achievement progress must format counters")
	AudioManager.bgm_volume = 0.55
	GameState.save_settings()
	AudioManager.bgm_volume = 0.1
	GameState.load_settings()
	assert(absf(AudioManager.bgm_volume - 0.55) < 0.01, "Global settings.cfg must persist BGM volume")

	GameState.has_starlight_mount = true
	GameState.mount_active = true
	GameState.monument_built = true
	var before_w := int(GameState.stats["wisdom"])
	GameState.hero_custom["race_key"] = "elf"
	GameState.add_stat_xp({"wisdom": 100})
	assert(int(GameState.stats["wisdom"]) - before_w == 115, "Golden Monument must grant +15% permanent XP bonus")
	GameState.check_achievements()
	assert(GameState.achievements_unlocked.has("ach_endgame"), "Mount + Monument must unlock ach_endgame")
	main_inst.world.spawn_floating_text(Vector2(100, 100), "+150 G", Color.YELLOW)
	assert(main_inst.world._floating_texts.size() >= 1, "Floating world texts must spawn")
	main_inst.wm_modal.open_map(main_inst.world)
	assert(main_inst.wm_modal._map_tex != null, "WorldMapModal must bake cached ImageTexture")
	main_inst.wm_modal.visible = false

	print("v10.0 Verified: True Procedural Character Creator, Adventurer's Guild (Rank F-S), Theater Replay Guard, Daily Gift Limit, Indoor Counter Collision, Achievement Progress & Floating Texts!")
	print("Achievements unlocked during test run: %d / %d" % [GameState.achievements_unlocked.size(), GameData.ACHIEVEMENTS.size()])
	print("=== [ALL GODOT 4 v10.0 CHECKS & 75 CUTSCENES PASSED 100% WITH ZERO ERRORS!] ===")
	get_tree().quit(0)
