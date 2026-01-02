#!/usr/bin/env python3
"""
Process Gemini-generated sprites with simulated checkered transparency background.
Specifically tuned for the gray checkered pattern Gemini uses.

Usage:
    python process_gemini_void_pulse.py input.png output.png
"""

import numpy as np
from PIL import Image
from pathlib import Path


def remove_gemini_checkered(img: Image.Image) -> Image.Image:
    """
    Remove Gemini's specific checkered pattern (dark gray ~62 and light gray ~100).
    """
    img_array = np.array(img.convert('RGBA'), dtype=np.float32)
    h, w = img_array.shape[:2]
    
    rgb = img_array[:, :, :3]
    
    # Gemini uses two gray tones for checkered pattern
    # Dark gray: ~62, Light gray: ~100
    dark_gray = np.array([62, 62, 62], dtype=np.float32)
    light_gray = np.array([100, 100, 100], dtype=np.float32)
    
    # Calculate distance from both checkered grays
    diff_dark = np.sqrt(np.sum((rgb - dark_gray) ** 2, axis=2))
    diff_light = np.sqrt(np.sum((rgb - light_gray) ** 2, axis=2))
    
    # Minimum distance to either checkered color
    min_diff = np.minimum(diff_dark, diff_light)
    
    # Check if pixel is grayscale (all channels similar)
    max_channel = np.max(rgb, axis=2)
    min_channel = np.min(rgb, axis=2)
    is_grayscale = (max_channel - min_channel) < 15
    
    # Background = grayscale AND close to checkered colors
    tolerance = 20
    is_background = is_grayscale & (min_diff < tolerance)
    
    # Calculate alpha: background = 0, content = 255
    # With gradient for edge pixels
    alpha = np.where(is_background, 0, 255)
    
    # Soften edges
    edge_tolerance = 40
    edge_mask = is_grayscale & (min_diff >= tolerance) & (min_diff < edge_tolerance)
    edge_alpha = ((min_diff - tolerance) / (edge_tolerance - tolerance)) * 255
    alpha = np.where(edge_mask, edge_alpha, alpha)
    
    # For colored pixels (non-grayscale), calculate alpha based on saturation and brightness
    saturation = (max_channel - min_channel) / (max_channel + 1)
    
    # Vortex colors: purples, magentas - high saturation = definitely content
    colored_alpha = np.clip(saturation * 400 + (255 - min_diff), 0, 255)
    alpha = np.where(~is_grayscale, colored_alpha, alpha)
    
    img_array[:, :, 3] = alpha
    
    return Image.fromarray(img_array.astype(np.uint8), 'RGBA')


def find_vortex_bounds(img: Image.Image) -> tuple:
    """
    Find the vertical bounds of the actual vortex content.
    """
    arr = np.array(img)
    
    if arr.shape[2] == 4:
        # Use alpha
        alpha = arr[:, :, 3]
        content_mask = alpha > 50
    else:
        # Use color difference from gray
        rgb = arr[:, :, :3].astype(float)
        gray_avg = np.mean(rgb, axis=2)
        saturation = np.max(rgb, axis=2) - np.min(rgb, axis=2)
        content_mask = saturation > 20
    
    # Find rows with significant content
    row_content = np.sum(content_mask, axis=1)
    threshold = np.max(row_content) * 0.1
    
    content_rows = np.where(row_content > threshold)[0]
    
    if len(content_rows) > 0:
        top = max(0, content_rows[0] - 10)
        bottom = min(arr.shape[0], content_rows[-1] + 10)
        return top, bottom
    
    return 0, arr.shape[0]


