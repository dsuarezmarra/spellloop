#!/usr/bin/env python3
"""
Redimensionador de alta calidad para spritesheets.
Usa técnicas avanzadas para minimizar la pérdida de calidad al reducir imágenes.

Técnicas usadas:
1. Redimensionado gradual por pasos (evita artifacts de redimensionado grande)
2. Sharpening adaptativo post-resize
3. Preservación de saturación y contraste
4. Super-sampling anti-aliasing

Usage:
    python resize_high_quality.py input.png output.png --target-size 64
"""

import numpy as np
from PIL import Image, ImageEnhance, ImageFilter
import argparse
import os
from pathlib import Path


def resize_step_by_step(img: Image.Image, target_size: tuple, steps: int = None) -> Image.Image:
    """
    Redimensiona la imagen gradualmente en pasos para preservar calidad.
    En lugar de reducir de 400px a 60px de golpe, hace 400->200->100->60
    """
    current = img.copy()
    current_size = max(img.size)
    target = max(target_size)
    
    if current_size <= target:
        # No necesitamos reducir, solo ajustar
        return img.resize(target_size, Image.Resampling.LANCZOS)
    
    # Calcular número de pasos si no se especifica
    if steps is None:
        ratio = current_size / target
        # Un paso por cada reducción del 50% aproximadamente
        steps = max(1, int(np.log2(ratio)))
    
    # Calcular tamaños intermedios
    sizes = []
    for i in range(steps):
        factor = (target / current_size) ** ((i + 1) / steps)
        intermediate_size = int(current_size * factor)
        sizes.append(intermediate_size)
    
    # Aplicar redimensionado gradual
    w, h = img.size
    aspect = w / h
    
    for i, size in enumerate(sizes):
        if aspect >= 1:
            new_w = size
            new_h = int(size / aspect)
        else:
            new_h = size
            new_w = int(size * aspect)
        
        # Usar LANCZOS que es el mejor para downscaling general
        current = current.resize((max(1, new_w), max(1, new_h)), Image.Resampling.LANCZOS)
    
    # Ajuste final al tamaño exacto
    return current.resize(target_size, Image.Resampling.LANCZOS)


def apply_adaptive_sharpening(img: Image.Image, amount: float = 1.0) -> Image.Image:
    """
    Aplica sharpening adaptativo que mejora bordes sin amplificar ruido.
    """
    if amount <= 0:
        return img
    
    # Crear máscara de bordes para sharpen selectivo
    # Convertir a escala de grises para detectar bordes
    if img.mode == 'RGBA':
        rgb = img.convert('RGB')
        alpha = img.split()[3]
    else:
        rgb = img.convert('RGB')
        alpha = None
    
    # Aplicar unsharp mask (más controlable que sharpen simple)
    # Radius pequeño = sharpen detalles finos
    sharpened = rgb.filter(ImageFilter.UnsharpMask(radius=0.5, percent=int(100 * amount), threshold=1))
    
    if alpha:
        # Reconstruir RGBA
        r, g, b = sharpened.split()
        return Image.merge('RGBA', (r, g, b, alpha))
    
    return sharpened


def enhance_colors(img: Image.Image, saturation: float = 1.1, contrast: float = 1.05) -> Image.Image:
    """
    Mejora saturación y contraste que se pierden al redimensionar.
    """
    if img.mode == 'RGBA':
        rgb = img.convert('RGB')
        alpha = img.split()[3]
    else:
        rgb = img.convert('RGB')
        alpha = None
    
    # Boost saturación
    if saturation != 1.0:
        enhancer = ImageEnhance.Color(rgb)
        rgb = enhancer.enhance(saturation)
    
    # Boost contraste
    if contrast != 1.0:
        enhancer = ImageEnhance.Contrast(rgb)
        rgb = enhancer.enhance(contrast)
    
    if alpha:
        r, g, b = rgb.split()
        return Image.merge('RGBA', (r, g, b, alpha))
    
    return rgb


