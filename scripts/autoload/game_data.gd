extends Node
## GameData Autoload — Loads all 15 JSON datasets, indexes all 284 2.5D Sprite Assets,
## and applies the global Thai + Latin + Symbols UI Theme across Godot 4.

const SPRITE_ROOT := "res://assets/sprites"
const DATA_ROOT := "res://data"

var raw_json: Dictionary = {}
var characters: Array = []
var char_by_id: Dictionary = {}
var dialogues: Dictionary = {}
var schedules: Dictionary = {}
var quests: Array = []
var social_stats: Array = []
var jobs: Array = []
var job_by_employer: Dictionary = {}
var items: Array = []
var item_by_id: Dictionary = {}
var hangout_spots: Array = []
var heart_events: Array = []
var landmarks: Array = []
var landmark_by_id: Dictionary = {}
var museum_collection: Array = []
var museum_milestones: Array = []
var night_market_stock: Array = []
var chapters: Array = []
var chapter_by_id: Dictionary = {}
var cutscenes_v7: Dictionary = {}
var world_map: Dictionary = {}
var use_hd_sprites: bool = false

var _tex_cache: Dictionary = {}
var ui_theme: Theme
var font_regular: FontFile
var font_bold: FontFile

const ACCESSORIES := [
	{"id": "acc_none", "name_th": "ไม่สวมเครื่องประดับ", "price": 0, "slot": "head", "desc_th": "แสดงทรงผมธรรมชาติของตัวเอก"},
	{"id": "acc_straw_hat", "name_th": "หมวกฟางนักบุกเบิก", "price": 120, "slot": "head", "desc_th": "หมวกฟางสานคาดริบบิ้นแดง กันแดดยามเดินสำรวจหุบเขา"},
	{"id": "acc_flower_crown", "name_th": "มงกุฎดอกไม้รากไม้โลก", "price": 180, "slot": "head", "desc_th": "มงกุฎดอกไม้เรืองแสงถักทอด้วยมือ (+เสน่ห์เมื่อสวมใส่)"},
	{"id": "acc_witch_hat", "name_th": "หมวกจอมเวทดารา", "price": 260, "slot": "head", "desc_th": "หมวกทรงสูงสีครามประดับดาวทองแห่งหอดูดาว"},
	{"id": "acc_wedding_veil", "name_th": "ผ้าคลุม/รัดเกล้าวิวาห์ศักดิ์สิทธิ์", "price": 350, "slot": "head", "desc_th": "เครื่องประดับศีรษะสีขาวมุกสำหรับพิธีวิวาห์ใต้ต้นไม้โลก"},
	{"id": "acc_fairy_wings", "name_th": "ปีกภูตแสงต้นไม้โลก", "price": 480, "slot": "back", "desc_th": "ปีกโปร่งแสงสีฟ้าทองกระพือเบาๆ ด้านหลังตัวเอก"},
	{"id": "acc_crimson_cape", "name_th": "ผ้าคลุมไหล่รัตติกาลสีชาด", "price": 420, "slot": "back", "desc_th": "ผ้าคลุมไหล่ขุนนางแวมไพร์โบกสะบัดสง่างาม"},
	{"id": "acc_royal_crown", "name_th": "มงกุฎทองแปดเผ่าพันธุ์", "price": 900, "slot": "head", "desc_th": "มงกุฎเกียรติยศสูงสุดของผู้ชำระล้างบอสชั้น B4 สำเร็จ!"}
]

const OUTFIT_THEMES := [
	{"id": "outfit_traveler", "name_th": "ชุดนักเดินทางดั้งเดิม", "price": 0, "hue": 0.0, "sat": 100.0, "val": 100.0, "aura": ""},
	{"id": "outfit_spring", "name_th": "ชุดเทศกาลกลีบซากุระผลิ", "price": 160, "hue": -35.0, "sat": 125.0, "val": 108.0, "aura": "#f472b6"},
	{"id": "outfit_summer", "name_th": "ชุดสายลมสมุทรฤดูร้อน", "price": 160, "hue": 145.0, "sat": 120.0, "val": 106.0, "aura": "#38bdf8"},
	{"id": "outfit_autumn", "name_th": "ชุดใบเมเปิลสีอำพัน", "price": 160, "hue": 28.0, "sat": 135.0, "val": 102.0, "aura": "#f59e0b"},
	{"id": "outfit_winter", "name_th": "ชุดคลุมเกล็ดหิมะจันทรา", "price": 200, "hue": 195.0, "sat": 85.0, "val": 115.0, "aura": "#e0f2fe"},
	{"id": "outfit_wedding", "name_th": "ชุดพิธีวิวาห์สีทองบริสุทธิ์", "price": 450, "hue": 45.0, "sat": 60.0, "val": 128.0, "aura": "#fde047"}
]

