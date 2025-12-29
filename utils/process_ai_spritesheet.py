#!/usr/bin/env python3
"""
AI Spritesheet Processor for Spellloop
=======================================
Procesa spritesheets generados por IA (ChatGPT/Gemini) y los convierte
al formato exacto requerido por Godot:
- Frames de 64x64 píxeles
- Sprites centrados
- Número correcto de frames (duplicando si es necesario)
- Fondo transparente

Uso:
    python process_ai_spritesheet.py <input_image> <output_path> [--frames N] [--duplicate FRAME_INDEX]
    
Ejemplo:
    python process_ai_spritesheet.py flight.png ice_wand/flight.png --frames 6 --duplicate 2
"""

import os
import sys
import argparse
from pathlib import Path

try:
    from PIL import Image
    import numpy as np
except ImportError:
    print("ERROR: Necesitas instalar Pillow y numpy")
    print("Ejecuta: pip install Pillow numpy")
    sys.exit(1)


class SpriteSheetProcessor:
    """Procesa spritesheets de IA al formato de Godot."""
    
    def __init__(self, target_frame_size: int = 64):
        self.target_frame_size = target_frame_size
        self.sprites = []
        self.bounding_boxes = []
        
    def load_image(self, path: str) -> Image.Image:
        """Carga una imagen y la convierte a RGBA."""
        img = Image.open(path)
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        return img
    
    def find_sprites(self, img: Image.Image, min_size: int = 20) -> list:
        """
        Detecta sprites individuales en la imagen usando análisis de columnas.
        Busca gaps de transparencia para separar los sprites.
        """
        arr = np.array(img)
        height, width = arr.shape[:2]
        
        # Obtener canal alpha
        alpha = arr[:, :, 3]
        
        # Encontrar columnas que tienen píxeles no transparentes
        col_has_content = np.any(alpha > 10, axis=0)
        
        # Encontrar los rangos de columnas con contenido
        sprites_x_ranges = []
        in_sprite = False
        start_x = 0
        
        for x in range(width):
            if col_has_content[x] and not in_sprite:
                in_sprite = True
                start_x = x
            elif not col_has_content[x] and in_sprite:
                in_sprite = False
                if x - start_x >= min_size:
                    sprites_x_ranges.append((start_x, x))
        
        # Manejar sprite que llega al borde derecho
        if in_sprite and width - start_x >= min_size:
            sprites_x_ranges.append((start_x, width))
        
        # Para cada rango X, encontrar el rango Y
        bounding_boxes = []
        for x_start, x_end in sprites_x_ranges:
            # Buscar filas con contenido en este rango X
            region_alpha = alpha[:, x_start:x_end]
            row_has_content = np.any(region_alpha > 10, axis=1)
            
            y_indices = np.where(row_has_content)[0]
            if len(y_indices) > 0:
                y_start = y_indices[0]
                y_end = y_indices[-1] + 1
                bounding_boxes.append((x_start, y_start, x_end, y_end))
        
        return bounding_boxes
    
    def extract_sprite(self, img: Image.Image, bbox: tuple) -> Image.Image:
        """Extrae un sprite de la imagen usando su bounding box."""
        x1, y1, x2, y2 = bbox
        return img.crop((x1, y1, x2, y2))
    
    def center_sprite_in_frame(self, sprite: Image.Image, 
                                frame_size: int = None,
                                max_sprite_size: int = None) -> Image.Image:
        """
        Centra un sprite en un frame del tamaño objetivo.
        Opcionalmente redimensiona si es demasiado grande.
        """
        if frame_size is None:
            frame_size = self.target_frame_size
            
        if max_sprite_size is None:
            max_sprite_size = int(frame_size * 0.85)  # 85% del frame máximo
        
        # Redimensionar si es necesario manteniendo proporción
        w, h = sprite.size
        if w > max_sprite_size or h > max_sprite_size:
            scale = min(max_sprite_size / w, max_sprite_size / h)
            new_w = int(w * scale)
            new_h = int(h * scale)
            sprite = sprite.resize((new_w, new_h), Image.Resampling.LANCZOS)
            w, h = sprite.size
        
        # Crear frame transparente
        frame = Image.new('RGBA', (frame_size, frame_size), (0, 0, 0, 0))
        
        # Calcular posición centrada
        x = (frame_size - w) // 2
        y = (frame_size - h) // 2
        
        # Pegar sprite centrado
        frame.paste(sprite, (x, y), sprite)
        
        return frame
    
    def process_image(self, input_path: str, 
                      target_frames: int = 6,
                      duplicate_frame: int = None) -> list:
        """
        Procesa una imagen de spritesheet de IA.
        
        Args:
            input_path: Ruta a la imagen de entrada
            target_frames: Número de frames deseado en la salida
            duplicate_frame: Índice del frame a duplicar si faltan frames (0-based)
                            Si es None, duplica el frame del medio
        
        Returns:
            Lista de imágenes de frames procesados
        """
        print(f"\n{'='*60}")
        print(f"Procesando: {input_path}")
        print(f"{'='*60}")
        
        # Cargar imagen
        img = self.load_image(input_path)
        print(f"Tamaño de imagen: {img.size[0]}x{img.size[1]}")
        
        # Detectar sprites
        bboxes = self.find_sprites(img)
        print(f"Sprites detectados: {len(bboxes)}")
        
        for i, bbox in enumerate(bboxes):
            x1, y1, x2, y2 = bbox
            print(f"  Sprite {i+1}: pos=({x1},{y1}) tamaño={x2-x1}x{y2-y1}")
        
        if len(bboxes) == 0:
            raise ValueError("No se detectaron sprites en la imagen")
        
        # Extraer y procesar sprites
        processed_frames = []
        for bbox in bboxes:
            sprite = self.extract_sprite(img, bbox)
            frame = self.center_sprite_in_frame(sprite)
            processed_frames.append(frame)
        
        # Ajustar número de frames
        current_count = len(processed_frames)
        
        if current_count < target_frames:
            # Necesitamos duplicar frames
            frames_to_add = target_frames - current_count
            
            if duplicate_frame is None:
                # Por defecto, duplicar el frame del medio
                duplicate_frame = current_count // 2
            
            # Asegurar que el índice es válido
            duplicate_frame = max(0, min(duplicate_frame, current_count - 1))
            
            print(f"\nAjustando frames: {current_count} → {target_frames}")
            print(f"Duplicando frame {duplicate_frame + 1} ({frames_to_add} veces)")
            
            # Insertar frames duplicados después del frame seleccionado
            for _ in range(frames_to_add):
                frame_copy = processed_frames[duplicate_frame].copy()
                processed_frames.insert(duplicate_frame + 1, frame_copy)
                
        elif current_count > target_frames:
            # Demasiados frames, recortar
            print(f"\nAjustando frames: {current_count} → {target_frames}")
            print(f"Eliminando {current_count - target_frames} frame(s) del final")
            processed_frames = processed_frames[:target_frames]
        
        print(f"Frames finales: {len(processed_frames)}")
        return processed_frames
    
    def create_spritesheet(self, frames: list) -> Image.Image:
        """Crea un spritesheet horizontal a partir de una lista de frames."""
        if not frames:
            raise ValueError("No hay frames para crear el spritesheet")
        
        frame_size = frames[0].size[0]
        total_width = frame_size * len(frames)
        
        spritesheet = Image.new('RGBA', (total_width, frame_size), (0, 0, 0, 0))
        
        for i, frame in enumerate(frames):
            spritesheet.paste(frame, (i * frame_size, 0))
        
        return spritesheet
    
    def save_spritesheet(self, spritesheet: Image.Image, output_path: str):
        """Guarda el spritesheet asegurando que el directorio existe."""
        output_dir = os.path.dirname(output_path)
        if output_dir:
            os.makedirs(output_dir, exist_ok=True)
        
        spritesheet.save(output_path, 'PNG')
        print(f"\n✅ Guardado: {output_path}")
        print(f"   Tamaño: {spritesheet.size[0]}x{spritesheet.size[1]}")


