"""
Reprocess pyromancer cast sprites from original spritesheet
to match walk sprite content size exactly
"""
from PIL import Image
from pathlib import Path
import os

BASE = Path(__file__).parent.parent / "project" / "assets" / "sprites" / "players" / "pyromancer"

def get_content_bounds(img):
    """Get content bounding box (non-transparent pixels)"""
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    return img.getbbox()

def get_average_content_size(folder, pattern):
    """Calculate average content size for sprites matching pattern"""
    sizes = []
    
    for f in folder.glob(pattern):
        if f.suffix == '.png' and '.import' not in str(f):
            img = Image.open(f)
            bbox = get_content_bounds(img)
            if bbox:
                left, top, right, bottom = bbox
                sizes.append((right - left, bottom - top))
    
    if sizes:
        avg_w = sum(s[0] for s in sizes) / len(sizes)
        avg_h = sum(s[1] for s in sizes) / len(sizes)
        return avg_w, avg_h
    return None, None

def extract_and_normalize_sprites(source_sheet, output_folder, output_prefix, target_width, target_height, frame_count=4):
    """Extract sprites from sheet and normalize to target size"""
    img = Image.open(source_sheet)
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    sheet_width, sheet_height = img.size
    print(f"  Source sheet: {sheet_width}x{sheet_height}")
    
    # Find content bounds of entire sheet
    sheet_bbox = get_content_bounds(img)
    if not sheet_bbox:
        print("  ❌ No content found in sheet")
        return
    
    left, top, right, bottom = sheet_bbox
    content_width = right - left
    content_height = bottom - top
    print(f"  Content bounds: ({left}, {top}, {right}, {bottom}) = {content_width}x{content_height}")
    
    # Estimate frame width from content
    estimated_frame_width = content_width // frame_count
    print(f"  Estimated frame width: {estimated_frame_width}")
    
    # Extract each frame by detecting gaps or equal division
    frames = []
    
    # Method: Divide content area into equal parts
    for i in range(frame_count):
        frame_left = left + i * estimated_frame_width
        frame_right = left + (i + 1) * estimated_frame_width
        
        # Crop frame from original
        frame = img.crop((frame_left, top, frame_right, bottom))
        
        # Get actual content bounds of this frame
        frame_bbox = get_content_bounds(frame)
        if frame_bbox:
            fl, ft, fr, fb = frame_bbox
            frame_content = frame.crop(frame_bbox)
            frames.append({
                'content': frame_content,
                'width': fr - fl,
                'height': fb - ft
            })
            print(f"    Frame {i+1}: content {fr-fl}x{fb-ft}")
    
    if not frames:
        print("  ❌ No frames extracted")
        return
    
    # Calculate scale factor based on target HEIGHT (to match vertical size)
    # This ensures the character appears the same height when casting as when walking
    max_width = max(f['width'] for f in frames)
    max_height = max(f['height'] for f in frames)
    
    # Scale based on HEIGHT to match the visual height
    scale = target_height / max_height
    
    print(f"  Max frame size: {max_width}x{max_height}")
    print(f"  Target size: {target_width}x{target_height}")
    print(f"  Scale factor (based on height): {scale:.3f}")
    
    # Process each frame
    output_frames = []
    for i, f in enumerate(frames):
        # Resize content
        new_width = int(f['width'] * scale)
        new_height = int(f['height'] * scale)
        resized = f['content'].resize((new_width, new_height), Image.Resampling.LANCZOS)
        
        # Create 128x128 canvas and center content
        canvas = Image.new('RGBA', (128, 128), (0, 0, 0, 0))
        x = (128 - new_width) // 2
        y = (128 - new_height) // 2
        canvas.paste(resized, (x, y))
        
        # Save individual frame
        output_path = output_folder / f"{output_prefix}_{i+1}.png"
        canvas.save(output_path)
        print(f"  ✓ Saved: {output_path.name}")
        
        output_frames.append(canvas)
    
    # Create spritesheet
    sheet = Image.new('RGBA', (128 * len(output_frames), 128), (0, 0, 0, 0))
    for i, frame in enumerate(output_frames):
        sheet.paste(frame, (i * 128, 0))
    
    sheet_path = output_folder / f"{output_prefix}.png"
    sheet.save(sheet_path)
    print(f"  ✓ Saved spritesheet: {sheet_path.name}")

def main():
    print("=" * 60)
    print("REPROCESSING PYROMANCER CAST SPRITES FROM ORIGINAL")
    print("=" * 60)
    
    # Get target size from walk sprites
    walk_folder = BASE / "walk"
    target_width, target_height = get_average_content_size(walk_folder, "pyromancer_walk_down_*.png")
    
    if not target_width:
        print("❌ Could not determine target size from walk sprites")
        return
    
    print(f"\n📏 Target content size (from walk): {target_width:.1f}x{target_height:.1f}")
    
    # Find original cast spritesheet (the one with UUID in name)
    cast_folder = BASE / "cast"
    original_sheets = [f for f in cast_folder.glob("*.png") 
                       if 'pyromancer_cast' not in f.name 
                       and '.import' not in str(f)
                       and '-' in f.stem]  # UUID pattern
    
    if original_sheets:
        print(f"\n📄 Found original spritesheet: {original_sheets[0].name}")
        extract_and_normalize_sprites(
            original_sheets[0], 
            cast_folder, 
            "pyromancer_cast", 
            target_width, 
            target_height
        )
    else:
        print("\n⚠️ No original spritesheet found")
        print("  Looking for files without 'pyromancer_cast' in name...")
        for f in cast_folder.glob("*.png"):
            if '.import' not in str(f):
                print(f"    {f.name}")
    
    print("\n" + "=" * 60)
    print("✅ DONE!")
    print("=" * 60)

if __name__ == "__main__":
    main()