const FESTIVALS := {
	7: {"day": 7, "id": "cs_fest_7", "name_th": "เทศกาลโคมไฟต้นไม้โลก", "desc_th": "ชาวเมืองทั้ง 8 เผ่าร่วมปล่อยโคมลอยอธิษฐานรอบจัตุรัส (+35 หัวใจทุกคน & +15 เสน่ห์)", "hearts_all": 35, "stat": {"charm": 15}},
	14: {"day": 14, "id": "cs_fest_14", "name_th": "คืนดนตรีโรงเตี๊ยมตะเกียงมอส", "desc_th": "งานเลี้ยงหม้อไฟและไวโอลินประสานเสียง (+35 หัวใจทุกคน & ฟื้นพลังเต็ม)", "hearts_all": 35, "stat": {"charm": 10, "wisdom": 10}},
	21: {"day": 21, "id": "cs_fest_21", "name_th": "ตลาดนัดหัตถศิลป์แปดเผ่า", "desc_th": "มหกรรมประกวดงานช่างฝีมือและลดราคาสินค้าทั่วเมือง 20%! (+300G & +15 ฝีมือ)", "hearts_all": 25, "gold": 300, "stat": {"craft": 15}},
	28: {"day": 28, "id": "cs_fest_28", "name_th": "คืนฝนดาวตกเอเธลการ์ด", "desc_th": "ชมสายฝนดาวตกส่งท้ายฤดูกาลริมทะเลสาบมุก (+ผลึกดาวตก x2 & +20 ปัญญา)", "hearts_all": 40, "item_id": "item_starfall_crystal", "item_qty": 2, "stat": {"wisdom": 20}}
}

const NPC_BIRTHDAYS := {
	"01_ren": {"season": 0, "day": 4}, "03_lilian": {"season": 0, "day": 11}, "07_sera": {"season": 0, "day": 18}, "11_pip": {"season": 0, "day": 25},
	"05_kyo": {"season": 1, "day": 3}, "06_sora": {"season": 1, "day": 10}, "13_mirelle": {"season": 1, "day": 17}, "14_kael": {"season": 1, "day": 24},
	"02_marcus": {"season": 2, "day": 5}, "08_roland": {"season": 2, "day": 12}, "12_trixie": {"season": 2, "day": 19}, "16_bram": {"season": 2, "day": 26},
	"04_eli": {"season": 3, "day": 6}, "09_celeste": {"season": 3, "day": 13}, "10_lucian": {"season": 3, "day": 20}, "15_thorn": {"season": 3, "day": 27}
}

const ACHIEVEMENTS := [
	{"id": "ach_welcome", "title_th": "ก้าวแรกแห่งเอเธลการ์ด", "desc_th": "พูดคุยทักทายชาวเมืองครบ 5 คน"},
	{"id": "ach_social_all", "title_th": "ขวัญใจแปดเผ่าพันธุ์", "desc_th": "พูดคุยครบทั้ง 16 ตัวละครในหุบเขา"},
	{"id": "ach_first_job", "title_th": "คนขยันประจำเมือง", "desc_th": "ทำงานพาร์ทไทม์สำเร็จเป็นครั้งแรก"},
	{"id": "ach_s_rank", "title_th": "ยอดฝีมือระดับ S", "desc_th": "ทำมินิเกมพาร์ทไทม์ได้ระดับ Rank S ครบ 3 ครั้ง"},
	{"id": "ach_angler", "title_th": "นักตกปลาแห่งทะเลสาบมุก", "desc_th": "ตกปลาสำเร็จครบ 5 ตัว"},
	{"id": "ach_forager", "title_th": "นักสำรวจของป่าเรืองแสง", "desc_th": "เก็บของป่าครบ 10 ชิ้น"},
	{"id": "ach_chef", "title_th": "เชฟและช่างฝีมือเอก", "desc_th": "คราฟต์ไอเทมหรือทำอาหารครบ 5 ชิ้น"},
	{"id": "ach_rich", "title_th": "เศรษฐีรากไม้ทอง", "desc_th": "สะสมเงินทองในกระเป๋าครบ 2,000 G"},
	{"id": "ach_loft", "title_th": "สถาปนิกห้องชมดาว", "desc_th": "ต่อเติมบ้านชั้น 2 (Starlight Loft) สำเร็จ"},
	{"id": "ach_decorator", "title_th": "นักจัดบ้านมือทอง", "desc_th": "วางเฟอร์นิเจอร์ตกแต่งในบ้านครบ 4 ชิ้น"},
	{"id": "ach_fashion", "title_th": "แฟชั่นนิสต้าแปดเผ่า", "desc_th": "เป็นเจ้าของเครื่องประดับหรือชุดพิเศษ 3 ชิ้น"},
	{"id": "ach_bestie", "title_th": "มิตรแท้รู้ใจ", "desc_th": "มีตัวละครที่ระดับหัวใจถึง 5 ดวง"},
	{"id": "ach_lover", "title_th": "ดอกไม้แห่งความรัก", "desc_th": "สารภาพรักและคบหาดูใจกับคนพิเศษ"},
	{"id": "ach_married", "title_th": "ระฆังวิวาห์ใต้ต้นไม้โลก", "desc_th": "เข้าพิธีแต่งงานกับคู่ชีวิตที่มี 10 หัวใจ"},
	{"id": "ach_parent", "title_th": "ครอบครัวสุขสันต์สมบูรณ์", "desc_th": "ให้กำเนิดทายาทตัวน้อยแห่งต้นไม้โลก"},
	{"id": "ach_child_grow", "title_th": "ก้าวเติบโตของสายใย", "desc_th": "เลี้ยงดูลูกน้อยจนเติบโตสู่วัยเดินได้"},
	{"id": "ach_landmark_1", "title_th": "ผู้บุกเบิกการบูรณะ", "desc_th": "บูรณะแลนด์มาร์กของเมืองสำเร็จ 1 แห่ง"},
	{"id": "ach_landmark_all", "title_th": "มหานครรากไม้ฟื้นคืน", "desc_th": "บูรณะแลนด์มาร์กครบทั้ง 5 แห่ง!"},
	{"id": "ach_museum_half", "title_th": "ภัณฑารักษ์ผู้ทุ่มเท", "desc_th": "บริจาคโบราณวัตถุเข้าพิพิธภัณฑ์ครบ 6 ชิ้น"},
	{"id": "ach_museum_all", "title_th": "ตำนานพิพิธภัณฑ์ 12 ชิ้น", "desc_th": "บริจาคโบราณวัตถุครบสมบูรณ์ทั้ง 12 ชิ้น!"},
	{"id": "ach_ruins_b1", "title_th": "ผู้ไขปริศนาเสาแสง", "desc_th": "ปลดผนึกเสาปริซึมโบราณสถานชั้น B1 สำเร็จ"},
	{"id": "ach_ruins_b3", "title_th": "ผู้ค้นพบแหวนบรรพกาล", "desc_th": "ปลดผนึกชั้น B3 โถงหัวใจบรรพกาลสำเร็จ"},
	{"id": "ach_boss_b4", "title_th": "ผู้ชำระล้างรากไม้ต้องสาป", "desc_th": "ปราบหมอกมืดและชำระล้างบอสผู้พิทักษ์ชั้น B4 สำเร็จ!"},
	{"id": "ach_chronicle", "title_th": "ผู้จารึกพงศาวดาร", "desc_th": "เล่นเนื้อเรื่องพงศาวดารต้นไม้โลกผ่าน 5 บท"}
]

