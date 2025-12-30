#!/usr/bin/env python3
"""
Procesador especial para Abyss impact - tiene estructura irregular
Solo 4 bloques visibles, el frame 2 contiene múltiples frames combinados
"""

from PIL import Image
import numpy as np
import os

def center_content_in_frame(frame, target_size=64, max_content=54):
    """Centra el contenido en un frame de tamaño fijo."""
    if frame.mode != 'RGBA':
        frame = frame.convert('RGBA')
    
    arr = np.array(frame)
    alpha = arr[:, :, 3]
    
    rows = np.any(alpha > 10, axis=1)
    cols = np.any(alpha > 10, axis=0)
    
    if not np.any(rows) or not np.any(cols):
        return Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))
    
    y_min, y_max = np.where(rows)[0][[0, -1]]
    x_min, x_max = np.where(cols)[0][[0, -1]]
    
    content = frame.crop((x_min, y_min, x_max + 1, y_max + 1))
    
    content_w, content_h = content.size
    scale = min(max_content / content_w, max_content / content_h, 1.0)
    
    if scale < 1.0:
        new_w = int(content_w * scale)
        new_h = int(content_h * scale)
        content = content.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    result = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))
    
    paste_x = (target_size - content.width) // 2
    paste_y = (target_size - content.height) // 2
    
    result.paste(content, (paste_x, paste_y), content)
    
    return result

def process_abyss_impact():
    base_path = r"c:\git\spellloop\project\assets\sprites\projectiles\fusion\abyss"
    input_path = os.path.join(base_path, "imapct.png")  # Nota: typo en el nombre original
    output_path = os.path.join(base_path, "impact_spritesheet_abyss.png")
    
    print("=" * 60)
    print("PROCESANDO ABYSS IMPACT (estructura irregular)")
    print("=" * 60)
    
    img = Image.open(input_path).convert('RGBA')
    print(f"Tamaño original: {img.size}")
    
    arr = np.array(img)
    alpha = arr[:,:,3]
    
    # Recortar zona vertical con contenido
    rows = np.any(alpha > 10, axis=1)
    y_min, y_max = np.where(rows)[0][[0, -1]]
    
    # Añadir un poco de padding
    y_min = max(0, y_min - 2)
    y_max = min(img.height - 1, y_max + 2)
    
    cropped = img.crop((0, y_min, img.width, y_max + 1))
    print(f"Zona recortada: {cropped.size}")
    
    # Encontrar bounds de cada bloque
    arr2 = np.array(cropped)
    alpha2 = arr2[:,:,3]
    density = np.sum(alpha2 > 10, axis=0)
    
    in_content = False
    blocks = []
    start = 0
    
    for x in range(len(density)):
        if density[x] > 5 and not in_content:
            in_content = True
            start = x
        elif density[x] <= 5 and in_content:
            in_content = False
            if x - start > 15:
                blocks.append((start, x))
    
    if in_content and len(density) - start > 15:
        blocks.append((start, len(density)))
    
    print(f"Bloques encontrados: {len(blocks)}")
    
    frames = []
    
    # Bloque 1: Frame 1 (impacto inicial)
    if len(blocks) > 0:
        s, e = blocks[0]
        frame = cropped.crop((s, 0, e, cropped.height))
        frames.append(frame)
        print(f"  Frame 1: bloque 0, x={s}-{e}")
    
    # Bloque 2: Es grande, contiene múltiples frames - dividir en 3 partes
    if len(blocks) > 1:
        s, e = blocks[1]
        width = e - s
        part_width = width // 3
        
        for i in range(3):
            ps = s + i * part_width
            pe = s + (i + 1) * part_width if i < 2 else e
            frame = cropped.crop((ps, 0, pe, cropped.height))
            frames.append(frame)
            print(f"  Frame {len(frames)}: bloque 1 parte {i+1}, x={ps}-{pe}")
    
    # Bloque 3: Frame 5
    if len(blocks) > 2:
        s, e = blocks[2]
        frame = cropped.crop((s, 0, e, cropped.height))
        frames.append(frame)
        print(f"  Frame {len(frames)}: bloque 2, x={s}-{e}")
    
    # Bloque 4: Frame 6
    if len(blocks) > 3:
        s, e = blocks[3]
        frame = cropped.crop((s, 0, e, cropped.height))
        frames.append(frame)
        print(f"  Frame {len(frames)}: bloque 3, x={s}-{e}")
    
    print(f"\nTotal frames extraídos: {len(frames)}")
    
    # Crear spritesheet
    spritesheet = Image.new('RGBA', (384, 64), (0, 0, 0, 0))
    
    for i, frame in enumerate(frames[:6]):
        centered = center_content_in_frame(frame, 64, 54)
        spritesheet.paste(centered, (i * 64, 0))
    
    spritesheet.save(output_path)
    print(f"\nGuardado: {output_path}")
    print(f"Spritesheet: {spritesheet.size}")
    
    # Verificar resultado
    print("\nVerificación de frames:")
    for i in range(6):
        frame = spritesheet.crop((i*64, 0, (i+1)*64, 64))
        arr_f = np.array(frame)
        opaque = np.sum(arr_f[:,:,3] > 10)
        print(f"  Frame {i+1}: {opaque} píxeles")

if __name__ == "__main__":
    process_abyss_impact()
