
import os
from PIL import Image

TARGET_SIZE = (128, 128)
PADDING = 10
ICONS_DIR = r"c:\git\spellloop\project\assets\icons"

FILES_TO_PROCESS = [
    { "src": "icon_crystal_guardian.png", "dest": "fusion_crystal_guardian.png" },
    { "src": "icon_void_storm.png", "dest": "fusion_void_storm.png" }
]

def process_file(file_info):
    src_path = os.path.join(ICONS_DIR, file_info["src"])
    dest_path = os.path.join(ICONS_DIR, file_info["dest"])
    
    if not os.path.exists(src_path):
        print(f"File not found: {src_path}")
        return

    print(f"Processing {file_info['src']} -> {file_info['dest']}")
    
    try:
        img = Image.open(src_path).convert("RGBA")
        
        # trim
        bbox = img.getbbox()
        if bbox:
            img = img.crop(bbox)
        
        # calculate scale
        max_w = TARGET_SIZE[0] - (PADDING * 2)
        max_h = TARGET_SIZE[1] - (PADDING * 2)
        
        iw, ih = img.size
        scale = min(max_w / iw, max_h / ih)
        
        new_w = int(iw * scale)
        new_h = int(ih * scale)
        
        img_resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
        
        # new canvas
        final = Image.new("RGBA", TARGET_SIZE, (0, 0, 0, 0))
        paste_x = (TARGET_SIZE[0] - new_w) // 2
        paste_y = (TARGET_SIZE[1] - new_h) // 2
        
        final.paste(img_resized, (paste_x, paste_y))
        
        final.save(dest_path)
        print(f"  Saved to {dest_path}")
        
        # Clean up original source if name is different
        if src_path != dest_path:
            # Close the image object so we can delete the file (Windows lock issue)
            img.close() 
            # Force close just in case
            try:
                os.remove(src_path)
                print(f"  Removed source {file_info['src']}")
            except Exception as e:
                print(f"  Could not remove source (locked?): {e}")

    except Exception as e:
        print(f"  Error processing: {e}")

if __name__ == "__main__":
    for f in FILES_TO_PROCESS:
        process_file(f)