const CROPS := [
	{"id": "crop_sunwheat", "name_th": "ข้าวสาลีสุริยัน", "seed_price": 25, "grow_days": 2, "harvest_item": "item_sunfruit", "color": "#facc15", "desc_th": "โตไวใน 2 วัน เก็บเกี่ยวได้ผลไม้สุริยันหอมหวาน"},
	{"id": "crop_rootdew", "name_th": "ดอกน้ำค้างรากไม้", "seed_price": 35, "grow_days": 2, "harvest_item": "item_rootdew_flower", "color": "#38bdf8", "desc_th": "โตใน 2 วัน ใช้ปรุงยาสมุนไพรและจัดช่อดอกไม้"},
	{"id": "crop_moonbloom", "name_th": "ดอกไม้จันทร์เรืองแสง", "seed_price": 45, "grow_days": 3, "harvest_item": "item_moonbloom", "color": "#c084fc", "desc_th": "โตใน 3 วัน เปล่งแสงสีม่วงเงินยามค่ำคืน"},
	{"id": "crop_waterlily", "name_th": "บัวมรกตสายน้ำ", "seed_price": 40, "grow_days": 3, "harvest_item": "item_water_lily", "color": "#34d399", "desc_th": "โตใน 3 วัน ของโปรดของเผ่าเงือกและเอลฟ์"},
	{"id": "crop_starflower", "name_th": "บุปผาผลึกดาวตก", "seed_price": 90, "grow_days": 4, "harvest_item": "item_starfall_crystal", "color": "#fde047", "desc_th": "โตใน 4 วัน เก็บเกี่ยวเป็นผลึกดาวตกล้ำค่า!"}
]

const RACE_PERKS := {
	"human": {"icon": "🧑", "name_th": "มนุษย์ (Human)", "perk_th": "XP สเตตัสทั้ง 4 แกน +10% ทุกกิจกรรม"},
	"elf": {"icon": "🌿", "name_th": "เอลฟ์ (Elf)", "perk_th": "เก็บของป่ามีโอกาส 35% ได้ x2 ชิ้น!"},
	"avian": {"icon": "🪽", "name_th": "เผ่าวิหก (Avian)", "perk_th": "เดิน/วิ่งไวขึ้น +12% & ค่าจ้างสายส่งของ/ลาดตระเวน +15%"},
	"beastkin": {"icon": "🐾", "name_th": "เผ่าครึ่งสัตว์ (Beastkin)", "perk_th": "คราฟต์ของ/ทำอาหารฟื้นพลังงานกลับคืน +8⚡ ทันที"},
	"vampire": {"icon": "🌙", "name_th": "แวมไพร์ (Vampire)", "perk_th": "หลัง 18:00 น. ใช้พลังงานลดลง 25%"},
	"goblin": {"icon": "⚙️", "name_th": "ก็อบลินเหลือง (Goblin)", "perk_th": "ซื้อของลด 8% & ขายของได้ราคา +10%"},
	"merfolk": {"icon": "🧜", "name_th": "เผ่าเงือก (Merfolk)", "perk_th": "แถบเขียวตกปลา Stardew กว้างขึ้น +28%"},
	"dwarf": {"icon": "⚒️", "name_th": "คนแคระ (Dwarf)", "perk_th": "พลังงานสูงสุด +15⚡ & ขุดแร่โบราณสถานได้ x2!"}
}

