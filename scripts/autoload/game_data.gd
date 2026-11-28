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
	{"id": "ach_chronicle", "title_th": "ผู้จารึกพงศาวดาร", "desc_th": "เล่นเนื้อเรื่องพงศาวดารต้นไม้โลกผ่าน 5 บท"},
	{"id": "ach_guild_master", "title_th": "นักผจญภัยกิลด์ระดับแนวหน้า", "desc_th": "พิชิตภารกิจจากกิลด์นักผจญภัยสำเร็จครบ 5 ภารกิจ"},
	{"id": "ach_endgame", "title_th": "ตำนานนิรันดร์แห่งเอเธลการ์ด", "desc_th": "ปลดล็อกพาหนะแสงดาว [V] หรือสร้างอนุสาวรีย์ทองคำ 8 เผ่า!"}
]

const GUILD_RANKS := [
	{"rank": "F", "title_th": "นักผจญภัยฝึกหัด", "xp_req": 0, "gold_bonus_pct": 0},
	{"rank": "E", "title_th": "นักสำรวจแนวหน้า", "xp_req": 60, "gold_bonus_pct": 5},
	{"rank": "D", "title_th": "นักล่าหมอกเงา", "xp_req": 150, "gold_bonus_pct": 10},
	{"rank": "C", "title_th": "ผู้พิทักษ์หุบเขา", "xp_req": 280, "gold_bonus_pct": 15},
	{"rank": "B", "title_th": "อัศวินรากไม้โลก", "xp_req": 450, "gold_bonus_pct": 20},
	{"rank": "A", "title_th": "จอมยุทธ์แปดเผ่าพันธุ์", "xp_req": 680, "gold_bonus_pct": 25},
	{"rank": "S", "title_th": "ตำนานแห่งเอเธลการ์ด", "xp_req": 950, "gold_bonus_pct": 35}
]

