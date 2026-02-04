import os
import sys
import math
from PIL import Image, ImageChops

def trim(im, border_color):
    bg = Image.new(im.mode, im.size, border_color)
    diff = ImageChops.difference(im, bg)
    bbox = diff.getbbox()
    if bbox:
        return im.crop(bbox)
    return im

def split_grid(image_path, output_dir, names=None, final_size=64, trim_images=True, force_grid=None):
    """
    Splits an image into a grid of 12 cells (3x4 or 4x3 auto-detected)
    and saves each cell centered.
    force_grid: tuple (rows, cols) to override auto-detection
    """
    if not os.path.exists(image_path):
        print(f"Image not found: {image_path}")
        return

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    img = Image.open(image_path)
    img = img.convert("RGBA")
    
    w, h = img.size
    
    # Auto-detect layout if not forced
    if force_grid:
        rows, cols = force_grid
    else:
        # Default Auto-detect
        if w > h:
            cols = 4
            rows = 3
        else:
            cols = 3
            rows = 4
        
    cell_w = w // cols
    cell_h = h // rows
    
    print(f"Processing {image_path} ({w}x{h}) -> {rows}x{cols} grid (Cell: {cell_w}x{cell_h}) Trim={trim_images}")
    
    count = 0
    for r in range(rows):
        for c in range(cols):
            if names and count >= len(names):
                break
                
            x1 = c * cell_w
            y1 = r * cell_h
            x2 = x1 + cell_w
            y2 = y1 + cell_h
            
            # Crop cell
            cell = img.crop((x1, y1, x2, y2))
            
            # --- SMART PROCESSING ---
            # --- SMART PROCESSING ---
            content = cell
            
            if trim_images:
                # 1. Get background color from top-left pixel
                bg_color = cell.getpixel((0, 0))
                
                # 2. Trim background (simple heuristic based on corner color)
                # This helps remove the solid dark grey background
                try:
                    # Create a mask of the background color with tolerance
                    # Simple trim:
                    trimmed = trim(cell, bg_color)
                    
                    # If trim returned full image or tiny, it might have failed or be empty
                    if trimmed.size != cell.size:
                         content = trimmed
                except Exception as e:
                    print(f"Error trimming: {e}")
                    content = cell

            # 3. Center in final canvas
            final_canvas = Image.new("RGBA", (final_size, final_size), (0,0,0,0))
            
            # Resize content to fit within final_size with padding
            target_size = int(final_size * 0.9)
            cw, ch = content.size
            
            # Scale down if needed OR scale up if too small (normalization)
            # We want icons to look uniform size
            if cw > 0 and ch > 0:
                scale = min(target_size / cw, target_size / ch)
                new_w = int(cw * scale)
                new_h = int(ch * scale)
                content = content.resize((new_w, new_h), Image.Resampling.LANCZOS)
                
                # Paste centered
                off_x = (final_size - new_w) // 2
                off_y = (final_size - new_h) // 2
                final_canvas.paste(content, (off_x, off_y))
            
            # Determine filename
            if names and count < len(names):
                filename = names[count]
                if not filename.endswith(".png"):
                    filename += ".png"
            else:
                filename = f"icon_{r}_{c}.png"
                
            save_path = os.path.join(output_dir, filename)
            final_canvas.save(save_path)
            print(f"Saved: {filename}")
            
            count += 1


if __name__ == "__main__":
    # Base path for input images
    input_base = r"project/assets/icons"
    output_base = r"project/assets/icons"

    # --- PHASE 2 BATCHES (Weapon & Fusion Upgrades) ---

    # BATCH 4: Ice, Fire & Lightning -> icon_rpg_set_09.png
    batch_4_names = [
        "upgrade_ice_damage", "upgrade_ice_pierce", "upgrade_ice_area", "upgrade_ice_effect",
        "upgrade_fire_damage", "upgrade_fire_area", "upgrade_fire_burn", "upgrade_fire_multishot",
        "upgrade_lightning_damage", "upgrade_lightning_speed", "upgrade_lightning_chain", "upgrade_lightning_multishot"
    ]
    # --- COMMENTED OUT OTHER BATCHES TO FOCUS ON BATCH 15 ---
    # split_grid(os.path.join(input_base, "icon_rpg_set_01.png"), output_base, batch_1_names, trim_images=True)
    # split_grid(os.path.join(input_base, "icon_rpg_set_09.png"), output_base, batch_4_names, trim_images=True)
    # split_grid(os.path.join(input_base, "icon_rpg_set_10.png"), output_base, batch_5_names, trim_images=True)
    # split_grid(os.path.join(input_base, "icon_rpg_set_11.png"), output_base, batch_6_names, trim_images=True)
    # split_grid(os.path.join(input_base, "icon_rpg_set_12.png"), output_base, batch_7_names, trim_images=True)
    # split_grid(os.path.join(input_base, "icon_rpg_set_13.png"), output_base, batch_8_names, trim_images=True)
    # split_grid(os.path.join(input_base, "icon_rpg_set_14.png"), output_base, batch_10_names, trim_images=False, force_grid=(3, 4))

    # --- REMEDIAL BATCH (Global Upgrades) ---
    print("--- RUNNING BATCH 15 ONLY ---")
    
    # BATCH 15: Global Stat Upgrades -> icon_rpg_set_15.png
    # Order matches icon_prompts_remedial.md (3x4 grid)
    # Row 1: Damage, Attack Speed, Crit Chance, Crit Damage
    # Row 2: Area, Duration, Knockback, Pierce
    # Row 3: Proj Count, Range, Proj Speed, Flat Damage
    batch_15_names = [
        "upgrade_global_damage", "upgrade_global_attack_speed", "upgrade_global_crit_chance", "upgrade_global_crit_damage",
        "upgrade_global_area", "upgrade_global_duration", "upgrade_global_knockback", "upgrade_global_pierce",
        "upgrade_global_proj_count", "upgrade_global_range", "upgrade_global_proj_speed", "upgrade_global_flat_damage"
    ]
    # FORCE 3 ROWS 4 COLS just to be safe, though auto-detect should work
    split_grid(os.path.join(input_base, "icon_rpg_set_15.png"), output_base, batch_15_names, trim_images=True, force_grid=(3, 4))

    print("All Phases Processing complete.")