const CRAFT_RECIPES := [
	{"id": "rec_ring", "out_id": "item_world_tree_ring", "name_th": "ตีแหวนสายใยรากไม้โลก (ขอแต่งงาน)", "ingredients": {"item_pure_gold_ore": 1, "item_starfall_crystal": 1}, "stat": {"craft": 20, "charm": 15}},
	{"id": "rec_croissant", "out_id": "item_honey_croissant", "name_th": "อบครัวซองต์เนยน้ำผึ้ง", "ingredients": {"item_wild_honey": 1, "item_rich_milk": 1}, "stat": {"craft": 8}},
	{"id": "rec_pie", "out_id": "item_apple_pie", "name_th": "อบพายผลไม้สุริยัน", "ingredients": {"item_sunfruit": 1, "item_wild_honey": 1}, "stat": {"craft": 10}},
	{"id": "rec_stew", "out_id": "item_hearty_stew", "name_th": "เคี่ยวสตูว์แซลมอนหม้อไฟ", "ingredients": {"item_grilled_salmon": 1, "item_wild_honey": 1}, "stat": {"craft": 10, "charm": 4}},
	{"id": "rec_elixir", "out_id": "item_ruby_elixir", "name_th": "ปรุงน้ำอมฤตทับทิม", "ingredients": {"item_rootdew_flower": 1, "item_moonbloom": 1}, "stat": {"wisdom": 12}},
	{"id": "rec_rose", "out_id": "item_velvet_rose", "name_th": "จัดช่อกุหลาบแดงกำมะหยี่", "ingredients": {"item_rootdew_flower": 1, "item_water_lily": 1}, "stat": {"charm": 10}},
	{"id": "rec_compass", "out_id": "item_brass_compass", "name_th": "ประดิษฐ์เข็มทิศทองเหลือง", "ingredients": {"item_brass_gear": 1, "item_ember_ore": 1}, "stat": {"craft": 12, "wisdom": 5}},
	{"id": "rec_pearl", "out_id": "item_sea_pearl", "name_th": "ขัดเงาไข่มุกสมุทร", "ingredients": {"item_glowing_shell": 1, "item_aqua_crystal": 1}, "stat": {"craft": 10, "charm": 6}},
	{"id": "rec_battery", "out_id": "item_mana_battery", "name_th": "ประกอบแบตเตอรี่มานา", "ingredients": {"item_brass_gear": 1, "item_starfall_crystal": 1}, "stat": {"wisdom": 12, "craft": 8}},
	{"id": "rec_ale", "out_id": "item_honey_ale", "name_th": "หมักเอลน้ำผึ้งป่า", "ingredients": {"item_wild_honey": 2}, "stat": {"craft": 7, "charm": 5}},
	{"id": "rec_barrel", "out_id": "item_oak_barrel", "name_th": "ต่อถังไม้โอ๊กช่างฝีมือ", "ingredients": {"item_hard_oak": 2}, "stat": {"craft": 12}}
]

