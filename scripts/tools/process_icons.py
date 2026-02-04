
import os
from PIL import Image

# Configuration
INPUT_DIR = r"c:\git\spellloop\project\assets\icons"
OUTPUT_DIR = r"c:\git\spellloop\project\assets\icons"
TARGET_SIZE = (128, 128)
ICON_PADDING = 10 # Padding inside the 128x128 box

# Ordered lists of filenames per Prompt Set (Top-Left to Bottom-Right)
ORDERS = {
    16: [
        "weapon_ice_wand.png", "weapon_fire_wand.png", "weapon_lightning_wand.png", "weapon_arcane_orb.png",
        "fusion_frozen_thunder.png", "fusion_frost_orb.png", "fusion_frostbite.png", "fusion_blizzard.png",
        "fusion_glacier.png", "fusion_aurora.png", "fusion_absolute_zero.png", "fusion_plasma.png"
    ],
    17: [
        "fusion_inferno_orb.png", "fusion_wildfire.png", "fusion_firestorm.png", "fusion_volcano.png",
        "fusion_solar_flare.png", "fusion_dark_flame.png", "fusion_arcane_storm.png", "fusion_dark_lightning.png",
        "fusion_thunder_bloom.png", "fusion_seismic_bolt.png", "fusion_void_bolt.png", "fusion_shadow_orbs.png"
    ],
    18: [
        "fusion_life_orbs.png", "fusion_wind_orbs.png", "fusion_cosmic_void.png", "fusion_phantom_blade.png",
        "fusion_stone_fang.png", "fusion_twilight.png", "fusion_abyss.png", "fusion_pollen_storm.png",
        "fusion_gaia.png", "fusion_solar_bloom.png", "fusion_decay.png", "fusion_sandstorm.png"
    ],
    19: [
        "fusion_prism_wind.png", "fusion_radiant_stone.png", "fusion_eclipse.png", "upgrade_sharpshooter.png",
        "upgrade_giant_slayer.png", "upgrade_combustion.png" # Expecting 6 items here based on Prompt 4
    ]
}

def get_ranges(bool_list, min_gap=5, min_size=10):
    """Finds contiguous ranges of True in a list of booleans."""
    ranges = []
    in_range = False
    start = 0
    for i, val in enumerate(bool_list):
        if val and not in_range:
            in_range = True
            start = i
        elif not val and in_range:
            # Check if this "gap" is real or just noise (though logic here requires gaps to separate cells)
            # Simpler approach: Strictly define ranges separated by ANY False gap? 
            # Better: Merge small gaps if needed, but for transparency detection, specific gaps matter.
            # Let's assume ANY transparent row breaks the blob.
            if (i - start) >= min_size:
                ranges.append((start, i))
            in_range = False
    
    if in_range and (len(bool_list) - start) >= min_size:
        ranges.append((start, len(bool_list)))
    return ranges

def detect_cells(img):
    """Detects individual icon bounding boxes using projection profiles."""
    width, height = img.size
    pixels = img.load()
    
    # 1. Horizontal Projection (Detect Rows)
    # Check if a row has ANY opaque pixel
    row_has_data = [False] * height
    for y in range(height):
        for x in range(width):
            if pixels[x, y][3] > 20: # Alpha threshold
                row_has_data[y] = True
                break
    
    row_ranges = get_ranges(row_has_data, min_gap=2, min_size=20)
    
    cells = []
    
    # 2. Vertical Projection per Row (Detect Cols)
    for r_start, r_end in row_ranges:
        col_has_data = [False] * width
        for x in range(width):
            for y in range(r_start, r_end):
                if pixels[x, y][3] > 20:
                    col_has_data[x] = True
                    break
        
        col_ranges = get_ranges(col_has_data, min_gap=2, min_size=20)
        
        for c_start, c_end in col_ranges:
            cells.append((c_start, r_start, c_end, r_end))
            
    # Sort: Top-to-bottom, then Left-to-right (approximate)
    # Standard grid sort: grouping by row closeness could be complex if drift is huge.
    # Simple Y sort might fail if one icon is slightly higher.
    # Approach: Sort by Y center, but bucket them into rows?
    # Given the gaps, 'cells' usually comes out row by row because of the outer loop.
    # Inside the row loop, cols are sorted by nature of scan.
    # So 'cells' should already be sorted correctly!
    return cells

def process_grid(set_num):
    filename = f"icon_rpg_set_{set_num}.png"
    path = os.path.join(INPUT_DIR, filename)
    
    if not os.path.exists(path):
        print(f"Skipping {filename}, not found.")
        return

    print(f"Processing {filename}...")
    try:
        img = Image.open(path).convert("RGBA")
    except Exception as e:
        print(f"  Error opening: {e}")
        return

    # Detect Cells
    cells = detect_cells(img)
    expected_names = ORDERS.get(set_num, [])
    
    print(f"  Detected {len(cells)} icons. Expected {len(expected_names)}.")
    
    # Process each detected cell
    for i, bbox in enumerate(cells):
        raw_crop = img.crop(bbox)
        
        # Determine Name
        if i < len(expected_names):
            out_name = expected_names[i]
        else:
            out_name = f"orphan_set{set_num}_unk{i}.png"
            
        # 1. Strict Trim (Autocrop alpha)
        content_bbox = raw_crop.getbbox()
        if not content_bbox:
            print(f"  Skipping empty content at index {i}")
            continue
            
        icon_img = raw_crop.crop(content_bbox)
        
        # 2. Resize to Fit Target (with padding)
        # We want the icon to be fully contained in 128x128 with padding.
        # Max dimensions for content:
        max_w = TARGET_SIZE[0] - (ICON_PADDING * 2)
        max_h = TARGET_SIZE[1] - (ICON_PADDING * 2)
        
        iw, ih = icon_img.size
        scale = min(max_w / iw, max_h / ih)
        # Only scale DOWN or slight UP. Don't upscale tiny noise.
        # If scale > 1 (image is small), purely upscale might blur pixel art if not nearest.
        # But user asked for "chubby/funko" which usually implies vector-like or painted.
        # Let's use LANCZOS but cap upscaling.
        
        new_w = int(iw * scale)
        new_h = int(ih * scale)
        
        icon_resized = icon_img.resize((new_w, new_h), Image.Resampling.LANCZOS)
        
        # 3. Paste Centered on Canvas
        final_canvas = Image.new("RGBA", TARGET_SIZE, (0,0,0,0))
        paste_x = (TARGET_SIZE[0] - new_w) // 2
        paste_y = (TARGET_SIZE[1] - new_h) // 2
        
        final_canvas.paste(icon_resized, (paste_x, paste_y))
        
        # Save
        out_path = os.path.join(OUTPUT_DIR, out_name)
        final_canvas.save(out_path)
        print(f"  Saved: {out_name}")

def main():
    for s in [16, 17, 18, 19]:
        process_grid(s)

if __name__ == "__main__":
    main()
