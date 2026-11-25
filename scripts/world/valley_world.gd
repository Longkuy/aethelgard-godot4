extends Node2D
class_name ValleyWorld
## Renders the 84x64 Outdoor Valley (connecting World_Sprites_25D tilesets, houses, landmarks,
## World Tree, props, and Items_Icons_39), 6 Indoor Rooms + 2nd Floor Starlight Loft with
## Grid Furniture Placement [H], and 3-Floor Under-Root Ancient Ruins with Laser Prism Beams!

const TILE := 32
const MAP_W := 84
const MAP_H := 64
const RUINS_PORTAL_TILE := Vector2i(39, 27)
const MAILBOX_TILE := Vector2i(20, 15)
const BULLETIN_TILE := Vector2i(45, 29)
const SHRINE_TILE := Vector2i(42, 28)

const BUILDINGS := [
	{"id": "farmhouse", "name_th": "บ้านตัวเอก", "x": 13, "y": 10, "w": 7, "h": 5, "door": Vector2i(16, 15)},
	{"id": "shop", "name_th": "ร้านชำ Goldleaf", "x": 31, "y": 13, "w": 7, "h": 5, "door": Vector2i(34, 18)},
	{"id": "bakery", "name_th": "ร้านขนมปัง Elderbark", "x": 52, "y": 12, "w": 7, "h": 5, "door": Vector2i(55, 17)},
	{"id": "tavern", "name_th": "โรงเตี๊ยมตะเกียงมอส", "x": 52, "y": 21, "w": 9, "h": 5, "door": Vector2i(56, 26)},
	{"id": "smithy", "name_th": "โรงตีเหล็กศิลาเพลิง", "x": 66, "y": 16, "w": 8, "h": 5, "door": Vector2i(69, 21)},
	{"id": "cottage", "name_th": "กระท่อมสมุนไพรลิเลียน", "x": 14, "y": 35, "w": 7, "h": 5, "door": Vector2i(17, 40)}
]

const INDOORS := {
	"farmhouse": {"name_th": "บ้านพักชั้น 1", "w": 16, "h": 12, "exit": Vector2i(8, 10), "spawn": Vector2i(8, 9), "wall": "#7c4a21", "floor": "#c89b63", "rug": "#b91c1c"},
	"farmhouse_upstairs": {"name_th": "ห้องใต้หลังคาชมดาว (ชั้น 2)", "w": 14, "h": 10, "exit": Vector2i(11, 8), "spawn": Vector2i(11, 7), "wall": "#312e81", "floor": "#b98b56", "rug": "#7e22ce"},
	"shop": {"name_th": "ร้านชำ Goldleaf", "w": 16, "h": 12, "exit": Vector2i(8, 10), "spawn": Vector2i(8, 9), "wall": "#1e4620", "floor": "#d2ab74", "rug": "#15803d"},
	"bakery": {"name_th": "ร้านขนมปัง Elderbark", "w": 16, "h": 12, "exit": Vector2i(8, 10), "spawn": Vector2i(8, 9), "wall": "#8c4a1d", "floor": "#deb887", "rug": "#d97706"},
	"tavern": {"name_th": "โรงเตี๊ยมตะเกียงมอส", "w": 18, "h": 13, "exit": Vector2i(9, 11), "spawn": Vector2i(9, 10), "wall": "#572811", "floor": "#9e6f40", "rug": "#7f1d1d"},
	"smithy": {"name_th": "โรงตีเหล็กศิลาเพลิง", "w": 16, "h": 12, "exit": Vector2i(8, 10), "spawn": Vector2i(8, 9), "wall": "#334155", "floor": "#64748b", "rug": "#9a3412"},
	"cottage": {"name_th": "กระท่อมสมุนไพรลิเลียน", "w": 16, "h": 12, "exit": Vector2i(8, 10), "spawn": Vector2i(8, 9), "wall": "#166534", "floor": "#c9b38c", "rug": "#059669"}
}

var map_grid: PackedByteArray
var solid_grid: PackedByteArray
var tree_tiles: Array[Vector2i] = []

var ground_drawer: Node2D
var entities_root: Node2D
var fx_drawer: Node2D
var player_actor: CharacterActor
var pet_actor: PetActor
var child_actor: ChildActor
var npc_actors: Dictionary = {}
var npc_states: Dictionary = {}
var hover_tile: Vector2i = Vector2i(8, 6)

var has_click_target: bool = false
var click_target: Vector2 = Vector2.ZERO
var _pulse_timer: float = 0.0
var _pulse_origin: Vector2 = Vector2.ZERO
var _wisp_cd: float = 0.0
var _particles: Array = []

var _tileset_tex: Texture2D
var _props_tex: Texture2D
var _world_tree_tex: Texture2D

func _ready() -> void:
	_tileset_tex = GameData.get_tex("world_sprites/tileset_seasons_8x3_512x192.png")
	_props_tex = GameData.get_tex("world_sprites/props_and_trees_8x2_512x192.png")
	_world_tree_tex = GameData.get_tex("world_sprites/world_tree_states_2x1_512x256.png")

	_build_valley_grids()
	for i in range(68):
		_particles.append({
			"seed": float(i) * 19.37,
			"x": fposmod(sin(float(i) * 12.9898) * 43758.54, 1.0),
			"y": fposmod(sin(float(i) * 78.233) * 29432.17, 1.0),
			"spd": 0.65 + fposmod(sin(float(i) * 39.11) * 9182.3, 0.75)
		})

	ground_drawer = Node2D.new()
	ground_drawer.draw.connect(_draw_ground_and_props)
	add_child(ground_drawer)

	entities_root = Node2D.new()
	entities_root.y_sort_enabled = true
	add_child(entities_root)

	player_actor = CharacterActor.new()
	player_actor.is_player = true
	player_actor.position = Vector2(42.5 * TILE, 31.5 * TILE)
	entities_root.add_child(player_actor)

	pet_actor = PetActor.new()
	pet_actor.position = player_actor.position + Vector2(-24, 8)
	entities_root.add_child(pet_actor)

	child_actor = ChildActor.new()
	entities_root.add_child(child_actor)

	fx_drawer = Node2D.new()
	fx_drawer.z_index = 20
	fx_drawer.draw.connect(_draw_atmosphere_and_fx)
	add_child(fx_drawer)

	_spawn_npcs()
	sync_npc_schedules()