const HOME_DECOR := [
	{"id": "decor_bookshelf", "label": "ชั้นหนังสือโบราณ", "price": 220, "perk_th": "+5 ปัญญาทุกเช้า", "stat": "wisdom", "w": 2, "h": 1, "color": "#78350f", "passable": false, "action": ""},
	{"id": "decor_tea_set", "label": "โต๊ะน้ำชามรกต", "price": 200, "perk_th": "+5 เสน่ห์ทุกเช้า", "stat": "charm", "w": 2, "h": 2, "color": "#15803d", "passable": false, "action": ""},
	{"id": "decor_workbench", "label": "โต๊ะงานฝีมือไม้โอ๊ก", "price": 250, "perk_th": "+5 ฝีมือทุกเช้า", "stat": "craft", "w": 2, "h": 1, "color": "#b45309", "passable": false, "action": ""},
	{"id": "decor_lantern", "label": "โคมไฟคริสตัลแขวน", "price": 190, "perk_th": "+5 ความกล้าทุกเช้า", "stat": "courage", "w": 1, "h": 1, "color": "#eab308", "passable": false, "action": ""},
	{"id": "decor_plush_bed", "label": "เตียงขนนกพรีเมียม", "price": 380, "perk_th": "พลังงานสูงสุด +20 ถาวร", "stat": "", "w": 2, "h": 2, "color": "#db2777", "passable": false, "action": ""},
	{"id": "decor_mirror", "label": "กระจกแต่งตัวเวทมนตร์", "price": 180, "perk_th": "กด [E] แต่งตัวเอก 8 เผ่า & ตู้เสื้อผ้าในบ้าน!", "stat": "charm", "w": 1, "h": 2, "color": "#8b5cf6", "passable": false, "action": "mirror"},
	{"id": "decor_aquarium", "label": "ตู้ปลาเรืองแสงทะเลสาบมุก", "price": 300, "perk_th": "กด [E] ชมปลาฟื้น +12 พลังงาน/วัน", "stat": "wisdom", "w": 2, "h": 1, "color": "#0284c7", "passable": false, "action": "aquarium"},
	{"id": "decor_rug_royal", "label": "พรมทอตราแปดเผ่า", "price": 160, "perk_th": "ปูพื้นเดินทับได้ +5 เสน่ห์", "stat": "charm", "w": 3, "h": 2, "color": "#9f1239", "passable": true, "action": ""},
	{"id": "decor_bonsai", "label": "บอนไซต้นไม้โลกเรืองแสง", "price": 260, "perk_th": "+5 ปัญญาทุกเช้า", "stat": "wisdom", "w": 1, "h": 1, "color": "#16a34a", "passable": false, "action": ""},
	{"id": "decor_cello", "label": "ไวโอลินไม้แดงตั้งพื้น", "price": 320, "perk_th": "กด [E] บรรเลงดนตรี 4 เลนในบ้าน!", "stat": "charm", "w": 1, "h": 1, "color": "#991b1b", "passable": false, "action": "music"},
	{"id": "decor_sofa", "label": "โซฟากำมะหยี่คู่รัก", "price": 340, "perk_th": "พลังงานสูงสุด +10 ถาวร", "stat": "", "w": 3, "h": 1, "color": "#7e22ce", "passable": false, "action": ""},
	{"id": "decor_telescope", "label": "กล้องดูดาวริมระเบียง", "price": 290, "perk_th": "กด [E] ส่องดาวรับ +8 ปัญญา/วัน", "stat": "wisdom", "w": 1, "h": 2, "color": "#1d4ed8", "passable": false, "action": "stargaze"}
]

