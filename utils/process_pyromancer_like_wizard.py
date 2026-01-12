# -*- coding: utf-8 -*-
"""
Process Pyromancer sprites to match Wizard format exactly:
- Individual frames: 128x128
- Walk spritesheets: 512x128 (4 horizontal frames)
- Cast spritesheets: 512x128 (4 horizontal frames)
- Death spritesheets: 512x128 (4 horizontal frames)
- Hit spritesheets: 256x128 (2 horizontal frames)
"""

from PIL import Image
import os

# Paths
BASE_PATH = r"c:\Users\dsuarez1\git\spellloop\project\assets\sprites\players\pyromancer"

# Target size (same as Wizard)
FRAME_SIZE = 128

def find_sprite_bounds(img):
    """Find bounding box of non-transparent content."""
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    pixels = img.load()
    width, height = img.size

    min_x, min_y = width, height
    max_x, max_y = 0, 0

    for y in range(height):
        for x in range(width):
            if pixels[x, y][3] > 10:
                min_x = min(min_x, x)
                max_x = max(max_x, x)
                min_y = min(min_y, y)
                max_y = max(max_y, y)

    if max_x < min_x:
        return None

    return (min_x, min_y, max_x + 1, max_y + 1)

def extract_sprites_from_source(source_path):
    """Extract individual sprites from source image (612x408)."""
    img = Image.open(source_path).convert('RGBA')
    width, height = img.size
    print(f"  Source size: {width}x{height}")

    pixels = img.load()
    sprites = []

    # Find columns with content
    col_has_content = []
    for x in range(width):
        has_content = False
        for y in range(height):
            if pixels[x, y][3] > 10:
                has_content = True
                break
        col_has_content.append(has_content)

    # Find sprite groups
    in_sprite = False
    start_x = 0
    sprite_ranges = []

    for x in range(width):
        if col_has_content[x] and not in_sprite:
            in_sprite = True
            start_x = x
        elif not col_has_content[x] and in_sprite:
            in_sprite = False
            sprite_ranges.append((start_x, x))

    if in_sprite:
        sprite_ranges.append((start_x, width))

    print(f"  Found {len(sprite_ranges)} sprite columns")

    # Extract each sprite
    for i, (x1, x2) in enumerate(sprite_ranges):
        min_y, max_y = height, 0
        for y in range(height):
            for x in range(x1, x2):
                if pixels[x, y][3] > 10:
                    min_y = min(min_y, y)
                    max_y = max(max_y, y)
                    break

        if max_y > min_y:
            sprite = img.crop((x1, min_y, x2, max_y + 1))
            sprites.append(sprite)
            print(f"    Sprite {i+1}: {sprite.size}")

    return sprites

def resize_sprite_to_frame(sprite, frame_size=FRAME_SIZE):
    """Resize sprite to fit in frame_size x frame_size, maintaining aspect."""
    # Crop to content
    bounds = find_sprite_bounds(sprite)
    if bounds:
        sprite = sprite.crop(bounds)

    sw, sh = sprite.size

    # Calculate scale with margin
    margin = 8
    available = frame_size - margin * 2

    scale = min(available / sw, available / sh)

    new_w = int(sw * scale)
    new_h = int(sh * scale)

    # Resize
    resized = sprite.resize((new_w, new_h), Image.Resampling.LANCZOS)

    # Create frame and center
    frame = Image.new('RGBA', (frame_size, frame_size), (0, 0, 0, 0))
    paste_x = (frame_size - new_w) // 2
    paste_y = (frame_size - new_h) // 2
    frame.paste(resized, (paste_x, paste_y), resized)

    return frame

def create_spritesheet(frames, name):
    """Create horizontal spritesheet from frames."""
    if not frames:
        return None

    num_frames = len(frames)
    width = FRAME_SIZE * num_frames
    height = FRAME_SIZE

    sheet = Image.new('RGBA', (width, height), (0, 0, 0, 0))

    for i, frame in enumerate(frames):
        sheet.paste(frame, (i * FRAME_SIZE, 0), frame)

    return sheet

