"""
SOLUCIÓN DEFINITIVA: Crear spritesheet con wrap/repeat para tilemap seamless
Los frames NO son seamless nativamente, así que usaremos WRAP mode en Godot
"""
import sys
from pathlib import Path
from PIL import Image

def create_clean_spritesheet(biome_name: str, base_dir: str):
    """
    Crea un spritesheet limpio sin modificaciones
    Godot manejará el tiling con TEXTURE_REPEAT_ENABLED
    """
    print("\n" + "="*70)
    print(f"CREANDO SPRITESHEET LIMPIO: {biome_name.upper()}")
    print("="*70)
    
    base_path = Path(base_dir)
    frames = []
    
    print("\nProcesando frames:")
    for i in range(1, 9):
        frame_path = base_path / f"{i}.png"
        if not frame_path.exists():
            print(f"  ❌ No encontrado: {frame_path}")
            continue
            
        img = Image.open(frame_path)
        print(f"  📄 Frame {i}: {img.size} {img.mode}")
        
        # Convertir a RGBA
        if img.mode != "RGBA":
            img = img.convert("RGBA")
            print(f"     → Convertido a RGBA")
        
        # Redimensionar a 512x512
        if img.size != (512, 512):
            img = img.resize((512, 512), Image.LANCZOS)
            print(f"     → Redimensionado a 512x512")
        
        frames.append(img)
        print(f"     ✅ Listo")
    
    if len(frames) != 8:
        print(f"\n❌ Error: Se esperaban 8 frames, encontrados {len(frames)}")
        return
    
    print(f"\n✅ {len(frames)} frames procesados")
    
    # Crear spritesheet horizontal SIMPLE
    frame_w, frame_h = 512, 512
    sheet_w = frame_w * 8  # 4096
    sheet_h = frame_h       # 512
    
    print(f"\nCreando spritesheet:")
    print(f"  • Formato: Horizontal simple")
    print(f"  • Frames: 8")
    print(f"  • Frame size: {frame_w}x{frame_h}px")
    print(f"  • Sheet size: {sheet_w}x{sheet_h}px")
    print(f"  • Padding: 0px")
    
    sheet = Image.new("RGBA", (sheet_w, sheet_h), (0, 0, 0, 0))
    
    # Pegar frames
    for idx, frame in enumerate(frames):
        x = idx * frame_w
        sheet.paste(frame, (x, 0))
    
    # Guardar
    output_path = base_path / f"{biome_name}_base_animated_sheet_f8_512.png"
    sheet.save(output_path, "PNG", optimize=False)
    
    print(f"\n✅ Guardado: {output_path.name}")
    
    # Verificar
    verify = Image.open(output_path)
    file_size = output_path.stat().st_size / (1024 * 1024)
    
    print(f"\nVerificación:")
    print(f"  • Dimensiones: {verify.size}")
    print(f"  • Modo: {verify.mode}")
    print(f"  • Tamaño archivo: {file_size:.2f} MB")
    
    print("\n" + "="*70)
    print("✅ SPRITESHEET CREADO")
    print("="*70)
    print("\n⚠️  IMPORTANTE: Para tiles seamless, configurar en Godot:")
    print("   • Import: texture_filter = NEAREST")
    print("   • Import: texture_repeat = ENABLED")
    print("="*70)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Uso: python create_final_spritesheet.py <biome> <base_dir>")
        sys.exit(1)
    
    biome = sys.argv[1].lower()
    base_dir = sys.argv[2]
    
    create_clean_spritesheet(biome, base_dir)
