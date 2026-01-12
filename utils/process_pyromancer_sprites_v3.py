#!/usr/bin/env python3
"""
Intelligent Pyromancer sprite processor for Spellloop - Version 3
This version uses gap detection to properly separate sprites without cutting through pixels.

Key features:
- Detects vertical gaps (empty columns) between sprites
- Never cuts through pixels
- Properly centers each sprite on the output canvas
- Generates mirrored sprites for right direction
"""

from PIL import Image
import os
from pathlib import Path

# Configuration
BASE_PATH = Path(__file__).parent.parent / "project" / "assets" / "sprites" / "players" / "pyromancer"
FRAME_SIZE = 500  # Output frame size
MIN_GAP_WIDTH = 3  # Minimum number of empty columns to consider as a gap
ALPHA_THRESHOLD = 10  # Pixels with alpha below this are considered transparent


def ensure_dir(path):
    """Ensure directory exists."""
    path.mkdir(parents=True, exist_ok=True)


def find_vertical_gaps(img, min_gap_width=MIN_GAP_WIDTH):
    """
    Find vertical gaps (columns of transparent pixels) in the image.
    Returns list of (gap_start, gap_end) tuples.
    """
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    width, height = img.size

    # Find all empty columns
    empty_cols = []
    for x in range(width):
        col_has_content = False
        for y in range(height):
            pixel = img.getpixel((x, y))
            if pixel[3] > ALPHA_THRESHOLD:
                col_has_content = True
                break
        if not col_has_content:
            empty_cols.append(x)

    if not empty_cols:
        return []

    # Group consecutive empty columns into gaps
    gaps = []
    start = empty_cols[0]
    prev = empty_cols[0]

    for col in empty_cols[1:]:
        if col != prev + 1:
            # End of current gap
            gap_width = prev - start + 1
            if gap_width >= min_gap_width:
                gaps.append((start, prev))
            start = col
        prev = col

    # Don't forget the last gap
    gap_width = prev - start + 1
    if gap_width >= min_gap_width:
        gaps.append((start, prev))

    return gaps


def find_sprite_regions(img):
    """
    Find the regions containing sprites by detecting gaps between them.
    Returns list of (left, right) tuples for each sprite.
    """
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    width, height = img.size
    gaps = find_vertical_gaps(img)

    print(f"    Found {len(gaps)} gaps in {width}px width image")
    for i, (gs, ge) in enumerate(gaps):
        print(f"      Gap {i+1}: cols {gs}-{ge} (width: {ge-gs+1})")

    # Build sprite regions from gaps
    sprite_regions = []

    if not gaps:
        # No gaps found, entire image is one sprite
        sprite_regions.append((0, width - 1))
    else:
        # First region: from start to first gap
        first_gap_start = gaps[0][0]
        if first_gap_start > 0:
            sprite_regions.append((0, first_gap_start - 1))

        # Middle regions: between gaps
        for i in range(len(gaps) - 1):
            current_gap_end = gaps[i][1]
            next_gap_start = gaps[i + 1][0]

            # Region starts after current gap, ends before next gap
            region_start = current_gap_end + 1
            region_end = next_gap_start - 1

            if region_end > region_start:  # Valid region
                sprite_regions.append((region_start, region_end))

        # Last region: from last gap to end
        last_gap_end = gaps[-1][1]
        if last_gap_end < width - 1:
            sprite_regions.append((last_gap_end + 1, width - 1))

    # Filter out very small regions (likely noise)
    min_sprite_width = 30
    sprite_regions = [(s, e) for s, e in sprite_regions if e - s + 1 >= min_sprite_width]

    print(f"    Found {len(sprite_regions)} sprite regions")
    for i, (rs, re) in enumerate(sprite_regions):
        print(f"      Sprite {i+1}: cols {rs}-{re} (width: {re-rs+1})")

    return sprite_regions


def get_content_bounds(img):
    """
    Get the bounding box of non-transparent content in an image.
    Returns (left, top, right, bottom) or None if empty.
    """
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    alpha = img.split()[3]
    bbox = alpha.getbbox()
    return bbox


