#!/usr/bin/env python3
"""
process_arcanewastes_textures.py
Script maestro para procesar texturas de ArcaneWastes.

Estructura de entrada:
- base/1.png hasta base/8.png (8 frames de textura base seamless)
- decor/01.png hasta decor/08.png (Decor 1 - frames 1-8)
- decor/11.png hasta decor/18.png (Decor 2 - frames 11-18)
- decor/21.png hasta decor/28.png (Decor 3 - frames 21-28)
... hasta decor 11

Salida:
- base/arcanewastes_base_animated_sheet_f8_512.png (sprite sheet horizontal 512×512px por frame)
- decor/arcanewastes_decor1_sheet_f8_256.png (sprite sheet horizontal 256×256px por frame)
- decor/arcanewastes_decor2_sheet_f8_256.png ... hasta decor11
"""

from pathlib import Path
from PIL import Image
import sys

def remove_background(img, threshold=30):
    """Asegurar que el fondo es completamente transparente."""
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    pixels = img.load()
    width, height = img.size
    
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if a < threshold:
                pixels[x, y] = (0, 0, 0, 0)
            elif r < 20 and g < 20 and b < 20 and a < 150:
                pixels[x, y] = (0, 0, 0, 0)
    
    return img

def get_content_bbox(img):
    """Obtener el bounding box del contenido real."""
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    alpha = img.split()[3]
    bbox = alpha.getbbox()
    return bbox

def align_frame_to_canvas(img, target_size=256):
    """
    Alinear frame a un canvas cuadrado de tamaño objetivo.
    Centrado horizontalmente, alineado al fondo verticalmente.
    """
    img = remove_background(img)
    
    bbox = get_content_bbox(img)
    if not bbox:
        return Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))
    
    content = img.crop(bbox)
    orig_w, orig_h = content.size
    
    canvas = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))
    
    scale = min(target_size / orig_w, target_size / orig_h)
    new_w = int(orig_w * scale)
    new_h = int(orig_h * scale)
    
    resized = content.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    x_offset = (target_size - new_w) // 2
    y_offset = target_size - new_h
    
    canvas.paste(resized, (x_offset, y_offset), resized)
    
    return canvas

def process_base_texture(base_dir, biome_name="arcanewastes"):
    """
    Procesar frames de textura base (1.png hasta 8.png).
    Crear sprite sheet horizontal sin recorte ni alineación (seamless).
    """
    base_path = Path(base_dir)
    
    # Buscar frames numerados
    frames = []
    for i in range(1, 9):  # 1 a 8
        frame_path = base_path / f"{i}.png"
        if frame_path.exists():
            frames.append(frame_path)
        else:
            print(f"⚠️  Advertencia: Frame {i}.png no encontrado")
    
    if len(frames) == 0:
        print("❌ ERROR: No se encontraron frames de textura base")
        return None
    
    print(f"\n{'='*70}")
    print(f"PROCESANDO TEXTURA BASE DE {biome_name.upper()}")
    print(f"{'='*70}")
    print(f"Frames encontrados: {len(frames)}")
    print(f"{'─'*70}\n")
    
    # Crear sprite sheet
    frame_size = 512
    padding = 4
    num_frames = len(frames)
    
    processed_frames = []
    for i, frame_path in enumerate(frames):
        img = Image.open(frame_path)
        
        # Asegurar RGBA
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        # Redimensionar si es necesario
        if img.size != (frame_size, frame_size):
            print(f"  Frame {i+1}: {img.size} → Redimensionando a {frame_size}×{frame_size}px")
            img = img.resize((frame_size, frame_size), Image.Resampling.LANCZOS)
        else:
            print(f"  Frame {i+1}: {frame_size}×{frame_size}px ✓")
        
        processed_frames.append(img)
    
    # Crear sprite sheet horizontal
    total_width = (frame_size * num_frames) + (padding * (num_frames - 1))
    spritesheet = Image.new('RGBA', (total_width, frame_size), (0, 0, 0, 0))
    
    x = 0
    for frame in processed_frames:
        spritesheet.paste(frame, (x, 0), frame.split()[3] if frame.mode == 'RGBA' else None)
        x += frame_size + padding
    
    # Guardar
    output_name = f"{biome_name}_base_animated_sheet_f{num_frames}_{frame_size}.png"
    output_path = base_path / output_name
    spritesheet.save(output_path, 'PNG')
    
    print(f"\n✅ Creado: {output_name}")
    print(f"   Dimensiones: {spritesheet.size[0]}×{spritesheet.size[1]}px")
    print(f"{'='*70}\n")
    
    return output_path