def main():
    print("=" * 60)
    print("PROCESSING PYROMANCER LIKE WIZARD")
    print("Target: 128x128 frames, 512x128 spritesheets")
    print("=" * 60)

    # Source files
    walk_sources = {
        'down': 'down.png',
        'up': 'up.png',
        'left': 'left.png',
    }

    cast_source = '7375d636-18b6-45b7-96fd-cf53ddff27db-md-removebg-preview.png'
    death_source = 'fa27ea80-897e-44d0-9c8d-263a8e843f0b-md-removebg-preview.png'
    hit_source = '6a2cf5f4-c44b-43cc-9357-c60351f8134e-md-removebg-preview.png'

    all_frames = {}

    # WALK animations
    for direction, source in walk_sources.items():
        source_path = os.path.join(BASE_PATH, 'walk', source)
        if os.path.exists(source_path):
            print(f"\n=== WALK {direction.upper()} ===")
            sprites = extract_sprites_from_source(source_path)
            if sprites:
                frames = [resize_sprite_to_frame(s) for s in sprites[:4]]
                while len(frames) < 4:
                    frames.append(frames[-1])
                all_frames[f'walk_{direction}'] = frames

    # LEFT file has RIGHT-facing sprites
    if 'walk_left' in all_frames:
        right_frames = all_frames['walk_left']
        left_frames = [f.transpose(Image.FLIP_LEFT_RIGHT) for f in right_frames]
        all_frames['walk_right'] = right_frames
        all_frames['walk_left'] = left_frames

    # CAST animation
    cast_path = os.path.join(BASE_PATH, 'cast', cast_source)
    if os.path.exists(cast_path):
        print(f"\n=== CAST ===")
        sprites = extract_sprites_from_source(cast_path)
        if sprites:
            frames = [resize_sprite_to_frame(s) for s in sprites[:4]]
            while len(frames) < 4:
                frames.append(frames[-1])
            all_frames['cast'] = frames

    # DEATH animation
    death_path = os.path.join(BASE_PATH, 'death', death_source)
    if os.path.exists(death_path):
        print(f"\n=== DEATH ===")
        sprites = extract_sprites_from_source(death_path)
        if sprites:
            frames = [resize_sprite_to_frame(s) for s in sprites[:4]]
            while len(frames) < 4:
                frames.append(frames[-1])
            all_frames['death'] = frames

    # HIT animation
    hit_path = os.path.join(BASE_PATH, 'hit', hit_source)
    if os.path.exists(hit_path):
        print(f"\n=== HIT ===")
        sprites = extract_sprites_from_source(hit_path)
        if sprites:
            frames = [resize_sprite_to_frame(s) for s in sprites[:2]]
            while len(frames) < 2:
                frames.append(frames[-1])
            all_frames['hit'] = frames

    # SAVE FILES
    print("\n" + "=" * 60)
    print("SAVING FILES")
    print("=" * 60)

    # Walk animations
    for direction in ['down', 'up', 'left', 'right']:
        key = f'walk_{direction}'
        if key in all_frames:
            frames = all_frames[key]
            folder = os.path.join(BASE_PATH, 'walk')

            # Individual frames
            for i, frame in enumerate(frames):
                path = os.path.join(folder, f'pyromancer_walk_{direction}_{i+1}.png')
                frame.save(path)
                print(f"  Saved: pyromancer_walk_{direction}_{i+1}.png (128x128)")

            # Spritesheet
            sheet = create_spritesheet(frames, f'walk_{direction}')
            sheet_path = os.path.join(folder, f'pyromancer_walk_{direction}.png')
            sheet.save(sheet_path)
            print(f"  Saved: pyromancer_walk_{direction}.png ({sheet.size[0]}x{sheet.size[1]})")

    # Cast
    if 'cast' in all_frames:
        frames = all_frames['cast']
        folder = os.path.join(BASE_PATH, 'cast')

        for i, frame in enumerate(frames):
            path = os.path.join(folder, f'pyromancer_cast_{i+1}.png')
            frame.save(path)
            print(f"  Saved: pyromancer_cast_{i+1}.png (128x128)")

        sheet = create_spritesheet(frames, 'cast')
        sheet_path = os.path.join(folder, 'pyromancer_cast.png')
        sheet.save(sheet_path)
        print(f"  Saved: pyromancer_cast.png ({sheet.size[0]}x{sheet.size[1]})")

    # Death
    if 'death' in all_frames:
        frames = all_frames['death']
        folder = os.path.join(BASE_PATH, 'death')

        for i, frame in enumerate(frames):
            path = os.path.join(folder, f'pyromancer_death_{i+1}.png')
            frame.save(path)
            print(f"  Saved: pyromancer_death_{i+1}.png (128x128)")

        sheet = create_spritesheet(frames, 'death')
        sheet_path = os.path.join(folder, 'pyromancer_death.png')
        sheet.save(sheet_path)
        print(f"  Saved: pyromancer_death.png ({sheet.size[0]}x{sheet.size[1]})")

    # Hit
    if 'hit' in all_frames:
        frames = all_frames['hit']
        folder = os.path.join(BASE_PATH, 'hit')

        for i, frame in enumerate(frames):
            path = os.path.join(folder, f'pyromancer_hit_{i+1}.png')
            frame.save(path)
            print(f"  Saved: pyromancer_hit_{i+1}.png (128x128)")

        sheet = create_spritesheet(frames, 'hit')
        sheet_path = os.path.join(folder, 'pyromancer_hit.png')
        sheet.save(sheet_path)
        print(f"  Saved: pyromancer_hit.png ({sheet.size[0]}x{sheet.size[1]})")

    print("\n" + "=" * 60)
    print("DONE!")
    print("Format: IDENTICAL to Wizard")
    print("- Frames: 128x128")
    print("- Walk/Cast/Death sheets: 512x128")
    print("- Hit sheet: 256x128")
    print("=" * 60)

if __name__ == '__main__':
    main()
