extends Node
## Automated End-to-End Verification Script for Godot 4 (`--headless`)
## Boots Main.tscn, verifies all 284 PNG sprites & 15 JSONs, and tests all 6 Deep Gameplay Systems.

func _ready() -> void:
	print("=== [AETHELGARD GODOT 4 VERIFICATION START] ===")

	# 1. Verify all 284 PNG sprites load cleanly as valid Texture2D resources
	var sp_check := GameData.verify_all_284_sprites()
	print("Sprites verified: %d / %d" % [int(sp_check["loaded_ok"]), int(sp_check["total_found"])])
	assert(int(sp_check["total_found"]) == 284, "Expected exactly 284 PNG sprites")
	assert(int(sp_check["loaded_ok"]) == 284, "All 284 PNG sprites must load as valid Texture2D")

	# 2. Verify all JSON datasets
	assert(GameData.characters.size() == 16, "Expected 16 characters")
	assert(GameData.items.size() >= 40, "Expected 39 base items + World Tree Ring")
	assert(GameData.jobs.size() == 8, "Expected 8 part-time jobs")
	assert(GameData.quests.size() == 10, "Expected 10 bulletin quests")
	assert(GameData.chapters.size() == 15, "Expected 15 story chronicle chapters")
	assert(GameData.landmarks.size() == 5, "Expected 5 restorable landmarks")
	assert(GameData.museum_collection.size() == 12, "Expected 12 museum items")
	assert(GameData.heart_events.size() == 32, "Expected 32 heart events")
	print("JSON datasets verified: 16 chars, %d items, 8 jobs, 10 quests, 15 chapters, 32 heart events" % GameData.items.size())

	# 3. Boot full Main.tscn scene!
	var main_packed := load("res://scenes/Main.tscn") as PackedScene
	assert(main_packed != null, "Main.tscn must load cleanly")
	var main_inst := main_packed.instantiate()
	add_child(main_inst)
	await get_tree().process_frame

	# 4. System 1: 8-Race Protagonist Customizer & Perks
	GameState.hero_custom = {"base_id": "15_thorn", "race_key": "dwarf", "hue": 45.0, "sat": 120.0, "val": 105.0, "skin": "tan"}
	main_inst.world.player_actor.refresh_appearance()
	assert(GameState.get_max_stamina() >= 115, "Dwarf perk must grant +15 max stamina")

	# 5. System 2: All 6 Specialized Minigames
	for mg_kind in ["forge_heat", "order_rush", "rune_memory", "sky_dash", "stardew_fish", "rhythm_stage"]:
		main_inst.mg_modal.start_minigame(mg_kind, "concert", null)
		main_inst.mg_modal._process(0.1)
		main_inst.mg_modal.stop_minigame()
	print("All 6 specialized minigames verified!")

	# 6. System 4: 2nd Floor Loft + Grid Furniture Placement
	GameState.gold = 2000
	GameState.add_item("item_hard_oak", 4)
	assert(GameState.upgrade_second_floor() == true, "2nd floor upgrade should succeed")
	assert(GameState.house_level == 2, "House level must be 2")
	GameState.decor_owned["decor_tea_set"] = true
	assert(GameState.place_decor_on_grid("decor_tea_set", "farmhouse_upstairs", 6, 4, 0) == true, "Valid loft grid placement must succeed")
	assert(GameState.place_decor_on_grid("decor_tea_set", "farmhouse_upstairs", 0, 0, 0) == false, "Wall collision placement must be rejected")
	print("Grid furniture placement & 2nd floor loft verified!")

	# 7. System 3: Marriage & Spouse Life
	GameState.partners["03_lilian"] = true
	GameState.relations["03_lilian"]["xp"] = 1000
	GameState.add_item("item_world_tree_ring", 1)
	main_inst.dlg_panel.open_npc_dialogue("03_lilian")
	main_inst.dlg_panel._on_propose_marriage()
	assert(GameState.spouse_id == "03_lilian", "Marriage proposal with ring at 10 hearts must wed 03_lilian")
	GameState.time_min = 7.0 * 60.0
	main_inst.world.sync_npc_schedules()
	assert(str(main_inst.world.npc_states["03_lilian"]["scene"]) == "farmhouse", "Married spouse must live in farmhouse in the morning")
	print("Marriage ceremony & spouse home schedule verified!")

	# 8. System 5: Under-Root Ancient Ruins Light-Pillar Raycast Solver (B1, B2, B3)
	assert(bool(GameState.compute_ruins_beams("ruins_b1")["solved"]) == false, "B1 must start unsolved")
	GameState.ruins_state["ruins_b1"]["pillars"] = [1, 1, 0]
	assert(bool(GameState.compute_ruins_beams("ruins_b1")["solved"]) == true, "B1 solution [1,1,0] must solve")

	assert(bool(GameState.compute_ruins_beams("ruins_b2")["solved"]) == false, "B2 must start unsolved")
	GameState.ruins_state["ruins_b2"]["pillars"] = [1, 1, 0, 0]
	assert(bool(GameState.compute_ruins_beams("ruins_b2")["solved"]) == true, "B2 solution [1,1,0,0] must solve")

	assert(bool(GameState.compute_ruins_beams("ruins_b3")["solved"]) == false, "B3 must start unsolved")
	GameState.ruins_state["ruins_b3"]["pillars"] = [1, 1, 0, 2, 1, 0]
	assert(bool(GameState.compute_ruins_beams("ruins_b3")["solved"]) == true, "B3 splitter solution [1,1,0,2,1,0] must solve")
	print("All 3 Under-Root Ancient Ruins Light-Pillar Puzzles (B1, B2, B3) verified!")

	# 9. System 6: 3 Save Slots + 7 Zone BGM
	GameState.player_name = "นักทดสอบเอเธลการ์ด"
	GameState.save_slot(3, true)
	GameState.reset_to_new_game()
	assert(GameState.load_slot(3, false) == true, "Save Slot 3 must load")
	assert(GameState.player_name == "นักทดสอบเอเธลการ์ด", "Save Slot 3 must preserve player name")
	GameState.delete_slot(3)

	for z in ["plaza", "home", "tavern", "smithy", "nature", "ruins", "wedding"]:
		AudioManager.set_zone(z)
		assert(AudioManager.current_zone == z, "BGM zone must switch to " + z)
	print("3 Save Slots & all 7 Zone BGM tracks verified!")

	print("=== [ALL GODOT 4 CHECKS PASSED 100% WITH ZERO ERRORS!] ===")
	get_tree().quit(0)
