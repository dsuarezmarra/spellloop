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

def split_grid(image_path, output_dir, names=None, final_size=64):
    """
    Splits an image into a grid of 12 cells (3x4 or 4x3 auto-detected)
    and saves each cell centered.
    """
    if not os.path.exists(image_path):
        print(f"Image not found: {image_path}")
        return

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    img = Image.open(image_path)
    img = img.convert("RGBA")
    
    w, h = img.size
    
    # Auto-detect layout for 12 items
    # If landscape, likely 4 cols x 3 rows. If portrait, 3 cols x 4 rows.
    if w > h:
        cols = 4
        rows = 3
    else:
        cols = 3
        rows = 4
        
    cell_w = w // cols
    cell_h = h // rows
    
    print(f"Processing {image_path} ({w}x{h}) -> {rows}x{cols} grid (Cell: {cell_w}x{cell_h})")
    
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
            # 1. Get background color from top-left pixel
            bg_color = cell.getpixel((0, 0))
            
            # 2. Trim background (simple heuristic based on corner color)
            # This helps remove the solid dark grey background
            try:
                # Create a mask of the background color with tolerance
                # Simple trim:
                content = trim(cell, bg_color)
                
                # If trim returned full image or tiny, it might have failed or be empty
                if content.size == cell.size:
                     # Try more aggressive trim if corner color matches
                     pass
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
    split_grid(os.path.join(input_base, "icon_rpg_set_09.png"), output_base, batch_4_names)

    # BATCH 5: Nature, Earth & Wind -> icon_rpg_set_10.png
    batch_5_names = [
        "upgrade_nature_heal", "upgrade_nature_duration", "upgrade_nature_multishot", "upgrade_nature_damage",
        "upgrade_earth_area", "upgrade_earth_stun", "upgrade_earth_damage", "upgrade_earth_speed",
        "upgrade_wind_knockback", "upgrade_wind_pierce", "upgrade_wind_area", "upgrade_wind_multishot"
    ]
    split_grid(os.path.join(input_base, "icon_rpg_set_10.png"), output_base, batch_5_names)

    # BATCH 6: Shadow, Light, Arcane & Void -> icon_rpg_set_11.png
    batch_6_names = [
        "upgrade_shadow_pierce", "upgrade_shadow_crit", "upgrade_shadow_speed", "upgrade_light_speed",
        "upgrade_light_area", "upgrade_light_crit", "upgrade_arcane_count", "upgrade_arcane_speed",
        "upgrade_arcane_area", "upgrade_void_pull", "upgrade_void_area", "upgrade_void_damage"
    ]
    split_grid(os.path.join(input_base, "icon_rpg_set_11.png"), output_base, batch_6_names)

    # BATCH 7: Fusion Upgrades & Mastery -> icon_rpg_set_12.png
    batch_7_names = [
        "upgrade_fusion_damage", "upgrade_fusion_area", "upgrade_fusion_speed", "upgrade_fusion_multishot",
        "upgrade_fusion_pierce", "upgrade_fusion_crit", "upgrade_fusion_mastery", "upgrade_weapon_mastery",
        "upgrade_generic_damage", "upgrade_generic_speed", "upgrade_generic_area", "upgrade_generic_multishot"
    ]
    split_grid(os.path.join(input_base, "icon_rpg_set_12.png"), output_base, batch_7_names)

    # --- PHASE 3 BATCH (Misc UI) ---
    
    # BATCH 8: UI & Utility Icons -> icon_rpg_set_13.png (Renamed from 14 per user input)
    batch_8_names = [
        "ui_random_character", "ui_locked_character", "ui_reroll", "ui_banish",
        "ui_skip", "pickup_gold_coin", "pickup_xp_gem", "pickup_health_heart",
        "stat_armor", "stat_speed", "stat_damage", "stat_cooldown"
    ]
    # NOTE: User provided the UI grid as set_13
    split_grid(os.path.join(input_base, "icon_rpg_set_13.png"), output_base, batch_8_names)

    print("All Phases Processing complete.")