def process_decor_textures(decor_dir, biome_name="arcanewastes"):
    """
    Procesar frames de decoraciones (01-08, 11-18, 21-28, ..., 101-108).
    Cada grupo de 8 frames forma un decor animado.
    """
    decor_path = Path(decor_dir)
    
    print(f"\n{'='*70}")
    print(f"PROCESANDO DECORACIONES DE {biome_name.upper()}")
    print(f"{'='*70}\n")
    
    # Detectar grupos de decor (01-08, 11-18, ..., 101-108)
    decor_groups = []
    for decor_num in range(0, 11):  # 0 a 10 (00-08, 11-18, ..., 101-108)
        prefix = f"{decor_num}"  # "0", "1", ..., "10"
        
        frames = []
        for i in range(1, 9):  # 1 a 8
            if decor_num == 0:
                frame_name = f"0{i}.png"  # 01, 02, ..., 08
            elif decor_num == 10:
                frame_name = f"10{i}.png"  # 101, 102, ..., 108
            else:
                frame_name = f"{decor_num}{i}.png"  # 11, 12, ..., 98
            
            frame_path = decor_path / frame_name
            if frame_path.exists():
                frames.append(frame_path)
        
        if len(frames) == 8:
            decor_groups.append((decor_num + 1, frames))  # Numerar desde 1
        elif len(frames) > 0:
            print(f"⚠️  Advertencia: Decor {decor_num + 1} tiene {len(frames)} frames (esperados: 8)")
    
    if len(decor_groups) == 0:
        print("❌ ERROR: No se encontraron grupos de decoraciones completos")
        return []
    
    print(f"Grupos de decor encontrados: {len(decor_groups)}")
    print(f"{'─'*70}\n")
    
    results = []
    frame_size = 256
    padding = 4
    
    for decor_num, frames in decor_groups:
        print(f"{'─'*70}")
        print(f"Procesando Decor {decor_num} ({len(frames)} frames)")
        print(f"{'─'*70}\n")
        
        # Procesar cada frame con alineación
        processed_frames = []
        for i, frame_path in enumerate(frames):
            img = Image.open(frame_path)
            
            orig_size = img.size
            
            # Alinear a canvas 256×256
            aligned = align_frame_to_canvas(img, frame_size)
            processed_frames.append(aligned)
            
            print(f"  Frame {i+1}: {orig_size[0]}×{orig_size[1]} → {frame_size}×{frame_size}px ✓")
        
        # Crear sprite sheet horizontal
        num_frames = len(processed_frames)
        total_width = (frame_size * num_frames) + (padding * (num_frames - 1))
        spritesheet = Image.new('RGBA', (total_width, frame_size), (0, 0, 0, 0))
        
        x = 0
        for frame in processed_frames:
            spritesheet.paste(frame, (x, 0), frame.split()[3])
            x += frame_size + padding
        
        # Guardar
        output_name = f"{biome_name}_decor{decor_num}_sheet_f{num_frames}_{frame_size}.png"
        output_path = decor_path / output_name
        spritesheet.save(output_path, 'PNG')
        
        print(f"\n✅ Creado: {output_name}")
        print(f"   Dimensiones: {spritesheet.size[0]}×{spritesheet.size[1]}px\n")
        
        results.append(output_name)
    
    print(f"{'='*70}")
    print(f"RESUMEN DECORACIONES")
    print(f"{'='*70}\n")
    
    for name in results:
        print(f"  ✓ {name}")
    
    print(f"\n{'='*70}\n")
    
    return results

def main():
    if len(sys.argv) < 2:
        print("USO: python process_arcanewastes_textures.py <directorio_bioma>")
        print("\nEjemplo:")
        print("  python process_arcanewastes_textures.py project/assets/textures/biomes/ArcaneWastes")
        sys.exit(1)
    
    biome_dir = Path(sys.argv[1])
    
    if not biome_dir.exists():
        print(f"❌ ERROR: Directorio no existe: {biome_dir}")
        sys.exit(1)
    
    base_dir = biome_dir / "base"
    decor_dir = biome_dir / "decor"
    
    if not base_dir.exists():
        print(f"❌ ERROR: Directorio base no existe: {base_dir}")
        sys.exit(1)
    
    if not decor_dir.exists():
        print(f"❌ ERROR: Directorio decor no existe: {decor_dir}")
        sys.exit(1)
    
    biome_name = biome_dir.name.lower()
    
    print(f"\n🎨 PROCESADOR DE TEXTURAS DE {biome_name.upper()}")
    print(f"{'='*70}\n")
    
    # Procesar textura base
    base_result = process_base_texture(base_dir, biome_name)
    
    # Procesar decoraciones
    decor_results = process_decor_textures(decor_dir, biome_name)
    
    print(f"\n{'='*70}")
    print(f"✅ PROCESAMIENTO COMPLETADO")
    print(f"{'='*70}")
    print(f"\nTextura base: {'✓' if base_result else '✗'}")
    print(f"Decoraciones: {len(decor_results)}/11")
    print(f"\n{'='*70}\n")

if __name__ == "__main__":
    main()