const RUINS_FLOORS := {
	"ruins_b1": {
		"id": "ruins_b1", "depth": 1, "w": 20, "h": 14,
		"name_th": "โบราณสถานใต้รากไม้ ชั้น B1 (โถงรากศิลา)",
		"exit_up": {"x": 10, "y": 12, "to": "outdoor"},
		"stairs_down": {"x": 10, "y": 2, "to": "ruins_b2"},
		"spawn": Vector2i(10, 11),
		"chest": {"x": 16, "y": 3, "gold": 320, "items": {"item_ancient_tablet": 1, "item_aqua_crystal": 1}, "stat": {"wisdom": 15, "courage": 10}},
		"emitters": [{"x": 3, "y": 5, "dir": 3, "color": "#fde047"}],
		"blocks": [{"x": 9, "y": 5}, {"x": 11, "y": 7}, {"x": 5, "y": 9}],
		"pillars": [
			{"x": 7, "y": 5, "init": 0, "max_states": 2},
			{"x": 7, "y": 9, "init": 0, "max_states": 2},
			{"x": 14, "y": 9, "init": 1, "max_states": 2}
		],
		"receptors": [{"x": 14, "y": 4}],
		"ores": [{"x": 4, "y": 3, "item_id": "item_ember_ore"}, {"x": 16, "y": 10, "item_id": "item_aqua_crystal"}],
		"wisps": [{"x1": 5, "y1": 7, "x2": 15, "y2": 7, "spd": 1.4}]
	},
	"ruins_b2": {
		"id": "ruins_b2", "depth": 2, "w": 20, "h": 14,
		"name_th": "โบราณสถานใต้รากไม้ ชั้น B2 (โถงกระจกวารี)",
		"exit_up": {"x": 10, "y": 12, "to": "ruins_b1"},
		"stairs_down": {"x": 10, "y": 2, "to": "ruins_b3"},
		"spawn": Vector2i(10, 11),
		"chest": {"x": 17, "y": 3, "gold": 480, "items": {"item_starfall_crystal": 1, "item_sea_pearl": 1}, "stat": {"wisdom": 20, "courage": 15}},
		"emitters": [{"x": 3, "y": 4, "dir": 3, "color": "#38bdf8"}, {"x": 3, "y": 10, "dir": 3, "color": "#fde047"}],
		"blocks": [{"x": 10, "y": 4}, {"x": 11, "y": 10}],
		"pillars": [
			{"x": 6, "y": 4, "init": 0, "max_states": 2},
			{"x": 6, "y": 7, "init": 0, "max_states": 2},
			{"x": 8, "y": 10, "init": 1, "max_states": 2},
			{"x": 8, "y": 5, "init": 1, "max_states": 2}
		],
		"receptors": [{"x": 16, "y": 7}, {"x": 16, "y": 5}],
		"ores": [{"x": 4, "y": 7, "item_id": "item_pure_gold_ore"}, {"x": 15, "y": 10, "item_id": "item_starfall_crystal"}],
		"wisps": [{"x1": 5, "y1": 8, "x2": 14, "y2": 8, "spd": 1.7}, {"x1": 12, "y1": 4, "x2": 12, "y2": 9, "spd": 1.5}]
	},
	"ruins_b3": {
		"id": "ruins_b3", "depth": 3, "w": 20, "h": 14,
		"name_th": "โบราณสถานใต้รากไม้ ชั้น B3 (โถงหัวใจบรรพกาล)",
		"exit_up": {"x": 10, "y": 12, "to": "ruins_b2"},
		"stairs_down": {"x": 10, "y": 2, "to": "ruins_b4"},
		"spawn": Vector2i(10, 11),
		"chest": {"x": 12, "y": 3, "gold": 800, "items": {"item_world_tree_ring": 1, "item_crimson_mana": 1, "item_ruby_elixir": 1}, "stat": {"wisdom": 30, "courage": 25, "charm": 15}},
		"emitters": [{"x": 3, "y": 7, "dir": 3, "color": "#f472b6"}],
		"blocks": [{"x": 9, "y": 7}, {"x": 12, "y": 4}],
		"pillars": [
			{"x": 7, "y": 7, "init": 0, "max_states": 2},
			{"x": 7, "y": 10, "init": 0, "max_states": 2},
			{"x": 12, "y": 10, "init": 1, "max_states": 2},
			{"x": 12, "y": 6, "init": 0, "max_states": 3},
			{"x": 9, "y": 6, "init": 0, "max_states": 2},
			{"x": 15, "y": 6, "init": 1, "max_states": 2}
		],
		"receptors": [{"x": 9, "y": 3}, {"x": 15, "y": 3}],
		"ores": [{"x": 4, "y": 4, "item_id": "item_crimson_mana"}, {"x": 16, "y": 10, "item_id": "item_pure_gold_ore"}, {"x": 17, "y": 5, "item_id": "item_raw_gem"}],
		"wisps": [{"x1": 4, "y1": 9, "x2": 16, "y2": 9, "spd": 1.9}, {"x1": 6, "y1": 4, "x2": 14, "y2": 4, "spd": 1.6}]
	},
	"ruins_b4": {
		"id": "ruins_b4", "depth": 4, "w": 22, "h": 16,
		"name_th": "ชั้น B4: วิหารแกนรากไม้โลก (บอสผู้พิทักษ์รากไม้ต้องสาป!)",
		"exit_up": {"x": 11, "y": 14, "to": "ruins_b3"},
		"stairs_down": {},
		"spawn": Vector2i(11, 13),
		"boss_tile": Vector2i(11, 6),
		"chest": {"x": 11, "y": 3, "gold": 1500, "items": {"item_crimson_mana": 2, "item_starfall_crystal": 2, "item_pure_gold_ore": 2}, "stat": {"courage": 40, "wisdom": 35, "charm": 25}},
		"emitters": [{"x": 3, "y": 9, "dir": 3, "color": "#fde047"}, {"x": 18, "y": 9, "dir": 1, "color": "#38bdf8"}],
		"blocks": [{"x": 9, "y": 9}, {"x": 13, "y": 9}],
		"pillars": [
			{"x": 7, "y": 9, "init": 1, "max_states": 2},
			{"x": 7, "y": 4, "init": 1, "max_states": 2},
			{"x": 15, "y": 9, "init": 0, "max_states": 2},
			{"x": 15, "y": 4, "init": 0, "max_states": 2}
		],
		"receptors": [{"x": 9, "y": 4}, {"x": 13, "y": 4}],
		"ores": [{"x": 4, "y": 5, "item_id": "item_crimson_mana"}, {"x": 18, "y": 5, "item_id": "item_starfall_crystal"}],
		"wisps": [{"x1": 5, "y1": 11, "x2": 17, "y2": 11, "spd": 2.1}, {"x1": 5, "y1": 7, "x2": 17, "y2": 7, "spd": 1.8}]
	}
}

func _ready() -> void:
	_setup_input_actions()
	_setup_thai_theme()
	_load_all_json_datasets()

func _setup_input_actions() -> void:
	var bindings := {
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"sprint": [KEY_SHIFT],
		"interact": [KEY_E, KEY_SPACE, KEY_ENTER],
		"open_map": [KEY_M],
		"pet_companion": [KEY_P],
		"home_edit": [KEY_H],
		"rotate_decor": [KEY_R],
		"sacred_pulse": [KEY_F],
		"toggle_lantern": [KEY_9],
		"skip_cutscene": [KEY_TAB]
	}
	for action in bindings.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for keycode in bindings[action]:
				var ev := InputEventKey.new()
				ev.physical_keycode = keycode
				InputMap.action_add_event(action, ev)