def process_ice_wand_batch():
    """
    Procesa el lote completo de Ice Wand desde las imágenes descargadas.
    Ajustado específicamente para las imágenes de ChatGPT.
    """
    processor = SpriteSheetProcessor(target_frame_size=64)
    
    # Rutas base
    downloads_dir = Path(r"C:\Users\Usuario\Downloads")
    output_base = Path(r"C:\git\spellloop\project\assets\sprites\projectiles\ice_wand")
    
    # Configuración para cada animación de Ice Wand (ChatGPT)
    # Basado en el análisis: Flight=5 frames, Impact=5 frames, Launch=4 frames
    animations = [
        {
            "name": "flight",
            "input_patterns": ["ice*flight*", "flight*ice*", "DALL*E*1*", "*cristal*vuelo*"],
            "target_frames": 6,
            "duplicate_frame": 2,  # Duplicar frame 3 (índice 2) - mitad de rotación
            "description": "Cristal de hielo volando (loop)"
        },
        {
            "name": "impact", 
            "input_patterns": ["ice*impact*", "impact*ice*", "DALL*E*2*", "*cristal*impacto*"],
            "target_frames": 6,
            "duplicate_frame": 2,  # Duplicar frame 3 - explosión máxima
            "description": "Cristal rompiéndose"
        },
        {
            "name": "launch",
            "input_patterns": ["ice*launch*", "launch*ice*", "DALL*E*3*", "*cristal*lanzamiento*"],
            "target_frames": 4,
            "duplicate_frame": None,  # Ya tiene 4 frames
            "description": "Cristal formándose"
        }
    ]
    
    print("\n" + "="*70)
    print("   ICE WAND SPRITESHEET PROCESSOR")
    print("   Procesando imágenes de ChatGPT para Spellloop")
    print("="*70)
    
    # Buscar archivos PNG en descargas
    png_files = list(downloads_dir.glob("*.png"))
    print(f"\nArchivos PNG encontrados en Downloads: {len(png_files)}")
    
    if png_files:
        print("\nArchivos disponibles:")
        for i, f in enumerate(png_files[-10:], 1):  # Mostrar los últimos 10
            print(f"  {i}. {f.name}")
    
    return processor, output_base, animations


