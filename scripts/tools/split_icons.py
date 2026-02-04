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

    # -------------------------------------------------------------------------
    # BATCH 1: Base Weapons & Fusions -> icon_rpg_set_06.png
    # -------------------------------------------------------------------------
    batch_1_names = [
        "weapon_shadow_dagger", "weapon_wind_blade", "weapon_nature_staff", "weapon_earth_spike",
        "weapon_light_beam", "weapon_void_pulse", "fusion_steam_cannon", "fusion_storm_caller",
        "fusion_soul_reaper", "fusion_cosmic_barrier", "fusion_rift_quake", "fusion_frostvine"
    ]
    split_grid(os.path.join(input_base, "icon_rpg_set_06.png"), output_base, batch_1_names)

    # -------------------------------------------------------------------------
    # BATCH 2: Fusions & Global Upgrades (Part 1) -> icon_rpg_set_07.png
    # -------------------------------------------------------------------------
    batch_2_names = [
        "fusion_hellfire", "fusion_thunder_spear", "upgrade_global_damage", "upgrade_global_attack_speed",
        "upgrade_global_area", "upgrade_global_proj_count", "upgrade_global_proj_speed", "upgrade_global_pierce",
        "upgrade_global_crit_chance", "upgrade_global_crit_damage", "upgrade_global_duration", "upgrade_global_knockback"
    ]
    split_grid(os.path.join(input_base, "icon_rpg_set_07.png"), output_base, batch_2_names)

    # -------------------------------------------------------------------------
    # BATCH 3: Global Upgrades (Part 2) & Weapon Specifics -> icon_rpg_set_08.png
    # -------------------------------------------------------------------------
    batch_3_names = [
        "upgrade_global_range", "upgrade_global_flat_damage", "special_ice_frost_nova", "special_ice_deep_freeze",
        "special_fire_inferno", "special_fire_spread", "special_lightning_chain_master", "special_lightning_overcharge",
        "special_shadow_assassin", "special_nature_overgrowth", "special_arcane_expansion", "upgrade_defensive_grit"
    ]
    split_grid(os.path.join(input_base, "icon_rpg_set_08.png"), output_base, batch_3_names)

    print("Processing complete.")