func set_click_move_target(world_pos: Vector2) -> void:
	if not is_point_blocked(world_pos):
		click_target = world_pos
		has_click_target = true

func clear_click_move() -> void:
	has_click_target = false

func trigger_sacred_pulse() -> void:
	_pulse_origin = player_actor.position
	_pulse_timer = 0.55
	player_actor.play_hop()
	player_actor.show_emote("✨", 1.5)
	AudioManager.play_sfx("sparkle")

	var sc := GameState.current_scene
	if GameState.night_lantern_on and sc == "outdoor":
		var hr := GameState.time_min / 60.0
		if hr >= 18.0 or hr < 6.0:
			GameState.night_lantern_steps += 1

	if GameData.RUINS_FLOORS.has(sc):
		var fl: Dictionary = GameData.RUINS_FLOORS[sc]
		var wlist: Array = fl.get("wisps", [])
		var now_s := Time.get_ticks_msec() / 1000.0
		if not GameState.purified_wisps_floor.has(sc):
			GameState.purified_wisps_floor[sc] = {}
		var pmap: Dictionary = GameState.purified_wisps_floor[sc]
		var purified_any := false
		for wi in range(wlist.size()):
			if pmap.has(str(wi)):
				continue
			var wp := _get_wisp_pos(wlist[wi], now_s, wi)
			if wp.distance_to(_pulse_origin) <= 125.0:
				pmap[str(wi)] = true
				purified_any = true
				GameState.add_gold(20)
				GameState.add_stat_xp({"courage": 4})
		if purified_any:
			GameState.toast_requested.emit("✨ ชำระล้างภูตหมอกเงามืดสำเร็จ! (+20G +ความกล้า)")
		if sc == "ruins_b4" and not GameState.boss_purified:
			var btile: Vector2i = fl.get("boss_tile", Vector2i(11, 6))
			var bpos := Vector2((btile.x + 0.5) * TILE, (btile.y + 0.5) * TILE)
			if bpos.distance_to(_pulse_origin) <= 165.0:
				GameState.purify_boss_damage()

func _get_wisp_pos(w: Dictionary, now_s: float, idx: int) -> Vector2:
	var p1 := Vector2((float(w["x1"]) + 0.5) * TILE, (float(w["y1"]) + 0.5) * TILE)
	var p2 := Vector2((float(w["x2"]) + 0.5) * TILE, (float(w["y2"]) + 0.5) * TILE)
	var t := 0.5 + 0.5 * sin(now_s * float(w.get("spd", 1.5)) + float(idx) * 1.7)
	return p1.lerp(p2, t)

func _idx(x: int, y: int) -> int:
	return y * MAP_W + x

func _fill_rect(arr: PackedByteArray, x0: int, y0: int, w: int, h: int, val: int) -> void:
	for y in range(maxi(0, y0), mini(MAP_H, y0 + h)):
		for x in range(maxi(0, x0), mini(MAP_W, x0 + w)):
			arr[_idx(x, y)] = val

func _build_valley_grids() -> void:
	map_grid.resize(MAP_W * MAP_H)
	solid_grid.resize(MAP_W * MAP_H)
	map_grid.fill(0)
	solid_grid.fill(0)

	_fill_rect(map_grid, 0, 0, MAP_W, 5, 8)
	_fill_rect(map_grid, 0, 0, 5, MAP_H, 8)
	_fill_rect(map_grid, MAP_W - 5, 0, 5, MAP_H, 8)
	_fill_rect(map_grid, 0, MAP_H - 4, MAP_W, 4, 8)
	_fill_rect(solid_grid, 0, 0, MAP_W, 3, 1)
	_fill_rect(solid_grid, 0, 0, 3, MAP_H, 1)
	_fill_rect(solid_grid, MAP_W - 3, 0, 3, MAP_H, 1)
	_fill_rect(solid_grid, 0, MAP_H - 3, MAP_W, 3, 1)

	_fill_rect(map_grid, 32, 22, 20, 16, 1)
	_fill_rect(map_grid, 10, 29, 64, 3, 2)
	_fill_rect(map_grid, 40, 10, 4, 46, 1)
	_fill_rect(map_grid, 16, 14, 3, 18, 2)
	_fill_rect(map_grid, 56, 15, 3, 17, 2)
	_fill_rect(map_grid, 68, 16, 3, 26, 2)
	_fill_rect(map_grid, 18, 31, 3, 20, 2)

	for x in range(3, MAP_W - 3):
		var ry := int(floor(47.0 + sin(x * 0.14) * 2.2))
		for dy in range(4):
			map_grid[_idx(x, ry + dy)] = 3
			solid_grid[_idx(x, ry + dy)] = 1
	for y in range(48, 60):
		for x in range(28, 57):
			var dx := (x - 42.0) / 14.0
			var dy := (y - 54.0) / 6.0
			if dx * dx + dy * dy <= 1.0:
				map_grid[_idx(x, y)] = 3
				solid_grid[_idx(x, y)] = 1

	for br in [[18, 45, 3, 7], [40, 44, 4, 6], [68, 44, 3, 7], [40, 49, 4, 4]]:
		_fill_rect(map_grid, br[0], br[1], br[2], br[3], 4)
		_fill_rect(solid_grid, br[0], br[1], br[2], br[3], 0)

	for b in BUILDINGS:
		_fill_rect(solid_grid, int(b["x"]), int(b["y"]) + 1, int(b["w"]), int(b["h"]) - 1, 1)
		var dr: Vector2i = b["door"]
		map_grid[_idx(dr.x, dr.y)] = 2
		solid_grid[_idx(dr.x, dr.y)] = 0

	_fill_rect(solid_grid, 40, 26, 4, 3, 1)
	solid_grid[_idx(RUINS_PORTAL_TILE.x, RUINS_PORTAL_TILE.y)] = 0
	map_grid[_idx(RUINS_PORTAL_TILE.x, RUINS_PORTAL_TILE.y)] = 1

	for lm in GameData.landmarks:
		var lx := int(lm["tx"])
		var ly := int(lm["ty"])
		var lw := int(lm["w"])
		var lh := int(lm["h"])
		_fill_rect(map_grid, lx, ly, lw, lh, 0 if lm["id"] == "lm_hotspring" else 1)
		_fill_rect(solid_grid, lx, ly + 1, lw, maxi(1, lh - 2), 1)
		_fill_rect(solid_grid, lx, ly + lh, lw, 1, 0)

	for i in range(120):
		var fx := 6 + int(fposmod(sin(i * 17.3) * 10000.0, 1.0) * (MAP_W - 12))
		var fy := 6 + int(fposmod(sin(i * 31.7) * 10000.0, 1.0) * (MAP_H - 12))
		if map_grid[_idx(fx, fy)] == 0:
			map_grid[_idx(fx, fy)] = 7

	for i in range(70):
		var tx := 5 + int(fposmod(sin(i * 43.1 + 9.0) * 10000.0, 1.0) * (MAP_W - 10))
		var ty := 5 + int(fposmod(sin(i * 19.7 + 3.0) * 10000.0, 1.0) * (MAP_H - 10))
		if map_grid[_idx(tx, ty)] in [0, 8] and solid_grid[_idx(tx, ty)] == 0 and abs(tx - 42) + abs(ty - 29) > 9:
			var near_door := false
			for b in BUILDINGS:
				var dr: Vector2i = b["door"]
				if abs(tx - dr.x) < 3 and abs(ty - dr.y) < 3:
					near_door = true
			if not near_door:
				tree_tiles.append(Vector2i(tx, ty))
				solid_grid[_idx(tx, ty)] = 1

