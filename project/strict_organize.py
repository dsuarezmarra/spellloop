import os
import csv
import shutil
import re

PROJECT_ROOT = r"c:\git\spellloop\project"
CSV_PATH = os.path.join(PROJECT_ROOT, "strict_audio_audit.csv")

# Extensions to scan for references to update
TEXT_EXTENSIONS = {'.gd', '.tscn', '.tres', '.json', '.cfg', '.import'}

def get_abs_path(res_path):
    return os.path.join(PROJECT_ROOT, res_path.replace("res://", "").replace("/", "\\"))

def main():
    print(f"Reading classification from {CSV_PATH}...")
    
    moves = [] # List of (old_res, new_res, old_abs, new_abs)
    
    if not os.path.exists(CSV_PATH):
        print("Error: CSV not found!")
        return

    with open(CSV_PATH, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            old_res = row['original_path']
            status = row['status']
            
            # Determine target subfolder name
            target_subfolder = "Usado" if status in ["USADO", "AMBIGUO"] else "No usado"
            
            # Parse Path
            # old_res might be like:
            # 1. res://audio/sfx/foo.wav
            # 2. res://audio/sfx/Usado/foo.wav
            # 3. res://audio/sfx/No usado/foo.wav
            
            parts = old_res.split("/")
            filename = parts[-1]
            
            # Check if currently in a sorting folder
            parent_folder = parts[-2]
            
            if parent_folder in ["Usado", "No usado"]:
                base_dir_parts = parts[:-2] # up to audio/sfx
                current_subfolder = parent_folder
            else:
                base_dir_parts = parts[:-1] # up to audio/sfx
                current_subfolder = ""
                
            base_dir_res = "/".join(base_dir_parts)
            
            # Construct new path
            new_res = f"{base_dir_res}/{target_subfolder}/{filename}"
            
            # Check if move is needed
            if old_res == new_res:
                continue
                
            old_abs = get_abs_path(old_res)
            new_abs = get_abs_path(new_res)
            
            moves.append({
                'old_res': old_res,
                'new_res': new_res,
                'old_abs': old_abs,
                'new_abs': new_abs
            })
            
    # 1. Move Files
    print(f"Planning to move {len(moves)} files...")
    moved_count = 0
    
    for m in moves:
        # Create dir
        new_dir = os.path.dirname(m['new_abs'])
        if not os.path.exists(new_dir):
            os.makedirs(new_dir)
            
        # Move file
        if os.path.exists(m['old_abs']):
            try:
                shutil.move(m['old_abs'], m['new_abs'])
                moved_count += 1
                
                # Also move .import file if it exists
                old_import = m['old_abs'] + ".import"
                new_import = m['new_abs'] + ".import"
                if os.path.exists(old_import):
                     shutil.move(old_import, new_import)
            except Exception as e:
                print(f"ERROR moving {m['old_abs']}: {e}")
        else:
            print(f"WARNING: Source file not found: {m['old_abs']}")

    print(f"Physically moved {moved_count} files.")

    # 2. Update References
    if moves:
        print("Updating project references...")
        
        # Sort moves by length of old_res descending
        moves.sort(key=lambda x: len(x['old_res']), reverse=True)
        
        count_updated_files = 0
        
        for root, _, files in os.walk(PROJECT_ROOT):
            if ".godot" in root: continue
                
            for file in files:
                ext = os.path.splitext(file)[1].lower()
                if ext in TEXT_EXTENSIONS:
                    # skip logs/audit scripts
                    if "audit" in file or "organize" in file or ".log" in file: continue
                    
                    file_path = os.path.join(root, file)
                    
                    try:
                        with open(file_path, 'r', encoding='utf-8') as f:
                            content = f.read()
                        
                        new_content = content
                        modified = False
                        
                        for m in moves:
                            if m['old_res'] in new_content:
                                new_content = new_content.replace(m['old_res'], m['new_res'])
                                modified = True
                                
                        if modified:
                            with open(file_path, 'w', encoding='utf-8') as f:
                                f.write(new_content)
                            count_updated_files += 1
                            
                    except Exception as e:
                        print(f"Error processing {file_path}: {e}")
                        
        print(f"Updated references in {count_updated_files} files.")
    else:
        print("No files needed moving.")

if __name__ == "__main__":
    main()