def super_sample_resize(img: Image.Image, target_size: tuple, scale_factor: int = 2) -> Image.Image:
    """
    Super-sampling: primero escala a un tamaño mayor, luego reduce al target.
    Esto puede mejorar el anti-aliasing y suavizar bordes.
    """
    # Escalar a tamaño intermedio mayor
    intermediate_size = (target_size[0] * scale_factor, target_size[1] * scale_factor)
    
    # Si la imagen original ya es más pequeña que el intermedio, usar directamente
    if img.size[0] <= intermediate_size[0] and img.size[1] <= intermediate_size[1]:
        intermediate = img.resize(intermediate_size, Image.Resampling.LANCZOS)
    else:
        intermediate = resize_step_by_step(img, intermediate_size)
    
    # Reducir al tamaño final con box filter (promedia píxeles)
    return intermediate.resize(target_size, Image.Resampling.BOX)


def resize_high_quality(
    img: Image.Image, 
    target_size: tuple,
    method: str = 'stepped',
    sharpen: float = 0.8,
    saturation_boost: float = 1.1,
    contrast_boost: float = 1.05
) -> Image.Image:
    """
    Redimensiona una imagen con la máxima calidad posible.
    
    Args:
        img: Imagen PIL de entrada
        target_size: Tupla (ancho, alto) del tamaño objetivo
        method: 'stepped' (gradual), 'supersample', 'lanczos' (directo)
        sharpen: Cantidad de sharpening (0 = ninguno, 1 = normal, 2 = fuerte)
        saturation_boost: Multiplicador de saturación (1.0 = sin cambio)
        contrast_boost: Multiplicador de contraste (1.0 = sin cambio)
    
    Returns:
        Imagen redimensionada con alta calidad
    """
    # Asegurar RGBA
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    # Aplicar método de redimensionado
    if method == 'stepped':
        resized = resize_step_by_step(img, target_size)
    elif method == 'supersample':
        resized = super_sample_resize(img, target_size)
    elif method == 'lanczos':
        resized = img.resize(target_size, Image.Resampling.LANCZOS)
    else:
        resized = resize_step_by_step(img, target_size)  # default
    
    # Aplicar mejoras de post-proceso
    if sharpen > 0:
        resized = apply_adaptive_sharpening(resized, sharpen)
    
    if saturation_boost != 1.0 or contrast_boost != 1.0:
        resized = enhance_colors(resized, saturation_boost, contrast_boost)
    
    return resized


def find_content_bounds(img: Image.Image, threshold: int = 10) -> tuple:
    """
    Encuentra los límites del contenido no transparente.
    """
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    pixels = np.array(img)
    alpha = pixels[:, :, 3]
    
    # Encontrar filas y columnas con contenido
    rows_with_content = np.any(alpha > threshold, axis=1)
    cols_with_content = np.any(alpha > threshold, axis=0)
    
    if not np.any(rows_with_content) or not np.any(cols_with_content):
        return None
    
    y_indices = np.where(rows_with_content)[0]
    x_indices = np.where(cols_with_content)[0]
    
    return (x_indices[0], y_indices[0], x_indices[-1] + 1, y_indices[-1] + 1)


def process_frame_high_quality(
    frame: Image.Image,
    target_content_size: int = 56,
    output_frame_size: int = 64,
    method: str = 'stepped',
    sharpen: float = 0.8,
    saturation_boost: float = 1.1,
    contrast_boost: float = 1.05
) -> Image.Image:
    """
    Procesa un frame individual: recorta al contenido, redimensiona con alta calidad, centra.
    """
    # Encontrar bounds del contenido
    bbox = find_content_bounds(frame)
    
    if bbox is None:
        # Frame vacío
        return Image.new('RGBA', (output_frame_size, output_frame_size), (0, 0, 0, 0))
    
    # Extraer contenido
    content = frame.crop(bbox)
    content_w, content_h = content.size
    
    # Calcular escala manteniendo aspecto
    scale = min(target_content_size / content_w, target_content_size / content_h)
    new_w = max(1, int(content_w * scale))
    new_h = max(1, int(content_h * scale))
    
    # Redimensionar con alta calidad
    resized = resize_high_quality(
        content,
        (new_w, new_h),
        method=method,
        sharpen=sharpen,
        saturation_boost=saturation_boost,
        contrast_boost=contrast_boost
    )
    
    # Centrar en canvas de salida
    output = Image.new('RGBA', (output_frame_size, output_frame_size), (0, 0, 0, 0))
    paste_x = (output_frame_size - new_w) // 2
    paste_y = (output_frame_size - new_h) // 2
    output.paste(resized, (paste_x, paste_y), resized)
    
    return output


