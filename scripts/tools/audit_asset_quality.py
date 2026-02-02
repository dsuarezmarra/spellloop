import os
from PIL import Image

# Directories to scan
scan_dirs = [
    r"project/assets/ui",
    r"project/assets/icons",
    r"project/assets/vfx",
    r"project/assets/sprites"
]

def analyze_image(path):
    try:
        img = Image.open(path)
        mode = img.mode
        w, h = img.size
        
        # Check transparency
        has_transparency = False
        if mode == 'RGBA':
            extrema = img.getextrema()
            if extrema[3][0] < 255:
                has_transparency = True
        elif mode == 'P':
            transparency = img.info.get("transparency")
            if transparency is not None:
                has_transparency = True
                
        # Get content bbox
        bbox = img.getbbox()
        if bbox:
            bw = bbox[2] - bbox[0]
            bh = bbox[3] - bbox[1]
            fill_pct = (bw * bh) / (w * h)
        else:
            bw, bh = 0, 0
            fill_pct = 0.0
            
        return {
            "dims": f"{w}x{h}",
            "mode": mode,
            "transparent": has_transparency,
            "bbox": f"{bw}x{bh}",
            "fill": f"{fill_pct:.2f}"
        }
    except Exception as e:
        return {"error": str(e)}

print(f"{'FILE':<50} | {'SIZE':<10} | {'MODE':<5} | {'ALPHA':<5} | {'CONTENT':<10}")
print("-" * 100)

for root_dir in scan_dirs:
    for root, dirs, files in os.walk(root_dir):
        for f in files:
            if f.lower().endswith('.png'):
                full_path = os.path.join(root, f)
                stats = analyze_image(full_path)
                
                name = f[:45]
                if "error" in stats:
                    print(f"{name:<50} | ERROR: {stats['error']}")
                else:
                    print(f"{name:<50} | {stats['dims']:<10} | {stats['mode']:<5} | {str(stats['transparent']):<5} | {stats['bbox']:<10}")
