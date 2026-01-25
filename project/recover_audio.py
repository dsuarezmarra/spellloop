import os
import csv
import shutil

PROJECT_ROOT = r"c:\git\spellloop\project"
AUDIT_CSV = os.path.join(PROJECT_ROOT, "final_audio_audit.csv")
UNUSED_ROOT = os.path.join(PROJECT_ROOT, "audio", "_unused")
AUDIO_ROOT = os.path.join(PROJECT_ROOT, "audio")

def recover():
    print("Starting recovery...")
    missed_count = 0
    recovered_count = 0
    
    with open(AUDIT_CSV, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row["Status"] == "MISSING":
                missed_count += 1
                path = row["Message"] # res://audio/sfx/ui/sfx_ui_error_01.mp3
                
                # Convert res:// path to local absolute path
                rel_path = path.replace("res://", "") # audio/sfx/ui/sfx_ui_error_01.mp3
                target_abs_path = os.path.join(PROJECT_ROOT, rel_path.replace("/", "\\"))
                filename = os.path.basename(target_abs_path)
                
                # Search in _unused (recursively or just known structure)
                # We know logic: _unused/<category>/filename
                # But let's just search recursively in _unused to be safe
                found_src = None
                for root, dirs, files in os.walk(UNUSED_ROOT):
                    if filename in files:
                        found_src = os.path.join(root, filename)
                        break
                
                if found_src:
                    # Move back
                    # Ensure target dir exists
                    os.makedirs(os.path.dirname(target_abs_path), exist_ok=True)
                    shutil.move(found_src, target_abs_path)
                    print(f"Recovered: {filename}")
                    recovered_count += 1
                else:
                    print(f"Could NOT find {filename} in _unused")

    print(f"Recovery complete. Recovered {recovered_count}/{missed_count} files.")

if __name__ == "__main__":
    recover()
