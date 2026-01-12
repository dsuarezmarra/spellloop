#!/usr/bin/env python3
"""
Intelligent Pyromancer sprite processor for Spellloop - Version 4
Fixes:
- All sprites normalized to the same size (based on largest sprite)
- Fixed left/right swap (left.png shows right-facing, so we swap names)
- Consistent centering across all frames
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
            gap_width = prev - start + 1
            if gap_width >= min_gap_width:
                gaps.append((start, prev))
            start = col
        prev = col

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

    sprite_regions = []

    if not gaps:
        sprite_regions.append((0, width - 1))
    else:
        first_gap_start = gaps[0][0]
        if first_gap_start > 0:
            sprite_regions.append((0, first_gap_start - 1))

        for i in range(len(gaps) - 1):
            current_gap_end = gaps[i][1]
            next_gap_start = gaps[i + 1][0]
            region_start = current_gap_end + 1
            region_end = next_gap_start - 1
            if region_end > region_start:
                sprite_regions.append((region_start, region_end))

        last_gap_end = gaps[-1][1]
        if last_gap_end < width - 1:
            sprite_regions.append((last_gap_end + 1, width - 1))

    min_sprite_width = 30
    sprite_regions = [(s, e) for s, e in sprite_regions if e - s + 1 >= min_sprite_width]

    print(f"    Found {len(sprite_regions)} sprite regions")

    return sprite_regions


def get_content_bounds(img):
    """Get the bounding box of non-transparent content."""
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    alpha = img.split()[3]
    return alpha.getbbox()


def extract_sprite_raw(img, left, right):
    """
    Extract a sprite from the image given horizontal bounds.
    Returns the trimmed sprite with its original dimensions.
    """
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    height = img.size[1]
    sprite = img.crop((left, 0, right + 1, height))

    bounds = get_content_bounds(sprite)
    if bounds:
        sprite = sprite.crop(bounds)

    return sprite


def normalize_sprites(sprites, target_size, foot_position=0.85):
    """
    Normalize all sprites to the same size canvas.
    First finds the max dimensions, then scales all consistently.
    """
    if not sprites:
        return []

    # Find max dimensions across all sprites
    max_width = 0
    max_height = 0
    for sprite in sprites:
        w, h = sprite.size
        max_width = max(max_width, w)
        max_height = max(max_height, h)

    print(f"    Max sprite dimensions: {max_width}x{max_height}")

    # Calculate uniform scale factor based on largest sprite
    max_dim = int(target_size * 0.80)  # Leave 20% margin
    scale = 1.0
    if max_width > max_dim or max_height > max_dim:
        scale = min(max_dim / max_width, max_dim / max_height)
        print(f"    Uniform scale factor: {scale:.3f}")

    # Apply uniform scaling and centering to all sprites
    normalized = []
    for sprite in sprites:
        if sprite.mode != 'RGBA':
            sprite = sprite.convert('RGBA')

        width, height = sprite.size

        # Apply the SAME scale to all sprites
        if scale < 1.0:
            new_width = int(width * scale)
            new_height = int(height * scale)
            sprite = sprite.resize((new_width, new_height), Image.Resampling.LANCZOS)
            width, height = new_width, new_height

        # Create canvas
        canvas = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))

        # Center horizontally, place feet at foot_position
        x = (target_size - width) // 2
        y = int(target_size * foot_position) - height
        y = max(0, y)

        canvas.paste(sprite, (x, y), sprite)
        normalized.append(canvas)

    return normalized


def process_spritesheet_normalized(image_path, output_prefix, output_dir, expected_frames=None):
    """
    Process a spritesheet, extracting and normalizing all sprites.
    Returns list of normalized frame images.
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

    regions = find_sprite_regions(img)

    if expected_frames and len(regions) != expected_frames:
        print(f"    WARNING: Expected {expected_frames} frames, found {len(regions)}")
        if len(regions) < expected_frames:
            regions = subdivide_regions(img, regions, expected_frames)

    # Extract raw sprites first
    raw_sprites = []
    for i, (left, right) in enumerate(regions):
        sprite = extract_sprite_raw(img, left, right)
        print(f"    Frame {i+1}: Extracted {sprite.size[0]}x{sprite.size[1]}")
        raw_sprites.append(sprite)

    # Normalize all sprites together (uniform scaling)
    ensure_dir(output_dir)
    normalized = normalize_sprites(raw_sprites, FRAME_SIZE)

    # Save
    for i, frame in enumerate(normalized):
        output_path = output_dir / f"{output_prefix}_{i+1}.png"
        frame.save(output_path)
        print(f"    Saved: {output_path.name}")

    return normalized


def subdivide_regions(img, regions, target_count):
    """Subdivide regions if we found fewer than expected."""
    if len(regions) == 0:
        width = img.size[0]
        frame_width = width // target_count
        return [(i * frame_width, (i + 1) * frame_width - 1) for i in range(target_count)]

    new_regions = list(regions)

    while len(new_regions) < target_count:
        widths = [(r[1] - r[0], i) for i, r in enumerate(new_regions)]
        widths.sort(reverse=True)

        widest_idx = widths[0][1]
        widest_region = new_regions[widest_idx]

        best_split = find_best_split(img, widest_region[0], widest_region[1])
        mid = (widest_region[0] + widest_region[1]) // 2

        if best_split:
            left_region = (widest_region[0], best_split - 1)
            right_region = (best_split, widest_region[1])
        else:
            left_region = (widest_region[0], mid)
            right_region = (mid + 1, widest_region[1])

        new_regions[widest_idx] = left_region
        new_regions.insert(widest_idx + 1, right_region)

    new_regions.sort(key=lambda r: r[0])
    return new_regions


