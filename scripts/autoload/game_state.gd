extends Node
## GameState Autoload — Manages 3 Save Slots, 8-Race Protagonist + Perks, Marriage & Spouse Life,
## Grid Furniture Placement & 2nd Floor Loft, 3-Floor Under-Root Ancient Ruins Light Puzzles,
## Social Stats, Quests, 15 Chronicles, 5 Landmarks, 12 Museum Relics, and Daily Loop.

signal hud_updated
signal toast_requested(msg: String)
signal scene_change_requested(scene_id: String, spawn_tile: Vector2i)
signal day_summary_requested

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

var house_level: int = 1
var decor_owned: Dictionary = {}
var decor_placed: Array = []
var decor_used_day: Dictionary = {}
var home_edit_mode: bool = false
var selected_decor_id: String = "decor_mirror"
var selected_decor_rot: int = 0

var ruins_state: Dictionary = {}
var quests_state: Dictionary = {}
var played_events: Dictionary = {}
var worked_today: Dictionary = {}
var landmarks_built: Dictionary = {}
var museum_donated: Dictionary = {}
var museum_milestones_claimed: Dictionary = {}
var chronicles_done: Dictionary = {}
var landmark_used_day: Dictionary = {}
var talked_ever: Dictionary = {}
var mailbox: Array = []
var delivered_mail_ids: Dictionary = {}
var forage_spots: Array = []

var total_shifts: int = 0
var s_rank_jobs: int = 0
var fish_caught: int = 0
var foraged_count: int = 0
var crafted_count: int = 0
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
	relations.clear()
	for c in GameData.characters:
		relations[c["id"]] = {"xp": 120, "talked_today": false, "gifted_today": false}
	partners.clear()
	spouse_id = ""
	wedding_day = 0
	spouse_cared_day = 0
	spouse_dated_day = 0
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
	quests_state = {"q01_welcome": "accepted"}
	played_events.clear()
	worked_today.clear()
	landmarks_built.clear()
	museum_donated.clear()
	museum_milestones_claimed.clear()
	chronicles_done.clear()
	landmark_used_day.clear()
	talked_ever.clear()
	mailbox = [
		{
			"id": "mail_d1",
			"sender": "คุณปู่บราม (โรงเตี๊ยมตะเกียงมอส)",
			"title": "ยินดีต้อนรับสู่กระท่อมหลังใหม่!",
			"body": "ฮ่าๆๆ ยินดีต้อนรับสู่หุบเขาต้นไม้โลกนะ! ลองกด [H] ในบ้านเพื่อวางเฟอร์นิเจอร์บนตาราง หรือสำรวจประตูโบราณสถานใต้รากไม้โลกฝั่งตะวันตกดูสิ!",
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
	for i in range(mini(8, cands.size())):
		var sp: Dictionary = cands[i].duplicate()
		sp["collected"] = false
		forage_spots.append(sp)

# --- 3 SAVE SLOTS ---
func has_save_slot(slot_num: int) -> bool:
	return FileAccess.file_exists(SAVE_PATH_FMT % slot_num)

func read_slot_summary(slot_num: int) -> Dictionary:
	var p := SAVE_PATH_FMT % slot_num
	if not FileAccess.file_exists(p):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(p))
	return d if typeof(d) == TYPE_DICTIONARY else {}

func save_slot(slot_num: int = active_slot, silent: bool = false) -> void:
	active_slot = slot_num
	hero_custom["race_key"] = GameData.get_char_race_key(str(hero_custom.get("base_id", "01_ren")))
	var payload := {
		"version": "6.0",
		"day": day, "time_min": time_min, "weather": weather,
		"gold": gold, "stamina": stamina,
		"player_name": player_name, "cottage_name": cottage_name, "fav_thing": fav_thing,
		"hero_custom": hero_custom, "pet_kind": pet_kind,
		"stats": stats, "inventory": inventory, "relations": relations,
		"partners": partners, "spouse_id": spouse_id, "wedding_day": wedding_day,
		"spouse_cared_day": spouse_cared_day, "spouse_dated_day": spouse_dated_day,
		"house_level": house_level, "decor_owned": decor_owned, "decor_placed": decor_placed,
		"ruins_state": ruins_state, "quests_state": quests_state,
		"played_events": played_events, "worked_today": worked_today,
		"landmarks_built": landmarks_built, "museum_donated": museum_donated,
		"museum_milestones_claimed": museum_milestones_claimed,
		"chronicles_done": chronicles_done, "talked_ever": talked_ever,
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
	pet_kind = str(d.get("pet_kind", "cat"))
	if d.has("stats"): stats.merge(d["stats"], true)
	if d.has("inventory"): inventory = d["inventory"].duplicate(true)
	if d.has("relations"): relations.merge(d["relations"], true)
	if d.has("partners"): partners = d["partners"].duplicate(true)
	spouse_id = str(d.get("spouse_id", ""))
	wedding_day = int(d.get("wedding_day", 0))
	spouse_cared_day = int(d.get("spouse_cared_day", 0))
	spouse_dated_day = int(d.get("spouse_dated_day", 0))
	house_level = int(d.get("house_level", 1))
	if d.has("decor_owned"): decor_owned.merge(d["decor_owned"], true)
	if d.has("decor_placed"): decor_placed = d["decor_placed"].duplicate(true)
	if d.has("ruins_state"):
		for k in d["ruins_state"].keys():
			if ruins_state.has(k):
				ruins_state[k].merge(d["ruins_state"][k], true)
	if d.has("quests_state"): quests_state.merge(d["quests_state"], true)
	if d.has("played_events"): played_events = d["played_events"].duplicate(true)
	if d.has("worked_today"): worked_today = d["worked_today"].duplicate(true)
	if d.has("landmarks_built"): landmarks_built = d["landmarks_built"].duplicate(true)
	if d.has("museum_donated"): museum_donated = d["museum_donated"].duplicate(true)
	if d.has("chronicles_done"): chronicles_done = d["chronicles_done"].duplicate(true)
	if d.has("talked_ever"): talked_ever = d["talked_ever"].duplicate(true)
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

func start_next_morning() -> void:
	day += 1
	time_min = 6.0 * 60.0
	weather = "rainy" if randf() < 0.25 else "sunny"
	stamina = get_max_stamina()
	pet_petted_today = false
	worked_today.clear()
	for k in relations.keys():
		relations[k]["talked_today"] = false
		relations[k]["gifted_today"] = false
	daily_log = {"gold": 0, "hearts": 0, "stats": 0, "items": 0}
	spawn_daily_forage()
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
	if not m_stats.is_empty():
		add_stat_xp(m_stats)
	save_slot(active_slot, true)
	hud_updated.emit()
	toast_requested.emit("เช้า%s วันที่ %d %s! พลังงานฟื้นเต็ม %d" % [get_weekday_name(), get_day_of_season(), get_season_name(), stamina])
