#!/usr/bin/env python3
"""
Audio Mixing Script
Applies standardized volume levels and bus routing to the audio manifest.
"""

import json
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
MANIFEST_PATH = PROJECT_ROOT / "project" / "audio_manifest.json"

# Mixing Standards (dB)
MIX_LEVELS = {
    "music": -12.0,
    "ui": -9.0,
    "weapon": -11.0,
    "footstep": -15.0,
    "enemy": -10.0,
    "pickup": -8.0,
    "streak": -8.0, 
    "chest": -6.0
}

DEFAULT_SFX_LEVEL = -6.0

def apply_mix():
    if not MANIFEST_PATH.exists():
        print(f"Error: Manifest not found at {MANIFEST_PATH}")
        return

    with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
        manifest = json.load(f)
        
    print(f"Mixing {len(manifest)} audio groups...")
    
    count = 0
    for key, data in manifest.items():
        count += 1
        
        # Determine category
        new_vol = DEFAULT_SFX_LEVEL
        new_bus = "SFX"
        
        if "music" in key or key.startswith("music_"):
            new_vol = MIX_LEVELS["music"]
            new_bus = "Music"
        elif "sfx_ui" in key:
            new_vol = MIX_LEVELS["ui"]
        elif "sfx_weapon" in key:
            new_vol = MIX_LEVELS["weapon"]
        elif "footstep" in key:
            new_vol = MIX_LEVELS["footstep"]
        elif "sfx_enemy" in key or "boss" in key: # Enemy sounds (if enabled)
            new_vol = MIX_LEVELS["enemy"]
        elif "pickup" in key or "coin" in key or "streak" in key:
            new_vol = MIX_LEVELS["pickup"]
        
        # Apply
        data["volume_db"] = new_vol
        data["bus"] = new_bus
        
        # Ensure pitch randomization for SFX (except music/UI)
        if new_bus == "Music" or "ui" in key:
            data["pitch_scale"] = [1.0, 1.0]
        else:
            # Standard variety
            data["pitch_scale"] = [0.95, 1.05]
            
    with open(MANIFEST_PATH, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
        
    print(f"Mix applied to {count} groups.")

if __name__ == "__main__":
    apply_mix()
