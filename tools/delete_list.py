import json
import os
from pathlib import Path
import sys

AUDIO_DIR = Path("audio")

def delete_files(json_path):
    if not Path(json_path).exists():
        print("Json not found")
        return

    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    count = 0
    for item in data:
        # Construct path found in validate_audio logic or just use name/category
        # Validate audio exported full objects: category, name, etc.
        category = item["category"]
        name = item["name"] # Includes suffix if variations=1 was forced
        filename = f"{name}.wav"
        
        file_path = AUDIO_DIR / category / filename
        if file_path.exists():
            file_path.unlink()
            print(f"Deleted: {file_path}")
            count += 1
            
    print(f"Deleted {count} files.")

if __name__ == "__main__":
    delete_files(sys.argv[1])