func _setup_thai_theme() -> void:
	font_regular = load("res://assets/fonts/NotoSans-Regular.ttf") as FontFile
	font_bold = load("res://assets/fonts/NotoSans-Bold.ttf") as FontFile
	var thai_reg := load("res://assets/fonts/NotoSansThai-Regular.ttf") as FontFile
	var thai_bold := load("res://assets/fonts/NotoSansThai-Bold.ttf") as FontFile
	var sym := load("res://assets/fonts/NotoSansSymbols2-Regular.ttf") as FontFile
	if font_regular and thai_reg:
		font_regular.fallbacks = [thai_reg, sym] if sym else [thai_reg]
	if font_bold and thai_bold:
		font_bold.fallbacks = [thai_bold, sym] if sym else [thai_bold]

	ui_theme = Theme.new()
	if font_bold:
		ui_theme.default_font = font_bold
		ui_theme.default_font_size = 15

	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = Color("#f6e4bc")
	panel_sb.border_color = Color("#5b2c0d")
	panel_sb.set_border_width_all(3)
	panel_sb.set_corner_radius_all(8)
	panel_sb.set_content_margin_all(10)
	ui_theme.set_stylebox("panel", "PanelContainer", panel_sb)

	var btn_sb := StyleBoxFlat.new()
	btn_sb.bg_color = Color("#ecd09c")
	btn_sb.border_color = Color("#6b3814")
	btn_sb.set_border_width_all(2)
	btn_sb.set_corner_radius_all(6)
	btn_sb.content_margin_left = 10
	btn_sb.content_margin_right = 10
	btn_sb.content_margin_top = 5
	btn_sb.content_margin_bottom = 5
	var btn_hov := btn_sb.duplicate() as StyleBoxFlat
	btn_hov.bg_color = Color("#fde047")
	ui_theme.set_stylebox("normal", "Button", btn_sb)
	ui_theme.set_stylebox("hover", "Button", btn_hov)
	ui_theme.set_stylebox("pressed", "Button", btn_hov)
	ui_theme.set_color("font_color", "Button", Color("#2b1608"))
	ui_theme.set_color("font_hover_color", "Button", Color("#2b1608"))
	ui_theme.set_color("font_pressed_color", "Button", Color("#2b1608"))
	ui_theme.set_color("font_disabled_color", "Button", Color("#78716c"))
	ui_theme.set_color("font_color", "Label", Color("#2b1608"))
	ui_theme.set_color("default_color", "RichTextLabel", Color("#2b1608"))

	if get_tree() and get_tree().root:
		get_tree().root.theme = ui_theme

