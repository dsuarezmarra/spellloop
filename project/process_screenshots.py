import os
from PIL import Image

# Source paths provided by user upload
src_files = [
    r"C:\Users\Usuario\.gemini\antigravity\brain\tempmediaStorage\media__1771264086546.png",
    r"C:\Users\Usuario\.gemini\antigravity\brain\tempmediaStorage\media__1771264086547.png"
]

dest_dir = r"c:\git\loopialike\project\docs\steam\assets\READY_TO_UPLOAD\screenshots"

print("Checking screenshots...")
for i, src in enumerate(src_files):
    try:
        if not os.path.exists(src):
            print(f"Missing: {src}")
            continue
            
        with Image.open(src) as img:
            print(f"Image {i+1}: {img.width}x{img.height} ({img.format})")
            
            # Convert to RGB (remove alpha) and Resize to 1920x1080
            # Note: We should ideally crop to aspect ratio then resize, 
            # but for now let's just force 1920x1080 or fit best.
            # Steam WANTS 1920x1080.
            
            target_size = (1920, 1080)
            
            # Simple resize for now to see if it works
            rgb_im = img.convert('RGB')
            resized = rgb_im.resize(target_size, Image.Resampling.LANCZOS)
            
            out_name = f"screenshot_0{i+1}.jpg"
            out_path = os.path.join(dest_dir, out_name)
            
            resized.save(out_path, quality=95)
            print(f"Saved {out_name} to {dest_dir}")
            
    except Exception as e:
        print(f"Error processing {src}: {e}")
