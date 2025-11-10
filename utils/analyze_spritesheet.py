#!/usr/bin/env python3
"""
analyze_spritesheet.py
Analiza visualmente un sprite sheet y muestra información sobre su estructura.
Útil para diagnosticar problemas con layouts incorrectos.
"""

import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

def analyze_spritesheet(image_path, expected_frames=None):
    """Analizar y generar visualización de un sprite sheet."""
    
    image_path = Path(image_path)
    
    if not image_path.exists():
        print(f"❌ Archivo no encontrado: {image_path}")
        return
    
    print(f"\n📄 Analizando: {image_path.name}")
    
    # Cargar imagen
    img = Image.open(image_path)
    width, height = img.size
    
    print(f"  📏 Dimensiones: {width}×{height} px")
    print(f"  🎨 Modo: {img.mode}")
    
    # Detectar contenido no transparente
    if img.mode == 'RGBA':
        # Obtener canal alpha
        alpha = img.split()[3]
        bbox = alpha.getbbox()
        
        if bbox:
            x1, y1, x2, y2 = bbox
            content_width = x2 - x1
            content_height = y2 - y1
            print(f"  📦 Área con contenido: ({x1}, {y1}) → ({x2}, {y2})")
            print(f"     Tamaño del contenido: {content_width}×{content_height} px")
        else:
            print(f"  ⚠️ Imagen completamente transparente")
            return
    
    # Si se especificó número de frames, intentar dividir
    if expected_frames:
        print(f"\n  🔍 Intentando detectar {expected_frames} frames...")
        
        # Probar diferentes layouts
        layouts_to_try = [
            (expected_frames, 1, "horizontal"),
            (1, expected_frames, "vertical"),
            (expected_frames // 2, 2, "grid 2 filas"),
            (2, expected_frames // 2, "grid 2 columnas"),
            (expected_frames // 3, 3, "grid 3 filas"),
            (3, expected_frames // 3, "grid 3 columnas"),
            (3, 2, "grid 3×2"),
            (2, 3, "grid 2×3"),
        ]
        
        for cols, rows, desc in layouts_to_try:
            if cols * rows != expected_frames:
                continue
            
            frame_w = width // cols
            frame_h = height // rows
            
            print(f"\n  Layout {desc}: {cols}×{rows}")
            print(f"    Tamaño de frame: {frame_w}×{frame_h} px")
            
            # Analizar cada frame
            empty_frames = 0
            for row in range(rows):
                for col in range(cols):
                    frame_num = row * cols + col + 1
                    x = col * frame_w
                    y = row * frame_h
                    
                    frame = img.crop((x, y, x + frame_w, y + frame_h))
                    
                    # Verificar si el frame tiene contenido
                    if frame.mode == 'RGBA':
                        alpha = frame.split()[3]
                        frame_bbox = alpha.getbbox()
                        
                        if frame_bbox:
                            fx1, fy1, fx2, fy2 = frame_bbox
                            fc_w = fx2 - fx1
                            fc_h = fy2 - fy1
                            print(f"      Frame {frame_num}: contenido {fc_w}×{fc_h} px en ({fx1},{fy1})")
                        else:
                            empty_frames += 1
                            print(f"      Frame {frame_num}: VACÍO")
            
            if empty_frames > 0:
                print(f"    ⚠️ {empty_frames} frames vacíos detectados")
            else:
                print(f"    ✅ Todos los frames tienen contenido")
    
    # Crear visualización con grid
    output_path = image_path.parent / f"{image_path.stem}_analysis.png"
    create_grid_visualization(img, output_path, expected_frames)
    print(f"\n  💾 Visualización guardada: {output_path.name}")

def create_grid_visualization(img, output_path, expected_frames=None):
    """Crear una imagen con grid superpuesto para visualizar divisiones."""
    
    # Crear copia de la imagen
    vis_img = img.copy().convert('RGBA')
    draw = ImageDraw.Draw(vis_img)
    
    width, height = img.size
    
    if expected_frames:
        # Probar layout más probable
        possible_layouts = [
            (expected_frames, 1),
            (expected_frames // 2, 2),
            (3, 2),
            (2, 3),
        ]
        
        for cols, rows in possible_layouts:
            if cols * rows == expected_frames:
                frame_w = width // cols
                frame_h = height // rows
                
                # Dibujar líneas verticales
                for i in range(1, cols):
                    x = i * frame_w
                    draw.line([(x, 0), (x, height)], fill=(255, 0, 0, 200), width=2)
                
                # Dibujar líneas horizontales
                for i in range(1, rows):
                    y = i * frame_h
                    draw.line([(0, y), (width, y)], fill=(255, 0, 0, 200), width=2)
                
                # Numerar frames
                for row in range(rows):
                    for col in range(cols):
                        frame_num = row * cols + col + 1
                        x = col * frame_w + 10
                        y = row * frame_h + 10
                        
                        # Fondo para el número
                        draw.rectangle([x-5, y-5, x+25, y+20], fill=(0, 0, 0, 180))
                        draw.text((x, y), str(frame_num), fill=(255, 255, 0, 255))
                
                break
    
    vis_img.save(output_path, 'PNG')

def main():
    if len(sys.argv) < 2:
        print("USO:")
        print(f"  python {sys.argv[0]} <imagen.png> [frames_esperados]")
        print()
        print("EJEMPLO:")
        print(f"  python {sys.argv[0]} lava_decor3_sheet_f6_256.png.backup 6")
        sys.exit(1)
    
    image_path = sys.argv[1]
    expected_frames = int(sys.argv[2]) if len(sys.argv) > 2 else None
    
    analyze_spritesheet(image_path, expected_frames)

if __name__ == "__main__":
    main()
