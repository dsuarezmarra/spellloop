#!/usr/bin/env python3
"""
Process Gemini void pulse sprite - specialized for purple vortex detection.
"""

import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter1d
from pathlib import Path


def detect_vortexes_by_color(img: Image.Image) -> tuple:
    """
    Detect vortex content by finding purple/magenta pixels.
    Returns: (y_top, y_bottom, x_centers)
    """
    arr = np.array(img)
    h, w = arr.shape[:2]
    
    r, g, b = arr[:,:,0].astype(float), arr[:,:,1].astype(float), arr[:,:,2].astype(float)
    
    # Purple: R and B similar, both higher than G
    is_purple = (np.abs(r - b) < 60) & ((r + b) / 2 > g + 15) & (r > 40)
    
    # Very dark (void centers) 
    luminance = 0.299 * r + 0.587 * g + 0.114 * b
    is_void_dark = luminance < 35
    
    # Bright energy
    is_bright = luminance > 140
    
    # Content mask
    content_mask = is_purple | is_void_dark | is_bright
    
    # Find vertical bounds
    row_density = np.sum(content_mask, axis=1)
    threshold = np.max(row_density) * 0.2
    significant_rows = np.where(row_density > threshold)[0]
    
    y_top = significant_rows[0] if len(significant_rows) > 0 else 0
    y_bottom = significant_rows[-1] if len(significant_rows) > 0 else h
    
    # Add padding
    y_top = max(0, y_top - 20)
    y_bottom = min(h, y_bottom + 20)
    
    print(f"  Content Y: {y_top} to {y_bottom} (height: {y_bottom - y_top})")
    
    # Find frame centers using purple density in content band
    content_band = content_mask[y_top:y_bottom, :]
    col_density = np.sum(content_band, axis=0).astype(float)
    smoothed = gaussian_filter1d(col_density, sigma=30)
    
    # Expected 6 frames - find 6 major peaks
    expected_spacing = w // 6
    
    # Find peaks with minimum spacing
    peaks = []
    min_peak_distance = expected_spacing * 0.6
    
    for i in range(int(expected_spacing * 0.5), w - int(expected_spacing * 0.5)):
        if smoothed[i] > np.max(smoothed) * 0.25:
            # Check if local maximum
            is_max = True
            for j in range(max(0, i - 30), min(w, i + 30)):
                if smoothed[j] > smoothed[i]:
                    is_max = False
                    break
            
            if is_max:
                # Check distance from existing peaks
                too_close = False
                for p in peaks:
                    if abs(i - p) < min_peak_distance:
                        too_close = True
                        break
                
                if not too_close:
                    peaks.append(i)
    
    # If we have more than 6, keep the 6 strongest
    if len(peaks) > 6:
        peak_values = [(p, smoothed[p]) for p in peaks]
        peak_values.sort(key=lambda x: -x[1])
        peaks = sorted([p[0] for p in peak_values[:6]])
    
    # If we have fewer than 6, use uniform distribution
    if len(peaks) < 6:
        peaks = [int(expected_spacing * (i + 0.5)) for i in range(6)]
    
    print(f"  Frame centers: {peaks}")
    
    return y_top, y_bottom, peaks, content_mask


def create_alpha_from_content(img: Image.Image, content_mask: np.ndarray) -> Image.Image:
    """
    Create RGBA image with alpha based on content detection.
    """
    arr = np.array(img)
    h, w = arr.shape[:2]
    
    # Create RGBA
    if arr.shape[2] == 3:
        rgba = np.zeros((h, w, 4), dtype=np.uint8)
        rgba[:, :, :3] = arr
    else:
        rgba = arr.copy()
    
    r, g, b = arr[:,:,0].astype(float), arr[:,:,1].astype(float), arr[:,:,2].astype(float)
    luminance = 0.299 * r + 0.587 * g + 0.114 * b
    
    # Calculate color distance from gray (the background)
    # Gray background is ~62 or ~100
    gray1, gray2 = 62.0, 100.0
    
    dist_gray1 = np.sqrt((r - gray1)**2 + (g - gray1)**2 + (b - gray1)**2)
    dist_gray2 = np.sqrt((r - gray2)**2 + (g - gray2)**2 + (b - gray2)**2)
    min_gray_dist = np.minimum(dist_gray1, dist_gray2)
    
    # Saturation check
    max_rgb = np.max(arr[:,:,:3], axis=2)
    min_rgb = np.min(arr[:,:,:3], axis=2)
    saturation = (max_rgb.astype(float) - min_rgb.astype(float)) / (max_rgb.astype(float) + 1)
    
    # Alpha calculation:
    # - High saturation (colored) = high alpha
    # - Far from gray = high alpha
    # - In content_mask = boost alpha
    
    alpha = np.zeros((h, w), dtype=float)
    
    # Base alpha from gray distance
    alpha = np.clip(min_gray_dist / 30 - 0.5, 0, 1)
    
    # Boost for saturation
    alpha = np.clip(alpha + saturation * 2, 0, 1)
    
    # Boost for content mask
    alpha = np.where(content_mask, np.clip(alpha + 0.3, 0, 1), alpha)
    
    # Very dark pixels (void center) should be opaque if in content area
    void_dark = luminance < 40
    alpha = np.where(void_dark & content_mask, 1.0, alpha)
    
    # Very bright pixels should be opaque
    bright = luminance > 150
    alpha = np.where(bright, 1.0, alpha)
    
    # Apply threshold for cleaner edges
    alpha = np.where(alpha > 0.3, np.clip(alpha * 1.5, 0, 1), 0)
    
    rgba[:, :, 3] = (alpha * 255).astype(np.uint8)
    
    return Image.fromarray(rgba, 'RGBA')


