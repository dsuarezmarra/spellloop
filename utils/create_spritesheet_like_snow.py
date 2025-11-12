"""
COPIAR EXACTAMENTE LA ESTRATEGIA DE SNOW
Snow spritesheet: 4124×512 = 8 frames de 512px + 4px padding entre cada frame
"""
import sys
from pathlib import Path
from PIL import Image

def create_spritesheet_like_snow(biome_name: str, base_dir: str):
    """
    Crear spritesheet EXACTAMENTE igual que Snow:
    - 8 frames de 512x512
    - 4px de padding entre frames
    - Total: 4124x512 px
    """
    print("\n" + "="*70)
    print(f"CREANDO SPRITESHEET IGUAL QUE SNOW: {biome_name.upper()}")
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
        
        # Convertir a RGBA (igual que Snow)
        if img.mode != "RGBA":
            img = img.convert("RGBA")
            print(f"     → RGBA")
        
        # Redimensionar a 512x512 (igual que Snow)
        if img.size != (512, 512):
            img = img.resize((512, 512), Image.LANCZOS)
            print(f"     → 512x512")
        
        frames.append(img)
        print(f"     ✅ OK")
    
    if len(frames) != 8:
        print(f"\n❌ Error: Se esperaban 8 frames, encontrados {len(frames)}")
        return
    
    print(f"\n✅ {len(frames)} frames cargados")
    
    # EXACTAMENTE IGUAL QUE SNOW
    frame_w, frame_h = 512, 512
    padding = 4
    sheet_w = (frame_w + padding) * 8 - padding  # 4124 px (igual que Snow)
    sheet_h = frame_h  # 512 px
    
    print(f"\nCreando spritesheet (IGUAL QUE SNOW):")
    print(f"  • Frames: 8")
    print(f"  • Frame size: {frame_w}x{frame_h}px")
    print(f"  • Padding: {padding}px entre frames")
    print(f"  • Sheet size: {sheet_w}x{sheet_h}px")
    print(f"  • Verificación: {sheet_w} = (512 + 4) × 8 - 4")
    
    sheet = Image.new("RGBA", (sheet_w, sheet_h), (0, 0, 0, 0))
    
    # Pegar frames con padding
    x = 0
    for idx, frame in enumerate(frames):
        sheet.paste(frame, (x, 0))
        x += frame_w + padding
    
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
    print(f"  • Tamaño: {file_size:.2f} MB")
    
    # Comparar con Snow
    print(f"\n✅ MATCH CON SNOW:")
    print(f"  • Snow: 4124x512 RGBA")
    print(f"  • {biome_name.capitalize()}: {verify.size[0]}x{verify.size[1]} {verify.mode}")
    print(f"  • ¿Iguales? {verify.size == (4124, 512) and verify.mode == 'RGBA'}")
    
    print("\n" + "="*70)
    print("✅ SPRITESHEET CREADO IGUAL QUE SNOW")
    print("="*70)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Uso: python create_spritesheet_like_snow.py <biome> <base_dir>")
        sys.exit(1)
    
    biome = sys.argv[1].lower()
    base_dir = sys.argv[2]
    
    create_spritesheet_like_snow(biome, base_dir)
