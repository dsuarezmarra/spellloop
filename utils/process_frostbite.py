#!/usr/bin/env python3
"""
Process frostbite sprites - already have transparent background.
Detects frame layout automatically and creates horizontal spritesheet (384x64).
Target format: 6 frames of 64x64 each = 384x64 total (same as fire_wand).
"""

from PIL import Image
import numpy as np
import os

# Paths
INPUT_DIR = r"C:\git\spellloop\project\assets\sprites\projectiles\fusion\frostbite"
OUTPUT_DIR = INPUT_DIR

# Config - Match fire_wand format
FRAME_SIZE = 64  # Output frame size (64x64 per frame)
TOTAL_FRAMES = 6


def find_content_bounds(img):
    """Find the bounding box of non-transparent content."""
    img_array = np.array(img)
    if img_array.shape[2] < 4:
        return None
    
    alpha = img_array[:, :, 3]
    non_transparent = np.where(alpha > 10)
    
    if len(non_transparent[0]) == 0:
        return None
    
    min_y, max_y = non_transparent[0].min(), non_transparent[0].max()
    min_x, max_x = non_transparent[1].min(), non_transparent[1].max()
    return (min_x, min_y, max_x + 1, max_y + 1)


def find_frame_boundaries(img):
    """
    Detect frame boundaries by finding vertical gaps in the content.
    Returns list of (left, top, right, bottom) tuples for each frame.
    """
    img_array = np.array(img)
    alpha = img_array[:, :, 3]
    
    # Find content area
    content_rows = np.where(np.any(alpha > 10, axis=1))[0]
    content_cols = np.where(np.any(alpha > 10, axis=0))[0]
    
    if len(content_rows) == 0 or len(content_cols) == 0:
        return []
    
    top = int(content_rows.min())
    bottom = int(content_rows.max()) + 1
    left = int(content_cols.min())
    right = int(content_cols.max()) + 1
    
    # Check for horizontal gaps (would indicate multiple rows)
    content_area = alpha[top:bottom, left:right]
    row_sums = np.sum(content_area > 10, axis=1)
    
    # Find empty rows in content area
    empty_rows = np.where(row_sums == 0)[0]
    
    # Check if there's a significant horizontal gap (multiple rows of frames)
    horizontal_gaps = []
    if len(empty_rows) > 0:
        start = empty_rows[0]
        prev = empty_rows[0]
        for row in empty_rows[1:]:
            if row != prev + 1:
                if prev - start >= 5:  # Significant gap
                    horizontal_gaps.append((start, prev))
                start = row
            prev = row
        if prev - start >= 5:
            horizontal_gaps.append((start, prev))
    
    frames = []
    
    if len(horizontal_gaps) > 0:
        # Multiple rows of frames - process each row
        row_boundaries = [0] + [gap[1] + 1 for gap in horizontal_gaps] + [bottom - top]
        
        for row_idx in range(len(row_boundaries) - 1):
            row_top = top + row_boundaries[row_idx]
            row_bottom = top + row_boundaries[row_idx + 1]
            
            # Find frames in this row
            row_alpha = alpha[row_top:row_bottom, left:right]
            col_sums = np.sum(row_alpha > 10, axis=0)
            
            row_frames = find_frames_in_strip(col_sums, left, row_top, row_bottom)
            frames.extend(row_frames)
    else:
        # Single row of frames - find vertical gaps
        col_sums = np.sum(content_area > 10, axis=0)
        frames = find_frames_in_strip(col_sums, left, top, bottom)
    
    return frames


def find_frames_in_strip(col_sums, offset_x, top, bottom):
    """Find frame boundaries in a horizontal strip by detecting vertical gaps."""
    empty_cols = np.where(col_sums == 0)[0]
    
    frames = []
    if len(empty_cols) == 0:
        # No gaps - single frame or equally spaced
        width = len(col_sums)
        frame_width = width // TOTAL_FRAMES
        for i in range(TOTAL_FRAMES):
            frames.append((offset_x + i * frame_width, top, 
                          offset_x + (i + 1) * frame_width, bottom))
    else:
        # Find gaps between frames
        gaps = []
        start = empty_cols[0]
        prev = empty_cols[0]
        for col in empty_cols[1:]:
            if col != prev + 1:
                if prev - start >= 2:  # Significant gap
                    gaps.append((int(start), int(prev)))
                start = col
            prev = col
        if prev - start >= 2:
            gaps.append((int(start), int(prev)))
        
        # Build frame boundaries from gaps
        frame_starts = [0] + [gap[1] + 1 for gap in gaps]
        frame_ends = [gap[0] for gap in gaps] + [len(col_sums)]
        
        for i in range(len(frame_starts)):
            left_x = offset_x + frame_starts[i]
            right_x = offset_x + frame_ends[i]
            frames.append((left_x, top, right_x, bottom))
    
    return frames


