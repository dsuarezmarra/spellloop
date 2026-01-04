#!/usr/bin/env python3
"""
Procesa spritesheets de Absolute Zero SIN PERDER CALIDAD.

En lugar de redimensionar (lo cual siempre pierde información),
este script:
1. Divide la imagen en frames SIN escalar
2. Recorta al contenido real
3. Centra el contenido en frames del tamaño necesario

Si el contenido es más grande que 64x64, se pueden usar frames más grandes
para mantener toda la calidad original.
"""

import numpy as np
from PIL import Image, ImageEnhance
from pathlib import Path
import os


def find_content_bounds(img: Image.Image, threshold: int = 10) -> tuple:
    """Encontrar los límites del contenido no transparente."""
    arr = np.array(img)
    alpha = arr[:, :, 3]
    
    rows = np.any(alpha > threshold, axis=1)
    cols = np.any(alpha > threshold, axis=0)
    
    if not np.any(rows) or not np.any(cols):
        return None
    
    y_indices = np.where(rows)[0]
    x_indices = np.where(cols)[0]
    
    return (x_indices[0], y_indices[0], x_indices[-1] + 1, y_indices[-1] + 1)


def find_frame_regions(img: Image.Image, num_frames: int = 6) -> list:
    """
    Encontrar las regiones de cada frame.
    Divide la imagen uniformemente en num_frames partes.
    """
    width = img.size[0]
    frame_width = width // num_frames
    
    regions = []
    for i in range(num_frames):
        x1 = i * frame_width
        x2 = (i + 1) * frame_width if i < num_frames - 1 else width
        regions.append((x1, x2))
    
    return regions


