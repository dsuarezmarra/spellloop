import os
import shutil
import json

PROJECT_ROOT = r"c:\git\spellloop\project"
AUDIO_ROOT = os.path.join(PROJECT_ROOT, "audio")
UNUSED_ROOT = os.path.join(AUDIO_ROOT, "_unused")
MANIFEST_PATH = os.path.join(PROJECT_ROOT, "audio_manifest.json")

def ensure_dir(path):
    if not os.path.exists(path):
        os.makedirs(path)

def move_files(src_dir, dst_dir):
    ensure_dir(dst_dir)
    for filename in os.listdir(src_dir):
        src_file = os.path.join(src_dir, filename)
        dst_file = os.path.join(dst_dir, filename)
        
        if os.path.isfile(src_file):
            # Handle collisions
            if os.path.exists(dst_file):
                print(f"Warning: File exists, overwriting: {dst_file}")
            
            shutil.move(src_file, dst_file)
            print(f"Moved: {src_file} -> {dst_file}")
        elif os.path.isdir(src_file):
             # Recursively move subdirectories if any (unlikely for Usado/No usado leaf nodes but safety first)
             move_files(src_file, os.path.join(dst_dir, filename))

def process_directory(current_dir):
    # Walk depth-first to handle nested folders correctly
    for entry in os.scandir(current_dir):
        if entry.is_dir():
            if entry.name == "Usado":
                # Move content up
                parent_dir = os.path.dirname(entry.path)
                print(f"Flattening 'Usado': {entry.path} -> {parent_dir}")
                move_files(entry.path, parent_dir)
                try:
                    os.rmdir(entry.path)
                except OSError:
                    print(f"Could not remove (not empty?): {entry.path}")
            
            elif entry.name == "No usado" or entry.name == "No Usado":
                # Move content to _unused
                parent_name = os.path.basename(os.path.dirname(entry.path))
                target_dir = os.path.join(UNUSED_ROOT, parent_name)
                print(f"Archiving 'No usado': {entry.path} -> {target_dir}")
                move_files(entry.path, target_dir)
                try:
                    os.rmdir(entry.path)
                except OSError:
                    print(f"Could not remove (not empty?): {entry.path}")
            
            else:
                # Recurse
                process_directory(entry.path)

def update_manifest():
    with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
        content = f.read()
    
    # Simple string replacement for Usado removal
    # res://audio/.../Usado/file.wav -> res://audio/.../file.wav
    new_content = content.replace("/Usado/", "/")
    
    # We don't need to replace "No usado" in manifest typically because 
    # the manifest *should* only contain used files. 
    # If "No usado" files were in manifest, they will now be broken links pointing to _unused.
    # We should detect this.
    
    with open(MANIFEST_PATH, "w", encoding="utf-8") as f:
        f.write(new_content)
    
    print("Updated manifest paths.")

if __name__ == "__main__":
    print("Starting audio reorganization...")
    ensure_dir(UNUSED_ROOT)
    process_directory(AUDIO_ROOT)
    update_manifest()
    print("Done.")
