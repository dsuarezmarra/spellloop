import json
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent / "project"
MANIFEST_PATH = PROJECT_ROOT / "audio_manifest.json"

def main():
    print("Fixing BOM in manifest...")
    valid_key = "music_boss_theme"
    
    with open(MANIFEST_PATH, 'r', encoding='utf-8') as f:
        manifest = json.load(f)
        
    entry = manifest.get(valid_key)
    if entry:
        files = entry.get("files", [])
        new_files = []
        for f in files:
            # Strip BOM and whitespace
            clean_f = f.replace("\ufeff", "").strip()
            new_files.append(clean_f)
            
        entry["files"] = new_files
        print(f"Cleaned {valid_key}: {new_files}")
        
    with open(MANIFEST_PATH, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, indent=2)

if __name__ == "__main__":
    main()
