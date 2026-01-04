#!/usr/bin/env python3
"""Procesa AOE sprites con estructura 1x6 (1 fila, 6 columnas)"""

from PIL import Image, ImageEnhance
import numpy as np

def process_1x6(path, name, output_base):
    img = Image.open(path).convert('RGBA')
    w, h = img.size
    
    print(f'=== {name} ({w}x{h}) ===')
    
    # 1 fila, 6 columnas
    cols = 6
    cell_w = w // cols
    
    frames = []
    centroids = []
    
    for col in range(cols):
        x1 = col * cell_w
        x2 = (col + 1) * cell_w if col < cols - 1 else w
        
        cell = img.crop((x1, 0, x2, h))
        cell_arr = np.array(cell)
        cell_alpha = cell_arr[:,:,3]
        
        # Bounding box
        rows_with = np.any(cell_alpha > 10, axis=1)
        cols_with = np.any(cell_alpha > 10, axis=0)
        
        if np.any(rows_with) and np.any(cols_with):
            cy1, cy2 = np.where(rows_with)[0][[0,-1]]
            cx1, cx2 = np.where(cols_with)[0][[0,-1]]
            content = cell.crop((cx1, cy1, cx2+1, cy2+1))
            
            # Centroide
            content_alpha = np.array(content)[:,:,3].astype(float) / 255.0
            ch, cw = content_alpha.shape
            y_coords, x_coords = np.meshgrid(np.arange(ch), np.arange(cw), indexing='ij')
            total = np.sum(content_alpha)
            cx = np.sum(x_coords * content_alpha) / total
            cy = np.sum(y_coords * content_alpha) / total
            
            frames.append(content)
            centroids.append((cx, cy))
            print(f'  Frame {col+1}: {content.size[0]}x{content.size[1]}, centroide=({cx:.1f}, {cy:.1f})')
    
    # Frame size basado en centroide
    max_left = max(c[0] for c in centroids)
    max_right = max(f.size[0] - c[0] for f, c in zip(frames, centroids))
    max_top = max(c[1] for c in centroids)
    max_bottom = max(f.size[1] - c[1] for f, c in zip(frames, centroids))
    
    frame_size = int(max(max_left + max_right, max_top + max_bottom)) + 16
    frame_size = ((frame_size + 7) // 8) * 8
    
    print(f'Frame size: {frame_size}x{frame_size}')
    
    center = frame_size // 2
    final_frames = []
    
    for content, (cx, cy) in zip(frames, centroids):
        frame = Image.new('RGBA', (frame_size, frame_size), (0,0,0,0))
        px = int(center - cx)
        py = int(center - cy)
        frame.paste(content, (px, py), content)
        final_frames.append(frame)
    
    sheet_w = frame_size * len(final_frames)
    sheet = Image.new('RGBA', (sheet_w, frame_size), (0,0,0,0))
    for i, f in enumerate(final_frames):
        sheet.paste(f, (i * frame_size, 0), f)
    
    sheet.save(f'{output_base}/aoe_active_{name}.png')
    
    impact = ImageEnhance.Brightness(sheet).enhance(1.3)
    impact = ImageEnhance.Color(impact).enhance(1.2)
    impact.save(f'{output_base}/aoe_impact_{name}.png')
    
    print(f'Spritesheet: {sheet_w}x{frame_size} ({len(final_frames)} frames)')
    scale = 64/frame_size
    print(f'sprite_scale: {scale:.2f}')
    return frame_size, round(scale, 2)


if __name__ == "__main__":
    results = {}
    
    fs, sc = process_1x6(
        r'C:\git\spellloop\project\assets\sprites\projectiles\weapons\void_pulse\unnamed-removebg-preview.png',
        'void_pulse',
        r'C:\git\spellloop\project\assets\sprites\projectiles\weapons\void_pulse'
    )
    results['void_pulse'] = (fs, sc)
    print()
    
    fs, sc = process_1x6(
        r'C:\git\spellloop\project\assets\sprites\projectiles\fusion\seismic_bolt\unnamed-removebg-preview.png',
        'seismic_bolt',
        r'C:\git\spellloop\project\assets\sprites\projectiles\fusion\seismic_bolt'
    )
    results['seismic_bolt'] = (fs, sc)
    print()
    
    fs, sc = process_1x6(
        r'C:\git\spellloop\project\assets\sprites\projectiles\fusion\glacier\unnamed-removebg-preview.png',
        'glacier',
        r'C:\git\spellloop\project\assets\sprites\projectiles\fusion\glacier'
    )
    results['glacier'] = (fs, sc)
    
    print()
    print('=== CONFIG PARA ProjectileVisualManager.gd ===')
    for name, (fs, sc) in results.items():
        print(f'"{name}": {{"frame_size": {fs}, "sprite_scale": {sc}}},')
