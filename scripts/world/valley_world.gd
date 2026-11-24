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
var player_actor: CharacterActor
var pet_actor: PetActor
var npc_actors: Dictionary = {}
var npc_states: Dictionary = {}
var hover_tile: Vector2i = Vector2i(8, 6)

var _tileset_tex: Texture2D
var _props_tex: Texture2D
var _world_tree_tex: Texture2D

func _ready() -> void:
	_tileset_tex = GameData.get_tex("world_sprites/tileset_seasons_8x3_512x192.png")
	_props_tex = GameData.get_tex("world_sprites/props_and_trees_8x2_512x192.png")
	_world_tree_tex = GameData.get_tex("world_sprites/world_tree_states_2x1_512x256.png")

	_build_valley_grids()

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

	_spawn_npcs()
	sync_npc_schedules()

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
			actor.position = Vector2(6.5 * TILE, 5.8 * TILE)
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

func update_world(delta: float) -> void:
	for cid in npc_actors.keys():
		var actor: CharacterActor = npc_actors[cid]
		var st: Dictionary = npc_states[cid]
		actor.visible = (str(st["scene"]) == GameState.current_scene)
		if actor.visible:
			var sway := sin(Time.get_ticks_msec() / 1100.0 + float(cid.hash() % 17)) * 18.0
			var target: Vector2 = st["home_pos"] + Vector2(sway, 0)
			var diff := target - actor.position
			var moving := diff.length() > 3.0
			if moving:
				actor.position += diff.normalized() * minf(diff.length(), 32.0 * delta)
				actor.dir_row = 1 if diff.x < 0.0 else 3
			else:
				actor.dir_row = 2
			actor.update_actor(delta, moving, false)
	pet_actor.follow_target(player_actor.position, delta)
	ground_drawer.queue_redraw()

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
