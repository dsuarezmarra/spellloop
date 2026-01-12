#!/usr/bin/env python3
"""
Pyromancer sprite processor for Spellloop.
- Splits horizontal spritesheets into individual frames
- Generates "right" sprites by flipping "left" sprites
- Normalizes and centers sprites to 500x500
"""

from PIL import Image
import os
from pathlib import Path

# Configuration
BASE_PATH = Path(__file__).parent.parent / "project" / "assets" / "sprites" / "players" / "pyromancer"
FRAME_SIZE = 500

def ensure_dir(path):
    """Ensure directory exists."""
    path.mkdir(parents=True, exist_ok=True)

def split_horizontal_strip(image_path, num_frames, output_prefix, output_dir):
    """
    Split a horizontal sprite strip into individual frames.
    """
    print(f"  Processing: {image_path.name}")
    
    img = Image.open(image_path)
    width, height = img.size
    frame_width = width // num_frames
    
    print(f"    Original size: {width}x{height}, Frame width: {frame_width}")
    
    frames = []
    for i in range(num_frames):
        left = i * frame_width
        right = (i + 1) * frame_width
        frame = img.crop((left, 0, right, height))
        
        # Resize/center to FRAME_SIZE x FRAME_SIZE if needed
        frame = center_and_resize(frame, FRAME_SIZE)
        
        # Save individual frame
        output_path = output_dir / f"{output_prefix}_{i+1}.png"
        frame.save(output_path)
        print(f"    Saved: {output_path.name}")
        frames.append(frame)
    
    return frames

def center_and_resize(img, target_size):
    """
    Center image on a target_size x target_size canvas.
    If image is larger, resize maintaining aspect ratio.
    """
    # Convert to RGBA if not already
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    width, height = img.size
    
    # If image is larger than target, resize
    if width > target_size or height > target_size:
        ratio = min(target_size / width, target_size / height)
        new_width = int(width * ratio)
        new_height = int(height * ratio)
        img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
        width, height = img.size
    
    # Create transparent canvas
    canvas = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))
    
    # Center the image
    x = (target_size - width) // 2
    y = (target_size - height) // 2
    canvas.paste(img, (x, y), img)
    
    return canvas

def flip_horizontal(frames, output_prefix, output_dir):
    """
    Flip frames horizontally to create the "right" version.
    """
    print(f"  Generating flipped sprites for: {output_prefix}")
    
    flipped_frames = []
    for i, frame in enumerate(frames):
        flipped = frame.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        output_path = output_dir / f"{output_prefix}_{i+1}.png"
        flipped.save(output_path)
        print(f"    Saved: {output_path.name}")
        flipped_frames.append(flipped)
    
    return flipped_frames

def process_walk_sprites():
    """Process walk sprites."""
    print("\n=== Processing WALK sprites ===")
    walk_dir = BASE_PATH / "walk"
    
    # Walk Down
    down_path = walk_dir / "down.png"
    if down_path.exists():
        split_horizontal_strip(down_path, 4, "pyromancer_walk_down", walk_dir)
    else:
        print(f"  WARNING: Not found {down_path}")
    
    # Walk Up
    up_path = walk_dir / "up.png"
    if up_path.exists():
        split_horizontal_strip(up_path, 4, "pyromancer_walk_up", walk_dir)
    else:
        print(f"  WARNING: Not found {up_path}")
    
    # Walk Left
    left_path = walk_dir / "left.png"
    if left_path.exists():
        left_frames = split_horizontal_strip(left_path, 4, "pyromancer_walk_left", walk_dir)
        # Generate Walk Right by flipping Left
        flip_horizontal(left_frames, "pyromancer_walk_right", walk_dir)
    else:
        print(f"  WARNING: Not found {left_path}")

def process_cast_sprites():
    """Process cast sprites."""
    print("\n=== Processing CAST sprites ===")
    cast_dir = BASE_PATH / "cast"
    
    # Find the cast file (may have long name)
    cast_files = list(cast_dir.glob("*.png"))
    if cast_files:
        cast_path = cast_files[0]
        split_horizontal_strip(cast_path, 4, "pyromancer_cast", cast_dir)
    else:
        print("  WARNING: No cast files found")

def process_death_sprites():
    """Process death sprites."""
    print("\n=== Processing DEATH sprites ===")
    death_dir = BASE_PATH / "death"
    
    # Find the death file
    death_files = list(death_dir.glob("*.png"))
    if death_files:
        death_path = death_files[0]
        split_horizontal_strip(death_path, 4, "pyromancer_death", death_dir)
    else:
        print("  WARNING: No death files found")

def process_hit_sprites():
    """Process hit sprites."""
    print("\n=== Processing HIT sprites ===")
    hit_dir = BASE_PATH / "hit"
    
    # Find the hit file
    hit_files = list(hit_dir.glob("*.png"))
    if hit_files:
        hit_path = hit_files[0]
        split_horizontal_strip(hit_path, 2, "pyromancer_hit", hit_dir)
    else:
        print("  WARNING: No hit files found")

def main():
    print("=" * 60)
    print("SPRITE PROCESSOR - PYROMANCER")
    print("=" * 60)
    
    if not BASE_PATH.exists():
        print(f"ERROR: Base directory not found: {BASE_PATH}")
        return
    
    print(f"Base directory: {BASE_PATH}")
    
    # Process each animation type
    process_walk_sprites()
    process_cast_sprites()
    process_death_sprites()
    process_hit_sprites()
    
    print("\n" + "=" * 60)
    print("PROCESS COMPLETED")
    print("=" * 60)
    print("\nGenerated files:")
    print("  - walk/pyromancer_walk_down_1.png to _4.png")
    print("  - walk/pyromancer_walk_up_1.png to _4.png")
    print("  - walk/pyromancer_walk_left_1.png to _4.png")
    print("  - walk/pyromancer_walk_right_1.png to _4.png (flipped)")
    print("  - cast/pyromancer_cast_1.png to _4.png")
    print("  - death/pyromancer_death_1.png to _4.png")
    print("  - hit/pyromancer_hit_1.png to _2.png")

if __name__ == "__main__":
    main()
