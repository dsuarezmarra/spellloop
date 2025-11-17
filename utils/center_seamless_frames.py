"""
Script para centrar frames por centro de masas manteniendo seamless
Calcula el centro de masas de todos los frames y los centra sin romper la continuidad seamless
"""

import os
import sys
from PIL import Image
import numpy as np

def calculate_center_of_mass(image_array):
    """Calcula el centro de masas de una imagen basándose en luminosidad y alpha"""
    # Convertir a RGB si tiene alpha
    if image_array.shape[2] == 4:
        alpha = image_array[:, :, 3].astype(float) / 255.0
        rgb = image_array[:, :, :3]
    else:
        alpha = np.ones(image_array.shape[:2], dtype=float)
        rgb = image_array
    
    # Calcular luminosidad (percepción humana)
    luminosity = (0.299 * rgb[:, :, 0] + 0.587 * rgb[:, :, 1] + 0.114 * rgb[:, :, 2])
    
    # Invertir luminosidad para que los objetos oscuros tengan más peso
    # (asumiendo fondo claro y objetos oscuros en Desert)
    max_lum = np.max(luminosity)
    min_lum = np.min(luminosity)
    
    # Normalizar y invertir si el fondo es más claro que los objetos
    if max_lum - min_lum > 50:  # Hay contraste significativo
        inverted_lum = max_lum - luminosity
    else:
        inverted_lum = luminosity
    
    # Peso = luminosidad invertida * alpha
    weight = inverted_lum * alpha
    
    total_weight = np.sum(weight)
    if total_weight == 0:
        return image_array.shape[1] // 2, image_array.shape[0] // 2
    
    y_indices, x_indices = np.indices(weight.shape)
    
    center_x = np.sum(x_indices * weight) / total_weight
    center_y = np.sum(y_indices * weight) / total_weight
    
    return center_x, center_y

def shift_seamless(image_array, offset_x, offset_y):
    """Desplaza una imagen manteniendo seamless (wrap-around)"""
    return np.roll(image_array, (offset_y, offset_x), axis=(0, 1))

def main():
    if len(sys.argv) < 2:
        print("Uso: python center_seamless_frames.py <biome_name>")
        print("Ejemplo: python center_seamless_frames.py Desert")
        sys.exit(1)
    
    biome_name = sys.argv[1]
    base_dir = f"c:\\Users\\dsuarez1\\git\\spellloop\\project\\assets\\textures\\biomes\\{biome_name}\\base"
    
    if not os.path.exists(base_dir):
        print(f"❌ ERROR: No existe el directorio {base_dir}")
        sys.exit(1)
    
    print(f"\n=== CENTRANDO FRAMES {biome_name.upper()} (MANTENIENDO SEAMLESS) ===\n")
    
    # Cargar todos los frames (1.png - 8.png)
    frames = []
    frame_paths = []
    
    for i in range(1, 9):
        frame_path = os.path.join(base_dir, f"{i}.png")
        if not os.path.exists(frame_path):
            print(f"❌ ERROR: No se encuentra {frame_path}")
            sys.exit(1)
        
        img = Image.open(frame_path)
        img_array = np.array(img)
        frames.append(img_array)
        frame_paths.append(frame_path)
        print(f"  ✓ Cargado frame {i}.png ({img_array.shape[1]}x{img_array.shape[0]})")
    
    # Calcular centro de masas de todos los frames
    print("\nCalculando centros de masas (basado en luminosidad)...")
    centers = []
    for i, frame in enumerate(frames):
        cx, cy = calculate_center_of_mass(frame)
        centers.append((cx, cy))
        print(f"  Frame {i+1}: centro en ({cx:.2f}, {cy:.2f})")
    
    # Calcular el centro de masas promedio
    avg_cx = np.mean([c[0] for c in centers])
    avg_cy = np.mean([c[1] for c in centers])
    
    # Calcular el centro de la imagen
    img_center_x = frames[0].shape[1] / 2
    img_center_y = frames[0].shape[0] / 2
    
    print(f"\nCentro de masas promedio: ({avg_cx:.2f}, {avg_cy:.2f})")
    print(f"Centro de imagen: ({img_center_x:.2f}, {img_center_y:.2f})")
    
    # Calcular offset global para centrar (redondear al píxel más cercano)
    global_offset_x = int(round(img_center_x - avg_cx))
    global_offset_y = int(round(img_center_y - avg_cy))
    
    print(f"Offset global a aplicar: ({global_offset_x}, {global_offset_y})")
    
    # Mostrar desviación estándar de los centros (para ver cuánto varían)
    std_x = np.std([c[0] for c in centers])
    std_y = np.std([c[1] for c in centers])
    print(f"Desviación estándar de centros: (±{std_x:.2f}px, ±{std_y:.2f}px)")
    
    if global_offset_x == 0 and global_offset_y == 0:
        print("\n✅ Los frames ya están centrados, no se requieren cambios")
        return
    
    # Aplicar offset a todos los frames (con wrap-around seamless)
    print("\nAplicando offset con wrap-around...")
    
    # Crear backup de frames originales
    backup_dir = os.path.join(base_dir, "backup_before_center")
    os.makedirs(backup_dir, exist_ok=True)
    
    for i, (frame, frame_path) in enumerate(zip(frames, frame_paths)):
        # Backup
        backup_path = os.path.join(backup_dir, f"{i+1}.png")
        Image.fromarray(frame).save(backup_path)
        
        # Aplicar shift seamless
        shifted = shift_seamless(frame, global_offset_x, global_offset_y)
        
        # Guardar frame centrado
        Image.fromarray(shifted).save(frame_path)
        print(f"  ✓ Frame {i+1}.png centrado y guardado")
    
    print(f"\n✅ PROCESO COMPLETADO")
    print(f"   Backup guardado en: {backup_dir}")
    print(f"   Frames centrados con offset ({global_offset_x}, {global_offset_y})")
    print(f"   Propiedad seamless PRESERVADA (wrap-around aplicado)")
    print(f"\n⚠️  Ahora regenera el spritesheet con los frames centrados")

if __name__ == "__main__":
    main()