def find_frame_boundaries(img: Image.Image, expected_frames: int = 6) -> list:
    """
    Detecta los límites de cada frame en un spritesheet horizontal.
    """
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    pixels = np.array(img)
    alpha = pixels[:, :, 3]
    
    # Buscar columnas con contenido
    cols_with_content = np.any(alpha > 10, axis=0)
    
    # Encontrar grupos de columnas con contenido
    frames = []
    in_frame = False
    frame_start = 0
    
    for x, has_content in enumerate(cols_with_content):
        if has_content and not in_frame:
            in_frame = True
            frame_start = x
        elif not has_content and in_frame:
            in_frame = False
            frames.append((frame_start, x))
    
    if in_frame:
        frames.append((frame_start, img.size[0]))
    
    # Si no detectamos el número esperado, dividir uniformemente
    if len(frames) != expected_frames:
        frame_width = img.size[0] // expected_frames
        frames = [(i * frame_width, (i + 1) * frame_width) for i in range(expected_frames)]
    
    return frames


def process_spritesheet_high_quality(
    input_path: str,
    output_path: str,
    num_frames: int = 6,
    target_content_size: int = 56,
    output_frame_size: int = 64,
    method: str = 'stepped',
    sharpen: float = 0.8,
    saturation_boost: float = 1.1,
    contrast_boost: float = 1.05,
    save_individual_frames: bool = True
) -> None:
    """
    Procesa un spritesheet completo con alta calidad.
    """
    print(f"\n{'='*60}")
    print(f"PROCESANDO CON ALTA CALIDAD: {Path(input_path).name}")
    print(f"{'='*60}")
    
    # Cargar imagen
    img = Image.open(input_path).convert('RGBA')
    print(f"📷 Imagen original: {img.size[0]}x{img.size[1]}")
    
    # Detectar frames
    frame_bounds = find_frame_boundaries(img, num_frames)
    print(f"🎞️ Frames detectados: {len(frame_bounds)}")
    
    # Encontrar límites verticales globales
    pixels = np.array(img)
    alpha = pixels[:, :, 3]
    rows_with_content = np.any(alpha > 10, axis=1)
    
    if np.any(rows_with_content):
        y_indices = np.where(rows_with_content)[0]
        y_min, y_max = y_indices[0], y_indices[-1] + 1
    else:
        y_min, y_max = 0, img.size[1]
    
    print(f"📐 Límites verticales: y={y_min}-{y_max}")
    print(f"\n⚙️ Configuración:")
    print(f"   Método: {method}")
    print(f"   Sharpen: {sharpen}")
    print(f"   Boost saturación: {saturation_boost}")
    print(f"   Boost contraste: {contrast_boost}")
    print(f"   Tamaño contenido: {target_content_size}px")
    print(f"   Tamaño frame: {output_frame_size}px")
    
    # Procesar cada frame
    processed_frames = []
    
    for i, (x1, x2) in enumerate(frame_bounds):
        frame = img.crop((x1, y_min, x2, y_max))
        
        processed = process_frame_high_quality(
            frame,
            target_content_size=target_content_size,
            output_frame_size=output_frame_size,
            method=method,
            sharpen=sharpen,
            saturation_boost=saturation_boost,
            contrast_boost=contrast_boost
        )
        
        processed_frames.append(processed)
        
        # Info del frame
        bbox = find_content_bounds(frame)
        if bbox:
            orig_w = bbox[2] - bbox[0]
            orig_h = bbox[3] - bbox[1]
            print(f"   Frame {i+1}: {orig_w}x{orig_h} → {output_frame_size}x{output_frame_size}")
        else:
            print(f"   Frame {i+1}: (vacío)")
    
    # Crear spritesheet
    spritesheet_width = output_frame_size * len(processed_frames)
    spritesheet = Image.new('RGBA', (spritesheet_width, output_frame_size), (0, 0, 0, 0))
    
    for i, frame in enumerate(processed_frames):
        spritesheet.paste(frame, (i * output_frame_size, 0), frame)
    
    # Guardar spritesheet
    spritesheet.save(output_path, 'PNG', optimize=False)
    print(f"\n✅ Spritesheet guardado: {output_path}")
    print(f"   Tamaño: {spritesheet_width}x{output_frame_size}")
    
    # Guardar frames individuales
    if save_individual_frames:
        output_dir = Path(output_path).parent / 'frames'
        output_dir.mkdir(exist_ok=True)
        
        for i, frame in enumerate(processed_frames):
            frame_path = output_dir / f'frame_{i+1}.png'
            frame.save(frame_path, 'PNG', optimize=False)
        
        print(f"   Frames individuales: {output_dir}")


