#!/usr/bin/env python3
"""
Remove Background from Spritesheet
Elimina el fondo de color sólido de un spritesheet y lo hace transparente.
"""

import sys
from pathlib import Path

try:
    from PIL import Image
    import numpy as np
except ImportError:
    print("❌ Instalando dependencias...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow", "numpy"])
    from PIL import Image
    import numpy as np


def remove_background(input_path: str, output_path: str = None, tolerance: int = 30):
    """
    Elimina el fondo de una imagen detectando el color de las esquinas.
    
    Args:
        input_path: Ruta a la imagen de entrada
        output_path: Ruta de salida (si es None, sobreescribe)
        tolerance: Tolerancia de color (0-255) para detectar variaciones del fondo
    """
    # Cargar imagen
    img = Image.open(input_path).convert("RGBA")
    data = np.array(img)
    
    print(f"📷 Imagen cargada: {img.size[0]}x{img.size[1]} px")
    
    # Detectar color de fondo desde las 4 esquinas
    corners = [
        data[0, 0],           # Top-left
        data[0, -1],          # Top-right
        data[-1, 0],          # Bottom-left
        data[-1, -1]          # Bottom-right
    ]
    
    # Usar el color más común de las esquinas
    bg_color = corners[0][:3]  # RGB sin alpha
    print(f"🎨 Color de fondo detectado: RGB{tuple(bg_color)}")
    
    # Crear máscara de transparencia
    # Pixels que coinciden con el fondo (dentro de tolerancia) se hacen transparentes
    r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]
    
    # Calcular diferencia con el color de fondo
    diff_r = np.abs(r.astype(int) - int(bg_color[0]))
    diff_g = np.abs(g.astype(int) - int(bg_color[1]))
    diff_b = np.abs(b.astype(int) - int(bg_color[2]))
    
    # Máscara: True donde el pixel es similar al fondo
    bg_mask = (diff_r <= tolerance) & (diff_g <= tolerance) & (diff_b <= tolerance)
    
    # Aplicar transparencia
    data[:,:,3] = np.where(bg_mask, 0, 255)
    
    # Contar pixels modificados
    transparent_pixels = np.sum(bg_mask)
    total_pixels = data.shape[0] * data.shape[1]
    percentage = (transparent_pixels / total_pixels) * 100
    
    print(f"✨ Pixels transparentes: {transparent_pixels:,} / {total_pixels:,} ({percentage:.1f}%)")
    
    # Guardar
    result = Image.fromarray(data)
    
    if output_path is None:
        # Crear nombre con sufijo _transparent
        p = Path(input_path)
        output_path = str(p.parent / f"{p.stem}_transparent{p.suffix}")
    
    result.save(output_path, "PNG")
    print(f"✅ Guardado: {output_path}")
    
    return output_path


def remove_background_by_color(input_path: str, output_path: str = None, 
                                target_color: tuple = None, tolerance: int = 30):
    """
    Elimina un color específico del fondo.
    
    Args:
        input_path: Ruta a la imagen
        output_path: Ruta de salida
        target_color: Tupla RGB del color a eliminar (ej: (255, 0, 255) para magenta)
        tolerance: Tolerancia de color
    """
    img = Image.open(input_path).convert("RGBA")
    data = np.array(img)
    
    print(f"📷 Imagen: {img.size[0]}x{img.size[1]} px")
    
    if target_color is None:
        # Auto-detectar desde esquina
        target_color = tuple(data[0, 0][:3])
    
    print(f"🎨 Eliminando color: RGB{target_color}")
    
    r, g, b = data[:,:,0], data[:,:,1], data[:,:,2]
    
    diff_r = np.abs(r.astype(int) - target_color[0])
    diff_g = np.abs(g.astype(int) - target_color[1])
    diff_b = np.abs(b.astype(int) - target_color[2])
    
    bg_mask = (diff_r <= tolerance) & (diff_g <= tolerance) & (diff_b <= tolerance)
    
    data[:,:,3] = np.where(bg_mask, 0, 255)
    
    # Contar pixels modificados
    transparent_pixels = np.sum(bg_mask)
    total_pixels = data.shape[0] * data.shape[1]
    percentage = (transparent_pixels / total_pixels) * 100
    print(f"✨ Pixels transparentes: {transparent_pixels:,} / {total_pixels:,} ({percentage:.1f}%)")
    
    result = Image.fromarray(data)
    
    if output_path is None:
        p = Path(input_path)
        output_path = str(p.parent / f"{p.stem}_transparent{p.suffix}")
    
    result.save(output_path, "PNG")
    print(f"✅ Guardado: {output_path}")
    
    return output_path