func _spawn_npcs() -> void:
	for c in GameData.characters:
		var cid: String = c["id"]
		var actor := CharacterActor.new()
		actor.char_id = cid
		actor.display_name = str(c["name_th"]).split(" ")[0]
		actor.position = Vector2(38 * TILE, 30 * TILE)
		entities_root.add_child(actor)
		npc_actors[cid] = actor
		npc_states[cid] = {"scene": "outdoor", "activity": "เดินเล่นในเมือง", "home_pos": Vector2(38 * TILE, 30 * TILE)}

func sync_npc_schedules() -> void:
	var mode := "rainy" if GameState.weather == "rainy" else "default"
	var hr := GameState.time_min / 60.0
	var idx := 0
	for c in GameData.characters:
		var cid: String = c["id"]
		var actor: CharacterActor = npc_actors[cid]
		var st: Dictionary = npc_states[cid]

		# Spouse lives inside our house morning & evening!
		if GameState.spouse_id == cid and (hr < 9.5 or hr >= 19.5):
			var sp_scene := "farmhouse_upstairs" if (GameState.house_level >= 2 and hr >= 20.5) else "farmhouse"
			st["scene"] = sp_scene
			st["activity"] = "ใช้เวลาคู่สมรสในบ้านพัก"
			st["home_pos"] = Vector2(6.5 * TILE, 5.8 * TILE)
			actor.position = st["home_pos"]
			actor.visible = (GameState.current_scene == sp_scene)
			actor.badge_text = "💒"
			idx += 1
			continue

		var entry: Dictionary = GameData.schedules.get(cid, {})
		var slots: Array = entry.get(mode, entry.get("default", []))
		var active: Dictionary = {"scene": "outdoor", "x": 36 + (idx % 6) * 2, "y": 27 + (idx % 4) * 2, "activity": "เดินเล่น"}
		for sl in slots:
			var parts := str(sl.get("time", "08:00")).split(":")
			var mins := int(parts[0]) * 60 + (int(parts[1]) if parts.size() > 1 else 0)
			if GameState.time_min >= mins:
				active = sl
		var sc := str(active.get("scene", "outdoor"))
		if sc != "outdoor" and not INDOORS.has(sc):
			sc = "outdoor"
		st["scene"] = sc
		st["activity"] = str(active.get("activity", "เดินเล่น"))
		var tx := float(active.get("x", 38)) + (0.0 if sc == "outdoor" else ((idx % 3) - 1) * 1.3)
		var ty := float(active.get("y", 30))
		if sc != "outdoor":
			var rm: Dictionary = INDOORS[sc]
			tx = clampf(tx, 2.5, float(rm["w"]) - 2.5)
			ty = clampf(ty, 3.5, float(rm["h"]) - 2.5)
		st["home_pos"] = Vector2(tx * TILE, ty * TILE)
		actor.position = st["home_pos"]
		actor.visible = (sc == GameState.current_scene)
		actor.badge_text = "💒" if GameState.spouse_id == cid else ("💑" if GameState.partners.has(cid) else "")
		idx += 1
	if child_actor:
		child_actor.refresh_child()

