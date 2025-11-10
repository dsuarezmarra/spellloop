"""
Regenera sprite sheets agregando padding de 4px entre frames.
Lee los sprite sheets existentes (sin padding) y los regenera con padding.
"""
from PIL import Image
from pathlib import Path

def add_padding_to_sheet(input_sheet_path, output_sheet_path, frame_width, frame_height, num_frames, padding=4):
    """
    Lee un sprite sheet sin padding y lo regenera con padding entre frames.
    
    Args:
        input_sheet_path: Ruta al sprite sheet sin padding
        output_sheet_path: Ruta de salida con padding
        frame_width: Ancho de cada frame
        frame_height: Alto de cada frame
        num_frames: Número de frames
        padding: Píxeles de padding entre frames (default 4)
    """
    # Cargar sprite sheet original
    sheet = Image.open(input_sheet_path)
    
    # Extraer frames individuales
    frames = []
    for i in range(num_frames):
        x = i * frame_width
        frame = sheet.crop((x, 0, x + frame_width, frame_height))
        frames.append(frame)
    
    # Crear nuevo sheet con padding
    new_width = frame_width * num_frames + padding * (num_frames - 1)
    new_height = frame_height
    
    new_sheet = Image.new('RGBA', (new_width, new_height), (0, 0, 0, 0))
    
    # Pegar frames con padding
    x_pos = 0
    for i, frame in enumerate(frames):
        new_sheet.paste(frame, (x_pos, 0))
        x_pos += frame_width + padding
    
    # Guardar
    new_sheet.save(output_sheet_path, 'PNG')
    
    print(f"✅ {output_sheet_path.name}")
    print(f"   Original: {sheet.size[0]}x{sheet.size[1]}px → Nuevo: {new_width}x{new_height}px")
    print(f"   {num_frames} frames con {padding}px padding")
    
    return new_sheet

def main():
    base_dir = Path(r"C:\git\spellloop\project\assets\textures\biomes\Snow")
    
    print("\n" + "="*80)
    print("REGENERANDO SPRITE SHEETS CON PADDING")
    print("="*80)
    
    # Procesar textura base
    print("\n--- TEXTURA BASE ---")
    base_sheet = base_dir / "base" / "snow_base_animated_sheet_f8_512.png"
    
    if base_sheet.exists():
        add_padding_to_sheet(
            base_sheet,
            base_sheet,  # Sobrescribir el mismo archivo
            512, 512, 8, padding=4
        )
    else:
        print(f"❌ No encontrado: {base_sheet}")
    
    # Procesar decoraciones
    print("\n--- DECORACIONES ---")
    decor_dir = base_dir / "decor"
    
    for i in range(1, 11):
        sheet_path = decor_dir / f"snow_decor{i}_sheet_f8_256.png"
        
        if sheet_path.exists():
            add_padding_to_sheet(
                sheet_path,
                sheet_path,  # Sobrescribir
                256, 256, 8, padding=4
            )
        else:
            print(f"❌ No encontrado: {sheet_path}")
    
    print("\n" + "="*80)
    print("COMPLETADO")
    print("="*80)
    print("✅ Todos los sprite sheets ahora tienen 4px de padding")
    print("✅ Compatible con AutoFrames.from_sheet() de Godot")

if __name__ == "__main__":
    main()