def find_best_split(img, left, right):
    """Find the best column to split a region."""
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    height = img.size[1]
    mid = (left + right) // 2
    search_range = min(50, (right - left) // 4)

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
    """Flip frames horizontally."""
    print(f"  Generating flipped sprites: {output_prefix}")
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

    # Collect all raw sprites first to find global max dimensions
    all_raw_sprites = []
    sprite_info = []  # (direction, sprites)

    # DOWN
    down_path = walk_dir / "down.png"
    if down_path.exists():
        print(f"\n  Extracting: down.png")
        img = Image.open(down_path).convert('RGBA')
        regions = find_sprite_regions(img)
        if len(regions) < 4:
            regions = subdivide_regions(img, regions, 4)
        sprites = [extract_sprite_raw(img, l, r) for l, r in regions]
        all_raw_sprites.extend(sprites)
        sprite_info.append(("down", sprites))

    # UP
    up_path = walk_dir / "up.png"
    if up_path.exists():
        print(f"\n  Extracting: up.png")
        img = Image.open(up_path).convert('RGBA')
        regions = find_sprite_regions(img)
        if len(regions) < 4:
            regions = subdivide_regions(img, regions, 4)
        sprites = [extract_sprite_raw(img, l, r) for l, r in regions]
        all_raw_sprites.extend(sprites)
        sprite_info.append(("up", sprites))

    # LEFT (but it's actually RIGHT-facing in the spritesheet!)
    left_path = walk_dir / "left.png"
    if left_path.exists():
        print(f"\n  Extracting: left.png (contains RIGHT-facing sprites)")
        img = Image.open(left_path).convert('RGBA')
        regions = find_sprite_regions(img)
        if len(regions) < 4:
            regions = subdivide_regions(img, regions, 4)
        sprites = [extract_sprite_raw(img, l, r) for l, r in regions]
        all_raw_sprites.extend(sprites)
        # Mark as "right" because the file contains right-facing sprites
        sprite_info.append(("right_from_left", sprites))

    # Find global max dimensions
    max_width = max(s.size[0] for s in all_raw_sprites) if all_raw_sprites else 100
    max_height = max(s.size[1] for s in all_raw_sprites) if all_raw_sprites else 100
    print(f"\n  Global max dimensions: {max_width}x{max_height}")

    # Calculate uniform scale
    max_dim = int(FRAME_SIZE * 0.80)
    scale = 1.0
    if max_width > max_dim or max_height > max_dim:
        scale = min(max_dim / max_width, max_dim / max_height)
    print(f"  Uniform scale factor: {scale:.3f}")

    # Process and save each direction
    ensure_dir(walk_dir)

    for direction, sprites in sprite_info:
        print(f"\n  Processing direction: {direction}")

        normalized = []
        for sprite in sprites:
            if sprite.mode != 'RGBA':
                sprite = sprite.convert('RGBA')

            width, height = sprite.size

            if scale < 1.0:
                new_width = int(width * scale)
                new_height = int(height * scale)
                sprite = sprite.resize((new_width, new_height), Image.Resampling.LANCZOS)
                width, height = new_width, new_height

            canvas = Image.new('RGBA', (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
            x = (FRAME_SIZE - width) // 2
            y = int(FRAME_SIZE * 0.85) - height
            y = max(0, y)
            canvas.paste(sprite, (x, y), sprite)
            normalized.append(canvas)

        if direction == "right_from_left":
            # Save as RIGHT (original sprites face right)
            for i, frame in enumerate(normalized):
                output_path = walk_dir / f"pyromancer_walk_right_{i+1}.png"
                frame.save(output_path)
                print(f"    Saved: {output_path.name}")

            # Generate LEFT by flipping
            print(f"  Generating LEFT by flipping RIGHT")
            for i, frame in enumerate(normalized):
                flipped = frame.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
                output_path = walk_dir / f"pyromancer_walk_left_{i+1}.png"
                flipped.save(output_path)
                print(f"    Saved: {output_path.name}")
        else:
            # Save normally
            for i, frame in enumerate(normalized):
                output_path = walk_dir / f"pyromancer_walk_{direction}_{i+1}.png"
                frame.save(output_path)
                print(f"    Saved: {output_path.name}")


def process_cast_sprites():
    """Process cast sprites."""
    print("\n" + "="*60)
    print("Processing CAST sprites")
    print("="*60)

    cast_dir = BASE_PATH / "cast"

    for f in cast_dir.iterdir():
        if f.suffix == '.png' and 'pyromancer_cast' not in f.name:
            print(f"  Found spritesheet: {f.name}")
            process_spritesheet_normalized(f, "pyromancer_cast", cast_dir, expected_frames=4)
            break


def process_death_sprites():
    """Process death sprites."""
    print("\n" + "="*60)
    print("Processing DEATH sprites")
    print("="*60)

    death_dir = BASE_PATH / "death"

    for f in death_dir.iterdir():
        if f.suffix == '.png' and 'pyromancer_death' not in f.name:
            print(f"  Found spritesheet: {f.name}")
            process_spritesheet_normalized(f, "pyromancer_death", death_dir, expected_frames=4)
            break


def process_hit_sprites():
    """Process hit/damage sprites."""
    print("\n" + "="*60)
    print("Processing HIT sprites")
    print("="*60)

    hit_dir = BASE_PATH / "hit"

    for f in hit_dir.iterdir():
        if f.suffix == '.png' and 'pyromancer_hit' not in f.name:
            print(f"  Found spritesheet: {f.name}")
            process_spritesheet_normalized(f, "pyromancer_hit", hit_dir, expected_frames=2)
            break


def main():
    """Main entry point."""
    print("="*60)
    print("Pyromancer Sprite Processor v4")
    print("- Uniform scaling across all frames")
    print("- Fixed left/right direction swap")
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