func update_world(delta: float, cutscene_freeze: bool = false) -> void:
	if _pulse_timer > 0.0:
		_pulse_timer = maxf(0.0, _pulse_timer - delta)
	if _wisp_cd > 0.0:
		_wisp_cd = maxf(0.0, _wisp_cd - delta)

	for cid in npc_actors.keys():
		var actor: CharacterActor = npc_actors[cid]
		var st: Dictionary = npc_states[cid]
		if cutscene_freeze:
			if actor.visible:
				actor.update_actor(delta, false, false)
			continue
		actor.visible = (str(st["scene"]) == GameState.current_scene)
		if actor.visible:
			var phase := Time.get_ticks_msec() / 1200.0 + float(abs(cid.hash()) % 23)
			var rx := sin(phase) * (24.0 if str(st["scene"]) == "outdoor" else 12.0)
			var ry := cos(phase * 0.7) * (12.0 if str(st["scene"]) == "outdoor" else 4.0)
			var target: Vector2 = st["home_pos"] + Vector2(rx, ry)
			var diff := target - actor.position
			var moving := diff.length() > 3.5 and not is_point_blocked(actor.position + diff.normalized() * 8.0)
			if moving:
				actor.position += diff.normalized() * minf(diff.length(), 30.0 * delta)
				if absf(diff.x) > absf(diff.y):
					actor.dir_row = 1 if diff.x < 0.0 else 3
				else:
					actor.dir_row = 0 if diff.y < 0.0 else 2
			else:
				actor.dir_row = 2
			actor.update_actor(delta, moving, false)

	# Shadow Wisp cozy collision check in Ruins B1..B4
	var sc := GameState.current_scene
	if not cutscene_freeze and GameData.RUINS_FLOORS.has(sc) and _wisp_cd <= 0.0:
		var fl: Dictionary = GameData.RUINS_FLOORS[sc]
		var wlist: Array = fl.get("wisps", [])
		var pmap: Dictionary = GameState.purified_wisps_floor.get(sc, {})
		var now_s := Time.get_ticks_msec() / 1000.0
		for wi in range(wlist.size()):
			if pmap.has(str(wi)):
				continue
			var wp := _get_wisp_pos(wlist[wi], now_s, wi)
			if wp.distance_to(player_actor.position) < 22.0:
				_wisp_cd = 1.6
				GameState.stamina = maxi(5, GameState.stamina - 4)
				AudioManager.play_sfx("miss")
				GameState.toast_requested.emit("👾 สัมผัสหมอกเงามืด (-4⚡)! กด [F] ปล่อยคลื่นแสงชำระล้างได้นะ!")
				break

	pet_actor.follow_target(player_actor.position, delta)
	if child_actor:
		child_actor.update_child(delta)
	ground_drawer.queue_redraw()
	if fx_drawer:
		fx_drawer.queue_redraw()

func is_point_blocked(pos: Vector2) -> bool:
	var tx := int(floor(pos.x / TILE))
	var ty := int(floor(pos.y / TILE))
	var sc := GameState.current_scene
	if sc == "outdoor":
		if tx < 0 or ty < 0 or tx >= MAP_W or ty >= MAP_H:
			return true
		return solid_grid[_idx(tx, ty)] == 1
	elif GameData.RUINS_FLOORS.has(sc):
		var fl: Dictionary = GameData.RUINS_FLOORS[sc]
		if tx < 1 or ty < 2 or tx >= int(fl["w"]) - 1 or ty >= int(fl["h"]) - 1:
			return true
		if sc == "ruins_b4" and not GameState.boss_purified:
			var bt: Vector2i = fl.get("boss_tile", Vector2i(11, 6))
			if abs(tx - bt.x) <= 1 and abs(ty - bt.y) <= 1:
				return true
		for arr_name in ["blocks", "emitters", "pillars", "receptors"]:
			for o in fl[arr_name]:
				if int(o["x"]) == tx and int(o["y"]) == ty:
					return true
		return false
	else:
		var rm: Dictionary = INDOORS.get(sc, INDOORS["farmhouse"])
		if tx < 1 or ty < 2 or tx >= int(rm["w"]) - 1 or ty >= int(rm["h"]) - 1:
			return true
		if sc in ["farmhouse", "farmhouse_upstairs"]:
			if tx >= 2 and tx < 4 and ty >= 3 and ty < 6:
				return true
			for p in GameState.decor_placed:
				if str(p["scene"]) != sc: continue
				var d := GameState.get_decor_def(str(p["id"]))
				if bool(d.get("passable", false)): continue
				if tx >= int(p["x"]) and tx < int(p["x"]) + int(p["w"]) and ty >= int(p["y"]) and ty < int(p["y"]) + int(p["h"]):
					return true
		return false

func is_near_water(pos: Vector2) -> bool:
	if GameState.current_scene != "outdoor":
		return false
	var tx := int(floor(pos.x / TILE))
	var ty := int(floor(pos.y / TILE))
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var nx := tx + dx
			var ny := ty + dy
			if nx >= 0 and ny >= 0 and nx < MAP_W and ny < MAP_H and map_grid[_idx(nx, ny)] == 3:
				return true
	return false

func get_scene_pixel_bounds() -> Vector2:
	var sc := GameState.current_scene
	if sc == "outdoor":
		return Vector2(MAP_W * TILE, MAP_H * TILE)
	elif GameData.RUINS_FLOORS.has(sc):
		var fl: Dictionary = GameData.RUINS_FLOORS[sc]
		return Vector2(int(fl["w"]) * TILE, int(fl["h"]) * TILE)
	var rm: Dictionary = INDOORS.get(sc, INDOORS["farmhouse"])
	return Vector2(int(rm["w"]) * TILE, int(rm["h"]) * TILE)

func _draw_tile_from_atlas(col: int, row: int, dest: Rect2) -> void:
	if _tileset_tex:
		ground_drawer.draw_texture_rect_region(_tileset_tex, dest, Rect2(col * 64, row * 64, 64, 64))