def scale_to_fit(img, max_size, padding=4):
    """
    Scale image to fit within max_size while maintaining aspect ratio.
    Only scales DOWN if the image is too large - never scales up.
    Uses LANCZOS for smooth scaling.
    """
    w, h = img.size
    if w == 0 or h == 0:
        return img
    
    available_size = max_size - padding
    scale = min(available_size / w, available_size / h)
    
    # Only scale down, never up - preserve small frames as-is
    if scale >= 1:
        return img
    
    new_w = max(1, int(w * scale))
    new_h = max(1, int(h * scale))
    
    return img.resize((new_w, new_h), Image.Resampling.LANCZOS)


def process_image(input_path, output_base_name):
    """
    Process a single spritesheet image:
    1. Load image (already has transparent background)
    2. Detect and extract frames automatically
    3. Create horizontal spritesheet (384x64)
    """
    print(f"\n{'='*60}")
    print(f"Processing: {output_base_name}")
    print(f"Input: {input_path}")
    
    # Load image
    img = Image.open(input_path).convert("RGBA")
    width, height = img.size
    print(f"  Source size: {width}x{height}")
    
    # Detect frame boundaries
    frame_bounds = find_frame_boundaries(img)
    print(f"  Detected {len(frame_bounds)} frames")
    
    if len(frame_bounds) != TOTAL_FRAMES:
        print(f"  WARNING: Expected {TOTAL_FRAMES} frames, got {len(frame_bounds)}")
        # Fall back to equal division
        frame_width = width // TOTAL_FRAMES
        frame_bounds = [(i * frame_width, 0, (i + 1) * frame_width, height) 
                       for i in range(TOTAL_FRAMES)]
    
    # Extract frames
    frames = []
    for i, (left, top, right, bottom) in enumerate(frame_bounds):
        cell = img.crop((left, top, right, bottom))
        
        # Trim to actual content
        content_box = find_content_bounds(cell)
        
        if content_box:
            content = cell.crop(content_box)
            frames.append(content)
            print(f"    Frame {i+1}: bounds ({left},{top})-({right},{bottom}) -> content {content.size}")
        else:
            frames.append(Image.new('RGBA', (1, 1), (0, 0, 0, 0)))
            print(f"    Frame {i+1}: Empty")
    
    # Create output spritesheet (384x64 = 6 frames of 64x64)
    output_width = FRAME_SIZE * TOTAL_FRAMES  # 384
    output_height = FRAME_SIZE  # 64
    output = Image.new('RGBA', (output_width, output_height), (0, 0, 0, 0))
    
    print(f"  Output spritesheet: {output_width}x{output_height}")
    
    # Place each frame centered in its 64x64 cell
    for i, frame in enumerate(frames):
        # Scale to fit within frame with padding
        scaled = scale_to_fit(frame, FRAME_SIZE, padding=4)
        
        # Center in the 64x64 cell
        x_offset = i * FRAME_SIZE + (FRAME_SIZE - scaled.width) // 2
        y_offset = (FRAME_SIZE - scaled.height) // 2
        
        output.paste(scaled, (x_offset, y_offset), scaled)
        print(f"    Placed frame {i+1}: scaled to {scaled.size}, at ({x_offset}, {y_offset})")
    
    # Save output spritesheet
    spritesheet_path = os.path.join(OUTPUT_DIR, f"{output_base_name}.png")
    output.save(spritesheet_path)
    print(f"  Saved: {spritesheet_path}")
    
    return spritesheet_path


def main():
    print("=" * 60)
    print("Frostbite Sprite Processor")
    print("Creates 384x64 spritesheet (6 frames of 64x64)")
    print("=" * 60)
    
    # Process flight spritesheet
    flight_input = os.path.join(INPUT_DIR, "flight_original.png")
    if os.path.exists(flight_input):
        process_image(flight_input, "flight")
    else:
        # Try without _original suffix
        flight_input = os.path.join(INPUT_DIR, "flight.png")
        if os.path.exists(flight_input):
            # Make backup first
            img = Image.open(flight_input)
            img.save(os.path.join(INPUT_DIR, "flight_original.png"))
            process_image(flight_input, "flight")
        else:
            print(f"Warning: flight.png not found")
    
    # Process impact spritesheet
    impact_input = os.path.join(INPUT_DIR, "impact_original.png")
    if os.path.exists(impact_input):
        process_image(impact_input, "impact")
    else:
        # Try without _original suffix
        impact_input = os.path.join(INPUT_DIR, "impact.png")
        if os.path.exists(impact_input):
            # Make backup first
            img = Image.open(impact_input)
            img.save(os.path.join(INPUT_DIR, "impact_original.png"))
            process_image(impact_input, "impact")
        else:
            print(f"Warning: impact.png not found")
    
    print("\n" + "=" * 60)
    print("Processing complete!")
    print("=" * 60)


if __name__ == "__main__":
    main()
