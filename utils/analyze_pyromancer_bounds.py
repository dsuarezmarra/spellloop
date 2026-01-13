"""
Analyze pyromancer sprite content bounds to detect size differences
"""
from PIL import Image
from pathlib import Path

BASE = Path(__file__).parent.parent / "project" / "assets" / "sprites" / "players" / "pyromancer"

def get_content_bounds(img_path):
    """Get content bounding box (non-transparent pixels)"""
    img = Image.open(img_path)
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    bbox = img.getbbox()
    if bbox:
        left, top, right, bottom = bbox
        return {
            'size': img.size,
            'bbox': bbox,
            'content_width': right - left,
            'content_height': bottom - top,
            'center_x': (left + right) / 2,
            'center_y': (top + bottom) / 2
        }
    return None

def analyze_folder(folder, pattern):
    """Analyze all matching sprites in folder"""
    results = []
    for f in sorted(folder.glob(pattern)):
        if f.suffix == '.png' and '.import' not in str(f):
            info = get_content_bounds(f)
            if info:
                info['file'] = f.name
                results.append(info)
    return results

print("=" * 60)
print("PYROMANCER SPRITE CONTENT ANALYSIS")
print("=" * 60)

# Analyze walk sprites
print("\n📁 WALK DOWN SPRITES:")
print("-" * 40)
walk_sprites = analyze_folder(BASE / "walk", "pyromancer_walk_down_*.png")
for s in walk_sprites:
    print(f"  {s['file']}: content {s['content_width']}x{s['content_height']}, center=({s['center_x']:.1f}, {s['center_y']:.1f})")

if walk_sprites:
    avg_walk_width = sum(s['content_width'] for s in walk_sprites) / len(walk_sprites)
    avg_walk_height = sum(s['content_height'] for s in walk_sprites) / len(walk_sprites)
    print(f"\n  AVERAGE: {avg_walk_width:.1f}x{avg_walk_height:.1f}")

# Analyze cast sprites
print("\n📁 CAST SPRITES:")
print("-" * 40)
cast_sprites = analyze_folder(BASE / "cast", "pyromancer_cast_*.png")
for s in cast_sprites:
    print(f"  {s['file']}: content {s['content_width']}x{s['content_height']}, center=({s['center_x']:.1f}, {s['center_y']:.1f})")

if cast_sprites:
    avg_cast_width = sum(s['content_width'] for s in cast_sprites) / len(cast_sprites)
    avg_cast_height = sum(s['content_height'] for s in cast_sprites) / len(cast_sprites)
    print(f"\n  AVERAGE: {avg_cast_width:.1f}x{avg_cast_height:.1f}")

# Compare
if walk_sprites and cast_sprites:
    print("\n" + "=" * 60)
    print("COMPARISON:")
    print("=" * 60)
    width_diff = avg_cast_width - avg_walk_width
    height_diff = avg_cast_height - avg_walk_height
    print(f"  Walk average: {avg_walk_width:.1f}x{avg_walk_height:.1f}")
    print(f"  Cast average: {avg_cast_width:.1f}x{avg_cast_height:.1f}")
    print(f"  Difference: {width_diff:+.1f}x{height_diff:+.1f}")
    
    scale_x = avg_cast_width / avg_walk_width if avg_walk_width > 0 else 1
    scale_y = avg_cast_height / avg_walk_height if avg_walk_height > 0 else 1
    print(f"  Scale factor: {scale_x:.3f}x {scale_y:.3f}y")
    
    if abs(scale_x - 1.0) > 0.05 or abs(scale_y - 1.0) > 0.05:
        print(f"\n  ⚠️ CAST sprites are {'LARGER' if scale_x > 1 else 'SMALLER'} than WALK sprites!")
        print(f"  Recommended scale for cast: {1/scale_x:.3f}x {1/scale_y:.3f}y")
