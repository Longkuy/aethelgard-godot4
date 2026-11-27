extends Node
## GameState Autoload — Manages 3 Save Slots, 8-Race Protagonist + Perks, Marriage & Spouse Life,
## Grid Furniture Placement & 2nd Floor Loft, 3-Floor Under-Root Ancient Ruins Light Puzzles,
## Social Stats, Quests, 15 Chronicles, 5 Landmarks, 12 Museum Relics, and Daily Loop.

signal hud_updated
signal toast_requested(msg: String)
signal scene_change_requested(scene_id: String, spawn_tile: Vector2i)
signal day_summary_requested
signal cutscene_requested(cs_id: String)

const SAVE_PATH_FMT := "user://aethelgard_slot_%d.json"
const SEASONS := ["ใบไม้ผลิ", "ฤดูร้อน", "ใบไม้ร่วง", "ฤดูหนาว"]
const WEEKDAYS := ["จ.", "อ.", "พ.", "พฤ.", "ศ.", "ส.", "อา."]
const SKIN_MODES := {"none": 0, "warm": 1, "tan": 2, "pale": 3, "drow": 4, "goblin": 5, "aqua": 6}

var active_slot: int = 1
var started: bool = false
var current_scene: String = "outdoor"
var return_outdoor_pos: Vector2 = Vector2(42.5 * 32.0, 31.5 * 32.0)

var player_name: String = "อาริน"
var cottage_name: String = "กระท่อมรากไม้ทอง"
var fav_thing: String = "ครัวซองต์น้ำผึ้ง"
var hero_custom: Dictionary = {
	"base_id": "01_ren",
	"race_key": "human",
	"hue": 0.0,
	"sat": 100.0,
	"val": 100.0,
	"skin": "none"
}
var owned_accessories: Dictionary = {"acc_none": true, "acc_straw_hat": true}
var equipped_accessory: String = "acc_straw_hat"
var owned_outfits: Dictionary = {"outfit_traveler": true}
var equipped_outfit: String = "outfit_traveler"

var pet_kind: String = "cat"
var pet_petted_today: bool = false

var day: int = 1
var time_min: float = 8.0 * 60.0
var weather: String = "sunny"
var gold: int = 600
var stamina: int = 100

var stats: Dictionary = {"charm": 10, "craft": 10, "wisdom": 10, "courage": 10}
var inventory: Dictionary = {}
var relations: Dictionary = {}
var partners: Dictionary = {}
var spouse_id: String = ""
var wedding_day: int = 0
var spouse_cared_day: int = 0
var spouse_dated_day: int = 0
var child_data: Dictionary = {"born": false, "name": "ลูมิน่า", "days_old": 0, "stage": 0, "cared_day": 0}

var house_level: int = 1
var decor_owned: Dictionary = {}
var decor_placed: Array = []
var decor_used_day: Dictionary = {}
var home_edit_mode: bool = false
var selected_decor_id: String = "decor_mirror"
var selected_decor_rot: int = 0

var ruins_state: Dictionary = {}
var boss_purified: bool = false
var boss_hp: int = 3
var boss_max_hp: int = 3
var purified_wisps_floor: Dictionary = {}

var quests_state: Dictionary = {}
var played_events: Dictionary = {}
var worked_today: Dictionary = {}
var landmarks_built: Dictionary = {}
var museum_donated: Dictionary = {}
var museum_milestones_claimed: Dictionary = {}
var sell_bonus_pct: int = 0
var chronicles_done: Dictionary = {}
var watched_cutscenes: Dictionary = {}
var achievements_unlocked: Dictionary = {}
var landmark_used_day: Dictionary = {}
var talked_ever: Dictionary = {}
var mailbox: Array = []
var delivered_mail_ids: Dictionary = {}
var forage_spots: Array = []
var farm_plots: Dictionary = {} # "x,y" -> {"tilled": bool, "crop_id": String, "days": int, "watered": bool}
var seeds: Dictionary = {}
var selected_seed_id: String = "crop_sunwheat"

var night_lantern_on: bool = false
var night_lantern_steps: int = 0
var visited_tavern_night: bool = false
var meteor_shower_tonight: bool = false
var festival_joined_day: int = 0

var total_shifts: int = 0
var s_rank_jobs: int = 0
var fish_caught: int = 0
var foraged_count: int = 0
var crafted_count: int = 0
var crops_harvested: int = 0
var compass_npc_id: String = ""
var daily_log: Dictionary = {"gold": 0, "hearts": 0, "stats": 0, "items": 0}

func _ready() -> void:
	reset_to_new_game()
	if has_save_slot(1):
		load_slot(1, false)

func reset_to_new_game() -> void:
	day = 1
	time_min = 8.0 * 60.0
	weather = "sunny"
	gold = 600
	player_name = "อาริน"
	cottage_name = "กระท่อมรากไม้ทอง"
	fav_thing = "ครัวซองต์น้ำผึ้ง"
	hero_custom = {"base_id": "01_ren", "race_key": "human", "hue": 0.0, "sat": 100.0, "val": 100.0, "skin": "none"}
	owned_accessories = {"acc_none": true, "acc_straw_hat": true}
	equipped_accessory = "acc_straw_hat"
	owned_outfits = {"outfit_traveler": true}
	equipped_outfit = "outfit_traveler"
	pet_kind = "cat"
	pet_petted_today = false
	stats = {"charm": 10, "craft": 10, "wisdom": 10, "courage": 10}
	inventory = {
		"item_honey_croissant": 2,
		"item_wild_honey": 2,
		"item_rich_milk": 1,
		"item_roasted_coffee": 1,
		"item_emerald_tea": 1,
		"item_hard_oak": 1
	}
	seeds = {
		"crop_sunwheat": 4,
		"crop_rootdew": 3,
		"crop_moonbloom": 2
	}
	selected_seed_id = "crop_sunwheat"
	farm_plots.clear()
	for fy in range(11, 14):
		for fx in range(21, 27):
			farm_plots["%d,%d" % [fx, fy]] = {"tilled": false, "crop_id": "", "days": 0, "watered": false}
	relations.clear()
	for c in GameData.characters:
		relations[c["id"]] = {"xp": 120, "talked_today": false, "gifted_today": false}
	partners.clear()
	spouse_id = ""
	wedding_day = 0
	spouse_cared_day = 0
	spouse_dated_day = 0
	child_data = {"born": false, "name": "ลูมิน่า", "days_old": 0, "stage": 0, "cared_day": 0}
	house_level = 1
	decor_owned = {"decor_mirror": true}
	decor_placed = [{"id": "decor_mirror", "scene": "farmhouse", "x": 4, "y": 2, "w": 1, "h": 2}]
	decor_used_day.clear()
	ruins_state.clear()
	for fid in GameData.RUINS_FLOORS.keys():
		var fl: Dictionary = GameData.RUINS_FLOORS[fid]
		var init_p: Array = []
		for p in fl["pillars"]:
			init_p.append(int(p["init"]))
		ruins_state[fid] = {"pillars": init_p, "solved": false, "chest_opened": false, "mined_day": {}}
	boss_purified = false
	boss_hp = boss_max_hp
	purified_wisps_floor.clear()
	quests_state = {"q01_welcome": "accepted"}
	played_events.clear()
	worked_today.clear()
	landmarks_built.clear()
	museum_donated.clear()
	museum_milestones_claimed.clear()
	sell_bonus_pct = 0
	chronicles_done.clear()
	watched_cutscenes.clear()
	achievements_unlocked.clear()
	landmark_used_day.clear()
	talked_ever.clear()
	delivered_mail_ids = {"mail_d1": true}
	night_lantern_on = false
	night_lantern_steps = 0
	visited_tavern_night = false
	meteor_shower_tonight = false
	festival_joined_day = 0
	crops_harvested = 0
	mailbox = [
		{
			"id": "mail_d1",
			"sender": "คุณปู่บราม (โรงเตี๊ยมตะเกียงมอส)",
			"title": "ยินดีต้อนรับสู่กระท่อมหลังใหม่!",
			"body": "ฮ่าๆๆ ยินดีต้อนรับสู่หุบเขาต้นไม้โลกนะ! ข้างบ้านมีแปลงสวนมานาให้ปลูกพืชรดน้ำด้วย ลองกด [E] ปลูกเมล็ด หรือกด [H] แต่งบ้านบนตารางได้เลย!",
			"gift_id": "item_honey_bread",
			"gold": 80,
			"claimed": false
		}
	]
	spawn_daily_forage()
	stamina = get_max_stamina()
	daily_log = {"gold": 0, "hearts": 0, "stats": 0, "items": 0}
	hud_updated.emit()