def remove_magenta(input_path: str, output_path: str = None, tolerance: int = 50):
    """
    Elimina el fondo MAGENTA (#FF00FF) de un spritesheet.
    Optimizado para spritesheets generados por ChatGPT/DALL-E.
    Incluye eliminación AGRESIVA de bordes con antialiasing.
    """
    print(f"🔮 Eliminando fondo MAGENTA de: {input_path}")
    
    img = Image.open(input_path).convert("RGBA")
    data = np.array(img)
    
    print(f"📷 Imagen: {img.size[0]}x{img.size[1]} px")
    
    r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]
    
    # ========== FASE 1: Eliminar magenta puro ==========
    diff_r = np.abs(r.astype(int) - 255)
    diff_g = g.astype(int)
    diff_b = np.abs(b.astype(int) - 255)
    magenta_pure = (diff_r <= tolerance) & (diff_g <= tolerance) & (diff_b <= tolerance)
    
    # ========== FASE 2: Eliminar cualquier tinte magenta ==========
    # Píxeles donde R > G y B > G (característica del magenta)
    r_int = r.astype(int)
    g_int = g.astype(int)
    b_int = b.astype(int)
    
    # Magenta tiene R alto, B alto, G bajo
    # Cualquier pixel donde R y B sean significativamente mayores que G
    magenta_tint1 = (r_int > g_int + 30) & (b_int > g_int + 30) & (r_int > 100) & (b_int > 100)
    
    # Detección más agresiva: R y B similares y ambos mayores que G
    rb_similar = np.abs(r_int - b_int) < 80
    rb_high = (r_int + b_int) / 2 > 120
    g_much_lower = g_int < (r_int + b_int) / 3
    magenta_tint2 = rb_similar & rb_high & g_much_lower
    
    # ========== FASE 3: Bordes con antialiasing muy suave ==========
    # Detectar píxeles que tienen CUALQUIER componente magenta
    # Ratio: si (R+B)/(G+1) > 3, es magenta
    magenta_ratio = ((r_int + b_int) / (g_int + 1)) > 2.5
    has_magenta_component = (r_int > 150) & (b_int > 150) & (g_int < 150)
    
    # ========== FASE 4: Ultra agresivo para bordes rosados/violetas ==========
    # Cualquier pixel con más rojo+azul que verde, y ambos altos
    purple_pink = (r_int > 120) & (b_int > 120) & (g_int < (r_int + b_int) / 2.2)
    
    # ========== Combinar TODAS las máscaras ==========
    combined_mask = magenta_pure | magenta_tint1 | magenta_tint2 | magenta_ratio | has_magenta_component | purple_pink
    
    # Aplicar transparencia
    data[:,:,3] = np.where(combined_mask, 0, 255)
    
    # ========== FASE 5: Erosión de bordes - eliminar píxeles adyacentes a transparentes ==========
    # que tengan cualquier tinte rosado/magenta
    from scipy import ndimage
    
    # Dilatar la máscara de transparencia para encontrar bordes
    alpha_mask = data[:,:,3] == 0
    dilated = ndimage.binary_dilation(alpha_mask, iterations=1)
    border_pixels = dilated & ~alpha_mask  # Píxeles en el borde del sprite
    
    # En los bordes, ser MUY estricto con cualquier tinte magenta
    border_magenta = border_pixels & ((r_int > 100) & (b_int > 100) & (g_int < 120))
    data[:,:,3] = np.where(border_magenta, 0, data[:,:,3])
    
    # Segunda pasada de erosión
    alpha_mask2 = data[:,:,3] == 0
    dilated2 = ndimage.binary_dilation(alpha_mask2, iterations=1)
    border_pixels2 = dilated2 & ~alpha_mask2
    border_magenta2 = border_pixels2 & ((r_int > 80) & (b_int > 80) & (g_int < 100))
    data[:,:,3] = np.where(border_magenta2, 0, data[:,:,3])
    
    # Contar pixels modificados
    transparent_pixels = np.sum(data[:,:,3] == 0)
    total_pixels = data.shape[0] * data.shape[1]
    percentage = (transparent_pixels / total_pixels) * 100
    print(f"✨ Pixels transparentes: {transparent_pixels:,} / {total_pixels:,} ({percentage:.1f}%)")
    
    result = Image.fromarray(data)
    
    if output_path is None:
        p = Path(input_path)
        output_path = str(p.parent / f"{p.stem}_transparent{p.suffix}")
    
    result.save(output_path, "PNG")
    print(f"✅ Guardado: {output_path}")
    
    return output_path


