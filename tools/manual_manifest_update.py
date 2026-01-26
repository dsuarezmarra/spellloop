import json
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent / "project"
MANIFEST_PATH = PROJECT_ROOT / "audio_manifest.json"

def main():
    with open(MANIFEST_PATH, 'r', encoding='utf-8') as f:
        manifest = json.load(f)
        
    # 1. Fix Cancel/Back
    cancel_file = "res://audio/sfx/ui/sfx_ui_cancel_01.mp3"
    
    # Update sfx_ui_back
    manifest["sfx_ui_back"] = {
        "files": [cancel_file],
        "volume_db": -6.0,
        "pitch_scale": [0.95, 1.05],
        "bus": "SFX"
    }
    print("Fixed sfx_ui_back")
    
    # Update sfx_ui_cancel
    manifest["sfx_ui_cancel"] = {
        "files": [cancel_file],
        "volume_db": -6.0,
        "pitch_scale": [0.95, 1.05],
        "bus": "SFX"
    }
    print("Fixed sfx_ui_cancel")
    
    # 2. Fix Navigation (Missing ID -> Silent)
    if "sfx_ui_navigation" not in manifest:
        manifest["sfx_ui_navigation"] = {
            "files": [], # Silent
            "volume_db": -6.0,
            "bus": "SFX"
        }
        print("Added sfx_ui_navigation (Silent)")

    # 3. Ensure sfx_ui_hover exists (even if silent)
    if "sfx_ui_hover" not in manifest:
         manifest["sfx_ui_hover"] = {
            "files": [],
            "volume_db": -6.0,
            "bus": "SFX"
        }
         print("Added sfx_ui_hover (Silent)")
    
    with open(MANIFEST_PATH, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, indent=2)

if __name__ == "__main__":
    main()