def extract_sprite(img, left, right):
    """
    Extract a sprite from the image given horizontal bounds.
    Also trims vertical transparent space.
    Returns the trimmed sprite.
    """
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    height = img.size[1]

    # Crop horizontally
    sprite = img.crop((left, 0, right + 1, height))

    # Find vertical bounds (trim top/bottom transparency)
    bounds = get_content_bounds(sprite)
    if bounds:
        sprite = sprite.crop(bounds)

    return sprite


def center_on_canvas(img, target_size, foot_position=0.85):
    """
    Center image on a target_size x target_size transparent canvas.
    Positions the sprite so feet are at foot_position (0-1) from top.
    Scales down if necessary to fit.
    """
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    width, height = img.size

    # Calculate scale to fit within target while maintaining aspect ratio
    max_dim = int(target_size * 0.85)  # Leave 15% margin

    if width > max_dim or height > max_dim:
        scale = min(max_dim / width, max_dim / height)
        new_width = int(width * scale)
        new_height = int(height * scale)
        img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
        width, height = new_width, new_height
        print(f"           Scaled to: {width}x{height}")

    # Create transparent canvas
    canvas = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))

    # Center horizontally, place feet at foot_position from top
    x = (target_size - width) // 2
    y = int(target_size * foot_position) - height

    # Ensure y is not negative
    y = max(0, y)

    canvas.paste(img, (x, y), img)

    return canvas


def process_spritesheet(image_path, output_prefix, output_dir, expected_frames=None):
    """
    Process a spritesheet by detecting gaps and extracting sprites.

    Args:
        image_path: Path to the spritesheet
        output_prefix: Prefix for output files
        output_dir: Directory for output files
        expected_frames: If provided, will validate the number of detected frames

    Returns:
        List of processed frame images
    """
    print(f"  Processing: {image_path.name}")

    if not image_path.exists():
        print(f"    ERROR: File not found: {image_path}")
        return []

    img = Image.open(image_path)
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    width, height = img.size
    print(f"    Original size: {width}x{height}")

    # Find sprite regions
    regions = find_sprite_regions(img)

    if expected_frames and len(regions) != expected_frames:
        print(f"    WARNING: Expected {expected_frames} frames, found {len(regions)}")
        # If we found fewer regions, try to subdivide
        if len(regions) < expected_frames:
            print(f"    Attempting to subdivide regions...")
            regions = subdivide_regions(img, regions, expected_frames)

    ensure_dir(output_dir)

    frames = []
    for i, (left, right) in enumerate(regions):
        # Extract sprite from region
        sprite = extract_sprite(img, left, right)
        sprite_w, sprite_h = sprite.size
        print(f"    Frame {i+1}: Extracted {sprite_w}x{sprite_h} from cols {left}-{right}")

        # Center on output canvas
        output_frame = center_on_canvas(sprite, FRAME_SIZE)

        # Save
        output_path = output_dir / f"{output_prefix}_{i+1}.png"
        output_frame.save(output_path)
        print(f"    Saved: {output_path.name}")
        frames.append(output_frame)

    return frames


def subdivide_regions(img, regions, target_count):
    """
    If gap detection found fewer regions than expected, try to subdivide.
    This handles cases where sprites are touching.
    """
    if len(regions) == 0:
        # No regions found, divide evenly
        width = img.size[0]
        frame_width = width // target_count
        return [(i * frame_width, (i + 1) * frame_width - 1) for i in range(target_count)]

    # Try to subdivide the largest regions
    new_regions = list(regions)

    while len(new_regions) < target_count:
        # Find the widest region
        widths = [(r[1] - r[0], i) for i, r in enumerate(new_regions)]
        widths.sort(reverse=True)

        widest_idx = widths[0][1]
        widest_region = new_regions[widest_idx]

        # Split in half
        mid = (widest_region[0] + widest_region[1]) // 2

        # Find the best split point (column with least content near the middle)
        best_split = find_best_split(img, widest_region[0], widest_region[1])

        if best_split:
            left_region = (widest_region[0], best_split - 1)
            right_region = (best_split, widest_region[1])
        else:
            left_region = (widest_region[0], mid)
            right_region = (mid + 1, widest_region[1])

        new_regions[widest_idx] = left_region
        new_regions.insert(widest_idx + 1, right_region)

    # Sort by position
    new_regions.sort(key=lambda r: r[0])

    print(f"    Subdivided into {len(new_regions)} regions")
    for i, (rs, re) in enumerate(new_regions):
        print(f"      Region {i+1}: cols {rs}-{re} (width: {re-rs+1})")

    return new_regions