func spawn_daily_forage() -> void:
	var cands := [
		{"tx": 18, "ty": 24, "item_id": "item_wild_honey"},
		{"tx": 22, "ty": 39, "item_id": "item_rootdew_flower"},
		{"tx": 29, "ty": 44, "item_id": "item_moonbloom"},
		{"tx": 35, "ty": 20, "item_id": "item_sunfruit"},
		{"tx": 49, "ty": 35, "item_id": "item_wild_honey"},
		{"tx": 61, "ty": 29, "item_id": "item_hard_oak"},
		{"tx": 72, "ty": 24, "item_id": "item_ember_ore"},
		{"tx": 67, "ty": 38, "item_id": "item_starfall_crystal"},
		{"tx": 37, "ty": 52, "item_id": "item_glowing_shell"},
		{"tx": 47, "ty": 48, "item_id": "item_water_lily"}
	]
	cands.shuffle()
	forage_spots.clear()
	var count := 10 if meteor_shower_tonight else 8
	for i in range(mini(count, cands.size())):
		var sp: Dictionary = cands[i].duplicate()
		if meteor_shower_tonight and i < 2:
			sp["item_id"] = "item_starfall_crystal"
		sp["collected"] = false
		forage_spots.append(sp)

# --- 3 SAVE SLOTS ---
func has_save_slot(slot_num: int) -> bool:
	return FileAccess.file_exists(SAVE_PATH_FMT % slot_num)

