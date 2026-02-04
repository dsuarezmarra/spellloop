import os
from PIL import Image

def generate_char_icons():
    base_path = r"project/assets/sprites/players"
    output_path = r"project/assets/icons"
    
    if not os.path.exists(output_path):
        os.makedirs(output_path)

    # List of characters (dirs)
    characters = [d for d in os.listdir(base_path) if os.path.isdir(os.path.join(base_path, d))]
    
    print(f"Found {len(characters)} characters: {characters}")

    for char in characters:
        strip_path = os.path.join(base_path, char, "walk", "walk_down_strip.png")
        
        # Fallback if strip doesn't exist (try non-strip)
        if not os.path.exists(strip_path):
            strip_path = os.path.join(base_path, char, "walk", "walk_down.png")
        
        if not os.path.exists(strip_path):
            print(f"⚠️ Sprite not found for {char}")
            continue

        try:
            img = Image.open(strip_path)
            
            # Assume 3 frames for strip, aspect ratio check
            # 624x208 -> 3 frames of 208x208
            frame_width = img.height # Square frames usually
            if img.width > img.height:
                frame_width = img.height
                # First frame is 0 to frame_width
            
            # 1. Extract first frame
            first_frame = img.crop((0, 0, frame_width, img.height))
            
            # 2. Smart Crop for Face/Bust
            # Frame is ~208x208. Character is centered. Head is up.
            # Crop box size: 60% of frame width
            crop_size = int(frame_width * 0.6) 
            
            center_x = frame_width // 2
            # Center Y biased upwards (0.35) to catch head
            center_y = int(img.height * 0.35)
            
            left = center_x - (crop_size // 2)
            top = center_y - (crop_size // 2)
            right = left + crop_size
            bottom = top + crop_size
            
            # Clamp
            left = max(0, left)
            top = max(0, top)
            right = min(frame_width, right)
            bottom = min(img.height, bottom)
            
            face_crop = first_frame.crop((left, top, right, bottom))
            
            # 3. Resize to 64x64
            icon = face_crop.resize((64, 64), Image.Resampling.LANCZOS)
            
            # 4. Save
            icon_name = f"{char}.png" # Matches ID
            save_path = os.path.join(output_path, icon_name)
            icon.save(save_path)
            print(f"✅ Generated icon for {char}: {save_path}")
            
        except Exception as e:
            print(f"❌ Error processing {char}: {e}")

if __name__ == "__main__":
    generate_char_icons()
