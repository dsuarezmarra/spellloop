import json
import os
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent / "project"
MANIFEST_PATH = PROJECT_ROOT / "audio_manifest.json"
AUDIO_DIR = PROJECT_ROOT / "audio"

def main():
    print("Loading current manifest...")
    if MANIFEST_PATH.exists():
        with open(MANIFEST_PATH, 'r', encoding='utf-8') as f:
            manifest = json.load(f)
    else:
        manifest = {}

    # Define update rules
    # 1. UI Sounds
    ui_updates = {
        "sfx_ui_hover": {"volume_db": -12.0, "pitch_scale": [0.98, 1.02], "bus": "UI"},
        "sfx_ui_navigation": {"volume_db": -11.0, "pitch_scale": [0.98, 1.02], "bus": "UI"},
        "sfx_ui_back": {"volume_db": -9.0, "bus": "UI"}, # No random pitch for fixed sounds typically
        "sfx_ui_click": {"volume_db": -8.0, "bus": "UI"},
        "sfx_ui_confirm": {"volume_db": -8.0, "bus": "UI"},
        "sfx_ui_cancel": {"volume_db": -9.0, "bus": "UI"}, # Alias to back if needed
        "sfx_pause_open": {"volume_db": -8.0, "bus": "UI"},
        "sfx_pause_close": {"volume_db": -8.0, "bus": "UI"},
        "sfx_ui_character_select": {"volume_db": -9.0, "bus": "UI"},
    }

    # Helper to find files
    def find_files(category_path):
        found = []
        search_dir = AUDIO_DIR / category_path
        if not search_dir.exists():
            # Try searching res:// format in existing tree?
            # Better to assume they exist if generator worked, or scan disk
            return []
        
        for f in os.listdir(search_dir):
            if f.endswith(".import"): continue
            if f.endswith(".txt"): continue
            # Sort by name
            found.append(f)
        found.sort()
        return [f"res://audio/{category_path}/{f}" for f in found]

    # Update UI
    print("Updating UI definitions...")
    # sfx_ui_hover
    hover_files = find_files("sfx/ui") # Wait, generator might output to audio/ui?
    # Generator uses OUTPUT_DIR / category. category="ui" -> audio/ui
    # existing structure is audio/sfx/ui
    # I need to check where generator put them.
    # The snippet says OUTPUT_DIR = project/audio. category="ui" -> project/audio/ui.
    # existing ui sounds are in project/audio/sfx/ui.
    # I should probably move them or check both.
    
    # Check "audio/ui" (generated)
    gen_ui = AUDIO_DIR / "ui"
    if gen_ui.exists():
        for f in os.listdir(gen_ui):
             # Move to sfx/ui for consistency? Or keep in ui?
             # User specified names: res://audio/sfx/ui/sfx_ui_hover_01.mp3
             # My manifest said category="ui", name="sfx_ui_hover".
             # Generator prompt said category="ui" -> audio/ui/sfx_ui_hover...
             # But user wanted res://audio/sfx/ui/...
             # I might need to move files.
             pass

    # Actually, let's scan recursively for the specific filenames expected.
    # sfx_ui_hover_*.mp3/wav
    
    def scan_for_prefix(prefix):
        matches = []
        for root, dirs, files in os.walk(AUDIO_DIR):
            for name in files:
                if name.startswith(prefix) and not name.endswith(".import"):
                     rel = Path(root).relative_to(PROJECT_ROOT)
                     matches.append(f"res://{str(rel).replace(os.sep, '/')}/{name}")
        return sorted(matches)

    for uid, rules in ui_updates.items():
        # Find files
        files = scan_for_prefix(uid)
        
        # Eliminate duplicates (user requirement 5)
        # Some might be in sfx/ui AND ui/ ?
        unique_files = list(set(files))
        unique_files.sort()
        
        if not unique_files and uid == "sfx_ui_cancel":
            # Alias to sfx_ui_back
            back_files = scan_for_prefix("sfx_ui_back")
            if back_files:
                unique_files = back_files
                print(f"Aliased sfx_ui_cancel to sfx_ui_back")

        if uid in manifest:
             manifest[uid].update(rules)
             manifest[uid]["files"] = unique_files
        else:
             manifest[uid] = rules
             manifest[uid]["files"] = unique_files

    # 2. Footsteps
    print("Updating Footsteps...")
    biomes = ["grass", "sand", "snow", "lava", "arcane", "void"]
    surfaces = ["ground", "path"]
    
    for b in biomes:
        for s in surfaces:
            key = f"sfx_footstep_{b}_{s}"
            # find files
            # Expected: sfx_footstep_grass_ground_01...
            files = scan_for_prefix(key)
            
            # Special case: map sfx_footstep_grass (legacy) to grass_ground if empty
            
            manifest[key] = {
                "files": files,
                "volume_db": -14.0,
                "pitch_scale": [0.95, 1.05],
                "bus": "SFX"
            }

    # Legacy mappings
    # sfx_footstep_grass -> alias to sfx_footstep_grass_ground
    legacy_map = {
        "sfx_footstep_grass": "sfx_footstep_grass_ground",
        "sfx_footstep_sand": "sfx_footstep_sand_ground",
        "sfx_footstep_snow": "sfx_footstep_snow_ground",
         "sfx_footstep_stone": "sfx_footstep_grass_path" # Map stone to path generic if needed
    }
    
    for old, new_key in legacy_map.items():
        if new_key in manifest and manifest[new_key]["files"]:
            manifest[old] = manifest[new_key].copy()
            # print(f"Mapped legacy {old} -> {new_key}")

    # clean empty files
    # User said: "Si falta... créalo". Assuming generator ran, we have files.
    # If still empty, we leave empty but ensure definition exists.

    with open(MANIFEST_PATH, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, indent=2)
    print("Manifest updated.")

if __name__ == "__main__":
    main()
