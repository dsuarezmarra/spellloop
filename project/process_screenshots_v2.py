import os
from PIL import Image

src_dir = r"C:\Users\Usuario\.gemini\antigravity\brain\tempmediaStorage"
dest_dir = r"c:\git\loopialike\project\docs\steam\assets\READY_TO_UPLOAD\screenshots"

if not os.path.exists(dest_dir):
    os.makedirs(dest_dir)

files = [f for f in os.listdir(src_dir) if f.lower().endswith(('.png', '.jpg', '.jpeg'))]

print(f"Found {len(files)} potential screenshots.")

for i, f in enumerate(files):
    src_path = os.path.join(src_dir, f)
    try:
        with Image.open(src_path) as img:
            print(f"Processing {f}: {img.width}x{img.height}")
            
            # Target 1920x1080
            target = (1920, 1080)
            
            # Convert to RGB
            img = img.convert('RGB')
            
            # Resize (Strech to fit 1920x1080 for now, usually safe for screenshots close to 16:9)
            img = img.resize(target, Image.Resampling.LANCZOS)
            
            # Save
            out_name = f"screenshot_{i+1:02d}.jpg"
            out_path = os.path.join(dest_dir, out_name)
            img.save(out_path, quality=95)
            print(f"Saved {out_name}")
            
    except Exception as e:
        print(f"Error {f}: {e}")
