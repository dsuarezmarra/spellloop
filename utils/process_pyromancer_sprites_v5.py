#!/usr/bin/env python3
"""
Pyromancer sprite processor - Version 5 (FINAL)
FIXES ALL ISSUES:
1. ALL sprites (walk, cast, death, hit) normalized to the SAME size
2. Left/Right directions swapped correctly
3. Uniform canvas size and positioning
"""

from PIL import Image
from pathlib import Path

# Configuration
BASE_PATH = Path(__file__).parent.parent / "project" / "assets" / "sprites" / "players" / "pyromancer"
FRAME_SIZE = 500  # Output frame size
MIN_GAP_WIDTH = 3
ALPHA_THRESHOLD = 10


def find_vertical_gaps(img):
    """Find vertical gaps between sprites."""
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    width, height = img.size
    empty_cols = []

    for x in range(width):
        col_has_content = False
        for y in range(height):
            if img.getpixel((x, y))[3] > ALPHA_THRESHOLD:
                col_has_content = True
                break
        if not col_has_content:
            empty_cols.append(x)

    if not empty_cols:
        return []

    gaps = []
    start = empty_cols[0]
    prev = empty_cols[0]

    for col in empty_cols[1:]:
        if col != prev + 1:
            if prev - start + 1 >= MIN_GAP_WIDTH:
                gaps.append((start, prev))
            start = col
        prev = col

    if prev - start + 1 >= MIN_GAP_WIDTH:
        gaps.append((start, prev))

    return gaps


def find_sprite_regions(img):
    """Find sprite regions in spritesheet."""
    width = img.size[0]
    gaps = find_vertical_gaps(img)

    regions = []
    if not gaps:
        regions.append((0, width - 1))
    else:
        if gaps[0][0] > 0:
            regions.append((0, gaps[0][0] - 1))

        for i in range(len(gaps) - 1):
            start = gaps[i][1] + 1
            end = gaps[i + 1][0] - 1
            if end > start:
                regions.append((start, end))

        if gaps[-1][1] < width - 1:
            regions.append((gaps[-1][1] + 1, width - 1))

    return [(s, e) for s, e in regions if e - s + 1 >= 30]


def subdivide_regions(img, regions, target_count):
    """Subdivide regions if needed."""
    if not regions:
        width = img.size[0]
        fw = width // target_count
        return [(i * fw, (i + 1) * fw - 1) for i in range(target_count)]

    new_regions = list(regions)
    while len(new_regions) < target_count:
        widths = [(r[1] - r[0], i) for i, r in enumerate(new_regions)]
        widths.sort(reverse=True)
        idx = widths[0][1]
        region = new_regions[idx]
        mid = (region[0] + region[1]) // 2
        new_regions[idx] = (region[0], mid)
        new_regions.insert(idx + 1, (mid + 1, region[1]))

    new_regions.sort(key=lambda r: r[0])
    return new_regions


def extract_sprite_raw(img, left, right):
    """Extract raw sprite from spritesheet."""
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    sprite = img.crop((left, 0, right + 1, img.size[1]))
    alpha = sprite.split()[3]
    bbox = alpha.getbbox()
    if bbox:
        sprite = sprite.crop(bbox)
    return sprite


def collect_all_sprites():
    """Collect ALL sprites from ALL spritesheets to find global max size."""
    all_sprites = []
    sprite_groups = {}  # name -> list of sprites

    walk_dir = BASE_PATH / "walk"
    cast_dir = BASE_PATH / "cast"
    death_dir = BASE_PATH / "death"
    hit_dir = BASE_PATH / "hit"

    # WALK - down
    down_path = walk_dir / "down.png"
    if down_path.exists():
        img = Image.open(down_path).convert('RGBA')
        regions = find_sprite_regions(img)
        if len(regions) < 4:
            regions = subdivide_regions(img, regions, 4)
        sprites = [extract_sprite_raw(img, l, r) for l, r in regions]
        all_sprites.extend(sprites)
        sprite_groups['walk_down'] = sprites
        print(f"  walk/down.png: {len(sprites)} sprites")

    # WALK - up
    up_path = walk_dir / "up.png"
    if up_path.exists():
        img = Image.open(up_path).convert('RGBA')
        regions = find_sprite_regions(img)
        if len(regions) < 4:
            regions = subdivide_regions(img, regions, 4)
        sprites = [extract_sprite_raw(img, l, r) for l, r in regions]
        all_sprites.extend(sprites)
        sprite_groups['walk_up'] = sprites
        print(f"  walk/up.png: {len(sprites)} sprites")

    # WALK - left (actually RIGHT-facing)
    left_path = walk_dir / "left.png"
    if left_path.exists():
        img = Image.open(left_path).convert('RGBA')
        regions = find_sprite_regions(img)
        if len(regions) < 4:
            regions = subdivide_regions(img, regions, 4)
        sprites = [extract_sprite_raw(img, l, r) for l, r in regions]
        all_sprites.extend(sprites)
        sprite_groups['walk_right'] = sprites  # These are RIGHT-facing!
        print(f"  walk/left.png (RIGHT): {len(sprites)} sprites")

    # CAST
    for f in cast_dir.iterdir():
        if f.suffix == '.png' and 'pyromancer_cast' not in f.name:
            img = Image.open(f).convert('RGBA')
            regions = find_sprite_regions(img)
            if len(regions) < 4:
                regions = subdivide_regions(img, regions, 4)
            sprites = [extract_sprite_raw(img, l, r) for l, r in regions]
            all_sprites.extend(sprites)
            sprite_groups['cast'] = sprites
            print(f"  cast/{f.name}: {len(sprites)} sprites")
            break

    # DEATH
    for f in death_dir.iterdir():
        if f.suffix == '.png' and 'pyromancer_death' not in f.name:
            img = Image.open(f).convert('RGBA')
            regions = find_sprite_regions(img)
            if len(regions) < 4:
                regions = subdivide_regions(img, regions, 4)
            sprites = [extract_sprite_raw(img, l, r) for l, r in regions]
            all_sprites.extend(sprites)
            sprite_groups['death'] = sprites
            print(f"  death/{f.name}: {len(sprites)} sprites")
            break

    # HIT
    for f in hit_dir.iterdir():
        if f.suffix == '.png' and 'pyromancer_hit' not in f.name:
            img = Image.open(f).convert('RGBA')
            regions = find_sprite_regions(img)
            if len(regions) < 2:
                regions = subdivide_regions(img, regions, 2)
            sprites = [extract_sprite_raw(img, l, r) for l, r in regions]
            all_sprites.extend(sprites)
            sprite_groups['hit'] = sprites
            print(f"  hit/{f.name}: {len(sprites)} sprites")
            break

    return all_sprites, sprite_groups


