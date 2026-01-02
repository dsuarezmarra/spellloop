#!/usr/bin/env python3
"""
Process Gemini-generated sprites with simulated checkered transparency background.
Removes the checkered pattern and watermark, outputs real transparency.

Usage:
    python process_gemini_checkered.py input.png output.png [--frames N] [--target-size N]
"""

import numpy as np
from PIL import Image
import argparse
from pathlib import Path


def detect_checkered_colors(img_array: np.ndarray) -> tuple:
    """
    Detect the two colors used in the checkered pattern.
    Usually light gray and darker gray.
    """
    h, w = img_array.shape[:2]
    
    # Sample corners where checkered pattern is most visible
    sample_size = min(30, w // 10)
    
    # Top-left corner
    corner = img_array[0:sample_size, 0:sample_size, :3]
    
    # Get unique colors (approximately)
    pixels = corner.reshape(-1, 3)
    
    # Find the two most common colors in the corner (checkered pattern)
    # Round to reduce noise
    rounded = (pixels // 10) * 10
    unique, counts = np.unique(rounded, axis=0, return_counts=True)
    
    # Get top 2 most common
    top_indices = np.argsort(counts)[-2:]
    color1 = unique[top_indices[0]]
    color2 = unique[top_indices[1]]
    
    print(f"  Checkered colors detected:")
    print(f"    Color 1: RGB({color1[0]}, {color1[1]}, {color1[2]})")
    print(f"    Color 2: RGB({color2[0]}, {color2[1]}, {color2[2]})")
    
    return color1, color2


def is_checkered_pixel(pixel: np.ndarray, color1: np.ndarray, color2: np.ndarray, tolerance: int = 25) -> bool:
    """Check if a pixel matches either checkered color."""
    diff1 = np.abs(pixel[:3].astype(int) - color1.astype(int))
    diff2 = np.abs(pixel[:3].astype(int) - color2.astype(int))
    
    return np.all(diff1 < tolerance) or np.all(diff2 < tolerance)


def remove_checkered_background(img: Image.Image, tolerance: int = 30) -> Image.Image:
    """
    Remove checkered transparency simulation and create real transparency.
    """
    img_array = np.array(img.convert('RGBA'), dtype=np.float32)
    h, w = img_array.shape[:2]
    
    # Detect checkered pattern colors
    color1, color2 = detect_checkered_colors(img_array.astype(np.uint8))
    
    # Calculate average checkered color for edge blending
    avg_checkered = (color1.astype(float) + color2.astype(float)) / 2
    
    # Create output with alpha channel
    output = img_array.copy()
    
    # For each pixel, determine if it's background or content
    rgb = img_array[:, :, :3]
    
    # Calculate distance from both checkered colors
    diff1 = np.abs(rgb - color1.astype(float))
    diff2 = np.abs(rgb - color2.astype(float))
    
    dist1 = np.max(diff1, axis=2)  # Max channel difference
    dist2 = np.max(diff2, axis=2)
    
    # Minimum distance to either checkered color
    min_dist = np.minimum(dist1, dist2)
    
    # Calculate alpha: 0 for checkered, 1 for content, gradient for edges
    # Pixels very close to checkered colors become transparent
    # Pixels far from checkered colors stay opaque
    alpha = np.clip((min_dist - tolerance * 0.5) / (tolerance * 0.5), 0, 1)
    
    # Additional check: look at saturation
    # Checkered pattern is grayscale, content usually has color
    max_rgb = np.max(rgb, axis=2)
    min_rgb = np.min(rgb, axis=2)
    saturation = (max_rgb - min_rgb) / (max_rgb + 1)  # +1 to avoid division by zero
    
    # Boost alpha for saturated pixels (they're definitely content)
    alpha = np.clip(alpha + saturation * 0.5, 0, 1)
    
    # Also check brightness difference from checkered
    # The vortex has very dark and very bright parts
    luminance = 0.299 * rgb[:,:,0] + 0.587 * rgb[:,:,1] + 0.114 * rgb[:,:,2]
    avg_check_lum = 0.299 * avg_checkered[0] + 0.587 * avg_checkered[1] + 0.114 * avg_checkered[2]
    
    lum_diff = np.abs(luminance - avg_check_lum) / 255
    alpha = np.clip(alpha + lum_diff * 0.3, 0, 1)
    
    output[:, :, 3] = alpha * 255
    
    return Image.fromarray(output.astype(np.uint8), 'RGBA')


def remove_watermark(img: Image.Image, corner_size: int = 60) -> Image.Image:
    """
    Remove watermark from bottom-right corner by making it transparent.
    """
    img_array = np.array(img)
    h, w = img_array.shape[:2]
    
    # Check bottom-right corner for watermark
    # Make that area transparent
    corner = img_array[h-corner_size:h, w-corner_size:w]
    
    # Detect if there's a watermark (usually lighter/different from content)
    # For now, just make the corner more transparent if it looks like a watermark
    
    # Check if corner has low-saturation content (watermark is usually gray/white)
    corner_rgb = corner[:, :, :3].astype(float)
    saturation = (np.max(corner_rgb, axis=2) - np.min(corner_rgb, axis=2)) / (np.max(corner_rgb, axis=2) + 1)
    
    # If mostly low saturation, it's likely a watermark - reduce alpha
    low_sat_mask = saturation < 0.2
    
    # Apply to main image
    img_array[h-corner_size:h, w-corner_size:w, 3] = np.where(
        low_sat_mask,
        img_array[h-corner_size:h, w-corner_size:w, 3] * 0.0,  # Make watermark transparent
        img_array[h-corner_size:h, w-corner_size:w, 3]
    )
    
    return Image.fromarray(img_array, 'RGBA')


def find_frame_centers(img: Image.Image, num_frames: int = 6) -> list:
    """
    Find the center of each frame by analyzing content density.
    """
    img_array = np.array(img)
    h, w = img_array.shape[:2]
    
    # Get alpha channel (or create from content)
    if img_array.shape[2] == 4:
        alpha = img_array[:, :, 3]
    else:
        # Use luminance variance as proxy for content
        gray = np.mean(img_array[:, :, :3], axis=2)
        alpha = np.abs(gray - np.mean(gray)) * 2
    
    # Sum alpha vertically to get horizontal density profile
    density = np.sum(alpha, axis=0)
    
    # Smooth the density
    kernel_size = w // 50
    kernel = np.ones(kernel_size) / kernel_size
    smoothed = np.convolve(density, kernel, mode='same')
    
    # Find peaks (frame centers)
    # First, find valleys to separate frames
    expected_frame_width = w // num_frames
    
    centers = []
    for i in range(num_frames):
        # Search region for this frame
        start = int(i * expected_frame_width)
        end = int((i + 1) * expected_frame_width)
        
        # Find peak (center of content) in this region
        region = smoothed[start:end]
        peak_local = np.argmax(region)
        center = start + peak_local
        centers.append(center)
    
    print(f"  Frame centers detected at: {centers}")
    return centers


def extract_frames(
    img: Image.Image,
    num_frames: int = 6,
    target_size: int = 56,
    output_frame_size: int = 64
) -> Image.Image:
    """
    Extract and normalize frames from the spritesheet.
    """
    w, h = img.size
    
    # Calculate frame width based on image width
    frame_width = w // num_frames
    print(f"  Image size: {w}x{h}, extracting {num_frames} frames @ ~{frame_width}px each")
    
    frames = []
    
    for i in range(num_frames):
        # Extract frame region
        x1 = i * frame_width
        x2 = (i + 1) * frame_width
        
        frame = img.crop((x1, 0, x2, h))
        
        # Find actual content bounds
        bbox = frame.getbbox()
        
        if bbox:
            # Add small padding to bbox
            pad = 2
            x1_c = max(0, bbox[0] - pad)
            y1_c = max(0, bbox[1] - pad)
            x2_c = min(frame.width, bbox[2] + pad)
            y2_c = min(frame.height, bbox[3] + pad)
            
            content = frame.crop((x1_c, y1_c, x2_c, y2_c))
            
            # Scale to target size maintaining aspect ratio
            content_w, content_h = content.size
            scale = min(target_size / content_w, target_size / content_h)
            new_w = int(content_w * scale)
            new_h = int(content_h * scale)
            
            content = content.resize((new_w, new_h), Image.Resampling.LANCZOS)
            
            # Center in output frame
            output_frame = Image.new('RGBA', (output_frame_size, output_frame_size), (0, 0, 0, 0))
            paste_x = (output_frame_size - new_w) // 2
            paste_y = (output_frame_size - new_h) // 2
            output_frame.paste(content, (paste_x, paste_y), content)
            
            frames.append(output_frame)
            print(f"    Frame {i+1}: content {content_w}x{content_h} → {new_w}x{new_h}")
        else:
            print(f"    Frame {i+1}: empty!")
            frames.append(Image.new('RGBA', (output_frame_size, output_frame_size), (0, 0, 0, 0)))
    
    # Combine into spritesheet
    total_width = output_frame_size * num_frames
    output = Image.new('RGBA', (total_width, output_frame_size), (0, 0, 0, 0))
    
    for i, frame in enumerate(frames):
        output.paste(frame, (i * output_frame_size, 0))
    
    return output


def process_gemini_sprite(
    input_path: str,
    output_path: str,
    num_frames: int = 6,
    target_size: int = 56,
    output_frame_size: int = 64,
    tolerance: int = 30
) -> None:
    """
    Full pipeline: remove checkered bg, remove watermark, extract frames.
    """
    print(f"\n{'='*60}")
    print(f"Processing Gemini sprite: {input_path}")
    print(f"{'='*60}")
    
    # Load image
    img = Image.open(input_path)
    print(f"  Input size: {img.width}x{img.height}, mode: {img.mode}")
    
    # Step 1: Remove checkered background
    print("\n[Step 1] Removing checkered background...")
    img_clean = remove_checkered_background(img, tolerance=tolerance)
    
    # Step 2: Remove watermark
    print("\n[Step 2] Removing watermark...")
    img_clean = remove_watermark(img_clean, corner_size=50)
    
    # Step 3: Extract and normalize frames
    print(f"\n[Step 3] Extracting {num_frames} frames...")
    output = extract_frames(
        img_clean,
        num_frames=num_frames,
        target_size=target_size,
        output_frame_size=output_frame_size
    )
    
    # Save
    output.save(output_path)
    print(f"\n✅ Saved: {output_path}")
    print(f"   Final size: {output.width}x{output.height}")
    
    # Also save intermediate for debugging
    debug_path = Path(output_path).parent / f"{Path(output_path).stem}_debug_nobg.png"
    img_clean.save(debug_path)
    print(f"   Debug (no bg): {debug_path}")


def main():
    parser = argparse.ArgumentParser(
        description='Process Gemini sprites with checkered background'
    )
    parser.add_argument('input', help='Input image path')
    parser.add_argument('output', help='Output image path')
    parser.add_argument('--frames', type=int, default=6,
                        help='Number of frames in spritesheet (default: 6)')
    parser.add_argument('--target-size', type=int, default=56,
                        help='Target content size within frame (default: 56)')
    parser.add_argument('--frame-size', type=int, default=64,
                        help='Output frame size (default: 64)')
    parser.add_argument('--tolerance', type=int, default=30,
                        help='Color tolerance for background detection (default: 30)')
    
    args = parser.parse_args()
    
    process_gemini_sprite(
        args.input,
        args.output,
        num_frames=args.frames,
        target_size=args.target_size,
        output_frame_size=args.frame_size,
        tolerance=args.tolerance
    )


if __name__ == '__main__':
    main()
