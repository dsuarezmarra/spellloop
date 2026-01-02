#!/usr/bin/env python3
"""
Remove background from AI-generated sprites while preserving semi-transparency.
Works best with solid or gradient backgrounds (gray, white, etc.)

Usage:
    python remove_background_preserve_alpha.py input.png output.png [--bg-color HEX] [--tolerance N]
    
Examples:
    python remove_background_preserve_alpha.py chatgpt_void.png void_clean.png
    python remove_background_preserve_alpha.py chatgpt_void.png void_clean.png --bg-color 808080
    python remove_background_preserve_alpha.py chatgpt_void.png void_clean.png --tolerance 40
"""

import numpy as np
from PIL import Image
import argparse
import sys
from pathlib import Path


def detect_background_color(img_array: np.ndarray) -> np.ndarray:
    """
    Detect background color by sampling corners and edges.
    Returns the most common color found in those regions.
    """
    h, w = img_array.shape[:2]
    
    # Sample regions: corners and edge centers
    sample_size = max(5, min(w, h) // 20)
    
    samples = []
    
    # Four corners
    corners = [
        (0, 0),  # top-left
        (0, w - sample_size),  # top-right
        (h - sample_size, 0),  # bottom-left
        (h - sample_size, w - sample_size),  # bottom-right
    ]
    
    for y, x in corners:
        region = img_array[y:y+sample_size, x:x+sample_size, :3]
        samples.extend(region.reshape(-1, 3).tolist())
    
    # Edge centers
    edge_samples = [
        (0, w//2 - sample_size//2),  # top center
        (h - sample_size, w//2 - sample_size//2),  # bottom center
        (h//2 - sample_size//2, 0),  # left center
        (h//2 - sample_size//2, w - sample_size),  # right center
    ]
    
    for y, x in edge_samples:
        region = img_array[y:y+sample_size, x:x+sample_size, :3]
        samples.extend(region.reshape(-1, 3).tolist())
    
    # Find median color (more robust than mean)
    samples = np.array(samples)
    bg_color = np.median(samples, axis=0).astype(np.uint8)
    
    print(f"  Detected background color: RGB({bg_color[0]}, {bg_color[1]}, {bg_color[2]}) = #{bg_color[0]:02X}{bg_color[1]:02X}{bg_color[2]:02X}")
    
    return bg_color


def remove_background_preserve_alpha(
    img: Image.Image,
    bg_color: np.ndarray = None,
    tolerance: int = 30,
    edge_softness: int = 10
) -> Image.Image:
    """
    Remove background while preserving semi-transparency at edges.
    
    Args:
        img: Input PIL Image
        bg_color: Background color as RGB array. If None, auto-detect.
        tolerance: Color difference threshold for considering a pixel as background
        edge_softness: How much to soften edges (gradient range)
    
    Returns:
        PIL Image with transparent background
    """
    # Convert to RGBA
    img = img.convert('RGBA')
    img_array = np.array(img, dtype=np.float32)
    
    # Auto-detect background if not provided
    if bg_color is None:
        bg_color = detect_background_color(img_array.astype(np.uint8))
    
    bg_color = np.array(bg_color, dtype=np.float32)
    
    # Calculate color distance from background for each pixel
    rgb = img_array[:, :, :3]
    
    # Use weighted Euclidean distance (human perception)
    weights = np.array([0.299, 0.587, 0.114])  # Luminance weights
    diff = rgb - bg_color
    weighted_diff = diff * np.sqrt(weights)
    color_distance = np.sqrt(np.sum(weighted_diff ** 2, axis=2))
    
    # Calculate alpha based on color distance
    # Pixels close to bg_color become transparent, distant pixels stay opaque
    alpha_from_distance = np.clip(
        (color_distance - tolerance) / edge_softness,
        0, 1
    )
    
    # Also consider original luminance/saturation
    # Brighter/more saturated pixels in the effect should stay more opaque
    luminance = np.sum(rgb * weights, axis=2)
    bg_luminance = np.sum(bg_color * weights)
    
    # For dark effects (like void), increase alpha for dark pixels
    # For bright effects, increase alpha for bright pixels
    avg_effect_luminance = np.mean(luminance[alpha_from_distance > 0.5])
    
    if avg_effect_luminance < bg_luminance:
        # Dark effect on lighter background
        luminance_factor = 1 - (luminance / 255)
    else:
        # Bright effect on darker background  
        luminance_factor = luminance / 255
    
    # Combine factors
    final_alpha = np.clip(alpha_from_distance * (0.5 + 0.5 * luminance_factor), 0, 1)
    
    # Apply saturation boost - more colorful pixels should be more opaque
    saturation = np.max(rgb, axis=2) - np.min(rgb, axis=2)
    saturation_factor = saturation / 255
    final_alpha = np.clip(final_alpha + saturation_factor * 0.3, 0, 1)
    
    # Create output image
    output = img_array.copy()
    output[:, :, 3] = final_alpha * 255
    
    # Optional: Premultiply alpha for better blending
    # output[:, :, :3] = output[:, :, :3] * (final_alpha[:, :, np.newaxis])
    
    return Image.fromarray(output.astype(np.uint8), 'RGBA')


def process_spritesheet(
    input_path: str,
    output_path: str,
    bg_color: np.ndarray = None,
    tolerance: int = 30,
    edge_softness: int = 10,
    frame_width: int = None,
    target_size: int = 56,
    output_frame_size: int = 64
) -> None:
    """
    Process a spritesheet: remove background and optionally resize frames.
    """
    print(f"\nProcessing: {input_path}")
    
    img = Image.open(input_path)
    print(f"  Input size: {img.width}x{img.height}")
    
    # Remove background
    clean_img = remove_background_preserve_alpha(
        img, bg_color, tolerance, edge_softness
    )
    
    # If frame_width specified, extract and resize frames
    if frame_width is not None:
        num_frames = img.width // frame_width
        print(f"  Detected {num_frames} frames @ {frame_width}px each")
        
        frames = []
        for i in range(num_frames):
            x = i * frame_width
            frame = clean_img.crop((x, 0, x + frame_width, clean_img.height))
            
            # Find content bounds
            bbox = frame.getbbox()
            if bbox:
                # Extract content with padding
                content = frame.crop(bbox)
                
                # Scale to target size while maintaining aspect ratio
                scale = min(target_size / content.width, target_size / content.height)
                new_size = (int(content.width * scale), int(content.height * scale))
                content = content.resize(new_size, Image.Resampling.LANCZOS)
                
                # Center in output frame
                output_frame = Image.new('RGBA', (output_frame_size, output_frame_size), (0, 0, 0, 0))
                paste_x = (output_frame_size - content.width) // 2
                paste_y = (output_frame_size - content.height) // 2
                output_frame.paste(content, (paste_x, paste_y))
                frames.append(output_frame)
            else:
                frames.append(Image.new('RGBA', (output_frame_size, output_frame_size), (0, 0, 0, 0)))
        
        # Combine frames
        total_width = output_frame_size * len(frames)
        output = Image.new('RGBA', (total_width, output_frame_size), (0, 0, 0, 0))
        for i, frame in enumerate(frames):
            output.paste(frame, (i * output_frame_size, 0))
        
        print(f"  Output: {len(frames)} frames @ {output_frame_size}x{output_frame_size}")
    else:
        output = clean_img
    
    # Save
    output.save(output_path)
    print(f"  Saved: {output_path}")


def hex_to_rgb(hex_color: str) -> np.ndarray:
    """Convert hex color string to RGB array."""
    hex_color = hex_color.lstrip('#')
    return np.array([int(hex_color[i:i+2], 16) for i in (0, 2, 4)])


def main():
    parser = argparse.ArgumentParser(
        description='Remove background from sprites while preserving semi-transparency'
    )
    parser.add_argument('input', help='Input image path')
    parser.add_argument('output', help='Output image path')
    parser.add_argument('--bg-color', type=str, default=None,
                        help='Background color in hex (e.g., 808080). Auto-detect if not specified.')
    parser.add_argument('--tolerance', type=int, default=30,
                        help='Color tolerance for background detection (default: 30)')
    parser.add_argument('--softness', type=int, default=15,
                        help='Edge softness/gradient range (default: 15)')
    parser.add_argument('--frame-width', type=int, default=None,
                        help='Frame width if processing spritesheet (auto-detects frames)')
    parser.add_argument('--target-size', type=int, default=56,
                        help='Target content size within frame (default: 56)')
    parser.add_argument('--output-frame-size', type=int, default=64,
                        help='Output frame size (default: 64)')
    
    args = parser.parse_args()
    
    bg_color = None
    if args.bg_color:
        bg_color = hex_to_rgb(args.bg_color)
        print(f"Using specified background color: #{args.bg_color}")
    
    process_spritesheet(
        args.input,
        args.output,
        bg_color=bg_color,
        tolerance=args.tolerance,
        edge_softness=args.softness,
        frame_width=args.frame_width,
        target_size=args.target_size,
        output_frame_size=args.output_frame_size
    )
    
    print("\nDone!")


if __name__ == '__main__':
    main()
