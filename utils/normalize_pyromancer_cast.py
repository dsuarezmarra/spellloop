"""
Normalize pyromancer cast sprites to match walk sprite sizes
This will rescale the content of cast sprites to match the average walk sprite size
while keeping the same 128x128 canvas.
"""
from PIL import Image
from pathlib import Path
import shutil

BASE = Path(__file__).parent.parent / "project" / "assets" / "sprites" / "players" / "pyromancer"

def get_content_bounds(img):
    """Get content bounding box (non-transparent pixels)"""
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    return img.getbbox()

def get_average_content_size(folder, pattern):
    """Calculate average content size for sprites matching pattern"""
    total_width = 0
    total_height = 0
    count = 0
    
    for f in folder.glob(pattern):
        if f.suffix == '.png' and '.import' not in str(f):
            img = Image.open(f)
            bbox = get_content_bounds(img)
            if bbox:
                left, top, right, bottom = bbox
                total_width += right - left
                total_height += bottom - top
                count += 1
    
    if count > 0:
        return total_width / count, total_height / count
    return None, None

def rescale_sprite_to_match(img_path, target_width, target_height, output_path):
    """Rescale sprite content to target size while keeping 128x128 canvas"""
    img = Image.open(img_path)
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    original_size = img.size
    bbox = get_content_bounds(img)
    
    if not bbox:
        print(f"  ⚠️ No content found in {img_path.name}")
        return False
    
    left, top, right, bottom = bbox
    content_width = right - left
    content_height = bottom - top
    
    # Calculate scale factor needed
    scale_x = target_width / content_width
    scale_y = target_height / content_height
    # Use uniform scale to avoid distortion
    scale = min(scale_x, scale_y)
    
    if abs(scale - 1.0) < 0.01:
        print(f"  ✓ {img_path.name}: Already correct size")
        # Don't copy to same file
        if img_path != output_path:
            shutil.copy(img_path, output_path)
        return True
    
    # Extract content
    content = img.crop(bbox)
    
    # Resize content
    new_content_width = int(content_width * scale)
    new_content_height = int(content_height * scale)
    content_resized = content.resize((new_content_width, new_content_height), Image.Resampling.LANCZOS)
    
    # Create new canvas (same size as original)
    new_img = Image.new('RGBA', original_size, (0, 0, 0, 0))
    
    # Calculate position to center content (keep same visual center)
    original_center_x = (left + right) / 2
    original_center_y = (top + bottom) / 2
    
    new_left = int(original_center_x - new_content_width / 2)
    new_top = int(original_center_y - new_content_height / 2)
    
    # Ensure content fits within canvas
    new_left = max(0, min(new_left, original_size[0] - new_content_width))
    new_top = max(0, min(new_top, original_size[1] - new_content_height))
    
    new_img.paste(content_resized, (new_left, new_top))
    new_img.save(output_path)
    
    print(f"  ✓ {img_path.name}: Scaled {scale:.3f}x ({content_width}x{content_height} -> {new_content_width}x{new_content_height})")
    return True

def main():
    print("=" * 60)
    print("NORMALIZING PYROMANCER CAST SPRITES")
    print("=" * 60)
    
    # Get average walk sprite size as target
    walk_folder = BASE / "walk"
    target_width, target_height = get_average_content_size(walk_folder, "pyromancer_walk_down_*.png")
    
    if not target_width:
        print("❌ Could not determine target size from walk sprites")
        return
    
    print(f"\n📏 Target content size (from walk): {target_width:.1f}x{target_height:.1f}")
    
    # Process cast sprites
    cast_folder = BASE / "cast"
    print(f"\n📁 Processing cast sprites in: {cast_folder}")
    print("-" * 40)
    
    # Backup original folder name (optional)
    # backup_folder = BASE / "cast_backup"
    
    for f in sorted(cast_folder.glob("pyromancer_cast_*.png")):
        if '.import' not in str(f):
            # Overwrite in place
            rescale_sprite_to_match(f, target_width, target_height, f)
    
    # Also process the spritesheet if it exists
    spritesheet = cast_folder / "pyromancer_cast.png"
    if spritesheet.exists():
        print(f"\n📄 Processing spritesheet: {spritesheet.name}")
        img = Image.open(spritesheet)
        width, height = img.size
        frame_count = width // 128  # Assuming 128px frames
        
        if frame_count > 0:
            # Split, rescale, and rejoin
            frames = []
            for i in range(frame_count):
                frame = img.crop((i * 128, 0, (i + 1) * 128, height))
                
                # Create temp file for processing
                temp_path = cast_folder / f"_temp_frame_{i}.png"
                frame.save(temp_path)
                
                # Rescale
                rescale_sprite_to_match(temp_path, target_width, target_height, temp_path)
                
                # Load rescaled and close properly
                rescaled = Image.open(temp_path)
                frames.append(rescaled.copy())
                rescaled.close()
                temp_path.unlink()  # Delete temp
            
            # Create new spritesheet
            new_sheet = Image.new('RGBA', (frame_count * 128, 128), (0, 0, 0, 0))
            for i, frame in enumerate(frames):
                new_sheet.paste(frame, (i * 128, 0))
            new_sheet.save(spritesheet)
            print(f"  ✓ Spritesheet updated: {frame_count} frames")
    
    print("\n" + "=" * 60)
    print("✅ DONE! Cast sprites normalized to match walk sprites.")
    print("=" * 60)

if __name__ == "__main__":
    main()