const GUILD_BOUNTIES := [
	{"id": "gb_forage_herb", "rank": "F", "title_th": "เก็บดอกน้ำค้างรากไม้ส่งกิลด์", "desc_th": "เก็บดอกน้ำค้างรากไม้จากป่ารอบเมืองมาส่ง 2 ดอก", "type": "deliver_item", "item_id": "item_rootdew_flower", "target": 2, "gold": 140, "guild_xp": 35, "stat": {"wisdom": 8}},
	{"id": "gb_patrol_town", "rank": "F", "title_th": "ลาดตระเวนตรวจความสงบหุบเขา", "desc_th": "พูดคุยทักทายสอบถามความสงบจากชาวเมือง 4 คน", "type": "talk_npcs", "target": 4, "gold": 130, "guild_xp": 35, "stat": {"charm": 10}},
	{"id": "gb_honey_supply", "rank": "F", "title_th": "เสบียงน้ำผึ้งป่าประจำกิลด์", "desc_th": "นำน้ำผึ้งป่า 2 ขวดมาส่งให้โรงครัวกิลด์นักผจญภัย", "type": "deliver_item", "item_id": "item_wild_honey", "target": 2, "gold": 150, "guild_xp": 40, "stat": {"craft": 8}},
	{"id": "gb_wisp_b1", "rank": "E", "title_th": "กวาดล้างภูตหมอกเงาชั้น B1", "desc_th": "ใช้คลื่นแสง [F] ชำระล้างภูตหมอกเงาในโบราณสถาน 2 ตน", "type": "purify_wisps", "target": 2, "gold": 220, "guild_xp": 60, "stat": {"courage": 14}},
	{"id": "gb_mine_ore", "rank": "E", "title_th": "สกัดแร่มานาใต้รากไม้โลก", "desc_th": "ขุดสกัดแร่มานาภายในโบราณสถานใต้รากไม้ 2 ก้อน", "type": "mine_ores", "target": 2, "gold": 240, "guild_xp": 65, "stat": {"craft": 12, "courage": 8}},
	{"id": "gb_fish_pearl", "rank": "E", "title_th": "ล่าปลาและวัตถุดิบทะเลสาบมุก", "desc_th": "ตกปลาที่ริมทะเลสาบมุกให้สำเร็จ 2 ตัว", "type": "catch_fish", "target": 2, "gold": 230, "guild_xp": 60, "stat": {"wisdom": 10, "craft": 8}},
	{"id": "gb_oak_timber", "rank": "D", "title_th": "ซ่อมแซมสะพานด้วยไม้โอ๊กเนื้อแข็ง", "desc_th": "นำไม้โอ๊กเนื้อแข็ง 2 ท่อนมาส่งที่เคาน์เตอร์กิลด์", "type": "deliver_item", "item_id": "item_hard_oak", "target": 2, "gold": 280, "guild_xp": 80, "stat": {"craft": 15}},
	{"id": "gb_ruins_b1", "rank": "D", "title_th": "สำรวจและปลดผนึกเสาแสงชั้น B1", "desc_th": "ไขปริศนาเสาปริซึมปลดผนึกโบราณสถานชั้น B1 ให้สำเร็จ", "type": "clear_floor", "floor_id": "ruins_b1", "target": 1, "gold": 320, "guild_xp": 95, "stat": {"wisdom": 16, "courage": 12}},
	{"id": "gb_wisp_sweep", "rank": "C", "title_th": "ปฏิบัติการชำระล้างหมอกเงาเชิงลึก", "desc_th": "ชำระล้างภูตหมอกเงาด้วยคลื่นแสง [F] รวม 4 ตน", "type": "purify_wisps", "target": 4, "gold": 420, "guild_xp": 120, "stat": {"courage": 22}},
	{"id": "gb_ruins_b2", "rank": "C", "title_th": "พิชิตโถงกระจกวารีชั้น B2", "desc_th": "ไขปริศนาเสาแสงคู่ในโบราณสถานชั้น B2 ให้สำเร็จ", "type": "clear_floor", "floor_id": "ruins_b2", "target": 1, "gold": 460, "guild_xp": 135, "stat": {"wisdom": 22, "courage": 16}},
	{"id": "gb_starfall", "rank": "B", "title_th": "ตามหาผลึกดาวตกแห่งวิหารโบราณ", "desc_th": "รวบรวมผลึกดาวตก 1 ชิ้นส่งให้นักวิจัยกิลด์", "type": "deliver_item", "item_id": "item_starfall_crystal", "target": 1, "gold": 560, "guild_xp": 160, "stat": {"wisdom": 25}},
	{"id": "gb_boss_b4", "rank": "S", "title_th": "ภารกิจระดับ S: ปราบบอสผู้พิทักษ์ชั้น B4!", "desc_th": "ทลายเกราะเสาแสงและใช้ [F] ชำระล้างบอสผู้พิทักษ์รากไม้ต้องสาป!", "type": "purify_boss", "target": 1, "gold": 1200, "guild_xp": 320, "stat": {"courage": 40, "wisdom": 30, "charm": 20}}
]