def process_absolute_zero_lossless(
    input_path: str,
    output_dir: str,
    num_frames: int = 6,
    output_frame_size: int = None,  # None = auto-detectar tamaño necesario
    force_size: int = None  # Forzar un tamaño específico (ej: 64, 128)
):
    """
    Procesa los sprites SIN pérdida de calidad.
    
    Si force_size se especifica, los frames tendrán ese tamaño.
    De lo contrario, se usa el tamaño mínimo necesario para contener todo el contenido.
    """
    print(f"\n{'='*60}")
    print("PROCESANDO ABSOLUTE ZERO - SIN PÉRDIDA")
    print(f"{'='*60}")
    
    # Cargar imagen
    img = Image.open(input_path).convert('RGBA')
    print(f"📷 Imagen fuente: {img.size[0]}x{img.size[1]}")
    
    # Encontrar límites verticales globales
    arr = np.array(img)
    alpha = arr[:, :, 3]
    rows = np.any(alpha > 10, axis=1)
    
    if np.any(rows):
        y_indices = np.where(rows)[0]
        y_min, y_max = y_indices[0], y_indices[-1] + 1
    else:
        y_min, y_max = 0, img.size[1]
    
    print(f"📐 Contenido vertical: y={y_min} a y={y_max} (altura={y_max-y_min}px)")
    
    # Encontrar regiones de frames
    regions = find_frame_regions(img, num_frames)
    
    # Primera pasada: determinar el tamaño máximo de contenido
    max_content_width = 0
    max_content_height = 0
    frame_contents = []
    
    for i, (x1, x2) in enumerate(regions):
        frame_region = img.crop((x1, y_min, x2, y_max))
        bbox = frame_region.getbbox()
        
        if bbox:
            content = frame_region.crop(bbox)
            frame_contents.append(content)
            max_content_width = max(max_content_width, content.width)
            max_content_height = max(max_content_height, content.height)
            print(f"   Frame {i+1}: contenido {content.width}x{content.height}")
        else:
            frame_contents.append(None)
            print(f"   Frame {i+1}: (vacío)")
    
    print(f"\n📊 Máximo contenido: {max_content_width}x{max_content_height}")
    
    # Determinar tamaño del frame de salida
    if force_size:
        frame_size = force_size
        print(f"⚙️ Tamaño forzado: {frame_size}x{frame_size}")
    else:
        # Usar el tamaño mínimo que contenga todo el contenido con padding
        padding = 4
        frame_size = max(max_content_width, max_content_height) + padding * 2
        # Redondear al múltiplo de 8 más cercano para compatibilidad
        frame_size = ((frame_size + 7) // 8) * 8
        print(f"⚙️ Tamaño auto-detectado: {frame_size}x{frame_size}")
    
    # Si el contenido es más grande que el frame, hay que escalar (con aviso)
    needs_scaling = max_content_width > frame_size or max_content_height > frame_size
    if needs_scaling:
        scale = min(frame_size / max_content_width, frame_size / max_content_height) * 0.9
        print(f"⚠️ AVISO: Contenido más grande que frame. Escala necesaria: {scale:.2%}")
    else:
        scale = 1.0
        print(f"✅ Sin escalado necesario (contenido cabe en {frame_size}x{frame_size})")
    
    # Segunda pasada: crear frames finales
    final_frames = []
    
    for i, content in enumerate(frame_contents):
        if content is None:
            final_frames.append(Image.new('RGBA', (frame_size, frame_size), (0, 0, 0, 0)))
            continue
        
        # Escalar si es necesario
        if needs_scaling:
            new_w = int(content.width * scale)
            new_h = int(content.height * scale)
            # Usar LANCZOS solo si es necesario
            content = content.resize((new_w, new_h), Image.Resampling.LANCZOS)
        
        # Crear frame y centrar contenido
        frame = Image.new('RGBA', (frame_size, frame_size), (0, 0, 0, 0))
        paste_x = (frame_size - content.width) // 2
        paste_y = (frame_size - content.height) // 2
        frame.paste(content, (paste_x, paste_y), content)
        
        final_frames.append(frame)
    
    # Crear directorio de salida
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    
    # Crear spritesheet
    spritesheet_width = frame_size * len(final_frames)
    spritesheet = Image.new('RGBA', (spritesheet_width, frame_size), (0, 0, 0, 0))
    
    for i, frame in enumerate(final_frames):
        spritesheet.paste(frame, (i * frame_size, 0), frame)
    
    # Guardar spritesheet activo
    active_path = output_path / 'aoe_active_absolute_zero.png'
    spritesheet.save(active_path, 'PNG', optimize=False)
    print(f"\n✅ Active: {active_path}")
    print(f"   Tamaño: {spritesheet_width}x{frame_size} ({len(final_frames)} frames de {frame_size}x{frame_size})")
    
    # Crear versión de impacto (más brillante)
    print("\n🔥 Creando versión de impacto...")
    impact = ImageEnhance.Brightness(spritesheet).enhance(1.3)
    impact = ImageEnhance.Color(impact).enhance(1.2)
    
    impact_path = output_path / 'aoe_impact_absolute_zero.png'
    impact.save(impact_path, 'PNG', optimize=False)
    print(f"✅ Impact: {impact_path}")
    
    # Guardar frames individuales
    frames_dir = output_path / 'frames'
    frames_dir.mkdir(exist_ok=True)
    
    for i, frame in enumerate(final_frames):
        frame_path = frames_dir / f'frame_{i+1}.png'
        frame.save(frame_path, 'PNG', optimize=False)
    
    print(f"\n📁 Frames individuales guardados en: {frames_dir}")
    
    # Mostrar estadísticas finales
    print(f"\n{'='*60}")
    print("RESUMEN")
    print(f"{'='*60}")
    print(f"Imagen original: {img.size[0]}x{img.size[1]}")
    print(f"Frames: {num_frames} de {frame_size}x{frame_size}")
    print(f"Spritesheet: {spritesheet_width}x{frame_size}")
    print(f"Escalado: {'SÍ ({:.1%})'.format(scale) if needs_scaling else 'NO (calidad 100%)'}")
    
    return frame_size


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Procesar Absolute Zero sin pérdida')
    parser.add_argument('--input', default=r'C:\git\spellloop\project\assets\sprites\projectiles\fusion\absolute_zero\unnamed-removebg-preview.png')
    parser.add_argument('--output', default=r'C:\git\spellloop\project\assets\sprites\projectiles\fusion\absolute_zero')
    parser.add_argument('--frames', type=int, default=6)
    parser.add_argument('--size', type=int, default=None, help='Forzar tamaño de frame (ej: 64, 128)')
    
    args = parser.parse_args()
    
    process_absolute_zero_lossless(
        args.input,
        args.output,
        num_frames=args.frames,
        force_size=args.size
    )


if __name__ == '__main__':
    main()