func _draw_ground_and_props() -> void:
	var sc := GameState.current_scene
	var font := GameData.font_bold
	var now_sec := Time.get_ticks_msec() / 1000.0

	if sc == "outdoor":
		var s_idx := GameState.get_season_index()
		for y in range(MAP_H):
			for x in range(MAP_W):
				var t := map_grid[_idx(x, y)]
				var dest := Rect2(x * TILE, y * TILE, TILE, TILE)
				match t:
					0, 5, 6:
						_draw_tile_from_atlas(s_idx * 2 + ((x + y) % 2), 0, dest)
					7:
						_draw_tile_from_atlas(s_idx, 1, dest)
					8:
						_draw_tile_from_atlas(4, 1, dest)
					1:
						_draw_tile_from_atlas(5, 1, dest)
					2:
						_draw_tile_from_atlas(6, 1, dest)
					4:
						_draw_tile_from_atlas(7, 1, dest)
					3:
						_draw_tile_from_atlas(int(now_sec * 3.0 + x) % 3, 2, dest)

		# Forage items (Items_Icons_39!)
		for fs in GameState.forage_spots:
			if bool(fs.get("collected", false)): continue
			var fp := Vector2((int(fs["tx"]) + 0.5) * TILE, (int(fs["ty"]) + 0.5) * TILE)
			ground_drawer.draw_circle(fp, 11.0 + sin(now_sec * 4.0) * 2.0, Color(1.0, 0.9, 0.3, 0.32))
			var it_tex := GameData.get_item_icon(str(fs["item_id"]), false)
			if it_tex:
				ground_drawer.draw_texture_rect(it_tex, Rect2(fp.x - 12, fp.y - 14 + sin(now_sec * 3.5) * 2.0, 24, 24), false)

		# World Tree + 8 Seals + Ruins Portal Archway
		var wtc := Vector2(42.0 * TILE, 27.5 * TILE)
		var finale := GameState.chronicles_done.has("main_ch5") or GameState.spouse_id != ""
		var seals := GameState.get_awakened_seal_count()
		ground_drawer.draw_circle(wtc + Vector2(0, -34), 128.0, Color(1.0, 0.9, 0.35, 0.16 + seals * 0.03))
		if _world_tree_tex:
			ground_drawer.draw_texture_rect_region(_world_tree_tex, Rect2(wtc.x - 116, wtc.y - 190, 232, 220), Rect2(256 if finale else 0, 0, 256, 256))
		var rpos := Vector2((RUINS_PORTAL_TILE.x + 0.5) * TILE, (RUINS_PORTAL_TILE.y + 0.5) * TILE)
		ground_drawer.draw_rect(Rect2(rpos.x - 15, rpos.y - 24, 30, 28), Color("#1e293b"))
		ground_drawer.draw_rect(Rect2(rpos.x - 15, rpos.y - 24, 30, 28), Color("#38bdf8"), false, 2.5)
		ground_drawer.draw_rect(Rect2(rpos.x - 10, rpos.y - 19, 20, 21), Color(0.22, 0.74, 0.97, 0.65 + sin(now_sec * 4.0) * 0.2))
		if font:
			ground_drawer.draw_string(font, rpos + Vector2(-36, -28), "โบราณสถาน", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#e0f2fe"))

		# Buildings (World_Sprites_25D/buildings!)
		for b in BUILDINGS:
			var bx := float(b["x"]) * TILE
			var by := float(b["y"]) * TILE
			var bw := float(b["w"]) * TILE
			var bh := float(b["h"]) * TILE
			var btex := GameData.get_building_tex(str(b["id"]))
			if btex:
				ground_drawer.draw_texture_rect(btex, Rect2(bx - 8, by - 22, bw + 16, bh + 26), false)
			if b["id"] == "farmhouse" and GameState.house_level >= 2:
				ground_drawer.draw_rect(Rect2(bx + bw * 0.5 - 22, by - 24, 44, 20), Color("#312e81"))
				ground_drawer.draw_rect(Rect2(bx + bw * 0.5 - 22, by - 24, 44, 20), Color("#fde047"), false, 2.0)
			if font:
				var title := GameState.cottage_name if b["id"] == "farmhouse" else str(b["name_th"])
				ground_drawer.draw_rect(Rect2(bx + bw * 0.5 - 46, by + 4, 92, 16), Color("#fbf0d9"))
				ground_drawer.draw_string(font, Vector2(bx + bw * 0.5 - 42, by + 16), title.left(12), HORIZONTAL_ALIGNMENT_LEFT, 86, 10, Color("#3f1d0b"))

		# 5 Restorable Landmarks (World_Sprites_25D/landmarks!)
		for lm in GameData.landmarks:
			var lx := float(lm["tx"]) * TILE
			var ly := float(lm["ty"]) * TILE
			var lw := float(lm["w"]) * TILE
			var lh := float(lm["h"]) * TILE
			var built := GameState.landmarks_built.has(lm["id"])
			var ltex := GameData.get_landmark_tex(str(lm["id"]), built)
			if ltex:
				ground_drawer.draw_texture_rect(ltex, Rect2(lx - 6, ly - 16, lw + 12, lh + 20), false)

		# Seasonal Trees & Props (props_and_trees_8x2_512x192.png!)
		if _props_tex:
			for tr in tree_tiles:
				ground_drawer.draw_texture_rect_region(_props_tex, Rect2(tr.x * TILE - 16, tr.y * TILE - 54, 64, 86), Rect2(s_idx * 64, 0, 64, 96))
			ground_drawer.draw_texture_rect_region(_props_tex, Rect2(MAILBOX_TILE.x * TILE - 8, MAILBOX_TILE.y * TILE - 32, 48, 64), Rect2(6 * 64, 0, 64, 96))
			ground_drawer.draw_texture_rect_region(_props_tex, Rect2(BULLETIN_TILE.x * TILE - 8, BULLETIN_TILE.y * TILE - 32, 48, 64), Rect2(7 * 64, 0, 64, 96))

	elif GameData.RUINS_FLOORS.has(sc):
		var fl: Dictionary = GameData.RUINS_FLOORS[sc]
		var rw := int(fl["w"]) * TILE
		var rh := int(fl["h"]) * TILE
		var rs: Dictionary = GameState.ruins_state[sc]
		var beam_info := GameState.compute_ruins_beams(sc)
		ground_drawer.draw_rect(Rect2(0, 0, rw, 2 * TILE), Color("#1e1b4b"))
		for y in range(2, int(fl["h"]) - 1):
			for x in range(1, int(fl["w"]) - 1):
				ground_drawer.draw_rect(Rect2(x * TILE, y * TILE, TILE, TILE), Color("#1e293b" if (x + y) % 2 == 0 else "#172033"))
				ground_drawer.draw_rect(Rect2(x * TILE, y * TILE, TILE, TILE), Color(0.22, 0.74, 0.97, 0.14), false, 1.0)
		ground_drawer.draw_rect(Rect2(2, 2, rw - 4, rh - 4), Color("#38bdf8"), false, 3.0)

		var eu: Dictionary = fl["exit_up"]
		ground_drawer.draw_rect(Rect2(int(eu["x"]) * TILE, int(eu["y"]) * TILE, TILE, TILE), Color("#475569"))
		var sd: Dictionary = fl["stairs_down"]
		if not sd.is_empty():
			ground_drawer.draw_rect(Rect2(int(sd["x"]) * TILE, int(sd["y"]) * TILE, TILE, TILE), Color("#0284c7" if bool(rs["solved"]) else "#7f1d1d"))

		for b in fl["blocks"]:
			ground_drawer.draw_rect(Rect2(int(b["x"]) * TILE + 2, int(b["y"]) * TILE + 2, TILE - 4, TILE - 4), Color("#334155"))
		for em in fl["emitters"]:
			var ep := Vector2((int(em["x"]) + 0.5) * TILE, (int(em["y"]) + 0.5) * TILE)
			ground_drawer.draw_rect(Rect2(ep.x - 13, ep.y - 13, 26, 26), Color("#4c1d95"))
			ground_drawer.draw_circle(ep, 8.0, Color(str(em["color"])))

		var lit_arr: Array = beam_info["lit_indices"]
		for ri in range(fl["receptors"].size()):
			var rc: Dictionary = fl["receptors"][ri]
			var rp := Vector2((int(rc["x"]) + 0.5) * TILE, (int(rc["y"]) + 0.5) * TILE)
			var lit := lit_arr.has(ri)
			ground_drawer.draw_circle(rp, 13.0, Color("#16a34a" if lit else "#334155"))
			ground_drawer.draw_circle(rp, 7.0, Color("#fde047" if lit else "#64748b"))

		var p_states: Array = rs["pillars"]
		for pi in range(fl["pillars"].size()):
			var pl: Dictionary = fl["pillars"][pi]
			var pp := Vector2((int(pl["x"]) + 0.5) * TILE, (int(pl["y"]) + 0.5) * TILE)
			ground_drawer.draw_rect(Rect2(pp.x - 13, pp.y - 13, 26, 26), Color("#0f172a"))
			ground_drawer.draw_rect(Rect2(pp.x - 13, pp.y - 13, 26, 26), Color("#38bdf8"), false, 2.0)
			var mst := int(p_states[pi])
			if mst == 0:
				ground_drawer.draw_line(pp + Vector2(-9, 9), pp + Vector2(9, -9), Color("#fef08a"), 4.0)
			elif mst == 1:
				ground_drawer.draw_line(pp + Vector2(-9, -9), pp + Vector2(9, 9), Color("#fef08a"), 4.0)
			else:
				ground_drawer.draw_line(pp + Vector2(-10, 0), pp + Vector2(10, 0), Color("#fef08a"), 4.0)
				ground_drawer.draw_line(pp + Vector2(0, -10), pp + Vector2(0, 10), Color("#fef08a"), 4.0)

		for seg in beam_info["segments"]:
			var p1 := (Vector2(seg["p1"]) + Vector2(0.5, 0.5)) * TILE
			var p2 := (Vector2(seg["p2"]) + Vector2(0.5, 0.5)) * TILE
			var c := Color(str(seg["color"]))
			c.a = 0.38
			ground_drawer.draw_line(p1, p2, c, 7.0)
			ground_drawer.draw_line(p1, p2, Color.WHITE, 2.5)

		var ch: Dictionary = fl["chest"]
		var cp := Vector2(int(ch["x"]) * TILE + 4, int(ch["y"]) * TILE + 6)
		ground_drawer.draw_rect(Rect2(cp.x, cp.y, 24, 20), Color("#475569" if bool(rs["chest_opened"]) else ("#d97706" if bool(rs["solved"]) else "#7f1d1d")))
		ground_drawer.draw_rect(Rect2(cp.x, cp.y, 24, 20), Color("#fde047"), false, 2.0)

		var mined: Dictionary = rs.get("mined_day", {})
		for oi in range(fl["ores"].size()):
			if int(mined.get(str(oi), -1)) == GameState.day: continue
			var ore: Dictionary = fl["ores"][oi]
			var op := Vector2((int(ore["x"]) + 0.5) * TILE, (int(ore["y"]) + 0.5) * TILE)
			var otex := GameData.get_item_icon(str(ore["item_id"]), false)
			if otex:
				ground_drawer.draw_texture_rect(otex, Rect2(op.x - 12, op.y - 12, 24, 24), false)

		# Shadow Miasma Wisps (Purifiable with [F]!)
		var wlist: Array = fl.get("wisps", [])
		var pmap: Dictionary = GameState.purified_wisps_floor.get(sc, {})
		for wi in range(wlist.size()):
			if pmap.has(str(wi)):
				continue
			var wp := _get_wisp_pos(wlist[wi], now_sec, wi)
			ground_drawer.draw_circle(wp, 16.0 + sin(now_sec * 6.0 + wi) * 2.5, Color(0.42, 0.12, 0.65, 0.36))
			ground_drawer.draw_circle(wp, 9.0, Color("#581c87"))
			ground_drawer.draw_circle(wp + Vector2(-3, -2), 2.2, Color("#f43f5e"))
			ground_drawer.draw_circle(wp + Vector2(3, -2), 2.2, Color("#f43f5e"))

		# Floor B4 Boss: Corrupted Root Warden -> Golden Guardian!
		if sc == "ruins_b4":
			var bt: Vector2i = fl.get("boss_tile", Vector2i(11, 6))
			var bp := Vector2((bt.x + 0.5) * TILE, (bt.y + 0.5) * TILE)
			if GameState.boss_purified:
				ground_drawer.draw_circle(bp, 38.0 + sin(now_sec * 3.0) * 4.0, Color(1.0, 0.9, 0.35, 0.32))
				ground_drawer.draw_circle(bp, 22.0, Color("#ca8a04"))
				ground_drawer.draw_circle(bp, 15.0, Color("#fef08a"))
				if font:
					ground_drawer.draw_string(font, bp + Vector2(-62, -32), "✨ ผู้พิทักษ์รากไม้ศักดิ์สิทธิ์", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#fef08a"))
			else:
				var shield_up := not bool(rs["solved"])
				if shield_up:
					ground_drawer.draw_arc(bp, 42.0 + sin(now_sec * 5.0) * 3.0, 0.0, TAU, 32, Color(0.58, 0.2, 0.92, 0.85), 4.0)
				ground_drawer.draw_circle(bp, 28.0, Color("#3b0764"))
				ground_drawer.draw_rect(Rect2(bp.x - 20, bp.y - 24, 40, 42), Color("#4c1d95"))
				ground_drawer.draw_rect(Rect2(bp.x - 20, bp.y - 24, 40, 42), Color("#f43f5e" if shield_up else "#fde047"), false, 2.5)
				ground_drawer.draw_circle(bp + Vector2(-7, -6), 4.0, Color("#ef4444"))
				ground_drawer.draw_circle(bp + Vector2(7, -6), 4.0, Color("#ef4444"))
				# Boss HP Bar
				var ratio := float(GameState.boss_hp) / float(maxi(1, GameState.boss_max_hp))
				ground_drawer.draw_rect(Rect2(bp.x - 32, bp.y - 40, 64, 8), Color("#0f172a"))
				ground_drawer.draw_rect(Rect2(bp.x - 30, bp.y - 38, 60.0 * ratio, 4), Color("#ec4899"))
				if font:
					var hint := "🛡️ เกราะเงามืด (ไขเสาแสงก่อน)" if shield_up else ("⚡ กด [F] ชำระล้าง! (%d/%d)" % [GameState.boss_hp, GameState.boss_max_hp])
					ground_drawer.draw_string(font, bp + Vector2(-70, -46), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#fde047"))

	else:
		# Indoor Room + 2nd Floor Starlight Loft + Grid Furniture Placement!
		var rm: Dictionary = INDOORS.get(sc, INDOORS["farmhouse"])
		var rw := int(rm["w"]) * TILE
		var rh := int(rm["h"]) * TILE
		ground_drawer.draw_rect(Rect2(0, 0, rw, 2 * TILE), Color(str(rm["wall"])))
		if sc == "farmhouse_upstairs":
			ground_drawer.draw_rect(Rect2(3 * TILE, 8, (int(rm["w"]) - 6) * TILE, 44), Color("#0f172a"))
			ground_drawer.draw_rect(Rect2(3 * TILE, 8, (int(rm["w"]) - 6) * TILE, 44), Color("#fde047"), false, 2.0)
			for s in range(12):
				ground_drawer.draw_circle(Vector2(3.5 * TILE + s * 20, 22 + (s * 9) % 18), 2.2, Color("#fef08a"))
		for y in range(2, int(rm["h"]) - 1):
			for x in range(1, int(rm["w"]) - 1):
				ground_drawer.draw_rect(Rect2(x * TILE, y * TILE, TILE, TILE), Color(str(rm["floor"])))
				ground_drawer.draw_rect(Rect2(x * TILE, y * TILE, TILE, TILE), Color(1, 1, 1, 0.35) if GameState.home_edit_mode else Color(0, 0, 0, 0.14), false, 1.0)
		ground_drawer.draw_rect(Rect2(4 * TILE, 5 * TILE, 6 * TILE, 3 * TILE), Color(str(rm["rug"])))
		var ex: Vector2i = rm["exit"]
		ground_drawer.draw_rect(Rect2(ex.x * TILE, ex.y * TILE + 6, TILE, TILE - 8), Color("#dc2626"))

		if sc == "farmhouse":
			ground_drawer.draw_rect(Rect2(2 * TILE, 3 * TILE, 2 * TILE, 3 * TILE), Color("#db2777" if GameState.spouse_id != "" else "#2563eb"))
			ground_drawer.draw_rect(Rect2(5 * TILE, 8 * TILE, 2 * TILE, 2 * TILE), Color("#92400e")) # Craft table
			if GameState.house_level >= 2:
				ground_drawer.draw_rect(Rect2(13 * TILE, 2 * TILE, 2 * TILE, 2 * TILE), Color("#d97706"))
				if font:
					ground_drawer.draw_string(font, Vector2(13 * TILE + 4, 2 * TILE + 20), "ขึ้นชั้น 2", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#fffbeb"))
		elif sc == "farmhouse_upstairs":
			ground_drawer.draw_rect(Rect2(2 * TILE, 3 * TILE, 3 * TILE, 3 * TILE), Color("#e11d48"))

		if sc in ["farmhouse", "farmhouse_upstairs"]:
			for p in GameState.decor_placed:
				if str(p["scene"]) != sc: continue
				var d := GameState.get_decor_def(str(p["id"]))
				var r := Rect2(int(p["x"]) * TILE + 2, int(p["y"]) * TILE + 2, int(p["w"]) * TILE - 4, int(p["h"]) * TILE - 4)
				ground_drawer.draw_rect(r, Color(str(d.get("color", "#78350f"))))
				ground_drawer.draw_rect(r, Color("#fde68a"), false, 2.0)
				if font:
					ground_drawer.draw_string(font, r.position + Vector2(4, 18), str(d.get("label", "")).left(8), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 4, 10, Color.WHITE)

			if GameState.home_edit_mode and GameState.selected_decor_id != "":
				var sd := GameState.get_decor_def(GameState.selected_decor_id)
				if not sd.is_empty():
					var gw := int(sd["h"]) if GameState.selected_decor_rot == 1 else int(sd["w"])
					var gh := int(sd["w"]) if GameState.selected_decor_rot == 1 else int(sd["h"])
					var ok := GameState.can_place_decor_at(GameState.selected_decor_id, sc, hover_tile.x, hover_tile.y, gw, gh)
					var gr := Rect2(hover_tile.x * TILE, hover_tile.y * TILE, gw * TILE, gh * TILE)
					ground_drawer.draw_rect(gr, Color(0.15, 0.85, 0.35, 0.45) if ok else Color(0.95, 0.25, 0.25, 0.45))
					ground_drawer.draw_rect(gr, Color.GREEN if ok else Color.RED, false, 2.5)

func _draw_atmosphere_and_fx() -> void:
	var now_s := Time.get_ticks_msec() / 1000.0
	var sc := GameState.current_scene

	# Click-to-move ring
	if has_click_target:
		fx_drawer.draw_arc(click_target, 10.0 + sin(now_s * 7.0) * 2.5, 0.0, TAU, 20, Color(0.99, 0.88, 0.28, 0.85), 2.2)

	# [F] Sacred Light Pulse golden shockwave!
	if _pulse_timer > 0.0:
		var prog := 1.0 - (_pulse_timer / 0.55)
		var rad := 18.0 + prog * 135.0
		fx_drawer.draw_arc(_pulse_origin, rad, 0.0, TAU, 36, Color(1.0, 0.92, 0.38, (1.0 - prog) * 0.92), 5.0)
		fx_drawer.draw_circle(_pulse_origin, rad * 0.65, Color(1.0, 0.96, 0.65, (1.0 - prog) * 0.22))

	if sc != "outdoor":
		return

	var hr := GameState.time_min / 60.0
	var is_night := (hr >= 18.0 or hr < 6.0)
	var s_idx := GameState.get_season_index()
	var cam_center := player_actor.position

	# Chimney smoke from cozy town buildings
	for b in BUILDINGS:
		if str(b["id"]) in ["bakery", "tavern", "smithy", "farmhouse"]:
			var cx := (float(b["x"]) + float(b["w"]) - 1.2) * TILE
			var cy := float(b["y"]) * TILE - 14.0
			for k in range(3):
				var ph := fposmod(now_s * 0.55 + float(k) * 0.33, 1.0)
				fx_drawer.draw_circle(Vector2(cx + sin(now_s * 2.0 + k) * 6.0 + ph * 10.0, cy - ph * 28.0), 4.0 + ph * 5.0, Color(0.95, 0.95, 0.98, (1.0 - ph) * 0.28))

	# Night warm window & plaza streetlamp glows
	if is_night:
		for b in BUILDINGS:
			var door_p := (Vector2(b["door"]) + Vector2(0.5, -0.3)) * TILE
			fx_drawer.draw_circle(door_p, 44.0 + sin(now_s * 3.0) * 3.0, Color(1.0, 0.82, 0.35, 0.20))
		for lp in [Vector2(36, 29), Vector2(48, 29), Vector2(42, 23), Vector2(42, 36), Vector2(59, 38)]:
			var wlp: Vector2 = (lp + Vector2(0.5, 0.5)) * float(TILE)
			fx_drawer.draw_circle(wlp, 48.0, Color(1.0, 0.86, 0.42, 0.18))
			fx_drawer.draw_circle(wlp, 4.0, Color(1.0, 0.95, 0.65, 0.85))

	# Weather Rain OR Seasonal Petals / Fireflies / Autumn Leaves / Snow
	var span := Vector2(860.0, 540.0)
	for pt in _particles:
		var spd := float(pt["spd"])
		if GameState.weather == "rainy":
			var rx := cam_center.x - span.x * 0.5 + fposmod(float(pt["x"]) * span.x - now_s * 95.0 * spd, span.x)
			var ry := cam_center.y - span.y * 0.5 + fposmod(float(pt["y"]) * span.y + now_s * 340.0 * spd, span.y)
			fx_drawer.draw_line(Vector2(rx, ry), Vector2(rx - 5.0, ry + 15.0), Color(0.68, 0.85, 1.0, 0.52), 1.6)
		elif is_night:
			# Night fireflies
			var fx := cam_center.x - span.x * 0.5 + fposmod(float(pt["x"]) * span.x + sin(now_s + float(pt["seed"])) * 24.0, span.x)
			var fy := cam_center.y - span.y * 0.5 + fposmod(float(pt["y"]) * span.y + cos(now_s * 0.8 + float(pt["seed"])) * 18.0, span.y)
			var a := 0.25 + 0.45 * absf(sin(now_s * 2.6 + float(pt["seed"])))
			fx_drawer.draw_circle(Vector2(fx, fy), 2.6, Color(0.65, 1.0, 0.45, a))
		else:
			var px := cam_center.x - span.x * 0.5 + fposmod(float(pt["x"]) * span.x + now_s * 22.0 * spd + sin(now_s + float(pt["seed"])) * 14.0, span.x)
			var py := cam_center.y - span.y * 0.5 + fposmod(float(pt["y"]) * span.y + now_s * 36.0 * spd, span.y)
			var col := Color(1.0, 0.72, 0.85, 0.72) if s_idx == 0 else (Color(1.0, 0.94, 0.55, 0.50) if s_idx == 1 else (Color(0.96, 0.52, 0.16, 0.76) if s_idx == 2 else Color(0.94, 0.98, 1.0, 0.82)))
			fx_drawer.draw_circle(Vector2(px, py), 2.8, col)

	# Meteor Shower tonight!
	if is_night and (GameState.meteor_shower_tonight or GameState.get_day_of_season() == 28):
		for m in range(4):
			var mp := fposmod(now_s * 0.65 + float(m) * 0.27, 1.0)
			if mp < 0.45:
				var start_p := cam_center + Vector2(260.0 - mp * 720.0 + m * 65.0, -220.0 + mp * 420.0)
				fx_drawer.draw_line(start_p, start_p + Vector2(46.0, -28.0), Color(1.0, 0.96, 0.65, 0.85), 2.6)
				fx_drawer.draw_circle(start_p, 3.5, Color.WHITE)

