import os
from PIL import Image

atlas_path = r"project/assets/sprites/projectiles/projectiles_base_sheet.png"
output_dir = r"project/assets/sprites/projectiles/"

icon_names = [
    "proj_ice_shard", "proj_fire_ball", "proj_arcane_orb", 
    "proj_lightning_spark", "proj_void_bolt", "proj_nature_leaf"
]

def force_split():
    if not os.path.exists(atlas_path):
        print("Atlas not found")
        return

    img = Image.open(atlas_path)
    img = img.convert("RGBA")
    w, h = img.size
    print(f"Atlas Size: {w}x{h}")

    # Assume 3x2 Grid
    cols = 3
    rows = 2
    cell_w = w // cols
    cell_h = h // rows

    count = 0
    for r in range(rows):
        for c in range(cols):
            if count >= len(icon_names):
                 break
            
            x1 = c * cell_w
            y1 = r * cell_h
            x2 = x1 + cell_w
            y2 = y1 + cell_h
            
            # Crop
            cell = img.crop((x1, y1, x2, y2))
            
            # Trim
            bbox = cell.getbbox()
            if bbox:
                cell = cell.crop(bbox)
                
                # Center in 64x64
                final_size = 64
                canvas = Image.new("RGBA", (final_size, final_size), (0,0,0,0))
                
                # Resize
                iw, ih = cell.size
                if iw > final_size or ih > final_size:
                    ratio = min(final_size/iw, final_size/ih)
                    new_size = (int(iw*ratio), int(ih*ratio))
                    cell = cell.resize(new_size, Image.Resampling.LANCZOS)
                
                cw, ch = cell.size
                offset = ((final_size - cw) // 2, (final_size - ch) // 2)
                canvas.paste(cell, offset)
                
                name = icon_names[count]
                save_path = os.path.join(output_dir, f"{name}.png")
                canvas.save(save_path)
                print(f"Saved: {name}.png")
            else:
                print(f"Cell {r},{c} is empty/transparent?!")

            count += 1

if __name__ == "__main__":
    force_split()