def normalize_and_save(sprite_groups, scale, max_height):
    """Normalize all sprites and save them."""
    walk_dir = BASE_PATH / "walk"
    cast_dir = BASE_PATH / "cast"
    death_dir = BASE_PATH / "death"
    hit_dir = BASE_PATH / "hit"

    for dir_path in [walk_dir, cast_dir, death_dir, hit_dir]:
        dir_path.mkdir(parents=True, exist_ok=True)

    def save_normalized(sprites, prefix, output_dir, is_walk_right=False):
        """Save normalized sprites."""
        for i, sprite in enumerate(sprites):
            w, h = sprite.size

            # Apply uniform scale
            if scale < 1.0:
                new_w = int(w * scale)
                new_h = int(h * scale)
                sprite = sprite.resize((new_w, new_h), Image.Resampling.LANCZOS)
                w, h = new_w, new_h

            # Create canvas
            canvas = Image.new('RGBA', (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))

            # Center horizontally, feet at 85% from top
            x = (FRAME_SIZE - w) // 2
            y = int(FRAME_SIZE * 0.85) - h
            y = max(0, y)

            canvas.paste(sprite, (x, y), sprite)

            output_path = output_dir / f"{prefix}_{i+1}.png"
            canvas.save(output_path)
            print(f"    Saved: {output_path.name}")

            # If this is RIGHT, also generate LEFT by flipping
            if is_walk_right:
                flipped = canvas.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
                left_path = output_dir / f"{prefix.replace('right', 'left')}_{i+1}.png"
                flipped.save(left_path)
                print(f"    Saved: {left_path.name} (flipped)")

    # Save all groups
    if 'walk_down' in sprite_groups:
        print("\n  Saving walk_down:")
        save_normalized(sprite_groups['walk_down'], 'pyromancer_walk_down', walk_dir)

    if 'walk_up' in sprite_groups:
        print("\n  Saving walk_up:")
        save_normalized(sprite_groups['walk_up'], 'pyromancer_walk_up', walk_dir)

    if 'walk_right' in sprite_groups:
        print("\n  Saving walk_right and walk_left:")
        save_normalized(sprite_groups['walk_right'], 'pyromancer_walk_right', walk_dir, is_walk_right=True)

    if 'cast' in sprite_groups:
        print("\n  Saving cast:")
        save_normalized(sprite_groups['cast'], 'pyromancer_cast', cast_dir)

    if 'death' in sprite_groups:
        print("\n  Saving death:")
        save_normalized(sprite_groups['death'], 'pyromancer_death', death_dir)

    if 'hit' in sprite_groups:
        print("\n  Saving hit:")
        save_normalized(sprite_groups['hit'], 'pyromancer_hit', hit_dir)


def main():
    print("="*60)
    print("Pyromancer Sprite Processor v5 - UNIFIED SIZE")
    print("="*60)
    print(f"Base path: {BASE_PATH}")
    print(f"Output frame size: {FRAME_SIZE}x{FRAME_SIZE}")

    print("\n[1] Collecting ALL sprites from ALL spritesheets...")
    all_sprites, sprite_groups = collect_all_sprites()

    if not all_sprites:
        print("ERROR: No sprites found!")
        return

    # Find GLOBAL max dimensions
    max_width = max(s.size[0] for s in all_sprites)
    max_height = max(s.size[1] for s in all_sprites)

    print(f"\n[2] Global max dimensions across ALL sprites: {max_width}x{max_height}")

    # Calculate UNIFORM scale factor
    max_dim = int(FRAME_SIZE * 0.75)  # Leave 25% margin
    scale = 1.0
    if max_width > max_dim or max_height > max_dim:
        scale = min(max_dim / max_width, max_dim / max_height)

    print(f"[3] UNIFORM scale factor for ALL sprites: {scale:.4f}")

    print(f"\n[4] Normalizing and saving ALL sprites...")
    normalize_and_save(sprite_groups, scale, max_height)

    print("\n" + "="*60)
    print("COMPLETE! All sprites now have uniform size.")
    print("="*60)


if __name__ == "__main__":
    main()