def extract_frames(
    img: Image.Image,
    y_top: int,
    y_bottom: int,
    x_centers: list,
    target_size: int = 56,
    output_frame_size: int = 64
) -> Image.Image:
    """
    Extract frames centered on detected vortex positions.
    """
    content_height = y_bottom - y_top
    
    # Calculate frame size based on content
    # Each vortex should be roughly square
    frame_size = min(content_height, img.width // 6)
    
    frames = []
    
    for i, center_x in enumerate(x_centers):
        # Calculate crop region
        half_size = frame_size // 2
        
        x1 = max(0, center_x - half_size)
        x2 = min(img.width, center_x + half_size)
        y1 = y_top
        y2 = y_bottom
        
        # Crop frame
        frame = img.crop((x1, y1, x2, y2))
        
        # Find actual content bounds
        bbox = frame.getbbox()
        
        if bbox:
            # Extract with padding
            pad = 5
            bx1 = max(0, bbox[0] - pad)
            by1 = max(0, bbox[1] - pad)
            bx2 = min(frame.width, bbox[2] + pad)
            by2 = min(frame.height, bbox[3] + pad)
            
            content = frame.crop((bx1, by1, bx2, by2))
            cw, ch = content.size
            
            # Scale to target size
            scale = min(target_size / cw, target_size / ch)
            new_w = max(1, int(cw * scale))
            new_h = max(1, int(ch * scale))
            
            content = content.resize((new_w, new_h), Image.Resampling.LANCZOS)
            
            # Center in output frame
            out_frame = Image.new('RGBA', (output_frame_size, output_frame_size), (0, 0, 0, 0))
            paste_x = (output_frame_size - new_w) // 2
            paste_y = (output_frame_size - new_h) // 2
            out_frame.paste(content, (paste_x, paste_y), content)
            
            frames.append(out_frame)
            print(f"    Frame {i+1}: center_x={center_x}, bbox={bbox}, size {cw}x{ch} → {new_w}x{new_h}")
        else:
            frames.append(Image.new('RGBA', (output_frame_size, output_frame_size), (0, 0, 0, 0)))
            print(f"    Frame {i+1}: no content")
    
    # Combine into spritesheet
    total_width = output_frame_size * len(frames)
    output = Image.new('RGBA', (total_width, output_frame_size), (0, 0, 0, 0))
    
    for i, frame in enumerate(frames):
        output.paste(frame, (i * output_frame_size, 0), frame)
    
    return output


def process_gemini_void_pulse(input_path: str, output_path: str):
    """
    Full pipeline for Gemini void pulse image.
    """
    print(f"\n{'='*60}")
    print("Processing Gemini Void Pulse (Color Detection)")
    print(f"{'='*60}")
    
    img = Image.open(input_path)
    print(f"Input: {img.width}x{img.height}")
    
    # Step 1: Detect vortexes by color
    print("\n[1] Detecting vortexes by color...")
    y_top, y_bottom, x_centers, content_mask = detect_vortexes_by_color(img)
    
    # Step 2: Create alpha channel
    print("\n[2] Creating alpha channel...")
    img_rgba = create_alpha_from_content(img, content_mask)
    
    # Save debug
    debug_dir = Path(output_path).parent
    debug_path = debug_dir / "void_pulse_alpha_debug.png"
    img_rgba.save(debug_path)
    print(f"    Debug saved: {debug_path}")
    
    # Step 3: Extract frames
    print("\n[3] Extracting frames...")
    output = extract_frames(img_rgba, y_top, y_bottom, x_centers, target_size=56, output_frame_size=64)
    
    # Save
    output.save(output_path)
    print(f"\n✅ Output: {output_path}")
    print(f"   Size: {output.width}x{output.height}")


if __name__ == '__main__':
    import sys
    if len(sys.argv) >= 3:
        process_gemini_void_pulse(sys.argv[1], sys.argv[2])
    else:
        print("Usage: python process_gemini_void_v2.py input.png output.png")
