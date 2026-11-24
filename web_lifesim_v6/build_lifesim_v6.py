#!/usr/bin/env python3
"""
build_lifesim_v6.py — Aethelgard: Echoes of the World Tree (Life-Sim v6.0 Builder)
===================================================================================
Bundles all 284 2.5D HD-2D sprite assets + all 11 Game_Data_JSON files into a single
self-contained playable HTML5 Life-Sim game (`aethelgard_world_map.html`) featuring
all 6 Deep Gameplay Systems:
  1. แต่งตัวเอก 8 เผ่า (8-Race / 16-Silhouette Protagonist Customizer + Outline-Preserving HSV & 7 Skin Tints + Race Perks)
  2. 6 มินิเกมแยกสาย (Forge/Oven Heat, Tavern/Shop Order Rush, Herbal/Archive Rune Memory, Courier/Patrol Sky Dash, Stardew Tension Fishing, 4-Lane Rhythm Concert)
  3. แต่งงาน & ชีวิตคู่ (World Tree Ring, 10-Heart Proposal, Grand Wedding Ceremony, Spouse Living at Home, Morning Meals & Romantic Dates)
  4. แต่งบ้านวางเฟอร์นิเจอร์บนตาราง & ขยายชั้น 2 (Interactive Grid Placement Mode [H] with Rotate [R] & 12 Items + 2nd Floor Starlight Loft)
  5. โบราณสถานใต้รากไม้โลก & ปริศนาเสาแสง (3-Floor Under-Root Sanctum B1-B3 + Real-Time Raycasted Prism Beam Puzzles + Daily Mana Ore)
  6. เซฟ 3 ช่อง + BGM แยกโซน (3 Save Slots with Live Previews & JSON Export/Import + 7 Zone-Specific Procedural Web Audio BGM Tracks)
"""

import argparse
import base64
import glob
import json
import os
import sys


def b64_file(path: str) -> str:
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode("ascii")


def load_all_assets(src_dir: str) -> dict:
    """Load all 284 PNG sprite files and 11 JSON datasets from Aethelgard_SpriteSheets."""
    json_dir = os.path.join(src_dir, "Game_Data_JSON")
    game_data = {}
    json_names = [
        "characters", "dialogues", "schedules", "quests", "social_stats",
        "jobs", "items", "events", "landmarks", "story_chronicles", "world_map"
    ]
    for name in json_names:
        jpath = os.path.join(json_dir, f"{name}.json")
        if not os.path.exists(jpath):
            raise FileNotFoundError(f"Missing required JSON dataset: {jpath}")
        with open(jpath, "r", encoding="utf-8") as f:
            game_data[name] = json.load(f)

    walk_b64 = {}
    idle_b64 = {}
    int_b64 = {}
    port_b64 = {}

    for ch in game_data["characters"]["characters"]:
        cid = ch["id"]
        walk_b64[cid] = b64_file(os.path.join(src_dir, "Walk_9x4_25D_16Chars_576x256", f"{cid}_walk_9x4.png"))
        idle_b64[cid] = b64_file(os.path.join(src_dir, "Idle_6x4_25D_16Chars_384x256", f"{cid}_idle_6x4.png"))
        int_b64[cid] = b64_file(os.path.join(src_dir, "Interact_8x4_25D_16Chars_512x256", f"{cid}_interact_8x4.png"))

        pdir = os.path.join(src_dir, "Portraits_Style2")
        port_b64[cid] = b64_file(os.path.join(pdir, f"{cid}_neutral_256.png"))
        for emo in ("happy", "blush", "sad"):
            epath = os.path.join(pdir, f"{cid}_{emo}_256.png")
            if os.path.exists(epath):
                port_b64[f"{cid}_{emo}"] = b64_file(epath)

    pet_b64 = {
        "cat": b64_file(os.path.join(src_dir, "Pets_4x4_25D_256x256", "pet_cat_4x4.png")),
        "dog": b64_file(os.path.join(src_dir, "Pets_4x4_25D_256x256", "pet_dog_4x4.png")),
        "fairy": b64_file(os.path.join(src_dir, "Pets_4x4_25D_256x256", "pet_fairy_4x4.png")),
    }

    item_icon_b64 = {}
    for ipath in sorted(glob.glob(os.path.join(src_dir, "Items_Icons_39", "32x32", "*.png"))):
        iid = os.path.splitext(os.path.basename(ipath))[0]
        item_icon_b64[iid] = b64_file(ipath)

    wdir = os.path.join(src_dir, "World_Sprites_25D")
    world_b64 = {
        "tileset_seasons": b64_file(os.path.join(wdir, "tileset_seasons_8x3_256x96.png")),
        "props_and_trees": b64_file(os.path.join(wdir, "props_and_trees_8x2_512x192.png")),
        "world_tree_states": b64_file(os.path.join(wdir, "world_tree_states_2x1_512x256.png")),
        "buildings": {},
        "landmarks": {},
    }
    for bname in ("farmhouse", "shop", "bakery", "tavern", "smithy", "cottage"):
        bpath = os.path.join(wdir, "buildings", f"house_{bname}.png")
        if os.path.exists(bpath):
            world_b64["buildings"][bname] = b64_file(bpath)
    for lm in ("lm_observatory", "lm_hotspring", "lm_museum", "lm_stage", "lm_nightmarket"):
        for st in ("ruined", "restored"):
            lpath = os.path.join(wdir, "landmarks", f"{lm}_{st}.png")
            if os.path.exists(lpath):
                world_b64["landmarks"][f"{lm}_{st}"] = b64_file(lpath)

    total_pngs = len(glob.glob(os.path.join(src_dir, "**", "*.png"), recursive=True))
    print(f"[build_lifesim_v6] Verified source sprite library: {total_pngs} PNGs, {len(game_data)} JSON datasets.")
    return {
        "game_data": game_data,
        "walk_b64": walk_b64,
        "idle_b64": idle_b64,
        "int_b64": int_b64,
        "port_b64": port_b64,
        "pet_b64": pet_b64,
        "item_icon_b64": item_icon_b64,
        "world_b64": world_b64,
        "total_pngs": total_pngs,
    }


HTML_HEAD_AND_BODY = r"""<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Aethelgard: Echoes of the World Tree — Life-Sim v6.0 (Complete 6 Deep Gameplay Systems)</title>
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+Thai:wght@400;600;700;800&display=swap" rel="stylesheet" />
  <style>
    * { box-sizing: border-box; user-select: none; }
    html, body {
      margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden;
      background: #0f172a; font-family: 'Noto Sans Thai', system-ui, sans-serif; color: #2b1608;
    }
    #gameWrap { position: relative; width: 100vw; height: 100vh; overflow: hidden; }
    canvas#gameCanvas {
      display: block; width: 100%; height: 100%;
      image-rendering: pixelated; image-rendering: crisp-edges;
    }
    .pixelated { image-rendering: pixelated; image-rendering: crisp-edges; }
    .sd-wood {
      background: linear-gradient(180deg, #9f5b24 0%, #7d4117 50%, #5b2c0d 100%);
      border: 3px solid #2b1205; border-radius: 10px; padding: 5px;
      box-shadow: inset 0 2px 0 #df9f53, inset 0 -2px 0 #3f1b08, 0 8px 20px rgba(0,0,0,0.55);
    }
    .sd-parchment {
      background: linear-gradient(180deg, #fbf0d9 0%, #f4dfb7 60%, #ebd09d 100%);
      border: 2px solid #9e6530; border-radius: 6px; padding: 6px 10px;
      box-shadow: inset 0 1px 0 #fff9ec;
    }
    .sd-btn {
      background: linear-gradient(180deg, #f8e5be 0%, #e1bc7c 100%);
      border: 2px solid #6b3814; border-radius: 6px; color: #2e1708; font-weight: 800;
      font-size: 12px; padding: 4px 8px; cursor: pointer;
      box-shadow: inset 0 1px 0 #fff7e2, 0 2px 0 #4d250b;
      transition: transform 0.08s, filter 0.1s;
    }
    .sd-btn:hover:not(:disabled) { filter: brightness(1.07); }
    .sd-btn:active:not(:disabled) { transform: translateY(1px); }
    .sd-btn:disabled { opacity: 0.55; cursor: not-allowed; }
    .sd-btn.active { background: linear-gradient(180deg, #fde047 0%, #eab308 100%); }
    .sd-btn.green { background: linear-gradient(180deg, #d7f5dc 0%, #8ed19d 100%); border-color: #1f5c2f; color: #0b3b19; }
    .sd-btn.pink  { background: linear-gradient(180deg, #fce7f3 0%, #f9a8d4 100%); border-color: #9d174d; color: #500724; }
    .sd-btn.blue  { background: linear-gradient(180deg, #dbeafe 0%, #93c5fd 100%); border-color: #1e40af; color: #1e3a8a; }
    .sd-btn.purple{ background: linear-gradient(180deg, #ede9fe 0%, #c4b5fd 100%); border-color: #5b21b6; color: #3b0764; }
    .sd-btn.red   { background: linear-gradient(180deg, #fee2e2 0%, #fca5a5 100%); border-color: #991b1b; color: #7f1d1d; }

    #titleOverlay, #daySummaryOverlay {
      position: absolute; inset: 0; z-index: 80;
      background: radial-gradient(circle at 50% 35%, rgba(28,54,36,0.9), rgba(9,13,24,0.97));
      display: flex; align-items: center; justify-content: center; padding: 14px; overflow-y: auto;
    }
    #daySummaryOverlay { display: none; z-index: 78; background: radial-gradient(circle at 50% 35%, rgba(24,24,58,0.92), rgba(8,10,22,0.97)); }
    #titleCard { width: min(740px, 96vw); text-align: center; }
    #daySummaryCard { width: min(560px, 95vw); text-align: center; }

    .slot-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; text-align: left; }
    @media (max-width: 680px) { .slot-grid { grid-template-columns: 1fr; } }
    .slot-card {
      background: rgba(255,250,238,0.9); border: 2px solid #b57b3d; border-radius: 8px;
      padding: 8px 10px; cursor: pointer; transition: transform 0.1s, border-color 0.15s;
      display: flex; flex-direction: column; justify-content: space-between; gap: 4px;
    }
    .slot-card.selected {
      border: 3px solid #d97706; background: linear-gradient(180deg, #fffbeb 0%, #fef08a 100%);
      box-shadow: 0 0 0 2px rgba(251,191,36,0.45);
    }

    #hud-top-left { position: absolute; top: 10px; left: 10px; z-index: 20; display: flex; flex-direction: column; gap: 5px; width: 236px; }
    #hud-top-right { position: absolute; top: 10px; right: 10px; z-index: 20; width: 280px; }
    #hud-bottom {
      position: absolute; bottom: 10px; left: 50%; transform: translateX(-50%); z-index: 20;
      display: flex; align-items: center; gap: 8px;
    }

    /* Home Grid Placement Bar ([H]) */
    #homeEditBar {
      position: absolute; top: 10px; left: 50%; transform: translateX(-50%); z-index: 32;
      display: none; width: min(680px, 92vw);
    }
    .decor-strip { display: flex; gap: 5px; overflow-x: auto; padding: 4px 2px; }

    /* Stardew-Style Full-Screen Illustrated Valley Map ([M]) */
    #worldMapOverlay {
      position: absolute; inset: 0; background: rgba(14, 10, 6, 0.8); z-index: 52;
      display: none; align-items: center; justify-content: center; padding: 14px;
    }
    #worldMapCard { width: min(920px, 96vw); }
    #worldMapCanvas {
      display: block; width: 100%; height: auto; aspect-ratio: 840 / 540;
      border: 3px solid #5b2c0d; border-radius: 6px; cursor: pointer;
      box-shadow: inset 0 0 24px rgba(91, 44, 13, 0.35); background: #e9d2a2;
    }
    .wm-info-bar {
      margin-top: 8px; padding: 7px 10px; background: rgba(255, 250, 236, 0.92);
      border: 2px solid #b57b3d; border-radius: 6px;
      display: flex; justify-content: space-between; align-items: center; gap: 10px; flex-wrap: wrap;
      font-size: 12.5px; font-weight: 700; color: #3f1d0b;
    }

    #questTrackerBox { display: none; }
    .qt-bar-bg { height: 5px; background: #d6b685; border-radius: 3px; overflow: hidden; margin-top: 3px; }
    .qt-bar-fill { height: 100%; background: #16a34a; transition: width 0.25s; }

    .stat-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 4px; margin-top: 3px; }
    .stat-pill {
      background: rgba(255,248,232,0.82); border: 1.5px solid #b57b3d; border-radius: 5px;
      padding: 2px 5px; font-size: 10px; font-weight: 800; display: flex; flex-direction: column; gap: 2px;
    }
    .stat-bar-bg { height: 4px; background: #d6b685; border-radius: 3px; overflow: hidden; }
    .stat-bar-fill { height: 100%; border-radius: 3px; transition: width 0.25s; }

    #interactPrompt {
      position: absolute; bottom: 84px; left: 50%; transform: translateX(-50%); z-index: 25;
      display: none; pointer-events: none;
    }
    #interactPrompt .sd-parchment {
      padding: 5px 14px; font-size: 13px; font-weight: 800; color: #2b1608;
      display: flex; align-items: center; gap: 6px;
    }

    #dialogueOverlay {
      position: absolute; bottom: 14px; left: 50%; transform: translateX(-50%); z-index: 40;
      width: min(900px, 95vw); display: none;
    }
    .dlg-inner { display: grid; grid-template-columns: 1fr 146px; gap: 12px; align-items: center; }
    .portrait-col { display: flex; flex-direction: column; align-items: center; gap: 5px; }
    .portrait-box {
      width: 140px; height: 140px; border: 3px solid #6b3410; border-radius: 6px;
      background: linear-gradient(180deg, #e7d0a3 0%, #d3b27c 100%);
      display: flex; align-items: center; justify-content: center; overflow: hidden;
      transition: border-color 0.2s ease, box-shadow 0.2s ease;
    }
    .portrait-box.emo-happy { border-color: #d97706; box-shadow: inset 0 0 14px rgba(253, 224, 71, 0.55); }
    .portrait-box.emo-blush { border-color: #db2777; box-shadow: inset 0 0 14px rgba(244, 114, 182, 0.52); }
    .portrait-box.emo-sad   { border-color: #475569; box-shadow: inset 0 0 14px rgba(100, 116, 139, 0.48); }
    #dlgEmotionBadge {
      font-size: 10.5px; font-weight: 800; padding: 2px 10px; border-radius: 99px;
      background: #f5dfb2; border: 1.5px solid #9e6530; color: #4c230a;
      white-space: nowrap; text-align: center;
    }
    .choice-list { display: flex; flex-direction: column; gap: 6px; margin-top: 8px; }
    .choice-btn {
      text-align: left; padding: 7px 10px; font-size: 13px; font-weight: 700;
      background: linear-gradient(180deg, #fff6e0, #ecd19e); border: 2px solid #854d0e;
      border-radius: 6px; cursor: pointer; color: #2b1608;
    }
    .choice-btn:hover { background: linear-gradient(180deg, #fef08a, #f59e0b); }

    /* Upgraded 6-Discipline Interactive Mini-Game Suite */
    #miniGameOverlay {
      position: absolute; inset: 0; background: rgba(9, 13, 24, 0.78); z-index: 60;
      display: none; align-items: center; justify-content: center; padding: 14px;
    }
    #miniGameCard { width: min(560px, 95vw); text-align: center; }
    #mgCanvas {
      display: block; width: 100%; max-width: 480px; height: auto; margin: 10px auto;
      border: 3px solid #4c230a; border-radius: 8px; background: #0f172a; cursor: pointer;
    }

    #modalBackdrop {
      position: absolute; inset: 0; background: rgba(15, 10, 5, 0.72); z-index: 70;
      display: none; align-items: center; justify-content: center; padding: 14px;
    }
    #modalBox { width: min(840px, 96vw); max-height: 89vh; display: flex; flex-direction: column; }
    #modalInner { display: flex; flex-direction: column; max-height: 85vh; padding: 12px 14px; }
    #modalHeader {
      display: flex; justify-content: space-between; align-items: center;
      border-bottom: 2px solid #b88244; padding-bottom: 8px; margin-bottom: 10px;
    }
    #modalTitle { font-size: 17px; font-weight: 800; color: #4c230a; }
    #modalBody { overflow-y: auto; display: flex; flex-direction: column; gap: 8px; padding-right: 4px; }

    .card-row {
      background: rgba(255,250,238,0.9); border: 1.5px solid #b57b3d; border-radius: 8px;
      padding: 9px 11px; display: flex; justify-content: space-between; align-items: center; gap: 10px;
    }
    .card-row.locked { opacity: 0.68; background: rgba(226,204,168,0.65); }
    .badge {
      display: inline-block; font-size: 10px; font-weight: 800; padding: 2px 6px;
      border-radius: 99px; background: #e7c996; border: 1px solid #9e6530; color: #4c230a;
    }
    .tab-bar { display: flex; gap: 6px; flex-wrap: wrap; margin-bottom: 6px; }
    .pet-choice { display: flex; gap: 6px; justify-content: center; flex-wrap: wrap; }
    .sum-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; text-align: left; margin: 10px 0; }
    .sum-cell {
      background: rgba(255,250,238,0.88); border: 1.5px solid #b57b3d; border-radius: 8px; padding: 8px 10px;
      font-size: 12.5px; font-weight: 700;
    }

    #fadeCurtain {
      position: absolute; inset: 0; background: #090604; opacity: 0; pointer-events: none;
      transition: opacity 0.22s ease; z-index: 65;
    }
    .hotbar-slot {
      min-width: 50px; height: 48px; padding: 0 5px; border: 2px solid #6b3814; border-radius: 6px;
      background: linear-gradient(180deg, #f8e8c6 0%, #dec08b 100%);
      display: flex; flex-direction: column; align-items: center; justify-content: center;
      cursor: pointer; font-size: 16px; position: relative; gap: 1px;
    }
    .hotbar-slot .hotbar-lbl { font-size: 9px; font-weight: 800; color: #4c230a; line-height: 1; }
    .hotbar-slot.active {
      border: 3px solid #d97706; background: linear-gradient(180deg, #fff5d6 0%, #f5cb6c 100%);
      box-shadow: 0 0 0 2px rgba(251,191,36,0.5);
    }
    .hotbar-num { position: absolute; top: 1px; left: 4px; font-size: 9px; font-weight: 800; color: #5b2c0d; }
    .mail-dot {
      position: absolute; top: -4px; right: -4px; width: 15px; height: 15px; border-radius: 50%;
      background: #ef4444; color: #fff; font-size: 9px; font-weight: 800;
      display: none; align-items: center; justify-content: center; border: 1.5px solid #fff;
    }
    #toastBox {
      position: absolute; top: 14px; left: 50%; transform: translateX(-50%); z-index: 88;
      display: none; max-width: 90vw; pointer-events: none;
    }
    #festivalBanner { display: none; margin-top: 3px; text-align: center; }
    .creator-two-col { display: grid; grid-template-columns: 210px 1fr; gap: 10px; align-items: start; }
    @media (max-width: 680px) { .creator-two-col { grid-template-columns: 1fr; } }
    .race-grid { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 5px; }
    @media (max-width: 620px) { .race-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); } }
  </style>
</head>
<body>
  <div id="gameWrap">
    <canvas id="gameCanvas"></canvas>
    <div id="fadeCurtain"></div>

    <!-- Title / Welcome Screen (3 Save Slots + 8-Race Protagonist Creator + Pet Picker!) -->
    <div id="titleOverlay">
      <div id="titleCard" class="sd-wood">
        <div class="sd-parchment" style="padding: 16px 20px; display:flex; flex-direction:column; gap:10px;">
          <div style="font-size:11.5px;font-weight:800;color:#9a3412;letter-spacing:1px;">🌳 AETHELGARD: ECHOES OF THE WORLD TREE</div>
          <div style="font-size:22px;font-weight:800;color:#4c230a;line-height:1.2;">หุบเขาต้นไม้โลก • Life-Sim v6.0 (Complete Edition)</div>
          <div style="font-size:11.5px;color:#5c3312;line-height:1.45;">
            🧙 แต่งตัวเอก 8 เผ่า • 🎮 6 มินิเกมแยกสาย • 💒 แต่งงาน & ชีวิตคู่ • 🛋️ วางเฟอร์นิเจอร์บนตาราง & บ้านชั้น 2 • 🏛️ โบราณสถานรากไม้โลก & ปริศนาเสาแสง • 💾 เซฟ 3 ช่อง + 🎵 BGM 7 โซน
          </div>

          <!-- 3 Save Slots Selector -->
          <div style="background:rgba(255,248,232,0.85);border:1.5px solid #b57b3d;border-radius:8px;padding:8px;">
            <div style="font-size:11.5px;font-weight:800;color:#4c230a;margin-bottom:6px;text-align:left;">💾 เลือกช่องเซฟ (Save Slot 1 – 3):</div>
            <div id="titleSlotGrid" class="slot-grid"></div>
          </div>

          <!-- Hero Preview + Name + 8-Race Customizer Launch -->
          <div style="display:flex;gap:10px;align-items:center;justify-content:space-between;background:rgba(255,248,232,0.88);border:1.5px solid #b57b3d;border-radius:8px;padding:8px 12px;flex-wrap:wrap;">
            <div style="display:flex;align-items:center;gap:10px;">
              <div style="background:#1e293b;border:2px solid #4c230a;border-radius:8px;padding:2px;width:54px;height:54px;display:flex;align-items:center;justify-content:center;">
                <canvas id="titleHeroCanvas" width="64" height="64" class="pixelated" style="width:48px;height:48px;"></canvas>
              </div>
              <div style="text-align:left;">
                <div style="display:flex;align-items:center;gap:6px;flex-wrap:wrap;">
                  <label for="heroNameInput" style="font-size:12px;font-weight:800;">ชื่อตัวเอก:</label>
                  <input id="heroNameInput" type="text" maxlength="16" value="อาริน" style="font-family:inherit;font-size:13px;font-weight:800;padding:3px 8px;border:2px solid #8d4d1d;border-radius:6px;background:#fffbf0;width:128px;" />
                </div>
                <div id="titleHeroSummary" style="font-size:11px;font-weight:700;color:#78350f;margin-top:3px;">🧑 มนุษย์ • 🏡 กระท่อมรากไม้ทอง</div>
              </div>
            </div>
            <button id="btnTitleCreator" type="button" class="sd-btn purple" style="font-size:12.5px;padding:7px 12px;">🧙 แต่งตัวเอก 8 เผ่า & สีชุด</button>
          </div>

          <!-- Pet Picker -->
          <div style="background:rgba(255,248,232,0.85);border:1.5px solid #b57b3d;border-radius:8px;padding:7px;">
            <div style="font-size:11.5px;font-weight:800;margin-bottom:5px;color:#4c230a;">🐾 เลือกคู่หูสัตว์เลี้ยงประจำตัว:</div>
            <div class="pet-choice" id="titlePetPicker">
              <button class="sd-btn active" data-pet="cat">🐱 โมจิ (แมวส้ม)</button>
              <button class="sd-btn" data-pet="dog">🐶 โคริ (ชิบะป่า)</button>
              <button class="sd-btn" data-pet="fairy">🧚 ลูมิ (ภูตแสง)</button>
            </div>
          </div>

          <div style="display:flex;gap:8px;justify-content:center;flex-wrap:wrap;">
            <button id="btnStartPlay" class="sd-btn green" style="font-size:15px;padding:9px 22px;">▶ เข้าสู่เมืองเอเธลการ์ด (เปิดเสียง BGM โซน)</button>
            <button id="btnStartMute" class="sd-btn" style="font-size:13px;padding:9px 14px;">🔇 เล่นแบบปิดเสียง</button>
          </div>
          <div style="font-size:10.5px;color:#78350f;">
            <b>WASD/คลิก</b> เดิน • <b>Shift</b> วิ่ง • <b>M</b> แผนที่ • <b>H</b> จัดเฟอร์นิเจอร์ในบ้าน • <b>P</b> ลูบสัตว์เลี้ยง • <b>E/Space</b> โต้ตอบ
          </div>
        </div>
      </div>
    </div>

    <!-- End-of-Day Summary Screen -->
    <div id="daySummaryOverlay">
      <div id="daySummaryCard" class="sd-wood">
        <div class="sd-parchment" style="padding: 18px 22px; display:flex; flex-direction:column; gap:10px;">
          <div id="sumHeader" style="font-size:20px;font-weight:800;color:#4c230a;">🌙 สรุปผลจบวันที่ 1</div>
          <div id="sumSubtitle" style="font-size:12.5px;color:#6b3814;font-weight:700;">คุณเอนตัวลงนอนอย่างมีความสุขในหุบเขาต้นไม้โลก...</div>
          <div class="sum-grid" id="sumGrid"></div>
          <div id="sumForecast" style="background:rgba(254,249,195,0.85);border:1.5px solid #ca8a04;border-radius:8px;padding:8px;font-size:12px;font-weight:800;color:#713f12;"></div>
          <button id="btnNextDay" class="sd-btn green" style="font-size:15px;padding:10px 24px;margin-top:4px;">🌅 ตื่นรับเช้าวันใหม่!</button>
        </div>
      </div>
    </div>

    <!-- Home Grid Furniture Placement Bar ([H] inside Farmhouse / Upstairs Loft) -->
    <div id="homeEditBar" class="sd-wood">
      <div class="sd-parchment" style="display:flex;flex-direction:column;gap:5px;">
        <div style="display:flex;justify-content:space-between;align-items:center;gap:8px;flex-wrap:wrap;">
          <span style="font-size:12.5px;font-weight:800;color:#4c230a;">🛋️ โหมดวางเฟอร์นิเจอร์บนตาราง — คลิกซ้าย: วาง/ย้าย • ปุ่ม [R]: หมุน • คลิกขวา: เก็บเข้าคลัง</span>
          <div style="display:flex;gap:5px;">
            <button class="sd-btn blue" onclick="window.rotateSelectedDecor()">🔄 หมุน [R]</button>
            <button class="sd-btn green" onclick="window.openShopBagModal('decor')">🛒 ซื้อเพิ่ม/ขยายชั้น 2</button>
            <button class="sd-btn red" onclick="window.toggleHomeEditMode(false)">✕ เสร็จสิ้น [H]</button>
          </div>
        </div>
        <div id="homeEditCatalog" class="decor-strip"></div>
      </div>
    </div>

    <!-- Top-Left HUD -->
    <div id="hud-top-left">
      <div class="sd-wood">
        <div class="sd-parchment" style="padding:6px 8px;display:flex;justify-content:space-between;align-items:center;gap:6px;">
          <div style="display:flex;flex-direction:column;gap:1px;min-width:0;">
            <span id="bgmZoneLabel" style="font-size:9.5px;font-weight:800;color:#7c2d12;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">🎵 ลมหายใจต้นไม้โลก</span>
            <span id="zoneLabel" style="font-size:12px;font-weight:800;color:#14532d;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">จัตุรัสต้นไม้โลก</span>
          </div>
          <button id="btnOpenMap" class="sd-btn active" style="font-size:11px;padding:5px 7px;white-space:nowrap;" title="เปิดแผนที่หุบเขาแบบ Stardew (ปุ่ม M)">🗺️ แผนที่ [M]</button>
        </div>
      </div>
      <div class="sd-wood" style="cursor:pointer;" onclick="window.openStoryModal('main')">
        <div class="sd-parchment" style="padding:5px 8px;display:flex;justify-content:space-between;align-items:center;font-size:11px;font-weight:800;">
          <span>📖 เนื้อเรื่อง & คดี</span>
          <span id="storySealBadge" style="color:#b45309;">0/15 บท • 0/8 เผ่า</span>
        </div>
      </div>
      <div class="sd-wood" style="cursor:pointer;" onclick="window.openTownModal('landmarks')">
        <div class="sd-parchment" style="padding:5px 8px;display:flex;justify-content:space-between;align-items:center;font-size:11px;font-weight:800;">
          <span>🏛️ เมือง & โบราณสถาน</span>
          <span id="townRestoreBadge" style="color:#0f766e;">0/5 • 🔦0/3</span>
        </div>
      </div>
      <div id="homeContextBtnWrap" class="sd-wood" style="display:none;">
        <div class="sd-parchment" style="padding:5px 8px;display:flex;justify-content:space-between;align-items:center;gap:4px;">
          <button class="sd-btn active" style="width:100%;font-size:11px;" onclick="window.toggleHomeEditMode()">🛋️ จัดเฟอร์นิเจอร์บนตาราง [H]</button>
        </div>
      </div>
      <div id="ruinsContextBtnWrap" class="sd-wood" style="display:none;">
        <div class="sd-parchment" style="padding:5px 8px;display:flex;justify-content:space-between;align-items:center;gap:4px;">
          <span id="ruinsFloorStatus" style="font-size:10.5px;font-weight:800;color:#0f766e;">🔦 เสาแสง: 0/1</span>
          <button class="sd-btn blue" style="font-size:10px;padding:2px 6px;" onclick="window.resetRuinsFloor()">↺ รีเซ็ตเสา</button>
        </div>
      </div>
      <div id="questTrackerBox" class="sd-wood">
        <div class="sd-parchment" style="padding:6px 8px;cursor:pointer;" onclick="window.openQuestsModal()">
          <div style="font-size:10px;font-weight:800;color:#9a3412;">📌 เควสต์ที่กำลังทำ</div>
          <div id="qtTitle" style="font-size:11.5px;font-weight:800;color:#2b1608;margin-top:1px;">-</div>
          <div id="qtStatus" style="font-size:10.5px;font-weight:700;color:#15803d;">-</div>
          <div class="qt-bar-bg"><div id="qtBar" class="qt-bar-fill" style="width:0%;"></div></div>
        </div>
      </div>
      <div id="compassBox" class="sd-wood" style="display:none;">
        <div class="sd-parchment" style="padding:5px 8px;display:flex;justify-content:space-between;align-items:center;font-size:11px;font-weight:800;">
          <span id="compassLabel">🧭 กำลังนำทาง...</span>
          <button class="sd-btn" style="font-size:9px;padding:1px 5px;" onclick="window.clearCompass()">✕</button>
        </div>
      </div>
    </div>

    <!-- Top-Right HUD -->
    <div id="hud-top-right">
      <div class="sd-wood">
        <div class="sd-parchment" style="display:flex;flex-direction:column;gap:4px;">
          <div style="display:flex;justify-content:space-between;align-items:center;font-weight:800;font-size:12px;">
            <span id="dayLabel">☀️ จ. วันที่ 1 • ใบไม้ผลิ</span>
            <span id="clockLabel" style="color:#9a3412;font-family:monospace;font-size:13px;">08:00</span>
          </div>
          <div id="festivalBanner">
            <button id="btnJoinFestival" class="sd-btn active" style="width:100%;font-size:11px;padding:3px;">🎉 วันเทศกาล! กดเข้าร่วมงาน</button>
          </div>
          <div style="display:flex;justify-content:space-between;align-items:center;font-size:12px;font-weight:800;border-top:1px solid #caa068;padding-top:4px;">
            <span>🪙 <span id="goldLabel">500</span> G</span>
            <span>⚡ <span id="staminaLabel">100</span>/<span id="maxStaminaLabel">100</span></span>
            <span id="heroNameBadge" style="font-size:10.5px;color:#7c2d12;max-width:96px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">👤 อาริน</span>
          </div>
          <div class="stat-grid" id="socialStatsHud"></div>
          <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:3px;margin-top:3px;">
            <button id="btn-time-skip" class="sd-btn" style="font-size:10px;padding:3px;">⏩ +2ชม.</button>
            <button id="btn-weather" class="sd-btn blue" style="font-size:10px;padding:3px;">🌧️ อากาศ</button>
            <button id="btn-char-custom" class="sd-btn purple" style="font-size:10px;padding:3px;">🧙 แต่งตัว</button>
            <button id="btn-audio" class="sd-btn" style="font-size:10px;padding:3px;">🔊 เสียง</button>
            <button id="btn-save-slots" class="sd-btn green" style="font-size:10px;padding:3px;">💾 เซฟ 3 ช่อง</button>
            <button id="btn-ruins-warp" class="sd-btn active" style="font-size:10px;padding:3px;" title="เดินทางไปรากต้นไม้โลก / โบราณสถาน">🔦 รากไม้</button>
          </div>
          <div style="font-size:9.5px;color:#693914;line-height:1.3;">
            <b>Shift</b> วิ่ง • <b>M</b> แผนที่ • <b>H</b> แต่งบ้าน • <b>P</b> ลูบสัตว์ • <b>1–9</b> เมนู
          </div>
        </div>
      </div>
    </div>

    <div id="toastBox" class="sd-wood">
      <div class="sd-parchment" id="toastText" style="font-size:13px;font-weight:800;color:#14532d;">-</div>
    </div>

    <div id="interactPrompt" class="sd-wood">
      <div class="sd-parchment" id="interactPromptText">กด [E] เพื่อโต้ตอบ</div>
    </div>

    <!-- Bottom Life-Sim Hotbar -->
    <div id="hud-bottom">
      <div class="sd-wood">
        <div class="sd-parchment" style="display:flex;gap:4px;padding:5px;">
          <div class="hotbar-slot active" data-tool="0" title="เดิน / คุย / เข้าบ้าน / ตกปลา / หมุนเสาแสง"><span class="hotbar-num">1</span><span>🖐️</span><span class="hotbar-lbl">เดิน/คุย</span></div>
          <div class="hotbar-slot" data-tool="1" title="งานพาร์ทไทม์ 8 อาชีพ (6 มินิเกมแยกสาย!)"><span class="hotbar-num">2</span><span>💼</span><span class="hotbar-lbl">งานเสริม</span></div>
          <div class="hotbar-slot" data-tool="2" title="ร้านค้า / กระเป๋า / เฟอร์นิเจอร์ & ขยายชั้น 2"><span class="hotbar-num">3</span><span>🛍️</span><span class="hotbar-lbl">ร้าน/บ้าน</span></div>
          <div class="hotbar-slot" data-tool="3" title="คราฟต์ของขวัญ อาหาร & แหวนแต่งงาน"><span class="hotbar-num">4</span><span>🍳</span><span class="hotbar-lbl">คราฟต์</span></div>
          <div class="hotbar-slot" data-tool="4" title="ความสัมพันธ์ 16 ตัวละคร / แต่งงาน & ชีวิตคู่"><span class="hotbar-num">5</span><span>💕</span><span class="hotbar-lbl">คู่รัก/เพื่อน</span></div>
          <div class="hotbar-slot" data-tool="5" title="เควสต์กระดานข่าว & เนื้อเรื่อง 4 สาย"><span class="hotbar-num">6</span><span>📜</span><span class="hotbar-lbl">เควสต์</span></div>
          <div class="hotbar-slot" data-tool="6" title="ตู้จดหมายหน้าบ้าน"><span class="hotbar-num">7</span><span>📮</span><span class="hotbar-lbl">จดหมาย</span><span id="mailBadge" class="mail-dot">1</span></div>
          <div class="hotbar-slot" data-tool="7" title="ปฏิทิน วันเกิด & ความสำเร็จ"><span class="hotbar-num">8</span><span>📅</span><span class="hotbar-lbl">ปฏิทิน</span></div>
          <div class="hotbar-slot" data-tool="8" title="ตะเกียงส่องสว่างยามค่ำ & ในโบราณสถาน"><span class="hotbar-num">9</span><span>🏮</span><span class="hotbar-lbl">ตะเกียง</span></div>
        </div>
      </div>
    </div>

    <!-- Stardew-Style Dialogue Overlay (Upgraded with Marriage & Spouse Life Actions!) -->
    <div id="dialogueOverlay" class="sd-wood">
      <div class="sd-parchment dlg-inner">
        <div style="display:flex;flex-direction:column;justify-content:space-between;gap:8px;min-height:142px;">
          <div>
            <div style="display:flex;justify-content:space-between;align-items:center;border-bottom:1.5px solid #c49257;padding-bottom:4px;margin-bottom:6px;gap:8px;flex-wrap:wrap;">
              <div>
                <span id="dlgName" style="font-weight:800;font-size:15px;color:#4c230a;">-</span>
                <span id="dlgMeta" class="badge" style="margin-left:6px;">-</span>
                <span id="dlgPartnerBadge" class="badge" style="display:none;background:#fce7f3;color:#9d174d;border-color:#db2777;margin-left:4px;">💑 คู่รัก</span>
                <span id="dlgSpouseBadge" class="badge" style="display:none;background:#fef08a;color:#854d0e;border-color:#ca8a04;margin-left:4px;">💒 คู่สมรส</span>
              </div>
              <span id="dlgHearts" style="font-size:13px;letter-spacing:1px;">❤️❤️❤️🤍🤍</span>
            </div>
            <div id="dlgBody" style="font-size:14px;font-weight:600;line-height:1.55;color:#2b1608;min-height:44px;cursor:pointer;" title="คลิกเพื่อแสดงข้อความทั้งหมด">-</div>
            <div id="dlgChoices" class="choice-list" style="display:none;"></div>
          </div>
          <div id="dlgActions" style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:5px;">
            <div style="display:flex;gap:5px;flex-wrap:wrap;">
              <button id="btnGiveGift" class="sd-btn green">🎁 มอบของขวัญ</button>
              <button id="btnHangout" class="sd-btn pink">☕ ชวน Hangout</button>
              <button id="btnHeartEvent" class="sd-btn active" style="display:none;">💖 อีเวนต์หัวใจ!</button>
              <button id="btnConfess" class="sd-btn pink" style="display:none;">💍 สารภาพรัก</button>
              <button id="btnProposeMarriage" class="sd-btn active" style="display:none;">💒 ขอแต่งงาน!</button>
              <button id="btnSpouseCare" class="sd-btn green" style="display:none;">🍳 รับมื้อเช้าคู่รัก</button>
              <button id="btnSpouseDate" class="sd-btn purple" style="display:none;">🌙 เดตคู่สมรส</button>
              <button id="btnNpcJob" class="sd-btn blue" style="display:none;">💼 ทำพาร์ทไทม์</button>
            </div>
            <button id="btnCloseDlg" class="sd-btn">ปิด [Esc]</button>
          </div>
          <div id="dlgCutsceneBar" style="display:none;justify-content:space-between;align-items:center;gap:8px;padding-top:4px;border-top:1px dashed #c49257;">
            <span id="dlgCutsceneStep" class="badge" style="background:#fef08a;color:#713f12;">📖 ฉากที่ 1/4</span>
            <div style="display:flex;gap:6px;">
              <button id="btnCutsceneNext" class="sd-btn active">▸ ต่อไป [Space]</button>
              <button id="btnCutsceneClose" class="sd-btn" style="display:none;">✨ จบบทนี้</button>
            </div>
          </div>
        </div>
        <div class="portrait-col">
          <div id="dlgPortraitBox" class="portrait-box">
            <canvas id="dlgPortrait" width="136" height="136" style="width:136px;height:136px;"></canvas>
          </div>
          <div id="dlgEmotionBadge">😊 ปกติ</div>
        </div>
      </div>
    </div>

    <!-- 6-Discipline Interactive Mini-Game Suite Overlay -->
    <div id="miniGameOverlay">
      <div id="miniGameCard" class="sd-wood">
        <div class="sd-parchment" style="padding:14px 18px;">
          <div id="mgTitle" style="font-size:17px;font-weight:800;color:#4c230a;">💼 มินิเกมแยกสาย</div>
          <div id="mgSubtitle" style="font-size:12px;color:#5c3312;margin-top:2px;">-</div>
          <div id="mgRoundBadge" class="badge" style="margin-top:6px;font-size:11.5px;">คะแนน: 0</div>
          <canvas id="mgCanvas" width="460" height="220"></canvas>
          <div id="mgCustomButtons" style="display:flex;gap:6px;justify-content:center;flex-wrap:wrap;margin-bottom:8px;"></div>
          <div id="mgFeedback" style="font-size:14px;font-weight:800;min-height:22px;color:#15803d;margin-bottom:6px;">เตรียมพร้อม!</div>
          <div style="display:flex;gap:8px;justify-content:center;">
            <button id="btnMgPrimary" class="sd-btn active" style="font-size:14px;padding:8px 24px;">⚡ กดจังหวะ! [Space]</button>
            <button id="btnMgCancel" class="sd-btn">ยกเลิก [Esc]</button>
          </div>
        </div>
      </div>
    </div>

    <!-- Universal Modal -->
    <div id="modalBackdrop">
      <div id="modalBox" class="sd-wood">
        <div id="modalInner" class="sd-parchment">
          <div id="modalHeader">
            <span id="modalTitle">เมนู</span>
            <button id="btnCloseModal" class="sd-btn">✕ ปิด</button>
          </div>
          <div id="modalBody"></div>
        </div>
      </div>
    </div>

    <!-- Stardew Valley-Style Illustrated Full-Screen World Map ([M]) -->
    <div id="worldMapOverlay">
      <div id="worldMapCard" class="sd-wood">
        <div class="sd-parchment" style="padding:10px 14px;">
          <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;flex-wrap:wrap;gap:8px;">
            <div style="display:flex;align-items:center;gap:8px;">
              <span style="font-size:17px;font-weight:800;color:#4c230a;">🗺️ แผนที่หุบเขาต้นไม้โลก (Aethelgard Valley)</span>
              <span id="wmSeasonBadge" class="badge">ฤดูใบไม้ผลิ</span>
            </div>
            <div style="display:flex;align-items:center;gap:8px;font-size:11.5px;font-weight:800;">
              <label style="cursor:pointer;"><input type="checkbox" id="wmToggleNpcs" checked /> ชาวเมือง</label>
              <label style="cursor:pointer;"><input type="checkbox" id="wmToggleForage" checked /> จุดของป่า ✨</label>
              <button id="btnCloseWorldMap" class="sd-btn">✕ ปิด [M / Esc]</button>
            </div>
          </div>
          <canvas id="worldMapCanvas" width="840" height="540"></canvas>
          <div class="wm-info-bar">
            <span id="wmHoverText">🖱️ เลื่อนเมาส์ชี้ดูชื่อสถานที่/ชาวเมือง • คลิกอาคาร แลนด์มาร์ก หรือโบราณสถานรากไม้โลกเพื่อวาร์ป • คลิกชาวเมืองเพื่อนำทาง</span>
            <span style="font-size:11px;color:#7c2d12;">🔴 คุณ • 🟡 ชาวเมือง • 🔦 โบราณสถาน • ✨ ของป่า</span>
          </div>
        </div>
      </div>
    </div>
  </div>
"""

JS_PART_1 = r"""
    const SPRITES = { walk: {}, idle: {}, interact: {}, portrait: {}, world: { buildings: {}, landmarks: {} } };
    const HERO_SHEETS = { walk: null, idle: null, interact: null };
    let assetsReady = false;

    function preloadAssets(cb) {
      const queue = [];
      for (const [k, v] of Object.entries(WALK_B64)) queue.push(["walk", k, v]);
      for (const [k, v] of Object.entries(IDLE_B64)) queue.push(["idle", k, v]);
      for (const [k, v] of Object.entries(INT_B64))  queue.push(["interact", k, v]);
      for (const [k, v] of Object.entries(PORT_B64)) queue.push(["portrait", k, v]);
      for (const [k, v] of Object.entries(WORLD_B64.buildings || {})) queue.push(["w_bldg", k, v]);
      for (const [k, v] of Object.entries(WORLD_B64.landmarks || {})) queue.push(["w_lm", k, v]);
      ["tileset_seasons", "props_and_trees", "world_tree_states"].forEach(k => {
        if (WORLD_B64[k]) queue.push(["w_root", k, WORLD_B64[k]]);
      });
      if (!queue.length) { assetsReady = true; cb(); return; }
      let done = 0;
      queue.forEach(([type, id, b64]) => {
        const img = new Image();
        const finish = () => {
          if (type === "w_bldg") SPRITES.world.buildings[id] = img;
          else if (type === "w_lm") SPRITES.world.landmarks[id] = img;
          else if (type === "w_root") SPRITES.world[id] = img;
          else SPRITES[type][id] = img;
          if (++done === queue.length) {
            assetsReady = true;
            rebuildHeroCustomSheets();
            renderTitleSlotCards();
            cb();
          }
        };
        img.onload = finish;
        img.onerror = finish;
        img.src = "data:image/png;base64," + b64;
      });
    }

    // =========================================================================
    // 2. OUTDOOR VALLEY (84 x 64) + 2ND FLOOR LOFT + 3-FLOOR ANCIENT RUINS!
    // =========================================================================
    const TILE = 32;
    const MAP_W = 84, MAP_H = 64;
    const mapGrid = Array.from({ length: MAP_H }, () => new Uint8Array(MAP_W));
    const solidGrid = Array.from({ length: MAP_H }, () => new Uint8Array(MAP_W));

    function fillRect(grid, x0, y0, w, h, val) {
      for (let y = Math.max(0, y0); y < Math.min(MAP_H, y0 + h); y++)
        for (let x = Math.max(0, x0); x < Math.min(MAP_W, x0 + w); x++)
          grid[y][x] = val;
    }

    fillRect(mapGrid, 0, 0, MAP_W, MAP_H, 0);
    fillRect(mapGrid, 0, 0, MAP_W, 5, 8);
    fillRect(mapGrid, 0, 0, 5, MAP_H, 8);
    fillRect(mapGrid, MAP_W - 5, 0, 5, MAP_H, 8);
    fillRect(mapGrid, 0, MAP_H - 4, MAP_W, 4, 8);
    fillRect(solidGrid, 0, 0, MAP_W, 3, 1);
    fillRect(solidGrid, 0, 0, 3, MAP_H, 1);
    fillRect(solidGrid, MAP_W - 3, 0, 3, MAP_H, 1);
    fillRect(solidGrid, 0, MAP_H - 3, MAP_W, 3, 1);

    fillRect(mapGrid, 32, 22, 20, 16, 1);
    fillRect(mapGrid, 10, 29, 64, 3, 2);
    fillRect(mapGrid, 40, 10, 4, 46, 1);
    fillRect(mapGrid, 16, 14, 3, 18, 2);
    fillRect(mapGrid, 56, 15, 3, 17, 2);
    fillRect(mapGrid, 68, 16, 3, 26, 2);
    fillRect(mapGrid, 18, 31, 3, 20, 2);

    for (let x = 3; x < MAP_W - 3; x++) {
      const ry = Math.floor(47 + Math.sin(x * 0.14) * 2.2);
      for (let dy = 0; dy < 4; dy++) {
        mapGrid[ry + dy][x] = 3;
        solidGrid[ry + dy][x] = 1;
      }
    }
    for (let y = 48; y <= 59; y++) {
      for (let x = 28; x <= 56; x++) {
        const dx = (x - 42) / 14, dy = (y - 54) / 6;
        if (dx*dx + dy*dy <= 1.0) { mapGrid[y][x] = 3; solidGrid[y][x] = 1; }
      }
    }
    [[18, 45, 3, 7], [40, 44, 4, 6], [68, 44, 3, 7]].forEach(([bx, by, bw, bh]) => {
      fillRect(mapGrid, bx, by, bw, bh, 4);
      fillRect(solidGrid, bx, by, bw, bh, 0);
    });
    fillRect(mapGrid, 40, 49, 4, 4, 4);
    fillRect(solidGrid, 40, 49, 4, 4, 0);

    for (let y = 20; y <= 25; y++) {
      for (let x = 10; x <= 14; x++) mapGrid[y][x] = ((x + y) % 3 === 0) ? 7 : 0;
      for (let x = 20; x <= 24; x++) mapGrid[y][x] = ((x + y) % 2 === 0) ? 7 : 0;
    }
    const seededRand = (s) => { let x = Math.sin(s) * 10000; return x - Math.floor(x); };
    for (let i = 0; i < 160; i++) {
      const fx = 6 + Math.floor(seededRand(i * 17.3) * (MAP_W - 12));
      const fy = 6 + Math.floor(seededRand(i * 31.7) * (MAP_H - 12));
      if (mapGrid[fy][fx] === 0) mapGrid[fy][fx] = 7;
    }

    const BUILDINGS = [
      { id: "farmhouse", name: "🏡 บ้านตัวเอก (Golden-Root Cottage)", x: 13, y: 10, w: 7, h: 5, doorX: 16, doorY: 15, roofColor: "#b45309", wallColor: "#f3e3c3", trimColor: "#78350f", sign: "🏡 บ้านของเรา", interiorId: "farmhouse" },
      { id: "shop",      name: "🪙 ร้านชำ Goldleaf ของพิป",             x: 31, y: 13, w: 7, h: 5, doorX: 34, doorY: 18, roofColor: "#15803d", wallColor: "#f7ead0", trimColor: "#14532d", sign: "🪙 Goldleaf",  interiorId: "shop" },
      { id: "bakery",    name: "🥐 ร้านขนมปัง Elderbark Bakery ของเซร่า",x: 52, y: 12, w: 7, h: 5, doorX: 55, doorY: 17, roofColor: "#c2410c", wallColor: "#fef3c7", trimColor: "#7c2d12", sign: "🥐 Bakery",    interiorId: "bakery" },
      { id: "tavern",    name: "🍺 โรงเตี๊ยมตะเกียงมอส ของปู่บราม",      x: 52, y: 21, w: 9, h: 5, doorX: 56, doorY: 26, roofColor: "#7f1d1d", wallColor: "#e7d3b0", trimColor: "#450a0a", sign: "🍺 Moss Tavern",interiorId: "tavern" },
      { id: "smithy",    name: "⚒️ โรงตีเหล็กศิลาเพลิง ของทอร์น",        x: 66, y: 16, w: 8, h: 5, doorX: 69, doorY: 21, roofColor: "#334155", wallColor: "#cbd5e1", trimColor: "#0f172a", sign: "⚒️ Smithy",    interiorId: "smithy" },
      { id: "cottage",   name: "🌿 กระท่อมสมุนไพร ของลิเลียน",           x: 14, y: 35, w: 7, h: 5, doorX: 17, doorY: 40, roofColor: "#047857", wallColor: "#ecfdf5", trimColor: "#064e3b", sign: "🌿 Herbs",     interiorId: "cottage" }
    ];
    BUILDINGS.forEach(b => {
      fillRect(solidGrid, b.x, b.y + 1, b.w, b.h - 1, 1);
      mapGrid[b.doorY][b.doorX] = 2;
      solidGrid[b.doorY][b.doorX] = 0;
    });
    fillRect(solidGrid, 40, 26, 4, 3, 1);

    // Entrance to Under-Root Ancient Ruins (West side of World Tree Roots!)
    const RUINS_ENTRANCE = { tx: 39, ty: 27 };
    solidGrid[27][39] = 0;
    mapGrid[27][39] = 1;

    const TREES = [];
    const LANTERNS = [
      { x: 16, y: 28 }, { x: 31, y: 22 }, { x: 52, y: 22 }, { x: 31, y: 37 }, { x: 52, y: 37 },
      { x: 39, y: 19 }, { x: 44, y: 19 }, { x: 39, y: 44 }, { x: 44, y: 44 },
      { x: 56, y: 28 }, { x: 67, y: 28 }, { x: 17, y: 42 }
    ];
    for (let i = 0; i < 85; i++) {
      const tx = 5 + Math.floor(seededRand(i * 43.1 + 9) * (MAP_W - 10));
      const ty = 5 + Math.floor(seededRand(i * 19.7 + 3) * (MAP_H - 10));
      if ((mapGrid[ty][tx] === 0 || mapGrid[ty][tx] === 8) && solidGrid[ty][tx] === 0 && Math.abs(tx - 42) + Math.abs(ty - 29) > 9) {
        const nearDoor = BUILDINGS.some(b => Math.abs(tx - b.doorX) < 3 && Math.abs(ty - b.doorY) < 3);
        if (!nearDoor) { TREES.push({ x: tx, y: ty, kind: i % 3 }); solidGrid[ty][tx] = 1; }
      }
    }

    // =========================================================================
    // 3. INDOORS (6 ROOMS + 2ND FLOOR STARLIGHT LOFT!)
    // =========================================================================
    const INDOORS = {
      farmhouse: {
        name: "🏡 บ้านพักชั้น 1 (Golden-Root Cottage)", w: 16, h: 12, floor: "#c89b63", wall: "#7c4a21", rug: "#b91c1c",
        exitX: 8, exitY: 10, spawnX: 8, spawnY: 9,
        stairsUp: { x: 13, y: 2 },
        furniture: [
          { type: "bed", x: 2, y: 3, w: 2, h: 3, label: "🛏️ เตียงนอน (กด E เพื่อนอนพักข้ามวัน)" },
          { type: "fireplace", x: 7, y: 1, w: 2, h: 2, label: "🔥 เตาผิง & โต๊ะทำอาหาร" },
          { type: "table", x: 5, y: 8, w: 2, h: 2, label: "🍳 โต๊ะคราฟต์ของขวัญ & แหวนแต่งงาน" }
        ]
      },
      farmhouse_upstairs: {
        name: "🌟 บ้านพักชั้น 2 (Starlight Loft)", w: 14, h: 10, floor: "#b98b56", wall: "#312e81", rug: "#7e22ce",
        exitX: 11, exitY: 8, spawnX: 11, spawnY: 7, isLoft: true,
        furniture: [
          { type: "bed", x: 2, y: 3, w: 3, h: 3, label: "💒 เตียงคู่ชมดาวชั้น 2 (กด E เพื่อนอนพักข้ามวัน)" },
          { type: "skylight", x: 6, y: 2, w: 2, h: 1, passable: true, label: "🌌 ระเบียงกระจกชมหมู่ดาวเอเธลการ์ด" }
        ]
      },
      bakery: {
        name: "🥐 ในร้าน Elderbark Bakery", w: 16, h: 12, floor: "#deb887", wall: "#8c4a1d", rug: "#d97706",
        exitX: 8, exitY: 10, spawnX: 8, spawnY: 9,
        furniture: [
          { type: "oven", x: 2, y: 2, w: 3, h: 2, label: "🔥 เตาอบหินขนมปังหอมกรุ่น" },
          { type: "counter", x: 5, y: 5, w: 6, h: 2, label: "🥐 เคาน์เตอร์ขนมปังเนยน้ำผึ้ง" },
          { type: "table", x: 12, y: 7, w: 2, h: 2, label: "☕ โต๊ะชิมขนม" },
          { type: "plant", x: 13, y: 2, w: 1, h: 1 }
        ]
      },
      tavern: {
        name: "🍺 ในโรงเตี๊ยมตะเกียงมอส", w: 18, h: 13, floor: "#9e6f40", wall: "#572811", rug: "#7f1d1d",
        exitX: 9, exitY: 11, spawnX: 9, spawnY: 10,
        furniture: [
          { type: "counter", x: 4, y: 3, w: 10, h: 2, label: "🍺 เคาน์เตอร์บาร์เอลน้ำผึ้ง" },
          { type: "barrel", x: 2, y: 2, w: 2, h: 2, label: "🛢️ ถังเอลโอ๊กหมัก 10 ปี" },
          { type: "table", x: 3, y: 7, w: 3, h: 2, label: "🍲 โต๊ะซุปหัวหอมร้อนๆ" },
          { type: "table", x: 12, y: 7, w: 3, h: 2, label: "🎻 มุมดนตรีไวโอลิน (กด E เล่นเพลงได้!)" },
          { type: "fireplace", x: 15, y: 2, w: 2, h: 2 }
        ]
      },
      shop: {
        name: "🪙 ในร้านชำ Goldleaf", w: 16, h: 12, floor: "#d2ab74", wall: "#1e4620", rug: "#15803d",
        exitX: 8, exitY: 10, spawnX: 8, spawnY: 9,
        furniture: [
          { type: "counter", x: 5, y: 3, w: 6, h: 2, label: "🪙 เคาน์เตอร์ร้านพิป" },
          { type: "bookshelf", x: 2, y: 3, w: 2, h: 4, label: "🌱 ชั้นของฝากแปดเผ่า" },
          { type: "bookshelf", x: 12, y: 3, w: 2, h: 4, label: "🧺 ชั้นเครื่องมือและวัตถุดิบ" },
          { type: "barrel", x: 2, y: 8, w: 2, h: 1 }
        ]
      },
      smithy: {
        name: "⚒️ ในโรงตีเหล็กศิลาเพลิง", w: 16, h: 12, floor: "#64748b", wall: "#334155", rug: "#9a3412",
        exitX: 8, exitY: 10, spawnX: 8, spawnY: 9,
        furniture: [
          { type: "oven", x: 6, y: 2, w: 4, h: 2, label: "🔥 เตาหลอมศิลาเพลิง" },
          { type: "anvil", x: 7, y: 5, w: 2, h: 2, label: "⚒️ ทั่งตีเหล็กมานา" },
          { type: "bookshelf", x: 2, y: 3, w: 2, h: 3, label: "⛏️ ชั้นแร่เหล็ก" },
          { type: "barrel", x: 12, y: 4, w: 2, h: 2 }
        ]
      },
      cottage: {
        name: "🌿 ในกระท่อมสมุนไพรลิเลียน", w: 16, h: 12, floor: "#c9b38c", wall: "#166534", rug: "#059669",
        exitX: 8, exitY: 10, spawnX: 8, spawnY: 9,
        furniture: [
          { type: "table", x: 6, y: 4, w: 4, h: 2, label: "🧪 โต๊ะปรุงยาสมุนไพร" },
          { type: "bookshelf", x: 2, y: 2, w: 3, h: 2, label: "🌿 ชั้นขวดน้ำยาเรืองแสง" },
          { type: "plant", x: 12, y: 3, w: 1, h: 1 },
          { type: "plant", x: 13, y: 6, w: 1, h: 1 },
          { type: "bed", x: 12, y: 8, w: 2, h: 2 }
        ]
      }
    };

    // =========================================================================
    // 4. UNDER-ROOT ANCIENT RUINS (3 FLOORS + LIGHT-PILLAR PRISM PUZZLES!)
    // =========================================================================
    // Directions: 0=UP, 1=LEFT, 2=DOWN, 3=RIGHT
    // Pillar Mirror States: 0 = '/' (NE-SW), 1 = '\' (NW-SE), 2 = '✦' (Perpendicular Splitter)
    const RUINS_FLOORS = {
      ruins_b1: {
        id: "ruins_b1", depth: 1, w: 20, h: 14,
        name: "🔦 โบราณสถานใต้รากไม้ ชั้น B1 (โถงรากศิลา)",
        exitUp: { x: 10, y: 12, to: "outdoor" },
        stairsDown: { x: 10, y: 2, to: "ruins_b2" },
        spawnX: 10, spawnY: 11,
        chest: { x: 16, y: 3, gold: 320, items: { item_ancient_tablet: 1, item_aqua_crystal: 1 }, stat: { wisdom: 15, courage: 10 } },
        emitters: [{ x: 3, y: 5, dir: 3, color: "#fde047" }],
        blocks: [{ x: 9, y: 5 }, { x: 11, y: 7 }, { x: 5, y: 9 }],
        pillars: [
          { x: 7,  y: 5, init: 0, maxStates: 2 }, // sol: 1 (\) -> DOWN
          { x: 7,  y: 9, init: 0, maxStates: 2 }, // sol: 1 (\) -> RIGHT
          { x: 14, y: 9, init: 1, maxStates: 2 }  // sol: 0 (/) -> UP
        ],
        receptors: [{ x: 14, y: 4 }],
        ores: [
          { x: 4, y: 3, item_id: "item_ember_ore" },
          { x: 16, y: 10, item_id: "item_aqua_crystal" }
        ]
      },
      ruins_b2: {
        id: "ruins_b2", depth: 2, w: 20, h: 14,
        name: "🔦 โบราณสถานใต้รากไม้ ชั้น B2 (โถงกระจกวารี)",
        exitUp: { x: 10, y: 12, to: "ruins_b1" },
        stairsDown: { x: 10, y: 2, to: "ruins_b3" },
        spawnX: 10, spawnY: 11,
        chest: { x: 17, y: 3, gold: 480, items: { item_starfall_crystal: 1, item_sea_pearl: 1 }, stat: { wisdom: 20, courage: 15 } },
        emitters: [
          { x: 3, y: 4,  dir: 3, color: "#38bdf8" },
          { x: 3, y: 10, dir: 3, color: "#fde047" }
        ],
        blocks: [{ x: 10, y: 4 }, { x: 11, y: 10 }],
        pillars: [
          { x: 6, y: 4,  init: 0, maxStates: 2 }, // sol: 1 (\) -> DOWN
          { x: 6, y: 7,  init: 0, maxStates: 2 }, // sol: 1 (\) -> RIGHT -> (16,7)
          { x: 8, y: 10, init: 1, maxStates: 2 }, // sol: 0 (/) -> UP
          { x: 8, y: 5,  init: 1, maxStates: 2 }  // sol: 0 (/) -> RIGHT -> (16,5)
        ],
        receptors: [{ x: 16, y: 7 }, { x: 16, y: 5 }],
        ores: [
          { x: 4, y: 7, item_id: "item_pure_gold_ore" },
          { x: 15, y: 10, item_id: "item_starfall_crystal" }
        ]
      },
      ruins_b3: {
        id: "ruins_b3", depth: 3, w: 20, h: 14,
        name: "🔦 โบราณสถานใต้รากไม้ ชั้น B3 (โถงหัวใจบรรพกาล)",
        exitUp: { x: 10, y: 12, to: "ruins_b2" },
        stairsDown: null,
        spawnX: 10, spawnY: 11,
        chest: { x: 12, y: 3, gold: 800, items: { item_world_tree_ring: 1, item_crimson_mana: 1, item_ruby_elixir: 1 }, stat: { wisdom: 30, courage: 25, charm: 15 } },
        emitters: [{ x: 3, y: 7, dir: 3, color: "#f472b6" }],
        blocks: [{ x: 9, y: 7 }, { x: 12, y: 4 }],
        pillars: [
          { x: 7,  y: 7,  init: 0, maxStates: 2 }, // sol: 1 (\) -> DOWN
          { x: 7,  y: 10, init: 0, maxStates: 2 }, // sol: 1 (\) -> RIGHT
          { x: 12, y: 10, init: 1, maxStates: 2 }, // sol: 0 (/) -> UP
          { x: 12, y: 6,  init: 0, maxStates: 3 }, // sol: 2 (✦ Splitter) -> LEFT + RIGHT
          { x: 9,  y: 6,  init: 0, maxStates: 2 }, // sol: 1 (\) -> UP -> (9,3)
          { x: 15, y: 6,  init: 1, maxStates: 2 }  // sol: 0 (/) -> UP -> (15,3)
        ],
        receptors: [{ x: 9, y: 3 }, { x: 15, y: 3 }],
        ores: [
          { x: 4, y: 4, item_id: "item_crimson_mana" },
          { x: 16, y: 10, item_id: "item_pure_gold_ore" },
          { x: 17, y: 5, item_id: "item_raw_gem" }
        ]
      }
    };

    // =========================================================================
    // 5. GAME DATA, ITEMS (+ WORLD TREE RING!), 8-RACE PERKS & 12 DECOR ITEMS
    // =========================================================================
    // Add heirloom World Tree Ring into items catalog so it works everywhere!
    if (!GAME_DATA.items.items.some(x => x.id === "item_world_tree_ring")) {
      GAME_DATA.items.items.push({
        id: "item_world_tree_ring",
        name_th: "แหวนสายใยรากไม้โลก",
        category: "heirloom",
        price: 850,
        sell_price: 500,
        energy_restore: 0,
        shop_id: "shop",
        loved_by: GAME_DATA.characters.characters.filter(c => c.romanceable).map(c => c.id),
        description_th: "แหวนทองคำประดับผลึกดาวตกจากรากต้นไม้โลก ใช้มอบขอแต่งงานกับคนรักที่มี 10 หัวใจ 💒"
      });
    }

    const PET_IMAGES = {};
    const ITEM_IMAGES = {};
    Object.entries(PET_B64).forEach(([k, b64]) => {
      if (b64 && b64.length > 8) { const im = new Image(); im.src = "data:image/png;base64," + b64; PET_IMAGES[k] = im; }
    });
    Object.entries(ITEM_ICON_B64).forEach(([k, b64]) => {
      if (b64 && b64.length > 8) { const im = new Image(); im.src = "data:image/png;base64," + b64; ITEM_IMAGES[k] = im; }
    });
    function itemIconHtml(iid, sz = 22) {
      if (iid === "item_world_tree_ring") return `<span style="font-size:${sz-4}px;margin-right:4px;">💍</span>`;
      const b64 = ITEM_ICON_B64[iid];
      return b64 && b64.length > 8
        ? `<img src="data:image/png;base64,${b64}" width="${sz}" height="${sz}" style="vertical-align:middle;image-rendering:pixelated;margin-right:4px;" alt="" />`
        : "✨ ";
    }

    const CHAR_BY_ID = Object.fromEntries(GAME_DATA.characters.characters.map(c => [c.id, c]));
    const ITEM_BY_ID = Object.fromEntries(GAME_DATA.items.items.map(it => [it.id, it]));
    const JOB_BY_EMPLOYER = {};
    GAME_DATA.jobs.jobs.forEach(j => { JOB_BY_EMPLOYER[j.employer_id] = j; });
    const LANDMARKS = GAME_DATA.landmarks.landmarks;
    const LANDMARK_BY_ID = Object.fromEntries(LANDMARKS.map(l => [l.id, l]));
    const MUSEUM_ITEMS = GAME_DATA.landmarks.museum_collection;
    const MUSEUM_MILESTONES = GAME_DATA.landmarks.museum_milestones;
    const NIGHT_MARKET_STOCK = [...GAME_DATA.landmarks.night_market_stock, "item_world_tree_ring"];
    const CHRONICLES = GAME_DATA.story_chronicles.chapters;
    const CHRONICLE_BY_ID = Object.fromEntries(CHRONICLES.map(ch => [ch.id, ch]));

    LANDMARKS.forEach(lm => {
      for (let i = TREES.length - 1; i >= 0; i--) {
        const t = TREES[i];
        if (t.x >= lm.tx - 1 && t.x <= lm.tx + lm.w && t.y >= lm.ty - 1 && t.y <= lm.ty + lm.h + 1) {
          solidGrid[t.y][t.x] = 0; TREES.splice(i, 1);
        }
      }
      fillRect(mapGrid, lm.tx, lm.ty, lm.w, lm.h, lm.id === "lm_hotspring" ? 0 : 1);
      fillRect(solidGrid, lm.tx, lm.ty + 1, lm.w, Math.max(1, lm.h - 2), 1);
      fillRect(mapGrid, Math.floor(lm.interactX) - 1, lm.ty + lm.h, 3, 1, 2);
      fillRect(solidGrid, lm.tx, lm.ty + lm.h, lm.w, 1, 0);
    });

    // 8 Playable Protagonist Races & Passive Perks!
    const RACE_PERKS = {
      human:    { key: "human",    icon: "🧑", name_th: "มนุษย์ (Human)",           perk_th: "XP สเตตัสทั้ง 4 แกน +10% ทุกกิจกรรม" },
      elf:      { key: "elf",      icon: "🌿", name_th: "เอลฟ์ (Elf)",              perk_th: "เก็บของป่ามีโอกาส 35% ได้ x2 ชิ้น!" },
      avian:    { key: "avian",    icon: "🪽", name_th: "เผ่าวิหก (Avian)",         perk_th: "เดิน/วิ่งไวขึ้น +12% & โบนัสค่าจ้างส่งของ/ลาดตระเวน +15%" },
      beastkin: { key: "beastkin", icon: "🐾", name_th: "เผ่าครึ่งสัตว์ (Beastkin)",perk_th: "ทำอาหาร/คราฟต์ของ ฟื้นพลังงานกลับคืน +8⚡ ทันที!" },
      vampire:  { key: "vampire",  icon: "🌙", name_th: "แวมไพร์ (Vampire)",        perk_th: "ยามค่ำ (หลัง 18:00 น.) ใช้พลังงานลดลง 25%!" },
      goblin:   { key: "goblin",   icon: "⚙️", name_th: "ก็อบลินเหลือง (Goblin)",   perk_th: "ซื้อสินค้าลดราคา 8% & ขายของได้กำไร +10%!" },
      merfolk:  { key: "merfolk",  icon: "🧜", name_th: "เผ่าเงือก (Merfolk)",       perk_th: "แถบจับปลา Stardew กว้างขึ้น +28% & โอกาสได้ไข่มุกสูงขึ้น!" },
      dwarf:    { key: "dwarf",    icon: "⚒️", name_th: "คนแคระ (Dwarf)",           perk_th: "พลังงานสูงสุด +15⚡ ถาวร & ขุดแร่โบราณสถานได้ x2 ก้อน!" }
    };
    // Normalize avian key if characters.json uses winged or avian
    function getCharRaceKey(cid) {
      const c = CHAR_BY_ID[cid];
      if (!c) return "human";
      if (c.race_key === "winged" || c.race_key === "avian") return "avian";
      return RACE_PERKS[c.race_key] ? c.race_key : "human";
    }

    const SEASONS = [
      { id: "spring", name_th: "ใบไม้ผลิ", grassA: "#65a34e", grassB: "#5a9644", dark: "#477c35", light: "#82be64", petal: "#fef08a" },
      { id: "summer", name_th: "ฤดูร้อน",   grassA: "#51973c", grassB: "#478a34", dark: "#377026", light: "#74b857", petal: "#86efac" },
      { id: "autumn", name_th: "ใบไม้ร่วง", grassA: "#c28b39", grassB: "#b37c2f", dark: "#8e5f1e", light: "#dea950", petal: "#fb923c" },
      { id: "winter", name_th: "ฤดูหนาว",   grassA: "#cbd5e1", grassB: "#bdcad8", dark: "#94a3b8", light: "#f1f5f9", petal: "#ffffff" }
    ];
    const WEEKDAYS = ["จ.", "อ.", "พ.", "พฤ.", "ศ.", "ส.", "อา."];
    const FESTIVALS = {
      7:  { name_th: "🏮 เทศกาลโคมไฟต้นไม้โลก", desc_th: "ชาวเมืองทั้ง 8 เผ่าร่วมปล่อยโคมลอยขอพรใต้ต้นไม้โลก", gold: 200, hearts: 40, stats: { charm: 10, wisdom: 8 } },
      14: { name_th: "🎻 คืนดนตรีโรงเตี๊ยมตะเกียงมอส", desc_th: "เซเลสและมิเรลล์ร่วมบรรเลงดนตรีพร้อมงานเลี้ยงปู่บราม", gold: 220, hearts: 45, stats: { charm: 12, courage: 6 } },
      21: { name_th: "🎪 ตลาดนัดหัตถศิลป์แปดเผ่า", desc_th: "ลดราคาสินค้า 20% ทั้งเมือง พร้อมโชว์สิ่งประดิษฐ์แปดเผ่า", gold: 280, hearts: 40, stats: { craft: 12, charm: 6 } },
      28: { name_th: "🌠 คืนฝนดาวตกเอเธลการ์ด", desc_th: "ชมฝนดาวตกเหนือทะเลสาบมุกศักดิ์สิทธิ์กับอีไลและชาวเมือง", gold: 320, hearts: 55, stats: { wisdom: 12, courage: 10 } }
    };
    const BDAY_DAYS = [2, 3, 5, 6, 8, 10, 11, 13, 15, 16, 18, 19, 22, 24, 25, 27];
    const NPC_BIRTHDAYS = {};
    GAME_DATA.characters.characters.forEach((c, i) => { NPC_BIRTHDAYS[c.id] = BDAY_DAYS[i % BDAY_DAYS.length]; });

    const STORY_SEALS = [
      { race_key: "human",     icon: "🧭", name_th: "ตราแห่งมนุษย์",       members: ["01_ren", "02_marcus"],  lore_th: "สายใยแห่งนักสำรวจและผู้บันทึกประวัติศาสตร์หุบเขา" },
      { race_key: "elf",       icon: "🌿", name_th: "ตราแห่งเอลฟ์",        members: ["03_lilian", "04_eli"],  lore_th: "ปัญญาแห่งรากสมุนไพรและดวงดาวเหนือกิ่งต้นไม้โลก" },
      { race_key: "winged",    icon: "🪽", name_th: "ตราแห่งเผ่ามีปีก",     members: ["05_kyo", "06_sora"],    lore_th: "สายลมผู้เชื่อมข่าวสารและอิสระแห่งท้องฟ้า" },
      { race_key: "beastkin",  icon: "🐾", name_th: "ตราแห่งเผ่าสัตว์",     members: ["07_sera", "08_roland"], lore_th: "ความอบอุ่นของเตาอบและพลังผู้พิทักษ์ผืนป่า" },
      { race_key: "vampire",   icon: "🌙", name_th: "ตราแห่งรัตติกาล",      members: ["09_celeste", "10_lucian"], lore_th: "บทเพลงไวโอลินและศาสตร์ปรุงยาใต้แสงจันทร์" },
      { race_key: "goblin",    icon: "⚙️", name_th: "ตราแห่งกอบลิน",       members: ["11_pip", "12_trixie"],  lore_th: "การค้าอันคึกคักและสิ่งประดิษฐ์ฟันเฟืองมานา" },
      { race_key: "merfolk",   icon: "🐚", name_th: "ตราแห่งเผ่าเงือก",     members: ["13_mirelle", "14_kael"],lore_th: "บทเพลงวารีและความทรงจำใต้ทะเลสาบมุกศักดิ์สิทธิ์" },
      { race_key: "dwarf",     icon: "⚒️", name_th: "ตราแห่งดวอร์ฟ",       members: ["15_thorn", "16_bram"],  lore_th: "เปลวไฟเตาหลอมศิลาเพลิงและมิตรภาพในโรงเตี๊ยม" }
    ];

    const CRAFT_RECIPES = [
      { id: "rec_ring",      out_id: "item_world_tree_ring", name_th: "💍 ตีแหวนสายใยรากไม้โลก (ขอแต่งงาน!)", ingredients: { item_pure_gold_ore: 1, item_starfall_crystal: 1 }, stat: { craft: 20, charm: 15 } },
      { id: "rec_croissant", out_id: "item_honey_croissant", name_th: "🥐 อบครัวซองต์เนยน้ำผึ้ง", ingredients: { item_wild_honey: 1, item_rich_milk: 1 }, stat: { craft: 8 } },
      { id: "rec_pie",       out_id: "item_apple_pie",       name_th: "🥧 อบพายผลไม้สุริยัน",      ingredients: { item_sunfruit: 1, item_wild_honey: 1 }, stat: { craft: 10 } },
      { id: "rec_stew",      out_id: "item_hearty_stew",     name_th: "🍲 เคี่ยวสตูว์แซลมอนหม้อไฟ", ingredients: { item_grilled_salmon: 1, item_wild_honey: 1 }, stat: { craft: 10, charm: 4 } },
      { id: "rec_elixir",    out_id: "item_ruby_elixir",     name_th: "🧪 ปรุงน้ำอมฤตทับทิม",      ingredients: { item_rootdew_flower: 1, item_moonbloom: 1 }, stat: { wisdom: 12 } },
      { id: "rec_rose",      out_id: "item_velvet_rose",     name_th: "🌹 จัดช่อกุหลาบแดงกำมะหยี่", ingredients: { item_rootdew_flower: 1, item_water_lily: 1 }, stat: { charm: 10 } },
      { id: "rec_compass",   out_id: "item_brass_compass",   name_th: "🧭 ประดิษฐ์เข็มทิศทองเหลือง",ingredients: { item_brass_gear: 1, item_ember_ore: 1 }, stat: { craft: 12, wisdom: 5 } },
      { id: "rec_pearl",     out_id: "item_sea_pearl",       name_th: "🦪 ขัดเงาไข่มุกสมุทร",       ingredients: { item_glowing_shell: 1, item_aqua_crystal: 1 }, stat: { craft: 10, charm: 6 } },
      { id: "rec_battery",   out_id: "item_mana_battery",    name_th: "🔋 ประกอบแบตเตอรี่มานา",    ingredients: { item_brass_gear: 1, item_starfall_crystal: 1 }, stat: { wisdom: 12, craft: 8 } },
      { id: "rec_ale",       out_id: "item_honey_ale",       name_th: "🍺 หมักเอลน้ำผึ้งป่า",        ingredients: { item_wild_honey: 2 }, stat: { craft: 7, charm: 5 } },
      { id: "rec_barrel",    out_id: "item_oak_barrel",      name_th: "🪵 ต่อถังไม้โอ๊กช่างฝีมือ",   ingredients: { item_hard_oak: 2 }, stat: { craft: 12 } }
    ];

    const PET_TYPES = {
      cat:   { name_th: "โมจิ (แมวส้ม)",   icon: "🐱", body: "#f59e0b", accent: "#fef3c7", ear: "#b45309", cry: "เมี้ยว~ 🐱💕" },
      dog:   { name_th: "โคริ (ชิบะป่า)", icon: "🐶", body: "#d97706", accent: "#fffbeb", ear: "#78350f", cry: "โฮ่งๆ! 🐶💕" },
      fairy: { name_th: "ลูมิ (ภูตแสง)",  icon: "🧚", body: "#38bdf8", accent: "#fef08a", ear: "#e0f2fe", cry: "วิ้งค์~ ✨💕" }
    };

    const MAIL_TEMPLATES = [
      { day: 1, id: "mail_d1", sender: "คุณปู่บราม (โรงเตี๊ยมตะเกียงมอส)", title: "ยินดีต้อนรับสู่ {farm}!", body: "ฮ่าๆๆ ยินดีต้อนรับสู่บ้านพักหลังใหม่นะ {player}! ลองกด [H] ในบ้านเพื่อวางเฟอร์นิเจอร์บนตาราง หรือสำรวจประตูโบราณสถานใต้รากไม้โลกดูสิ!", gift_id: "item_honey_bread", gold: 80 },
      { day: 2, id: "mail_d2", sender: "โรแลนด์ & ทอร์น", title: "บริการต่อเติมบ้านชั้น 2 (Starlight Loft)!", body: "สวัสดี {player}! ถ้าอยากมีห้องใต้หลังคาชมดาวชั้น 2 และเตรียมเรือนหอแต่งงาน แวะเปิดเมนูร้าน/บ้าน [3] ได้เลยนะ!", gift_id: "item_hard_oak", gold: 0 },
      { day: 3, id: "mail_d3", sender: "คาเอล & อีไล", title: "ประตูศิลาโบราณใต้รากไม้โลกเปิดออกแล้ว!", body: "{player}! ทางทิศตะวันตกของรากต้นไม้โลกมีบันไดลงสู่โบราณสถาน 3 ชั้น ลองไปไขปริศนาเสาแสงสะท้อนปริซึมดูนะ มีสมบัติเพียบเลย!", gift_id: "item_emerald_tea", gold: 0 },
      { day: 5, id: "mail_d5", sender: "มิเรลล์ (ทะเลสาบมุกศักดิ์สิทธิ์)", title: "ชวนมาตกปลาสไตล์ Stardew ริมทะเลสาบ", body: "น้ำในทะเลสาบทางใต้ใสมากเลยจ้ะ {player} ลองมาเลี้ยงแถบเขียวตกปลาหาไข่มุกไปบริจาคพิพิธภัณฑ์ดูนะ!", gift_id: "item_glowing_shell", gold: 0 },
      { day: 7, id: "mail_d7", sender: "คณะกรรมการเทศกาลเอเธลการ์ด", title: "🏮 วันนี้เทศกาลโคมไฟต้นไม้โลก!", body: "อย่าลืมกดปุ่มเข้าร่วมเทศกาลมุมขวาบนเพื่อรับรางวัลและเพิ่มความสนิทกับชาวเมืองทุกคนนะ!", gift_id: "item_honey_croissant", gold: 100 }
    ];

    // 12 Grid-Placeable Interactive Furniture Items!
    const HOME_DECOR = [
      { id: "decor_bookshelf", icon: "📚", name_th: "ชั้นหนังสือโบราณ",     price: 220, perk_th: "+5 📖 ปัญญาทุกเช้า",        stat: "wisdom",  w: 2, h: 1, color: "#78350f", defaultPos: { scene: "farmhouse", x: 10, y: 2 } },
      { id: "decor_tea_set",   icon: "🍵", name_th: "โต๊ะน้ำชามรกต",         price: 200, perk_th: "+5 ✨ เสน่ห์ทุกเช้า",        stat: "charm",   w: 2, h: 2, color: "#15803d", defaultPos: { scene: "farmhouse", x: 11, y: 5 } },
      { id: "decor_workbench", icon: "🔨", name_th: "โต๊ะงานฝีมือไม้โอ๊ก",    price: 250, perk_th: "+5 🔨 ฝีมือทุกเช้า",         stat: "craft",   w: 2, h: 1, color: "#b45309", defaultPos: { scene: "farmhouse", x: 2,  y: 7 } },
      { id: "decor_lantern",   icon: "🏮", name_th: "โคมไฟคริสตัลแขวน",      price: 190, perk_th: "+5 🛡️ ความกล้าทุกเช้า",       stat: "courage", w: 1, h: 1, color: "#eab308", defaultPos: { scene: "farmhouse", x: 5,  y: 2 } },
      { id: "decor_plush_bed", icon: "🛏️", name_th: "เตียงขนนกพรีเมียม",     price: 380, perk_th: "พลังงานสูงสุด +20 ⚡ ถาวร!",  stat: null,      w: 2, h: 2, color: "#db2777", defaultPos: { scene: "farmhouse", x: 12, y: 8 } },
      { id: "decor_mirror",    icon: "🪞", name_th: "กระจกแต่งตัวเวทมนตร์",  price: 180, perk_th: "กด [E] แต่งตัวเอก 8 เผ่าในบ้าน!", stat: "charm", w: 1, h: 2, color: "#8b5cf6", action: "mirror", defaultPos: { scene: "farmhouse", x: 4, y: 2 } },
      { id: "decor_aquarium",  icon: "🐠", name_th: "ตู้ปลาเรืองแสงทะเลสาบมุก",price: 300, perk_th: "กด [E] ชมปลาฟื้น +12⚡/วัน",   stat: "wisdom",  w: 2, h: 1, color: "#0284c7", action: "aquarium", defaultPos: { scene: "farmhouse", x: 9, y: 8 } },
      { id: "decor_rug_royal", icon: "🧶", name_th: "พรมทอตราแปดเผ่า",       price: 160, perk_th: "ปูพื้นเดินทับได้ • +5 ✨ เสน่ห์",stat: "charm",  w: 3, h: 2, color: "#9f1239", passable: true, defaultPos: { scene: "farmhouse", x: 7, y: 5 } },
      { id: "decor_bonsai",    icon: "🌳", name_th: "บอนไซต้นไม้โลกเรืองแสง", price: 260, perk_th: "+5 📖 ปัญญาทุกเช้า",         stat: "wisdom",  w: 1, h: 1, color: "#16a34a", defaultPos: { scene: "farmhouse_upstairs", x: 3, y: 7 } },
      { id: "decor_cello",     icon: "🎻", name_th: "ไวโอลินไม้แดงตั้งพื้น",  price: 320, perk_th: "กด [E] บรรเลงมินิเกมดนตรี 4 เลน!",stat: "charm", w: 1, h: 1, color: "#991b1b", action: "music", defaultPos: { scene: "farmhouse_upstairs", x: 9, y: 3 } },
      { id: "decor_sofa",      icon: "🛋️", name_th: "โซฟากำมะหยี่คู่รัก",     price: 340, perk_th: "พลังงานสูงสุด +10 ⚡ ถาวร!",  stat: null,      w: 3, h: 1, color: "#7e22ce", defaultPos: { scene: "farmhouse_upstairs", x: 6, y: 5 } },
      { id: "decor_telescope", icon: "🔭", name_th: "กล้องดูดาวริมระเบียง",   price: 290, perk_th: "กด [E] ส่องดาวรับ +8💡/วัน",   stat: "wisdom",  w: 1, h: 2, color: "#1d4ed8", action: "stargaze", defaultPos: { scene: "farmhouse_upstairs", x: 8, y: 2 } }
    ];
    const DECOR_BY_ID = Object.fromEntries(HOME_DECOR.map(d => [d.id, d]));

    const FISH_POOL = [
      { item_id: "item_grilled_salmon", weight: 28, label: "🐟 ปลาแซลมอนแม่น้ำ", speed: 1.0 },
      { item_id: "item_glowing_shell",  weight: 22, label: "🐚 เปลือกหอยเรืองแสง", speed: 1.1 },
      { item_id: "item_water_lily",     weight: 18, label: "🪷 ดอกบัววารี", speed: 0.9 },
      { item_id: "item_sea_pearl",      weight: 14, label: "🦪 ไข่มุกสมุทรหายาก!", speed: 1.35 },
      { item_id: "item_aqua_crystal",   weight: 10, label: "💎 ผลึกวารีใส", speed: 1.45 },
      { item_id: "item_ancient_tablet", weight: 8,  label: "🪨 แผ่นจารึกโบราณใต้น้ำ!", speed: 1.55 }
    ];

    const FORAGE_CANDIDATES = [
      { tx: 18, ty: 24, item_id: "item_wild_honey" }, { tx: 22, ty: 39, item_id: "item_rootdew_flower" },
      { tx: 29, ty: 44, item_id: "item_moonbloom" },  { tx: 35, ty: 20, item_id: "item_sunfruit" },
      { tx: 49, ty: 35, item_id: "item_wild_honey" }, { tx: 61, ty: 29, item_id: "item_hard_oak" },
      { tx: 72, ty: 24, item_id: "item_ember_ore" },  { tx: 67, ty: 38, item_id: "item_starfall_crystal" },
      { tx: 37, ty: 52, item_id: "item_glowing_shell" }, { tx: 47, ty: 48, item_id: "item_water_lily" },
      { tx: 25, ty: 18, item_id: "item_emerald_tea" }, { tx: 58, ty: 39, item_id: "item_brass_gear" }
    ];

    const BULLETIN_BOARD = { tx: 45, ty: 29 };
    const MAILBOX_POS = { tx: 20, ty: 15 };
    const WORLD_TREE_SHRINE = { tx: 42, ty: 28 };
    const SCENE_NAMES_TH = {
      outdoor: "หุบเขาต้นไม้โลก",
      farmhouse: "บ้านพักตัวเอก (ชั้น 1)",
      farmhouse_upstairs: "ห้องใต้หลังคาชมดาว (ชั้น 2)",
      shop: "ร้านชำ Goldleaf",
      bakery: "ร้านขนมปัง Elderbark",
      tavern: "โรงเตี๊ยมตะเกียงมอส",
      smithy: "โรงตีเหล็กศิลาเพลิง",
      cottage: "กระท่อมสมุนไพรลิเลียน",
      ruins_b1: "โบราณสถานรากไม้ B1",
      ruins_b2: "โบราณสถานรากไม้ B2",
      ruins_b3: "โบราณสถานรากไม้ B3"
    };

    const NPCS = [
      { id: "02_marcus",  scene: "outdoor", x: 37, y: 25, patrol: [[37,25],[37,33],[46,33],[46,25]] },
      { id: "04_eli",     scene: "outdoor", x: 25, y: 36, patrol: [[25,36],[29,36]] },
      { id: "05_kyo",     scene: "outdoor", x: 45, y: 28, patrol: [[45,28],[51,28],[51,34],[45,34]] },
      { id: "06_sora",    scene: "outdoor", x: 70, y: 29, patrol: [[65,29],[75,29]] },
      { id: "08_roland",  scene: "outdoor", x: 22, y: 31, patrol: [[22,31],[27,31]] },
      { id: "10_lucian",  scene: "outdoor", x: 27, y: 42, patrol: [[27,42],[33,42]] },
      { id: "12_trixie",  scene: "outdoor", x: 64, y: 35, patrol: [[64,35],[72,35]] },
      { id: "13_mirelle", scene: "outdoor", x: 41, y: 50, patrol: [[41,50],[42,50]] },
      { id: "14_kael",    scene: "outdoor", x: 43, y: 46, patrol: [[38,46],[46,46]] },
      { id: "07_sera",    scene: "bakery",  x: 8,  y: 4,  patrol: [[6,4],[10,4]] },
      { id: "16_bram",    scene: "tavern",  x: 8,  y: 2.3,patrol: [[6,2.3],[11,2.3]] },
      { id: "09_celeste", scene: "tavern",  x: 13, y: 9.5,patrol: [[13,9.5],[14,9.5]] },
      { id: "11_pip",     scene: "shop",    x: 8,  y: 2.3,patrol: [[6,2.3],[10,2.3]] },
      { id: "15_thorn",   scene: "smithy",  x: 8,  y: 4.3,patrol: [[8,4.3],[8,4.3]] },
      { id: "03_lilian",  scene: "cottage", x: 8,  y: 3.3,patrol: [[6,3.3],[10,3.3]] },
      { id: "01_ren",     scene: "outdoor", x: 34, y: 28, patrol: [[34,28],[38,28],[38,32]] }
    ];
    NPCS.forEach((n, i) => {
      const c = CHAR_BY_ID[n.id];
      n.name = c ? `${c.name_th} (${c.name_en.split(" ")[0]})` : n.id;
      n.px = n.x * TILE; n.py = n.y * TILE;
      n.wpIdx = 0; n.dir = 2; n.state = "idle"; n.timer = 1.5 + (i % 4);
      n.animT = i * 0.4; n.actionRow = 2; n.activity = "เดินเล่นในเมือง";
    });

    // =========================================================================
    // 6. SYSTEM 6B: 7 ZONE-SPECIFIC DYNAMIC WEB AUDIO BGM ENGINE + SFX!
    // =========================================================================
    const BGM_THEMES = {
      plaza:   { name_th: "🌳 ลมหายใจต้นไม้โลก",     tempo: 560, wave: "sine",     bassWave: "triangle", vol: 0.026, notes: [261.6, 329.6, 392.0, 493.9, 523.3, 493.9, 392.0, 329.6, 293.7, 369.9, 440.0, 392.0], bass: [130.8, 130.8, 146.8, 196.0] },
      home:    { name_th: "🏡 อ้อมกอดกระท่อมรากไม้ทอง", tempo: 660, wave: "sine",     bassWave: "sine",     vol: 0.025, notes: [349.2, 440.0, 523.3, 440.0, 392.0, 523.3, 659.3, 523.3, 349.2, 440.0, 587.3, 523.3], bass: [174.6, 130.8, 146.8, 130.8] },
      tavern:  { name_th: "🍺 ค่ำคืนโรงเตี๊ยมตะเกียงมอส",tempo: 390, wave: "triangle", bassWave: "triangle", vol: 0.028, notes: [392.0, 493.9, 587.3, 659.3, 587.3, 493.9, 440.0, 523.3, 659.3, 587.3, 493.9, 392.0], bass: [196.0, 146.8, 164.8, 146.8] },
      smithy:  { name_th: "⚒️ จังหวะค้อนศิลาเพลิง",    tempo: 440, wave: "triangle", bassWave: "sawtooth", vol: 0.024, notes: [293.7, 349.2, 440.0, 293.7, 392.0, 440.0, 523.3, 440.0, 349.2, 329.6, 293.7, 261.6], bass: [146.8, 146.8, 130.8, 146.8] },
      nature:  { name_th: "🌊 เพลงพรายน้ำและพงไพร",     tempo: 620, wave: "sine",     bassWave: "sine",     vol: 0.025, notes: [329.6, 392.0, 440.0, 587.3, 659.3, 587.3, 440.0, 392.0, 329.6, 493.9, 587.3, 440.0], bass: [164.8, 196.0, 146.8, 164.8] },
      ruins:   { name_th: "🔦 เสียงสะท้อนใต้รากไม้โบราณ",tempo: 700, wave: "sine",     bassWave: "triangle", vol: 0.028, notes: [220.0, 261.6, 329.6, 415.3, 440.0, 415.3, 329.6, 261.6, 246.9, 293.7, 329.6, 220.0], bass: [110.0, 130.8, 123.5, 110.0] },
      wedding: { name_th: "💒 คำสัญญาใต้กลีบใบไม้ทอง",   tempo: 520, wave: "sine",     bassWave: "triangle", vol: 0.032, notes: [293.7, 369.9, 440.0, 587.3, 659.3, 739.9, 587.3, 440.0, 392.0, 493.9, 587.3, 739.9], bass: [146.8, 110.0, 123.5, 196.0] }
    };

    const audio = { ctx: null, enabled: false, bgmTimer: null, noteIdx: 0, currentZone: "plaza", overrideZone: null };
    function ensureAudio() {
      if (!audio.ctx && typeof window !== "undefined") {
        const AC = window.AudioContext || window.webkitAudioContext;
        if (AC) audio.ctx = new AC();
      }
      if (audio.ctx && audio.ctx.state === "suspended") audio.ctx.resume();
    }
    function playTone(freq, dur = 0.12, type = "sine", vol = 0.08, delay = 0) {
      if (!audio.enabled || !audio.ctx) return;
      const now = audio.ctx.currentTime + delay;
      const osc = audio.ctx.createOscillator();
      const gain = audio.ctx.createGain();
      osc.type = type; osc.frequency.setValueAtTime(freq, now);
      gain.gain.setValueAtTime(0.0001, now);
      gain.gain.exponentialRampToValueAtTime(Math.max(0.0002, vol), now + 0.015);
      gain.gain.exponentialRampToValueAtTime(0.0001, now + dur);
      osc.connect(gain); gain.connect(audio.ctx.destination);
      osc.start(now); osc.stop(now + dur + 0.02);
    }
    function sfx(kind) {
      if (!audio.enabled) return;
      ensureAudio();
      if (kind === "talk") playTone(520 + Math.random()*140, 0.05, "triangle", 0.045);
      else if (kind === "door") { playTone(260, 0.09, "sine", 0.07); playTone(390, 0.12, "sine", 0.06, 0.06); }
      else if (kind === "coin") { playTone(880, 0.08, "sine", 0.07); playTone(1175, 0.16, "sine", 0.07, 0.07); }
      else if (kind === "heart") { playTone(523, 0.1, "sine", 0.07); playTone(659, 0.1, "sine", 0.07, 0.08); playTone(784, 0.2, "sine", 0.08, 0.16); }
      else if (kind === "quest") { [523, 659, 784, 1046].forEach((f, i) => playTone(f, 0.16, "triangle", 0.07, i * 0.08)); }
      else if (kind === "sparkle") { playTone(1046, 0.08, "sine", 0.06); playTone(1318, 0.12, "sine", 0.06, 0.06); }
      else if (kind === "splash") { playTone(180, 0.12, "triangle", 0.08); playTone(310, 0.15, "sine", 0.06, 0.06); }
      else if (kind === "miss") { playTone(190, 0.16, "sawtooth", 0.05); }
      else if (kind === "build") { [330, 440, 554, 659, 880].forEach((f, i) => playTone(f, 0.16, "triangle", 0.075, i * 0.07)); }
      else if (kind === "concert") { [392, 494, 587, 784, 988, 784].forEach((f, i) => playTone(f, 0.24, "sine", 0.065, i * 0.09)); }
      else if (kind === "mystery") { [440, 523, 622, 659].forEach((f, i) => playTone(f, 0.15, "triangle", 0.06, i * 0.08)); }
      else if (kind === "beam") { playTone(660, 0.09, "sine", 0.07); playTone(990, 0.14, "sine", 0.06, 0.05); }
      else if (kind === "anvil") { playTone(220, 0.07, "sawtooth", 0.08); playTone(880, 0.12, "triangle", 0.07, 0.02); }
      else if (kind === "wedding") { [293.7, 369.9, 440, 587.3, 739.9, 880].forEach((f, i) => playTone(f, 0.32, "sine", 0.075, i * 0.11)); }
    }

    function computeDesiredBgmZone() {
      if (audio.overrideZone && BGM_THEMES[audio.overrideZone]) return audio.overrideZone;
      const sc = state.scene;
      if (sc.startsWith("ruins_")) return "ruins";
      if (sc === "farmhouse" || sc === "farmhouse_upstairs") return "home";
      if (sc === "tavern" || sc === "bakery" || sc === "shop") return "tavern";
      if (sc === "smithy") return "smithy";
      if (sc === "cottage") return "nature";
      const tx = state.player.x / TILE, ty = state.player.y / TILE;
      if (tx < 26 && ty < 26) return "home";
      if (tx > 62 && ty < 36) return "smithy";
      if (tx > 50 && ty < 34) return "tavern";
      if (ty > 43 || (tx < 28 && ty > 32)) return "nature";
      return "plaza";
    }

    function restartBgmLoop() {
      clearInterval(audio.bgmTimer);
      const theme = BGM_THEMES[audio.currentZone] || BGM_THEMES.plaza;
      const lbl = document.getElementById("bgmZoneLabel");
      if (lbl) lbl.textContent = `🎵 ${theme.name_th}`;
      if (!audio.enabled) return;
      audio.bgmTimer = setInterval(() => {
        if (!audio.enabled) return;
        const th = BGM_THEMES[audio.currentZone] || BGM_THEMES.plaza;
        const isNight = (state.timeMin >= 18.5 * 60 || state.timeMin < 6 * 60) && state.scene === "outdoor";
        const mult = isNight ? 0.84 : 1.0;
        const n = th.notes[audio.noteIdx % th.notes.length] * mult;
        playTone(n, (th.tempo / 1000) * 0.88, th.wave, th.vol);
        if (audio.noteIdx % 3 === 0) {
          const b = th.bass[Math.floor(audio.noteIdx / 3) % th.bass.length] * mult;
          playTone(b, (th.tempo / 1000) * 1.6, th.bassWave, th.vol * 0.65);
        }
        audio.noteIdx++;
      }, theme.tempo);
    }

    function syncBgmZone() {
      const z = computeDesiredBgmZone();
      if (z !== audio.currentZone) {
        audio.currentZone = z;
        audio.noteIdx = 0;
        restartBgmLoop();
      } else {
        const lbl = document.getElementById("bgmZoneLabel");
        if (lbl) lbl.textContent = `🎵 ${(BGM_THEMES[z] || BGM_THEMES.plaza).name_th}`;
      }
    }

    function setAudioEnabled(on) {
      if (on) ensureAudio();
      audio.enabled = on;
      const btn = document.getElementById("btn-audio");
      if (btn) btn.textContent = on ? "🔊 เสียง" : "🔇 เสียง";
      if (on) sfx("heart");
      restartBgmLoop();
    }

    // =========================================================================
    // 7. STATE, 8-RACE HERO RECOLOR, 3 SAVE SLOTS & ACHIEVEMENTS
    // =========================================================================
    const SAVE_PREFIX = "aethelgard_lifesim_v6_slot_";
    let activeSaveSlot = 1;

    function makeDefaultRelations() {
      const rel = {};
      GAME_DATA.characters.characters.forEach(c => {
        rel[c.id] = { xp: 120, talkedToday: false, giftedToday: false };
      });
      return rel;
    }
    function makeDefaultRuinsState() {
      const rs = {};
      for (const [fid, fdef] of Object.entries(RUINS_FLOORS)) {
        rs[fid] = {
          pillars: fdef.pillars.map(p => p.init),
          solved: false,
          chestOpened: false,
          minedDay: {}
        };
      }
      return rs;
    }

    const state = {
      started: false,
      scene: "outdoor",
      returnPos: { x: 42 * TILE, y: 31 * TILE },
      playerName: "อาริน",
      cottageName: "กระท่อมรากไม้ทอง",
      favThing: "ครัวซองต์น้ำผึ้ง",
      heroCustom: { baseId: "01_ren", raceKey: "human", hue: 0, sat: 100, val: 100, skin: "none" },
      player: { x: 42 * TILE, y: 31 * TILE, dir: 2, moving: false, sprinting: false, animT: 0, target: null, interactT: 0 },
      pet: { kind: "cat", x: 41 * TILE, y: 31.4 * TILE, dir: 2, pettedToday: false, hopT: 0 },
      day: 1,
      timeMin: 8 * 60,
      weather: "sunny",
      gold: 600,
      stamina: 100,
      tool: 0,
      fading: false,
      activeDlgNpc: null,
      modalOpen: false,
      miniGameOpen: false,
      worldMapOpen: false,
      summaryOpen: false,
      homeEditMode: false,
      selectedDecorId: null,
      selectedDecorRot: 0,
      mouseWorld: { tx: 8, ty: 6 },
      compassNpcId: null,
      compassLandmarkId: null,
      keys: {},
      stats: { charm: 10, craft: 10, wisdom: 10, courage: 10 },
      inventory: {
        item_honey_croissant: 2,
        item_wild_honey: 2,
        item_rich_milk: 1,
        item_roasted_coffee: 1,
        item_emerald_tea: 1,
        item_hard_oak: 1
      },
      relations: makeDefaultRelations(),
      partners: {},
      spouseId: null,
      weddingDay: 0,
      spouseCaredDay: 0,
      spouseDatedDay: 0,
      houseLevel: 1, // 1 = Ground Floor, 2 = 2nd Floor Starlight Loft Unlocked!
      decorOwned: { decor_mirror: true }, // Free starter Magic Wardrobe Mirror!
      decorPlaced: [
        { id: "decor_mirror", scene: "farmhouse", x: 4, y: 2, w: 1, h: 2 }
      ],
      decorUsedDay: {},
      ruins: makeDefaultRuinsState(),
      quests: { q01_welcome: "accepted" },
      playedEvents: {},
      workedToday: {},
      landmarksBuilt: {},
      museumDonated: {},
      museumMilestonesClaimed: {},
      chroniclesDone: {},
      landmarkUsedDay: {},
      meteorShowerDay: 0,
      talkedEver: {},
      achievements: {},
      mailbox: [],
      deliveredMailIds: {},
      storyFinaleSeen: false,
      festivalJoinedDay: 0,
      totalShifts: 0,
      sRankJobs: 0,
      fishCaught: 0,
      foragedCount: 0,
      craftedCount: 0,
      nightLanternSteps: 0,
      visitedTavernNight: false,
      dailyLog: { goldEarned: 0, heartsGained: 0, statXpGained: 0, itemsFound: 0, craftsMade: 0 }
    };

    // Outline-Preserving HSV + 7 Skin-Tint Protagonist Sheet Recolor!
    function rgbToHsv(r, g, b) {
      r /= 255; g /= 255; b /= 255;
      const mx = Math.max(r, g, b), mn = Math.min(r, g, b), d = mx - mn;
      let h = 0;
      if (d !== 0) {
        if (mx === r) h = ((g - b) / d) % 6;
        else if (mx === g) h = (b - r) / d + 2;
        else h = (r - g) / d + 4;
        h = (h * 60 + 360) % 360;
      }
      return [h, mx === 0 ? 0 : d / mx, mx];
    }
    function hsvToRgb(h, s, v) {
      const c = v * s, x = c * (1 - Math.abs(((h / 60) % 2) - 1)), m = v - c;
      let r = 0, g = 0, b = 0;
      if (h < 60) [r,g,b] = [c,x,0];
      else if (h < 120) [r,g,b] = [x,c,0];
      else if (h < 180) [r,g,b] = [0,c,x];
      else if (h < 240) [r,g,b] = [0,x,c];
      else if (h < 300) [r,g,b] = [x,0,c];
      else [r,g,b] = [c,0,x];
      return [Math.round((r+m)*255), Math.round((g+m)*255), Math.round((b+m)*255)];
    }
    const SKIN_TARGETS = {
      warm:   [22, 0.28, 0.96],
      tan:    [26, 0.44, 0.80],
      pale:   [320, 0.08, 0.96],
      drow:   [255, 0.24, 0.72],
      goblin: [46, 0.68, 0.92],
      aqua:   [172, 0.34, 0.88]
    };
    function recolorSheetImage(img, hc) {
      if (!img) return null;
      const w = img.width || 576, h = img.height || 256;
      const c = document.createElement("canvas");
      c.width = w; c.height = h;
      const g = c.getContext("2d");
      g.imageSmoothingEnabled = false;
      g.drawImage(img, 0, 0);
      if (hc.hue === 0 && hc.sat === 100 && hc.val === 100 && hc.skin === "none") return c;
      const idata = g.getImageData(0, 0, w, h);
      const d = idata.data;
      const satMul = hc.sat / 100, valMul = hc.val / 100, skinCfg = SKIN_TARGETS[hc.skin];
      for (let i = 0; i < d.length; i += 4) {
        if (d[i + 3] < 160) continue; // Keep ground shadow untouched!
        const r = d[i], gr = d[i + 1], b = d[i + 2];
        const lum = 0.299 * r + 0.587 * gr + 0.114 * b;
        if (lum < 68) continue; // Keep crisp 2.5D ink outlines!
        let [hv, sv, vv] = rgbToHsv(r, gr, b);
        if (sv < 0.09 && vv > 0.85) continue; // Keep white eye sclera!
        const isWarmSkin = (hv >= 10 && hv <= 42 && sv >= 0.12 && sv <= 0.48 && vv >= 0.55);
        if (skinCfg && isWarmSkin) {
          hv = skinCfg[0];
          sv = Math.min(0.95, sv * 0.35 + skinCfg[1] * 0.65);
          vv = Math.min(0.98, vv * 0.55 + skinCfg[2] * 0.45);
        } else {
          hv = (hv + hc.hue + 360) % 360;
          sv = Math.min(0.96, sv * satMul);
          vv = Math.min(0.97, Math.max(0.12, vv * valMul));
        }
        const [nr, ng, nb] = hsvToRgb(hv, sv, vv);
        d[i] = nr; d[i + 1] = ng; d[i + 2] = nb;
      }
      g.putImageData(idata, 0, 0);
      return c;
    }

    function rebuildHeroCustomSheets() {
      const bid = state.heroCustom.baseId || "01_ren";
      state.heroCustom.raceKey = getCharRaceKey(bid);
      HERO_SHEETS.walk     = recolorSheetImage(SPRITES.walk[bid], state.heroCustom);
      HERO_SHEETS.idle     = recolorSheetImage(SPRITES.idle[bid], state.heroCustom);
      HERO_SHEETS.interact = recolorSheetImage(SPRITES.interact[bid], state.heroCustom);
      // Update Title Screen Mini Preview
      const tc = document.getElementById("titleHeroCanvas");
      if (tc && HERO_SHEETS.walk) {
        const tg = tc.getContext("2d");
        tg.imageSmoothingEnabled = false;
        tg.clearRect(0, 0, 64, 64);
        tg.drawImage(HERO_SHEETS.walk, 0, 2 * 64, 64, 64, 0, 0, 64, 64);
      }
      const rInfo = RACE_PERKS[state.heroCustom.raceKey] || RACE_PERKS.human;
      const ts = document.getElementById("titleHeroSummary");
      if (ts) ts.textContent = `${rInfo.icon} ${rInfo.name_th} • 🏡 ${state.cottageName}`;
      try {
        localStorage.setItem("aethelgard_protagonist_v1", JSON.stringify({
          name: state.playerName, farm: state.cottageName, favorite: state.favThing,
          base_id: state.heroCustom.baseId, hue: state.heroCustom.hue,
          saturation: state.heroCustom.sat, brightness: state.heroCustom.val, skin_tint: state.heroCustom.skin
        }));
      } catch (_) {}
    }

    // Achievements (Expanded to 20 covering Marriage, 2nd Floor, Grid Decor, Ancient Ruins, Protagonist!)
    const ACHIEVEMENTS = [
      { id: "ach_social",    icon: "🤝", title_th: "เพื่อนใหม่หุบเขา",        desc_th: "พูดคุยกับชาวเมืองครบ 5 คน",         check: () => Object.keys(state.talkedEver).length >= 5 },
      { id: "ach_srank",     icon: "🌟", title_th: "ยอดฝีมือ 6 สายอาชีพ",    desc_th: "ทำคะแนนระดับ S ในมินิเกมแยกสาย",    check: () => (state.sRankJobs || 0) >= 1 },
      { id: "ach_angler",    icon: "🎣", title_th: "เซียนตกปลา Stardew",      desc_th: "ตกปลาจากทะเลสาบมุกครบ 3 ครั้ง",     check: () => (state.fishCaught || 0) >= 3 },
      { id: "ach_forager",   icon: "✨", title_th: "นักสำรวจตาเหยี่ยว",      desc_th: "เก็บของป่าเรืองแสงครบ 5 จุด",        check: () => (state.foragedCount || 0) >= 5 },
      { id: "ach_craft",     icon: "🍳", title_th: "เชฟ & นักคราฟต์มือทอง",  desc_th: "คราฟต์หรือทำอาหารครบ 3 ชิ้น",        check: () => (state.craftedCount || 0) >= 3 },
      { id: "ach_rich",      icon: "💰", title_th: "เศรษฐีเอเธลการ์ด",        desc_th: "มีเงินเก็บตั้งแต่ 1,500 G",          check: () => state.gold >= 1500 },
      { id: "ach_decor",     icon: "🛋️", title_th: "มัณฑนากรจัดบ้านตาราง",   desc_th: "วางเฟอร์นิเจอร์ตกแต่งบ้านครบ 4 ชิ้น", check: () => (state.decorPlaced || []).length >= 4 },
      { id: "ach_loft",      icon: "🌟", title_th: "ห้องใต้หลังคาชมดาว",     desc_th: "ขยายต่อเติมบ้านพักชั้น 2 สำเร็จ!",     check: () => state.houseLevel >= 2 },
      { id: "ach_heart",     icon: "💖", title_th: "สายใยแรกใต้ต้นไม้โลก",    desc_th: "เล่นอีเวนต์หัวใจจบอย่างน้อย 1 อีเวนต์", check: () => Object.keys(state.playedEvents).length >= 1 },
      { id: "ach_partner",   icon: "💍", title_th: "คู่รักแห่งเอเธลการ์ด",    desc_th: "สารภาพรักสำเร็จกับคนที่ชอบ",         check: () => Object.keys(state.partners || {}).length >= 1 },
      { id: "ach_married",   icon: "💒", title_th: "วิวาห์ใต้กลีบใบไม้ทอง",   desc_th: "เข้าพิธีแต่งงานและเริ่มต้นชีวิตคู่!",   check: () => !!state.spouseId },
      { id: "ach_ruins_b1",  icon: "🔦", title_th: "ผู้จุดเสาแสงรากไม้โลก",   desc_th: "ไขปริศนาเสาแสงโบราณสถานชั้น B1 สำเร็จ", check: () => !!state.ruins?.ruins_b1?.solved },
      { id: "ach_ruins_all", icon: "👑", title_th: "จ้าวแห่งหัวใจบรรพกาล",    desc_th: "พิชิตปริศนาเสาแสงครบทั้ง 3 ชั้น B1–B3!",check: () => ["ruins_b1","ruins_b2","ruins_b3"].every(k => state.ruins?.[k]?.solved) },
      { id: "ach_tree",      icon: "🌳", title_th: "ผู้ปลุกต้นไม้โลก",        desc_th: "ปลุกตราแห่งสายใยครบทั้ง 8 เผ่า!",     check: () => getAwakenedSealCount() >= 8 },
      { id: "ach_builder",   icon: "🏛️", title_th: "สถาปนิกแห่งเอเธลการ์ด",   desc_th: "บูรณะแลนด์มาร์กเมืองครบทั้ง 5 แห่ง!",  check: () => Object.keys(state.landmarksBuilt || {}).length >= 5 },
      { id: "ach_curator",   icon: "📚", title_th: "ภัณฑารักษ์ 8 เผ่า",        desc_th: "บริจาคโบราณวัตถุเข้าพิพิธภัณฑ์ครบ 6 ชิ้น", check: () => Object.keys(state.museumDonated || {}).length >= 6 },
      { id: "ach_detective", icon: "🕵️", title_th: "ยอดนักสืบหุบเขา",        desc_th: "ไขครบทั้ง 3 คดีสืบสวนประจำเมือง!",    check: () => ["mys_croissant","mys_loveletter","mys_violin"].every(id => state.chroniclesDone?.[id]) },
      { id: "ach_chronicle", icon: "📖", title_th: "ผู้สืบทอดเสียงสะท้อน",     desc_th: "จบเนื้อเรื่องหลักทั้ง 5 บทสมบูรณ์!",   check: () => !!state.chroniclesDone?.main_ch5 }
    ];

    // =========================================================================
    // SYSTEM 6A: 3 SAVE SLOTS (MIGRATION, PREVIEW, LOAD, SAVE, EXPORT/IMPORT!)
    // =========================================================================
    function migrateLegacySaveIfNeeded() {
      try {
        if (!localStorage.getItem(SAVE_PREFIX + "1")) {
          const old = localStorage.getItem("aethelgard_lifesim_v5") || localStorage.getItem("aethelgard_lifesim_v4");
          if (old) localStorage.setItem(SAVE_PREFIX + "1", old);
        }
      } catch (_) {}
    }
    migrateLegacySaveIfNeeded();

    function serializeCurrentState() {
      return {
        version: "6.0",
        savedAt: new Date().toISOString(),
        day: state.day, timeMin: state.timeMin, weather: state.weather,
        gold: state.gold, stamina: state.stamina,
        playerName: state.playerName, cottageName: state.cottageName, favThing: state.favThing,
        heroCustom: { ...state.heroCustom }, petKind: state.pet.kind,
        stats: { ...state.stats }, inventory: { ...state.inventory },
        relations: state.relations, partners: state.partners,
        spouseId: state.spouseId, weddingDay: state.weddingDay,
        spouseCaredDay: state.spouseCaredDay, spouseDatedDay: state.spouseDatedDay,
        houseLevel: state.houseLevel, decorOwned: state.decorOwned,
        decorPlaced: state.decorPlaced, decorUsedDay: state.decorUsedDay,
        ruins: state.ruins, quests: state.quests, playedEvents: state.playedEvents,
        workedToday: state.workedToday, landmarksBuilt: state.landmarksBuilt,
        museumDonated: state.museumDonated, museumMilestonesClaimed: state.museumMilestonesClaimed,
        chroniclesDone: state.chroniclesDone, landmarkUsedDay: state.landmarkUsedDay,
        meteorShowerDay: state.meteorShowerDay, talkedEver: state.talkedEver,
        achievements: state.achievements, mailbox: state.mailbox,
        deliveredMailIds: state.deliveredMailIds, storyFinaleSeen: state.storyFinaleSeen,
        festivalJoinedDay: state.festivalJoinedDay, totalShifts: state.totalShifts,
        sRankJobs: state.sRankJobs, fishCaught: state.fishCaught,
        foragedCount: state.foragedCount, craftedCount: state.craftedCount,
        nightLanternSteps: state.nightLanternSteps, visitedTavernNight: state.visitedTavernNight
      };
    }

    function readSlotData(slotNum) {
      try {
        const raw = localStorage.getItem(SAVE_PREFIX + slotNum);
        return raw ? JSON.parse(raw) : null;
      } catch (_) { return null; }
    }

    function applySaveObjectToState(s) {
      // Reset core defaults first so switching slots is 100% clean
      state.day = 1; state.timeMin = 8 * 60; state.weather = "sunny"; state.gold = 600; state.stamina = 100;
      state.playerName = "อาริน"; state.cottageName = "กระท่อมรากไม้ทอง"; state.favThing = "ครัวซองต์น้ำผึ้ง";
      state.heroCustom = { baseId: "01_ren", raceKey: "human", hue: 0, sat: 100, val: 100, skin: "none" };
      state.stats = { charm: 10, craft: 10, wisdom: 10, courage: 10 };
      state.inventory = { item_honey_croissant: 2, item_wild_honey: 2, item_rich_milk: 1, item_roasted_coffee: 1, item_emerald_tea: 1, item_hard_oak: 1 };
      state.relations = makeDefaultRelations();
      state.partners = {}; state.spouseId = null; state.weddingDay = 0; state.spouseCaredDay = 0; state.spouseDatedDay = 0;
      state.houseLevel = 1; state.decorOwned = { decor_mirror: true };
      state.decorPlaced = [{ id: "decor_mirror", scene: "farmhouse", x: 4, y: 2, w: 1, h: 2 }];
      state.decorUsedDay = {}; state.ruins = makeDefaultRuinsState();
      state.quests = { q01_welcome: "accepted" }; state.playedEvents = {}; state.workedToday = {};
      state.landmarksBuilt = {}; state.museumDonated = {}; state.museumMilestonesClaimed = {};
      state.chroniclesDone = {}; state.landmarkUsedDay = {}; state.talkedEver = {}; state.achievements = {};
      state.mailbox = []; state.deliveredMailIds = {}; state.storyFinaleSeen = false;

      if (!s) {
        try {
          const hp = JSON.parse(localStorage.getItem("aethelgard_protagonist_v1") || "null");
          if (hp) {
            if (hp.name) state.playerName = hp.name;
            if (hp.farm) state.cottageName = hp.farm;
            if (hp.favorite) state.favThing = hp.favorite;
            if (hp.base_id && CHAR_BY_ID[hp.base_id]) state.heroCustom.baseId = hp.base_id;
            if (hp.hue !== undefined) state.heroCustom.hue = Number(hp.hue);
            if (hp.saturation !== undefined) state.heroCustom.sat = Number(hp.saturation);
            if (hp.brightness !== undefined) state.heroCustom.val = Number(hp.brightness);
            if (hp.skin_tint) state.heroCustom.skin = hp.skin_tint;
          }
        } catch (_) {}
        return;
      }

      ["day","timeMin","weather","gold","stamina","playerName","cottageName","favThing","spouseId","weddingDay","spouseCaredDay","spouseDatedDay","houseLevel","totalShifts","sRankJobs","fishCaught","foragedCount","craftedCount","nightLanternSteps","visitedTavernNight","festivalJoinedDay","storyFinaleSeen","meteorShowerDay"].forEach(k => {
        if (s[k] !== undefined) state[k] = s[k];
      });
      if (s.heroCustom) state.heroCustom = Object.assign(state.heroCustom, s.heroCustom);
      ["stats","inventory","relations","partners","quests","playedEvents","workedToday","decorOwned","decorUsedDay","landmarksBuilt","museumDonated","museumMilestonesClaimed","chroniclesDone","landmarkUsedDay","talkedEver","achievements","deliveredMailIds"].forEach(k => {
        if (s[k]) state[k] = Object.assign(state[k] || {}, s[k]);
      });
      if (Array.isArray(s.decorPlaced)) {
        state.decorPlaced = s.decorPlaced;
      } else if (s.decorOwned) {
        // Migrate v5 owned decor onto valid grid positions!
        const migrated = [{ id: "decor_mirror", scene: "farmhouse", x: 4, y: 2, w: 1, h: 2 }];
        Object.keys(s.decorOwned).forEach(did => {
          if (did === "decor_mirror") return;
          const d = DECOR_BY_ID[did];
          if (d && d.defaultPos && d.defaultPos.scene === "farmhouse") {
            migrated.push({ id: did, scene: "farmhouse", x: d.defaultPos.x, y: d.defaultPos.y, w: d.w, h: d.h });
          }
        });
        state.decorPlaced = migrated;
      }
      if (s.ruins) {
        for (const [fid, fr] of Object.entries(s.ruins)) {
          if (state.ruins[fid]) state.ruins[fid] = Object.assign(state.ruins[fid], fr);
        }
      }
      if (Array.isArray(s.mailbox)) state.mailbox = s.mailbox;
      if (s.petKind && PET_TYPES[s.petKind]) state.pet.kind = s.petKind;
    }

    function loadSaveSlot(slotNum, announce = false) {
      activeSaveSlot = slotNum;
      const data = readSlotData(slotNum);
      applySaveObjectToState(data);
      const nameInp = document.getElementById("heroNameInput");
      if (nameInp) nameInp.value = state.playerName;
      document.querySelectorAll("#titlePetPicker button").forEach(b => b.classList.toggle("active", b.dataset.pet === state.pet.kind));
      spawnDailyForage();
      deliverDailyMail();
      if (assetsReady) rebuildHeroCustomSheets();
      renderSocialStatsHud();
      syncNpcSchedules();
      renderTitleSlotCards();
      if (announce) showToast(data ? `📂 โหลดเซฟช่องที่ ${slotNum} (${state.playerName}) สำเร็จ!` : `🌱 เลือกช่องที่ ${slotNum} (เริ่มเกมใหม่)`);
    }

    function saveGame(silent = false, slotNum = activeSaveSlot) {
      activeSaveSlot = slotNum;
      try {
        localStorage.setItem(SAVE_PREFIX + slotNum, JSON.stringify(serializeCurrentState()));
        renderTitleSlotCards();
        if (!silent) showToast(`💾 บันทึกเกมลง [ช่องเซฟ ${slotNum}] เรียบร้อยแล้ว!`);
      } catch (_) {}
    }

    function renderTitleSlotCards() {
      const grid = document.getElementById("titleSlotGrid");
      if (!grid) return;
      grid.innerHTML = [1, 2, 3].map(n => {
        const d = readSlotData(n);
        const sel = n === activeSaveSlot;
        if (!d) {
          return `<div class="slot-card ${sel ? 'selected' : ''}" onclick="window.selectTitleSlot(${n})">
            <div style="font-weight:800;font-size:12px;color:#4c230a;">📁 ช่องเซฟ ${n} ${sel ? '<span class="badge" style="background:#fde047;">เลือกอยู่</span>' : ''}</div>
            <div style="font-size:11.5px;color:#78350f;padding:6px 0;">✨ ว่างเปล่า — พร้อมสร้างตัวเอกใหม่</div>
          </div>`;
        }
        const sIdx = Math.floor(((d.day || 1) - 1) / 28) % 4;
        const dSeason = (((d.day || 1) - 1) % 28) + 1;
        const rKey = getCharRaceKey(d.heroCustom?.baseId || "01_ren");
        const rInfo = RACE_PERKS[rKey] || RACE_PERKS.human;
        const spouseTxt = d.spouseId ? `💒 ${CHAR_BY_ID[d.spouseId]?.name_th?.split(" ")[0]}` : "โสด/จีบอยู่";
        const ruinsCnt = ["ruins_b1","ruins_b2","ruins_b3"].filter(k => d.ruins?.[k]?.solved).length;
        return `<div class="slot-card ${sel ? 'selected' : ''}" onclick="window.selectTitleSlot(${n})">
          <div style="display:flex;justify-content:space-between;align-items:center;">
            <span style="font-weight:800;font-size:12px;color:#4c230a;">💾 ช่อง ${n}: ${d.playerName || "อาริน"}</span>
            ${sel ? '<span class="badge" style="background:#fde047;">เลือกอยู่</span>' : ''}
          </div>
          <div style="font-size:10.5px;font-weight:700;color:#5c3312;">${rInfo.icon} ${rInfo.name_th.split(" ")[0]} • วันที่ ${dSeason} ${SEASONS[sIdx].name_th}</div>
          <div style="font-size:10.5px;font-weight:800;color:#15803d;">🪙 ${d.gold || 0}G • ${spouseTxt} • 🔦B${ruinsCnt}/3</div>
        </div>`;
      }).join("");
    }
    window.selectTitleSlot = (n) => { sfx("talk"); loadSaveSlot(n, false); };
"""

JS_PART_2 = r"""
    const floatingTexts = [];
    const particles = [];
    const chimneySmoke = [];
    const ambientMotes = Array.from({ length: 28 }, (_, i) => ({
      x: Math.random() * MAP_W * TILE, y: Math.random() * MAP_H * TILE,
      vx: 8 + Math.random() * 14, vy: 6 + Math.random() * 10, phase: i * 0.7, size: 2 + (i % 3)
    }));
    let forageSpots = [];
    function spawnDailyForage() {
      const shuffled = [...FORAGE_CANDIDATES].sort(() => Math.random() - 0.5);
      forageSpots = shuffled.slice(0, 8).map((s, idx) => ({ ...s, id: `f_${state.day}_${idx}`, collected: false }));
    }
    function spawnFloatText(text, x, y, color = "#fef08a") {
      floatingTexts.push({ text, x, y, color, life: 1.5, maxLife: 1.5 });
    }
    function spawnParticles(x, y, color, count = 10) {
      for (let i = 0; i < count; i++) {
        const a = Math.random() * Math.PI * 2, sp = 24 + Math.random() * 48;
        particles.push({ x, y, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp - 18, color, life: 0.65 + Math.random() * 0.35, size: 2.5 + Math.random() * 2.5 });
      }
    }

    function deliverDailyMail() {
      MAIL_TEMPLATES.forEach(m => {
        if (state.day >= m.day && !state.deliveredMailIds[m.id]) {
          state.deliveredMailIds[m.id] = true;
          state.mailbox.unshift({ ...m, read: false, claimed: false });
        }
      });
      const genId = `mail_auto_d${state.day}`;
      if (state.day >= 4 && state.day % 3 === 0 && !state.deliveredMailIds[genId]) {
        state.deliveredMailIds[genId] = true;
        const c = GAME_DATA.characters.characters[state.day % GAME_DATA.characters.characters.length];
        const giftPool = ["item_wild_honey", "item_roasted_coffee", "item_emerald_tea", "item_brass_gear", "item_sunfruit"];
        const gid = giftPool[state.day % giftPool.length];
        state.mailbox.unshift({
          id: genId, sender: `${c.name_th} (${c.race_th})`,
          title: `ทักทายยามเช้าจาก${c.name_th}!`,
          body: `สวัสดี {player}! ฉันเจอของดีแถว${c.home} เลยส่งมาฝากไว้ที่ {farm} หวังว่าจะช่วยให้วันนี้ของเธอสดใสขึ้นนะ!`,
          gift_id: gid, gold: 45, read: false, claimed: false
        });
      }
      updateMailBadge();
    }
    function updateMailBadge() {
      const unread = state.mailbox.filter(m => !m.read || (!m.claimed && (m.gift_id || m.gold))).length;
      const el = document.getElementById("mailBadge");
      if (!el) return;
      if (unread > 0) { el.style.display = "flex"; el.textContent = unread; }
      else { el.style.display = "none"; }
    }

    function getAwakenedSealCount() {
      return STORY_SEALS.filter(s => s.members.some(cid => getHearts(cid) >= 3)).length;
    }
    function updateStoryBadge() {
      const seals = getAwakenedSealCount();
      const doneCh = CHRONICLES.filter(ch => state.chroniclesDone[ch.id]).length;
      const el = document.getElementById("storySealBadge");
      if (el) el.textContent = state.chroniclesDone.main_ch5 ? `🌟 ${doneCh}/${CHRONICLES.length} • 8/8` : `${doneCh}/${CHRONICLES.length} บท • ${seals}/8 เผ่า`;
      const built = Object.keys(state.landmarksBuilt || {}).length;
      const ruinsCnt = ["ruins_b1","ruins_b2","ruins_b3"].filter(k => state.ruins?.[k]?.solved).length;
      const tel = document.getElementById("townRestoreBadge");
      if (tel) tel.textContent = `${built}/5 แห่ง • 🔦B${ruinsCnt}/3`;
      if (seals >= 8 && !state.storyFinaleSeen && state.started) {
        state.storyFinaleSeen = true;
        sfx("quest");
        spawnParticles(state.player.x, state.player.y - 24, "#fde047", 36);
        showToast("🌳✨ สายใยครบทั้ง 8 เผ่า! เปิด '📖 เนื้อเรื่อง & คดี' เพื่อเล่นบทที่ 5 Grand Finale ได้เลย!");
        checkAchievements();
      }
    }

    function getCalendarInfo() {
      const seasonIdx = Math.floor((state.day - 1) / 28) % 4;
      const dayOfSeason = ((state.day - 1) % 28) + 1;
      const dayOfWeekIdx = (state.day - 1) % 7;
      const weekday = WEEKDAYS[dayOfWeekIdx];
      return { season: SEASONS[seasonIdx], seasonIdx, dayOfSeason, dayOfWeekIdx, weekday, festival: FESTIVALS[dayOfSeason] || null };
    }
    function getStatLevelInfo(statId) {
      const def = GAME_DATA.social_stats.stats.find(s => s.id === statId);
      const xp = state.stats[statId] || 0;
      let cur = def.levels[0], next = def.levels[1] || null;
      for (let i = 0; i < def.levels.length; i++) {
        if (xp >= def.levels[i].xp_required) { cur = def.levels[i]; next = def.levels[i + 1] || null; }
      }
      const pct = next ? Math.min(100, Math.round(((xp - cur.xp_required) / (next.xp_required - cur.xp_required)) * 100)) : 100;
      return { def, xp, level: cur.level, title_th: cur.title_th, perk_th: cur.perk_th, pct };
    }
    function hasPlacedDecor(did) {
      return (state.decorPlaced || []).some(p => p.id === did);
    }
    function getMaxStamina() {
      let max = 100;
      if (getStatLevelInfo("courage").level >= 4) max += 20;
      if (hasPlacedDecor("decor_plush_bed") || state.decorOwned.decor_plush_bed) max += 20;
      if (hasPlacedDecor("decor_sofa") || state.decorOwned.decor_sofa) max += 10;
      if (state.houseLevel >= 2) max += 15;
      if (state.heroCustom.raceKey === "dwarf") max += 15;
      if (state.spouseId) max += 10;
      return max;
    }
    function getStaminaCost(rawCost) {
      if (state.heroCustom.raceKey === "vampire" && (state.timeMin >= 18 * 60 || state.timeMin < 6 * 60)) {
        return Math.max(1, Math.round(rawCost * 0.75));
      }
      return rawCost;
    }

    function checkAchievements() {
      ACHIEVEMENTS.forEach(a => {
        if (!state.achievements[a.id] && a.check()) {
          state.achievements[a.id] = true;
          sfx("quest");
          spawnFloatText(`🏆 ${a.title_th}!`, state.player.x, state.player.y - 48, "#fde047");
          spawnParticles(state.player.x, state.player.y - 20, "#facc15", 16);
          showToast(`🏆 ปลดล็อกความสำเร็จ: ${a.icon} ${a.title_th}!`);
        }
      });
    }
    function addStatXp(statMap) {
      const msgs = [];
      const humanMult = state.heroCustom.raceKey === "human" ? 1.1 : 1.0;
      for (const [k, v] of Object.entries(statMap || {})) {
        if (!v) continue;
        const gain = Math.max(1, Math.round(v * humanMult));
        const before = getStatLevelInfo(k).level;
        state.stats[k] = (state.stats[k] || 0) + gain;
        state.dailyLog.statXpGained += gain;
        const after = getStatLevelInfo(k);
        msgs.push(`${after.def.icon}+${gain}`);
        if (after.level > before) {
          setTimeout(() => showToast(`🎉 สเตตัส ${after.def.icon}${after.def.name_th} อัปเป็น Lv.${after.level} (${after.title_th})!`), 700);
        }
      }
      renderSocialStatsHud();
      checkAchievements();
      return msgs.join(" ");
    }
    function getHearts(cid) {
      return Math.min(10, Math.floor(((state.relations[cid]?.xp) || 0) / 100));
    }
    function addFriendship(cid, delta) {
      if (!state.relations[cid]) state.relations[cid] = { xp: 0, talkedToday: false, giftedToday: false };
      const bonus = (delta > 0 && getStatLevelInfo("charm").level >= 4) ? Math.round(delta * 1.2) : delta;
      state.relations[cid].xp = Math.max(0, Math.min(1000, state.relations[cid].xp + bonus));
      if (bonus > 0) state.dailyLog.heartsGained += bonus;
      updateStoryBadge();
      return bonus;
    }
    function addGold(amount) {
      state.gold += amount;
      if (amount > 0) state.dailyLog.goldEarned += amount;
    }
    function formatText(txt) {
      return (txt || "")
        .replace(/\{player\}/g, state.playerName)
        .replace(/\{farm\}/g, state.cottageName || "กระท่อมรากไม้ทอง")
        .replace(/\{fav\}/g, state.favThing || "ครัวซองต์น้ำผึ้ง");
    }
    function renderSocialStatsHud() {
      const wrap = document.getElementById("socialStatsHud");
      if (!wrap) return;
      wrap.innerHTML = GAME_DATA.social_stats.stats.map(s => {
        const info = getStatLevelInfo(s.id);
        return `<div class="stat-pill" title="${s.name_th} Lv.${info.level} (${info.title_th}) — ${info.perk_th}">
          <div style="display:flex;justify-content:space-between;"><span>${s.icon} ${s.name_th}</span><span>Lv.${info.level}</span></div>
          <div class="stat-bar-bg"><div class="stat-bar-fill" style="width:${info.pct}%;background:${s.color};"></div></div>
        </div>`;
      }).join("");
      const mx = document.getElementById("maxStaminaLabel");
      if (mx) mx.textContent = getMaxStamina();
      const hb = document.getElementById("heroNameBadge");
      if (hb) {
        const rIcon = (RACE_PERKS[state.heroCustom.raceKey] || RACE_PERKS.human).icon;
        hb.textContent = `${state.spouseId ? "💒" : rIcon} ${state.playerName}`;
      }
      updateQuestTrackerHud();
      updateStoryBadge();
      updateMailBadge();
    }

    function getQuestProgress(q) {
      const obj = q.objective || {};
      if (obj.type === "talk_npcs") {
        const cur = Object.keys(state.talkedEver).length, req = obj.count || 5;
        return { cur, req, ready: cur >= req, text: `คุยชาวเมือง ${Math.min(cur,req)}/${req} คน` };
      }
      if (obj.type === "work_shifts") {
        const cur = state.totalShifts || 0, req = obj.count || 1;
        return { cur, req, ready: cur >= req, text: `ทำพาร์ทไทม์ ${Math.min(cur,req)}/${req} กะ` };
      }
      if (obj.type === "have_item") {
        const cur = state.inventory[obj.item_id] || 0, req = obj.count || 1;
        return { cur, req, ready: cur >= req, text: `มี ${obj.item} ${cur}/${req} ชิ้น` };
      }
      if (obj.type === "inspect_night") {
        const cur = Math.floor((state.nightLanternSteps || 0) / 15), req = obj.count || 4;
        return { cur, req, ready: cur >= req, text: `ถือตะเกียง [9] ตรวจเมืองคืนนี้ ${Math.min(cur,req)}/${req}` };
      }
      if (obj.type === "attend_event") {
        const ready = !!state.visitedTavernNight;
        return { cur: ready ? 1 : 0, req: 1, ready, text: ready ? "เข้าโรงเตี๊ยมหลัง 19:00 น. แล้ว!" : "เข้าโรงเตี๊ยมหลัง 19:00 น." };
      }
      return { cur: 1, req: 1, ready: true, text: "พร้อมส่งเควสต์" };
    }
    function updateQuestTrackerHud() {
      const box = document.getElementById("questTrackerBox");
      if (!box) return;
      const activeQ = GAME_DATA.quests.quests.find(q => state.quests[q.id] === "accepted");
      if (!activeQ) { box.style.display = "none"; return; }
      const prog = getQuestProgress(activeQ);
      box.style.display = "block";
      document.getElementById("qtTitle").textContent = activeQ.title;
      document.getElementById("qtStatus").textContent = prog.ready ? "✅ ครบเงื่อนไขแล้ว! คลิกเพื่อส่ง" : prog.text;
      document.getElementById("qtBar").style.width = `${Math.min(100, Math.round((prog.cur / Math.max(1, prog.req)) * 100))}%`;
    }

    function parseHHMM(str) {
      const [h, m] = (str || "08:00").split(":").map(Number);
      return (h || 0) * 60 + (m || 0);
    }
    function syncNpcSchedules() {
      const schedMap = GAME_DATA.schedules.schedules;
      const mode = state.weather === "rainy" ? "rainy" : "default";
      const hr = state.timeMin / 60;
      NPCS.forEach((n, idx) => {
        // SYSTEM 3: Married Spouse lives in our home morning (06:00-09:30) & evening (19:30-24:00)!
        if (state.spouseId === n.id && (hr < 9.5 || hr >= 19.5)) {
          const spouseScene = (state.houseLevel >= 2 && hr >= 20.5) ? "farmhouse_upstairs" : "farmhouse";
          n.activity = spouseScene === "farmhouse_upstairs" ? "ชมดาวกับคู่ชีวิตบนชั้น 2 💒" : "ดูแลบ้านพักและเตรียมมื้ออุ่นๆ 💒";
          if (n.scene !== spouseScene) {
            n.scene = spouseScene;
            const sx = spouseScene === "farmhouse_upstairs" ? 6 : 6.5;
            const sy = spouseScene === "farmhouse_upstairs" ? 6 : 5.5;
            n.px = sx * TILE; n.py = sy * TILE;
            n.patrol = [[sx, sy], [sx + 1.5, sy]];
            n.wpIdx = 0;
          }
          return;
        }

        const entry = schedMap[n.id];
        if (!entry) return;
        const list = entry[mode] || entry.default || [];
        if (!list.length) return;
        let active = list[0];
        for (const slot of list) { if (state.timeMin >= parseHHMM(slot.time)) active = slot; }
        const targetScene = (active.scene && (active.scene === "outdoor" || INDOORS[active.scene])) ? active.scene : "outdoor";
        n.activity = active.activity || "เดินเล่นในเมือง";
        if (n.scene !== targetScene) {
          n.scene = targetScene;
          const ox = targetScene === "outdoor" ? 0 : ((idx % 4) - 1.5) * 1.1;
          const oy = targetScene === "outdoor" ? 0 : (Math.floor(idx / 4) % 2) * 1.0;
          const rm = targetScene === "outdoor" ? null : INDOORS[targetScene];
          const tx = rm ? Math.max(2, Math.min(rm.w - 3, (active.x || 7) + ox)) : (active.x || n.x);
          const ty = rm ? Math.max(3, Math.min(rm.h - 3, (active.y || 6) + oy)) : (active.y || n.y);
          n.px = tx * TILE; n.py = ty * TILE;
          n.patrol = [[tx, ty], [Math.max(2, tx - 1.2), ty], [tx + 1.2, ty]];
          n.wpIdx = 0;
        }
      });
    }

    let pendingNextWeather = "sunny";
    function triggerEndOfDaySummary() {
      if (state.summaryOpen) return;
      state.summaryOpen = true;
      if (state.homeEditMode) window.toggleHomeEditMode(false);
      if (state.modalOpen) closeModal();
      if (state.worldMapOpen) window.closeWorldMap();
      if (state.activeDlgNpc) closeDialogue();
      const cal = getCalendarInfo();
      pendingNextWeather = Math.random() < 0.25 ? "rainy" : "sunny";
      const nextDayNum = state.day + 1;
      const nextDayOfSeason = ((nextDayNum - 1) % 28) + 1;
      const nextFest = FESTIVALS[nextDayOfSeason];
      const nextBdays = GAME_DATA.characters.characters.filter(c => NPC_BIRTHDAYS[c.id] === nextDayOfSeason).map(c => c.name_th);

      document.getElementById("sumHeader").textContent = `🌙 สรุปผลจบวันที่ ${cal.dayOfSeason} (${cal.weekday} • ${cal.season.name_th})`;
      const spouseNote = state.spouseId ? `คุณและ ${CHAR_BY_ID[state.spouseId]?.name_th} หลับฝันดีเคียงข้างกันใน ${state.cottageName} 💒` : `คุณเอนตัวลงนอนอย่างอบอุ่นใน ${state.cottageName}...`;
      document.getElementById("sumSubtitle").textContent = spouseNote;
      document.getElementById("sumGrid").innerHTML = `
        <div class="sum-cell">🪙 รายได้วันนี้<br/><span style="font-size:17px;color:#b45309;">+${state.dailyLog.goldEarned} G</span></div>
        <div class="sum-cell">❤️ แต้มความสัมพันธ์ที่เพิ่ม<br/><span style="font-size:17px;color:#be185d;">+${state.dailyLog.heartsGained} แต้ม</span></div>
        <div class="sum-cell">✨ สเตตัสชีวิตที่ฝึกได้<br/><span style="font-size:17px;color:#1d4ed8;">+${state.dailyLog.statXpGained} XP</span></div>
        <div class="sum-cell">🎣 ของป่า/แร่ & คราฟต์<br/><span style="font-size:17px;color:#15803d;">${state.dailyLog.itemsFound} ชิ้น • 🍳 ${state.dailyLog.craftsMade}</span></div>
      `;
      let fc = `🔮 พยากรณ์วันพรุ่งนี้ (วันที่ ${nextDayOfSeason}): ${pendingNextWeather === "rainy" ? "🌧️ ฝนตกโปรยปราย" : "☀️ แดดสดใสตลอดวัน"}`;
      if (nextFest) fc += ` • 🎉 พรุ่งนี้มี ${nextFest.name_th}!`;
      if (nextBdays.length) fc += ` • 🎂 วันเกิด ${nextBdays.join(", ")}!`;
      document.getElementById("sumForecast").textContent = fc;
      document.getElementById("daySummaryOverlay").style.display = "flex";
      sfx("heart");
    }

    function finishNextMorning() {
      state.summaryOpen = false;
      document.getElementById("daySummaryOverlay").style.display = "none";
      state.day++;
      state.timeMin = 6 * 60;
      state.stamina = getMaxStamina();
      state.weather = pendingNextWeather;
      state.pet.pettedToday = false;
      state.dailyLog = { goldEarned: 0, heartsGained: 0, statXpGained: 0, itemsFound: 0, craftsMade: 0 };
      Object.values(state.relations).forEach(r => { r.talkedToday = false; r.giftedToday = false; });
      state.workedToday = {};
      spawnDailyForage();
      deliverDailyMail();
      syncNpcSchedules();
      const morningBonus = {};
      const countedDecor = {};
      (state.decorPlaced || []).forEach(p => {
        if (countedDecor[p.id]) return;
        countedDecor[p.id] = true;
        const d = DECOR_BY_ID[p.id];
        if (d && d.stat) morningBonus[d.stat] = (morningBonus[d.stat] || 0) + 5;
      });
      if (Object.keys(state.partners).length > 0) morningBonus.charm = (morningBonus.charm || 0) + 5;
      if (state.spouseId) {
        morningBonus.charm = (morningBonus.charm || 0) + 8;
        morningBonus.courage = (morningBonus.courage || 0) + 5;
      }
      const decorStr = addStatXp(morningBonus);
      const cal = getCalendarInfo();
      saveGame(true);
      showToast(`🌅 เช้า${cal.weekday} วันที่ ${cal.dayOfSeason} ${cal.season.name_th}! พลังงานเต็ม ${state.stamina}${decorStr ? " • โบนัสบ้าน & คู่ชีวิต: " + decorStr : ""}`);
    }
    document.getElementById("btnNextDay").addEventListener("click", finishNextMorning);

    function advanceHours(hrs) {
      state.timeMin += hrs * 60;
      if (state.timeMin >= 24 * 60) triggerEndOfDaySummary();
      else syncNpcSchedules();
    }

    function getUnlockedEventForNpc(cid) {
      const h = getHearts(cid);
      return GAME_DATA.events.heart_events.find(ev => {
        if (ev.character_id !== cid || state.playedEvents[ev.id]) return false;
        if (h < ev.hearts_required) return false;
        if (ev.stat_gate) {
          for (const [sk, reqLv] of Object.entries(ev.stat_gate)) {
            if (getStatLevelInfo(sk).level < reqLv) return false;
          }
        }
        return true;
      });
    }

    // =========================================================================
    // SYSTEM 5: ANCIENT RUINS RAYCASTING LIGHT-BEAM PUZZLE SOLVER!
    // =========================================================================
    const DIR_DELTAS = [[0, -1], [-1, 0], [0, 1], [1, 0]]; // 0=UP, 1=LEFT, 2=DOWN, 3=RIGHT
    const MIRROR_REFLECT = {
      0: { 3: [0], 0: [3], 1: [2], 2: [1] }, // '/' mirror
      1: { 3: [2], 2: [3], 1: [0], 0: [1] }, // '\' mirror
      2: { 0: [1, 3], 2: [1, 3], 1: [0, 2], 3: [0, 2] } // '✦' perpendicular splitter
    };

    function computeRuinsBeams(floorId) {
      const fl = RUINS_FLOORS[floorId];
      if (!fl) return { segments: [], litReceptors: 0, totalReceptors: 0 };
      const rState = state.ruins[floorId];
      const segments = [];
      const litSet = new Set();
      const visited = new Set();
      const queue = fl.emitters.map(e => ({ x: e.x, y: e.y, dir: e.dir, color: e.color, depth: 0 }));

      while (queue.length > 0) {
        const ray = queue.shift();
        if (ray.depth > 24) continue;
        const [dx, dy] = DIR_DELTAS[ray.dir];
        let cx = ray.x, cy = ray.y;
        let steps = 0;
        while (steps < 30) {
          steps++;
          const nx = cx + dx, ny = cy + dy;
          if (nx < 1 || ny < 2 || nx >= fl.w - 1 || ny >= fl.h - 1) {
            segments.push({ x1: ray.x, y1: ray.y, x2: nx, y2: ny, color: ray.color });
            break;
          }
          // Check solid stone block
          if (fl.blocks.some(b => b.x === nx && b.y === ny)) {
            segments.push({ x1: ray.x, y1: ray.y, x2: nx, y2: ny, color: ray.color });
            break;
          }
          // Check receptor
          const recIdx = fl.receptors.findIndex(r => r.x === nx && r.y === ny);
          if (recIdx >= 0) {
            litSet.add(recIdx);
            segments.push({ x1: ray.x, y1: ray.y, x2: nx, y2: ny, color: ray.color });
            break;
          }
          // Check prism pillar
          const pIdx = fl.pillars.findIndex(p => p.x === nx && p.y === ny);
          if (pIdx >= 0) {
            segments.push({ x1: ray.x, y1: ray.y, x2: nx, y2: ny, color: ray.color });
            const mType = rState.pillars[pIdx] ?? fl.pillars[pIdx].init;
            const nextDirs = (MIRROR_REFLECT[mType] && MIRROR_REFLECT[mType][ray.dir]) || [];
            nextDirs.forEach(nd => {
              const vKey = `${nx},${ny},${nd}`;
              if (!visited.has(vKey)) {
                visited.add(vKey);
                queue.push({ x: nx, y: ny, dir: nd, color: ray.color, depth: ray.depth + 1 });
              }
            });
            break;
          }
          cx = nx; cy = ny;
        }
      }

      const allLit = litSet.size === fl.receptors.length && fl.receptors.length > 0;
      if (allLit && !rState.solved) {
        rState.solved = true;
        sfx("quest");
        addStatXp({ wisdom: 15, courage: 10 });
        spawnParticles(state.player.x, state.player.y - 20, "#fde047", 30);
        spawnFloatText("🔦✨ ปลดผนึกเสาแสงสำเร็จ!!", state.player.x, state.player.y - 46, "#fde047");
        checkAchievements(); updateStoryBadge(); saveGame(true);
        showToast(`🎉 ปลดผนึกเสาแสง "${fl.name}" สำเร็จ! หีบสมบัติบรรพกาลและบันไดชั้นถัดไปเปิดออกแล้ว!`);
      }
      return { segments, litSet, litReceptors: litSet.size, totalReceptors: fl.receptors.length };
    }

    window.resetRuinsFloor = () => {
      const fl = RUINS_FLOORS[state.scene];
      if (!fl) return;
      state.ruins[fl.id].pillars = fl.pillars.map(p => p.init);
      sfx("beam");
      showToast("↺ รีเซ็ตมุมเสาปริซึมในห้องนี้กลับค่าเริ่มต้นแล้ว!");
    };

    // =========================================================================
    // SYSTEM 4: INTERACTIVE GRID FURNITURE PLACEMENT ENGINE ([H] & [R])!
    // =========================================================================
    function isHomeScene(sc = state.scene) {
      return sc === "farmhouse" || sc === "farmhouse_upstairs";
    }
    window.rotateSelectedDecor = () => {
      state.selectedDecorRot = (state.selectedDecorRot + 1) % 2;
      sfx("talk");
      renderHomeEditCatalog();
    };
    window.selectDecorForPlacement = (did) => {
      state.selectedDecorId = did;
      state.selectedDecorRot = 0;
      sfx("talk");
      renderHomeEditCatalog();
    };
    function renderHomeEditCatalog() {
      const strip = document.getElementById("homeEditCatalog");
      if (!strip) return;
      const ownedIds = HOME_DECOR.filter(d => state.decorOwned[d.id]);
      if (!ownedIds.length) {
        strip.innerHTML = `<span style="font-size:11.5px;font-weight:700;color:#7c2d12;">ยังไม่มีเฟอร์นิเจอร์ในคลัง — กดปุ่ม '🛒 ซื้อเพิ่ม/ขยายชั้น 2' เพื่อช้อปของแต่งบ้านได้เลย!</span>`;
        return;
      }
      strip.innerHTML = ownedIds.map(d => {
        const placedObj = (state.decorPlaced || []).find(p => p.id === d.id);
        const isSel = state.selectedDecorId === d.id;
        const w = (isSel && state.selectedDecorRot === 1) ? d.h : d.w;
        const h = (isSel && state.selectedDecorRot === 1) ? d.w : d.h;
        return `<button class="sd-btn ${isSel ? 'active' : (placedObj ? 'green' : '')}" style="white-space:nowrap;font-size:11px;" onclick="window.selectDecorForPlacement('${d.id}')">
          ${d.icon} ${d.name_th} (${w}×${h}) ${placedObj ? `[วางที่ ${placedObj.scene === 'farmhouse_upstairs' ? 'ชั้น2' : 'ชั้น1'}]` : '[ในคลัง]'}
        </button>`;
      }).join("");
    }
    window.toggleHomeEditMode = (force) => {
      if (!isHomeScene()) {
        showToast("🏡 ต้องเข้าไปในบ้านพักชั้น 1 หรือชั้น 2 ก่อนถึงจะจัดวางเฟอร์นิเจอร์บนตารางได้!");
        return;
      }
      state.homeEditMode = typeof force === "boolean" ? force : !state.homeEditMode;
      const bar = document.getElementById("homeEditBar");
      if (state.homeEditMode) {
        if (state.modalOpen) closeModal();
        if (state.activeDlgNpc) closeDialogue();
        const firstOwned = HOME_DECOR.find(d => state.decorOwned[d.id]);
        if (!state.selectedDecorId && firstOwned) state.selectedDecorId = firstOwned.id;
        renderHomeEditCatalog();
        bar.style.display = "block";
        sfx("sparkle");
        showToast("🛋️ เข้าสู่โหมดวางเฟอร์นิเจอร์บนตาราง! เลื่อนเมาส์เลือกช่องแล้วคลิกซ้ายเพื่อวางได้เลย");
      } else {
        bar.style.display = "none";
        saveGame(true);
      }
    };

    function canPlaceDecorAt(did, sc, tx, ty, w, h) {
      const rm = INDOORS[sc];
      if (!rm) return false;
      if (tx < 1 || ty < 2 || tx + w > rm.w - 1 || ty + h > rm.h - 1) return false;
      // Keep exit & stairs clear!
      if (tx <= rm.exitX && rm.exitX < tx + w && ty <= rm.exitY - 1 && rm.exitY >= ty) return false;
      if (rm.stairsUp && tx <= rm.stairsUp.x + 1 && rm.stairsUp.x - 1 < tx + w && ty <= rm.stairsUp.y + 1 && rm.stairsUp.y < ty + h) return false;
      // Check static room furniture
      for (const f of rm.furniture) {
        if (tx < f.x + f.w && tx + w > f.x && ty < f.y + f.h && ty + h > f.y) return false;
      }
      // Check other placed custom furniture (allow rugs underneath non-rugs or vice-versa? Keep clean 1-per-tile unless same id being moved!)
      for (const p of (state.decorPlaced || [])) {
        if (p.scene !== sc || p.id === did) continue;
        if (tx < p.x + p.w && tx + w > p.x && ty < p.y + p.h && ty + h > p.y) return false;
      }
      return true;
    }

    function handleHomeEditClick(wx, wy, rightClick = false) {
      const tx = Math.floor(wx / TILE), ty = Math.floor(wy / TILE);
      // Right-click removes any placed item under cursor back to storage!
      const hitIdx = (state.decorPlaced || []).findIndex(p => p.scene === state.scene && tx >= p.x && tx < p.x + p.w && ty >= p.y && ty < p.y + p.h);
      if (rightClick) {
        if (hitIdx >= 0) {
          const rem = state.decorPlaced.splice(hitIdx, 1)[0];
          sfx("door");
          renderHomeEditCatalog(); renderSocialStatsHud(); saveGame(true);
          showToast(`📦 เก็บ "${DECOR_BY_ID[rem.id]?.name_th}" เข้าคลังเฟอร์นิเจอร์แล้ว`);
        }
        return;
      }
      if (!state.selectedDecorId && hitIdx >= 0) {
        state.selectedDecorId = state.decorPlaced[hitIdx].id;
        renderHomeEditCatalog();
        return;
      }
      const d = DECOR_BY_ID[state.selectedDecorId];
      if (!d || !state.decorOwned[d.id]) return;
      const w = state.selectedDecorRot === 1 ? d.h : d.w;
      const h = state.selectedDecorRot === 1 ? d.w : d.h;
      if (!canPlaceDecorAt(d.id, state.scene, tx, ty, w, h)) {
        sfx("miss");
        showToast("⚠️ ช่องนี้ติดผนัง ทางเดิน หรือทับเฟอร์นิเจอร์ชิ้นอื่น ลองขยับไปช่องว่างนะ!");
        return;
      }
      // Remove previous placement of this item (supports moving across Floor 1 & Floor 2!)
      state.decorPlaced = (state.decorPlaced || []).filter(p => p.id !== d.id);
      state.decorPlaced.push({ id: d.id, scene: state.scene, x: tx, y: ty, w, h });
      sfx("build");
      spawnParticles((tx + w / 2) * TILE, (ty + h / 2) * TILE, "#fde047", 14);
      renderHomeEditCatalog(); renderSocialStatsHud(); checkAchievements(); saveGame(true);
      showToast(`🛋️ วาง "${d.icon} ${d.name_th}" ที่ช่อง (${tx}, ${ty}) เรียบร้อย!`);
    }

    // =========================================================================
    // 8. CANVAS, PROCEDURAL TILESET & STARDEW WORLD MAP ([M])
    // =========================================================================
    const canvas = document.getElementById("gameCanvas");
    const ctx = canvas.getContext("2d");
    const wmCanvas = document.getElementById("worldMapCanvas");
    const wmCtx = wmCanvas.getContext("2d");

    const TILE_CACHE = {};
    function makeOffscreen(w, h) {
      const c = document.createElement("canvas"); c.width = w; c.height = h; return c;
    }
    function buildTileSetCache() {
      SEASONS.forEach(s => {
        [0, 1].forEach(v => {
          const c = makeOffscreen(TILE, TILE), g = c.getContext("2d");
          g.fillStyle = v === 0 ? s.grassA : s.grassB; g.fillRect(0, 0, TILE, TILE);
          g.fillStyle = s.dark;
          for (let i = 0; i < 6; i++) {
            const bx = (i * 11 + v * 5) % 28 + 2, by = (i * 7 + v * 9) % 26 + 3;
            g.fillRect(bx, by, 2, 3); g.fillRect(bx + 2, by + 1, 2, 2);
          }
          g.fillStyle = s.light;
          for (let i = 0; i < 4; i++) {
            const bx = (i * 13 + v * 7) % 28 + 2, by = (i * 9 + v * 4) % 26 + 2;
            g.fillRect(bx, by, 2, 2);
          }
          TILE_CACHE[`grass_${s.id}_${v}`] = c;
        });
        const cf = makeOffscreen(TILE, TILE), g = cf.getContext("2d");
        g.drawImage(TILE_CACHE[`grass_${s.id}_0`], 0, 0);
        [[6,8,"#fef08a","#fff"],[20,16,"#f472b6","#fce7f3"],[11,23,"#93c5fd","#fff"]].forEach(([fx,fy,c1,c2]) => {
          g.fillStyle = "#166534"; g.fillRect(fx+1, fy+3, 2, 4);
          g.fillStyle = c1; g.fillRect(fx-1, fy, 6, 4); g.fillRect(fx, fy-1, 4, 6);
          g.fillStyle = c2; g.fillRect(fx+1, fy+1, 2, 2);
        });
        TILE_CACHE[`flower_${s.id}`] = cf;
      });
      const cs = makeOffscreen(TILE, TILE);
      {
        const g = cs.getContext("2d");
        g.fillStyle = "#9c876c"; g.fillRect(0, 0, TILE, TILE);
        [[1,1,14,13,"#dfd1b4"],[17,1,14,13,"#d5c5a3"],[1,16,10,15,"#d2c09d"],[13,16,18,15,"#e3d6bc"]].forEach(([sx,sy,sw,sh,col]) => {
          g.fillStyle = col; g.fillRect(sx, sy, sw, sh);
          g.fillStyle = "rgba(255,255,255,0.35)"; g.fillRect(sx, sy, sw, 2);
          g.fillStyle = "rgba(68,48,28,0.28)"; g.fillRect(sx, sy+sh-2, sw, 2);
        });
        TILE_CACHE.stone = cs;
      }
      const cd = makeOffscreen(TILE, TILE);
      {
        const g = cd.getContext("2d");
        g.fillStyle = "#c99e67"; g.fillRect(0, 0, TILE, TILE);
        g.fillStyle = "#b58750"; [[4,6,4,3],[18,4,5,3],[10,20,6,3],[23,22,4,3]].forEach(([x,y,w,h]) => g.fillRect(x,y,w,h));
        g.fillStyle = "#e0bb87"; [[12,10,3,2],[25,13,3,2],[5,25,3,2]].forEach(([x,y,w,h]) => g.fillRect(x,y,w,h));
        TILE_CACHE.dirt = cd;
      }
      const cb = makeOffscreen(TILE, TILE);
      {
        const g = cb.getContext("2d");
        g.fillStyle = "#6b3814"; g.fillRect(0, 0, TILE, TILE);
        [2, 10, 18, 26].forEach((py, idx) => {
          g.fillStyle = idx % 2 === 0 ? "#b4682b" : "#a35b23"; g.fillRect(1, py, TILE - 2, 6);
          g.fillStyle = "#d99250"; g.fillRect(1, py, TILE - 2, 1);
        });
        TILE_CACHE.bridge = cb;
      }
      const cfor = makeOffscreen(TILE, TILE);
      {
        const g = cfor.getContext("2d");
        g.fillStyle = "#355e2c"; g.fillRect(0, 0, TILE, TILE);
        g.fillStyle = "#294b21"; g.fillRect(4,5,6,4); g.fillRect(18,16,8,5);
        g.fillStyle = "#487c3c"; g.fillRect(12,8,4,3); g.fillRect(6,22,5,3);
        TILE_CACHE.forest = cfor;
      }
    }
    buildTileSetCache();

    const MAP_LANDMARKS = [
      { id: "lm_square", name: "🌳 จัตุรัสต้นไม้โลก & แท่นพลังแปดเผ่า", desc: "ศูนย์กลางหุบเขา แท่นต้นไม้โลก และกระดานเควสต์", tx: 42, ty: 29, rx: 4, warp: [42, 31], icon: "🌳" },
      { id: "lm_ruins",  name: "🔦 ประตูโบราณสถานใต้รากไม้โลก (B1–B3)", desc: "ดันเจี้ยนลับ 3 ชั้น ปริศนาเสาแสงสะท้อนปริซึม & หีบสมบัติบรรพกาล!", tx: 39, ty: 27, rx: 4, warp: [39, 28], icon: "🔦" },
      { id: "lm_lake",   name: "🎣 ทะเลสาบมุกศักดิ์สิทธิ์", desc: "จุดตกปลา Stardew และชมวิวริมน้ำ", tx: 42, ty: 52, rx: 7, warp: [42, 46], icon: "🎣" },
      { id: "lm_forest", name: "🌿 ป่าพฤกษาตะวันตก", desc: "แหล่งเก็บสมุนไพรใกล้กระท่อมลิเลียน", tx: 18, ty: 44, rx: 5, warp: [21, 41], icon: "🌿" },
      { id: "lm_east",   name: "⚙️ ลานช่างและสะพานตะวันออก", desc: "เส้นทางสู่โรงตีเหล็กศิลาเพลิง", tx: 69, ty: 32, rx: 5, warp: [68, 29], icon: "⚙️" }
    ];
    let wmHoverTarget = null, wmShowNpcs = true, wmShowForage = true;

    function mapTileToWm(tx, ty) {
      const padX = 24, padY = 20, drawW = wmCanvas.width - padX * 2, drawH = wmCanvas.height - padY * 2;
      return { x: padX + (tx / MAP_W) * drawW, y: padY + (ty / MAP_H) * drawH, sx: drawW / MAP_W, sy: drawH / MAP_H };
    }
    function getWmPins() {
      const pins = [];
      BUILDINGS.forEach(b => {
        const pt = mapTileToWm(b.x + b.w / 2, b.y + b.h / 2);
        const insideNpcs = NPCS.filter(n => n.scene === b.interiorId || (b.interiorId === "farmhouse" && n.scene === "farmhouse_upstairs")).map(n => n.name.split(" ")[0]);
        pins.push({
          kind: "building", id: b.interiorId, name: b.name, x: pt.x, y: pt.y, r: 22, warp: [b.doorX, b.doorY + 1],
          info: `🏠 ${b.name} ${insideNpcs.length ? `• อยู่ด้านใน: ${insideNpcs.join(", ")}` : ""} — คลิกเพื่อเดินวาร์ปไปหน้าประตู!`
        });
      });
      MAP_LANDMARKS.forEach(lm => {
        const pt = mapTileToWm(lm.tx, lm.ty);
        pins.push({ kind: "landmark", id: lm.id, name: lm.name, x: pt.x, y: pt.y, r: 20, warp: lm.warp, info: `${lm.name} — ${lm.desc} (คลิกเพื่อวาร์ป!)` });
      });
      LANDMARKS.forEach(lm => {
        const pt = mapTileToWm(lm.tx + lm.w / 2, lm.ty + lm.h / 2);
        const built = !!state.landmarksBuilt[lm.id];
        pins.push({
          kind: "town_lm", id: lm.id, name: `${lm.icon} ${lm.name_th}`, x: pt.x, y: pt.y, r: 22,
          warp: [Math.floor(lm.interactX), Math.floor(lm.interactY)],
          info: built ? `${lm.icon} ${lm.name_th} (✨ บูรณะแล้ว!) — ${lm.ability_th}` : `🚧 พื้นที่บูรณะ: ${lm.icon} ${lm.name_th} — ${lm.summary_th}`
        });
      });
      if (wmShowNpcs) {
        const indoorSlots = {};
        NPCS.forEach(n => {
          let tx, ty;
          if (n.scene === "outdoor") { tx = n.px / TILE; ty = n.py / TILE; }
          else {
            const targetBId = n.scene === "farmhouse_upstairs" ? "farmhouse" : n.scene;
            const b = BUILDINGS.find(x => x.interiorId === targetBId);
            const slot = indoorSlots[targetBId] || 0; indoorSlots[targetBId] = slot + 1;
            tx = (b ? b.x + b.w / 2 : 42) + (slot - 0.5) * 1.6; ty = (b ? b.y + b.h + 1.1 : 30);
          }
          const pt = mapTileToWm(tx, ty), ch = CHAR_BY_ID[n.id], h = getHearts(n.id);
          pins.push({
            kind: "npc", id: n.id, npc: n, name: ch ? ch.name_th : n.name, x: pt.x, y: pt.y, r: 12,
            info: `👤 ${ch ? ch.name_th : n.name} (${"❤️".repeat(Math.min(5, h))}${h>5?`+${h-5}`:""}) • 📍 ${SCENE_NAMES_TH[n.scene] || n.scene} — ${n.activity} (คลิกนำทาง 🧭)`
          });
        });
      }
      return pins;
    }

    function renderStardewWorldMap(now) {
      if (!state.worldMapOpen) return;
      const w = wmCanvas.width, h = wmCanvas.height, cal = getCalendarInfo();
      const padX = 24, padY = 20, drawW = w - padX * 2, drawH = h - padY * 2;
      const tw = drawW / MAP_W, th = drawH / MAP_H;
      wmCtx.fillStyle = "#e8cf9b"; wmCtx.fillRect(0, 0, w, h);
      wmCtx.fillStyle = "#5b2c0d"; wmCtx.fillRect(padX - 4, padY - 4, drawW + 8, drawH + 8);
      for (let y = 0; y < MAP_H; y++) {
        for (let x = 0; x < MAP_W; x++) {
          const t = mapGrid[y][x];
          let col = cal.season.grassA;
          if (t === 0 || t === 5 || t === 6) col = (x + y) % 2 === 0 ? cal.season.grassA : cal.season.grassB;
          else if (t === 7) col = "#79b859";
          else if (t === 8) col = (x + y) % 2 === 0 ? "#2d5a27" : "#254c20";
          else if (t === 1) col = "#e2cfa8";
          else if (t === 2) col = "#c99a5b";
          else if (t === 3) col = ((x + y + Math.floor(now / 450)) % 3 === 0) ? "#3b82f6" : "#2563eb";
          else if (t === 4) col = "#9a5520";
          wmCtx.fillStyle = col; wmCtx.fillRect(padX + x * tw, padY + y * th, Math.ceil(tw), Math.ceil(th));
        }
      }
      TREES.forEach(tr => {
        const pt = mapTileToWm(tr.x + 0.5, tr.y + 0.5);
        wmCtx.fillStyle = "rgba(22, 68, 28, 0.55)"; wmCtx.beginPath(); wmCtx.arc(pt.x, pt.y, 4.2, 0, Math.PI * 2); wmCtx.fill();
      });
      const wt = mapTileToWm(42, 26.5);
      wmCtx.fillStyle = state.chroniclesDone.main_ch5 ? "rgba(253, 224, 71, 0.58)" : "rgba(250, 204, 21, 0.34)";
      wmCtx.beginPath(); wmCtx.arc(wt.x, wt.y, 26 + Math.sin(now / 300) * 3, 0, Math.PI * 2); wmCtx.fill();
      wmCtx.fillStyle = "#5c3317"; wmCtx.fillRect(wt.x - 5, wt.y, 10, 18);
      wmCtx.fillStyle = state.chroniclesDone.main_ch5 ? "#eab308" : "#15803d"; wmCtx.beginPath(); wmCtx.arc(wt.x, wt.y - 4, 18, 0, Math.PI * 2); wmCtx.fill();

      // Ancient Ruins Portal Pin
      const rp = mapTileToWm(RUINS_ENTRANCE.tx, RUINS_ENTRANCE.ty);
      wmCtx.fillStyle = "#38bdf8"; wmCtx.beginPath(); wmCtx.arc(rp.x, rp.y, 8 + Math.sin(now / 220) * 2, 0, Math.PI * 2); wmCtx.fill();
      wmCtx.strokeStyle = "#1e1b4b"; wmCtx.lineWidth = 2; wmCtx.stroke();
      wmCtx.font = "11px sans-serif"; wmCtx.textAlign = "center"; wmCtx.fillText("🔦", rp.x, rp.y + 4);

      BUILDINGS.forEach(b => {
        const tl = mapTileToWm(b.x, b.y), bw = b.w * tw, bh = b.h * th;
        const isHov = wmHoverTarget && wmHoverTarget.kind === "building" && wmHoverTarget.id === b.interiorId;
        wmCtx.fillStyle = "rgba(0,0,0,0.3)"; wmCtx.fillRect(tl.x + 3, tl.y + 4, bw, bh);
        wmCtx.fillStyle = b.wallColor || "#f3dec0"; wmCtx.fillRect(tl.x, tl.y + bh * 0.4, bw, bh * 0.6);
        wmCtx.fillStyle = isHov ? "#facc15" : (b.roofColor || "#b45309"); wmCtx.fillRect(tl.x - 3, tl.y - 2, bw + 6, bh * 0.55);
        wmCtx.strokeStyle = isHov ? "#ffffff" : "#2b1205"; wmCtx.lineWidth = isHov ? 2.5 : 1.5; wmCtx.strokeRect(tl.x - 3, tl.y - 2, bw + 6, bh + 2);
        const lbl = b.id === "farmhouse" ? `🏡 ${state.cottageName.slice(0,12)}` : (b.sign || b.name.slice(0, 14));
        wmCtx.font = "bold 10.5px 'Noto Sans Thai', sans-serif"; wmCtx.textAlign = "center";
        const lw = Math.max(76, lbl.length * 6.5);
        wmCtx.fillStyle = isHov ? "#fef08a" : "rgba(251, 240, 217, 0.94)";
        wmCtx.fillRect(tl.x + bw / 2 - lw / 2, tl.y - 19, lw, 16);
        wmCtx.strokeStyle = "#6b3814"; wmCtx.lineWidth = 1.2; wmCtx.strokeRect(tl.x + bw / 2 - lw / 2, tl.y - 19, lw, 16);
        wmCtx.fillStyle = "#3f1d0b"; wmCtx.fillText(lbl, tl.x + bw / 2, tl.y - 7);
      });

      LANDMARKS.forEach(lm => {
        const tl = mapTileToWm(lm.tx, lm.ty), lw = lm.w * tw, lh = lm.h * th;
        const cx = tl.x + lw / 2, cy = tl.y + lh / 2;
        const built = !!state.landmarksBuilt[lm.id];
        const isHov = wmHoverTarget && wmHoverTarget.kind === "town_lm" && wmHoverTarget.id === lm.id;
        wmCtx.fillStyle = built ? lm.color : "rgba(120, 113, 108, 0.85)";
        wmCtx.fillRect(tl.x, tl.y, lw, lh);
        wmCtx.strokeStyle = isHov ? "#ffffff" : (built ? lm.accent : "#fef08a");
        wmCtx.lineWidth = isHov ? 2.5 : 1.8; wmCtx.strokeRect(tl.x, tl.y, lw, lh);
        wmCtx.font = "13px sans-serif"; wmCtx.textAlign = "center"; wmCtx.fillText(built ? lm.icon : "🚧", cx, cy + 5);
      });

      if (wmShowForage) {
        forageSpots.forEach(fs => {
          if (fs.collected) return;
          const pt = mapTileToWm(fs.tx + 0.5, fs.ty + 0.5), p = 3.5 + Math.sin(now / 200 + fs.tx) * 1.5;
          wmCtx.fillStyle = "#34d399"; wmCtx.beginPath(); wmCtx.arc(pt.x, pt.y, p + 2, 0, Math.PI * 2); wmCtx.fill();
          wmCtx.fillStyle = "#fef08a"; wmCtx.beginPath(); wmCtx.arc(pt.x, pt.y, 3, 0, Math.PI * 2); wmCtx.fill();
        });
      }
      const pins = getWmPins();
      pins.filter(p => p.kind === "npc").forEach(pin => {
        const isHov = wmHoverTarget && wmHoverTarget.kind === "npc" && wmHoverTarget.id === pin.id;
        wmCtx.fillStyle = state.spouseId === pin.id ? "#f43f5e" : (state.compassNpcId === pin.id ? "#ec4899" : (isHov ? "#ffffff" : "#facc15"));
        wmCtx.beginPath(); wmCtx.arc(pin.x, pin.y, isHov ? 8 : 6.5, 0, Math.PI * 2); wmCtx.fill();
        wmCtx.strokeStyle = "#3f1d0b"; wmCtx.lineWidth = 1.8; wmCtx.stroke();
        wmCtx.fillStyle = "#2b1608"; wmCtx.font = "bold 9px 'Noto Sans Thai', sans-serif"; wmCtx.textAlign = "center";
        wmCtx.fillText(pin.name.slice(0, 1), pin.x, pin.y + 3);
      });

      const ptx = state.scene === "outdoor" ? state.player.x / TILE : state.returnPos.x / TILE;
      const pty = state.scene === "outdoor" ? state.player.y / TILE : state.returnPos.y / TILE;
      const pp = mapTileToWm(ptx, pty), pr = 9 + Math.sin(now / 180) * 3;
      wmCtx.strokeStyle = "#ef4444"; wmCtx.lineWidth = 3; wmCtx.beginPath(); wmCtx.arc(pp.x, pp.y, pr, 0, Math.PI * 2); wmCtx.stroke();
      wmCtx.fillStyle = "#ef4444"; wmCtx.beginPath(); wmCtx.arc(pp.x, pp.y, 6.5, 0, Math.PI * 2); wmCtx.fill();
    }

    window.openWorldMap = () => {
      if (state.miniGameOpen || state.summaryOpen) return;
      if (state.homeEditMode) window.toggleHomeEditMode(false);
      if (state.modalOpen) closeModal();
      if (state.activeDlgNpc) closeDialogue();
      state.worldMapOpen = true;
      const cal = getCalendarInfo();
      document.getElementById("wmSeasonBadge").textContent = `${cal.weekday} วันที่ ${cal.dayOfSeason} • ${cal.season.name_th}`;
      document.getElementById("worldMapOverlay").style.display = "flex";
      sfx("talk");
      renderStardewWorldMap(performance.now());
    };
    window.closeWorldMap = () => {
      state.worldMapOpen = false; wmHoverTarget = null;
      document.getElementById("worldMapOverlay").style.display = "none";
    };
    wmCanvas.addEventListener("mousemove", (e) => {
      if (!state.worldMapOpen) return;
      const rect = wmCanvas.getBoundingClientRect();
      const mx = (e.clientX - rect.left) * (wmCanvas.width / Math.max(1, rect.width));
      const my = (e.clientY - rect.top) * (wmCanvas.height / Math.max(1, rect.height));
      let hit = null, bestD = 999;
      for (const p of getWmPins()) {
        const d = Math.hypot(p.x - mx, p.y - my);
        const bonus = p.kind === "npc" ? 0 : 6;
        if (d <= p.r && (d + bonus) < bestD) { bestD = d + bonus; hit = p; }
      }
      wmHoverTarget = hit;
      document.getElementById("wmHoverText").textContent = hit
        ? hit.info : "🖱️ เลื่อนเมาส์ชี้ดูชื่อสถานที่/ชาวเมือง • คลิกอาคาร แลนด์มาร์ก หรือโบราณสถานเพื่อเดินทางไปได้ทันที!";
    });
    wmCanvas.addEventListener("click", () => {
      if (!state.worldMapOpen || !wmHoverTarget) return;
      if (wmHoverTarget.kind === "npc") { const cid = wmHoverTarget.id; window.closeWorldMap(); window.trackNpc(cid); }
      else if (wmHoverTarget.warp) {
        const [tx, ty] = wmHoverTarget.warp, name = wmHoverTarget.name;
        window.closeWorldMap(); sfx("door"); transitionScene("outdoor", tx, ty, false);
        showToast(`🗺️ เดินทางไปยัง ${name}!`);
      }
    });
    document.getElementById("btnOpenMap").addEventListener("click", () => window.openWorldMap());
    document.getElementById("btnCloseWorldMap").addEventListener("click", () => window.closeWorldMap());
    document.getElementById("worldMapOverlay").addEventListener("click", (e) => { if (e.target.id === "worldMapOverlay") window.closeWorldMap(); });
    document.getElementById("wmToggleNpcs").addEventListener("change", (e) => { wmShowNpcs = !!e.target.checked; });
    document.getElementById("wmToggleForage").addEventListener("change", (e) => { wmShowForage = !!e.target.checked; });

    function resize() { canvas.width = window.innerWidth; canvas.height = window.innerHeight; }
    window.addEventListener("resize", resize);
    resize();

    function showToast(msg) {
      const box = document.getElementById("toastBox");
      document.getElementById("toastText").textContent = msg;
      box.style.display = "block";
      clearTimeout(showToast._t);
      showToast._t = setTimeout(() => { box.style.display = "none"; }, 3100);
    }

    function transitionScene(targetScene, spawnTx, spawnTy, saveReturn = false) {
      if (state.fading) return;
      if (state.homeEditMode) window.toggleHomeEditMode(false);
      state.fading = true;
      const curtain = document.getElementById("fadeCurtain");
      curtain.style.opacity = "1";
      setTimeout(() => {
        if (saveReturn && state.scene === "outdoor") state.returnPos = { x: state.player.x, y: state.player.y + 18 };
        state.scene = targetScene;
        state.player.x = spawnTx * TILE + TILE / 2;
        state.player.y = spawnTy * TILE + TILE / 2;
        state.pet.x = state.player.x - 22;
        state.pet.y = state.player.y + 6;
        state.player.target = null;
        state.player.dir = targetScene === "outdoor" ? 2 : 0;
        syncBgmZone();
        curtain.style.opacity = "0";
        setTimeout(() => { state.fading = false; }, 220);
        const sName = targetScene === "outdoor" ? "🌳 กลับสู่หุบเขาต้นไม้โลก"
          : (RUINS_FLOORS[targetScene] ? RUINS_FLOORS[targetScene].name : `🚪 ${INDOORS[targetScene]?.name || targetScene}`);
        showToast(sName);
      }, 190);
    }

    function isBlocked(px, py) {
      const tx = Math.floor(px / TILE), ty = Math.floor(py / TILE);
      if (state.scene === "outdoor") {
        if (tx < 0 || ty < 0 || tx >= MAP_W || ty >= MAP_H) return true;
        return solidGrid[ty][tx] === 1;
      } else if (RUINS_FLOORS[state.scene]) {
        const fl = RUINS_FLOORS[state.scene];
        if (tx < 1 || ty < 2 || tx >= fl.w - 1 || ty >= fl.h - 1) return true;
        if (fl.blocks.some(b => b.x === tx && b.y === ty)) return true;
        if (fl.emitters.some(e => e.x === tx && e.y === ty)) return true;
        if (fl.pillars.some(p => p.x === tx && p.y === ty)) return true;
        if (fl.receptors.some(r => r.x === tx && r.y === ty)) return true;
        return false;
      } else {
        const rm = INDOORS[state.scene];
        if (tx < 1 || ty < 2 || tx >= rm.w - 1 || ty >= rm.h - 1) return true;
        for (const f of rm.furniture) {
          if (!f.passable && tx >= f.x && tx < f.x + f.w && ty >= f.y && ty < f.y + f.h) return true;
        }
        for (const p of (state.decorPlaced || [])) {
          if (p.scene !== state.scene) continue;
          const d = DECOR_BY_ID[p.id];
          if (d && d.passable) continue;
          if (tx >= p.x && tx < p.x + p.w && ty >= p.y && ty < p.y + p.h) return true;
        }
        return false;
      }
    }
    function isNearWater(px, py) {
      const tx = Math.floor(px / TILE), ty = Math.floor(py / TILE);
      for (let dy = -1; dy <= 1; dy++) {
        for (let dx = -1; dx <= 1; dx++) {
          const nx = tx + dx, ny = ty + dy;
          if (nx >= 0 && ny >= 0 && nx < MAP_W && ny < MAP_H && mapGrid[ny][nx] === 3) return true;
        }
      }
      return false;
    }

    function petCompanion() {
      const petDef = PET_TYPES[state.pet.kind] || PET_TYPES.cat;
      sfx("heart");
      spawnParticles(state.pet.x, state.pet.y - 12, "#f472b6", 12);
      if (!state.pet.pettedToday) {
        state.pet.pettedToday = true;
        state.stamina = Math.min(getMaxStamina(), state.stamina + 10);
        addStatXp({ charm: 5 });
        spawnFloatText(`${petDef.cry} +10⚡ ✨+5`, state.pet.x, state.pet.y - 26, "#f472b6");
        saveGame(true);
        showToast(`🐾 ลูบหัว ${petDef.name_th}! "${petDef.cry}" (ฟื้นพลัง +10 ⚡ & เสน่ห์ +5)`);
      } else {
        spawnFloatText(petDef.cry, state.pet.x, state.pet.y - 24, "#fde047");
        showToast(`🐾 ${petDef.name_th} ดูมีความสุขมาก! "${petDef.cry}"`);
      }
    }

    // =========================================================================
    // 9. SYSTEM 2: 6 SPECIALIZED INTERACTIVE MINIGAMES ENGINE!
    // =========================================================================
    const mgCanvas = document.getElementById("mgCanvas");
    const mgCtx = mgCanvas.getContext("2d");
    const mg = {
      active: false, kind: "forge_heat", contextMode: "job", payload: null,
      score: 0, maxScore: 6, rafId: 0, lastT: 0,
      holdDown: false, data: {}
    };

    function getJobMiniGameKind(jobId) {
      if (jobId === "job_smithy" || jobId === "job_bakery") return "forge_heat";
      if (jobId === "job_tavern" || jobId === "job_shop") return "order_rush";
      if (jobId === "job_herbalist" || jobId === "job_archives") return "rune_memory";
      if (jobId === "job_courier" || jobId === "job_patrol") return "sky_dash";
      return "forge_heat";
    }

    function closeMiniGameOverlay() {
      mg.active = false; mg.holdDown = false; state.miniGameOpen = false;
      cancelAnimationFrame(mg.rafId);
      document.getElementById("miniGameOverlay").style.display = "none";
      document.getElementById("mgCustomButtons").innerHTML = "";
    }

    function concludeMiniGame(score, maxScore) {
      const ctxMode = mg.contextMode, payload = mg.payload;
      closeMiniGameOverlay();
      if (ctxMode === "job") finishJobResult(payload, score, maxScore);
      else if (ctxMode === "fish") finishFishResult(score, maxScore);
      else if (ctxMode === "concert") finishConcertResult(score, maxScore);
    }

    function startSpecializedMiniGame(kind, contextMode, payload) {
      mg.active = true; mg.kind = kind; mg.contextMode = contextMode; mg.payload = payload;
      mg.holdDown = false; state.miniGameOpen = true;
      const btnPri = document.getElementById("btnMgPrimary");
      const btnWrap = document.getElementById("mgCustomButtons");
      const fb = document.getElementById("mgFeedback");
      btnWrap.innerHTML = "";
      btnPri.style.display = "inline-block";

      if (kind === "forge_heat") {
        // 1. Forge & Oven Heat Hammering (4 rounds)
        const isBake = payload?.id === "job_bakery";
        mg.score = 0; mg.maxScore = 8;
        mg.data = { round: 1, total: 4, pos: 0.1, dir: 1, speed: 1.25, zoneCenter: 0.52, zoneHalf: 0.14, perfHalf: 0.055, isBake, flash: 0 };
        document.getElementById("mgTitle").textContent = isBake ? "🥐 มินิเกมสายอบขนม: คุมไฟเตาอบ Elderbark!" : "⚒️ มินิเกมสายช่าง: ตีค้อนเตาหลอมศิลาเพลิง!";
        document.getElementById("mgSubtitle").textContent = "กด [Space] หรือปุ่มด้านล่าง เมื่อเข็มความร้อนเข้าสู่โซนสีทอง! (4 รอบ)";
        btnPri.textContent = isBake ? "🔥 อบแป้งตรงจังหวะ! [Space]" : "⚒️ ทุบค้อนลงทั่ง! [Space]";
        fb.textContent = "จ้องเกจความร้อนแล้วกดเลย!";
      } else if (kind === "order_rush") {
        // 2. Tavern & Shop Order Matching (5 orders, 22s)
        const pool = ["item_honey_croissant", "item_honey_ale", "item_hearty_stew", "item_roasted_coffee", "item_emerald_tea", "item_apple_pie"];
        mg.score = 0; mg.maxScore = 10;
        const pickOrder = () => ({
          npc: GAME_DATA.characters.characters[Math.floor(Math.random() * 16)],
          itemId: pool[Math.floor(Math.random() * pool.length)]
        });
        mg.data = { pool, round: 1, total: 5, timeLeft: 22.0, current: pickOrder(), pickOrder };
        document.getElementById("mgTitle").textContent = "🍺 มินิเกมสายบริการ: เสิร์ฟด่วนออเดอร์ชาวเมือง!";
        document.getElementById("mgSubtitle").textContent = "คลิกไอเทม (หรือกดปุ่ม 1–6) ให้ตรงกับออเดอร์ที่ลูกค้าสั่งให้ทันเวลา!";
        btnPri.style.display = "none";
        btnWrap.innerHTML = pool.map((iid, idx) => {
          const it = ITEM_BY_ID[iid];
          return `<button class="sd-btn green" onclick="window.mgPickOrderItem('${iid}')">[${idx+1}] ${itemIconHtml(iid, 18)}${it?.name_th.slice(0, 12)}</button>`;
        }).join("");
        fb.textContent = "เลือกเมนูเสิร์ฟให้ตรงกับภาพในบอลลูนลูกค้า!";
      } else if (kind === "rune_memory") {
        // 3. Herbalist & Archive Rune Memory Sequence (3 rounds: len 3, 4, 5)
        const glyphs = [
          { icon: "🌿", name: "ใบไม้โลก", col: "#22c55e", freq: 392 },
          { icon: "💎", name: "ผลึกวารี", col: "#38bdf8", freq: 440 },
          { icon: "🔥", name: "ศิลาเพลิง", col: "#f97316", freq: 523.3 },
          { icon: "🌙", name: "จันทรา",   col: "#c084fc", freq: 587.3 },
          { icon: "☀️", name: "สุริยัน",  col: "#facc15", freq: 659.3 },
          { icon: "🪶", name: "สายลม",    col: "#f472b6", freq: 784.0 }
        ];
        mg.score = 0; mg.maxScore = 6;
        mg.data = { glyphs, round: 1, total: 3, seq: [], inputIdx: 0, showing: true, showIdx: -1, timer: 0.5 };
        const genSeq = (len) => Array.from({ length: len }, () => Math.floor(Math.random() * 6));
        mg.data.genSeq = genSeq;
        mg.data.seq = genSeq(3);
        document.getElementById("mgTitle").textContent = "🌿 มินิเกมสายปัญญา: จดจำลำดับรูน & สมุนไพรเวท!";
        document.getElementById("mgSubtitle").textContent = "ดูลำดับสัญลักษณ์ที่สว่างขึ้น แล้วคลิกทวนลำดับ (หรือกด 1–6) ให้ถูกต้อง!";
        btnPri.style.display = "none";
        btnWrap.innerHTML = glyphs.map((g, idx) => `<button class="sd-btn" onclick="window.mgPressRune(${idx})">[${idx+1}] ${g.icon} ${g.name}</button>`).join("");
        fb.textContent = "👀 จดจำลำดับแสงรูน...";
      } else if (kind === "sky_dash") {
        // 4. Sky-Courier & Forest Reflex Catch/Dodge (14s arcade)
        mg.score = 0; mg.maxScore = 100;
        mg.data = { px: 230, timeLeft: 14.0, spawnT: 0.35, objs: [] };
        document.getElementById("mgTitle").textContent = "🪽 มินิเกมสายความกล้า: วิ่งส่งพัสดุ & หลบสิ่งกีดขวาง!";
        document.getElementById("mgSubtitle").textContent = "กด [A / D] หรือ [◀ / ▶] หรือเลื่อนเมาส์บนจอเพื่อเก็บ ✉️🌟 (+20) และหลบ 🪨 (-15)!";
        btnPri.style.display = "none";
        btnWrap.innerHTML = `
          <button class="sd-btn blue" style="padding:8px 18px;" onmousedown="window.mgMoveDash(-46)">◀ ขยับซ้าย [A]</button>
          <button class="sd-btn blue" style="padding:8px 18px;" onmousedown="window.mgMoveDash(46)">ขยับขวา [D] ▶</button>
        `;
        fb.textContent = "เก็บซองจดหมายสีทองให้ครบ 85+ แต้มเพื่อคว้า Rank S!";
      } else if (kind === "stardew_fish") {
        // 5. Authentic Stardew Tension-Bar Fishing!
        const isMerfolk = state.heroCustom.raceKey === "merfolk";
        const barH = isMerfolk ? 74 : 56;
        mg.score = 0; mg.maxScore = 100;
        mg.data = {
          fishY: 110, fishVy: 0, fishTargetY: 60, fishTimer: 0.6,
          barY: 120, barVy: 0, barH, progress: 34, timeMax: 16.0, elapsed: 0
        };
        document.getElementById("mgTitle").textContent = "🎣 ตกปลาทะเลสาบมุก (Stardew Tension Bar!)";
        document.getElementById("mgSubtitle").textContent = "กดค้าง [Space] หรือคลิกเมาส์ค้างไว้เพื่อยกแถบเขียวขึ้น ปล่อยเพื่อให้แถบลง เลี้ยงให้ตรงตัวปลา!";
        btnPri.textContent = "🎣 กดค้างเพื่อดึงเบ็ด! [Hold Space]";
        fb.textContent = isMerfolk ? "🧜 โบนัสเผ่าเงือก: แถบจับปลากว้างพิเศษ +28%!" : "เลี้ยงแถบเขียวทับตัวปลาจนหลอดขวาเต็ม 100%!";
      } else if (kind === "rhythm_stage") {
        // 6. 4-Lane Rhythm Concert ([D][F][J][K])
        const lanes = [
          { key: "d", label: "D 🎻", col: "#f43f5e", freq: 392.0 },
          { key: "f", label: "F 🪈", col: "#facc15", freq: 493.9 },
          { key: "j", label: "J 🔔", col: "#38bdf8", freq: 587.3 },
          { key: "k", label: "K ✨", col: "#a855f7", freq: 784.0 }
        ];
        const notes = Array.from({ length: 12 }, (_, i) => ({
          lane: (i * 3 + (i % 2)) % 4,
          y: -30 - i * 68,
          hit: false, missed: false
        }));
        mg.score = 0; mg.maxScore = 24;
        mg.data = { lanes, notes, speed: 135, combo: 0 };
        document.getElementById("mgTitle").textContent = "🎻 มินิเกมสายดนตรี: คอนเสิร์ตประสานเสียง 4 เลน!";
        document.getElementById("mgSubtitle").textContent = "กดปุ่ม [D] [F] [J] [K] หรือคลิกแป้นโน้ตเมื่อลูกแก้วดนตรีตกลงมาถึงเส้นสีทอง!";
        btnPri.style.display = "none";
        btnWrap.innerHTML = lanes.map((l, idx) => `<button class="sd-btn active" style="min-width:78px;padding:8px 12px;" onclick="window.mgHitLane(${idx})">${l.label}</button>`).join("");
        fb.textContent = "บรรเลงบทเพลงแห่งต้นไม้โลก!";
      }

      document.getElementById("miniGameOverlay").style.display = "flex";
      mg.lastT = performance.now();
      mg.rafId = requestAnimationFrame(stepMiniGame);
    }

    window.mgPickOrderItem = (iid) => {
      if (!mg.active || mg.kind !== "order_rush") return;
      const d = mg.data, fb = document.getElementById("mgFeedback");
      if (iid === d.current.itemId) {
        mg.score += 2; sfx("coin");
        fb.textContent = `🌟 เสิร์ฟถูกใจ ${d.current.npc.name_th}! (+2 แต้ม)`; fb.style.color = "#15803d";
      } else {
        sfx("miss");
        fb.textContent = `😅 ผิดเมนู! ลูกค้าสั่ง ${ITEM_BY_ID[d.current.itemId]?.name_th}`; fb.style.color = "#b91c1c";
      }
      if (d.round >= d.total) concludeMiniGame(mg.score, mg.maxScore);
      else { d.round++; d.current = d.pickOrder(); }
    };

    window.mgPressRune = (idx) => {
      if (!mg.active || mg.kind !== "rune_memory" || mg.data.showing) return;
      const d = mg.data, fb = document.getElementById("mgFeedback");
      playTone(d.glyphs[idx].freq, 0.14, "sine", 0.08);
      d.showIdx = idx; setTimeout(() => { if (mg.active && !d.showing) d.showIdx = -1; }, 160);
      if (d.seq[d.inputIdx] === idx) {
        d.inputIdx++;
        if (d.inputIdx >= d.seq.length) {
          mg.score += 2; sfx("sparkle");
          fb.textContent = `✨ ถอดรหัสรอบที่ ${d.round} สำเร็จ! (+2 แต้ม)`; fb.style.color = "#15803d";
          if (d.round >= d.total) { setTimeout(() => concludeMiniGame(mg.score, mg.maxScore), 260); return; }
          d.round++; d.seq = d.genSeq(2 + d.round); d.inputIdx = 0; d.showing = true; d.showIdx = -1; d.timer = 0.55;
        }
      } else {
        sfx("miss");
        fb.textContent = `💥 ลำดับคลาดเคลื่อน! ไปต่อรอบถัดไป...`; fb.style.color = "#b91c1c";
        if (d.round >= d.total) { setTimeout(() => concludeMiniGame(mg.score, mg.maxScore), 260); return; }
        d.round++; d.seq = d.genSeq(2 + d.round); d.inputIdx = 0; d.showing = true; d.showIdx = -1; d.timer = 0.55;
      }
    };

    window.mgMoveDash = (dx) => {
      if (!mg.active || mg.kind !== "sky_dash") return;
      mg.data.px = Math.max(36, Math.min(424, mg.data.px + dx));
    };

    window.mgHitLane = (laneIdx) => {
      if (!mg.active || mg.kind !== "rhythm_stage") return;
      const d = mg.data, fb = document.getElementById("mgFeedback");
      const hitLineY = 182;
      const cand = d.notes.find(n => !n.hit && !n.missed && n.lane === laneIdx && Math.abs(n.y - hitLineY) <= 36);
      if (cand) {
        cand.hit = true;
        const diff = Math.abs(cand.y - hitLineY);
        playTone(d.lanes[laneIdx].freq, 0.18, "triangle", 0.085);
        if (diff <= 16) { mg.score += 2; d.combo++; fb.textContent = `🌟 PERFECT! Combo x${d.combo}`; fb.style.color = "#ca8a04"; }
        else { mg.score += 1; d.combo++; fb.textContent = `✨ GREAT! Combo x${d.combo}`; fb.style.color = "#15803d"; }
      } else {
        d.combo = 0; sfx("miss"); fb.textContent = "😅 กดก่อนจังหวะ!"; fb.style.color = "#b91c1c";
      }
    };

    function triggerMgPrimaryHit() {
      if (!mg.active) return;
      if (mg.kind === "forge_heat") {
        const d = mg.data, fb = document.getElementById("mgFeedback");
        const dist = Math.abs(d.pos - d.zoneCenter);
        sfx("anvil"); d.flash = 1.0;
        if (dist <= d.perfHalf) { mg.score += 2; sfx("sparkle"); fb.textContent = "🔥 PERFECT HEAT!! (+2 แต้ม)"; fb.style.color = "#ca8a04"; }
        else if (dist <= d.zoneHalf) { mg.score += 1; fb.textContent = "✨ GOOD STRIKE! (+1 แต้ม)"; fb.style.color = "#15803d"; }
        else { sfx("miss"); fb.textContent = "💨 ไฟอ่อน/แรงเกินไป! (0 แต้ม)"; fb.style.color = "#b91c1c"; }
        if (d.round >= d.total) { setTimeout(() => concludeMiniGame(mg.score, mg.maxScore), 220); return; }
        d.round++; d.speed += 0.28; d.zoneCenter = 0.25 + Math.random() * 0.5;
      }
    }

    function stepMiniGame(now) {
      if (!mg.active) return;
      const dt = Math.min(0.05, (now - mg.lastT) / 1000); mg.lastT = now;
      const w = mgCanvas.width, h = mgCanvas.height;
      mgCtx.fillStyle = "#0f172a"; mgCtx.fillRect(0, 0, w, h);
      const badge = document.getElementById("mgRoundBadge");

      if (mg.kind === "forge_heat") {
        const d = mg.data;
        d.pos += d.dir * d.speed * dt;
        if (d.pos >= 0.96) { d.pos = 0.96; d.dir = -1; }
        if (d.pos <= 0.04) { d.pos = 0.04; d.dir = 1; }
        if (d.flash > 0) d.flash = Math.max(0, d.flash - dt * 4);
        badge.textContent = `รอบที่ ${d.round} / ${d.total} • คะแนน: ${mg.score} / ${mg.maxScore}`;
        // Draw furnace glow
        const grd = mgCtx.createRadialGradient(w/2, 85, 10, w/2, 85, 130);
        grd.addColorStop(0, d.isBake ? "rgba(251,191,36,0.45)" : "rgba(249,115,22,0.55)");
        grd.addColorStop(1, "rgba(15,23,42,0)");
        mgCtx.fillStyle = grd; mgCtx.fillRect(0, 0, w, h);
        mgCtx.font = "40px sans-serif"; mgCtx.textAlign = "center";
        mgCtx.fillText(d.isBake ? "🥐🔥" : "⚒️🔥", w / 2, 92);
        // Heat bar track
        const tx = 36, ty = 138, tw = w - 72, th = 36;
        mgCtx.fillStyle = "#1e293b"; mgCtx.fillRect(tx, ty, tw, th);
        mgCtx.fillStyle = "rgba(34,197,94,0.48)";
        mgCtx.fillRect(tx + (d.zoneCenter - d.zoneHalf) * tw, ty, d.zoneHalf * 2 * tw, th);
        mgCtx.fillStyle = "rgba(250,204,21,0.9)";
        mgCtx.fillRect(tx + (d.zoneCenter - d.perfHalf) * tw, ty, d.perfHalf * 2 * tw, th);
        mgCtx.strokeStyle = "#f59e0b"; mgCtx.lineWidth = 2.5; mgCtx.strokeRect(tx, ty, tw, th);
        // Needle
        const nx = tx + d.pos * tw;
        mgCtx.fillStyle = "#ffffff"; mgCtx.fillRect(nx - 4, ty - 6, 8, th + 12);
      } else if (mg.kind === "order_rush") {
        const d = mg.data;
        d.timeLeft -= dt;
        if (d.timeLeft <= 0) { concludeMiniGame(mg.score, mg.maxScore); return; }
        badge.textContent = `ออเดอร์ ${d.round}/${d.total} • ⏱️ ${d.timeLeft.toFixed(1)}s • คะแนน: ${mg.score}/${mg.maxScore}`;
        mgCtx.fillStyle = "#3f1d0b"; mgCtx.fillRect(24, 150, w - 48, 48);
        // Customer portrait + order bubble
        const pImg = SPRITES.portrait[d.current.npc.id];
        if (pImg) mgCtx.drawImage(pImg, 54, 34, 108, 108);
        mgCtx.fillStyle = "#fffbeb"; mgCtx.fillRect(184, 42, 236, 92);
        mgCtx.strokeStyle = "#92400e"; mgCtx.lineWidth = 3; mgCtx.strokeRect(184, 42, 236, 92);
        mgCtx.fillStyle = "#4c230a"; mgCtx.font = "bold 13px 'Noto Sans Thai', sans-serif"; mgCtx.textAlign = "left";
        mgCtx.fillText(`${d.current.npc.name_th} ขอสั่ง:`, 198, 66);
        const itImg = ITEM_IMAGES[d.current.itemId];
        if (itImg) mgCtx.drawImage(itImg, 198, 76, 40, 40);
        mgCtx.fillStyle = "#b45309"; mgCtx.font = "bold 15px 'Noto Sans Thai', sans-serif";
        mgCtx.fillText(ITEM_BY_ID[d.current.itemId]?.name_th || "", 248, 102);
      } else if (mg.kind === "rune_memory") {
        const d = mg.data;
        badge.textContent = `รอบที่ ${d.round}/${d.total} (ความยาว ${d.seq.length}) • คะแนน: ${mg.score}/${mg.maxScore}`;
        if (d.showing) {
          d.timer -= dt;
          if (d.timer <= 0) {
            d.inputIdx++;
            if (d.inputIdx > d.seq.length) {
              d.showing = false; d.inputIdx = 0; d.showIdx = -1;
              document.getElementById("mgFeedback").textContent = "👉 ตาคุณแล้ว! กดปุ่มรูนตามลำดับเมื่อสักครู่เลย!";
            } else {
              d.showIdx = d.seq[d.inputIdx - 1];
              playTone(d.glyphs[d.showIdx].freq, 0.22, "sine", 0.085);
              d.timer = 0.58;
            }
          }
        }
        d.glyphs.forEach((g, idx) => {
          const gx = 42 + (idx % 3) * 132, gy = 28 + Math.floor(idx / 3) * 88;
          const lit = d.showIdx === idx;
          mgCtx.fillStyle = lit ? g.col : "#1e293b";
          mgCtx.fillRect(gx, gy, 112, 72);
          mgCtx.strokeStyle = lit ? "#ffffff" : g.col;
          mgCtx.lineWidth = lit ? 4 : 2;
          mgCtx.strokeRect(gx, gy, 112, 72);
          mgCtx.font = "28px sans-serif"; mgCtx.textAlign = "center";
          mgCtx.fillText(g.icon, gx + 56, gy + 44);
          mgCtx.fillStyle = lit ? "#0f172a" : "#e2e8f0"; mgCtx.font = "bold 11px 'Noto Sans Thai', sans-serif";
          mgCtx.fillText(`[${idx+1}] ${g.name}`, gx + 56, gy + 64);
        });
      } else if (mg.kind === "sky_dash") {
        const d = mg.data;
        d.timeLeft -= dt;
        if (d.timeLeft <= 0) { concludeMiniGame(mg.score, mg.maxScore); return; }
        if (state.keys["a"] || state.keys["arrowleft"]) d.px = Math.max(30, d.px - 260 * dt);
        if (state.keys["d"] || state.keys["arrowright"]) d.px = Math.min(w - 30, d.px + 260 * dt);
        d.spawnT -= dt;
        if (d.spawnT <= 0) {
          d.spawnT = 0.36;
          const good = Math.random() < 0.7;
          d.objs.push({ x: 34 + Math.random() * (w - 68), y: -16, vy: 135 + Math.random() * 65, good });
        }
        badge.textContent = `⏱️ ${d.timeLeft.toFixed(1)}s • คะแนนสะสม: ${mg.score} (เป้า S: 85+)`;
        mgCtx.fillStyle = "#14532d"; mgCtx.fillRect(0, 186, w, 34);
        for (let i = d.objs.length - 1; i >= 0; i--) {
          const o = d.objs[i]; o.y += o.vy * dt;
          mgCtx.font = "24px sans-serif"; mgCtx.textAlign = "center";
          mgCtx.fillText(o.good ? "✉️" : "🪨", o.x, o.y);
          if (Math.hypot(o.x - d.px, o.y - 176) < 28) {
            if (o.good) { mg.score += 20; sfx("coin"); }
            else { mg.score = Math.max(0, mg.score - 15); sfx("miss"); }
            d.objs.splice(i, 1); continue;
          }
          if (o.y > h + 20) d.objs.splice(i, 1);
        }
        // Draw player hero mini sprite!
        if (HERO_SHEETS.walk) {
          mgCtx.imageSmoothingEnabled = false;
          mgCtx.drawImage(HERO_SHEETS.walk, (Math.floor(now / 90) % 9) * 64, 2 * 64, 64, 64, d.px - 24, 142, 48, 48);
        } else {
          mgCtx.fillStyle = "#fde047"; mgCtx.beginPath(); mgCtx.arc(d.px, 174, 14, 0, Math.PI * 2); mgCtx.fill();
        }
      } else if (mg.kind === "stardew_fish") {
        const d = mg.data;
        d.elapsed += dt;
        // Fish AI
        d.fishTimer -= dt;
        if (d.fishTimer <= 0) {
          d.fishTimer = 0.55 + Math.random() * 0.9;
          d.fishTargetY = 24 + Math.random() * 168;
        }
        d.fishY += (d.fishTargetY - d.fishY) * 3.4 * dt;
        // Player Tension Bar physics
        const thrust = (mg.holdDown || state.keys[" "] || state.keys["e"]) ? -340 : 290;
        d.barVy = Math.max(-210, Math.min(210, d.barVy + thrust * dt));
        d.barY += d.barVy * dt;
        if (d.barY < 14) { d.barY = 14; d.barVy = 0; }
        if (d.barY + d.barH > 206) { d.barY = 206 - d.barH; d.barVy = 0; }
        const inside = d.fishY >= d.barY - 6 && d.fishY <= d.barY + d.barH + 6;
        d.progress = Math.max(0, Math.min(100, d.progress + (inside ? 26 : -17) * dt));
        mg.score = Math.round(d.progress);
        badge.textContent = `🎣 ความคืบหน้าจับปลา: ${mg.score}%`;
        if (d.progress >= 100) { concludeMiniGame(100, 100); return; }
        if (d.progress <= 0 || d.elapsed >= 20) { concludeMiniGame(0, 100); return; }

        // Render Stardew Water Column
        const colX = 185, colW = 54;
        mgCtx.fillStyle = "#0c4a6e"; mgCtx.fillRect(colX, 14, colW, 192);
        mgCtx.strokeStyle = "#bae6fd"; mgCtx.lineWidth = 2.5; mgCtx.strokeRect(colX, 14, colW, 192);
        mgCtx.fillStyle = inside ? "rgba(74, 222, 128, 0.82)" : "rgba(250, 204, 21, 0.55)";
        mgCtx.fillRect(colX + 4, d.barY, colW - 8, d.barH);
        mgCtx.strokeStyle = "#166534"; mgCtx.lineWidth = 2; mgCtx.strokeRect(colX + 4, d.barY, colW - 8, d.barH);
        mgCtx.font = "22px sans-serif"; mgCtx.textAlign = "center";
        mgCtx.fillText("🐟", colX + colW / 2, d.fishY + 7);
        // Right-side progress gauge
        const px = 258, ph = 192, fillH = (d.progress / 100) * ph;
        mgCtx.fillStyle = "#1e293b"; mgCtx.fillRect(px, 14, 22, ph);
        mgCtx.fillStyle = d.progress > 65 ? "#22c55e" : "#f59e0b";
        mgCtx.fillRect(px + 2, 14 + ph - fillH, 18, fillH);
        mgCtx.strokeStyle = "#f8fafc"; mgCtx.strokeRect(px, 14, 22, ph);
      } else if (mg.kind === "rhythm_stage") {
        const d = mg.data;
        const hitLineY = 182;
        badge.textContent = `🎵 คะแนนดนตรี: ${mg.score}/${mg.maxScore} • Combo x${d.combo}`;
        for (let i = 0; i < 4; i++) {
          const lx = 75 + i * 86;
          mgCtx.strokeStyle = "rgba(148,163,184,0.28)"; mgCtx.lineWidth = 2;
          mgCtx.strokeRect(lx, 12, 68, 196);
          mgCtx.fillStyle = "rgba(250,204,21,0.22)";
          mgCtx.fillRect(lx, hitLineY - 12, 68, 24);
          mgCtx.fillStyle = "#e2e8f0"; mgCtx.font = "bold 12px sans-serif"; mgCtx.textAlign = "center";
          mgCtx.fillText(d.lanes[i].label, lx + 34, 202);
        }
        let activeLeft = 0;
        d.notes.forEach(n => {
          if (n.hit || n.missed) return;
          n.y += d.speed * dt;
          if (n.y > hitLineY + 34) { n.missed = true; d.combo = 0; return; }
          activeLeft++;
          const lx = 75 + n.lane * 86 + 34;
          mgCtx.fillStyle = d.lanes[n.lane].col;
          mgCtx.beginPath(); mgCtx.arc(lx, n.y, 14, 0, Math.PI * 2); mgCtx.fill();
          mgCtx.strokeStyle = "#ffffff"; mgCtx.lineWidth = 2; mgCtx.stroke();
        });
        if (activeLeft === 0) { concludeMiniGame(mg.score, mg.maxScore); return; }
      }

      mg.rafId = requestAnimationFrame(stepMiniGame);
    }

    document.getElementById("btnMgPrimary").addEventListener("mousedown", () => {
      mg.holdDown = true;
      if (mg.kind === "forge_heat") triggerMgPrimaryHit();
    });
    window.addEventListener("mouseup", () => { mg.holdDown = false; });
    mgCanvas.addEventListener("mousedown", () => {
      mg.holdDown = true;
      if (mg.kind === "forge_heat") triggerMgPrimaryHit();
    });
    mgCanvas.addEventListener("mousemove", (e) => {
      if (mg.active && mg.kind === "sky_dash") {
        const r = mgCanvas.getBoundingClientRect();
        mg.data.px = Math.max(30, Math.min(430, (e.clientX - r.left) * (mgCanvas.width / Math.max(1, r.width))));
      }
    });
    document.getElementById("btnMgCancel").addEventListener("click", closeMiniGameOverlay);

    function finishJobResult(job, score, maxScore) {
      const craftLv = getStatLevelInfo("craft").level;
      const baseCost = (job.bonus_stat === "craft" && craftLv >= 4) ? Math.round(job.energy_cost * 0.8) : job.energy_cost;
      const cost = getStaminaCost(baseCost);
      state.stamina = Math.max(0, state.stamina - cost);
      const bonusLv = getStatLevelInfo(job.bonus_stat).level;
      const ratio = score / Math.max(1, maxScore);
      const rank = ratio >= 0.82 ? "S" : ratio >= 0.5 ? "A" : "B";
      const rankMult = rank === "S" ? 1.5 : rank === "A" ? 1.2 : 1.0;
      const avianMult = (state.heroCustom.raceKey === "avian" && (job.id === "job_courier" || job.id === "job_patrol")) ? 1.15 : 1.0;
      const pay = Math.round(job.base_pay_gold * (1 + (bonusLv - 1) * 0.15) * rankMult * avianMult);
      addGold(pay);
      state.workedToday[job.id] = true; state.totalShifts++;
      if (rank === "S") state.sRankJobs = (state.sRankJobs || 0) + 1;
      const scaledStats = {};
      for (const [k, v] of Object.entries(job.stat_gains || {})) scaledStats[k] = Math.round(v * (rank === "S" ? 1.4 : 1.0));
      const statStr = addStatXp(scaledStats);
      for (const [cid, fp] of Object.entries(job.friendship_gains || {})) addFriendship(cid, Math.round(fp * rankMult));
      let bonusMsg = "";
      const chance = rank === "S" ? 1.0 : (craftLv >= 3 ? Math.max(0.45, job.bonus_item_chance) : job.bonus_item_chance);
      if (job.bonus_item_id && Math.random() < chance) {
        state.inventory[job.bonus_item_id] = (state.inventory[job.bonus_item_id] || 0) + 1;
        bonusMsg = ` + 🎁 ${ITEM_BY_ID[job.bonus_item_id]?.name_th || "ไอเทม"}`;
      }
      sfx(rank === "S" ? "quest" : "coin");
      spawnFloatText(`Rank ${rank}! +${pay} G`, state.player.x, state.player.y - 42, rank === "S" ? "#fde047" : "#86efac");
      spawnParticles(state.player.x, state.player.y - 20, "#facc15", rank === "S" ? 18 : 10);
      advanceHours(job.duration_hours); checkAchievements(); saveGame(true);
      showToast(`💼 [Rank ${rank}] จบงาน "${job.title_th}"! รับ +${pay}G (${statStr})${bonusMsg}`);
    }

    function startFishingGame() {
      const cost = getStaminaCost(8);
      if (state.stamina < cost) { showToast(`⚡ พลังงานไม่พอตกปลา (ต้องใช้ ${cost} ⚡) กินของว่างก่อนนะ!`); return; }
      sfx("splash"); state.player.interactT = 0.6;
      startSpecializedMiniGame("stardew_fish", "fish", null);
    }
    function finishFishResult(score, maxScore) {
      state.stamina = Math.max(0, state.stamina - getStaminaCost(8));
      if (score < 100) {
        spawnFloatText("💨 ปลาหลุดเบ็ด!", state.player.x, state.player.y - 36, "#fca5a5");
        showToast("😅 ปลากระตุกหลุดเบ็ดไปซะแล้ว ลองเลี้ยงแถบเขียวใหม่นะ!");
        return;
      }
      const isMerfolk = state.heroCustom.raceKey === "merfolk";
      const pool = isMerfolk ? FISH_POOL.slice(1) : FISH_POOL;
      const totalW = pool.reduce((a, b) => a + b.weight, 0);
      let r = Math.random() * totalW, caught = pool[0];
      for (const p of pool) { r -= p.weight; if (r <= 0) { caught = p; break; } }
      state.inventory[caught.item_id] = (state.inventory[caught.item_id] || 0) + 1;
      state.fishCaught = (state.fishCaught || 0) + 1;
      state.dailyLog.itemsFound++;
      addStatXp({ craft: 5, wisdom: 3 }); sfx("sparkle");
      const it = ITEM_BY_ID[caught.item_id];
      spawnFloatText(`🎣 ได้ ${it?.name_th}!`, state.player.x, state.player.y - 42, "#93c5fd");
      spawnParticles(state.player.x, state.player.y - 18, "#60a5fa", 16);
      checkAchievements(); saveGame(true);
      showToast(`🎣 ตกปลาสำเร็จ! ได้ ${caught.label} เข้ากระเป๋าแล้ว!`);
    }

    function finishConcertResult(score, maxScore) {
      const rankS = score >= maxScore * 0.75;
      const hBonus = rankS ? 20 : 12;
      state.stamina = Math.min(getMaxStamina(), state.stamina + 25);
      const statStr = addStatXp({ charm: rankS ? 14 : 8 });
      GAME_DATA.characters.characters.forEach(c => addFriendship(c.id, hBonus));
      if (rankS) addGold(120);
      sfx("concert");
      spawnParticles(state.player.x, state.player.y - 22, "#f472b6", 28);
      spawnFloatText(`🎻 คอนเสิร์ต +${hBonus}❤️ ทั้งเมือง!`, state.player.x, state.player.y - 46, "#fbcfe8");
      saveGame(true);
      showToast(`🎻 จบการบรรเลงดนตรี! ชาวเมืองทุกคน +${hBonus}❤️ • ฟื้นพลัง +25⚡ ${rankS ? "• ทิปพิเศษ +120G!" : ""} (${statStr})`);
    }
"""

JS_PART_3A = r"""
    // =========================================================================
    // 10. DIALOGUE, MARRIAGE & SPOUSE LIFE, 8-RACE CREATOR & SAVE SLOTS MODALS
    // =========================================================================
    let typeTimer = null, fullDlgText = "", activeCutscene = null;
    function setDialogueText(text) {
      clearInterval(typeTimer); fullDlgText = text;
      const el = document.getElementById("dlgBody"); el.textContent = "";
      let idx = 0;
      typeTimer = setInterval(() => {
        idx += 2; el.textContent = fullDlgText.slice(0, idx);
        if (idx % 6 === 0) sfx("talk");
        if (idx >= fullDlgText.length) { el.textContent = fullDlgText; clearInterval(typeTimer); typeTimer = null; }
      }, 20);
    }
    function skipTypewriter() {
      if (typeTimer) { clearInterval(typeTimer); typeTimer = null; document.getElementById("dlgBody").textContent = fullDlgText; return true; }
      return false;
    }
    document.getElementById("dlgBody").addEventListener("click", () => {
      if (skipTypewriter()) return;
      if (activeCutscene) window.advanceCutsceneBeat();
    });

    const EMOTION_META = {
      neutral: { label: "😊 ปกติ", bg: "#f5dfb2", border: "#9e6530", color: "#4c230a", cls: "" },
      happy:   { label: "😄 ดีใจ", bg: "#fef08a", border: "#ca8a04", color: "#713f12", cls: "emo-happy" },
      blush:   { label: "😳 เขินอาย", bg: "#fce7f3", border: "#db2777", color: "#831843", cls: "emo-blush" },
      sad:     { label: "😔 เศร้า", bg: "#e2e8f0", border: "#475569", color: "#1e293b", cls: "emo-sad" }
    };
    function getNpcDialogueWithEmotion(cid) {
      const dlg = GAME_DATA.dialogues.dialogues[cid];
      if (!dlg) return { text: "สวัสดี! ยินดีที่ได้เจอในหุบเขาต้นไม้โลกนะ", emotion: "neutral" };
      const cal = getCalendarInfo();
      if (NPC_BIRTHDAYS[cid] === cal.dayOfSeason) {
        return { text: formatText(`🎂 วันนี้วันเกิดของฉันเองล่ะ {player}! ดีใจจังที่เธอแวะมาทักทายกันนะ!`), emotion: "happy" };
      }
      if (state.spouseId === cid) {
        const lines = [
          `💒 อรุณสวัสดิ์ที่รัก {player}! การได้ตื่นมาเจอเธอใน {farm} ทุกเช้าคือความสุขที่สุดในชีวิตฉันเลยนะ 💕`,
          `💒 วันนี้อย่าโหมงานหนักเกินไปนะ {player} เย็นนี้กลับมานั่งดูดาวบนชั้น 2 ด้วยกันนะจ๊ะ 💖`,
          `💒 ฉันจัดดอกไม้ในบ้านไว้รอเธอแล้วนะ {player} ถ้าหิวเมื่อไหร่มารับมื้อเช้าฝีมือฉันได้เลย!`
        ];
        return { text: formatText(lines[(state.day + Math.floor(state.timeMin)) % lines.length]), emotion: "blush" };
      }
      if (state.partners[cid] && Math.random() < 0.5) {
        return { text: formatText(`💑 ดีใจทุกครั้งเลยที่ได้เห็นหน้าเธอในเมืองนะ {player} เมื่อไหร่หัวใจเราเต็ม 10 ดวง เรามาสร้างครอบครัวที่ {farm} ด้วยกันนะ 💕`), emotion: "blush" };
      }
      const h = state.timeMin / 60, hearts = getHearts(cid);
      let greeting = dlg.greetings.morning, emotion = hearts >= 7 ? "happy" : "neutral";
      if (state.weather === "rainy") { greeting = dlg.greetings.rainy; if (hearts < 4) emotion = "sad"; }
      else if (h >= 17 || h < 5) greeting = dlg.greetings.evening;
      const tierKey = hearts >= 9 ? "9_10" : hearts >= 6 ? "6_8" : hearts >= 3 ? "3_5" : "0_2";
      const tierLine = dlg.heart_tiers?.[tierKey] || "";
      if (Math.random() < 0.55 && tierLine) {
        const tierEmo = hearts >= 9 && CHAR_BY_ID[cid]?.romanceable ? "blush" : (hearts >= 6 ? "happy" : "neutral");
        return { text: formatText(tierLine), emotion: tierEmo };
      }
      return { text: formatText(greeting), emotion };
    }

    function drawPortrait(cid, emotion = "neutral") {
      const emo = EMOTION_META[emotion] ? emotion : "neutral";
      const meta = EMOTION_META[emo];
      const box = document.getElementById("dlgPortraitBox");
      if (box) box.className = "portrait-box" + (meta.cls ? " " + meta.cls : "");
      const badge = document.getElementById("dlgEmotionBadge");
      if (badge) {
        badge.textContent = meta.label;
        badge.style.background = meta.bg; badge.style.borderColor = meta.border; badge.style.color = meta.color;
      }
      const pc = document.getElementById("dlgPortrait").getContext("2d");
      pc.clearRect(0, 0, 136, 136);
      const exprImg = (emo !== "neutral" && SPRITES.portrait[`${cid}_${emo}`]) ? SPRITES.portrait[`${cid}_${emo}`] : SPRITES.portrait[cid];
      if (exprImg) { pc.imageSmoothingEnabled = true; pc.drawImage(exprImg, 0, 0, 136, 136); }
      else if (SPRITES.walk[cid]) { pc.imageSmoothingEnabled = false; pc.drawImage(SPRITES.walk[cid], 0, 2 * 64 + 6, 64, 48, 4, 16, 128, 96); }
    }
    window._drawPortrait = drawPortrait;

    function updateDialogueHeader(cid) {
      const c = CHAR_BY_ID[cid], h = getHearts(cid);
      const isSpouse = state.spouseId === cid;
      document.getElementById("dlgName").textContent = c ? `${c.name_th} (${c.name_en})` : cid;
      document.getElementById("dlgMeta").textContent = c ? `${c.race_th} • ${c.role}` : "";
      document.getElementById("dlgSpouseBadge").style.display = isSpouse ? "inline-block" : "none";
      document.getElementById("dlgPartnerBadge").style.display = (!isSpouse && state.partners[cid]) ? "inline-block" : "none";
      document.getElementById("dlgHearts").textContent = "❤️".repeat(Math.min(5, h)) + (h > 5 ? ` +${h-5}💖` : "🤍".repeat(Math.max(0, 5 - h)));
      document.getElementById("btnHeartEvent").style.display = getUnlockedEventForNpc(cid) ? "inline-block" : "none";
      document.getElementById("btnConfess").style.display = (c?.romanceable && !state.partners[cid] && !isSpouse && h >= 6) ? "inline-block" : "none";
      document.getElementById("btnProposeMarriage").style.display = (c?.romanceable && state.partners[cid] && !state.spouseId && h >= 9) ? "inline-block" : "none";
      document.getElementById("btnSpouseCare").style.display = (isSpouse && state.spouseCaredDay !== state.day) ? "inline-block" : "none";
      document.getElementById("btnSpouseDate").style.display = (isSpouse && state.spouseDatedDay !== state.day) ? "inline-block" : "none";
      document.getElementById("btnNpcJob").style.display = JOB_BY_EMPLOYER[cid] ? "inline-block" : "none";
    }

    function openDialogue(npc) {
      state.activeDlgNpc = npc; state.talkedEver[npc.id] = true;
      const rel = state.relations[npc.id];
      if (rel && !rel.talkedToday) {
        rel.talkedToday = true; addFriendship(npc.id, 15); addStatXp({ charm: 2 });
        spawnFloatText("+15 ❤️", npc.px, npc.py - 46, "#f472b6");
      }
      document.getElementById("dlgChoices").style.display = "none";
      document.getElementById("dlgCutsceneBar").style.display = "none";
      document.getElementById("dlgActions").style.display = "flex";
      document.getElementById("dialogueOverlay").style.display = "block";
      const dlgRes = getNpcDialogueWithEmotion(npc.id);
      updateDialogueHeader(npc.id); setDialogueText(dlgRes.text); drawPortrait(npc.id, dlgRes.emotion);
      checkAchievements(); updateQuestTrackerHud();
    }
    function closeDialogue() {
      clearInterval(typeTimer); typeTimer = null;
      if (audio.overrideZone === "wedding") { audio.overrideZone = null; syncBgmZone(); }
      state.activeDlgNpc = null; activeCutscene = null;
      document.getElementById("dlgCutsceneBar").style.display = "none";
      document.getElementById("dlgChoices").style.display = "none";
      document.getElementById("dialogueOverlay").style.display = "none";
    }

    // SYSTEM 3: MARRIAGE PROPOSAL, GRAND WEDDING CEREMONY & SPOUSE DAILY LIFE!
    function triggerMarriageProposal(cid) {
      const ch = CHAR_BY_ID[cid]; if (!ch) return;
      if (getHearts(cid) < 10) {
        showToast(`💒 ต้องมีความสัมพันธ์เต็ม 10 ❤️ ก่อนถึงจะขอแต่งงานได้! (ปัจจุบัน ${getHearts(cid)}/10 ❤️)`);
        return;
      }
      if (!state.inventory.item_world_tree_ring) {
        showToast("💍 ต้องมี 'แหวนสายใยรากไม้โลก' ก่อน! (คราฟต์ได้จากโต๊ะคราฟต์ [4] ซื้อที่ร้านพิป หรือเก็บจากหีบชั้น B3 ในโบราณสถาน)");
        return;
      }
      state.inventory.item_world_tree_ring--;
      if (state.inventory.item_world_tree_ring <= 0) delete state.inventory.item_world_tree_ring;
      state.spouseId = cid;
      state.weddingDay = state.day;
      audio.overrideZone = "wedding"; syncBgmZone();
      sfx("wedding");
      addGold(500);
      addStatXp({ charm: 25, courage: 25 });
      GAME_DATA.characters.characters.forEach(c => addFriendship(c.id, 35));

      // Move to World Tree Shrine & play Grand Wedding Ceremony Cutscene!
      state.scene = "outdoor";
      state.player.x = 42 * TILE; state.player.y = 29.5 * TILE;
      spawnParticles(state.player.x, state.player.y - 24, "#fde047", 45);
      spawnParticles(state.player.x, state.player.y - 16, "#f472b6", 35);

      const weddingCh = {
        id: `wedding_${cid}`,
        arc: "wedding",
        icon: "💒",
        title_th: `พิธีวิวาห์ใต้ต้นไม้โลก: ${state.playerName} & ${ch.name_th}`,
        beats: [
          { speaker: "16_bram", emotion: "happy", text: `ฮ่าๆๆ! วันนี้เป็นวันมงคลยิ่งใหญ่ของหุบเขาต้นไม้โลก! ชาวเมืองทั้ง 8 เผ่ามารวมตัวกันเพื่อร่วมเป็นสักขีพยานรักให้กับ {player} และ ${ch.name_th}!` },
          { speaker: cid, emotion: "blush", text: `{player}... ตอนที่เธอยื่นแหวนสายใยรากไม้โลกวงนี้ให้ ฉันดีใจจนพูดไม่ออกเลย ขอบคุณที่เลือกใช้ชีวิตเคียงข้างกันที่ {farm} นะ 💕` },
          { speaker: "03_lilian", emotion: "happy", text: `ดูบนยอดต้นไม้โลกสิคะ! กลีบใบไม้สีทองโปรยปรายลงมาอวยพรให้คู่บ่าวสาวทั้งสองคนแล้ว สวยงามราวกับปาฏิหาริย์เลย!` },
          { speaker: cid, emotion: "happy", text: `ไม่ว่าจะฤดูใบไม้ผลิ ร้อน ร่วง หรือหนาว... จากวันนี้ไป เราสองคนจะดูแลกันและกันตลอดไปนะ ที่รักของฉัน 💒💖` }
        ],
        choices: [
          { text_th: "💍 สวมแหวนและให้คำสัญญาว่าจะรักตลอดไป (+500G ขวัญถุงวิวาห์!)", speaker: cid, emotion: "blush", reply_th: `ฉันรักเธอที่สุดในเอเธลการ์ดเลย {player}! คืนนี้เรากลับบ้านของเราที่ {farm} ด้วยกันนะ! 💒✨` }
        ]
      };
      activeCutscene = { ch: weddingCh, beatIdx: 0, isReplay: true, finished: false };
      syncNpcSchedules(); checkAchievements(); renderSocialStatsHud(); saveGame(true);
      renderCutsceneBeat();
      showToast(`💒 วิวาห์หวานชื่น! คุณและ ${ch.name_th} แต่งงานเป็นคู่สมรสกันแล้ว! (+500G ขวัญถุงแต่งงาน)`);
    }

    function triggerSpouseMorningCare(cid) {
      if (state.spouseId !== cid || state.spouseCaredDay === state.day) return;
      state.spouseCaredDay = state.day;
      const mealPool = ["item_honey_croissant", "item_apple_pie", "item_hearty_stew", "item_emerald_tea", "item_ruby_elixir"];
      const giftId = mealPool[state.day % mealPool.length];
      state.inventory[giftId] = (state.inventory[giftId] || 0) + 1;
      state.stamina = Math.min(getMaxStamina(), state.stamina + 25);
      addStatXp({ charm: 8, courage: 5 });
      sfx("heart");
      updateDialogueHeader(cid);
      drawPortrait(cid, "happy");
      setDialogueText(`🍳 "ฉันตื่นมาเตรียม ${ITEM_BY_ID[giftId]?.name_th} ร้อนๆ ไว้ให้เธอสำหรับวันนี้ด้วยนะ ${state.playerName}! กินให้อิ่มแล้วขอให้วันนี้เป็นวันที่ดีนะจ๊ะ 💕" (+25⚡ +🎁)`);
      saveGame(true);
      showToast(`💒 คู่สมรสมอบ "${ITEM_BY_ID[giftId]?.name_th}" + ฟื้นพลังงาน +25⚡!`);
    }

    function triggerSpouseRomanticDate(cid) {
      const ch = CHAR_BY_ID[cid];
      if (state.spouseId !== cid || state.spouseDatedDay === state.day) return;
      state.spouseDatedDay = state.day;
      audio.overrideZone = "wedding"; syncBgmZone();
      state.stamina = getMaxStamina();
      addFriendship(cid, 50);
      const statStr = addStatXp({ charm: 12, wisdom: 8 });
      advanceHours(2);
      sfx("wedding");
      updateDialogueHeader(cid);
      drawPortrait(cid, "blush");
      setDialogueText(`🌙 คุณและ ${ch.name_th} ใช้เวลายามค่ำคืนนั่งอิงแอบชมหมู่ดาวเหนือหุบเขาต้นไม้โลก เสียงหัวเราะและสายลมอุ่นช่วยเติมพลังกายใจจนเต็มเปี่ยม 100%! 💒✨`);
      saveGame(true);
      showToast(`🌙 เดตคู่สมรสสุดโรแมนติกกับ ${ch.name_th}! พลังงานฟื้นเต็ม 100% (${statStr})`);
    }

    function openModal(title, htmlContent) {
      state.modalOpen = true;
      document.getElementById("modalTitle").textContent = title;
      document.getElementById("modalBody").innerHTML = htmlContent;
      document.getElementById("modalBackdrop").style.display = "flex";
    }
    function closeModal() {
      clearInterval(window._creatorAnimTimer);
      state.modalOpen = false;
      document.getElementById("modalBackdrop").style.display = "none";
      if (state.started) selectTool(0, true);
    }
    window.closeModal = closeModal;
    document.getElementById("btnCloseModal").addEventListener("click", closeModal);
    document.getElementById("modalBackdrop").addEventListener("click", (e) => { if (e.target.id === "modalBackdrop") closeModal(); });

    // =========================================================================
    // SYSTEM 1: 8-RACE PROTAGONIST CUSTOMIZER MODAL (16 BASES + HSV + 7 SKINS!)
    // =========================================================================
    window.openProtagonistCreator = () => {
      const hc = state.heroCustom;
      const rKey = getCharRaceKey(hc.baseId);
      const curPerk = RACE_PERKS[rKey] || RACE_PERKS.human;
      const html = `
        <div class="creator-two-col">
          <div class="card-row" style="flex-direction:column;align-items:center;text-align:center;gap:8px;">
            <div style="font-weight:800;font-size:13px;color:#4c230a;">✨ พรีวิวตัวเอก 2.5D</div>
            <div style="background:#1e293b;border:3px solid #4c230a;border-radius:8px;padding:8px;">
              <canvas id="creatorPreviewCanvas" width="128" height="128" class="pixelated" style="width:128px;height:128px;"></canvas>
            </div>
            <div style="display:flex;gap:4px;">
              <button class="sd-btn" onclick="window._creatorDir=0">⬆️</button>
              <button class="sd-btn" onclick="window._creatorDir=1">⬅️</button>
              <button class="sd-btn active" onclick="window._creatorDir=2">⬇️</button>
              <button class="sd-btn" onclick="window._creatorDir=3">➡️</button>
            </div>
            <div id="creatorPerkBox" style="background:#fef9c3;border:1.5px solid #ca8a04;border-radius:6px;padding:6px;font-size:11px;font-weight:700;color:#713f12;width:100%;">
              <b>${curPerk.icon} ${curPerk.name_th}</b><br/>🌟 ${curPerk.perk_th}
            </div>
            <button class="sd-btn purple" style="width:100%;" onclick="window.randomizeProtagonist()">🎲 สุ่มเผ่า & โทนสี</button>
            <button class="sd-btn green" style="width:100%;padding:7px;" onclick="window.applyProtagonistAndClose()">✅ บันทึกรูปลักษณ์ตัวเอก</button>
          </div>
          <div style="display:flex;flex-direction:column;gap:8px;">
            <div class="card-row" style="display:grid;grid-template-columns:repeat(3,1fr);gap:6px;">
              <label style="font-size:11px;font-weight:800;">ชื่อตัวเอก<input id="crName" value="${state.playerName}" maxlength="16" style="width:100%;padding:4px;border:1.5px solid #8c4d1d;border-radius:5px;font-weight:700;" /></label>
              <label style="font-size:11px;font-weight:800;">ชื่อบ้าน/กระท่อม<input id="crFarm" value="${state.cottageName}" maxlength="20" style="width:100%;padding:4px;border:1.5px solid #8c4d1d;border-radius:5px;font-weight:700;" /></label>
              <label style="font-size:11px;font-weight:800;">ของโปรด<input id="crFav" value="${state.favThing}" maxlength="20" style="width:100%;padding:4px;border:1.5px solid #8c4d1d;border-radius:5px;font-weight:700;" /></label>
            </div>
            <div class="card-row" style="flex-direction:column;align-items:stretch;">
              <div style="font-size:12px;font-weight:800;color:#4c230a;margin-bottom:4px;">🧬 เลือกเผ่าพันธุ์ทั้ง 8 เผ่า (16 โครงร่างตัวละคร):</div>
              <div class="race-grid">
                ${GAME_DATA.characters.characters.map(c => {
                  const rk = getCharRaceKey(c.id), rp = RACE_PERKS[rk];
                  return `<button class="sd-btn ${c.id === hc.baseId ? 'active' : ''}" style="text-align:left;padding:4px 6px;font-size:10.5px;" onclick="window.setCreatorBase('${c.id}')">
                    ${rp.icon} ${c.race_th}<br/><span style="font-weight:600;color:#5c3312;">${c.name_th.split(" ")[0]}</span>
                  </button>`;
                }).join("")}
              </div>
            </div>
            <div class="card-row" style="flex-direction:column;align-items:stretch;gap:6px;">
              <div style="display:flex;justify-content:space-between;align-items:center;">
                <span style="font-size:12px;font-weight:800;color:#4c230a;">🎨 ปรับสีชุด/ทรงผม & โทนสีผิว (รักษาเส้นขอบดำ 2.5D 100%)</span>
                <button class="sd-btn" style="font-size:10px;" onclick="window.setCreatorPreset(0,100,100,'none')">↺ สีต้นฉบับ</button>
              </div>
              <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;font-size:11px;font-weight:800;">
                <label>🌈 เฉดสีผม/ชุด (<span id="crHueLbl">${hc.hue}°</span>)<input id="crHue" type="range" min="-180" max="180" value="${hc.hue}" style="width:100%;" oninput="window.updateCreatorSliders()" /></label>
                <label>✨ ความสดสี (<span id="crSatLbl">${hc.sat}%</span>)<input id="crSat" type="range" min="40" max="170" value="${hc.sat}" style="width:100%;" oninput="window.updateCreatorSliders()" /></label>
                <label>☀️ ความสว่าง (<span id="crValLbl">${hc.val}%</span>)<input id="crVal" type="range" min="75" max="130" value="${hc.val}" style="width:100%;" oninput="window.updateCreatorSliders()" /></label>
                <label>🧑 โทนสีผิว
                  <select id="crSkin" style="width:100%;padding:3px;border:1.5px solid #8c4d1d;border-radius:5px;font-weight:700;" onchange="window.updateCreatorSliders()">
                    <option value="none" ${hc.skin==='none'?'selected':''}>ตามเผ่าพันธุ์ (Default)</option>
                    <option value="warm" ${hc.skin==='warm'?'selected':''}>ผิวขาวอมชมพู (Warm Fair)</option>
                    <option value="tan" ${hc.skin==='tan'?'selected':''}>ผิวแทนน้ำผึ้ง (Sun Tan)</option>
                    <option value="pale" ${hc.skin==='pale'?'selected':''}>ผิวขาวจันทรา (Moon Pale)</option>
                    <option value="drow" ${hc.skin==='drow'?'selected':''}>ผิวดาร์กเอลฟ์ (Night Drow)</option>
                    <option value="goblin" ${hc.skin==='goblin'?'selected':''}>ผิวทองก็อบลิน (Golden)</option>
                    <option value="aqua" ${hc.skin==='aqua'?'selected':''}>ผิวฟ้าสมุทร (Merfolk Aqua)</option>
                  </select>
                </label>
              </div>
              <div style="display:flex;gap:4px;flex-wrap:wrap;">
                <button class="sd-btn" style="font-size:10px;" onclick="window.setCreatorPreset(-45,120,105,'none')">🔥 อัศวินเพลิง</button>
                <button class="sd-btn" style="font-size:10px;" onclick="window.setCreatorPreset(110,115,100,'none')">❄️ เวทน้ำแข็ง</button>
                <button class="sd-btn" style="font-size:10px;" onclick="window.setCreatorPreset(165,125,95,'pale')">🌙 ราตรีสีม่วง</button>
                <button class="sd-btn" style="font-size:10px;" onclick="window.setCreatorPreset(42,130,108,'tan')">☀️ นักสำรวจทอง</button>
                <button class="sd-btn" style="font-size:10px;" onclick="window.setCreatorPreset(-120,110,102,'aqua')">🌊 สมุทรสีคราม</button>
              </div>
            </div>
          </div>
        </div>
      `;
      openModal("🧙 แต่งตัวเอก 8 เผ่าพันธุ์ & ปรับโทนสี 2.5D เรียลไทม์", html);
      window._creatorDir = 2;
      clearInterval(window._creatorAnimTimer);
      let tickF = 0;
      window._creatorAnimTimer = setInterval(() => {
        const cv = document.getElementById("creatorPreviewCanvas");
        if (!cv) { clearInterval(window._creatorAnimTimer); return; }
        const g = cv.getContext("2d");
        g.imageSmoothingEnabled = false;
        g.clearRect(0, 0, 128, 128);
        if (HERO_SHEETS.walk) {
          g.drawImage(HERO_SHEETS.walk, (tickF % 9) * 64, (window._creatorDir || 2) * 64, 64, 64, 0, 0, 128, 128);
        }
        tickF++;
      }, 115);
    };

    window.syncCreatorInputs = () => {
      const nm = document.getElementById("crName"), fm = document.getElementById("crFarm"), fv = document.getElementById("crFav");
      if (nm && nm.value.trim()) state.playerName = nm.value.trim();
      if (fm && fm.value.trim()) state.cottageName = fm.value.trim();
      if (fv && fv.value.trim()) state.favThing = fv.value.trim();
      const titleInp = document.getElementById("heroNameInput");
      if (titleInp) titleInp.value = state.playerName;
    };
    window.setCreatorBase = (cid) => {
      window.syncCreatorInputs();
      state.heroCustom.baseId = cid;
      rebuildHeroCustomSheets();
      sfx("talk");
      window.openProtagonistCreator();
    };
    window.updateCreatorSliders = () => {
      window.syncCreatorInputs();
      state.heroCustom.hue = Number(document.getElementById("crHue").value);
      state.heroCustom.sat = Number(document.getElementById("crSat").value);
      state.heroCustom.val = Number(document.getElementById("crVal").value);
      state.heroCustom.skin = document.getElementById("crSkin").value;
      document.getElementById("crHueLbl").textContent = `${state.heroCustom.hue}°`;
      document.getElementById("crSatLbl").textContent = `${state.heroCustom.sat}%`;
      document.getElementById("crValLbl").textContent = `${state.heroCustom.val}%`;
      rebuildHeroCustomSheets();
    };
    window.setCreatorPreset = (h, s, v, sk) => {
      window.syncCreatorInputs();
      state.heroCustom.hue = h; state.heroCustom.sat = s; state.heroCustom.val = v; state.heroCustom.skin = sk;
      rebuildHeroCustomSheets();
      sfx("sparkle");
      window.openProtagonistCreator();
    };
    window.randomizeProtagonist = () => {
      window.syncCreatorInputs();
      const chars = GAME_DATA.characters.characters;
      state.heroCustom.baseId = chars[Math.floor(Math.random() * chars.length)].id;
      state.heroCustom.hue = Math.floor(Math.random() * 360) - 180;
      state.heroCustom.sat = 85 + Math.floor(Math.random() * 60);
      state.heroCustom.val = 90 + Math.floor(Math.random() * 25);
      const skins = ["none","warm","tan","pale","drow","goblin","aqua"];
      state.heroCustom.skin = skins[Math.floor(Math.random() * skins.length)];
      rebuildHeroCustomSheets();
      sfx("sparkle");
      window.openProtagonistCreator();
    };
    window.applyProtagonistAndClose = () => {
      window.syncCreatorInputs();
      rebuildHeroCustomSheets();
      renderSocialStatsHud();
      if (state.started) saveGame(true);
      sfx("quest");
      closeModal();
      const rp = RACE_PERKS[state.heroCustom.raceKey] || RACE_PERKS.human;
      showToast(`🧙 บันทึกตัวเอก "${state.playerName}" (${rp.icon} ${rp.name_th}) เรียบร้อย!`);
    };

    // =========================================================================
    // SYSTEM 6A MODAL: 3 SAVE SLOTS MANAGER + JSON EXPORT/IMPORT!
    // =========================================================================
    window.saveToSlotAction = (n) => {
      saveGame(false, n);
      sfx("coin");
      window.openSaveSlotsModal();
    };
    window.loadFromSlotAction = (n) => {
      const d = readSlotData(n);
      if (!d) { showToast(`ช่องเซฟที่ ${n} ยังว่างอยู่! กด '💾 เซฟลงช่องนี้' เพื่อบันทึกได้เลย`); return; }
      loadSaveSlot(n, true);
      sfx("quest");
      closeModal();
    };
    window.deleteSlotAction = (n) => {
      if (!confirm(`ต้องการลบข้อมูลใน [ช่องเซฟ ${n}] หรือไม่?`)) return;
      localStorage.removeItem(SAVE_PREFIX + n);
      renderTitleSlotCards();
      sfx("door");
      window.openSaveSlotsModal();
    };
    window.exportSlotJson = (n) => {
      const d = readSlotData(n) || (n === activeSaveSlot ? serializeCurrentState() : null);
      if (!d) { showToast("ไม่มีข้อมูลในช่องนี้สำหรับส่งออก!"); return; }
      const blob = new Blob([JSON.stringify(d, null, 2)], { type: "application/json" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url; a.download = `aethelgard_slot${n}_${d.playerName || "save"}.json`; a.click();
      setTimeout(() => URL.revokeObjectURL(url), 2500);
      showToast(`📤 ดาวน์โหลดไฟล์ JSON ของช่องเซฟ ${n} แล้ว!`);
    };
    window.importSlotJson = (n) => {
      const inp = document.createElement("input");
      inp.type = "file"; inp.accept = ".json,application/json";
      inp.onchange = (e) => {
        const f = e.target.files?.[0]; if (!f) return;
        const r = new FileReader();
        r.onload = () => {
          try {
            const parsed = JSON.parse(r.result);
            localStorage.setItem(SAVE_PREFIX + n, JSON.stringify(parsed));
            loadSaveSlot(n, true);
            window.openSaveSlotsModal();
          } catch (_) { showToast("❌ ไฟล์เซฟ JSON ไม่ถูกต้อง!"); }
        };
        r.readAsText(f);
      };
      inp.click();
    };
    window.openSaveSlotsModal = () => {
      const rows = [1, 2, 3].map(n => {
        const d = readSlotData(n);
        const isCur = n === activeSaveSlot;
        let info = `<div style="font-size:11.5px;color:#78350f;">✨ ช่องว่าง — ยังไม่มีข้อมูลบันทึก</div>`;
        if (d) {
          const sIdx = Math.floor(((d.day || 1) - 1) / 28) % 4;
          const dSeason = (((d.day || 1) - 1) % 28) + 1;
          const rInfo = RACE_PERKS[getCharRaceKey(d.heroCustom?.baseId || "01_ren")] || RACE_PERKS.human;
          const sp = d.spouseId ? `💒 คู่สมรส: ${CHAR_BY_ID[d.spouseId]?.name_th}` : "โสด/กำลังจีบ";
          info = `<div style="font-size:12px;font-weight:700;color:#3f1d0b;">${rInfo.icon} <b>${d.playerName}</b> (${d.cottageName || "กระท่อมรากไม้ทอง"}) • วันที่ ${dSeason} ${SEASONS[sIdx].name_th}</div>
                  <div style="font-size:11px;color:#15803d;font-weight:800;">🪙 ${d.gold || 0}G • ${sp} • บ้านชั้น ${d.houseLevel || 1}</div>`;
        }
        return `<div class="card-row" style="${isCur ? 'border:2px solid #d97706;background:#fffbeb;' : ''}">
          <div>
            <div style="font-weight:800;font-size:14px;">💾 ช่องเซฟที่ ${n} ${isCur ? '<span class="badge" style="background:#fde047;">กำลังเล่นช่องนี้</span>' : ''}</div>
            ${info}
          </div>
          <div style="display:flex;gap:4px;flex-wrap:wrap;justify-content:flex-end;">
            <button class="sd-btn green" onclick="window.saveToSlotAction(${n})">💾 เซฟทับ</button>
            <button class="sd-btn blue" ${d ? '' : 'disabled'} onclick="window.loadFromSlotAction(${n})">📂 โหลด</button>
            <button class="sd-btn" onclick="window.exportSlotJson(${n})">📤 Export</button>
            <button class="sd-btn" onclick="window.importSlotJson(${n})">📥 Import</button>
            ${d ? `<button class="sd-btn red" onclick="window.deleteSlotAction(${n})">🗑️</button>` : ""}
          </div>
        </div>`;
      }).join("");
      const bgmRow = `<div class="card-row" style="background:#f0fdf4;border-color:#15803d;">
        <div>
          <div style="font-weight:800;font-size:13px;">🎵 ระบบเพลงประกอบแยกตามโซนอัตโนมัติ (7 Zone BGM Tracks)</div>
          <div style="font-size:11.5px;color:#14532d;">กำลังบรรเลง: <b>${(BGM_THEMES[audio.currentZone] || BGM_THEMES.plaza).name_th}</b> (เปลี่ยนอัตโนมัติตามจัตุรัส บ้าน โรงเตี๊ยม โรงตีเหล็ก ทะเลสาบ โบราณสถาน และงานแต่งงาน!)</div>
        </div>
        <button class="sd-btn ${audio.enabled ? 'active' : ''}" onclick="setAudioEnabled(!audio.enabled);window.openSaveSlotsModal();">${audio.enabled ? '🔊 เปิดเสียงอยู่' : '🔇 ปิดเสียงอยู่'}</button>
      </div>`;
      openModal("💾 จัดการเซฟ 3 ช่อง (Save Slots 1–3) & ตั้งค่าเสียงโซน", bgmRow + rows);
    };
"""

JS_PART_3B = r"""
    // =========================================================================
    // 10A. 4-ARC CHRONICLES, TOWN RESTORATION + ANCIENT RUINS, SHOPS & LOFT!
    // =========================================================================
    function isChapterUnlocked(ch) {
      if (state.chroniclesDone[ch.id]) return true;
      const u = ch.unlock || { type: "always" };
      const seals = getAwakenedSealCount(), built = Object.keys(state.landmarksBuilt || {}).length, cal = getCalendarInfo();
      if (u.type === "always") return true;
      if (u.type === "main_prog") {
        if (u.prev && !state.chroniclesDone[u.prev]) return false;
        const [minS, minD] = u.min_seals_or_day || [0, 1];
        return seals >= minS || state.day >= minD;
      }
      if (u.type === "main_ch4_cond") return !!state.chroniclesDone.main_ch3 && (seals >= 5 || built >= 2 || state.day >= 7);
      if (u.type === "main_finale") return !!state.chroniclesDone.main_ch4 && (seals >= 8 || (seals >= 6 && built >= 3));
      if (u.type === "prev_or_day") return !!state.chroniclesDone[u.prev] || state.day >= (u.day || 2);
      if (u.type === "talked_pair") return (u.pair || []).every(cid => state.talkedEver[cid] || getHearts(cid) >= 2);
      if (u.type === "season_or_obs") return cal.seasonIdx === u.season_idx || !!state.landmarksBuilt.lm_observatory;
      if (u.type === "season_or_heart") return cal.seasonIdx === u.season_idx || getHearts(u.cid) >= (u.hearts || 2) || !!state.landmarksBuilt.lm_observatory;
      return true;
    }

    function renderCutsceneBeat() {
      if (!activeCutscene) return;
      const { ch, beatIdx } = activeCutscene;
      const beat = ch.beats[beatIdx];
      const sp = CHAR_BY_ID[beat.speaker];
      document.getElementById("dialogueOverlay").style.display = "block";
      document.getElementById("dlgActions").style.display = "none";
      document.getElementById("dlgCutsceneBar").style.display = "flex";
      document.getElementById("dlgName").textContent = `${ch.icon} ${sp ? sp.name_th : beat.speaker}`;
      document.getElementById("dlgMeta").textContent = `${ch.title_th}`;
      document.getElementById("dlgPartnerBadge").style.display = "none";
      document.getElementById("dlgSpouseBadge").style.display = "none";
      document.getElementById("dlgHearts").textContent = `${sp ? sp.race_th : ""}`;
      document.getElementById("dlgCutsceneStep").textContent = `📖 ฉากที่ ${beatIdx + 1}/${ch.beats.length}`;
      drawPortrait(beat.speaker, beat.emotion || "neutral");
      setDialogueText(formatText(beat.text));

      const isLast = beatIdx >= ch.beats.length - 1;
      const box = document.getElementById("dlgChoices");
      document.getElementById("btnCutsceneClose").style.display = "none";
      if (isLast && ch.choices && ch.choices.length) {
        document.getElementById("btnCutsceneNext").style.display = "none";
        box.style.display = "flex";
        box.innerHTML = ch.choices.map((c, idx) => `<button class="choice-btn" onclick="window.finishCutsceneChoice(${idx})">▸ ${c.text_th}</button>`).join("");
      } else {
        box.style.display = "none";
        document.getElementById("btnCutsceneNext").style.display = "inline-block";
      }
    }

    window.advanceCutsceneBeat = () => {
      if (!activeCutscene) return;
      if (skipTypewriter()) return;
      if (activeCutscene.finished) { closeDialogue(); return; }
      if (activeCutscene.beatIdx < activeCutscene.ch.beats.length - 1) {
        activeCutscene.beatIdx++; sfx("talk"); renderCutsceneBeat();
      }
    };

    window.finishCutsceneChoice = (idx) => {
      if (!activeCutscene) return;
      const { ch, isReplay } = activeCutscene;
      const choice = ch.choices[idx]; if (!choice) return;
      activeCutscene.finished = true;
      const sp = CHAR_BY_ID[choice.speaker];
      document.getElementById("dlgChoices").style.display = "none";
      document.getElementById("btnCutsceneNext").style.display = "none";
      document.getElementById("btnCutsceneClose").style.display = "inline-block";
      document.getElementById("dlgName").textContent = `${ch.icon} ${sp ? sp.name_th : choice.speaker}`;
      drawPortrait(choice.speaker, choice.emotion || "happy");
      setDialogueText(formatText(choice.reply_th));

      if (!isReplay && ch.arc !== "wedding") {
        state.chroniclesDone[ch.id] = true;
        const statStr = addStatXp(choice.stat || {});
        if (choice.hearts_all) GAME_DATA.characters.characters.forEach(c => addFriendship(c.id, choice.hearts_all));
        for (const [cid, delta] of Object.entries(choice.hearts || {})) addFriendship(cid, delta);
        const rewGold = ch.reward?.gold || 0;
        if (rewGold > 0) addGold(rewGold);
        let itemLbl = "";
        if (ch.reward?.item_id && ITEM_BY_ID[ch.reward.item_id]) {
          state.inventory[ch.reward.item_id] = (state.inventory[ch.reward.item_id] || 0) + 1;
          itemLbl = ` + 🎁 ${ITEM_BY_ID[ch.reward.item_id].name_th}`;
        }
        sfx(ch.id === "main_ch5" ? "concert" : (ch.arc === "mystery" ? "mystery" : "quest"));
        spawnParticles(state.player.x, state.player.y - 24, "#fde047", 24);
        updateStoryBadge(); checkAchievements(); saveGame(true);
        showToast(`📖 จบ "${ch.title_th}"! รับ +${rewGold}G${itemLbl} ${statStr}`);
      } else {
        sfx("heart");
      }
    };

    window.playChronicleChapter = (chId) => {
      const ch = CHRONICLE_BY_ID[chId]; if (!ch) return;
      if (!isChapterUnlocked(ch)) { showToast(`🔒 เงื่อนไขปลดล็อก: ${ch.unlock_hint_th}`); return; }
      const isReplay = !!state.chroniclesDone[ch.id];
      closeModal();
      state.activeDlgNpc = { id: ch.beats[0].speaker };
      activeCutscene = { ch, beatIdx: 0, isReplay, finished: false };
      sfx(ch.arc === "mystery" ? "mystery" : "sparkle");
      renderCutsceneBeat();
    };

    window.openStoryModal = (tab = "main") => {
      const seals = getAwakenedSealCount();
      const countArc = (arc) => CHRONICLES.filter(c => c.arc === arc && state.chroniclesDone[c.id]).length;
      const totalArc = (arc) => CHRONICLES.filter(c => c.arc === arc).length;
      const tabsHtml = `<div class="tab-bar">
        <button class="sd-btn ${tab==='main'?'active':''}" onclick="window.openStoryModal('main')">🌳 เนื้อเรื่องหลัก (${countArc('main')}/${totalArc('main')})</button>
        <button class="sd-btn ${tab==='mystery'?'active':''}" onclick="window.openStoryModal('mystery')">🕵️ 3 คดีสืบสวน (${countArc('mystery')}/${totalArc('mystery')})</button>
        <button class="sd-btn ${tab==='matchmaker'?'active':''}" onclick="window.openStoryModal('matchmaker')">💞 3 คู่จิ้น (${countArc('matchmaker')}/${totalArc('matchmaker')})</button>
        <button class="sd-btn ${tab==='seasonal'?'active':''}" onclick="window.openStoryModal('seasonal')">❄️ 4 ฤดู (${countArc('seasonal')}/${totalArc('seasonal')})</button>
        <button class="sd-btn ${tab==='seals'?'active':''}" onclick="window.openStoryModal('seals')">✨ ตรา 8 เผ่า (${seals}/8)</button>
      </div>`;
      let body = "";
      if (tab === "seals") {
        body = STORY_SEALS.map(s => {
          const bestH = Math.max(...s.members.map(cid => getHearts(cid)));
          const ok = bestH >= 3;
          const names = s.members.map(cid => `${CHAR_BY_ID[cid]?.name_th} (${getHearts(cid)}❤️)`).join(" • ");
          return `<div class="card-row ${ok ? '' : 'locked'}" style="${ok ? 'border-color:#15803d;background:#f0fdf4;' : ''}">
            <div>
              <div style="font-weight:800;font-size:13.5px;">${s.icon} ${s.name_th} ${ok ? '<span class="badge" style="background:#dcfce7;color:#15803d;">✨ ตื่นแล้ว!</span>' : `<span class="badge">ต้องการ 3 ❤️ (${bestH}/3)</span>`}</div>
              <div style="font-size:11.5px;color:#5c3312;">${s.lore_th} • 👥 ${names}</div>
            </div>
          </div>`;
        }).join("");
      } else {
        body = CHRONICLES.filter(c => c.arc === tab).map(ch => {
          const done = !!state.chroniclesDone[ch.id], unlocked = isChapterUnlocked(ch);
          return `<div class="card-row ${unlocked ? '' : 'locked'}" style="${done ? 'border-color:#15803d;background:#f0fdf4;' : ''}">
            <div>
              <div style="font-weight:800;font-size:13.5px;">${ch.icon} ${ch.title_th} ${done ? '<span class="badge" style="background:#dcfce7;color:#15803d;">✓ ผ่านแล้ว</span>' : (unlocked ? '<span class="badge" style="background:#fde047;">✨ พร้อมเล่น</span>' : '<span class="badge">🔒 ล็อกอยู่</span>')}</div>
              <div style="font-size:11.5px;color:#5c3312;">${ch.subtitle_th} • ${unlocked ? `🎁 +${ch.reward?.gold || 0}G` : `📌 ${ch.unlock_hint_th}`}</div>
            </div>
            <button class="sd-btn ${done ? 'blue' : (unlocked ? 'green' : '')}" ${unlocked ? '' : 'disabled'} onclick="window.playChronicleChapter('${ch.id}')">${done ? '↺ ย้อนดู' : '▶ เล่นคัตซีน'}</button>
          </div>`;
        }).join("");
      }
      openModal("📖 พงศาวดารแห่งเอเธลการ์ด (4 เส้นเรื่อง • 15 บท)", tabsHtml + body);
    };

    window.trackLandmark = (lmId) => {
      const lm = LANDMARK_BY_ID[lmId]; if (!lm) return;
      state.compassNpcId = null; state.compassLandmarkId = lmId;
      document.getElementById("compassBox").style.display = "block";
      document.getElementById("compassLabel").textContent = `🧭 ${lm.icon} ${lm.name_th}`;
      closeModal();
      showToast(`🧭 กำลังนำทางไปยัง ${lm.icon} ${lm.name_th}!`);
    };

    window.buildLandmark = (lmId) => {
      const lm = LANDMARK_BY_ID[lmId];
      if (!lm || state.landmarksBuilt[lmId]) return;
      if (state.gold < lm.gold_cost) { showToast(`🪙 เงินไม่พอ! ต้องการ ${lm.gold_cost} G`); return; }
      for (const [iid, req] of Object.entries(lm.materials || {})) {
        if ((state.inventory[iid] || 0) < req) { showToast(`📦 ต้องการ ${ITEM_BY_ID[iid]?.name_th} x${req}`); return; }
      }
      state.gold -= lm.gold_cost;
      for (const [iid, req] of Object.entries(lm.materials || {})) {
        state.inventory[iid] -= req; if (state.inventory[iid] <= 0) delete state.inventory[iid];
      }
      state.landmarksBuilt[lmId] = true;
      (lm.partners || []).forEach(cid => addFriendship(cid, 45));
      const statStr = addStatXp({ craft: 15, charm: 10 });
      sfx("build");
      updateStoryBadge(); checkAchievements(); saveGame(true);
      showToast(`🎉 บูรณะ "${lm.icon} ${lm.name_th}" สำเร็จแล้ว! (${statStr})`);
      window.openTownModal("landmarks");
    };

    window.donateMuseumItem = (itemId) => {
      if (!state.landmarksBuilt.lm_museum) { showToast("ต้องบูรณะ 📚 พิพิธภัณฑ์ 8 เผ่า ให้เสร็จก่อนนะ!"); return; }
      if (state.museumDonated[itemId] || !state.inventory[itemId]) return;
      state.inventory[itemId]--; if (state.inventory[itemId] <= 0) delete state.inventory[itemId];
      state.museumDonated[itemId] = true;
      addGold(60); addStatXp({ wisdom: 8 });
      addFriendship("02_marcus", 25); addFriendship("14_kael", 25);
      sfx("sparkle");
      const count = Object.keys(state.museumDonated).length;
      MUSEUM_MILESTONES.forEach(ms => {
        if (count >= ms.count && !state.museumMilestonesClaimed[ms.count]) {
          state.museumMilestonesClaimed[ms.count] = true;
          if (ms.gold) addGold(ms.gold);
          if (ms.stat) addStatXp(ms.stat);
          if (ms.item_id) state.inventory[ms.item_id] = (state.inventory[ms.item_id] || 0) + 1;
          if (ms.hearts_all) GAME_DATA.characters.characters.forEach(c => addFriendship(c.id, ms.hearts_all));
          sfx("quest");
        }
      });
      updateStoryBadge(); checkAchievements(); saveGame(true);
      showToast(`📚 บริจาค "${ITEM_BY_ID[itemId]?.name_th}" เข้าพิพิธภัณฑ์แล้ว! (+60G)`);
      window.openTownModal("museum");
    };

    window.useLandmarkAbility = (lmId) => {
      const lm = LANDMARK_BY_ID[lmId]; if (!lm) return;
      if (!state.landmarksBuilt[lmId]) { window.openTownModal("landmarks"); return; }
      if (lmId === "lm_museum") { window.openTownModal("museum"); return; }
      if (lmId === "lm_nightmarket") { window.openNightMarketModal(); return; }
      if (lmId === "lm_stage") {
        // Launch 4-Lane Rhythm Concert Minigame!
        startSpecializedMiniGame("rhythm_stage", "concert", null);
        return;
      }
      if (state.landmarkUsedDay[lmId] === state.day) {
        showToast(`✨ วันนี้ใช้งาน ${lm.icon} ${lm.name_th} ไปแล้ว พรุ่งนี้ค่อยมาใหม่นะ!`);
        return;
      }
      state.landmarkUsedDay[lmId] = state.day;
      if (lmId === "lm_observatory") {
        state.meteorShowerDay = state.day;
        addStatXp({ wisdom: 10 });
        [{ tx: 44, ty: 14, item_id: "item_starfall_crystal" }, { tx: 36, ty: 24, item_id: "item_moonbloom" }, { tx: 50, ty: 24, item_id: "item_aqua_crystal" }]
          .forEach((sp, i) => forageSpots.push({ ...sp, id: `meteor_${state.day}_${i}`, collected: false }));
        sfx("sparkle"); saveGame(true);
        showToast("🔭 ส่องกล้องดูดาวสำเร็จ! คืนนี้เกิดฝนดาวตกและจุดเก็บผลึกหายาก 3 จุด!");
      } else if (lmId === "lm_hotspring") {
        state.stamina = getMaxStamina(); addStatXp({ courage: 6, charm: 4 });
        sfx("splash"); saveGame(true);
        showToast("♨️ แช่บ่อน้ำพุร้อนฟื้นพลังงานเต็ม 100%!");
      }
    };

    window.waitForNightMarket = () => {
      if (state.timeMin < 18 * 60) { state.timeMin = 18 * 60; syncNpcSchedules(); sfx("sparkle"); }
      window.openNightMarketModal();
    };
    window.buyNightMarketItem = (itemId) => {
      const it = ITEM_BY_ID[itemId]; if (!it) return;
      const cal = getCalendarInfo(), isWeekend = cal.dayOfWeekIdx >= 4;
      const gobMult = state.heroCustom.raceKey === "goblin" ? 0.92 : 1.0;
      const price = Math.round(it.price * (isWeekend ? 0.75 : 0.9) * gobMult);
      if (state.gold < price) { showToast("🪙 เงินไม่พอซื้อของชิ้นนี้!"); return; }
      state.gold -= price; state.inventory[itemId] = (state.inventory[itemId] || 0) + 1;
      sfx("coin"); saveGame(true);
      showToast(`🏮 ซื้อ "${it.name_th}" จากตลาดนัดกลางคืน (-${price}G)!`);
      window.openNightMarketModal();
    };
    window.openNightMarketModal = () => {
      const cal = getCalendarInfo(), hr = state.timeMin / 60, isOpen = hr >= 18 || hr < 2;
      if (!isOpen) {
        openModal("🏮 ตลาดนัดกลางคืนรากไม้", `<div class="card-row" style="flex-direction:column;align-items:center;padding:18px;gap:8px;">
          <div style="font-weight:800;font-size:15px;">🌙 ตลาดนัดกลางคืนเปิด 18:00 – 24:00 น.</div>
          <button class="sd-btn active" onclick="window.waitForNightMarket()">⏩ ข้ามเวลาไป 18:00 น. เลย!</button></div>`);
        return;
      }
      const isWeekend = cal.dayOfWeekIdx >= 4, gobMult = state.heroCustom.raceKey === "goblin" ? 0.92 : 1.0;
      const rows = NIGHT_MARKET_STOCK.map(iid => {
        const it = ITEM_BY_ID[iid]; if (!it) return "";
        const price = Math.round(it.price * (isWeekend ? 0.75 : 0.9) * gobMult);
        return `<div class="card-row"><div><b>${itemIconHtml(iid)}${it.name_th}</b> <span class="badge">มี ${state.inventory[iid]||0}</span><div style="font-size:11px;color:#5c3312;">${it.description_th}</div></div><button class="sd-btn green" onclick="window.buyNightMarketItem('${iid}')">🪙 ซื้อ ${price}G</button></div>`;
      }).join("");
      openModal(`🏮 ตลาดนัดกลางคืนรากไม้ (มีเงิน ${state.gold} G)`, rows);
    };

    window.warpToRuinsEntrance = () => {
      closeModal();
      sfx("door");
      transitionScene("ruins_b1", 10, 11, true);
    };
    window.openTownModal = (tab = "landmarks") => {
      const builtCnt = Object.keys(state.landmarksBuilt || {}).length;
      const donatedCnt = Object.keys(state.museumDonated || {}).length;
      const ruinsCnt = ["ruins_b1","ruins_b2","ruins_b3"].filter(k => state.ruins?.[k]?.solved).length;
      const tabsHtml = `<div class="tab-bar">
        <button class="sd-btn ${tab==='landmarks'?'active':''}" onclick="window.openTownModal('landmarks')">🏛️ 5 แลนด์มาร์ก (${builtCnt}/5)</button>
        <button class="sd-btn ${tab==='museum'?'active':''}" onclick="window.openTownModal('museum')">📚 พิพิธภัณฑ์ (${donatedCnt}/${MUSEUM_ITEMS.length})</button>
        <button class="sd-btn ${tab==='ruins'?'active':''}" onclick="window.openTownModal('ruins')">🔦 โบราณสถานรากไม้ (${ruinsCnt}/3 ชั้น)</button>
      </div>`;
      let content = "";
      if (tab === "landmarks") {
        content = LANDMARKS.map(lm => {
          const built = !!state.landmarksBuilt[lm.id];
          let canBuild = state.gold >= lm.gold_cost;
          const matsHtml = Object.entries(lm.materials || {}).map(([iid, req]) => {
            const have = state.inventory[iid] || 0; if (have < req) canBuild = false;
            return `<span style="color:${have>=req?'#15803d':'#b91c1c'};">${ITEM_BY_ID[iid]?.name_th} (${have}/${req})</span>`;
          }).join(" + ");
          return `<div class="card-row"><div><div style="font-weight:800;font-size:13.5px;">${lm.icon} ${lm.name_th} ${built ? '<span class="badge" style="background:#ccfbf1;color:#0f766e;">✨ สร้างแล้ว</span>' : ''}</div><div style="font-size:11.5px;color:#5c3312;">${lm.summary_th}</div>${built ? '' : `<div style="font-size:11px;font-weight:700;">🪙 ${lm.gold_cost}G + ${matsHtml}</div>`}</div><div style="display:flex;gap:4px;">${built ? `<button class="sd-btn green" onclick="window.closeModal();window.useLandmarkAbility('${lm.id}')">✨ ใช้งาน</button>` : `<button class="sd-btn ${canBuild?'green':''}" ${canBuild?'':'disabled'} onclick="window.buildLandmark('${lm.id}')">🔨 บูรณะ</button>`}<button class="sd-btn blue" onclick="window.trackLandmark('${lm.id}')">🧭</button></div></div>`;
        }).join("");
      } else if (tab === "museum") {
        const musBuilt = !!state.landmarksBuilt.lm_museum;
        content = MUSEUM_ITEMS.map(m => {
          const it = ITEM_BY_ID[m.item_id], done = !!state.museumDonated[m.item_id], have = state.inventory[m.item_id] || 0;
          return `<div class="card-row ${done?'':(have>0&&musBuilt?'':'locked')}"><div><b>${itemIconHtml(m.item_id)}${it?.name_th}</b> ${done?'<span class="badge">✓ จัดแสดงแล้ว</span>':`<span class="badge">มี ${have}</span>`}<div style="font-size:11px;color:#5c3312;">${m.lore_th}</div></div>${done?'<span class="badge">✨</span>':`<button class="sd-btn ${have>0&&musBuilt?'green':''}" ${have>0&&musBuilt?'':'disabled'} onclick="window.donateMuseumItem('${m.item_id}')">🏛️ บริจาค</button>`}</div>`;
        }).join("");
      } else {
        content = `<div class="card-row" style="background:#f0fdfa;border-color:#0f766e;"><div><div style="font-weight:800;font-size:13.5px;">🔦 โบราณสถานใต้รากไม้โลก (Under-Root Sanctum B1–B3)</div><div style="font-size:11.5px;color:#134e4a;">เดินเข้าทางรากต้นไม้โลกฝั่งตะวันตก หรือกดปุ่มด้านขวาเพื่อลงไปไขปริศนาเสาแสงสะท้อนปริซึม ขุดแร่มานาประจำวัน และรับแหวนสายใยรากไม้โลกในชั้น B3!</div></div><button class="sd-btn green" onclick="window.warpToRuinsEntrance()">🔦 ลงสู่ชั้น B1 เลย!</button></div>` +
          Object.values(RUINS_FLOORS).map(fl => {
            const rs = state.ruins[fl.id] || {};
            return `<div class="card-row"><div><div style="font-weight:800;font-size:13px;">${fl.name} ${rs.solved ? '<span class="badge" style="background:#dcfce7;color:#15803d;">✓ ปลดผนึกแสงแล้ว</span>' : '<span class="badge">🔒 รอไขปริศนาเสาแสง</span>'}</div><div style="font-size:11.5px;color:#5c3312;">เสาปริซึม ${fl.pillars.length} ต้น • แท่นรับแสง ${fl.receptors.length} จุด • หีบสมบัติ: ${rs.chestOpened ? '✓ เปิดรับแล้ว' : `+${fl.chest.gold}G & ของหายาก!`}</div></div></div>`;
          }).join("");
      }
      openModal("🏛️ ศูนย์บูรณะเมือง พิพิธภัณฑ์ & โบราณสถานใต้รากไม้", tabsHtml + content);
    };

    // CRAFTING, MAILBOX, 6-MINIGAME JOBS, SHOPS + 2ND FLOOR LOFT!
    window.craftRecipe = (recId) => {
      const rec = CRAFT_RECIPES.find(r => r.id === recId); if (!rec) return;
      for (const [iid, req] of Object.entries(rec.ingredients)) {
        if ((state.inventory[iid] || 0) < req) { showToast("วัตถุดิบไม่พอ! ลองเดินเก็บของป่า ตกปลา หรือลงโบราณสถานดูนะ"); return; }
      }
      const cost = getStaminaCost(6);
      if (state.stamina < cost) { showToast(`⚡ พลังงานไม่พอ (ต้องใช้ ${cost} ⚡)`); return; }
      state.stamina -= cost;
      if (state.heroCustom.raceKey === "beastkin") {
        state.stamina = Math.min(getMaxStamina(), state.stamina + 8);
      }
      for (const [iid, req] of Object.entries(rec.ingredients)) {
        state.inventory[iid] -= req; if (state.inventory[iid] <= 0) delete state.inventory[iid];
      }
      state.inventory[rec.out_id] = (state.inventory[rec.out_id] || 0) + 1;
      state.craftedCount = (state.craftedCount || 0) + 1;
      state.dailyLog.craftsMade++;
      const statStr = addStatXp(rec.stat);
      sfx("sparkle");
      const outItem = ITEM_BY_ID[rec.out_id];
      checkAchievements(); updateQuestTrackerHud(); saveGame(true);
      showToast(`🍳 สร้าง "${outItem?.name_th}" สำเร็จ! (${statStr})${state.heroCustom.raceKey==='beastkin'?' • 🐾 โบนัสเผ่าสัตว์ +8⚡!':''}`);
      window.openCraftModal();
    };
    window.openCraftModal = () => {
      const rows = CRAFT_RECIPES.map(r => {
        const out = ITEM_BY_ID[r.out_id]; let canCraft = true;
        const ingText = Object.entries(r.ingredients).map(([iid, req]) => {
          const have = state.inventory[iid] || 0; if (have < req) canCraft = false;
          return `<span style="color:${have>=req?'#15803d':'#b91c1c'};">${itemIconHtml(iid, 18)}${ITEM_BY_ID[iid]?.name_th} (${have}/${req})</span>`;
        }).join(" + ");
        return `<div class="card-row ${canCraft?'':'locked'}"><div><div style="font-weight:800;font-size:13.5px;">${itemIconHtml(r.out_id)}${r.name_th} <span class="badge">ขาย ${out?.sell_price||60}G</span></div><div style="font-size:11.5px;font-weight:700;">📦 ${ingText}</div><div style="font-size:11px;color:#5c3312;">${out?.description_th||""}</div></div><button class="sd-btn ${canCraft?'green':''}" ${canCraft?'':'disabled'} onclick="window.craftRecipe('${r.id}')">🍳 สร้าง</button></div>`;
      }).join("");
      openModal("🍳 โต๊ะทำอาหาร คราฟต์ของขวัญ & ตีแหวนแต่งงาน (11 สูตร)", rows);
    };

    window.claimMail = (mailId) => {
      const m = state.mailbox.find(x => x.id === mailId); if (!m) return;
      m.read = true;
      if (!m.claimed) {
        m.claimed = true;
        if (m.gift_id) state.inventory[m.gift_id] = (state.inventory[m.gift_id] || 0) + 1;
        if (m.gold) addGold(m.gold);
        sfx("coin"); saveGame(true);
        showToast("🎁 รับของขวัญจากจดหมายเรียบร้อย!");
      }
      updateMailBadge(); window.openMailboxModal();
    };
    window.openMailboxModal = () => {
      state.mailbox.forEach(m => { m.read = true; }); updateMailBadge();
      const rows = !state.mailbox.length ? `<div class="card-row">ยังไม่มีจดหมายใหม่</div>` : state.mailbox.map(m => {
        const hasReward = !m.claimed && (m.gift_id || m.gold);
        return `<div class="card-row ${m.claimed?'locked':''}" style="flex-direction:column;align-items:stretch;">
          <div style="display:flex;justify-content:space-between;"><b>✉️ ${formatText(m.title)}</b><span class="badge">จาก: ${m.sender}</span></div>
          <div style="font-size:12px;margin:4px 0;">${formatText(m.body)}</div>
          <div style="display:flex;justify-content:space-between;align-items:center;"><span style="font-size:11.5px;font-weight:800;color:#15803d;">${m.gift_id?`🎁 ${ITEM_BY_ID[m.gift_id]?.name_th}`:''} ${m.gold?`🪙 ${m.gold}G`:''}</span>${hasReward?`<button class="sd-btn green" onclick="window.claimMail('${m.id}')">🎁 รับของแนบ</button>`:'<span class="badge">✓ รับแล้ว</span>'}</div>
        </div>`;
      }).join("");
      openModal("📮 ตู้จดหมายหน้าบ้านพักตัวเอก", rows);
    };

    window.doPartTimeJob = (jobId) => {
      const job = GAME_DATA.jobs.jobs.find(j => j.id === jobId); if (!job) return;
      if (state.workedToday[jobId]) { showToast("วันนี้ทำกะงานนี้ไปแล้ว ลองงานสายอื่นดูนะ!"); return; }
      const craftLv = getStatLevelInfo("craft").level;
      const cost = getStaminaCost((job.bonus_stat === "craft" && craftLv >= 4) ? Math.round(job.energy_cost * 0.8) : job.energy_cost);
      if (state.stamina < cost) { showToast(`⚡ พลังงานไม่พอ (ต้องใช้ ${cost} ⚡)`); return; }
      closeModal();
      startSpecializedMiniGame(getJobMiniGameKind(job.id), "job", job);
    };

    function openJobsModal() {
      const mgLabels = {
        forge_heat: "🔥 มินิเกมคุมไฟ & ตีจังหวะ",
        order_rush: "🍺 มินิเกมจับคู่ออเดอร์ด่วน",
        rune_memory: "🌿 มินิเกมจำลำดับรูนเวท",
        sky_dash: "🪽 มินิเกมวิ่งเก็บพัสดุหลบหิน"
      };
      const rows = GAME_DATA.jobs.jobs.map(j => {
        const emp = CHAR_BY_ID[j.employer_id], done = !!state.workedToday[j.id];
        const kind = getJobMiniGameKind(j.id);
        return `<div class="card-row ${done?'locked':''}">
          <div>
            <div style="font-weight:800;font-size:13.5px;">${j.title_th} <span class="badge" style="background:#dbeafe;color:#1e40af;">${mgLabels[kind]}</span></div>
            <div style="font-size:11.5px;color:#5c3312;">${j.description_th}</div>
            <div style="font-size:11px;font-weight:700;color:#7c2d12;">👤 ${emp?.name_th} • ⚡-${j.energy_cost} • 🪙 ${j.base_pay_gold}G (Rank S x1.5!)</div>
          </div>
          <button class="sd-btn ${done?'':'green'}" ${done?'disabled':''} onclick="window.doPartTimeJob('${j.id}')">${done?'✓ ทำแล้ว':'🎮 เริ่มงาน'}</button>
        </div>`;
      }).join("");
      openModal("💼 งานพาร์ทไทม์ 8 อาชีพ (แยกสายมินิเกมเฉพาะทาง!)", rows);
    }

    window.upgradeHouseSecondFloor = () => {
      if (state.houseLevel >= 2) return;
      if (state.gold < 600) { showToast("🪙 เงินไม่พอ! ต้องการ 600 G เพื่อต่อเติมชั้น 2"); return; }
      if ((state.inventory.item_hard_oak || 0) < 2) { showToast("🪵 ต้องการ 'ไม้โอ๊กเนื้อแข็ง' x2 ชิ้น (ซื้อที่ร้านพิป หรือเก็บในหุบเขา)"); return; }
      state.gold -= 600;
      state.inventory.item_hard_oak -= 2;
      if (state.inventory.item_hard_oak <= 0) delete state.inventory.item_hard_oak;
      state.houseLevel = 2;
      sfx("build");
      addStatXp({ craft: 20, charm: 15 });
      renderSocialStatsHud(); checkAchievements(); saveGame(true);
      showToast("🌟 ต่อเติม 'ชั้น 2 ห้องใต้หลังคาชมดาว (Starlight Loft)' สำเร็จแล้ว! เดินขึ้นบันไดมุมขวาบนในบ้านได้เลย!");
      window.openShopBagModal("decor");
    };

    window.buyDecor = (decorId) => {
      const d = DECOR_BY_ID[decorId];
      if (!d || state.decorOwned[decorId]) return;
      const gobMult = state.heroCustom.raceKey === "goblin" ? 0.92 : 1.0;
      const price = Math.round(d.price * gobMult);
      if (state.gold < price) { showToast("🪙 เงินไม่พอซื้อเฟอร์นิเจอร์ชิ้นนี้!"); return; }
      state.gold -= price;
      state.decorOwned[decorId] = true;
      // Auto-place on default tile if valid, otherwise store ready for [H] grid placement!
      if (d.defaultPos && (d.defaultPos.scene === "farmhouse" || state.houseLevel >= 2)) {
        if (canPlaceDecorAt(d.id, d.defaultPos.scene, d.defaultPos.x, d.defaultPos.y, d.w, d.h)) {
          state.decorPlaced.push({ id: d.id, scene: d.defaultPos.scene, x: d.defaultPos.x, y: d.defaultPos.y, w: d.w, h: d.h });
        }
      }
      state.selectedDecorId = d.id;
      sfx("coin"); renderSocialStatsHud(); checkAchievements(); saveGame(true);
      showToast(`🛋️ ซื้อ "${d.icon} ${d.name_th}" แล้ว! กด [H] ในบ้านเพื่อย้ายวางบนตารางได้ตามใจชอบ!`);
      window.openShopBagModal("decor");
    };

    window.switchPet = (kind) => {
      if (!PET_TYPES[kind]) return;
      state.pet.kind = kind; sfx("heart"); saveGame(true);
      showToast(`🐾 เปลี่ยนคู่หูเป็น ${PET_TYPES[kind].name_th} แล้ว!`);
      window.openShopBagModal("decor");
    };

    function getShopDiscountMult() {
      const cal = getCalendarInfo();
      return (getStatLevelInfo("charm").level >= 3 ? 0.9 : 1.0) * (cal.dayOfSeason === 21 ? 0.8 : 1.0) * (state.heroCustom.raceKey === "goblin" ? 0.92 : 1.0);
    }
    window.buyItem = (itemId) => {
      const it = ITEM_BY_ID[itemId]; if (!it) return;
      const price = Math.round(it.price * getShopDiscountMult());
      if (state.gold < price) { showToast("🪙 เงินไม่พอ!"); return; }
      state.gold -= price; state.inventory[itemId] = (state.inventory[itemId] || 0) + 1;
      sfx("coin"); updateQuestTrackerHud(); saveGame(true);
      showToast(`🛍️ ซื้อ "${it.name_th}" (-${price}G) เข้ากระเป๋าแล้ว!`);
      window.openShopBagModal(window._shopTab || "bag");
    };
    window.sellItem = (itemId) => {
      const it = ITEM_BY_ID[itemId]; if (!it || !state.inventory[itemId]) return;
      state.inventory[itemId]--; if (state.inventory[itemId] <= 0) delete state.inventory[itemId];
      const mult = (state.museumMilestonesClaimed?.[9] ? 1.2 : 1.0) * (state.heroCustom.raceKey === "goblin" ? 1.1 : 1.0);
      const gain = Math.round(it.sell_price * mult);
      addGold(gain); sfx("coin"); checkAchievements(); updateQuestTrackerHud(); saveGame(true);
      showToast(`💰 ขาย "${it.name_th}" ได้รับ +${gain} G!`);
      window.openShopBagModal("bag");
    };
    window.eatItem = (itemId) => {
      const it = ITEM_BY_ID[itemId]; if (!it || !state.inventory[itemId] || it.energy_restore <= 0) return;
      state.inventory[itemId]--; if (state.inventory[itemId] <= 0) delete state.inventory[itemId];
      state.stamina = Math.min(getMaxStamina(), state.stamina + it.energy_restore);
      sfx("heart"); saveGame(true);
      showToast(`😋 กิน "${it.name_th}" ฟื้นพลัง +${it.energy_restore} ⚡!`);
      window.openShopBagModal("bag");
    };

    window.openShopBagModal = (tab = "bag") => {
      window._shopTab = tab;
      const shops = [
        { id: "bag", label: "🎒 กระเป๋า" }, { id: "decor", label: "🛋️ แต่งบ้านตาราง & ชั้น 2" },
        { id: "shop", label: "🏪 ร้านชำ" }, { id: "bakery", label: "🥐 ขนมปัง" },
        { id: "tavern", label: "🍺 โรงเตี๊ยม" }, { id: "cottage", label: "🌿 สมุนไพร" }, { id: "smithy", label: "⚒️ ตีเหล็ก" }
      ];
      const tabsHtml = `<div class="tab-bar">${shops.map(s => `<button class="sd-btn ${tab===s.id?'active':''}" onclick="window.openShopBagModal('${s.id}')">${s.label}</button>`).join("")}</div>`;
      let content = "";
      if (tab === "bag") {
        const entries = Object.entries(state.inventory).filter(([,q]) => q > 0);
        content = !entries.length ? `<div class="card-row">กระเป๋าว่างเปล่า</div>` : entries.map(([id, qty]) => {
          const it = ITEM_BY_ID[id]; if (!it) return "";
          return `<div class="card-row"><div><b>${itemIconHtml(id)}${it.name_th}</b> <span class="badge">x${qty}</span><div style="font-size:11px;color:#5c3312;">${it.description_th}</div></div><div style="display:flex;gap:4px;">${it.energy_restore>0?`<button class="sd-btn green" onclick="window.eatItem('${id}')">🍽️ +${it.energy_restore}⚡</button>`:""}<button class="sd-btn" onclick="window.sellItem('${id}')">💰 ขาย ${it.sell_price}G</button></div></div>`;
        }).join("");
      } else if (tab === "decor") {
        const haveOak = state.inventory.item_hard_oak || 0;
        const loftRow = `<div class="card-row" style="background:${state.houseLevel>=2?'#f0fdf4':'#fef9c3'};border:2px solid ${state.houseLevel>=2?'#15803d':'#ca8a04'};">
          <div>
            <div style="font-weight:800;font-size:14px;">🌟 ขยายต่อเติมชั้น 2: ห้องใต้หลังคาชมดาว (Starlight Loft 14×10) ${state.houseLevel>=2?'<span class="badge" style="background:#dcfce7;color:#15803d;">✓ สร้างแล้ว!</span>':''}</div>
            <div style="font-size:11.5px;color:#5c3312;">ปลดล็อกบันไดขึ้นชั้น 2 ในบ้าน พื้นที่วางเฟอร์นิเจอร์เพิ่ม พลังงานสูงสุด +15⚡ และห้องหอชมดาวกับคู่สมรส! ${state.houseLevel>=2?'':`(ใช้ 600G + ไม้โอ๊กเนื้อแข็ง ${haveOak}/2)`}</div>
          </div>
          ${state.houseLevel>=2 ? (isHomeScene() ? `<button class="sd-btn active" onclick="window.closeModal();window.toggleHomeEditMode(true)">🛋️ เปิดโหมดจัดตาราง [H]</button>` : `<span class="badge">✨ พร้อมใช้งาน</span>`) : `<button class="sd-btn green" onclick="window.upgradeHouseSecondFloor()">🔨 ต่อเติมชั้น 2 (600G)</button>`}
        </div>`;
        const editHint = isHomeScene() ? `<div class="card-row" style="background:#eff6ff;border-color:#2563eb;"><div><b>🛋️ คุณกำลังอยู่ในบ้านพัก!</b> กดปุ่มขวาหรือกด <b>[H]</b> เพื่อลากวางเฟอร์นิเจอร์บนช่องตารางพื้นห้อง หมุน [R] หรือเก็บเข้าคลังได้อิสระ</div><button class="sd-btn blue" onclick="window.closeModal();window.toggleHomeEditMode(true)">🛠️ จัดวางบนตารางเลย!</button></div>` : "";
        const petRow = `<div class="card-row"><div><b>🐾 สัตว์เลี้ยงคู่ใจ:</b></div><div style="display:flex;gap:5px;">${Object.entries(PET_TYPES).map(([k,p]) => `<button class="sd-btn ${state.pet.kind===k?'active':''}" onclick="window.switchPet('${k}')">${p.icon} ${p.name_th}</button>`).join("")}</div></div>`;
        const gobMult = state.heroCustom.raceKey === "goblin" ? 0.92 : 1.0;
        content = loftRow + editHint + petRow + HOME_DECOR.map(d => {
          const owned = !!state.decorOwned[d.id], placed = (state.decorPlaced||[]).find(p => p.id === d.id);
          const price = Math.round(d.price * gobMult);
          return `<div class="card-row"><div><div style="font-weight:800;font-size:13px;">${d.icon} ${d.name_th} <span class="badge">ขนาด ${d.w}×${d.h} ช่อง</span> ${owned ? (placed ? `<span class="badge" style="background:#dcfce7;color:#15803d;">วางที่ ${placed.scene==='farmhouse_upstairs'?'ชั้น 2':'ชั้น 1'}</span>` : '<span class="badge">ในคลัง</span>') : ''}</div><div style="font-size:11.5px;color:#15803d;font-weight:700;">✨ ${d.perk_th}</div></div>${owned ? (isHomeScene() ? `<button class="sd-btn active" onclick="window.closeModal();state.selectedDecorId='${d.id}';window.toggleHomeEditMode(true)">📐 เลือกวาง</button>` : '<span class="badge">เป็นเจ้าของ</span>') : `<button class="sd-btn green" onclick="window.buyDecor('${d.id}')">🪙 ซื้อ ${price}G</button>`}</div>`;
        }).join("");
      } else {
        const disc = getShopDiscountMult();
        content = GAME_DATA.items.items.filter(it => it.shop_id === tab).map(it => {
          const price = Math.round(it.price * disc), owned = state.inventory[it.id] || 0;
          return `<div class="card-row"><div><b>${itemIconHtml(it.id)}${it.name_th}</b> ${owned?`<span class="badge">มี ${owned}</span>`:""} ${it.energy_restore?`<span class="badge">⚡+${it.energy_restore}</span>`:""}<div style="font-size:11px;color:#5c3312;">${it.description_th}</div></div><button class="sd-btn green" onclick="window.buyItem('${it.id}')">🪙 ซื้อ ${price}G</button></div>`;
        }).join("");
      }
      openModal(`🛍️ ร้านค้า กระเป๋า & แต่งบ้าน (มีเงิน ${state.gold} G)`, tabsHtml + content);
    };

    // GIFTS, HANGOUT, HEART EVENTS, CONFESSION, RELATIONSHIPS, QUESTS, CALENDAR
    window.giveSpecificGift = (cid, itemId) => {
      const it = ITEM_BY_ID[itemId], ch = CHAR_BY_ID[cid], dlg = GAME_DATA.dialogues.dialogues[cid];
      if (!it || !ch || !state.inventory[itemId]) return;
      if (itemId === "item_world_tree_ring" && state.partners[cid] && !state.spouseId && getHearts(cid) >= 10) {
        closeModal();
        triggerMarriageProposal(cid);
        return;
      }
      state.inventory[itemId]--; if (state.inventory[itemId] <= 0) delete state.inventory[itemId];
      state.relations[cid].giftedToday = true;
      let tier = "neutral", delta = 25;
      if (ch.gifts.loved.includes(it.name_th) || itemId === "item_world_tree_ring") { tier = "loved"; delta = 85; }
      else if (ch.gifts.liked.includes(it.name_th)) { tier = "liked"; delta = 45; }
      else if (ch.gifts.disliked.includes(it.name_th)) { tier = "disliked"; delta = -20; }
      const isBday = NPC_BIRTHDAYS[cid] === getCalendarInfo().dayOfSeason;
      if (isBday && delta > 0) delta *= 2;
      const gained = addFriendship(cid, delta);
      if (tier === "loved") addStatXp({ charm: 8 });
      sfx("heart"); closeModal(); updateDialogueHeader(cid);
      drawPortrait(cid, tier === "disliked" ? "sad" : (tier === "loved" && ch.romanceable ? "blush" : "happy"));
      setDialogueText((isBday ? "🎂 จำวันเกิดฉันได้ด้วยเหรอ!! " : "") + formatText(dlg?.gift_reactions?.[tier] || `ขอบคุณสำหรับ ${it.name_th} นะ!`));
      saveGame(true);
      showToast(`🎁 มอบ "${it.name_th}" ให้ ${ch.name_th} (${gained >= 0 ? "+" : ""}${gained} ❤️)`);
    };
    function openGiftPicker(cid) {
      const ch = CHAR_BY_ID[cid];
      if (state.relations[cid]?.giftedToday) { showToast(`วันนี้มอบของขวัญให้ ${ch.name_th} ไปแล้ว พรุ่งนี้ค่อยให้ใหม่นะ!`); return; }
      const entries = Object.entries(state.inventory).filter(([,q]) => q > 0);
      if (!entries.length) { showToast("🎒 ไม่มีของในกระเป๋า!"); return; }
      const rows = entries.map(([id, qty]) => {
        const it = ITEM_BY_ID[id], isLoved = ch.gifts.loved.includes(it.name_th);
        return `<div class="card-row"><div><b>${itemIconHtml(id)}${it.name_th}</b> <span class="badge">x${qty}</span> ${isLoved?'<span class="badge" style="background:#fce7f3;color:#9d174d;">💖 ของโปรด</span>':''}</div><button class="sd-btn green" onclick="window.giveSpecificGift('${cid}','${id}')">🎁 มอบให้</button></div>`;
      }).join("");
      openModal(`🎁 เลือกของขวัญมอบให้ ${ch.name_th}`, rows);
    }

    window.doHangout = (cid, spotId) => {
      const spot = GAME_DATA.events.hangout_spots.find(s => s.id === spotId), ch = CHAR_BY_ID[cid];
      if (!spot || !ch) return;
      const cost = getStaminaCost(15);
      if (state.gold < spot.cost_gold || state.stamina < cost) { showToast("เงินหรือพลังงานไม่พอสำหรับ Hangout!"); return; }
      state.gold -= spot.cost_gold; state.stamina -= cost;
      const isFav = spot.favorite_of.includes(cid), xpGain = Math.round(spot.base_hearts_xp * (isFav ? 1.65 : 1.0));
      addFriendship(cid, xpGain); const statStr = addStatXp(spot.stat_gain);
      advanceHours(2); sfx("heart"); closeModal(); updateDialogueHeader(cid);
      drawPortrait(cid, (isFav && ch.romanceable) ? "blush" : "happy");
      setDialogueText(`บรรยากาศที่ "${spot.name_th}" ดีจังเลย ขอบคุณที่ชวนมานะ ${state.playerName}! 💖 (+${xpGain} แต้มหัวใจ)`);
      saveGame(true);
      showToast(`☕ Hangout กับ ${ch.name_th}! (+${xpGain}❤️ ${statStr})`);
    };
    function openHangoutModal(cid) {
      const ch = CHAR_BY_ID[cid];
      const rows = GAME_DATA.events.hangout_spots.map(s => `<div class="card-row"><div><b>${s.name_th}</b> ${s.favorite_of.includes(cid)?'<span class="badge" style="background:#fce7f3;color:#9d174d;">⭐ จุดโปรด!</span>':''}<div style="font-size:11px;color:#5c3312;">📍 ${s.location_th} • 🪙 ${s.cost_gold||'ฟรี'}</div></div><button class="sd-btn pink" onclick="window.doHangout('${cid}','${s.id}')">☕ ชวนไป</button></div>`).join("");
      openModal(`☕ ชวน ${ch.name_th} ไป Hangout / เดต`, rows);
    }

    function playHeartEvent(ev) {
      const ch = CHAR_BY_ID[ev.character_id];
      document.getElementById("dialogueOverlay").style.display = "block";
      document.getElementById("dlgName").textContent = `💖 อีเวนต์หัวใจ: ${ev.title_th}`;
      document.getElementById("dlgMeta").textContent = `${ch.name_th} • ${ev.location_th}`;
      setDialogueText(formatText(ev.intro_th)); drawPortrait(ev.character_id, "neutral");
      document.getElementById("dlgActions").style.display = "none";
      const box = document.getElementById("dlgChoices"); box.style.display = "flex";
      box.innerHTML = ev.choices.map((c, idx) => `<button class="choice-btn" data-idx="${idx}">▸ ${c.text_th}</button>`).join("");
      box.querySelectorAll(".choice-btn").forEach(btn => {
        btn.addEventListener("click", () => {
          const choice = ev.choices[Number(btn.dataset.idx)];
          state.playedEvents[ev.id] = true;
          const fp = addFriendship(ev.character_id, choice.friendship_delta), statStr = addStatXp(choice.stat_delta);
          box.style.display = "none"; document.getElementById("dlgActions").style.display = "flex";
          updateDialogueHeader(ev.character_id); drawPortrait(ev.character_id, choice.friendship_delta < 0 ? "sad" : "blush");
          setDialogueText(formatText(choice.reply_th));
          sfx("quest"); checkAchievements(); saveGame(true);
          showToast(`💖 จบอีเวนต์ "${ev.title_th}" (+${fp}❤️ ${statStr})`);
        });
      });
    }

    function triggerConfession(cid) {
      const ch = CHAR_BY_ID[cid]; if (!ch) return;
      state.partners[cid] = true; addFriendship(cid, 120); addStatXp({ charm: 15, courage: 15 });
      sfx("quest"); spawnParticles(state.player.x, state.player.y - 20, "#f472b6", 24);
      updateDialogueHeader(cid); drawPortrait(cid, "blush");
      setDialogueText(`💍 "${state.playerName}... ฉันก็รักเธอเหมือนกัน! พอความสัมพันธ์เราถึง 10 ❤️ นำ 'แหวนสายใยรากไม้โลก' มาขอฉันแต่งงานที่ใต้ต้นไม้โลกนะ 💕"`);
      checkAchievements(); saveGame(true);
      showToast(`💍 สารภาพรักสำเร็จ! คุณและ ${ch.name_th} เป็นคู่รักกันแล้ว! (10❤️ ขอแต่งงานได้!)`);
    }

    window.trackNpc = (cid) => {
      state.compassNpcId = cid; state.compassLandmarkId = null;
      const c = CHAR_BY_ID[cid], n = NPCS.find(x => x.id === cid);
      const loc = n ? (SCENE_NAMES_TH[n.scene] || n.scene) : "ในเมือง";
      document.getElementById("compassBox").style.display = "block";
      document.getElementById("compassLabel").textContent = `🧭 ${c?.name_th}: ${loc}`;
      closeModal();
      showToast(`🧭 กำลังนำทางไปยัง ${c?.name_th} (${loc})`);
    };
    window.clearCompass = () => { state.compassNpcId = null; state.compassLandmarkId = null; document.getElementById("compassBox").style.display = "none"; };
    window.triggerEventFromDir = (evId) => {
      const ev = GAME_DATA.events.heart_events.find(e => e.id === evId); if (!ev) return;
      closeModal(); state.activeDlgNpc = NPCS.find(n => n.id === ev.character_id) || { id: ev.character_id }; playHeartEvent(ev);
    };

    function openRelationshipsModal() {
      const spouseBanner = state.spouseId
        ? `<div class="card-row" style="background:#fdf2f8;border:2px solid #db2777;"><div><div style="font-weight:800;font-size:13.5px;">💒 ชีวิตคู่สมรสกับ ${CHAR_BY_ID[state.spouseId]?.name_th}</div><div style="font-size:11.5px;color:#831843;">อาศัยอยู่ด้วยกันที่ ${state.cottageName} • รับมื้อเช้าฟรีทุกวัน (+25⚡) และชวนเดตชมดาวฟื้นพลัง 100%!</div></div><button class="sd-btn pink" onclick="window.trackNpc('${state.spouseId}')">🧭 หาคู่สมรส</button></div>`
        : `<div class="card-row" style="background:#fffbeb;border-color:#d97706;"><div style="font-size:12px;">💡 <b>ระบบความรัก & แต่งงาน:</b> จีบตัวละครให้ถึง <b>6 ❤️</b> เพื่อสารภาพรัก และเมื่อถึง <b>10 ❤️</b> พร้อมมี 💍 <b>แหวนสายใยรากไม้โลก</b> จะขอแต่งงานจัดพิธีวิวาห์ใต้ต้นไม้โลกได้!</div></div>`;
      const rows = GAME_DATA.characters.characters.map(c => {
        const h = getHearts(c.id), xp = state.relations[c.id]?.xp || 0, ev = getUnlockedEventForNpc(c.id);
        const n = NPCS.find(x => x.id === c.id), loc = n ? (SCENE_NAMES_TH[n.scene] || n.scene) : c.home;
        const relTag = state.spouseId === c.id ? '<span class="badge" style="background:#fef08a;color:#854d0e;">💒 คู่สมรส</span>'
          : (state.partners[c.id] ? '<span class="badge" style="background:#fce7f3;color:#9d174d;">💑 คู่รัก</span>' : '');
        return `<div class="card-row"><div><div style="font-weight:800;font-size:13.5px;">${c.name_th} ${relTag} <span class="badge">${c.race_th} • 🎂 วันที่ ${NPC_BIRTHDAYS[c.id]}</span></div><div style="font-size:12px;">${"❤️".repeat(Math.min(5,h))}${h>5?` +${h-5}💖`:"🤍".repeat(Math.max(0,5-h))} <span style="font-size:11px;color:#7c2d12;">(${xp}/1000) • 📍 ${loc}</span></div><div style="font-size:11px;color:#5c3312;">💖 ชอบมาก: ${c.gifts.loved.join(", ")}</div></div><div style="display:flex;gap:4px;">${ev?`<button class="sd-btn active" onclick="window.triggerEventFromDir('${ev.id}')">💖 อีเวนต์</button>`:""}${n?`<button class="sd-btn blue" onclick="window.trackNpc('${c.id}')">🧭 นำทาง</button>`:""}</div></div>`;
      }).join("");
      openModal("💕 สมุดความสัมพันธ์ คู่รัก & ชีวิตแต่งงาน (16 ตัวละคร)", spouseBanner + rows);
    }

    window.questAction = (qid, action) => {
      const q = GAME_DATA.quests.quests.find(x => x.id === qid); if (!q) return;
      if (action === "accept") { state.quests[qid] = "accepted"; sfx("talk"); showToast(`📜 รับเควสต์ "${q.title}" แล้ว!`); }
      else if (action === "complete") {
        const prog = getQuestProgress(q);
        if (!prog.ready) return;
        if (q.objective?.type === "have_item" && q.objective.item_id) {
          state.inventory[q.objective.item_id] -= (q.objective.count || 1);
          if (state.inventory[q.objective.item_id] <= 0) delete state.inventory[q.objective.item_id];
        }
        const goldReward = Math.round((q.reward?.gold || 150) * (getStatLevelInfo("wisdom").level >= 4 ? 1.25 : 1.0));
        addGold(goldReward);
        if (q.reward?.item_id) state.inventory[q.reward.item_id] = (state.inventory[q.reward.item_id] || 0) + 1;
        if (q.reward?.hearts_all) GAME_DATA.characters.characters.forEach(c => addFriendship(c.id, q.reward.hearts_all * 50));
        if (q.giver) addFriendship(q.giver, 40);
        addStatXp({ charm: 8, wisdom: 8 }); state.quests[qid] = "completed";
        sfx("quest"); checkAchievements(); showToast(`🏆 ส่งเควสต์ "${q.title}" สำเร็จ! +${goldReward}G`);
      }
      updateQuestTrackerHud(); saveGame(true); window.openQuestsModal();
    };
    window.openQuestsModal = () => {
      const rows = GAME_DATA.quests.quests.map(q => {
        const st = state.quests[q.id] || "open", giver = CHAR_BY_ID[q.giver], prog = getQuestProgress(q);
        return `<div class="card-row ${st==='completed'?'locked':''}"><div><div style="font-weight:800;font-size:13.5px;">${q.title} <span class="badge">👤 ${giver?.name_th}</span></div><div style="font-size:11.5px;color:#5c3312;">${q.desc} • 📌 ${prog.text}</div></div>${st==="completed"?'<span class="badge">✓ สำเร็จ</span>':st==="accepted"?`<button class="sd-btn ${prog.ready?'green':''}" ${prog.ready?'':'disabled'} onclick="window.questAction('${q.id}','complete')">✅ ส่งเควสต์</button>`:`<button class="sd-btn active" onclick="window.questAction('${q.id}','accept')">📜 รับเควสต์</button>`}</div>`;
      }).join("");
      openModal("📜 กระดานข่าว & เควสต์ชาวเมืองเอเธลการ์ด (10 เควสต์)", rows);
    };

    window.openCalendarModal = (tab = "cal") => {
      const cal = getCalendarInfo(), unlockedCount = ACHIEVEMENTS.filter(a => state.achievements[a.id]).length;
      const tabsHtml = `<div class="tab-bar"><button class="sd-btn ${tab==='cal'?'active':''}" onclick="window.openCalendarModal('cal')">📅 ปฏิทินเทศกาล & วันเกิด</button><button class="sd-btn ${tab==='ach'?'active':''}" onclick="window.openCalendarModal('ach')">🏆 ความสำเร็จ (${unlockedCount}/${ACHIEVEMENTS.length})</button></div>`;
      let content = "";
      if (tab === "cal") {
        const festRows = Object.entries(FESTIVALS).map(([d, f]) => `<div class="card-row"><div><b>วันที่ ${d} • ${f.name_th}</b><div style="font-size:11.5px;color:#5c3312;">${f.desc_th}</div></div><span class="badge">🎁 +${f.gold}G</span></div>`).join("");
        const bdayList = GAME_DATA.characters.characters.map(c => `<span class="badge">วันที่ ${NPC_BIRTHDAYS[c.id]}: 🎂 ${c.name_th}</span>`).join(" ");
        content = `${festRows}<div class="card-row" style="flex-direction:column;align-items:flex-start;"><b>🎂 วันเกิดชาวเมือง (ของขวัญวันเกิดหัวใจ x2!)</b><div style="display:flex;flex-wrap:wrap;gap:5px;margin-top:4px;">${bdayList}</div></div>`;
      } else {
        content = ACHIEVEMENTS.map(a => `<div class="card-row ${state.achievements[a.id]?'':'locked'}"><div><b>${a.icon} ${a.title_th}</b> ${state.achievements[a.id]?'<span class="badge" style="background:#dcfce7;color:#15803d;">✓ ปลดล็อก</span>':''}<div style="font-size:11.5px;color:#5c3312;">${a.desc_th}</div></div></div>`).join("");
      }
      openModal("📅 ปฏิทินเมืองเอเธลการ์ด & ความสำเร็จ", tabsHtml + content);
    };
"""

JS_PART_4A = r"""
    // =========================================================================
    // 11. INTERACTION FINDER (OUTDOOR, 2ND FLOOR LOFT, DECOR & ANCIENT RUINS!)
    // =========================================================================
    function findNearbyContext() {
      const p = state.player;
      let bestNpc = null, bestD = 54;
      for (const n of NPCS) {
        if (n.scene !== state.scene) continue;
        const d = Math.hypot(n.px - p.x, n.py - p.y);
        if (d < bestD) { bestD = d; bestNpc = n; }
      }
      if (bestNpc) {
        const ev = getUnlockedEventForNpc(bestNpc.id);
        const tag = state.spouseId === bestNpc.id ? "💒 " : (ev ? "💖 " : "💬 ");
        return { kind: "npc", target: bestNpc, label: `${tag}กด [E] คุยกับ ${bestNpc.name}${ev ? " (อีเวนต์หัวใจ!)" : ""}` };
      }

      if (state.scene === "outdoor") {
        // Under-Root Ancient Ruins Entrance!
        const rux = (RUINS_ENTRANCE.tx + 0.5) * TILE, ruy = (RUINS_ENTRANCE.ty + 0.5) * TILE;
        if (Math.hypot(rux - p.x, ruy - p.y) < 48) {
          return { kind: "enter_ruins", label: "🔦 กด [E] ลงสู่โบราณสถานใต้รากไม้โลก (ชั้น B1)" };
        }
        const mbx = (MAILBOX_POS.tx + 0.5) * TILE, mby = (MAILBOX_POS.ty + 0.5) * TILE;
        if (Math.hypot(mbx - p.x, mby - p.y) < 40) return { kind: "mailbox", label: "📮 กด [E] เปิดตู้จดหมายหน้าบ้าน" };
        const bbx = (BULLETIN_BOARD.tx + 0.5) * TILE, bby = (BULLETIN_BOARD.ty + 0.5) * TILE;
        if (Math.hypot(bbx - p.x, bby - p.y) < 42) return { kind: "bulletin", label: "📜 กด [E] เปิดกระดานข่าว & เควสต์" };
        const wtx = (WORLD_TREE_SHRINE.tx + 0.5) * TILE, wty = (WORLD_TREE_SHRINE.ty + 0.5) * TILE;
        if (Math.hypot(wtx - p.x, wty - p.y) < 52) return { kind: "shrine", label: `🌳 กด [E] เปิดพงศาวดารต้นไม้โลก (${getAwakenedSealCount()}/8 เผ่า)` };
        for (const lm of LANDMARKS) {
          const lx = lm.interactX * TILE, ly = lm.interactY * TILE;
          const cx = (lm.tx + lm.w / 2) * TILE, cy = (lm.ty + lm.h / 2) * TILE;
          if (Math.hypot(lx - p.x, ly - p.y) < 52 || Math.hypot(cx - p.x, cy - p.y) < 62) {
            return state.landmarksBuilt[lm.id]
              ? { kind: "landmark_use", target: lm, label: `${lm.ability_th} [E]` }
              : { kind: "landmark_build", target: lm, label: `🚧 กด [E] บูรณะ ${lm.icon} ${lm.name_th}` };
          }
        }
        for (const fs of forageSpots) {
          if (fs.collected) continue;
          const fx = (fs.tx + 0.5) * TILE, fy = (fs.ty + 0.5) * TILE;
          if (Math.hypot(fx - p.x, fy - p.y) < 38) {
            const it = ITEM_BY_ID[fs.item_id];
            return { kind: "forage", target: fs, label: `✨ กด [E] เก็บ ${it ? it.name_th : "ของป่า"}` };
          }
        }
        for (const b of BUILDINGS) {
          const dx = (b.doorX + 0.5) * TILE, dy = (b.doorY + 0.2) * TILE;
          if (Math.hypot(dx - p.x, dy - p.y) < 38) return { kind: "enter", target: b, label: `🚪 กด [E] เข้าสู่ ${b.name}` };
        }
        if (isNearWater(p.x, p.y)) return { kind: "fish", label: "🎣 กด [E] ตกปลา Stardew ริมน้ำ!" };
      } else if (RUINS_FLOORS[state.scene]) {
        const fl = RUINS_FLOORS[state.scene];
        const rs = state.ruins[fl.id];
        // Exit stairs up
        if (Math.hypot((fl.exitUp.x + 0.5) * TILE - p.x, (fl.exitUp.y + 0.5) * TILE - p.y) < 42) {
          return { kind: "ruins_up", target: fl.exitUp, label: fl.exitUp.to === "outdoor" ? "🪜 กด [E] ขึ้นกลับสู่หุบเขาต้นไม้โลก" : `🪜 กด [E] ย้อนขึ้นไป ${fl.exitUp.to.toUpperCase()}` };
        }
        // Stairs down to deeper floor (requires solved!)
        if (fl.stairsDown && Math.hypot((fl.stairsDown.x + 0.5) * TILE - p.x, (fl.stairsDown.y + 0.5) * TILE - p.y) < 44) {
          return { kind: "ruins_down", target: fl.stairsDown, solved: rs.solved, label: rs.solved ? `🌀 กด [E] ลงสู่ชั้นถัดไป (${fl.stairsDown.to.toUpperCase()})!` : "🔒 ผนึกเสาแสงยังไม่เปิด — หมุนเสาปริซึมให้ลำแสงชนแท่นรับแสงครบก่อน!" };
        }
        // Ancient Treasure Chest (requires solved!)
        if (fl.chest && !rs.chestOpened && Math.hypot((fl.chest.x + 0.5) * TILE - p.x, (fl.chest.y + 0.5) * TILE - p.y) < 46) {
          return { kind: "ruins_chest", target: fl, label: rs.solved ? "🎁✨ กด [E] เปิดหีบสมบัติบรรพกาล!" : "🔒 หีบถูกผนึกด้วยเสาแสงรูน" };
        }
        // Prism Pillars (Rotate 90 deg!)
        for (let i = 0; i < fl.pillars.length; i++) {
          const pil = fl.pillars[i];
          if (Math.hypot((pil.x + 0.5) * TILE - p.x, (pil.y + 0.5) * TILE - p.y) < 48) {
            return { kind: "ruins_pillar", idx: i, target: fl, label: `🔮 กด [E] หมุนเสาปริซึมแสง (#${i+1})` };
          }
        }
        // Daily Mana Ore Nodes
        for (let i = 0; i < fl.ores.length; i++) {
          const ore = fl.ores[i];
          if (rs.minedDay?.[i] === state.day) continue;
          if (Math.hypot((ore.x + 0.5) * TILE - p.x, (ore.y + 0.5) * TILE - p.y) < 44) {
            return { kind: "ruins_ore", idx: i, ore, target: fl, label: `⛏️ กด [E] สกัดแร่มานา (${ITEM_BY_ID[ore.item_id]?.name_th})` };
          }
        }
      } else {
        const rm = INDOORS[state.scene];
        const ex = (rm.exitX + 0.5) * TILE, ey = (rm.exitY + 0.5) * TILE;
        if (Math.hypot(ex - p.x, ey - p.y) < 38) {
          return state.scene === "farmhouse_upstairs"
            ? { kind: "stairs_down", label: "🪜 กด [E] ลงบันไดกลับบ้านชั้น 1" }
            : { kind: "exit", label: "🚪 กด [E] ออกไปข้างนอก" };
        }
        if (state.scene === "farmhouse" && state.houseLevel >= 2 && rm.stairsUp) {
          if (Math.hypot((rm.stairsUp.x + 0.5) * TILE - p.x, (rm.stairsUp.y + 0.5) * TILE - p.y) < 46) {
            return { kind: "stairs_up", label: "🌟 กด [E] ขึ้นบันไดสู่ชั้น 2 (Starlight Loft)" };
          }
        }
        // Check interactive grid-placed custom furniture!
        for (const pl of (state.decorPlaced || [])) {
          if (pl.scene !== state.scene) continue;
          const d = DECOR_BY_ID[pl.id];
          if (!d || !d.action) continue;
          const fx = (pl.x + pl.w / 2) * TILE, fy = (pl.y + pl.h / 2) * TILE;
          if (Math.hypot(fx - p.x, fy - p.y) < 52) {
            return { kind: "decor_use", decor: d, label: `${d.icon} กด [E] ใช้งาน ${d.name_th}` };
          }
        }
        for (const f of rm.furniture) {
          if (!f.label) continue;
          const fx = (f.x + f.w / 2) * TILE, fy = (f.y + f.h / 2) * TILE;
          if (Math.hypot(fx - p.x, fy - p.y) < 60) {
            if (f.type === "bed") return { kind: "sleep", target: f, label: "🛏️ กด [E] เข้านอน & สรุปผลประจำวัน" };
            if (isHomeScene() && (f.type === "table" || f.type === "fireplace")) {
              return { kind: "craft", target: f, label: "🍳 กด [E] เปิดโต๊ะคราฟต์ & ตีแหวนแต่งงาน" };
            }
            if (state.scene === "tavern" && f.label.includes("ไวโอลิน")) {
              return { kind: "tavern_music", label: "🎻 กด [E] ร่วมบรรเลงมินิเกมดนตรี 4 เลน!" };
            }
            return { kind: "inspect", target: f, label: f.label };
          }
        }
      }
      return null;
    }

    function triggerInteract() {
      if (!state.started || state.modalOpen || state.miniGameOpen || state.worldMapOpen || state.summaryOpen || state.homeEditMode) return;
      if (activeCutscene) {
        if (skipTypewriter()) return;
        if (activeCutscene.finished) { closeDialogue(); return; }
        if (document.getElementById("dlgChoices").style.display === "none") window.advanceCutsceneBeat();
        return;
      }
      if (state.activeDlgNpc) {
        if (skipTypewriter()) return;
        if (document.getElementById("dlgChoices").style.display === "none") closeDialogue();
        return;
      }
      const ctxObj = findNearbyContext();
      if (!ctxObj) return;
      if (ctxObj.kind === "mailbox") { sfx("talk"); window.openMailboxModal(); }
      else if (ctxObj.kind === "bulletin") { sfx("talk"); window.openQuestsModal(); }
      else if (ctxObj.kind === "shrine") { sfx("sparkle"); window.openStoryModal("main"); }
      else if (ctxObj.kind === "landmark_build") { sfx("talk"); window.openTownModal("landmarks"); }
      else if (ctxObj.kind === "landmark_use") { window.useLandmarkAbility(ctxObj.target.id); }
      else if (ctxObj.kind === "craft") { sfx("talk"); window.openCraftModal(); }
      else if (ctxObj.kind === "tavern_music") { startSpecializedMiniGame("rhythm_stage", "concert", null); }
      else if (ctxObj.kind === "enter_ruins") { sfx("door"); transitionScene("ruins_b1", 10, 11, true); }
      else if (ctxObj.kind === "ruins_up") {
        sfx("door");
        if (ctxObj.target.to === "outdoor") transitionScene("outdoor", RUINS_ENTRANCE.tx, RUINS_ENTRANCE.ty + 1, false);
        else { const upFl = RUINS_FLOORS[ctxObj.target.to]; transitionScene(ctxObj.target.to, upFl.stairsDown.x, upFl.stairsDown.y + 1, false); }
      } else if (ctxObj.kind === "ruins_down") {
        if (!ctxObj.solved) { sfx("miss"); showToast("🔒 หมุนเสาปริซึมให้ลำแสงส่องถึงแท่นรับแสงครบทุกจุดก่อนนะ!"); return; }
        sfx("door");
        const nextFl = RUINS_FLOORS[ctxObj.target.to];
        transitionScene(ctxObj.target.to, nextFl.spawnX, nextFl.spawnY, false);
      } else if (ctxObj.kind === "ruins_pillar") {
        const fl = ctxObj.target, pDef = fl.pillars[ctxObj.idx];
        const cur = state.ruins[fl.id].pillars[ctxObj.idx] ?? pDef.init;
        state.ruins[fl.id].pillars[ctxObj.idx] = (cur + 1) % (pDef.maxStates || 2);
        state.player.interactT = 0.3;
        sfx("beam");
        computeRuinsBeams(fl.id);
        saveGame(true);
      } else if (ctxObj.kind === "ruins_chest") {
        const fl = ctxObj.target, rs = state.ruins[fl.id];
        if (!rs.solved) { sfx("miss"); showToast("🔒 ต้องไขปริศนาเสาแสงให้สำเร็จก่อนถึงจะเปิดหีบได้!"); return; }
        rs.chestOpened = true;
        addGold(fl.chest.gold);
        const gotNames = [];
        for (const [iid, qty] of Object.entries(fl.chest.items || {})) {
          state.inventory[iid] = (state.inventory[iid] || 0) + qty;
          gotNames.push(`${ITEM_BY_ID[iid]?.name_th} x${qty}`);
        }
        addStatXp(fl.chest.stat || {});
        sfx("quest");
        spawnParticles(state.player.x, state.player.y - 22, "#fde047", 30);
        saveGame(true);
        showToast(`🎁 เปิดหีบสมบัติบรรพกาล! รับ +${fl.chest.gold}G และ ${gotNames.join(", ")}!`);
      } else if (ctxObj.kind === "ruins_ore") {
        const cost = getStaminaCost(6);
        if (state.stamina < cost) { showToast(`⚡ พลังงานไม่พอสกัดแร่ (ต้องใช้ ${cost} ⚡)`); return; }
        state.stamina -= cost;
        const fl = ctxObj.target, rs = state.ruins[fl.id];
        if (!rs.minedDay) rs.minedDay = {};
        rs.minedDay[ctxObj.idx] = state.day;
        const qty = state.heroCustom.raceKey === "dwarf" ? 2 : 1;
        state.inventory[ctxObj.ore.item_id] = (state.inventory[ctxObj.ore.item_id] || 0) + qty;
        state.dailyLog.itemsFound += qty;
        state.player.interactT = 0.45;
        sfx("anvil"); addStatXp({ craft: 5, courage: 4 }); saveGame(true);
        showToast(`⛏️ สกัดได้ "${ITEM_BY_ID[ctxObj.ore.item_id]?.name_th}" x${qty}!${qty>1?' (โบนัสคนแคระ x2!)':''}`);
      } else if (ctxObj.kind === "decor_use") {
        const d = ctxObj.decor;
        if (d.action === "mirror") { sfx("sparkle"); window.openProtagonistCreator(); }
        else if (d.action === "music") { startSpecializedMiniGame("rhythm_stage", "concert", null); }
        else if (d.action === "aquarium") {
          if (state.decorUsedDay.aquarium === state.day) { showToast("🐠 ปลาเรืองแสงว่ายวนอย่างสงบ~ (รับโบนัสวันนี้แล้ว)"); return; }
          state.decorUsedDay.aquarium = state.day;
          state.stamina = Math.min(getMaxStamina(), state.stamina + 12);
          sfx("splash"); saveGame(true); showToast("🐠 ชมตู้ปลาเรืองแสง ผ่อนคลายฟื้นพลังงาน +12 ⚡!");
        } else if (d.action === "stargaze") {
          if (state.decorUsedDay.stargaze === state.day) { showToast("🔭 หมู่ดาวเหนือเอเธลการ์ดส่องประกายงดงาม~"); return; }
          state.decorUsedDay.stargaze = state.day;
          addStatXp({ wisdom: 8 }); sfx("sparkle"); saveGame(true); showToast("🔭 ส่องกล้องดูดาวจากบ้านพัก รับ +8 📖 ปัญญา!");
        }
      } else if (ctxObj.kind === "forage") {
        ctxObj.target.collected = true;
        const iid = ctxObj.target.item_id, it = ITEM_BY_ID[iid];
        const qty = (state.heroCustom.raceKey === "elf" && Math.random() < 0.35) ? 2 : 1;
        state.inventory[iid] = (state.inventory[iid] || 0) + qty;
        state.foragedCount = (state.foragedCount || 0) + qty;
        state.dailyLog.itemsFound += qty;
        state.player.interactT = 0.45; sfx("sparkle");
        spawnFloatText(`✨ +${qty} ${it?.name_th}`, state.player.x, state.player.y - 40, "#fde047");
        addStatXp({ wisdom: 3 }); checkAchievements(); updateQuestTrackerHud(); saveGame(true);
        showToast(`✨ เก็บ "${it?.name_th}" x${qty} เข้ากระเป๋าแล้ว!${qty>1?' (🌿 โบนัสเอลฟ์ x2!)':''}`);
      } else if (ctxObj.kind === "fish") { startFishingGame(); }
      else if (ctxObj.kind === "npc") { sfx("talk"); openDialogue(ctxObj.target); }
      else if (ctxObj.kind === "enter") {
        sfx("door");
        if (ctxObj.target.interiorId === "tavern" && state.timeMin >= 19 * 60) { state.visitedTavernNight = true; updateQuestTrackerHud(); }
        const rm = INDOORS[ctxObj.target.interiorId];
        transitionScene(ctxObj.target.interiorId, rm.spawnX, rm.spawnY, true);
      } else if (ctxObj.kind === "stairs_up") {
        sfx("door"); transitionScene("farmhouse_upstairs", 11, 7, false);
      } else if (ctxObj.kind === "stairs_down") {
        sfx("door"); transitionScene("farmhouse", 13, 3, false);
      } else if (ctxObj.kind === "exit") {
        sfx("door"); transitionScene("outdoor", state.returnPos.x / TILE, state.returnPos.y / TILE, false);
      } else if (ctxObj.kind === "sleep") { triggerEndOfDaySummary(); }
      else if (ctxObj.kind === "inspect") { showToast(ctxObj.target.label); }
    }

    function selectTool(idx, silent = false) {
      state.tool = idx;
      document.querySelectorAll(".hotbar-slot").forEach(el => el.classList.toggle("active", Number(el.dataset.tool) === idx));
      if (silent) return;
      if (idx === 1) openJobsModal();
      else if (idx === 2) window.openShopBagModal(isHomeScene() ? "decor" : "bag");
      else if (idx === 3) window.openCraftModal();
      else if (idx === 4) openRelationshipsModal();
      else if (idx === 5) window.openQuestsModal();
      else if (idx === 6) window.openMailboxModal();
      else if (idx === 7) window.openCalendarModal("cal");
    }

    window.addEventListener("keydown", (e) => {
      const k = e.key.toLowerCase();
      state.keys[k] = true;
      if (!state.started) return;
      if (state.summaryOpen) {
        if (k === " " || k === "enter" || k === "e") { e.preventDefault(); finishNextMorning(); }
        return;
      }
      if (state.miniGameOpen) {
        if (k === "escape") { closeMiniGameOverlay(); return; }
        if (mg.kind === "forge_heat" && (k === " " || k === "enter" || k === "e")) { e.preventDefault(); triggerMgPrimaryHit(); }
        else if (mg.kind === "order_rush" && "123456".includes(k)) { const iid = mg.data.pool[Number(k)-1]; if (iid) window.mgPickOrderItem(iid); }
        else if (mg.kind === "rune_memory" && "123456".includes(k)) { window.mgPressRune(Number(k)-1); }
        else if (mg.kind === "rhythm_stage") {
          const lIdx = ["d","f","j","k"].indexOf(k);
          if (lIdx >= 0) { e.preventDefault(); window.mgHitLane(lIdx); }
        }
        return;
      }
      if (e.target && (e.target.tagName === "INPUT" || e.target.tagName === "SELECT")) return;
      if (k === "h" && isHomeScene()) { e.preventDefault(); window.toggleHomeEditMode(); return; }
      if (state.homeEditMode) {
        if (k === "r") { e.preventDefault(); window.rotateSelectedDecor(); }
        else if (k === "escape") window.toggleHomeEditMode(false);
        return;
      }
      if (k === "m") { e.preventDefault(); if (state.worldMapOpen) window.closeWorldMap(); else window.openWorldMap(); return; }
      if (k === "escape") {
        if (state.worldMapOpen) window.closeWorldMap();
        else if (state.modalOpen) closeModal();
        else if (state.activeDlgNpc) closeDialogue();
        return;
      }
      if (state.modalOpen || state.worldMapOpen) return;
      if (k === "p") { e.preventDefault(); petCompanion(); return; }
      if (k === "e" || k === " " || k === "enter") { e.preventDefault(); triggerInteract(); }
      if ("123456789".includes(k)) selectTool(Number(k) - 1);
    });
    window.addEventListener("keyup", (e) => { state.keys[e.key.toLowerCase()] = false; });

    canvas.addEventListener("mousemove", (e) => {
      const rect = canvas.getBoundingClientRect(), cam = getCamera();
      const wx = (e.clientX - rect.left) / cam.zoom + cam.x, wy = (e.clientY - rect.top) / cam.zoom + cam.y;
      state.mouseWorld.tx = Math.floor(wx / TILE);
      state.mouseWorld.ty = Math.floor(wy / TILE);
    });
    canvas.addEventListener("contextmenu", (e) => {
      if (state.homeEditMode) {
        e.preventDefault();
        const rect = canvas.getBoundingClientRect(), cam = getCamera();
        handleHomeEditClick((e.clientX - rect.left) / cam.zoom + cam.x, (e.clientY - rect.top) / cam.zoom + cam.y, true);
      }
    });
    canvas.addEventListener("mousedown", (e) => {
      if (!state.started || state.activeDlgNpc || state.modalOpen || state.miniGameOpen || state.worldMapOpen || state.summaryOpen) return;
      const rect = canvas.getBoundingClientRect(), cam = getCamera();
      const wx = (e.clientX - rect.left) / cam.zoom + cam.x, wy = (e.clientY - rect.top) / cam.zoom + cam.y;
      if (state.homeEditMode) {
        if (e.button === 0) handleHomeEditClick(wx, wy, false);
        return;
      }
      if (Math.hypot(state.pet.x - wx, (state.pet.y - 8) - wy) < 22) { petCompanion(); return; }
      for (const n of NPCS) {
        if (n.scene === state.scene && Math.hypot(n.px - wx, (n.py - 20) - wy) < 28 && Math.hypot(n.px - state.player.x, n.py - state.player.y) < 76) {
          sfx("talk"); openDialogue(n); return;
        }
      }
      state.player.target = { x: wx, y: wy };
    });

    document.querySelectorAll("#titlePetPicker button").forEach(btn => {
      btn.addEventListener("click", () => {
        state.pet.kind = btn.dataset.pet;
        document.querySelectorAll("#titlePetPicker button").forEach(b => b.classList.toggle("active", b === btn));
      });
    });
    document.getElementById("btnTitleCreator").addEventListener("click", () => window.openProtagonistCreator());

    function startGameWithAudio(enableAudio) {
      const v = (document.getElementById("heroNameInput").value || "").trim();
      if (v) state.playerName = v;
      state.started = true;
      document.getElementById("titleOverlay").style.display = "none";
      rebuildHeroCustomSheets();
      renderSocialStatsHud(); syncNpcSchedules(); setAudioEnabled(enableAudio); syncBgmZone();
      saveGame(true, activeSaveSlot);
      const rp = RACE_PERKS[state.heroCustom.raceKey] || RACE_PERKS.human;
      showToast(`✨ ยินดีต้อนรับ ${state.playerName} (${rp.icon} ${rp.name_th.split(" ")[0]}) สู่ ${state.cottageName}! (เซฟช่อง ${activeSaveSlot})`);
    }
    document.getElementById("btnStartPlay").addEventListener("click", () => startGameWithAudio(true));
    document.getElementById("btnStartMute").addEventListener("click", () => startGameWithAudio(false));
    document.querySelectorAll(".hotbar-slot").forEach(el => el.addEventListener("click", () => selectTool(Number(el.dataset.tool))));
    document.getElementById("btnCloseDlg").addEventListener("click", closeDialogue);
    document.getElementById("btnCutsceneNext").addEventListener("click", () => window.advanceCutsceneBeat());
    document.getElementById("btnCutsceneClose").addEventListener("click", closeDialogue);
    document.getElementById("btnGiveGift").addEventListener("click", () => { if (state.activeDlgNpc) openGiftPicker(state.activeDlgNpc.id); });
    document.getElementById("btnHangout").addEventListener("click", () => { if (state.activeDlgNpc) openHangoutModal(state.activeDlgNpc.id); });
    document.getElementById("btnConfess").addEventListener("click", () => { if (state.activeDlgNpc) triggerConfession(state.activeDlgNpc.id); });
    document.getElementById("btnProposeMarriage").addEventListener("click", () => { if (state.activeDlgNpc) triggerMarriageProposal(state.activeDlgNpc.id); });
    document.getElementById("btnSpouseCare").addEventListener("click", () => { if (state.activeDlgNpc) triggerSpouseMorningCare(state.activeDlgNpc.id); });
    document.getElementById("btnSpouseDate").addEventListener("click", () => { if (state.activeDlgNpc) triggerSpouseRomanticDate(state.activeDlgNpc.id); });
    document.getElementById("btnHeartEvent").addEventListener("click", () => { if (state.activeDlgNpc) { const ev = getUnlockedEventForNpc(state.activeDlgNpc.id); if (ev) playHeartEvent(ev); } });
    document.getElementById("btnNpcJob").addEventListener("click", () => { if (state.activeDlgNpc) { const job = JOB_BY_EMPLOYER[state.activeDlgNpc.id]; if (job) { closeDialogue(); window.doPartTimeJob(job.id); } } });
    document.getElementById("btn-time-skip").addEventListener("click", () => advanceHours(2));
    document.getElementById("btn-weather").addEventListener("click", () => {
      state.weather = state.weather === "sunny" ? "rainy" : "sunny"; syncNpcSchedules();
      showToast(state.weather === "rainy" ? "🌧️ ฝนเริ่มโปรยปราย..." : "☀️ ท้องฟ้าแจ่มใสแล้ว!");
    });
    document.getElementById("btn-char-custom").addEventListener("click", () => window.openProtagonistCreator());
    document.getElementById("btn-audio").addEventListener("click", () => setAudioEnabled(!audio.enabled));
    document.getElementById("btn-save-slots").addEventListener("click", () => window.openSaveSlotsModal());
    document.getElementById("btn-ruins-warp").addEventListener("click", () => {
      if (RUINS_FLOORS[state.scene]) transitionScene("outdoor", RUINS_ENTRANCE.tx, RUINS_ENTRANCE.ty + 1, false);
      else transitionScene("outdoor", RUINS_ENTRANCE.tx, RUINS_ENTRANCE.ty + 1, false);
    });
    document.getElementById("btnJoinFestival").addEventListener("click", () => {
      const cal = getCalendarInfo();
      if (!cal.festival || state.festivalJoinedDay === state.day) return;
      state.festivalJoinedDay = state.day; addGold(cal.festival.gold);
      GAME_DATA.characters.characters.forEach(c => addFriendship(c.id, cal.festival.hearts));
      const statStr = addStatXp(cal.festival.stats);
      sfx("quest"); spawnParticles(state.player.x, state.player.y - 24, "#fde047", 24);
      saveGame(true); showToast(`🎉 เข้าร่วม "${cal.festival.name_th}"! รับ +${cal.festival.gold}G (${statStr})`);
    });
"""

JS_PART_4B = r"""
    // =========================================================================
    // 12. UPDATE + 2.5D RENDERER (WORLD SPRITES + LOFT + ANCIENT RUINS BEAMS!)
    // =========================================================================
    function getSceneDims() {
      if (state.scene === "outdoor") return { w: MAP_W, h: MAP_H, zoom: 1.65 };
      if (RUINS_FLOORS[state.scene]) return { w: RUINS_FLOORS[state.scene].w, h: RUINS_FLOORS[state.scene].h, zoom: 2.0 };
      const rm = INDOORS[state.scene];
      return { w: rm.w, h: rm.h, zoom: 2.15 };
    }
    function getCamera() {
      const dims = getSceneDims();
      const vw = canvas.width / dims.zoom, vh = canvas.height / dims.zoom;
      const mw = dims.w * TILE, mh = dims.h * TILE;
      let cx = state.player.x - vw / 2, cy = state.player.y - vh / 2;
      cx = mw <= vw ? (mw - vw) / 2 : Math.max(0, Math.min(mw - vw, cx));
      cy = mh <= vh ? (mh - vh) / 2 : Math.max(0, Math.min(mh - vh, cy));
      return { x: cx, y: cy, zoom: dims.zoom, vw, vh };
    }

    let bgmCheckAccum = 0;
    function update(dt) {
      if (!assetsReady) return;
      if (state.started && !state.modalOpen && !state.miniGameOpen && !state.activeDlgNpc && !state.worldMapOpen && !state.summaryOpen && !state.homeEditMode) {
        const prevHr = Math.floor(state.timeMin / 60);
        state.timeMin += dt * 1.5;
        if (state.timeMin >= 24 * 60) triggerEndOfDaySummary();
        else if (Math.floor(state.timeMin / 60) !== prevHr) syncNpcSchedules();
      }

      bgmCheckAccum += dt;
      if (bgmCheckAccum >= 1.2) { bgmCheckAccum = 0; if (state.started) syncBgmZone(); }

      const hh = Math.floor(state.timeMin / 60), mm = Math.floor(state.timeMin % 60), cal = getCalendarInfo();
      const icon = state.weather === "rainy" ? "🌧️" : (hh >= 6 && hh < 17 ? "☀️" : hh >= 17 && hh < 20 ? "🌇" : "🌙");
      document.getElementById("clockLabel").textContent = `${String(hh).padStart(2,"0")}:${String(mm).padStart(2,"0")}`;
      document.getElementById("dayLabel").textContent = `${icon} ${cal.weekday} วันที่ ${cal.dayOfSeason} • ${cal.season.name_th}`;
      document.getElementById("goldLabel").textContent = state.gold;
      document.getElementById("staminaLabel").textContent = state.stamina;

      document.getElementById("homeContextBtnWrap").style.display = isHomeScene() ? "block" : "none";
      const inRuins = !!RUINS_FLOORS[state.scene];
      document.getElementById("ruinsContextBtnWrap").style.display = inRuins ? "block" : "none";

      const festBan = document.getElementById("festivalBanner");
      if (cal.festival && state.festivalJoinedDay !== state.day) {
        festBan.style.display = "block";
        document.getElementById("btnJoinFestival").textContent = `🎉 ${cal.festival.name_th}`;
      } else festBan.style.display = "none";

      if (inRuins) {
        document.getElementById("zoneLabel").textContent = SCENE_NAMES_TH[state.scene];
      } else if (state.scene !== "outdoor") {
        document.getElementById("zoneLabel").textContent = SCENE_NAMES_TH[state.scene] || INDOORS[state.scene].name;
      } else {
        const tx = state.player.x / TILE, ty = state.player.y / TILE;
        let z = "จัตุรัสต้นไม้โลก";
        if (tx < 26 && ty < 28) z = state.cottageName;
        else if (tx > 50 && ty < 32) z = "ตลาด & โรงเตี๊ยม";
        else if (tx > 62) z = "ย่านช่างเหล็ก & หอเวหา";
        else if (ty > 45) z = "ทะเลสาบมุกศักดิ์สิทธิ์";
        else if (tx < 30 && ty > 32) z = "ป่าพฤกษา & กระท่อมยา";
        document.getElementById("zoneLabel").textContent = z;
      }

      if (state.started && !state.activeDlgNpc && !state.fading && !state.modalOpen && !state.miniGameOpen && !state.worldMapOpen && !state.summaryOpen && !state.homeEditMode) {
        let vx = 0, vy = 0;
        if (state.keys["w"] || state.keys["arrowup"]) vy -= 1;
        if (state.keys["s"] || state.keys["arrowdown"]) vy += 1;
        if (state.keys["a"] || state.keys["arrowleft"]) vx -= 1;
        if (state.keys["d"] || state.keys["arrowright"]) vx += 1;
        if (vx !== 0 || vy !== 0) state.player.target = null;
        else if (state.player.target) {
          const dx = state.player.target.x - state.player.x, dy = state.player.target.y - state.player.y;
          if (Math.hypot(dx, dy) > 8) { vx = dx; vy = dy; } else state.player.target = null;
        }
        const len = Math.hypot(vx, vy);
        if (len > 0) {
          vx /= len; vy /= len;
          const sprint = !!state.keys["shift"]; state.player.sprinting = sprint;
          const avianSpd = state.heroCustom.raceKey === "avian" ? 1.12 : 1.0;
          const spd = (sprint ? 205 : 134) * avianSpd * dt;
          const nx = state.player.x + vx * spd, ny = state.player.y + vy * spd;
          if (!isBlocked(nx, state.player.y)) state.player.x = nx;
          if (!isBlocked(state.player.x, ny)) state.player.y = ny;
          if (Math.abs(vx) > Math.abs(vy)) state.player.dir = vx < 0 ? 1 : 3;
          else state.player.dir = vy < 0 ? 0 : 2;
          state.player.moving = true; state.player.animT += dt * (sprint ? 12.5 : 9);
          if (state.scene === "outdoor" && state.tool === 8 && (state.timeMin >= 18 * 60 || state.timeMin < 6 * 60)) {
            state.nightLanternSteps += dt * 4; updateQuestTrackerHud();
          }
          if (state.scene === "outdoor") {
            for (const b of BUILDINGS) {
              const dx = (b.doorX + 0.5) * TILE, dy = b.doorY * TILE + 6;
              if (Math.hypot(dx - state.player.x, dy - state.player.y) < 16 && state.player.dir === 0) {
                sfx("door");
                if (b.interiorId === "tavern" && state.timeMin >= 19 * 60) { state.visitedTavernNight = true; updateQuestTrackerHud(); }
                const rm = INDOORS[b.interiorId]; transitionScene(b.interiorId, rm.spawnX, rm.spawnY, true);
              }
            }
          } else if (!inRuins) {
            const rm = INDOORS[state.scene];
            const ex = (rm.exitX + 0.5) * TILE, ey = (rm.exitY + 0.7) * TILE;
            if (Math.hypot(ex - state.player.x, ey - state.player.y) < 16 && state.player.dir === 2) {
              sfx("door");
              if (state.scene === "farmhouse_upstairs") transitionScene("farmhouse", 13, 3, false);
              else transitionScene("outdoor", state.returnPos.x / TILE, state.returnPos.y / TILE, false);
            }
          }
        } else { state.player.moving = false; state.player.sprinting = false; state.player.animT += dt * 4.5; }
        if (state.player.interactT > 0) state.player.interactT -= dt;
      }

      const pdx = state.player.x - state.pet.x, pdy = (state.player.y + 8) - state.pet.y;
      const pdist = Math.hypot(pdx, pdy);
      if (pdist > 28) {
        const pspd = Math.min(185, pdist * 3.8) * dt;
        state.pet.x += (pdx / pdist) * pspd; state.pet.y += (pdy / pdist) * pspd;
        state.pet.dir = Math.abs(pdx) > Math.abs(pdy) ? (pdx < 0 ? 1 : 3) : (pdy < 0 ? 0 : 2);
        state.pet.moving = true; state.pet.hopT += dt * 9.5;
      } else { state.pet.moving = false; state.pet.hopT += dt * 3; }

      if (state.scene === "outdoor" && Math.random() < dt * 3.0) {
        const b = BUILDINGS[Math.floor(Math.random() * BUILDINGS.length)];
        chimneySmoke.push({ x: (b.x + b.w - 1.2) * TILE, y: (b.y - 0.6) * TILE, vy: -14 - Math.random() * 8, vx: 4 + Math.random() * 6, r: 3.5, life: 1.8 });
      }
      for (let i = chimneySmoke.length - 1; i >= 0; i--) {
        const sm = chimneySmoke[i]; sm.x += sm.vx * dt; sm.y += sm.vy * dt; sm.r += dt * 4.5; sm.life -= dt;
        if (sm.life <= 0) chimneySmoke.splice(i, 1);
      }

      for (const n of NPCS) {
        if (n.scene !== state.scene) continue;
        n.animT += dt * (n.state === "walk" ? 7.5 : n.state === "interact" ? 6 : 4);
        n.timer -= dt;
        if (n.state === "walk") {
          const [wx, wy] = n.patrol[n.wpIdx], tx = wx * TILE + 16, ty = wy * TILE + 16;
          const dx = tx - n.px, dy = ty - n.py, dist = Math.hypot(dx, dy);
          if (dist < 4) { n.state = Math.random() < 0.6 ? "interact" : "idle"; n.timer = 2.6 + Math.random() * 2.5; n.dir = 2; }
          else { const sp = 42 * dt; n.px += (dx / dist) * sp; n.py += (dy / dist) * sp; n.dir = Math.abs(dx) > Math.abs(dy) ? (dx < 0 ? 1 : 3) : (dy < 0 ? 0 : 2); }
        } else if (n.timer <= 0) {
          if (n.patrol.length > 1) { n.wpIdx = (n.wpIdx + 1) % n.patrol.length; n.state = "walk"; }
          else { n.state = n.state === "interact" ? "idle" : "interact"; n.timer = 3.0; }
        }
      }

      for (let i = particles.length - 1; i >= 0; i--) { const pt = particles[i]; pt.x += pt.vx * dt; pt.y += pt.vy * dt; pt.life -= dt; if (pt.life <= 0) particles.splice(i, 1); }
      for (let i = floatingTexts.length - 1; i >= 0; i--) { const ft = floatingTexts[i]; ft.y -= 26 * dt; ft.life -= dt; if (ft.life <= 0) floatingTexts.splice(i, 1); }
      for (const m of ambientMotes) { m.x = (m.x + m.vx * dt) % (MAP_W * TILE); m.y = (m.y + m.vy * dt) % (MAP_H * TILE); }

      const promptEl = document.getElementById("interactPrompt");
      const near = (state.started && !state.activeDlgNpc && !state.modalOpen && !state.miniGameOpen && !state.worldMapOpen && !state.summaryOpen && !state.homeEditMode) ? findNearbyContext() : null;
      if (near) { document.getElementById("interactPromptText").textContent = near.label; promptEl.style.display = "block"; }
      else promptEl.style.display = "none";
    }

    function drawSprite(id, mode, row, col, x, y, useHeroCustom = false) {
      const sheet = useHeroCustom
        ? (HERO_SHEETS[mode] || HERO_SHEETS.walk || SPRITES[mode]?.[id] || SPRITES.walk[id])
        : (SPRITES[mode]?.[id] || SPRITES.walk[id]);
      if (!sheet) return;
      ctx.fillStyle = "rgba(0,0,0,0.28)";
      ctx.beginPath(); ctx.ellipse(x, y + 3, 15, 6, 0, 0, Math.PI * 2); ctx.fill();
      ctx.drawImage(sheet, col * 64, row * 64, 64, 64, Math.round(x - 32), Math.round(y - 54), 64, 64);
    }

    function drawPet(now) {
      const p = state.pet;
      const px = Math.round(p.x), py = Math.round(p.y);
      const petSheet = PET_IMAGES[p.kind];
      if (petSheet && petSheet.complete !== false) {
        const row = (p.dir >= 0 && p.dir <= 3) ? p.dir : 2;
        const col = p.moving ? (Math.floor(p.hopT) % 4) : (p.kind === "fairy" ? (Math.floor(now / 180) % 4) : 0);
        const floatY = p.kind === "fairy" ? Math.round(Math.sin(now / 220) * 3) : 0;
        ctx.drawImage(petSheet, col * 64, row * 64, 64, 64, px - 22, py - 38 + floatY, 44, 44);
      }
    }

    function drawBuilding25D(b, isNight) {
      const bx = b.x * TILE, by = b.y * TILE, bw = b.w * TILE, bh = b.h * TILE;
      const spr = SPRITES.world.buildings[b.id];
      if (spr) {
        ctx.drawImage(spr, bx - 8, by - 22, bw + 16, bh + 26);
      } else {
        ctx.fillStyle = b.wallColor; ctx.fillRect(bx, by + 32, bw, bh - 32);
        ctx.fillStyle = b.roofColor; ctx.fillRect(bx - 6, by, bw + 12, 42);
      }
      if (isNight) {
        ctx.fillStyle = "rgba(253, 224, 71, 0.25)";
        ctx.beginPath(); ctx.arc(bx + bw * 0.26, by + bh * 0.58, 22, 0, Math.PI * 2);
        ctx.arc(bx + bw * 0.74, by + bh * 0.58, 22, 0, Math.PI * 2); ctx.fill();
      }
      if (b.id === "farmhouse" && state.houseLevel >= 2) {
        // 2nd Floor Starlight Dormer Badge on Roof!
        ctx.fillStyle = "#312e81"; ctx.fillRect(bx + bw / 2 - 22, by - 24, 44, 22);
        ctx.strokeStyle = "#fde047"; ctx.lineWidth = 2; ctx.strokeRect(bx + bw / 2 - 22, by - 24, 44, 22);
        ctx.fillStyle = "#fef08a"; ctx.fillRect(bx + bw / 2 - 10, by - 19, 20, 12);
      }
      const signText = b.id === "farmhouse" ? `🏡 ${state.cottageName.slice(0, 12)}` : (b.sign || b.name);
      ctx.font = "bold 10.5px 'Noto Sans Thai', sans-serif"; ctx.textAlign = "center";
      const sw = Math.max(78, signText.length * 6.5);
      ctx.fillStyle = "#4c230a"; ctx.fillRect(bx + bw / 2 - sw / 2 - 2, by + 4, sw + 4, 18);
      ctx.fillStyle = "#fbf0d9"; ctx.fillRect(bx + bw / 2 - sw / 2, by + 6, sw, 14);
      ctx.fillStyle = "#3f1d0b"; ctx.fillText(signText, bx + bw / 2, by + 16.5);
    }

    function drawWorldTree(now) {
      const cx = 42 * TILE, cy = 27.5 * TILE;
      const seals = getAwakenedSealCount();
      const finale = !!state.chroniclesDone?.main_ch5 || !!state.spouseId;
      const glowPulse = (finale ? 0.52 : 0.22 + (seals / 8) * 0.35) + Math.sin(now / 450) * 0.08;
      const auraR = finale ? 190 : 130 + seals * 8;
      const aura = ctx.createRadialGradient(cx, cy - 38, 12, cx, cy - 38, auraR);
      aura.addColorStop(0, `rgba(253, 224, 71, ${glowPulse})`);
      aura.addColorStop(1, "rgba(250, 204, 21, 0)");
      ctx.fillStyle = aura; ctx.beginPath(); ctx.arc(cx, cy - 38, auraR, 0, Math.PI * 2); ctx.fill();

      const wtSheet = SPRITES.world.world_tree_states;
      if (wtSheet) {
        const srcX = finale ? 256 : 0;
        ctx.drawImage(wtSheet, srcX, 0, 256, 256, cx - 118, cy - 196, 236, 224);
      }
      for (let i = 0; i < 8; i++) {
        const ang = (i / 8) * Math.PI * 2 + now / 2200;
        const rx = cx + Math.cos(ang) * 44, ry = cy + 6 + Math.sin(ang) * 14;
        ctx.fillStyle = (finale || i < seals) ? "#fde047" : "rgba(148,163,184,0.45)";
        ctx.beginPath(); ctx.arc(rx, ry, (finale || i < seals) ? 4.8 : 3, 0, Math.PI * 2); ctx.fill();
      }
      // Glowing Under-Root Ancient Ruins Stone Portal Archway at (39, 27)!
      const px = (RUINS_ENTRANCE.tx + 0.5) * TILE, py = (RUINS_ENTRANCE.ty + 0.5) * TILE;
      ctx.fillStyle = "#1e293b"; ctx.fillRect(px - 15, py - 24, 30, 28);
      ctx.strokeStyle = "#38bdf8"; ctx.lineWidth = 2.5; ctx.strokeRect(px - 15, py - 24, 30, 28);
      ctx.fillStyle = `rgba(56, 189, 248, ${0.55 + Math.sin(now / 260) * 0.25})`;
      ctx.fillRect(px - 10, py - 19, 20, 22);
      ctx.font = "bold 9.5px 'Noto Sans Thai', sans-serif"; ctx.textAlign = "center";
      ctx.fillStyle = "#e0f2fe"; ctx.fillText("🔦 โบราณสถาน", px, py - 28);
    }

    function drawLandmark25D(lm, now) {
      const bx = lm.tx * TILE, by = lm.ty * TILE, bw = lm.w * TILE, bh = lm.h * TILE;
      const cx = bx + bw / 2;
      const built = !!state.landmarksBuilt[lm.id];
      const key = `${lm.id}_${built ? "restored" : "ruined"}`;
      const spr = SPRITES.world.landmarks[key];
      if (spr) {
        ctx.drawImage(spr, bx - 6, by - 16, bw + 12, bh + 20);
      }
      const signText = built ? `${lm.icon} ${lm.name_th}` : `🚧 บูรณะ: ${lm.icon} ${lm.name_th.slice(0, 10)}`;
      ctx.font = "bold 10px 'Noto Sans Thai', sans-serif"; ctx.textAlign = "center";
      const sw = Math.max(94, signText.length * 6);
      ctx.fillStyle = built ? "#134e4a" : "#4c230a"; ctx.fillRect(cx - sw / 2 - 2, by - 18, sw + 4, 17);
      ctx.fillStyle = built ? "#f0fdfa" : "#fef3c7"; ctx.fillRect(cx - sw / 2, by - 16, sw, 13);
      ctx.fillStyle = built ? "#0f766e" : "#9a3412"; ctx.fillText(signText, cx, by - 6);
    }

    function drawTree(t, now) {
      const x = t.x * TILE + 16, y = t.y * TILE + 24;
      const cal = getCalendarInfo();
      const sw = Math.sin(now / 1100 + t.x) * 1.6;
      const propsImg = SPRITES.world.props_and_trees;
      if (propsImg) {
        const col = cal.seasonIdx; // 0=spring, 1=summer, 2=autumn, 3=winter in row 0!
        ctx.drawImage(propsImg, col * 64, 0, 64, 96, x - 32 + sw, y - 78, 64, 86);
        return;
      }
      ctx.fillStyle = "#5c3317"; ctx.fillRect(x - 5, y - 22, 10, 26);
      ctx.fillStyle = "#166534"; ctx.beginPath(); ctx.arc(x + sw, y - 30, 20, 0, Math.PI * 2); ctx.fill();
    }

    function renderAncientRuinsRoom(fl, now) {
      const rw = fl.w * TILE, rh = fl.h * TILE;
      const rs = state.ruins[fl.id];
      const beamRes = computeRuinsBeams(fl.id);
      const statusEl = document.getElementById("ruinsFloorStatus");
      if (statusEl) statusEl.textContent = `🔦 แท่นรับแสง: ${beamRes.litReceptors}/${beamRes.totalReceptors} ${rs.solved ? "✨ เปิดผนึกแล้ว!" : ""}`;

      // Mystic Mossy Stone Wall & Floor
      ctx.fillStyle = "#1e1b4b"; ctx.fillRect(0, 0, rw, 2 * TILE);
      for (let y = 2; y < fl.h - 1; y++) {
        for (let x = 1; x < fl.w - 1; x++) {
          ctx.fillStyle = (x + y) % 2 === 0 ? "#1e293b" : "#172033";
          ctx.fillRect(x * TILE, y * TILE, TILE, TILE);
          ctx.strokeStyle = "rgba(56, 189, 248, 0.12)"; ctx.lineWidth = 1;
          ctx.strokeRect(x * TILE, y * TILE, TILE, TILE);
        }
      }
      ctx.strokeStyle = "#38bdf8"; ctx.lineWidth = 4; ctx.strokeRect(2, 2, rw - 4, rh - 4);

      // Exit Stairs Up
      ctx.fillStyle = "#475569"; ctx.fillRect(fl.exitUp.x * TILE, fl.exitUp.y * TILE, TILE, TILE);
      ctx.fillStyle = "#fde047"; ctx.font = "bold 10px sans-serif"; ctx.textAlign = "center";
      ctx.fillText("🪜 UP", fl.exitUp.x * TILE + 16, fl.exitUp.y * TILE + 20);

      // Stairs Down Portal
      if (fl.stairsDown) {
        const sx = fl.stairsDown.x * TILE, sy = fl.stairsDown.y * TILE;
        ctx.fillStyle = rs.solved ? "#0284c7" : "#334155";
        ctx.fillRect(sx, sy, TILE, TILE);
        ctx.strokeStyle = rs.solved ? "#fde047" : "#ef4444"; ctx.lineWidth = 2; ctx.strokeRect(sx + 2, sy + 2, TILE - 4, TILE - 4);
        ctx.fillStyle = "#fff"; ctx.fillText(rs.solved ? "🌀 B" + (fl.depth + 1) : "🔒", sx + 16, sy + 20);
      }

      // Stone Blocks
      fl.blocks.forEach(b => {
        ctx.fillStyle = "#334155"; ctx.fillRect(b.x * TILE + 2, b.y * TILE + 2, TILE - 4, TILE - 4);
        ctx.strokeStyle = "#64748b"; ctx.strokeRect(b.x * TILE + 4, b.y * TILE + 4, TILE - 8, TILE - 8);
      });

      // Emitters
      fl.emitters.forEach(e => {
        const ex = e.x * TILE + 16, ey = e.y * TILE + 16;
        ctx.fillStyle = "#4c1d95"; ctx.fillRect(ex - 13, ey - 13, 26, 26);
        ctx.fillStyle = e.color; ctx.beginPath(); ctx.arc(ex, ey, 8 + Math.sin(now / 180) * 2, 0, Math.PI * 2); ctx.fill();
      });

      // Receptors
      fl.receptors.forEach((r, idx) => {
        const rx = r.x * TILE + 16, ry = r.y * TILE + 16;
        const lit = beamRes.litSet.has(idx);
        ctx.fillStyle = lit ? "#14532d" : "#1e293b";
        ctx.beginPath(); ctx.arc(rx, ry, 14, 0, Math.PI * 2); ctx.fill();
        ctx.strokeStyle = lit ? "#4ade80" : "#94a3b8"; ctx.lineWidth = 2.5; ctx.stroke();
        ctx.fillStyle = lit ? "#fde047" : "#475569";
        ctx.beginPath(); ctx.arc(rx, ry, 7, 0, Math.PI * 2); ctx.fill();
      });

      // Prism Pillars (with clear visual mirror slash / or \ or ✦!)
      fl.pillars.forEach((p, idx) => {
        const px = p.x * TILE + 16, py = p.y * TILE + 16;
        const mState = rs.pillars[idx] ?? p.init;
        ctx.fillStyle = "#0f172a"; ctx.fillRect(px - 13, py - 13, 26, 26);
        ctx.strokeStyle = "#38bdf8"; ctx.lineWidth = 2; ctx.strokeRect(px - 13, py - 13, 26, 26);
        ctx.strokeStyle = "#fef08a"; ctx.lineWidth = 4; ctx.beginPath();
        if (mState === 0) { // '/'
          ctx.moveTo(px - 9, py + 9); ctx.lineTo(px + 9, py - 9);
        } else if (mState === 1) { // '\'
          ctx.moveTo(px - 9, py - 9); ctx.lineTo(px + 9, py + 9);
        } else { // '✦' Splitter
          ctx.moveTo(px - 10, py); ctx.lineTo(px + 10, py);
          ctx.moveTo(px, py - 10); ctx.lineTo(px, py + 10);
        }
        ctx.stroke();
      });

      // Raycasted Laser Light Beams!
      beamRes.segments.forEach(seg => {
        const x1 = seg.x1 * TILE + 16, y1 = seg.y1 * TILE + 16;
        const x2 = seg.x2 * TILE + 16, y2 = seg.y2 * TILE + 16;
        ctx.save();
        ctx.strokeStyle = seg.color; ctx.lineWidth = 6 + Math.sin(now / 120) * 1.5; ctx.globalAlpha = 0.35;
        ctx.beginPath(); ctx.moveTo(x1, y1); ctx.lineTo(x2, y2); ctx.stroke();
        ctx.strokeStyle = "#ffffff"; ctx.lineWidth = 2.5; ctx.globalAlpha = 0.95;
        ctx.beginPath(); ctx.moveTo(x1, y1); ctx.lineTo(x2, y2); ctx.stroke();
        ctx.restore();
      });

      // Ancient Treasure Chest
      if (fl.chest) {
        const cx = fl.chest.x * TILE + 4, cy = fl.chest.y * TILE + 6;
        ctx.fillStyle = rs.chestOpened ? "#475569" : (rs.solved ? "#d97706" : "#7c2d12");
        ctx.fillRect(cx, cy, 24, 20);
        ctx.strokeStyle = rs.solved ? "#fde047" : "#f43f5e"; ctx.lineWidth = 2; ctx.strokeRect(cx, cy, 24, 20);
        ctx.font = "13px sans-serif"; ctx.textAlign = "center";
        ctx.fillText(rs.chestOpened ? "📭" : (rs.solved ? "🎁" : "🔒"), cx + 12, cy + 15);
      }

      // Daily Mana Ore Nodes
      fl.ores.forEach((ore, idx) => {
        if (rs.minedDay?.[idx] === state.day) return;
        const ox = ore.x * TILE + 16, oy = ore.y * TILE + 16;
        ctx.fillStyle = "rgba(56, 189, 248, 0.25)"; ctx.beginPath(); ctx.arc(ox, oy, 13, 0, Math.PI * 2); ctx.fill();
        const itImg = ITEM_IMAGES[ore.item_id];
        if (itImg) ctx.drawImage(itImg, ox - 12, oy - 12, 24, 24);
        else { ctx.fillStyle = "#38bdf8"; ctx.fillRect(ox - 8, oy - 8, 16, 16); }
      });
    }

    function render(now) {
      ctx.imageSmoothingEnabled = false;
      ctx.fillStyle = "#0f172a";
      ctx.fillRect(0, 0, canvas.width, canvas.height);
      if (!assetsReady) return;

      const cam = getCamera(), cal = getCalendarInfo();
      const h = state.timeMin / 60, isNight = h >= 17.5 || h < 6;
      ctx.save();
      ctx.scale(cam.zoom, cam.zoom);
      ctx.translate(-Math.round(cam.x), -Math.round(cam.y));

      const drawables = [];

      if (state.scene === "outdoor") {
        const x0 = Math.max(0, Math.floor(cam.x / TILE) - 1), y0 = Math.max(0, Math.floor(cam.y / TILE) - 1);
        const x1 = Math.min(MAP_W - 1, Math.ceil((cam.x + cam.vw) / TILE) + 1), y1 = Math.min(MAP_H - 1, Math.ceil((cam.y + cam.vh) / TILE) + 1);
        const waterShift = Math.floor(now / 360) % 3;

        for (let y = y0; y <= y1; y++) {
          for (let x = x0; x <= x1; x++) {
            const t = mapGrid[y][x], px = x * TILE, py = y * TILE;
            if (t === 0 || t === 5 || t === 6) ctx.drawImage(TILE_CACHE[`grass_${cal.season.id}_${(x + y) % 2}`], px, py);
            else if (t === 7) ctx.drawImage(TILE_CACHE[`flower_${cal.season.id}`], px, py);
            else if (t === 8) ctx.drawImage(TILE_CACHE.forest, px, py);
            else if (t === 1) ctx.drawImage(TILE_CACHE.stone, px, py);
            else if (t === 2) ctx.drawImage(TILE_CACHE.dirt, px, py);
            else if (t === 3) {
              ctx.fillStyle = "#1d4ed8"; ctx.fillRect(px, py, TILE, TILE);
              ctx.fillStyle = "#2563eb"; ctx.fillRect(px, py + 2, TILE, TILE - 4);
              const waveX = ((x * 7 + waterShift * 6) % 16) + 2;
              ctx.fillStyle = "#60a5fa"; ctx.fillRect(px + waveX, py + 9, 12, 2.5);
            } else if (t === 4) ctx.drawImage(TILE_CACHE.bridge, px, py);
          }
        }

        forageSpots.forEach(fs => {
          if (fs.collected) return;
          const fx = fs.tx * TILE + 16, fy = fs.ty * TILE + 16, pulse = 5 + Math.sin(now / 220 + fs.tx) * 2.5;
          ctx.fillStyle = "rgba(250, 204, 21, 0.32)"; ctx.beginPath(); ctx.arc(fx, fy, pulse + 6, 0, Math.PI * 2); ctx.fill();
          const itImg = ITEM_IMAGES[fs.item_id];
          if (itImg && itImg.complete !== false) ctx.drawImage(itImg, fx - 12, fy - 14 + Math.round(Math.sin(now / 260 + fs.tx) * 2), 24, 24);
        });

        BUILDINGS.forEach(b => drawables.push({ y: (b.y + b.h) * TILE, fn: () => drawBuilding25D(b, isNight) }));
        LANDMARKS.forEach(lm => drawables.push({ y: (lm.ty + lm.h) * TILE, fn: () => drawLandmark25D(lm, now) }));
        drawables.push({ y: 28.6 * TILE, fn: () => drawWorldTree(now) });
        TREES.forEach(t => drawables.push({ y: (t.y + 0.85) * TILE, fn: () => drawTree(t, now) }));

        drawables.push({
          y: (MAILBOX_POS.ty + 1) * TILE,
          fn: () => {
            const mx = MAILBOX_POS.tx * TILE + 8, my = MAILBOX_POS.ty * TILE + 6;
            ctx.fillStyle = "#6b3814"; ctx.fillRect(mx + 7, my + 8, 4, 15);
            ctx.fillStyle = "#dc2626"; ctx.fillRect(mx + 2, my, 15, 11);
            const unread = state.mailbox.filter(m => !m.read || (!m.claimed && (m.gift_id || m.gold))).length;
            if (unread > 0) {
              const bob = Math.sin(now / 180) * 3;
              ctx.fillStyle = "#fff"; ctx.fillRect(mx + 2, my - 15 + bob, 14, 10);
              ctx.strokeStyle = "#b91c1c"; ctx.lineWidth = 1.5; ctx.strokeRect(mx + 2, my - 15 + bob, 14, 10);
            }
          }
        });
        drawables.push({
          y: (BULLETIN_BOARD.ty + 1) * TILE,
          fn: () => {
            const bx = BULLETIN_BOARD.tx * TILE, by = BULLETIN_BOARD.ty * TILE;
            ctx.fillStyle = "#5b2c0d"; ctx.fillRect(bx + 5, by + 12, 4, 18); ctx.fillRect(bx + 23, by + 12, 4, 18);
            ctx.fillStyle = "#8d4d1d"; ctx.fillRect(bx + 1, by - 2, 30, 18);
            ctx.fillStyle = "#f4dfb7"; ctx.fillRect(bx + 4, by + 1, 10, 11); ctx.fillRect(bx + 16, by + 2, 11, 10);
          }
        });
        LANTERNS.forEach(l => drawables.push({
          y: (l.y + 0.8) * TILE,
          fn: () => {
            const lx = l.x * TILE + 16, ly = l.y * TILE + 24;
            ctx.fillStyle = "#334155"; ctx.fillRect(lx - 2, ly - 24, 4, 26);
            ctx.fillStyle = "#fde047"; ctx.fillRect(lx - 4, ly - 29, 8, 8);
          }
        }));
      } else if (RUINS_FLOORS[state.scene]) {
        renderAncientRuinsRoom(RUINS_FLOORS[state.scene], now);
      } else {
        // Indoor Room + 2nd Floor Starlight Loft + Grid-Placed Furniture!
        const rm = INDOORS[state.scene], rw = rm.w * TILE, rh = rm.h * TILE;
        ctx.fillStyle = rm.wall; ctx.fillRect(0, 0, rw, 2 * TILE);
        if (rm.isLoft) {
          // Starry Panoramic Skylight Windows on 2nd Floor!
          ctx.fillStyle = "#0f172a"; ctx.fillRect(3 * TILE, 8, (rm.w - 6) * TILE, 46);
          ctx.strokeStyle = "#fde047"; ctx.lineWidth = 2; ctx.strokeRect(3 * TILE, 8, (rm.w - 6) * TILE, 46);
          for (let i = 0; i < 14; i++) {
            ctx.fillStyle = i % 2 === 0 ? "#fef08a" : "#bae6fd";
            ctx.beginPath(); ctx.arc(3.5 * TILE + i * 19, 18 + (i * 11) % 24, 1.8 + Math.sin(now / 300 + i) * 0.8, 0, Math.PI * 2); ctx.fill();
          }
        } else {
          [3, rm.w - 5].forEach(wx => {
            ctx.fillStyle = "#4c230a"; ctx.fillRect(wx * TILE, 14, 48, 34);
            ctx.fillStyle = isNight ? "#1e1b4b" : "#7dd3fc"; ctx.fillRect(wx * TILE + 3, 17, 42, 28);
          });
        }

        for (let y = 2; y < rm.h - 1; y++) {
          for (let x = 1; x < rm.w - 1; x++) {
            ctx.fillStyle = rm.floor; ctx.fillRect(x * TILE, y * TILE, TILE, TILE);
            ctx.strokeStyle = state.homeEditMode ? "rgba(255,255,255,0.38)" : "rgba(60,30,10,0.14)";
            ctx.lineWidth = state.homeEditMode ? 1.4 : 1;
            ctx.strokeRect(x * TILE, y * TILE, TILE, TILE);
          }
        }
        ctx.fillStyle = rm.rug; ctx.fillRect(Math.floor(rm.w * 0.3) * TILE, 5 * TILE, Math.floor(rm.w * 0.4) * TILE, 3 * TILE);
        ctx.fillStyle = "#dc2626"; ctx.fillRect(rm.exitX * TILE, rm.exitY * TILE + 6, TILE, TILE - 8);
        ctx.fillStyle = "#fef3c7"; ctx.font = "bold 9px sans-serif"; ctx.textAlign = "center";
        ctx.fillText(rm.isLoft ? "DOWN" : "EXIT", rm.exitX * TILE + 16, rm.exitY * TILE + 22);

        // Wooden Stairs Up to 2nd Floor Starlight Loft!
        if (state.scene === "farmhouse" && state.houseLevel >= 2 && rm.stairsUp) {
          const sx = rm.stairsUp.x * TILE, sy = rm.stairsUp.y * TILE;
          ctx.fillStyle = "#78350f"; ctx.fillRect(sx, sy, TILE * 2, TILE * 2);
          for (let s = 0; s < 5; s++) {
            ctx.fillStyle = s % 2 === 0 ? "#d97706" : "#b45309";
            ctx.fillRect(sx + 4, sy + 4 + s * 11, TILE * 2 - 8, 8);
          }
          ctx.fillStyle = "#fef08a"; ctx.font = "bold 9.5px 'Noto Sans Thai', sans-serif";
          ctx.fillText("🌟 ชั้น 2", sx + TILE, sy - 4);
        }
        ctx.strokeStyle = "#2b1205"; ctx.lineWidth = 6; ctx.strokeRect(0, 0, rw, rh);

        // Render Grid-Placed Custom Furniture!
        if (isHomeScene()) {
          (state.decorPlaced || []).forEach(pl => {
            if (pl.scene !== state.scene) return;
            const d = DECOR_BY_ID[pl.id]; if (!d) return;
            const drawFn = () => {
              const dx = pl.x * TILE, dy = pl.y * TILE, dw = pl.w * TILE, dh = pl.h * TILE;
              ctx.fillStyle = "rgba(0,0,0,0.22)"; ctx.fillRect(dx + 2, dy + dh - 4, dw - 4, 5);
              ctx.fillStyle = d.color; ctx.fillRect(dx + 2, dy + 2, dw - 4, dh - 4);
              ctx.strokeStyle = "#fde68a"; ctx.lineWidth = 1.6; ctx.strokeRect(dx + 2, dy + 2, dw - 4, dh - 4);
              ctx.font = "16px sans-serif"; ctx.textAlign = "center";
              ctx.fillText(d.icon, dx + dw / 2, dy + dh / 2 + 6);
            };
            if (d.passable) drawFn();
            else drawables.push({ y: (pl.y + pl.h) * TILE, fn: drawFn });
          });

          // Ghost Placement Preview in [H] Mode!
          if (state.homeEditMode && state.selectedDecorId) {
            const d = DECOR_BY_ID[state.selectedDecorId];
            if (d) {
              const gw = state.selectedDecorRot === 1 ? d.h : d.w;
              const gh = state.selectedDecorRot === 1 ? d.w : d.h;
              const gx = state.mouseWorld.tx, gy = state.mouseWorld.ty;
              const ok = canPlaceDecorAt(d.id, state.scene, gx, gy, gw, gh);
              ctx.fillStyle = ok ? "rgba(34, 197, 94, 0.45)" : "rgba(239, 68, 68, 0.48)";
              ctx.fillRect(gx * TILE, gy * TILE, gw * TILE, gh * TILE);
              ctx.strokeStyle = ok ? "#4ade80" : "#f87171"; ctx.lineWidth = 2.5;
              ctx.strokeRect(gx * TILE, gy * TILE, gw * TILE, gh * TILE);
              ctx.font = "16px sans-serif"; ctx.textAlign = "center";
              ctx.fillText(d.icon, (gx + gw / 2) * TILE, (gy + gh / 2) * TILE + 6);
            }
          }
        }

        rm.furniture.forEach(f => {
          drawables.push({
            y: (f.y + f.h) * TILE,
            fn: () => {
              const fx = f.x * TILE, fy = f.y * TILE, fw = f.w * TILE, fh = f.h * TILE;
              if (f.type === "bed") {
                ctx.fillStyle = "#5c2c0e"; ctx.fillRect(fx, fy, fw, fh);
                ctx.fillStyle = "#f8fafc"; ctx.fillRect(fx + 5, fy + 6, fw - 10, 17);
                ctx.fillStyle = state.spouseId ? "#e11d48" : "#2563eb"; ctx.fillRect(fx + 5, fy + 23, fw - 10, fh - 28);
              } else if (f.type === "oven" || f.type === "fireplace") {
                ctx.fillStyle = "#475569"; ctx.fillRect(fx, fy, fw, fh);
                ctx.fillStyle = "#f97316"; ctx.fillRect(fx + fw * 0.25, fy + fh * 0.4, fw * 0.5, fh * 0.45);
              } else if (f.type === "skylight") {
                ctx.fillStyle = "rgba(56, 189, 248, 0.25)"; ctx.fillRect(fx, fy, fw, fh);
                ctx.strokeStyle = "#fde047"; ctx.strokeRect(fx + 2, fy + 2, fw - 4, fh - 4);
              } else {
                ctx.fillStyle = "#6b3814"; ctx.fillRect(fx, fy, fw, fh);
                ctx.fillStyle = "#a16207"; ctx.fillRect(fx + 3, fy + 3, fw - 6, fh - 10);
              }
            }
          });
        });
      }

      // NPCs
      for (const n of NPCS) {
        if (n.scene !== state.scene) continue;
        drawables.push({
          y: n.py,
          fn: () => {
            const mode = n.state === "walk" ? "walk" : (n.state === "interact" ? "interact" : "idle");
            const cols = mode === "walk" ? 9 : mode === "interact" ? 8 : 6;
            drawSprite(n.id, mode, mode === "interact" ? n.actionRow : n.dir, Math.floor(n.animT) % cols, n.px, n.py, false);
            ctx.fillStyle = "rgba(15,23,42,0.76)"; ctx.fillRect(n.px - 36, n.py - 64, 72, 14);
            ctx.fillStyle = "#fef3c7"; ctx.font = "bold 9px 'Noto Sans Thai', sans-serif"; ctx.textAlign = "center";
            ctx.fillText(n.name.split(" ")[0], n.px, n.py - 54);
            let emote = null;
            if (state.spouseId === n.id) emote = "💒";
            else if (getUnlockedEventForNpc(n.id)) emote = "💖";
            else if (NPC_BIRTHDAYS[n.id] === cal.dayOfSeason) emote = "🎂";
            else if (state.partners[n.id]) emote = "💑";
            if (emote) { ctx.font = "13px sans-serif"; ctx.fillText(emote, n.px, n.py - 70 + Math.sin(now / 260 + n.px) * 3); }
          }
        });
      }

      // Pet & Custom Recolored Protagonist!
      drawables.push({ y: state.pet.y, fn: () => drawPet(now) });
      drawables.push({
        y: state.player.y,
        fn: () => {
          const heroId = state.heroCustom.baseId || "01_ren";
          if (state.player.interactT > 0) drawSprite(heroId, "interact", 1, Math.floor(now / 90) % 8, state.player.x, state.player.y, true);
          else if (state.player.moving) drawSprite(heroId, "walk", state.player.dir, Math.floor(state.player.animT) % 9, state.player.x, state.player.y, true);
          else drawSprite(heroId, "idle", state.player.dir, Math.floor(state.player.animT) % 6, state.player.x, state.player.y, true);
        }
      });

      drawables.sort((a, b) => a.y - b.y);
      for (const d of drawables) d.fn();

      if (state.scene === "outdoor") {
        for (const sm of chimneySmoke) {
          ctx.fillStyle = `rgba(241, 245, 249, ${Math.max(0, sm.life * 0.25)})`;
          ctx.beginPath(); ctx.arc(sm.x, sm.y, sm.r, 0, Math.PI * 2); ctx.fill();
        }
      }

      // Compass Arrow
      {
        let tx = null, ty = null;
        if (state.compassNpcId) {
          const targetNpc = NPCS.find(x => x.id === state.compassNpcId);
          if (targetNpc) {
            if (targetNpc.scene === state.scene) { tx = targetNpc.px; ty = targetNpc.py; }
            else if (state.scene === "outdoor") {
              const targetB = targetNpc.scene === "farmhouse_upstairs" ? "farmhouse" : targetNpc.scene;
              const b = BUILDINGS.find(x => x.interiorId === targetB);
              if (b) { tx = (b.doorX + 0.5) * TILE; ty = b.doorY * TILE; }
            }
          }
        } else if (state.compassLandmarkId && state.scene === "outdoor") {
          const lm = LANDMARK_BY_ID[state.compassLandmarkId];
          if (lm) { tx = lm.interactX * TILE; ty = lm.interactY * TILE; }
        }
        if (tx !== null) {
          const ang = Math.atan2(ty - state.player.y, tx - state.player.x);
          const ax = state.player.x + Math.cos(ang) * 32, ay = state.player.y - 18 + Math.sin(ang) * 32;
          ctx.save(); ctx.translate(ax, ay); ctx.rotate(ang);
          ctx.fillStyle = "#fde047"; ctx.strokeStyle = "#78350f"; ctx.lineWidth = 1.5;
          ctx.beginPath(); ctx.moveTo(8, 0); ctx.lineTo(-5, -5); ctx.lineTo(-5, 5); ctx.closePath(); ctx.fill(); ctx.stroke(); ctx.restore();
        }
      }

      for (const pt of particles) { ctx.globalAlpha = Math.max(0, pt.life); ctx.fillStyle = pt.color; ctx.beginPath(); ctx.arc(pt.x, pt.y, pt.size, 0, Math.PI * 2); ctx.fill(); }
      ctx.globalAlpha = 1;
      for (const ft of floatingTexts) {
        ctx.globalAlpha = Math.max(0, ft.life / ft.maxLife);
        ctx.font = "bold 12px 'Noto Sans Thai', sans-serif"; ctx.textAlign = "center";
        ctx.fillStyle = "#0f172a"; ctx.fillText(ft.text, ft.x + 1, ft.y + 1);
        ctx.fillStyle = ft.color; ctx.fillText(ft.text, ft.x, ft.y);
      }
      ctx.globalAlpha = 1;

      if (state.scene === "outdoor") {
        let tint = null;
        if (h >= 17 && h < 19.5) tint = `rgba(217, 119, 6, ${((h - 17) / 2.5) * 0.24})`;
        else if (h >= 19.5 || h < 5.5) tint = "rgba(15, 23, 56, 0.46)";
        if (tint) {
          ctx.fillStyle = tint; ctx.fillRect(cam.x - 10, cam.y - 10, cam.vw + 20, cam.vh + 20);
          if (isNight) {
            if (state.tool === 8) {
              const pg = ctx.createRadialGradient(state.player.x, state.player.y - 10, 6, state.player.x, state.player.y - 10, 110);
              pg.addColorStop(0, "rgba(254, 240, 138, 0.56)"); pg.addColorStop(1, "rgba(251, 191, 36, 0)");
              ctx.fillStyle = pg; ctx.beginPath(); ctx.arc(state.player.x, state.player.y - 10, 110, 0, Math.PI * 2); ctx.fill();
            }
            LANTERNS.forEach(l => {
              const g = ctx.createRadialGradient(l.x*TILE+16, l.y*TILE, 4, l.x*TILE+16, l.y*TILE, 72);
              g.addColorStop(0, "rgba(253, 224, 71, 0.42)"); g.addColorStop(1, "rgba(253, 224, 71, 0)");
              ctx.fillStyle = g; ctx.beginPath(); ctx.arc(l.x*TILE+16, l.y*TILE, 72, 0, Math.PI*2); ctx.fill();
            });
          }
        }
        if (state.weather === "rainy") {
          ctx.fillStyle = "rgba(30, 58, 138, 0.14)"; ctx.fillRect(cam.x - 10, cam.y - 10, cam.vw + 20, cam.vh + 20);
          ctx.strokeStyle = "rgba(191, 219, 254, 0.55)"; ctx.lineWidth = 1.2; ctx.beginPath();
          const t = now * 0.45;
          for (let i = 0; i < 80; i++) {
            const rx = cam.x + ((i * 97 + t * 0.6) % (cam.vw + 40)) - 20;
            const ry = cam.y + ((i * 61 + t * 1.4) % (cam.vh + 40)) - 20;
            ctx.moveTo(rx, ry); ctx.lineTo(rx - 4, ry + 11);
          }
          ctx.stroke();
        }
      }
      ctx.restore();
      if (state.worldMapOpen) renderStardewWorldMap(now);
    }

    // Boot Save Slot 1 & Start Loop!
    loadSaveSlot(1, false);
    let last = performance.now();
    function tick(now) {
      const dt = Math.min(0.05, (now - last) / 1000);
      last = now; update(dt); render(now); requestAnimationFrame(tick);
    }
    preloadAssets(() => { requestAnimationFrame(tick); });
"""


def build_html(src_dir: str, out_path: str) -> None:
    assets = load_all_assets(src_dir)
    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(HTML_HEAD_AND_BODY)
        f.write("  <script>\n  (() => {\n    \"use strict\";\n")
        f.write(f"    const WALK_B64 = {json.dumps(assets['walk_b64'])};\n")
        f.write(f"    const IDLE_B64 = {json.dumps(assets['idle_b64'])};\n")
        f.write(f"    const INT_B64  = {json.dumps(assets['int_b64'])};\n")
        f.write(f"    const PORT_B64 = {json.dumps(assets['port_b64'])};\n")
        f.write(f"    const GAME_DATA = {json.dumps(assets['game_data'], ensure_ascii=False)};\n")
        f.write(f"    const PET_B64 = {json.dumps(assets['pet_b64'])};\n")
        f.write(f"    const ITEM_ICON_B64 = {json.dumps(assets['item_icon_b64'])};\n")
        f.write(f"    const WORLD_B64 = {json.dumps(assets['world_b64'])};\n")
        f.write(JS_PART_1)
        f.write(JS_PART_2)
        f.write(JS_PART_3A)
        f.write(JS_PART_3B)
        f.write(JS_PART_4A)
        f.write(JS_PART_4B)
        f.write("\n  })();\n  </script>\n</body>\n</html>\n")
    sz_mb = os.path.getsize(out_path) / (1024 * 1024)
    print(f"[build_lifesim_v6] Successfully built {out_path} ({sz_mb:.2f} MB) with all 6 Deep Gameplay Systems!")


def main() -> None:
    parser = argparse.ArgumentParser(description="Build Aethelgard Life-Sim v6.0 HTML5 Game")
    parser.add_argument(
        "--src",
        default="/home/antigravity/aethelgard/drive_sync",
        help="Path to Aethelgard_SpriteSheets directory",
    )
    parser.add_argument(
        "--out",
        default="/home/antigravity/aethelgard/web_lifesim_v6/aethelgard_world_map.html",
        help="Output HTML path",
    )
    args = parser.parse_args()
    build_html(args.src, args.out)


if __name__ == "__main__":
    main()
