import os
from PIL import Image

# Config
atlas_path = r"project/assets/sprites/projectiles/projectiles_base_sheet.png"
output_dir = r"project/assets/sprites/projectiles/"

# Order: Ice, Fire, Arcane, Lightning, Void, Nature
icon_names = [
    "proj_ice_shard", "proj_fire_ball", "proj_arcane_orb", 
    "proj_lightning_spark", "proj_void_bolt", "proj_nature_leaf"
]

def split_atlas():
    if not os.path.exists(atlas_path):
        print("Atlas not found")
        return

    img = Image.open(atlas_path)
    img = img.convert("RGBA")
    
    w, h = img.size
    print(f"Atlas Size: {w}x{h}")
    
    # 1. Detect Rows (Vertical projection)
    # Scan y-axis for empty lines
    row_ranges = []
    in_row = False
    start_y = 0
    
    # Threshold for noise (sometimes "transparent" isn't 0)
    alpha_threshold = 10 
    
    for y in range(h):
        # Check if this horizontal line has any non-transparent pixel
        has_content = False
        for x in range(w):
            if img.getpixel((x, y))[3] > alpha_threshold:
                has_content = True
                break
        
        if has_content and not in_row:
            in_row = True
            start_y = y
        elif not has_content and in_row:
            in_row = False
            # Found a row from start_y to y
            # Only add if significant height
            if (y - start_y) > 10:
                row_ranges.append((start_y, y))
    
    # Handle last row if edge
    if in_row:
        row_ranges.append((start_y, h))
        
    print(f"Detected {len(row_ranges)} rows of icons.")
    
    count = 0
    # 2. Process each row to find columns
    for r_idx, (y1, y2) in enumerate(row_ranges):
        # Crop to the row strip first to analyze columns
        # But we can just read pixels from main img
        
        col_ranges = []
        in_col = False
        start_x = 0
        
        for x in range(w):
            # Check vertical line segment within this row strip
            has_content = False
            for y in range(y1, y2):
                if img.getpixel((x, y))[3] > alpha_threshold:
                    has_content = True
                    break
            
            if has_content and not in_col:
                in_col = True
                start_x = x
            elif not has_content and in_col:
                in_col = False
                if (x - start_x) > 10:
                    col_ranges.append((start_x, x))
        
        if in_col:
            col_ranges.append((start_x, w))
            
        print(f"  Row {r_idx}: Detected {len(col_ranges)} items.")
        
        # 3. Extract and Save
        for x1, x2 in col_ranges:
            if count >= len(icon_names): break
            
            # Crop exact rect
            icon = img.crop((x1, y1, x2, y2))
            
            # Optional: Trim tight bounding box around content inside this cell
            bbox = icon.getbbox()
            if bbox:
                icon = icon.crop(bbox)
                
                # Center in 64x64 canvas if needed? User asked for adapting them.
                # Let's save as tight crop for now, or resize to uniform 64x64?
                # User prompt said "optimized for 64x64 icon". 
                # Let's put it in a 64x64 container centered.
                
                final_size = 64
                canvas = Image.new("RGBA", (final_size, final_size), (0,0,0,0))
                
                # Scale if too big
                iw, ih = icon.size
                if iw > final_size or ih > final_size:
                    ratio = min(final_size/iw, final_size/ih)
                    new_size = (int(iw*ratio), int(ih*ratio))
                    icon = icon.resize(new_size, Image.Resampling.LANCZOS)
                    iw, ih = new_size
                
                # Paste centered
                offset = ((final_size - iw) // 2, (final_size - ih) // 2)
                canvas.paste(icon, offset)
                
                name = icon_names[count]
                save_path = os.path.join(output_dir, f"{name}.png")
                canvas.save(save_path)
                print(f"    Saved: {name}.png")
                
                count += 1


if __name__ == "__main__":
    split_atlas()
