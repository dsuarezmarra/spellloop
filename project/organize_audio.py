import os
import csv
import shutil
import re

PROJECT_ROOT = r"c:\git\spellloop\project"
CSV_PATH = os.path.join(PROJECT_ROOT, "audio_audit_preview.csv")

# Extensions to scan for references to update
TEXT_EXTENSIONS = {'.gd', '.tscn', '.tres', '.json', '.cfg', '.import'}

def get_abs_path(res_path):
    return os.path.join(PROJECT_ROOT, res_path.replace("res://", "").replace("/", "\\"))

def get_res_path(abs_path):
    return "res://" + os.path.relpath(abs_path, PROJECT_ROOT).replace("\\", "/")

def main():
    print(f"Reading classification from {CSV_PATH}...")
    
    moves = [] # List of (old_res, new_res, old_abs, new_abs)
    
    with open(CSV_PATH, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            old_res = row['original_path']
            status = row['status']
            
            # Determine subfolder
            subfolder = "Usado" if status == "USADO" or status == "AMBIGUO" else "No usado"
            
            # Construct new path
            # e.g. res://audio/sfx/foo.wav -> res://audio/sfx/Usado/foo.wav
            
            parts = old_res.split("/")
            filename = parts[-1]
            parent_dir = "/".join(parts[:-1]) # e.g. res://audio/sfx
            
            new_res = f"{parent_dir}/{subfolder}/{filename}"
            
            old_abs = get_abs_path(old_res)
            new_abs = get_abs_path(new_res)
            
            moves.append({
                'old_res': old_res,
                'new_res': new_res,
                'old_abs': old_abs,
                'new_abs': new_abs,
                'subfolder': subfolder
            })
            
    # 1. Move Files
    print("Moving files...")
    for m in moves:
        # Create dir
        new_dir = os.path.dirname(m['new_abs'])
        if not os.path.exists(new_dir):
            os.makedirs(new_dir)
            print(f"Created directory: {new_dir}")
            
        # Move file
        if os.path.exists(m['old_abs']):
            try:
                shutil.move(m['old_abs'], m['new_abs'])
                # Also move .import file if it exists
                old_import = m['old_abs'] + ".import"
                new_import = m['new_abs'] + ".import"
                if os.path.exists(old_import):
                     shutil.move(old_import, new_import)
            except Exception as e:
                print(f"ERROR moving {m['old_abs']}: {e}")
        else:
            print(f"WARNING: Source file not found: {m['old_abs']}")

    # 2. Update References
    print("Updating project references...")
    
    # Sort moves by length of old_res descending to avoid partial matches
    # e.g. replacing 'a/b.wav' before 'a/b.wav' (unlikely for full paths but good practice)
    moves.sort(key=lambda x: len(x['old_res']), reverse=True)
    
    count_updated_files = 0
    
    for root, _, files in os.walk(PROJECT_ROOT):
        # Skip .godot folder
        if ".godot" in root:
            continue
            
        for file in files:
            ext = os.path.splitext(file)[1].lower()
            if ext in TEXT_EXTENSIONS:
                file_path = os.path.join(root, file)
                # Skip the audit files themselves
                if "audit" in file or "organize_audio" in file:
                    continue
                    
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    new_content = content
                    modified = False
                    
                    for m in moves:
                        if m['old_res'] in new_content:
                            new_content = new_content.replace(m['old_res'], m['new_res'])
                            modified = True
                            
                        # Special case for .import files: source_file="res://..."
                        # (Usually handled by simple string replace above, but just in case)
                            
                    if modified:
                        with open(file_path, 'w', encoding='utf-8') as f:
                            f.write(new_content)
                        print(f"Updated: {file}")
                        count_updated_files += 1
                        
                except Exception as e:
                    print(f"Error processing {file_path}: {e}")

    print("-" * 50)
    print("Reorganization Complete.")
    print(f"Moved {len(moves)} audio assets.")
    print(f"Updated references in {count_updated_files} files.")

if __name__ == "__main__":
    main()