func read_slot_summary(slot_num: int) -> Dictionary:
	var p := SAVE_PATH_FMT % slot_num
	if not FileAccess.file_exists(p):
		return {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
	return d if typeof(d) == TYPE_DICTIONARY else {}

func save_slot(slot_num: int = active_slot, silent: bool = false) -> void:
	active_slot = slot_num
	hero_custom["race_key"] = GameData.get_char_race_key(str(hero_custom.get("base_id", "01_ren")))
	var payload := {
		"version": "7.0",
		"day": day, "time_min": time_min, "weather": weather,
		"gold": gold, "stamina": stamina,
		"player_name": player_name, "cottage_name": cottage_name, "fav_thing": fav_thing,
		"hero_custom": hero_custom,
		"owned_accessories": owned_accessories, "equipped_accessory": equipped_accessory,
		"owned_outfits": owned_outfits, "equipped_outfit": equipped_outfit,
		"pet_kind": pet_kind,
		"stats": stats, "inventory": inventory, "relations": relations,
		"partners": partners, "spouse_id": spouse_id, "wedding_day": wedding_day,
		"spouse_cared_day": spouse_cared_day, "spouse_dated_day": spouse_dated_day,
		"child_data": child_data,
		"house_level": house_level, "decor_owned": decor_owned, "decor_placed": decor_placed,
		"ruins_state": ruins_state, "boss_purified": boss_purified, "boss_hp": boss_hp,
		"quests_state": quests_state,
		"played_events": played_events, "worked_today": worked_today,
		"landmarks_built": landmarks_built, "museum_donated": museum_donated,
		"museum_milestones_claimed": museum_milestones_claimed, "sell_bonus_pct": sell_bonus_pct,
		"chronicles_done": chronicles_done, "watched_cutscenes": watched_cutscenes,
		"achievements_unlocked": achievements_unlocked, "talked_ever": talked_ever,
		"night_lantern_steps": night_lantern_steps, "visited_tavern_night": visited_tavern_night,
		"festival_joined_day": festival_joined_day,
		"farm_plots": farm_plots, "seeds": seeds, "selected_seed_id": selected_seed_id,
		"crops_harvested": crops_harvested, "delivered_mail_ids": delivered_mail_ids,
		"decor_used_day": decor_used_day, "landmark_used_day": landmark_used_day,
		"mailbox": mailbox, "total_shifts": total_shifts, "s_rank_jobs": s_rank_jobs,
		"fish_caught": fish_caught, "foraged_count": foraged_count, "crafted_count": crafted_count
	}
	var f := FileAccess.open(SAVE_PATH_FMT % slot_num, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()
	if not silent:
		AudioManager.play_sfx("coin")
		toast_requested.emit("บันทึกเกมลง [ช่องเซฟ %d] เรียบร้อยแล้ว!" % slot_num)
	hud_updated.emit()

func load_slot(slot_num: int, announce: bool = true) -> bool:
	active_slot = slot_num
	var d := read_slot_summary(slot_num)
	if d.is_empty():
		reset_to_new_game()
		if announce:
			toast_requested.emit("เลือกช่องเซฟ %d (เริ่มเกมใหม่)" % slot_num)
		return false
	reset_to_new_game()
	day = int(d.get("day", 1))
	time_min = float(d.get("time_min", 480.0))
	weather = str(d.get("weather", "sunny"))
	gold = int(d.get("gold", 600))
	stamina = int(d.get("stamina", 100))
	player_name = str(d.get("player_name", "อาริน"))
	cottage_name = str(d.get("cottage_name", "กระท่อมรากไม้ทอง"))
	fav_thing = str(d.get("fav_thing", "ครัวซองต์น้ำผึ้ง"))
	if d.has("hero_custom"):
		hero_custom.merge(d["hero_custom"], true)
	hero_custom["race_key"] = GameData.get_char_race_key(str(hero_custom.get("base_id", "01_ren")))
	if d.has("owned_accessories"): owned_accessories.merge(d["owned_accessories"], true)
	equipped_accessory = str(d.get("equipped_accessory", "acc_straw_hat"))
	if d.has("owned_outfits"): owned_outfits.merge(d["owned_outfits"], true)
	equipped_outfit = str(d.get("equipped_outfit", "outfit_traveler"))
	pet_kind = str(d.get("pet_kind", "cat"))
	if d.has("stats"): stats.merge(d["stats"], true)
	if d.has("inventory"): inventory = d["inventory"].duplicate(true)
	if d.has("relations"): relations.merge(d["relations"], true)
	if d.has("partners"): partners = d["partners"].duplicate(true)
	spouse_id = str(d.get("spouse_id", ""))
	wedding_day = int(d.get("wedding_day", 0))
	spouse_cared_day = int(d.get("spouse_cared_day", 0))
	spouse_dated_day = int(d.get("spouse_dated_day", 0))
	if d.has("child_data"): child_data.merge(d["child_data"], true)
	house_level = int(d.get("house_level", 1))
	if d.has("decor_owned"): decor_owned.merge(d["decor_owned"], true)
	if d.has("decor_placed"): decor_placed = d["decor_placed"].duplicate(true)
	if d.has("decor_used_day"): decor_used_day = d["decor_used_day"].duplicate(true)
	if d.has("landmark_used_day"): landmark_used_day = d["landmark_used_day"].duplicate(true)
	if d.has("ruins_state"):
		for k in d["ruins_state"].keys():
			if ruins_state.has(k):
				ruins_state[k].merge(d["ruins_state"][k], true)
	boss_purified = bool(d.get("boss_purified", false))
	boss_hp = int(d.get("boss_hp", 0 if boss_purified else boss_max_hp))
	if d.has("quests_state"): quests_state.merge(d["quests_state"], true)
	if d.has("played_events"): played_events = d["played_events"].duplicate(true)
	if d.has("worked_today"): worked_today = d["worked_today"].duplicate(true)
	if d.has("landmarks_built"): landmarks_built = d["landmarks_built"].duplicate(true)
	if d.has("museum_donated"): museum_donated = d["museum_donated"].duplicate(true)
	if d.has("museum_milestones_claimed"): museum_milestones_claimed = d["museum_milestones_claimed"].duplicate(true)
	sell_bonus_pct = int(d.get("sell_bonus_pct", 0))
	if d.has("chronicles_done"): chronicles_done = d["chronicles_done"].duplicate(true)
	if d.has("watched_cutscenes"): watched_cutscenes = d["watched_cutscenes"].duplicate(true)
	if d.has("achievements_unlocked"): achievements_unlocked = d["achievements_unlocked"].duplicate(true)
	if d.has("talked_ever"): talked_ever = d["talked_ever"].duplicate(true)
	if d.has("farm_plots"): farm_plots.merge(d["farm_plots"], true)
	if d.has("seeds"): seeds = d["seeds"].duplicate(true)
	selected_seed_id = str(d.get("selected_seed_id", "crop_sunwheat"))
	crops_harvested = int(d.get("crops_harvested", 0))
	if d.has("delivered_mail_ids"): delivered_mail_ids.merge(d["delivered_mail_ids"], true)
	night_lantern_steps = int(d.get("night_lantern_steps", 0))
	visited_tavern_night = bool(d.get("visited_tavern_night", false))
	festival_joined_day = int(d.get("festival_joined_day", 0))
	if d.has("mailbox"): mailbox = d["mailbox"].duplicate(true)
	total_shifts = int(d.get("total_shifts", 0))
	s_rank_jobs = int(d.get("s_rank_jobs", 0))
	fish_caught = int(d.get("fish_caught", 0))
	foraged_count = int(d.get("foraged_count", 0))
	crafted_count = int(d.get("crafted_count", 0))
	if announce:
		AudioManager.play_sfx("quest")
		toast_requested.emit("โหลดข้อมูล [ช่องเซฟ %d: %s] สำเร็จ!" % [slot_num, player_name])
	hud_updated.emit()
	return true

func delete_slot(slot_num: int) -> void:
	var p := SAVE_PATH_FMT % slot_num
	if FileAccess.file_exists(p):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	hud_updated.emit()

# --- STATS, PERKS & HELPERS ---
func get_season_index() -> int:
	return ((day - 1) / 28) % 4

func get_day_of_season() -> int:
	return ((day - 1) % 28) + 1

func get_season_name() -> String:
	return SEASONS[get_season_index()]

func get_weekday_name() -> String:
	return WEEKDAYS[(day - 1) % 7]

func format_text(txt: String) -> String:
	return txt.replace("{player}", player_name).replace("{farm}", cottage_name).replace("{fav}", fav_thing)

func get_stat_level(stat_id: String) -> int:
	var xp := int(stats.get(stat_id, 0))
	for s in GameData.social_stats:
		if s["id"] == stat_id:
			var lv := 1
			for l in s["levels"]:
				if xp >= int(l["xp_required"]):
					lv = int(l["level"])
			return lv
	return 1

func has_placed_decor(did: String) -> bool:
	for p in decor_placed:
		if str(p.get("id", "")) == did:
			return true
	return false

func get_max_stamina() -> int:
	var mx := 100
	if get_stat_level("courage") >= 4: mx += 20
	if has_placed_decor("decor_plush_bed") or decor_owned.has("decor_plush_bed"): mx += 20
	if has_placed_decor("decor_sofa") or decor_owned.has("decor_sofa"): mx += 10
	if house_level >= 2: mx += 15
	if str(hero_custom.get("race_key", "human")) == "dwarf": mx += 15
	if spouse_id != "": mx += 10
	return mx

func get_stamina_cost(raw: int) -> int:
	if str(hero_custom.get("race_key", "human")) == "vampire" and (time_min >= 18.0 * 60.0 or time_min < 6.0 * 60.0):
		return maxi(1, int(round(raw * 0.75)))
	return raw

func add_gold(amount: int) -> void:
	gold += amount
	if amount > 0:
		daily_log["gold"] = int(daily_log["gold"]) + amount
	hud_updated.emit()

func add_item(item_id: String, qty: int = 1) -> void:
	var cur := int(inventory.get(item_id, 0)) + qty
	if cur <= 0:
		inventory.erase(item_id)
	else:
		inventory[item_id] = cur
	if qty > 0:
		daily_log["items"] = int(daily_log["items"]) + qty
	hud_updated.emit()

func add_stat_xp(gains: Dictionary) -> void:
	var mult := 1.1 if str(hero_custom.get("race_key", "human")) == "human" else 1.0
	for k in gains.keys():
		var g := maxi(1, int(round(float(gains[k]) * mult)))
		stats[k] = int(stats.get(k, 0)) + g
		daily_log["stats"] = int(daily_log["stats"]) + g
	hud_updated.emit()

func get_hearts(cid: String) -> int:
	var xp := int(relations.get(cid, {}).get("xp", 0))
	return mini(10, xp / 100)

func add_friendship(cid: String, delta: int) -> int:
	if not relations.has(cid):
		relations[cid] = {"xp": 0, "talked_today": false, "gifted_today": false}
	var gain := int(round(delta * 1.2)) if (delta > 0 and get_stat_level("charm") >= 4) else delta
	relations[cid]["xp"] = clampi(int(relations[cid]["xp"]) + gain, 0, 1000)
	if gain > 0:
		daily_log["hearts"] = int(daily_log["hearts"]) + gain
	hud_updated.emit()
	return gain

func get_awakened_seal_count() -> int:
	var pairs := [
		["01_ren", "02_marcus"], ["03_lilian", "04_eli"], ["05_kyo", "06_sora"], ["07_sera", "08_roland"],
		["09_celeste", "10_lucian"], ["11_pip", "12_trixie"], ["13_mirelle", "14_kael"], ["15_thorn", "16_bram"]
	]
	var cnt := 0
	for p in pairs:
		if get_hearts(p[0]) >= 3 or get_hearts(p[1]) >= 3:
			cnt += 1
	return cnt

# --- SYSTEM 4: GRID FURNITURE & 2ND FLOOR LOFT ---
func upgrade_second_floor() -> bool:
	if house_level >= 2:
		return false
	if gold < 600:
		toast_requested.emit("เงินไม่พอ! ต้องการ 600 G เพื่อขยายบ้านชั้น 2")
		return false
	if int(inventory.get("item_hard_oak", 0)) < 2:
		toast_requested.emit("ต้องการ 'ไม้โอ๊กเนื้อแข็ง' x2 ชิ้น")
		return false
	gold -= 600
	add_item("item_hard_oak", -2)
	house_level = 2
	add_stat_xp({"craft": 20, "charm": 15})
	AudioManager.play_sfx("build")
	save_slot(active_slot, true)
	toast_requested.emit("ต่อเติม 'ชั้น 2 ห้องใต้หลังคาชมดาว (Starlight Loft)' สำเร็จแล้ว!")
	return true

func get_decor_def(did: String) -> Dictionary:
	for d in GameData.HOME_DECOR:
		if d["id"] == did:
			return d
	return {}

func can_place_decor_at(did: String, scene_id: String, tx: int, ty: int, w: int, h: int) -> bool:
	var rw := 14 if scene_id == "farmhouse_upstairs" else 16
	var rh := 10 if scene_id == "farmhouse_upstairs" else 12
	if tx < 1 or ty < 2 or tx + w > rw - 1 or ty + h > rh - 1:
		return false
	# Keep bed (x=2..4, y=3..5), exit, and stairs clear
	if tx < 5 and ty < 6 and scene_id in ["farmhouse", "farmhouse_upstairs"]:
		if tx < 4 and ty >= 3:
			return false
	var exit_x := 11 if scene_id == "farmhouse_upstairs" else 8
	var exit_y := 8 if scene_id == "farmhouse_upstairs" else 10
	if tx <= exit_x and exit_x < tx + w and ty <= exit_y and exit_y - 1 < ty + h:
		return false
	if scene_id == "farmhouse" and tx + w > 12 and ty < 4:
		return false
	for p in decor_placed:
		if str(p["scene"]) != scene_id or str(p["id"]) == did:
			continue
		if tx < int(p["x"]) + int(p["w"]) and tx + w > int(p["x"]) and ty < int(p["y"]) + int(p["h"]) and ty + h > int(p["y"]):
			return false
	return true

func place_decor_on_grid(did: String, scene_id: String, tx: int, ty: int, rot: int) -> bool:
	var d := get_decor_def(did)
	if d.is_empty() or not decor_owned.has(did):
		return false
	var w := int(d["h"]) if rot == 1 else int(d["w"])
	var h := int(d["w"]) if rot == 1 else int(d["h"])
	if not can_place_decor_at(did, scene_id, tx, ty, w, h):
		AudioManager.play_sfx("miss")
		toast_requested.emit("ช่องนี้ติดผนังหรือทับเฟอร์นิเจอร์ชิ้นอื่น ลองขยับไปช่องว่างนะ!")
		return false
	for i in range(decor_placed.size() - 1, -1, -1):
		if str(decor_placed[i]["id"]) == did:
			decor_placed.remove_at(i)
	decor_placed.append({"id": did, "scene": scene_id, "x": tx, "y": ty, "w": w, "h": h})
	AudioManager.play_sfx("build")
	save_slot(active_slot, true)
	hud_updated.emit()
	return true

func remove_decor_at_tile(scene_id: String, tx: int, ty: int) -> bool:
	for i in range(decor_placed.size() - 1, -1, -1):
		var p: Dictionary = decor_placed[i]
		if str(p["scene"]) == scene_id and tx >= int(p["x"]) and tx < int(p["x"]) + int(p["w"]) and ty >= int(p["y"]) and ty < int(p["y"]) + int(p["h"]):
			var d := get_decor_def(str(p["id"]))
			decor_placed.remove_at(i)
			AudioManager.play_sfx("door")
			toast_requested.emit("เก็บ '%s' เข้าคลังเฟอร์นิเจอร์แล้ว" % d.get("label", ""))
			save_slot(active_slot, true)
			hud_updated.emit()
			return true
	return false

# --- SYSTEM 5: ANCIENT RUINS LIGHT-PILLAR PRISM RAYCAST SOLVER ---
func compute_ruins_beams(floor_id: String) -> Dictionary:
	if not GameData.RUINS_FLOORS.has(floor_id):
		return {"segments": [], "lit_indices": [], "solved": false}
	var fl: Dictionary = GameData.RUINS_FLOORS[floor_id]
	var rs: Dictionary = ruins_state[floor_id]
	var p_states: Array = rs["pillars"]
	var dirs := [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(1, 0)] # 0=UP, 1=LEFT, 2=DOWN, 3=RIGHT
	var reflect_0 := {3: [0], 0: [3], 1: [2], 2: [1]} # '/'
	var reflect_1 := {3: [2], 2: [3], 1: [0], 0: [1]} # '\'
	var reflect_2 := {0: [1, 3], 2: [1, 3], 1: [0, 2], 3: [0, 2]} # '✦'

	var segments: Array = []
	var lit_indices: Array[int] = []
	var visited: Dictionary = {}
	var queue: Array = []
	for em in fl["emitters"]:
		queue.append({"x": int(em["x"]), "y": int(em["y"]), "dir": int(em["dir"]), "color": str(em["color"]), "depth": 0})

	while not queue.is_empty():
		var ray: Dictionary = queue.pop_front()
		if int(ray["depth"]) > 24:
			continue
		var dvec: Vector2i = dirs[int(ray["dir"])]
		var cx := int(ray["x"])
		var cy := int(ray["y"])
		for _step in range(30):
			var nx := cx + dvec.x
			var ny := cy + dvec.y
			if nx < 1 or ny < 2 or nx >= int(fl["w"]) - 1 or ny >= int(fl["h"]) - 1:
				segments.append({"p1": Vector2i(ray["x"], ray["y"]), "p2": Vector2i(nx, ny), "color": ray["color"]})
				break
			var hit_block := false
			for b in fl["blocks"]:
				if int(b["x"]) == nx and int(b["y"]) == ny:
					hit_block = true
					break
			if hit_block:
				segments.append({"p1": Vector2i(ray["x"], ray["y"]), "p2": Vector2i(nx, ny), "color": ray["color"]})
				break
			var rec_hit := -1
			for ri in range(fl["receptors"].size()):
				var rc: Dictionary = fl["receptors"][ri]
				if int(rc["x"]) == nx and int(rc["y"]) == ny:
					rec_hit = ri
					break
			if rec_hit >= 0:
				if not lit_indices.has(rec_hit):
					lit_indices.append(rec_hit)
				segments.append({"p1": Vector2i(ray["x"], ray["y"]), "p2": Vector2i(nx, ny), "color": ray["color"]})
				break
			var pil_hit := -1
			for pi in range(fl["pillars"].size()):
				var pl: Dictionary = fl["pillars"][pi]
				if int(pl["x"]) == nx and int(pl["y"]) == ny:
					pil_hit = pi
					break
			if pil_hit >= 0:
				segments.append({"p1": Vector2i(ray["x"], ray["y"]), "p2": Vector2i(nx, ny), "color": ray["color"]})
				var m_state := int(p_states[pil_hit])
				var next_dirs: Array = []
				if m_state == 0: next_dirs = reflect_0.get(int(ray["dir"]), [])
				elif m_state == 1: next_dirs = reflect_1.get(int(ray["dir"]), [])
				else: next_dirs = reflect_2.get(int(ray["dir"]), [])
				for nd in next_dirs:
					var vk := "%d,%d,%d" % [nx, ny, int(nd)]
					if not visited.has(vk):
						visited[vk] = true
						queue.append({"x": nx, "y": ny, "dir": int(nd), "color": ray["color"], "depth": int(ray["depth"]) + 1})
				break
			cx = nx
			cy = ny

	var rec_list: Array = fl["receptors"]
	var all_lit: bool = (lit_indices.size() == rec_list.size()) and (rec_list.size() > 0)
	if all_lit and not bool(rs["solved"]):
		rs["solved"] = true
		AudioManager.play_sfx("quest")
		add_stat_xp({"wisdom": 15, "courage": 10})
		save_slot(active_slot, true)
		toast_requested.emit("ปลดผนึกเสาแสง '%s' สำเร็จ! หีบสมบัติและบันไดเปิดออกแล้ว!" % fl["name_th"])
	return {"segments": segments, "lit_indices": lit_indices, "solved": bool(rs["solved"])}

func rotate_ruins_pillar(floor_id: String, idx: int) -> void:
	var fl: Dictionary = GameData.RUINS_FLOORS[floor_id]
	var rs: Dictionary = ruins_state[floor_id]
	var mx := int(fl["pillars"][idx]["max_states"])
	rs["pillars"][idx] = (int(rs["pillars"][idx]) + 1) % mx
	AudioManager.play_sfx("beam")
	compute_ruins_beams(floor_id)

func reset_ruins_floor(floor_id: String) -> void:
	if not GameData.RUINS_FLOORS.has(floor_id):
		return
	var fl: Dictionary = GameData.RUINS_FLOORS[floor_id]
	var arr: Array = []
	for p in fl["pillars"]:
		arr.append(int(p["init"]))
	ruins_state[floor_id]["pillars"] = arr
	AudioManager.play_sfx("beam")

func get_buy_price(raw_price: int, is_night_market: bool = false) -> int:
	var mult := 1.0
	if str(hero_custom.get("race_key", "human")) == "goblin":
		mult *= 0.92
	if get_day_of_season() == 21:
		mult *= 0.80
	if is_night_market and ((day - 1) % 7) in [4, 5, 6]:
		mult *= 0.75
	return maxi(1, int(round(float(raw_price) * mult)))

func get_sell_price(raw_sell: int) -> int:
	var mult := 1.0 + float(sell_bonus_pct) / 100.0
	if str(hero_custom.get("race_key", "human")) == "goblin":
		mult *= 1.10
	return maxi(1, int(round(float(raw_sell) * mult)))

# --- CHILD & FAMILY SYSTEM (3 GROWTH STAGES) ---
func trigger_child_birth(custom_name: String = "") -> bool:
	if spouse_id == "" or bool(child_data.get("born", false)):
		return false
	if custom_name.strip_edges() != "":
		child_data["name"] = custom_name.strip_edges()
	child_data["born"] = true
	child_data["days_old"] = 0
	child_data["stage"] = 1
	child_data["cared_day"] = 0
	add_stat_xp({"charm": 25, "wisdom": 15})
	check_achievements()
	save_slot(active_slot, true)
	cutscene_requested.emit("cs_child_birth")
	return true

func interact_with_child() -> String:
	if not bool(child_data.get("born", false)):
		return ""
	var cname := str(child_data.get("name", "ลูมิน่า"))
	var stg := int(child_data.get("stage", 1))
	if int(child_data.get("cared_day", 0)) != day:
		child_data["cared_day"] = day
		stamina = mini(get_max_stamina(), stamina + 18)
		add_stat_xp({"charm": 10, "courage": 6})
		if spouse_id != "":
			add_friendship(spouse_id, 25)
		AudioManager.play_sfx("heart")
		save_slot(active_slot, true)
		if stg == 1:
			return "คุณอุ้มกล่อม '%s' ในเปลไม้รากไม้โลก ทารกน้อยยิ้มตาหยีอย่างอบอุ่น! (+18⚡ +10 เสน่ห์)" % cname
		elif stg == 2:
			return "'%s' วิ่งเตาะแตะมากอดขาคุณแล้วหัวเราะคิกคัก! (+18⚡ +10 เสน่ห์)" % cname
		return "นักสำรวจน้อย '%s' อวดใบไม้สีทองที่เก็บมาฝากคุณด้วยความภูมิใจ! (+18⚡ +10 เสน่ห์)" % cname
	return "'%s' กำลังอารมณ์ดีและยิ้มสดใสให้คุณ!" % cname

# --- COZY DUNGEON SHADOW WISPS & FLOOR B4 BOSS PURIFICATION ---
func purify_boss_damage() -> String:
	if boss_purified:
		return "already_purified"
	var rs4: Dictionary = ruins_state.get("ruins_b4", {})
	if not bool(rs4.get("solved", false)):
		AudioManager.play_sfx("miss")
		toast_requested.emit("เกราะเงามืดยังขวางอยู่! หมุนเสาปริซึมทั้ง 4 ต้นให้ลำแสงทำลายเกราะบอสก่อน!")
		return "shielded"
	boss_hp = maxi(0, boss_hp - 1)
	AudioManager.play_sfx("beam")
	if boss_hp <= 0:
		boss_purified = true
		owned_accessories["acc_royal_crown"] = true
		add_gold(600)
		add_stat_xp({"courage": 35, "wisdom": 25})
		check_achievements()
		save_slot(active_slot, true)
		cutscene_requested.emit("cs_boss_purified")
		return "purified"
	toast_requested.emit("คลื่นแสงศักดิ์สิทธิ์ชำระล้างผู้พิทักษ์! (พลังเงามืดเหลือ %d/%d — กด [F] ต่อ!)" % [boss_hp, boss_max_hp])
	hud_updated.emit()
	return "hit"

# --- FULL PARITY: CHAPTER UNLOCKS, QUESTS, LANDMARKS, MUSEUM & FESTIVALS ---
func is_chapter_unlocked(ch: Dictionary) -> bool:
	var u: Dictionary = ch.get("unlock", {"type": "always"})
	var utype := str(u.get("type", "always"))
	match utype:
		"always":
			return true
		"main_prog":
			var prev_ok := chronicles_done.has(str(u.get("prev", "")))
			var arr: Array = u.get("min_seals_or_day", [1, 2])
			return prev_ok and (get_awakened_seal_count() >= int(arr[0]) or day >= int(arr[1]))
		"main_ch4_cond":
			return chronicles_done.has("main_ch3") and (landmarks_built.size() >= 1 or get_awakened_seal_count() >= 5 or day >= 6)
		"main_finale":
			return chronicles_done.has("main_ch4") and (landmarks_built.size() >= 2 or get_awakened_seal_count() >= 6 or day >= 8)
		"prev_or_day":
			return chronicles_done.has(str(u.get("prev", ""))) or day >= int(u.get("day", 2))
		"talked_pair":
			var p: Array = u.get("pair", [])
			if p.size() < 2:
				return true
			return talked_ever.has(str(p[0])) and talked_ever.has(str(p[1]))
		"season_or_obs":
			return get_season_index() == int(u.get("season_idx", 0)) or landmarks_built.has("lm_observatory")
		"season_or_heart":
			return get_season_index() == int(u.get("season_idx", 0)) or get_hearts(str(u.get("cid", "01_ren"))) >= int(u.get("hearts", 2))
	return true

func get_quest_progress(q: Dictionary) -> Dictionary:
	var obj: Dictionary = q.get("objective", {})
	var otype := str(obj.get("type", ""))
	match otype:
		"talk_npcs":
			var need := int(obj.get("count", 5))
			var cur := talked_ever.size()
			return {"done": cur >= need, "text": "คุยชาวเมือง %d/%d คน" % [mini(cur, need), need]}
		"work_shifts":
			var need2 := int(obj.get("count", 1))
			return {"done": total_shifts >= need2, "text": "ทำงานพาร์ทไทม์ %d/%d กะ" % [mini(total_shifts, need2), need2]}
		"have_item":
			var iid := str(obj.get("item_id", ""))
			var need3 := int(obj.get("count", 1))
			var have := int(inventory.get(iid, 0))
			var iname := str(GameData.item_by_id.get(iid, {}).get("name_th", obj.get("item", iid)))
			return {"done": have >= need3, "text": "มี %s %d/%d" % [iname, mini(have, need3), need3]}
		"inspect_night":
			var need4 := int(obj.get("count", 4))
			return {"done": night_lantern_steps >= need4, "text": "เดินถือตะเกียง [9] ยามค่ำ %d/%d จุด" % [mini(night_lantern_steps, need4), need4]}
		"attend_event":
			return {"done": visited_tavern_night, "text": "เข้าโรงเตี๊ยมหลัง 19:00 น. (%s)" % ("สำเร็จ!" if visited_tavern_night else "ยังไม่ได้เข้า")}
	return {"done": true, "text": "พร้อมส่งเควสต์"}

func complete_quest(q: Dictionary) -> bool:
	var qid := str(q["id"])
	if str(quests_state.get(qid, "open")) == "completed":
		return false
	var prog := get_quest_progress(q)
	if not bool(prog["done"]):
		toast_requested.emit("ยังไม่ครบเงื่อนไขเควสต์: " + str(prog["text"]))
		return false
	var obj: Dictionary = q.get("objective", {})
	if str(obj.get("type", "")) == "have_item":
		add_item(str(obj["item_id"]), -int(obj.get("count", 1)))
	quests_state[qid] = "completed"
	var rew: Dictionary = q.get("reward", {})
	if int(rew.get("gold", 0)) > 0:
		add_gold(int(rew["gold"]))
	if rew.has("item_id"):
		add_item(str(rew["item_id"]), 1)
	if int(rew.get("hearts_all", 0)) > 0:
		var ha := int(rew["hearts_all"]) * 40
		for c in GameData.characters:
			add_friendship(str(c["id"]), ha)
	if rew.has("hearts") and typeof(rew["hearts"]) == TYPE_DICTIONARY:
		var hd: Dictionary = rew["hearts"]
		for cid in hd.keys():
			add_friendship(str(cid), int(hd[cid]) * 50)
	AudioManager.play_sfx("quest")
	check_achievements()
	save_slot(active_slot, true)
	toast_requested.emit("ส่งเควสต์ '%s' สำเร็จ! รับรางวัลเรียบร้อย!" % str(q["title"]))
	return true

func can_build_landmark(lm: Dictionary) -> Dictionary:
	var cost := int(lm.get("gold_cost", 250))
	var mats: Dictionary = lm.get("materials", {})
	var parts: Array[String] = ["ทอง %d/%dG" % [gold, cost]]
	var ok := gold >= cost
	for iid in mats.keys():
		var req := int(mats[iid])
		var have := int(inventory.get(iid, 0))
		if have < req:
			ok = false
		parts.append("%s %d/%d" % [GameData.item_by_id.get(str(iid), {}).get("name_th", str(iid)), have, req])
	return {"ok": ok, "req_text": " + ".join(parts)}

func build_landmark(lm_id: String) -> bool:
	if landmarks_built.has(lm_id) or not GameData.landmark_by_id.has(lm_id):
		return false
	var lm: Dictionary = GameData.landmark_by_id[lm_id]
	var chk := can_build_landmark(lm)
	if not bool(chk["ok"]):
		toast_requested.emit("วัตถุดิบไม่พอ: " + str(chk["req_text"]))
		return false
	gold -= int(lm["gold_cost"])
	var mats: Dictionary = lm.get("materials", {})
	for iid in mats.keys():
		add_item(str(iid), -int(mats[iid]))
	landmarks_built[lm_id] = true
	for pid in lm.get("partners", []):
		add_friendship(str(pid), 60)
	add_stat_xp({"craft": 20, "charm": 15})
	AudioManager.play_sfx("build")
	check_achievements()
	save_slot(active_slot, true)
	var cs_key := "cs_" + lm_id
	if GameData.cutscenes_v7.has(cs_key):
		cutscene_requested.emit(cs_key)
	return true

func donate_museum_item(iid: String) -> bool:
	if museum_donated.has(iid) or int(inventory.get(iid, 0)) <= 0:
		return false
	add_item(iid, -1)
	museum_donated[iid] = true
	add_gold(60)
	add_stat_xp({"wisdom": 8})
	AudioManager.play_sfx("sparkle")
	var cnt := museum_donated.size()
	for ms in GameData.museum_milestones:
		var mc := int(ms["count"])
		var mkey := str(mc)
		if cnt >= mc and not museum_milestones_claimed.has(mkey):
			museum_milestones_claimed[mkey] = true
			add_gold(int(ms.get("gold", 0)))
			if ms.has("stat"):
				add_stat_xp(ms["stat"])
			if ms.has("item_id"):
				add_item(str(ms["item_id"]), 1)
			if int(ms.get("hearts_all", 0)) > 0:
				for c in GameData.characters:
					add_friendship(str(c["id"]), int(ms["hearts_all"]))
			if int(ms.get("sell_bonus_pct", 0)) > 0:
				sell_bonus_pct = maxi(sell_bonus_pct, int(ms["sell_bonus_pct"]))
			toast_requested.emit("บรรลุเป้าหมายพิพิธภัณฑ์ %s! (%s)" % [str(ms["title_th"]), str(ms["desc_th"])])
	check_achievements()
	save_slot(active_slot, true)
	if cnt >= 12 and GameData.cutscenes_v7.has("cs_museum_complete"):
		cutscene_requested.emit("cs_museum_complete")
	return true

func join_today_festival() -> bool:
	var dos := get_day_of_season()
	if not GameData.FESTIVALS.has(dos) or festival_joined_day == day:
		return false
	var fest: Dictionary = GameData.FESTIVALS[dos]
	festival_joined_day = day
	stamina = get_max_stamina()
	if int(fest.get("gold", 0)) > 0:
		add_gold(int(fest["gold"]))
	if fest.has("item_id"):
		add_item(str(fest["item_id"]), int(fest.get("item_qty", 1)))
	if fest.has("stat"):
		add_stat_xp(fest["stat"])
	var ha := int(fest.get("hearts_all", 30))
	for c in GameData.characters:
		add_friendship(str(c["id"]), ha)
	if dos == 28:
		meteor_shower_tonight = true
	save_slot(active_slot, true)
	cutscene_requested.emit(str(fest["id"]))
	return true

func check_achievements() -> void:
	var max_h := 0
	for c in GameData.characters:
		max_h = maxi(max_h, get_hearts(str(c["id"])))
	var conds := {
		"ach_welcome": talked_ever.size() >= 5,
		"ach_social_all": talked_ever.size() >= 16,
		"ach_first_job": total_shifts >= 1,
		"ach_s_rank": s_rank_jobs >= 3,
		"ach_angler": fish_caught >= 5,
		"ach_forager": foraged_count >= 10,
		"ach_chef": crafted_count >= 5,
		"ach_rich": gold >= 2000,
		"ach_loft": house_level >= 2,
		"ach_decorator": decor_placed.size() >= 4,
		"ach_fashion": (owned_accessories.size() + owned_outfits.size()) >= 5,
		"ach_bestie": max_h >= 5,
		"ach_lover": not partners.is_empty(),
		"ach_married": spouse_id != "",
		"ach_parent": bool(child_data.get("born", false)),
		"ach_child_grow": int(child_data.get("stage", 0)) >= 2,
		"ach_landmark_1": landmarks_built.size() >= 1,
		"ach_landmark_all": landmarks_built.size() >= 5,
		"ach_museum_half": museum_donated.size() >= 6,
		"ach_museum_all": museum_donated.size() >= 12,
		"ach_ruins_b1": bool(ruins_state.get("ruins_b1", {}).get("solved", false)),
		"ach_ruins_b3": bool(ruins_state.get("ruins_b3", {}).get("solved", false)),
		"ach_boss_b4": boss_purified,
		"ach_chronicle": chronicles_done.size() >= 5
	}
	for a in GameData.ACHIEVEMENTS:
		var aid := str(a["id"])
		if bool(conds.get(aid, false)) and not achievements_unlocked.has(aid):
			achievements_unlocked[aid] = true
			AudioManager.play_sfx("quest")
			toast_requested.emit("🏆 ปลดล็อกความสำเร็จ: %s!" % str(a["title_th"]))

# --- MANA GARDEN FARMING SYSTEM (18-TILE PLOT BESIDE FARMHOUSE) ---
func interact_farm_plot(tx: int, ty: int) -> String:
	var key := "%d,%d" % [tx, ty]
	if not farm_plots.has(key):
		return ""
	var pl: Dictionary = farm_plots[key]
	var cid := str(pl.get("crop_id", ""))
	if cid != "":
		var cdef := GameData.get_crop_def(cid)
		if int(pl.get("days", 0)) >= int(cdef["grow_days"]):
			var qty := 2 if (str(hero_custom.get("race_key", "")) == "elf" and randf() < 0.4) else 1
			add_item(str(cdef["harvest_item"]), qty)
			crops_harvested += qty
			pl["crop_id"] = ""
			pl["days"] = 0
			pl["watered"] = false
			add_stat_xp({"craft": 5, "wisdom": 3})
			AudioManager.play_sfx("sparkle")
			check_achievements()
			save_slot(active_slot, true)
			return "🌾 เก็บเกี่ยว '%s' x%d สำเร็จ!" % [str(cdef["name_th"]), qty]
		elif not bool(pl.get("watered", false)):
			var cost := get_stamina_cost(2)
			if stamina < cost:
				return "พลังงานไม่พอรดน้ำ!"
			stamina -= cost
			pl["watered"] = true
			AudioManager.play_sfx("splash")
			hud_updated.emit()
			return "💧 รดน้ำแปลง '%s' แล้ว! (%d/%d วัน)" % [str(cdef["name_th"]), int(pl["days"]), int(cdef["grow_days"])]
		return "🌱 '%s' รดน้ำแล้ว รอโตในวันพรุ่งนี้ (%d/%d วัน)" % [str(cdef["name_th"]), int(pl["days"]), int(cdef["grow_days"])]
	if not bool(pl.get("tilled", false)):
		var cost2 := get_stamina_cost(2)
		if stamina < cost2:
			return "พลังงานไม่พอพรวนดิน!"
		stamina -= cost2
		pl["tilled"] = true
		AudioManager.play_sfx("door")
		hud_updated.emit()
		return "⛏️ พรวนดินแปลงสวนมานาเรียบร้อย! กด [E] อีกครั้งเพื่อหว่านเมล็ด"
	# Plant selected seed (or auto-pick any owned seed)
	var use_seed := selected_seed_id
	if int(seeds.get(use_seed, 0)) <= 0:
		use_seed = ""
		for sk in seeds.keys():
			if int(seeds[sk]) > 0:
				use_seed = str(sk)
				selected_seed_id = use_seed
				break
	if use_seed == "":
		return "ไม่มีเมล็ดพันธุ์ในกระเป๋า! ซื้อเมล็ดได้ที่แท็บ '🌱 เมล็ดพันธุ์' ในเมนูร้านค้า"
	seeds[use_seed] = int(seeds[use_seed]) - 1
	if int(seeds[use_seed]) <= 0:
		seeds.erase(use_seed)
	pl["crop_id"] = use_seed
	pl["days"] = 0
	pl["watered"] = (weather == "rainy")
	AudioManager.play_sfx("sparkle")
	hud_updated.emit()
	return "🌱 ปลูกเมล็ด '%s' แล้ว! %s" % [str(GameData.get_crop_def(use_seed)["name_th"]), "(ฝนตกรดน้ำให้แล้ว!)" if bool(pl["watered"]) else "(กด [E] รดน้ำได้เลย)"]

func _deliver_scheduled_mail() -> void:
	var scheduled := [
		{"id": "mail_d2", "cond": day >= 2, "sender": "พิป โกลด์ลีฟ (ร้านชำ Goldleaf)", "title": "คูปองต้อนรับลูกค้าประจำ!", "body": "ฮิฮิ แวะมาอุดหนุนเมล็ดพันธุ์หรือของขวัญที่ร้านพิปได้ทุกวันนะ ส่งเงินขวัญถุงและเมล็ดพันธุ์มาให้ทดลองปลูกด้วย!", "gift_id": "item_sunfruit", "gold": 120},
		{"id": "mail_d3", "cond": day >= 3, "sender": "คาเอล ทอร์น (หน่วยสำรวจ)", "title": "เบาะแสโบราณสถานใต้รากไม้โลก", "body": "ทางเข้าโบราณสถานอยู่ฝั่งซ้ายของต้นไม้โลก ข้างในมีปริศนาเสาแสงและบอสผู้พิทักษ์ชั้น B4 พกอาหารเติมพลังไปด้วยล่ะ!", "gift_id": "item_honey_croissant", "gold": 100},
		{"id": "mail_d5", "cond": day >= 5, "sender": "เซร่า (Elderbark Bakery)", "title": "ครัวซองต์สูตรใหม่เพิ่งอบเสร็จเมี้ยว~", "body": "เซร่าแอบแบ่งครัวซองต์อุ่นๆ มาฝาก {player} ทานก่อนออกไปทำงานนะเมี้ยว!", "gift_id": "item_honey_croissant", "gold": 60},
		{"id": "mail_fest_eve", "cond": get_day_of_season() in [6, 13, 20, 27], "sender": "สภาเมืองแปดเผ่าพันธุ์", "title": "แจ้งเตือน: พรุ่งนี้มีเทศกาลประจำฤดู!", "body": "พรุ่งนี้ชาวเมืองทั้ง 8 เผ่าจะมารวมตัวจัดเทศกาลใหญ่กลางจัตุรัส อย่าลืมแวะมากด [E] เข้าร่วมรับรางวัลและชมคัตซีนพิเศษนะ!", "gift_id": "item_wild_honey", "gold": 90}
	]
	for sm in scheduled:
		var mid := str(sm["id"])
		if mid == "mail_fest_eve":
			mid = "mail_fest_eve_%d" % day
		if bool(sm["cond"]) and not delivered_mail_ids.has(mid):
			delivered_mail_ids[mid] = true
			mailbox.push_front({
				"id": mid,
				"sender": str(sm["sender"]),
				"title": str(sm["title"]),
				"body": format_text(str(sm["body"])),
				"gift_id": str(sm["gift_id"]),
				"gold": int(sm["gold"]),
				"claimed": false
			})

func start_next_morning() -> void:
	day += 1
	time_min = 6.0 * 60.0
	var dos := get_day_of_season()
	weather = "sunny" if GameData.FESTIVALS.has(dos) else ("rainy" if randf() < 0.25 else "sunny")
	meteor_shower_tonight = (dos == 28)
	stamina = get_max_stamina()
	pet_petted_today = false
	worked_today.clear()
	purified_wisps_floor.clear()
	for k in relations.keys():
		relations[k]["talked_today"] = false
		relations[k]["gifted_today"] = false
	# Grow watered Mana Garden crops & auto-water on rainy mornings!
	for fkey in farm_plots.keys():
		var pl: Dictionary = farm_plots[fkey]
		if str(pl.get("crop_id", "")) != "":
			if bool(pl.get("watered", false)):
				pl["days"] = int(pl.get("days", 0)) + 1
			pl["watered"] = (weather == "rainy")
	daily_log = {"gold": 0, "hearts": 0, "stats": 0, "items": 0}
	spawn_daily_forage()
	_deliver_scheduled_mail()
	# Morning bonuses from placed furniture & spouse
	var m_stats := {}
	var seen := {}
	for p in decor_placed:
		var did := str(p["id"])
		if seen.has(did): continue
		seen[did] = true
		var d := get_decor_def(did)
		var st := str(d.get("stat", ""))
		if st != "":
			m_stats[st] = int(m_stats.get(st, 0)) + 5
	if spouse_id != "":
		m_stats["charm"] = int(m_stats.get("charm", 0)) + 8
		m_stats["courage"] = int(m_stats.get("courage", 0)) + 5
	if bool(child_data.get("born", false)):
		m_stats["charm"] = int(m_stats.get("charm", 0)) + 6
		child_data["days_old"] = int(child_data.get("days_old", 0)) + 1
		var dold := int(child_data["days_old"])
		var prev_stage := int(child_data.get("stage", 1))
		if dold >= 6 and prev_stage < 3:
			child_data["stage"] = 3
			cutscene_requested.emit("cs_child_explorer")
		elif dold >= 3 and prev_stage < 2:
			child_data["stage"] = 2
			cutscene_requested.emit("cs_child_grow")
	elif spouse_id != "" and wedding_day > 0 and (day - wedding_day) >= 3:
		trigger_child_birth()
	if not m_stats.is_empty():
		add_stat_xp(m_stats)
	check_achievements()
	save_slot(active_slot, true)
	hud_updated.emit()
	toast_requested.emit("เช้า%s วันที่ %d %s! พลังงานฟื้นเต็ม %d" % [get_weekday_name(), dos, get_season_name(), stamina])

