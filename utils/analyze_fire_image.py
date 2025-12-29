"""
Script de diagnóstico para ver qué colores tiene la imagen
"""

from PIL import Image
import numpy as np
from collections import Counter

img_path = r"C:\git\spellloop\utils\fire_wand_raw\flight_raw.png"
img = Image.open(img_path).convert("RGBA")
pixels = np.array(img)

# Muestrear algunos píxeles para ver los colores
print("Imagen:", img.size)
print("\nMuestra de colores en diferentes posiciones:")

# Esquinas y centro
positions = [
    (10, 10, "Esquina sup-izq"),
    (img.width//2, 10, "Centro superior"),
    (img.width-10, 10, "Esquina sup-der"),
    (10, img.height//2, "Centro izquierda"),
    (img.width//2, img.height//2, "Centro"),
]

for x, y, name in positions:
    r, g, b, a = pixels[y, x]
    print(f"  {name} ({x},{y}): R={r} G={g} B={b} A={a}")

# Contar colores más comunes
print("\nColores más comunes (muestreo):")
flat = pixels.reshape(-1, 4)
# Agrupar por color aproximado
colors = []
for i in range(0, len(flat), 1000):  # Muestrear cada 1000 píxeles
    r, g, b, a = flat[i]
    colors.append((r, g, b, a))

counter = Counter(colors)
for color, count in counter.most_common(15):
    r, g, b, a = color
    is_gray = abs(int(r)-int(g)) < 20 and abs(int(g)-int(b)) < 20
    print(f"  RGBA({r:3d},{g:3d},{b:3d},{a:3d}) x{count:5d} {'(GRIS)' if is_gray else ''}")

# Ver una franja horizontal en el medio
print("\nPerfil horizontal en Y=768 (mitad):")
y = img.height // 2
for x in range(0, img.width, 200):
    r, g, b, a = pixels[y, x]
    is_gray = abs(int(r)-int(g)) < 20 and abs(int(g)-int(b)) < 20
    print(f"  X={x:4d}: R={r:3d} G={g:3d} B={b:3d} A={a:3d} {'GRIS' if is_gray else 'COLOR'}")