func _load_json_file(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("Missing JSON file: " + path)
		return {}
	var txt := FileAccess.get_file_as_string(path)
	return JSON.parse_string(txt)

func _load_all_json_datasets() -> void:
	var names := [
		"characters", "dialogues", "schedules", "quests", "social_stats",
		"jobs", "items", "events", "landmarks", "story_chronicles", "cutscenes_v7", "world_map", "manifest"
	]
	for n in names:
		raw_json[n] = _load_json_file("%s/%s.json" % [DATA_ROOT, n])
	raw_json["items_atlas"] = _load_json_file("%s/items_icons/items_atlas.json" % SPRITE_ROOT)
	raw_json["world_atlas"] = _load_json_file("%s/world_sprites/world_atlas.json" % SPRITE_ROOT)

	characters = raw_json["characters"].get("characters", [])
	for c in characters:
		char_by_id[c["id"]] = c
	dialogues = raw_json["dialogues"].get("dialogues", {})
	schedules = raw_json["schedules"].get("schedules", {})
	quests = raw_json["quests"].get("quests", [])
	social_stats = raw_json["social_stats"].get("stats", [])
	jobs = raw_json["jobs"].get("jobs", [])
	for j in jobs:
		job_by_employer[j["employer_id"]] = j

	items = raw_json["items"].get("items", []).duplicate(true)
	var has_ring := false
	for it in items:
		if it["id"] == "item_world_tree_ring":
			has_ring = true
	if not has_ring:
		items.append({
			"id": "item_world_tree_ring",
			"name_th": "แหวนสายใยรากไม้โลก",
			"category": "heirloom",
			"price": 850,
			"sell_price": 500,
			"energy_restore": 0,
			"shop_id": "shop",
			"loved_by": ["01_ren", "03_lilian", "04_eli", "07_sera", "09_celeste", "10_lucian", "13_mirelle", "14_kael"],
			"description_th": "แหวนทองคำประดับผลึกดาวตกจากรากต้นไม้โลก ใช้มอบขอแต่งงานกับคนรักที่มี 10 หัวใจ"
		})
	for it in items:
		item_by_id[it["id"]] = it

	hangout_spots = raw_json["events"].get("hangout_spots", [])
	heart_events = raw_json["events"].get("heart_events", [])
	landmarks = raw_json["landmarks"].get("landmarks", [])
	for lm in landmarks:
		landmark_by_id[lm["id"]] = lm
	museum_collection = raw_json["landmarks"].get("museum_collection", [])
	museum_milestones = raw_json["landmarks"].get("museum_milestones", [])
	night_market_stock = raw_json["landmarks"].get("night_market_stock", []).duplicate()
	if not night_market_stock.has("item_world_tree_ring"):
		night_market_stock.append("item_world_tree_ring")

	chapters = raw_json["story_chronicles"].get("chapters", [])
	for ch in chapters:
		chapter_by_id[ch["id"]] = ch
	cutscenes_v7 = raw_json["cutscenes_v7"].get("cutscenes", {})
	world_map = raw_json["world_map"]

func get_accessory_def(acc_id: String) -> Dictionary:
	for a in ACCESSORIES:
		if str(a["id"]) == acc_id:
			return a
	return ACCESSORIES[0]

func get_outfit_def(out_id: String) -> Dictionary:
	for o in OUTFIT_THEMES:
		if str(o["id"]) == out_id:
			return o
	return OUTFIT_THEMES[0]

func get_crop_def(crop_id: String) -> Dictionary:
	for cr in CROPS:
		if str(cr["id"]) == crop_id:
			return cr
	return CROPS[0]

func is_npc_birthday(cid: String, season_idx: int, day_of_season: int) -> bool:
	if not NPC_BIRTHDAYS.has(cid):
		return false
	var b: Dictionary = NPC_BIRTHDAYS[cid]
	return int(b["season"]) == season_idx and int(b["day"]) == day_of_season

func get_char_race_key(cid: String) -> String:
	var c: Dictionary = char_by_id.get(cid, {})
	var rk: String = str(c.get("race_key", "human"))
	if rk == "winged" or rk == "avian":
		return "avian"
	return rk if RACE_PERKS.has(rk) else "human"

func get_tex(rel_path: String) -> Texture2D:
	var full := "%s/%s" % [SPRITE_ROOT, rel_path]
	if _tex_cache.has(full):
		return _tex_cache[full]
	if ResourceLoader.exists(full):
		var t := load(full) as Texture2D
		_tex_cache[full] = t
		return t
	return null

func get_walk_sheet(cid: String, hd: bool = use_hd_sprites) -> Texture2D:
	var dir := "walk_9x4_hd_1152x512" if hd else "walk_9x4"
	return get_tex("%s/%s_walk_9x4.png" % [dir, cid])

func get_idle_sheet(cid: String, hd: bool = use_hd_sprites) -> Texture2D:
	var dir := "idle_6x4_hd_768x512" if hd else "idle_6x4"
	return get_tex("%s/%s_idle_6x4.png" % [dir, cid])

func get_interact_sheet(cid: String, hd: bool = use_hd_sprites) -> Texture2D:
	var dir := "interact_8x4_hd_1024x512" if hd else "interact_8x4"
	return get_tex("%s/%s_interact_8x4.png" % [dir, cid])

func get_portrait(cid: String, emotion: String = "neutral") -> Texture2D:
	var emo := emotion if emotion in ["neutral", "happy", "blush", "sad"] else "neutral"
	var t := get_tex("portraits_style2/%s_%s_256.png" % [cid, emo])
	return t if t else get_tex("portraits_style2/%s_neutral_256.png" % cid)

func get_pet_sheet(kind: String, hd: bool = use_hd_sprites) -> Texture2D:
	var dir := "pets_4x4_hd_512x512" if hd else "pets_4x4"
	return get_tex("%s/pet_%s_4x4.png" % [dir, kind])

func get_item_icon(iid: String, hd: bool = true) -> Texture2D:
	if iid == "item_world_tree_ring":
		return get_tex("items_icons/64x64/item_starfall_crystal.png")
	var sz := "64x64" if hd else "32x32"
	return get_tex("items_icons/%s/%s.png" % [sz, iid])

func get_building_tex(bid: String) -> Texture2D:
	return get_tex("world_sprites/buildings/house_%s.png" % bid)

func get_landmark_tex(lmid: String, restored: bool) -> Texture2D:
	return get_tex("world_sprites/landmarks/%s_%s.png" % [lmid, "restored" if restored else "ruined"])

func verify_all_284_sprites() -> Dictionary:
	var all_pngs: Array[String] = []
	_scan_pngs_recursive(SPRITE_ROOT, all_pngs)
	var loaded_ok := 0
	for p in all_pngs:
		var t := load(p) as Texture2D
		if t != null and t.get_width() > 0:
			loaded_ok += 1
	return {"total_found": all_pngs.size(), "loaded_ok": loaded_ok}

func _scan_pngs_recursive(dir_path: String, out: Array[String]) -> void:
	var d := DirAccess.open(dir_path)
	if not d:
		return
	d.list_dir_begin()
	var fname := d.get_next()
	while fname != "":
		if fname != "." and fname != "..":
			var full := "%s/%s" % [dir_path, fname]
			if d.current_is_dir():
				_scan_pngs_recursive(full, out)
			elif fname.ends_with(".png"):
				out.append(full)
		fname = d.get_next()
	d.list_dir_end()