const CREATOR_OPTIONS := {
	"builds": [
		{"id": "slim", "name_th": "เพรียวบาง"},
		{"id": "normal", "name_th": "สมส่วน"},
		{"id": "sturdy", "name_th": "กำยำ"}
	],
	"skins": [
		{"id": "fair", "name_th": "ขาวอมชมพู", "hex": "#fde2cf"},
		{"id": "cream", "name_th": "ผิวครีม", "hex": "#f5cfa6"},
		{"id": "honey", "name_th": "ผิวแทนน้ำผึ้ง", "hex": "#d99b66"},
		{"id": "bronze", "name_th": "สีน้ำตาลเข้ม", "hex": "#9a633b"},
		{"id": "pale", "name_th": "ขาวจันทรา", "hex": "#eef2ff"},
		{"id": "drow", "name_th": "ดาร์กเอลฟ์", "hex": "#8b7da8"},
		{"id": "goblin", "name_th": "เขียวมรกต", "hex": "#86b86b"},
		{"id": "aqua", "name_th": "ฟ้าสมุทร", "hex": "#7dd3fc"}
	],
	"hair_styles": [
		{"id": "short_spiky", "name_th": "ผมสั้นตั้ง"},
		{"id": "long_flow", "name_th": "ผมยาวสลวย"},
		{"id": "ponytail", "name_th": "มัดหางม้า"},
		{"id": "twin_tails", "name_th": "ทวินเทล"},
		{"id": "bob_cut", "name_th": "ผมบ็อบ"},
		{"id": "braid", "name_th": "ถักเปียข้าง"},
		{"id": "wild_mane", "name_th": "ผมฟูนักผจญภัย"},
		{"id": "noble_part", "name_th": "แสกข้างคุณชาย/คุณหนู"}
	],
	"hair_colors": [
		{"name_th": "ดำรัตติกาล", "hex": "#1e293b"},
		{"name_th": "น้ำตาลเกาลัด", "hex": "#6b3e26"},
		{"name_th": "ทองอรุณ", "hex": "#eab308"},
		{"name_th": "แดงเพลิง", "hex": "#dc2626"},
		{"name_th": "เงินจันทรา", "hex": "#cbd5e1"},
		{"name_th": "ชมพูซากุระ", "hex": "#f472b6"},
		{"name_th": "ฟ้าคราม", "hex": "#2563eb"},
		{"name_th": "เขียวมรกต", "hex": "#16a34a"},
		{"name_th": "ม่วงอเมทิสต์", "hex": "#7c3aed"},
		{"name_th": "ขาวหิมะ", "hex": "#f8fafc"}
	],
	"eye_styles": [
		{"id": "round", "name_th": "ตากลมโต"},
		{"id": "sharp", "name_th": "ตาคมเฉี่ยว"},
		{"id": "gentle", "name_th": "ตาอบอุ่น"},
		{"id": "mystic", "name_th": "ตาลึกลับ"}
	],
	"eye_colors": [
		{"name_th": "น้ำตาล", "hex": "#5c3312"},
		{"name_th": "ฟ้าคราม", "hex": "#0284c7"},
		{"name_th": "มรกต", "hex": "#15803d"},
		{"name_th": "ทองอำพัน", "hex": "#d97706"},
		{"name_th": "แดงทับทิม", "hex": "#dc2626"},
		{"name_th": "ม่วงเวท", "hex": "#7e22ce"},
		{"name_th": "ชมพู", "hex": "#db2777"},
		{"name_th": "เงิน", "hex": "#64748b"}
	],
	"outfit_styles": [
		{"id": "adventurer", "name_th": "ชุดนักผจญภัย"},
		{"id": "knight", "name_th": "เกราะเบาอัศวิน"},
		{"id": "mage", "name_th": "เสื้อคลุมจอมเวท"},
		{"id": "tunic", "name_th": "เสื้อกั๊กชาวเมือง"},
		{"id": "bard", "name_th": "ชุดนักดนตรี"},
		{"id": "royal", "name_th": "ชุดราชวงศ์"}
	],
	"shirt_colors": [
		{"name_th": "เขียวพงไพร", "hex": "#15803d"},
		{"name_th": "น้ำเงินอัศวิน", "hex": "#1d4ed8"},
		{"name_th": "แดงชาด", "hex": "#b91c1c"},
		{"name_th": "ม่วงจอมเวท", "hex": "#6d28d9"},
		{"name_th": "ครีมอบอุ่น", "hex": "#d97706"},
		{"name_th": "ดำเงา", "hex": "#334155"},
		{"name_th": "ชมพูกุหลาบ", "hex": "#be185d"},
		{"name_th": "ขาวบริสุทธิ์", "hex": "#e2e8f0"}
	],
	"pants_colors": [
		{"name_th": "น้ำตาลหนัง", "hex": "#5c3312"},
		{"name_th": "กรมท่า", "hex": "#1e3a5f"},
		{"name_th": "เทาเข้ม", "hex": "#334155"},
		{"name_th": "ดำสนิท", "hex": "#111827"},
		{"name_th": "เขียวเข้ม", "hex": "#14532d"},
		{"name_th": "ขาวครีม", "hex": "#cbd5e1"}
	]
}

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
		"skip_cutscene": [KEY_TAB],
		"open_guild": [KEY_Q],
		"toggle_mount": [KEY_V]
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

func get_guild_rank_info(gxp: int) -> Dictionary:
	var best: Dictionary = GUILD_RANKS[0]
	for r in GUILD_RANKS:
		if gxp >= int(r["xp_req"]):
			best = r
	return best

func get_guild_bounty_def(bid: String) -> Dictionary:
	for gb in GUILD_BOUNTIES:
		if str(gb["id"]) == bid:
			return gb
	return {}

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
