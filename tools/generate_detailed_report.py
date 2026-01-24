#!/usr/bin/env python3
"""
Generate Detailed Audio Audit Report
Reads audio_manifest.json and creates a detailed markdown report with file paths.
"""

import json
from pathlib import Path
import datetime

PROJECT_ROOT = Path(__file__).parent.parent
MANIFEST_PATH = PROJECT_ROOT / "project" / "audio_manifest.json"
REPORT_PATH = Path(r"C:\Users\Usuario\.gemini\antigravity\brain\997646ed-5c6a-45ef-9b45-d115fdcdf263\audio_audit_report.md")

TRIGGER_MAP = {
    "sfx_ui_click": "Button interaction (UI)",
    "sfx_ui_hover": "Focus change (UI)",
    "sfx_ui_confirm": "Selection confirmation",
    "sfx_ui_cancel": "Back/Cancel action",
    "sfx_ui_start_game": "Game Start",
    "sfx_chest_open": "Treasure Chest Open",
    "sfx_player_hurt": "Player Take Damage",
    "sfx_player_heal": "Player Heal",
    "sfx_player_death": "Player Death",
    "sfx_level_up": "Level Up Event",
    "sfx_xp_pickup": "XP Gem Pickup",
    "sfx_dash": "Player Dash",
    "sfx_critical_hit": "Critical Damage Dealt",
    "sfx_item_pickup": "Item Collection",
    "music_intro_theme": "MainMenu (Loop)",
    "music_gameplay_loop": "Gameplay (Loop)",
    "music_boss_theme": "Boss Encounter (Loop)"
}

def get_trigger(key):
    if key in TRIGGER_MAP:
        return TRIGGER_MAP[key]
    if key.startswith("sfx_weapon_"):
        return "BaseWeapon.gd (Cast)"
    if "footstep" in key:
        return "SpellloopPlayer.gd (Movement)"
    return "Script Call / Auto"

def generate_report():
    if not MANIFEST_PATH.exists():
        print("Error: Manifest not found")
        return

    with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
        manifest = json.load(f)

    # Categorize
    categories = {
        "Music": {},
        "UI & Menu": {},
        "Weapons (Proyectiles)": {},
        "Footsteps & Biome": {},
        "Gameplay (Events/Pickups)": {},
        "Enemies": {}
    }

    for key, data in manifest.items():
        files = [f.replace("res://", "") for f in data.get("files", [])]
        files_str = "<br>".join([f"`{f}`" for f in files])
        
        entry = {
            "vol": data.get("volume_db", 0),
            "bus": data.get("bus", "SFX"),
            "files": files_str,
            "trigger": get_trigger(key)
        }

        if "music" in key:
            categories["Music"][key] = entry
        elif "sfx_ui" in key or "menu" in key:
            categories["UI & Menu"][key] = entry
        elif "sfx_weapon" in key:
            categories["Weapons (Proyectiles)"][key] = entry
        elif "footstep" in key:
            categories["Footsteps & Biome"][key] = entry
        elif "enemy" in key or "boss" in key:
            categories["Enemies"][key] = entry
        else:
            categories["Gameplay (Events/Pickups)"][key] = entry

    # Generate Markdown
    lines = []
    lines.append(f"# 🔊 Definitive Audio Audit Report")
    lines.append(f"Generated: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M')}")
    lines.append("")
    lines.append("## 📁 File Reference By Category")
    lines.append("This report lists the **exact file** used for every sound effect in the game.")
    lines.append("")

    for cat_name, items in categories.items():
        if not items: continue
        
        lines.append(f"### {cat_name}")
        lines.append("| ID (Code Key) | Volume | Bus | Exact File(s) Used |")
        lines.append("|---|---|---|---|")
        
        for key in sorted(items.keys()):
            data = items[key]
            lines.append(f"| `{key}` | {data['vol']} dB | {data['bus']} | {data['files']} |")
        
        lines.append("")

    lines.append("## 🎚️ Current Mixing Standards")
    lines.append("- **Proyectiles (Weapons)**: -11.0 dB (Mitad volumen)")
    lines.append("- **Music**: -12.0 dB")
    lines.append("- **Footsteps**: -15.0 dB")
    lines.append("- **UI**: -9.0 dB")
    lines.append("- **Standard SFX**: -6.0 dB")

    # Write
    with open(REPORT_PATH, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
        
    print(f"Report generated at {REPORT_PATH}")

if __name__ == "__main__":
    generate_report()