def remove_green(input_path: str, output_path: str = None, tolerance: int = 50):
    """
    Elimina el fondo VERDE LIME de un spritesheet.
    Optimizado para verde brillante (#00FF00 o similar).
    Eliminación ULTRA-AGRESIVA de bordes.
    """
    print(f"🌿 Eliminando fondo VERDE de: {input_path}")
    
    img = Image.open(input_path).convert("RGBA")
    data = np.array(img)
    
    print(f"📷 Imagen: {img.size[0]}x{img.size[1]} px")
    
    r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]
    r_int = r.astype(int)
    g_int = g.astype(int)
    b_int = b.astype(int)
    
    # ========== FASE 1: Verde lime puro (#00FF00 o cercano) ==========
    green_pure = (r_int < 180) & (g_int > 180) & (b_int < 180)
    
    # ========== FASE 2: Verde brillante (G >> R y G >> B) ==========
    g_dominant = (g_int > r_int + 30) & (g_int > b_int + 30) & (g_int > 120)
    
    # ========== FASE 3: Cualquier verde saturado ==========
    green_saturated = (g_int > 150) & (r_int < 200) & (b_int < 200) & (g_int > r_int) & (g_int > b_int)
    
    # ========== FASE 4: Verde con algo de amarillo (verde lima) ==========
    lime_green = (g_int > 180) & (r_int > 80) & (r_int < 230) & (b_int < 120)
    
    # ========== FASE 5: Ratio verde - MÁS AGRESIVO ==========
    green_ratio = (g_int / (r_int + 1) > 1.2) & (g_int / (b_int + 1) > 1.2) & (g_int > 100)
    
    # ========== FASE 6: Verde con tinte - para antialiasing ==========
    green_tint = (g_int > 100) & (g_int >= r_int) & (g_int >= b_int) & ((g_int - r_int) + (g_int - b_int) > 40)
    
    # ========== FASE 7: Detección ultra-sensible para bordes ==========
    # Cualquier pixel donde G sea el canal dominante significativamente
    g_is_max = (g_int >= r_int) & (g_int >= b_int)
    g_much_higher = (g_int > 80) & ((g_int - np.minimum(r_int, b_int)) > 20)
    ultra_green = g_is_max & g_much_higher
    
    # Combinar máscaras
    combined_mask = green_pure | g_dominant | green_saturated | lime_green | green_ratio | green_tint | ultra_green
    
    # Aplicar transparencia
    data[:,:,3] = np.where(combined_mask, 0, 255)
    
    # ========== FASE 8: Erosión de bordes verdes - MÚLTIPLES PASADAS ==========
    from scipy import ndimage
    
    for iteration in range(3):  # 3 pasadas de erosión
        alpha_mask = data[:,:,3] == 0
        dilated = ndimage.binary_dilation(alpha_mask, iterations=1)
        border_pixels = dilated & ~alpha_mask
        
        # En bordes, eliminar cualquier pixel con tinte verde
        # Cada pasada es más agresiva
        threshold = 100 - (iteration * 20)  # 100, 80, 60
        border_green = border_pixels & (g_int > threshold) & (g_int >= r_int - 10) & (g_int >= b_int - 10)
        data[:,:,3] = np.where(border_green, 0, data[:,:,3])
    
    # ========== FASE 9: Limpieza final de píxeles verdosos aislados ==========
    # Píxeles donde G > promedio(R,B) + margen
    rb_avg = (r_int + b_int) / 2
    greenish = (g_int > rb_avg + 15) & (g_int > 70)
    
    # Solo aplicar a píxeles cerca de áreas transparentes
    alpha_mask_final = data[:,:,3] == 0
    near_transparent = ndimage.binary_dilation(alpha_mask_final, iterations=2)
    edge_greenish = greenish & near_transparent & ~alpha_mask_final
    data[:,:,3] = np.where(edge_greenish, 0, data[:,:,3])
    
    # Contar pixels
    transparent_pixels = np.sum(data[:,:,3] == 0)
    total_pixels = data.shape[0] * data.shape[1]
    percentage = (transparent_pixels / total_pixels) * 100
    print(f"✨ Pixels transparentes: {transparent_pixels:,} / {total_pixels:,} ({percentage:.1f}%)")
    
    result = Image.fromarray(data)
    
    if output_path is None:
        p = Path(input_path)
        output_path = str(p.parent / f"{p.stem}_transparent{p.suffix}")
    
    result.save(output_path, "PNG")
    print(f"✅ Guardado: {output_path}")
    
    return output_path
    
    return output_path


def process_folder(folder_path: str, tolerance: int = 30):
    """Procesa todas las imágenes PNG en una carpeta."""
    folder = Path(folder_path)
    images = list(folder.glob("*.png"))
    
    print(f"📁 Procesando {len(images)} imágenes en {folder}")
    
    for img_path in images:
        if "_transparent" in img_path.stem:
            continue  # Saltar ya procesadas
        
        print(f"\n--- {img_path.name} ---")
        try:
            remove_background(str(img_path), tolerance=tolerance)
        except Exception as e:
            print(f"❌ Error: {e}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python remove_background.py <imagen.png> [tolerancia]")
        print("     python remove_background.py <carpeta/> [tolerancia]")
        print("     python remove_background.py --magenta <imagen.png>")
        print("     python remove_background.py --green <imagen.png>")
        sys.exit(1)
    
    # Modo magenta
    if sys.argv[1] == "--magenta" and len(sys.argv) > 2:
        tolerance = int(sys.argv[3]) if len(sys.argv) > 3 else 50
        remove_magenta(sys.argv[2], tolerance=tolerance)
        sys.exit(0)
    
    # Modo verde lime
    if sys.argv[1] == "--green" and len(sys.argv) > 2:
        tolerance = int(sys.argv[3]) if len(sys.argv) > 3 else 50
        remove_green(sys.argv[2], tolerance=tolerance)
        sys.exit(0)
    
    path = sys.argv[1]
    tolerance = int(sys.argv[2]) if len(sys.argv) > 2 else 30
    
    if Path(path).is_dir():
        process_folder(path, tolerance)
    else:
        remove_background(path, tolerance=tolerance)