def create_impact_version(spritesheet: Image.Image, brightness: float = 1.3, color_boost: float = 1.2) -> Image.Image:
    """
    Crea una versión de impacto más brillante del spritesheet.
    """
    impact = spritesheet.copy()
    
    # Aumentar brillo
    if brightness != 1.0:
        impact = ImageEnhance.Brightness(impact).enhance(brightness)
    
    # Aumentar saturación/color
    if color_boost != 1.0:
        impact = ImageEnhance.Color(impact).enhance(color_boost)
    
    return impact


def main():
    parser = argparse.ArgumentParser(
        description='Redimensionador de alta calidad para spritesheets'
    )
    parser.add_argument('input', help='Imagen de entrada')
    parser.add_argument('output', help='Imagen de salida')
    parser.add_argument('--frames', type=int, default=6,
                        help='Número de frames esperados (default: 6)')
    parser.add_argument('--target-size', type=int, default=56,
                        help='Tamaño del contenido dentro del frame (default: 56)')
    parser.add_argument('--frame-size', type=int, default=64,
                        help='Tamaño del frame de salida (default: 64)')
    parser.add_argument('--method', choices=['stepped', 'supersample', 'lanczos'],
                        default='stepped',
                        help='Método de redimensionado (default: stepped)')
    parser.add_argument('--sharpen', type=float, default=0.8,
                        help='Cantidad de sharpening 0-2 (default: 0.8)')
    parser.add_argument('--saturation', type=float, default=1.1,
                        help='Boost de saturación (default: 1.1)')
    parser.add_argument('--contrast', type=float, default=1.05,
                        help='Boost de contraste (default: 1.05)')
    parser.add_argument('--no-individual-frames', action='store_true',
                        help='No guardar frames individuales')
    parser.add_argument('--create-impact', action='store_true',
                        help='También crear versión de impacto (más brillante)')
    parser.add_argument('--impact-brightness', type=float, default=1.3,
                        help='Brillo de la versión de impacto (default: 1.3)')
    
    args = parser.parse_args()
    
    process_spritesheet_high_quality(
        args.input,
        args.output,
        num_frames=args.frames,
        target_content_size=args.target_size,
        output_frame_size=args.frame_size,
        method=args.method,
        sharpen=args.sharpen,
        saturation_boost=args.saturation,
        contrast_boost=args.contrast,
        save_individual_frames=not args.no_individual_frames
    )
    
    # Crear versión de impacto si se solicita
    if args.create_impact:
        output_path = Path(args.output)
        impact_path = output_path.parent / output_path.name.replace('active', 'impact').replace('_hq', '_impact_hq')
        if 'impact' not in str(impact_path):
            impact_path = output_path.parent / f"impact_{output_path.name}"
        
        print(f"\n🔥 Creando versión de impacto...")
        spritesheet = Image.open(args.output)
        impact = create_impact_version(spritesheet, args.impact_brightness, 1.2)
        impact.save(impact_path, 'PNG')
        print(f"✅ Impacto guardado: {impact_path}")


if __name__ == '__main__':
    main()
