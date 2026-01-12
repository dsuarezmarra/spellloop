#!/usr/bin/env python3
"""
Improved Pyromancer sprite processor for Spellloop.
- Detects actual sprite bounds using alpha channel
- Splits horizontal spritesheets into individual frames
- Centers sprites properly without cutting
- Generates "right" sprites by flipping "left" sprites
"""

from PIL import Image
import os
from pathlib import Path

# Configuration
BASE_PATH = Path(__file__).parent.parent / "project" / "assets" / "sprites" / "players" / "pyromancer"
FRAME_SIZE = 500  # Output frame size
PADDING = 20  # Extra padding around the sprite

def ensure_dir(path):
    """Ensure directory exists."""
    path.mkdir(parents=True, exist_ok=True)

def get_content_bounds(img):
    """
    Get the bounding box of non-transparent content in an image.
    Returns (left, top, right, bottom) or None if empty.
    """
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    # Get alpha channel
    alpha = img.split()[3]
    bbox = alpha.getbbox()
    return bbox

def split_horizontal_strip_smart(image_path, num_frames, output_prefix, output_dir):
    """
    Split a horizontal sprite strip into individual frames.
    Uses smart detection to find each frame's content.
    """
    print(f"  Processing: {image_path.name}")

    img = Image.open(image_path)
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    width, height = img.size
    frame_width = width // num_frames

    print(f"    Original size: {width}x{height}")
    print(f"    Frame width: {frame_width}, Frames: {num_frames}")

    frames = []
    for i in range(num_frames):
        left = i * frame_width
        right = (i + 1) * frame_width

        # Crop the frame from the strip
        frame = img.crop((left, 0, right, height))

        # Get content bounds
        bounds = get_content_bounds(frame)
        if bounds:
            content_left, content_top, content_right, content_bottom = bounds
            content_width = content_right - content_left
            content_height = content_bottom - content_top
            print(f"    Frame {i+1}: Content bounds ({content_left}, {content_top}) to ({content_right}, {content_bottom})")
            print(f"             Content size: {content_width}x{content_height}")
        else:
            print(f"    Frame {i+1}: No content detected, using full frame")
            bounds = (0, 0, frame_width, height)

        # Crop to content with some padding
        content_left, content_top, content_right, content_bottom = bounds

        # Add padding but stay within frame bounds
        padded_left = max(0, content_left - PADDING)
        padded_top = max(0, content_top - PADDING)
        padded_right = min(frame_width, content_right + PADDING)
        padded_bottom = min(height, content_bottom + PADDING)

        # Extract the content
        content = frame.crop((padded_left, padded_top, padded_right, padded_bottom))

        # Create output canvas and center the content
        output_frame = center_on_canvas(content, FRAME_SIZE)

        # Save individual frame
        output_path = output_dir / f"{output_prefix}_{i+1}.png"
        output_frame.save(output_path)
        print(f"    Saved: {output_path.name} ({output_frame.size[0]}x{output_frame.size[1]})")
        frames.append(output_frame)

    return frames

def center_on_canvas(img, target_size):
    """
    Center image on a target_size x target_size transparent canvas.
    Scales down if necessary to fit.
    """
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    width, height = img.size

    # Calculate scale to fit within target while maintaining aspect ratio
    # Leave some margin (90% of target size)
    max_dim = int(target_size * 0.9)

    if width > max_dim or height > max_dim:
        scale = min(max_dim / width, max_dim / height)
        new_width = int(width * scale)
        new_height = int(height * scale)
        img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
        width, height = new_width, new_height
        print(f"             Scaled to: {width}x{height}")

    # Create transparent canvas
    canvas = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))

    # Center horizontally, but place sprite towards bottom (feet at ~85% height)
    x = (target_size - width) // 2
    y = int(target_size * 0.85) - height  # Feet at 85% from top

    # Ensure y is not negative
    y = max(0, y)

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
    ensure_dir(walk_dir)

    # Walk Down
    down_path = walk_dir / "down.png"
    if down_path.exists():
        split_horizontal_strip_smart(down_path, 4, "pyromancer_walk_down", walk_dir)
    else:
        print(f"  WARNING: Not found {down_path}")

    # Walk Up
    up_path = walk_dir / "up.png"
    if up_path.exists():
        split_horizontal_strip_smart(up_path, 4, "pyromancer_walk_up", walk_dir)
    else:
        print(f"  WARNING: Not found {up_path}")

    # Walk Left
    left_path = walk_dir / "left.png"
    if left_path.exists():
        left_frames = split_horizontal_strip_smart(left_path, 4, "pyromancer_walk_left", walk_dir)
        # Generate Walk Right by flipping Left
        flip_horizontal(left_frames, "pyromancer_walk_right", walk_dir)
    else:
        print(f"  WARNING: Not found {left_path}")

def process_cast_sprites():
    """Process cast sprites."""
    print("\n=== Processing CAST sprites ===")
    cast_dir = BASE_PATH / "cast"
    ensure_dir(cast_dir)

    # Find the cast source file (exclude already processed _1, _2, etc.)
    cast_files = [f for f in cast_dir.glob("*.png") if not any(f.stem.endswith(f"_{i}") for i in range(1, 10))]
    if cast_files:
        cast_path = cast_files[0]
        split_horizontal_strip_smart(cast_path, 4, "pyromancer_cast", cast_dir)
    else:
        print("  WARNING: No cast source files found")

def process_death_sprites():
    """Process death sprites."""
    print("\n=== Processing DEATH sprites ===")
    death_dir = BASE_PATH / "death"
    ensure_dir(death_dir)

    # Find the death source file
    death_files = [f for f in death_dir.glob("*.png") if not any(f.stem.endswith(f"_{i}") for i in range(1, 10))]
    if death_files:
        death_path = death_files[0]
        split_horizontal_strip_smart(death_path, 4, "pyromancer_death", death_dir)
    else:
        print("  WARNING: No death source files found")

def process_hit_sprites():
    """Process hit sprites."""
    print("\n=== Processing HIT sprites ===")
    hit_dir = BASE_PATH / "hit"
    ensure_dir(hit_dir)

    # Find the hit source file
    hit_files = [f for f in hit_dir.glob("*.png") if not any(f.stem.endswith(f"_{i}") for i in range(1, 10))]
    if hit_files:
        hit_path = hit_files[0]
        # Hit usually has 2 frames
        split_horizontal_strip_smart(hit_path, 2, "pyromancer_hit", hit_dir)
    else:
        print("  WARNING: No hit source files found")

def main():
    print("=" * 60)
    print("PYROMANCER SPRITE PROCESSOR v2 (Smart Detection)")
    print("=" * 60)
    print(f"Base path: {BASE_PATH}")
    print(f"Output frame size: {FRAME_SIZE}x{FRAME_SIZE}")

    process_walk_sprites()
    process_cast_sprites()
    process_death_sprites()
    process_hit_sprites()

    print("\n" + "=" * 60)
    print("Processing complete!")
    print("=" * 60)

if __name__ == "__main__":
    main()
