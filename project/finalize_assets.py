import os
from PIL import Image

src_dir = r'c:\git\loopialike\project\docs\steam\assets'

# Mapping: Source Filename -> (Dest Filename, Target Size/Format)
tasks = {
    "Hero Image.png": {"dest": "hero_image.png", "size": (3840, 1240), "format": "PNG"},
    "Client Icon.png": {"dest": "client_icon.ico", "size": (32, 32), "format": "ICO"},
    "Community Icon.png": {"dest": "community_icon.jpg", "size": (184, 184), "format": "JPEG"},
    "Library Capsule.png": {"dest": "library_capsule.png", "size": (600, 900), "format": "PNG"},
    "Main Capsule.png": {"dest": "main_capsule.png", "size": (616, 353), "format": "PNG"},
    "Small Capsule.png": {"dest": "small_capsule.png", "size": (231, 87), "format": "PNG"},
    "Logo.png": {"dest": "logo.png", "size": None, "format": "PNG"} # Keep size
}

print("Processing assets...")

for src_name, config in tasks.items():
    src_path = os.path.join(src_dir, src_name)
    dest_path = os.path.join(src_dir, config["dest"])
    
    if not os.path.exists(src_path):
        print(f"Skipping {src_name} (Not found)")
        continue
        
    try:
        with Image.open(src_path) as img:
            # Resize if needed
            if config["size"] and (img.width != config["size"][0] or img.height != config["size"][1]):
                print(f"Resizing {src_name} ({img.width}x{img.height}) -> {config['size']}")
                # High quality resize
                img = img.resize(config["size"], Image.Resampling.LANCZOS)
            
            # Save
            if config["format"] == "JPEG":
                rgb_im = img.convert('RGB')
                rgb_im.save(dest_path, quality=95)
            elif config["format"] == "ICO":
                 img.save(dest_path, format='ICO', sizes=[(32,32)])
            else:
                img.save(dest_path)
                
        print(f"Saved {config['dest']}")
        
    except Exception as e:
        print(f"Error processing {src_name}: {e}")

# Handle Header Capsule separately (it has a hash name)
# Find header_capsule_*.png
for f in os.listdir(src_dir):
    if f.startswith("header_capsule_") and f.endswith(".png") and "import" not in f:
        src = os.path.join(src_dir, f)
        dst = os.path.join(src_dir, "header_capsule.png")
        try:
             import shutil
             shutil.copy2(src, dst)
             print(f"Standardized {f} -> header_capsule.png")
        except Exception as e:
            print(f"Header copy error: {e}")
        break

print("Done.")
