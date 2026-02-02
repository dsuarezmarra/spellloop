import os
from PIL import Image

assets_to_check = [
    r"project/assets/sprites/projectiles/projectiles_base_sheet.png",
    r"project/assets/sprites/pickups/coins/coin_set_sheet.png",
    # Background doesn't need transparency removal (it's full screen), but checking it is fine.
    # Actually, the prompt said "No characters... just environment". It should be opaque.
    # But check_assets.py removes "background color" if consistent.
    # Let's SKIP the background to avoid accidental holes in it if it has a solid color area.
]

print("--- Image Audit ---")
for path in assets_to_check:
    if not os.path.exists(path):
        print(f"MISSING: {path}")
        continue
        
    try:
        img = Image.open(path)
        print(f"FILE: {os.path.basename(path)}")
        print(f"  Size: {img.size}")
        print(f"  Mode: {img.mode}")
        
        has_transparency = False
        if img.mode in ('RGBA', 'LA') or (img.mode == 'P' and 'transparency' in img.info):
            if img.mode == 'RGBA':
                extrema = img.getextrema()
                if extrema[3][0] < 255:
                    has_transparency = True
        
        print(f"  Has Alpha: {has_transparency}")
        
        # Check corners to guess background
        corners = [
            img.getpixel((0,0)),
            img.getpixel((img.width-1, 0)),
            img.getpixel((0, img.height-1)),
            img.getpixel((img.width-1, img.height-1))
        ]
        
        print(f"  Corners: {corners}")
        print("-" * 20)
        
        # AUTO-FIX: Remove background if detected
        bg_color = corners[0] # Assume top-left is background
        # Simple heuristic: if corners are all essentially same color
        if all(sum(abs(c[i]-corners[0][i]) for i in range(3)) < 15 for c in corners):
             print(f"  DETECTED BACKGROUND: {bg_color}. Attempting removal...")
             
             # Create new image with alpha
             img = img.convert("RGBA")
             datas = img.getdata()
             
             new_data = []
             # Threshold for background removal sensitivity
             threshold = 20 
             
             for item in datas:
                 # Check difference from bg color
                 diff = sum(abs(item[i] - bg_color[i]) for i in range(3))
                 if diff < threshold:
                     new_data.append((255, 255, 255, 0)) # Transparent
                 else:
                     new_data.append(item)
             
             img.putdata(new_data)
             img.save(path, "PNG")
             print(f"  ✓ FIXED: Saved with transparency to {path}")

    except Exception as e:
        print(f"ERROR reading {path}: {e}")
