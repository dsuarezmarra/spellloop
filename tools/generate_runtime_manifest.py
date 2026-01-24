import os
import json
from pathlib import Path

AUDIO_DIR = "project/audio"
MANIFEST_FILE = "project/audio_manifest.json"

def generate_runtime_manifest():
    manifest = {}
    
    print(f"Scanning {AUDIO_DIR}...")
    
    # Walk through the audio directory
    for root, dirs, files in os.walk(AUDIO_DIR):
        for file in files:
            if file.endswith(".wav") or file.endswith(".ogg") or file.endswith(".mp3"):
                # Rel path for Godot (res://audio/...)
                abs_path = (Path(root) / file).resolve()
                rel_path = abs_path.relative_to(Path.cwd().resolve()).as_posix()
                
                # Naming convention: sfx_category_name_variation.wav
                # Simple parsing: use the filename wrapper as the ID? 
                # Or just map "sfx_player_hurt" -> [list of files]
                
                # Heuristic: Remove the last number if it ends with _01, _02 etc
                stem = abs_path.stem
                
                # Check for variation suffix like _01, _02
                parts = stem.split('_')
                if parts[-1].isdigit() and len(parts[-1]) <= 2:
                    group_id = "_".join(parts[:-1])
                else:
                    group_id = stem
                    
                godot_path = f"res://{rel_path}"
                
                if group_id not in manifest:
                    manifest[group_id] = []
                
                manifest[group_id].append(godot_path)
                
    # Metadata injection (Volume/Pitch defaults)
    final_data = {}
    for group_id, paths in manifest.items():
        # Default properties
        entry = {
            "files": sorted(paths),
            "volume_db": 0.0,
            "pitch_scale": [0.95, 1.05] if "music" not in group_id else [1.0, 1.0],
            "bus": "Music" if "music" in group_id else "SFX"
        }
        
        # Specific overrides
        if "ui_" in group_id:
            entry["pitch_scale"] = [1.0, 1.0] # UI usually fixed pitch
        
        final_data[group_id] = entry

    with open(MANIFEST_FILE, "w", encoding="utf-8") as f:
        json.dump(final_data, f, indent=2)
        
    print(f"✅ Created runtime manifest with {len(final_data)} audio groups.")

if __name__ == "__main__":
    generate_runtime_manifest()
