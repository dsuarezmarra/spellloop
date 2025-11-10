#!/usr/bin/env python3
"""
fix_spritesheet_advanced.py
Algoritmo avanzado que detecta frames por centro de masa y clustering.
"""

import sys
from pathlib import Path
from PIL import Image
import numpy as np
from scipy import ndimage
from collections import defaultdict

def analyze_content_distribution(img):
    """
    Analizar la distribución horizontal del contenido usando centro de masa.
    """
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    alpha = np.array(img.split()[3])
    width, height = img.size
    
    # Calcular densidad de contenido por columna
    column_density = np.sum(alpha > 30, axis=0)  # Threshold para contenido visible
    
    return column_density

def detect_frame_centers(column_density, expected_frames, width):
    """
    Detectar los centros de cada frame usando análisis de picos de densidad.
    """
    from scipy.signal import find_peaks
    
    # Suavizar la señal para eliminar ruido
    from scipy.ndimage import gaussian_filter1d
    smoothed = gaussian_filter1d(column_density, sigma=5)
    
    # Encontrar picos (centros de frames)
    peaks, properties = find_peaks(smoothed, distance=width//(expected_frames*2), prominence=np.max(smoothed)*0.1)
    
    print(f"  🎯 Picos detectados: {len(peaks)}")
    
    if len(peaks) == expected_frames:
        return peaks
    
    # Si no coincide, dividir uniformemente basándose en la distribución
    # Encontrar el rango de contenido
    content_start = np.argmax(column_density > 0)
    content_end = len(column_density) - np.argmax(column_density[::-1] > 0)
    content_width = content_end - content_start
    
    # Dividir uniformemente el espacio de contenido
    frame_spacing = content_width / expected_frames
    centers = [int(content_start + frame_spacing * (i + 0.5)) for i in range(expected_frames)]
    
    print(f"  📏 Usando división uniforme del contenido")
    print(f"     Contenido: {content_start} → {content_end} ({content_width}px)")
    print(f"     Espaciado: {frame_spacing:.1f}px por frame")
    
    return centers

def extract_frame_at_center(img, center_x, frame_width):
    """
    Extraer un frame centrado en center_x con un ancho dado.
    """
    width, height = img.size
    
    # Calcular límites del frame
    left = max(0, int(center_x - frame_width / 2))
    right = min(width, int(center_x + frame_width / 2))
    
    # Extraer frame
    frame = img.crop((left, 0, right, height))
    
    # Recortar contenido (eliminar espacio vacío vertical y horizontal)
    if frame.mode != 'RGBA':
        frame = frame.convert('RGBA')
    
    alpha = frame.split()[3]
    bbox = alpha.getbbox()
    
    if bbox:
        frame = frame.crop(bbox)
    
    return frame

def extract_frames_by_centers(img, expected_frames):
    """
    Extraer frames detectando sus centros por densidad de contenido.
    """
    width, height = img.size
    
    print(f"  📐 Analizando distribución de contenido...")
    
    # Analizar distribución horizontal
    column_density = analyze_content_distribution(img)
    
    # Detectar centros de frames
    centers = detect_frame_centers(column_density, expected_frames, width)
    
    # Calcular ancho aproximado de frame
    if len(centers) > 1:
        avg_spacing = np.mean(np.diff(centers))
        frame_width = avg_spacing * 0.95  # 95% del espaciado para evitar solapamiento
    else:
        frame_width = width / expected_frames
    
    print(f"  📊 Extrayendo {len(centers)} frames (ancho ~{frame_width:.0f}px):")
    
    # Extraer cada frame
    frames = []
    for i, center in enumerate(centers):
        frame = extract_frame_at_center(img, center, frame_width)
        
        if frame.size[0] > 0 and frame.size[1] > 0:
            frames.append(frame)
            print(f"    Frame {i+1}: centro en x={center}, tamaño {frame.size[0]}×{frame.size[1]}px")
        else:
            print(f"    Frame {i+1}: VACÍO (saltado)")
    
    return frames

def resize_and_center_frame(frame, target_size):
    """
    Redimensionar frame manteniendo aspecto y centrarlo.
    Alinea al fondo para decoraciones de suelo.
    """
    orig_w, orig_h = frame.size
    
    # Crear canvas transparente
    result = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))
    
    # Calcular escala
    scale = min(target_size / orig_w, target_size / orig_h)
    new_w = int(orig_w * scale)
    new_h = int(orig_h * scale)
    
    # Redimensionar con alta calidad
    resized = frame.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    # Centrar horizontalmente, alinear al fondo verticalmente
    x_offset = (target_size - new_w) // 2
    y_offset = target_size - new_h
    
    result.paste(resized, (x_offset, y_offset), resized)
    
    return result

def process_spritesheet_advanced(input_path, output_path, expected_frames, frame_size=256, padding=4):
    """
    Procesar sprite sheet con detección avanzada por centro de masa.
    """
    print(f"\n{'='*70}")
    print(f"📄 Procesamiento avanzado: {Path(input_path).name}")
    print(f"   Frames esperados: {expected_frames}")
    print(f"{'='*70}")
    
    img = Image.open(input_path)
    width, height = img.size
    print(f"  📏 Dimensiones originales: {width}×{height}px")
    
    # Extraer frames por centros de masa
    frames = extract_frames_by_centers(img, expected_frames)
    
    if len(frames) != expected_frames:
        print(f"\n  ⚠️ Se extrajeron {len(frames)} frames, esperados {expected_frames}")
        if len(frames) == 0:
            print(f"  ❌ No se pudo extraer ningún frame")
            return False
    
    print(f"\n  ✅ {len(frames)} frames extraídos")
    print(f"  🔧 Redimensionando a {frame_size}×{frame_size}px...")
    
    # Redimensionar y centrar
    processed_frames = []
    for i, frame in enumerate(frames):
        resized = resize_and_center_frame(frame, frame_size)
        processed_frames.append(resized)
        print(f"    Frame {i+1}: {frame.size[0]}×{frame.size[1]} → {frame_size}×{frame_size}px")
    
    # Crear sprite sheet horizontal
    total_width = (frame_size * len(processed_frames)) + (padding * (len(processed_frames) - 1))
    spritesheet = Image.new('RGBA', (total_width, frame_size), (0, 0, 0, 0))
    
    x = 0
    for frame in processed_frames:
        spritesheet.paste(frame, (x, 0))
        x += frame_size + padding
    
    # Guardar
    spritesheet.save(output_path, 'PNG')
    print(f"\n  ✅ Guardado: {Path(output_path).name}")
    print(f"     Dimensiones finales: {spritesheet.size[0]}×{spritesheet.size[1]}px")
    
    return True

def main():
    if len(sys.argv) < 4:
        print("USO: python fix_spritesheet_advanced.py <input.png> <output.png> <frames>")
        sys.exit(1)
    
    input_path = sys.argv[1]
    output_path = sys.argv[2]
    expected_frames = int(sys.argv[3])
    
    success = process_spritesheet_advanced(input_path, output_path, expected_frames)
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