def find_best_split(img, left, right):
    """
    Find the best column to split a region (column with least alpha content).
    Searches around the middle of the region.
    """
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    height = img.size[1]
    mid = (left + right) // 2
    search_range = min(50, (right - left) // 4)  # Search within 50px or 1/4 of region

    min_alpha = float('inf')
    best_col = None

    for x in range(max(left + 10, mid - search_range), min(right - 10, mid + search_range)):
        col_alpha = 0
        for y in range(height):
            col_alpha += img.getpixel((x, y))[3]

        if col_alpha < min_alpha:
            min_alpha = col_alpha
            best_col = x

    return best_col


def flip_horizontal(frames, output_prefix, output_dir):
    """
    Flip frames horizontally to create the "right" version.
    """
    print(f"  Generating flipped sprites for: {output_prefix}")
    ensure_dir(output_dir)

    flipped_frames = []
    for i, frame in enumerate(frames):
        flipped = frame.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        output_path = output_dir / f"{output_prefix}_{i+1}.png"
        flipped.save(output_path)
        print(f"    Saved: {output_path.name}")
        flipped_frames.append(flipped)

    return flipped_frames


def process_walk_sprites():
    """Process walk sprites for all 4 directions."""
    print("\n" + "="*60)
    print("Processing WALK sprites")
    print("="*60)

    walk_dir = BASE_PATH / "walk"

    # Process DOWN
    down_path = walk_dir / "down.png"
    if down_path.exists():
        frames = process_spritesheet(down_path, "pyromancer_walk_down", walk_dir, expected_frames=4)

    # Process UP
    up_path = walk_dir / "up.png"
    if up_path.exists():
        frames = process_spritesheet(up_path, "pyromancer_walk_up", walk_dir, expected_frames=4)

    # Process LEFT
    left_path = walk_dir / "left.png"
    if left_path.exists():
        left_frames = process_spritesheet(left_path, "pyromancer_walk_left", walk_dir, expected_frames=4)

        # Generate RIGHT by flipping LEFT
        if left_frames:
            flip_horizontal(left_frames, "pyromancer_walk_right", walk_dir)


def process_cast_sprites():
    """Process cast sprites."""
    print("\n" + "="*60)
    print("Processing CAST sprites")
    print("="*60)

    cast_dir = BASE_PATH / "cast"

    # Find the spritesheet (look for the UUID-named file)
    for f in cast_dir.iterdir():
        if f.suffix == '.png' and 'pyromancer_cast' not in f.name:
            print(f"  Found spritesheet: {f.name}")
            frames = process_spritesheet(f, "pyromancer_cast", cast_dir, expected_frames=4)
            break


def process_death_sprites():
    """Process death sprites."""
    print("\n" + "="*60)
    print("Processing DEATH sprites")
    print("="*60)

    death_dir = BASE_PATH / "death"

    # Find the spritesheet (look for the UUID-named file)
    for f in death_dir.iterdir():
        if f.suffix == '.png' and 'pyromancer_death' not in f.name:
            print(f"  Found spritesheet: {f.name}")
            frames = process_spritesheet(f, "pyromancer_death", death_dir, expected_frames=4)
            break


def process_hit_sprites():
    """Process hit/damage sprites."""
    print("\n" + "="*60)
    print("Processing HIT sprites")
    print("="*60)

    hit_dir = BASE_PATH / "hit"

    # Find the spritesheet (look for the UUID-named file)
    for f in hit_dir.iterdir():
        if f.suffix == '.png' and 'pyromancer_hit' not in f.name:
            print(f"  Found spritesheet: {f.name}")
            frames = process_spritesheet(f, "pyromancer_hit", hit_dir, expected_frames=2)
            break


def main():
    """Main entry point."""
    print("="*60)
    print("Pyromancer Sprite Processor v3 - Intelligent Gap Detection")
    print("="*60)
    print(f"Base path: {BASE_PATH}")
    print(f"Output frame size: {FRAME_SIZE}x{FRAME_SIZE}")

    process_walk_sprites()
    process_cast_sprites()
    process_death_sprites()
    process_hit_sprites()

    print("\n" + "="*60)
    print("PROCESSING COMPLETE!")
    print("="*60)


if __name__ == "__main__":
    main()
