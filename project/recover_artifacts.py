import os
import shutil

src_dir = r'C:\Users\Usuario\.gemini\antigravity\brain\3762163f-b80c-4102-9cb1-7e1dc0992c85'
dest_dir = r'c:\git\loopialike\project\docs\steam\assets'

candidates = {
    "library_capsule.png": "library_capsule_600x900_1771094627224.png",
    "small_capsule.png": "small_capsule_231x87_1771073509340.png",
    "main_capsule.png": "main_capsule_1771007656522.png"
}

print(f"Checking artifacts in {src_dir}...")

for dest_name, src_name in candidates.items():
    src_path = os.path.join(src_dir, src_name)
    dest_path = os.path.join(dest_dir, dest_name)
    
    if os.path.exists(src_path):
        print(f"FOUND: {src_name}")
        try:
            shutil.copy2(src_path, dest_path)
            print(f"  -> Copied to {dest_name}")
        except Exception as e:
            print(f"  -> COPY FAILED: {e}")
    else:
        print(f"MISSING: {src_name}")

print("Done.")
