#!/usr/bin/env python3
"""
Generate runtime audio manifest for Godot.
Scans project/audio/ and creates audio_manifest.json.
"""

import os
import json
from pathlib import Path

# Paths
PROJECT_ROOT = Path(__file__).parent.parent
AUDIO_DIR = PROJECT_ROOT / "project" / "audio"
MANIFEST_OUTPUT = PROJECT_ROOT / "project" / "audio_manifest.json"

def generate_manifest():
    """Scan audio directory and create runtime manifest."""
    manifest = {}
    
    print(f"Scanning: {AUDIO_DIR}")
    
    if not AUDIO_DIR.exists():
        print("ERROR: Audio directory does not exist")
        return False
    
    file_count = 0
    
    for root, dirs, files in os.walk(AUDIO_DIR):
        for file in files:
            # Only process audio files
            if not file.lower().endswith(('.wav', '.ogg', '.mp3')):
                continue
            
            file_count += 1
            abs_path = Path(root) / file
            
            # Calculate Godot resource path (relative to project/)
            try:
                rel_path = abs_path.relative_to(PROJECT_ROOT / "project")
                godot_path = f"res://{rel_path.as_posix()}"
            except ValueError:
                print(f"  Warning: {abs_path} not in project folder")
                continue
            
            # Extract group ID from filename
            stem = abs_path.stem
            parts = stem.split('_')
            
            # Remove variation suffix (_01, _02, etc)
            if len(parts) > 1 and parts[-1].isdigit() and len(parts[-1]) <= 2:
                group_id = "_".join(parts[:-1])
            else:
                group_id = stem
            
            # Add to manifest
            if group_id not in manifest:
                manifest[group_id] = {
                    "files": [],
                    "volume_db": 0.0,
                    "pitch_scale": [0.95, 1.05],
                    "bus": "SFX"
                }
            
            manifest[group_id]["files"].append(godot_path)
            
            # Adjust settings based on type
            if "music" in group_id:
                manifest[group_id]["bus"] = "Music"
                manifest[group_id]["pitch_scale"] = [1.0, 1.0]
                manifest[group_id]["volume_db"] = -3.0
            elif "ui_" in group_id:
                manifest[group_id]["pitch_scale"] = [1.0, 1.0]
            elif "loop" in group_id:
                manifest[group_id]["pitch_scale"] = [1.0, 1.0]
    
    # Sort file lists for consistency
    for group_id in manifest:
        manifest[group_id]["files"] = sorted(manifest[group_id]["files"])
    
    # Write manifest
    with open(MANIFEST_OUTPUT, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    
    print(f"Found {file_count} audio files")
    print(f"Created {len(manifest)} audio groups")
    print(f"Manifest saved to: {MANIFEST_OUTPUT}")
    
    return True

if __name__ == "__main__":
    generate_manifest()
