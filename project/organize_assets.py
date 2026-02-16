import os
import shutil

base_dir = r'c:\git\loopialike\project\docs\steam\assets'
final_dir = os.path.join(base_dir, 'READY_TO_UPLOAD')
work_dir = os.path.join(base_dir, 'working_files')
surplus_dir = os.path.join(base_dir, 'surplus')

# 1. Create Directories
for d in [final_dir, work_dir]:
    if not os.path.exists(d):
        os.makedirs(d)
        print(f"Created {d}")

# 2. Key Assets to Move to READY_TO_UPLOAD
key_assets = [
    "header_capsule.png",
    "small_capsule.png",
    "main_capsule.png",
    "hero_image.png",
    "library_capsule.png",
    "logo.png",
    "client_icon.ico",
    "community_icon.jpg"
]

print("--- Moving Key Assets ---")
for f in key_assets:
    src = os.path.join(base_dir, f)
    dst = os.path.join(final_dir, f)
    if os.path.exists(src):
        shutil.move(src, dst)
        print(f"Moved {f} to READY_TO_UPLOAD")
    else:
        print(f"MISSING {f}")

# 3. Create Library Hero copy if it doesn't exist
lib_hero_dst = os.path.join(final_dir, "library_hero.png")
hero_src = os.path.join(final_dir, "hero_image.png")
if os.path.exists(hero_src) and not os.path.exists(lib_hero_dst):
    shutil.copy2(hero_src, lib_hero_dst)
    print("Created library_hero.png from hero_image.png")

# 4. Move everything else to working_files
print("--- Cleaning Up ---")
for f in os.listdir(base_dir):
    src = os.path.join(base_dir, f)
    
    # Skip directories we want to keep/ignore
    if src == final_dir or src == work_dir or src == surplus_dir:
        continue
    
    # Skip if it's a directory (unless we want to move dirs too?)
    # Let's move files and dirs that are not the special ones
    
    dst = os.path.join(work_dir, f)
    try:
        shutil.move(src, dst)
        print(f"Moved {f} to working_files")
    except Exception as e:
        print(f"Failed to move {f}: {e}")

print("Done.")