def extract_frames_smart(
    img: Image.Image,
    num_frames: int = 6,
    target_size: int = 56,
    output_frame_size: int = 64
) -> Image.Image:
    """
    Extract frames intelligently, focusing on the content band.
    """
    w, h = img.size
    
    # Find vertical content bounds
    top, bottom = find_vortex_bounds(img)
    content_height = bottom - top
    print(f"  Content vertical band: y={top} to y={bottom} (height={content_height})")
    
    # Crop to content band
    content_band = img.crop((0, top, w, bottom))
    
    # Calculate frame width
    frame_width = w // num_frames
    print(f"  Frame width: {frame_width}px")
    
    frames = []
    
    for i in range(num_frames):
        x1 = i * frame_width
        x2 = (i + 1) * frame_width
        
        frame = content_band.crop((x1, 0, x2, content_band.height))
        
        # Find content bounds within frame
        bbox = frame.getbbox()
        
        if bbox:
            # Extract content with small padding
            pad = 5
            bx1 = max(0, bbox[0] - pad)
            by1 = max(0, bbox[1] - pad)
            bx2 = min(frame.width, bbox[2] + pad)
            by2 = min(frame.height, bbox[3] + pad)
            
            content = frame.crop((bx1, by1, bx2, by2))
            cw, ch = content.size
            
            # Scale to fit target size
            scale = min(target_size / cw, target_size / ch)
            new_w = int(cw * scale)
            new_h = int(ch * scale)
            
            content = content.resize((new_w, new_h), Image.Resampling.LANCZOS)
            
            # Center in output frame
            output_frame = Image.new('RGBA', (output_frame_size, output_frame_size), (0, 0, 0, 0))
            paste_x = (output_frame_size - new_w) // 2
            paste_y = (output_frame_size - new_h) // 2
            output_frame.paste(content, (paste_x, paste_y), content)
            
            frames.append(output_frame)
            print(f"    Frame {i+1}: bbox {bbox}, content {cw}x{ch} → {new_w}x{new_h}")
        else:
            frames.append(Image.new('RGBA', (output_frame_size, output_frame_size), (0, 0, 0, 0)))
            print(f"    Frame {i+1}: no content found")
    
    # Combine frames
    total_width = output_frame_size * num_frames
    output = Image.new('RGBA', (total_width, output_frame_size), (0, 0, 0, 0))
    
    for i, frame in enumerate(frames):
        output.paste(frame, (i * output_frame_size, 0), frame)
    
    return output


def remove_watermark_area(img: Image.Image) -> Image.Image:
    """
    Make the watermark area in bottom-right transparent.
    """
    arr = np.array(img)
    h, w = arr.shape[:2]
    
    # Watermark is in bottom-right, usually ~50-80px
    wm_size = 80
    
    # Check bottom-right corner
    corner = arr[h-wm_size:h, w-wm_size:w]
    
    # Make low-saturation pixels in this area transparent
    if corner.shape[2] == 4:
        rgb = corner[:, :, :3].astype(float)
        saturation = np.max(rgb, axis=2) - np.min(rgb, axis=2)
        
        # Low saturation = likely watermark or background
        watermark_mask = saturation < 30
        corner[:, :, 3] = np.where(watermark_mask, 0, corner[:, :, 3])
        arr[h-wm_size:h, w-wm_size:w] = corner
    
    return Image.fromarray(arr, 'RGBA')


def process_void_pulse(input_path: str, output_path: str):
    """
    Full processing pipeline for void_pulse Gemini image.
    """
    print(f"\n{'='*60}")
    print("Processing Gemini Void Pulse")
    print(f"{'='*60}")
    print(f"Input: {input_path}")
    
    # Load
    img = Image.open(input_path)
    print(f"Size: {img.width}x{img.height}, mode: {img.mode}")
    
    # Step 1: Remove checkered background
    print("\n[1] Removing checkered background...")
    img_clean = remove_gemini_checkered(img)
    
    # Step 2: Remove watermark
    print("\n[2] Removing watermark...")
    img_clean = remove_watermark_area(img_clean)
    
    # Save debug version
    debug_path = Path(output_path).parent / "void_pulse_nobg_debug.png"
    img_clean.save(debug_path)
    print(f"    Debug saved: {debug_path}")
    
    # Step 3: Extract frames
    print("\n[3] Extracting 6 frames...")
    output = extract_frames_smart(img_clean, num_frames=6, target_size=56, output_frame_size=64)
    
    # Save final
    output.save(output_path)
    print(f"\n✅ Output: {output_path}")
    print(f"   Size: {output.width}x{output.height}")


if __name__ == '__main__':
    import sys
    if len(sys.argv) >= 3:
        process_void_pulse(sys.argv[1], sys.argv[2])
    else:
        print("Usage: python process_gemini_void_pulse.py input.png output.png")
