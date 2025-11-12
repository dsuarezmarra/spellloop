"""
Genera spritesheet recortando 1px de cada borde de cada frame
para eliminar posibles artefactos en los bordes
"""
import sys
from pathlib import Path
from PIL import Image

def create_cropped_spritesheet(biome_name: str, base_dir: str):
    """
    Crea un spritesheet recortando 1px de cada borde de cada frame
    
    Args:
        biome_name: Nombre del bioma (lava, snow, etc.)
        base_dir: Directorio con frames 1.png a 8.png
    """
    print("\n" + "="*70)
    print(f"CREANDO SPRITESHEET CON CROP 1PX: {biome_name.upper()}")
    print("="*70)
    
    base_path = Path(base_dir)
    frames = []
    
    print("\nCargando y recortando frames:")
    for i in range(1, 9):
        frame_path = base_path / f"{i}.png"
        if not frame_path.exists():
            print(f"  ❌ No se encontró: {frame_path}")
            continue
            
        print(f"  📄 {i}.png")
        img = Image.open(frame_path)
        
        # Convertir a RGBA si es necesario
        if img.mode != "RGBA":
            print(f"     Convirtiendo {img.mode} → RGBA")
            img = img.convert("RGBA")
        
        # Redimensionar a 512x512 si es necesario
        if img.size != (512, 512):
            print(f"     Redimensionando {img.size} → 512×512px")
            img = img.resize((512, 512), Image.LANCZOS)
        
        # RECORTAR 1 PÍXEL DE CADA BORDE (512x512 → 510x510)
        print(f"     ✂️  Recortando 1px de cada borde (512x512 → 510x510)")
        img = img.crop((1, 1, 511, 511))  # (left, top, right, bottom)
        
        frames.append(img)
        print(f"     ✅ Procesado")
    
    if len(frames) != 8:
        print(f"\n❌ Error: Se esperaban 8 frames, se encontraron {len(frames)}")
        return
    
    print(f"\n✅ {len(frames)} frames procesados")
    
    # Crear spritesheet SIN padding
    frame_w, frame_h = 510, 510  # Tamaño después del crop
    sheet_w = frame_w * 8  # 510 * 8 = 4080
    sheet_h = frame_h      # 510
    
    print(f"\nCreando spritesheet:")
    print(f"  • Frames: 8")
    print(f"  • Tamaño por frame: {frame_w}×{frame_h}px (recortado)")
    print(f"  • Padding: 0px")
    print(f"  • Dimensiones finales: {sheet_w}×{sheet_h}px")
    
    sheet = Image.new("RGBA", (sheet_w, sheet_h), (0, 0, 0, 0))
    
    # Pegar frames sin espacios
    x = 0
    for frame in frames:
        sheet.paste(frame, (x, 0))
        x += frame_w
    
    # Guardar
    output_path = base_path / f"{biome_name}_base_animated_sheet_f8_510.png"
    sheet.save(output_path, "PNG")
    
    print(f"\n✅ Spritesheet guardado: {output_path.name}")
    
    # Verificar
    verify = Image.open(output_path)
    file_size_mb = output_path.stat().st_size / (1024 * 1024)
    
    print(f"\nVerificación:")
    print(f"  • Dimensiones: {verify.size}")
    print(f"  • Modo: {verify.mode}")
    print(f"  • Tamaño: {file_size_mb:.2f} MB")
    
    print("\n" + "="*70)
    print("✅ COMPLETADO - Frames recortados 1px por borde")
    print("="*70)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Uso: python create_spritesheet_cropped.py <biome_name> <base_dir>")
        print('Ejemplo: python create_spritesheet_cropped.py lava "C:\\path\\to\\base"')
        sys.exit(1)
    
    biome = sys.argv[1].lower()
    base_dir = sys.argv[2]
    
    create_cropped_spritesheet(biome, base_dir)