def interactive_mode():
    """Modo interactivo para seleccionar y procesar archivos."""
    processor = SpriteSheetProcessor(target_frame_size=64)
    
    downloads_dir = Path(r"C:\Users\Usuario\Downloads")
    output_base = Path(r"C:\git\spellloop\project\assets\sprites\projectiles\ice_wand")
    
    print("\n" + "="*70)
    print("   MODO INTERACTIVO - PROCESADOR DE SPRITESHEETS")
    print("="*70)
    
    # Listar archivos PNG recientes
    png_files = sorted(downloads_dir.glob("*.png"), key=os.path.getmtime, reverse=True)[:15]
    
    if not png_files:
        print("❌ No se encontraron archivos PNG en Downloads")
        return
    
    print("\nArchivos PNG más recientes:")
    for i, f in enumerate(png_files, 1):
        size = os.path.getsize(f) / 1024
        print(f"  [{i:2d}] {f.name} ({size:.1f} KB)")
    
    # Procesar Ice Wand
    print("\n" + "-"*50)
    print("PROCESANDO ICE WAND")
    print("-"*50)
    
    animations_config = {
        "flight": {"frames": 6, "duplicate": 2, "desc": "Vuelo (6 frames, loop)"},
        "impact": {"frames": 6, "duplicate": 2, "desc": "Impacto (6 frames)"},
        "launch": {"frames": 4, "duplicate": None, "desc": "Lanzamiento (4 frames)"}
    }
    
    for anim_name, config in animations_config.items():
        print(f"\n>> {anim_name.upper()} - {config['desc']}")
        
        try:
            idx = int(input(f"   Número del archivo para {anim_name} (0 para saltar): ")) - 1
            if idx < 0:
                print(f"   Saltando {anim_name}")
                continue
                
            input_file = png_files[idx]
            output_file = output_base / f"{anim_name}.png"
            
            frames = processor.process_image(
                str(input_file),
                target_frames=config["frames"],
                duplicate_frame=config["duplicate"]
            )
            
            spritesheet = processor.create_spritesheet(frames)
            processor.save_spritesheet(spritesheet, str(output_file))
            
        except (ValueError, IndexError) as e:
            print(f"   ⚠️ Error: {e}")
            continue
    
    print("\n" + "="*70)
    print("   PROCESO COMPLETADO")
    print("="*70)


def process_single_file(input_path: str, output_path: str, 
                        target_frames: int = 6, duplicate_frame: int = None):
    """Procesa un solo archivo."""
    processor = SpriteSheetProcessor(target_frame_size=64)
    
    frames = processor.process_image(input_path, target_frames, duplicate_frame)
    spritesheet = processor.create_spritesheet(frames)
    processor.save_spritesheet(spritesheet, output_path)


def main():
    parser = argparse.ArgumentParser(
        description="Procesa spritesheets de IA para Godot",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Ejemplos:
  python process_ai_spritesheet.py flight.png output/flight.png --frames 6 --duplicate 2
  python process_ai_spritesheet.py --interactive
  python process_ai_spritesheet.py --batch-ice-wand
        """
    )
    
    parser.add_argument("input", nargs="?", help="Archivo de entrada")
    parser.add_argument("output", nargs="?", help="Archivo de salida")
    parser.add_argument("--frames", "-f", type=int, default=6,
                        help="Número de frames objetivo (default: 6)")
    parser.add_argument("--duplicate", "-d", type=int, default=None,
                        help="Índice del frame a duplicar (0-based, default: medio)")
    parser.add_argument("--interactive", "-i", action="store_true",
                        help="Modo interactivo")
    parser.add_argument("--batch-ice-wand", action="store_true",
                        help="Procesar lote de Ice Wand")
    
    args = parser.parse_args()
    
    if args.interactive:
        interactive_mode()
    elif args.batch_ice_wand:
        process_ice_wand_batch()
    elif args.input and args.output:
        process_single_file(args.input, args.output, args.frames, args.duplicate)
    else:
        # Si no hay argumentos, mostrar modo interactivo simplificado
        print("\n¿Qué deseas hacer?")
        print("  1. Modo interactivo (seleccionar archivos)")
        print("  2. Procesar un archivo específico")
        
        choice = input("\nOpción [1]: ").strip() or "1"
        
        if choice == "1":
            interactive_mode()
        else:
            input_path = input("Ruta del archivo de entrada: ").strip()
            output_path = input("Ruta del archivo de salida: ").strip()
            frames = int(input("Número de frames [6]: ").strip() or "6")
            dup = input("Frame a duplicar (vacío=auto): ").strip()
            dup = int(dup) if dup else None
            
            process_single_file(input_path, output_path, frames, dup)


if __name__ == "__main__":
    main()
