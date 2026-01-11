"""
Analiza los sprites del wizard para determinar sus dimensiones y estructura
"""
from PIL import Image
import os

base_path = "c:/git/spellloop/project/assets/sprites/players/wizard"
folders = ["walk", "cast", "hit", "death"]

print("=" * 60)
print("ANÁLISIS DE SPRITES DEL WIZARD")
print("=" * 60)

for folder in folders:
    folder_path = os.path.join(base_path, folder)
    if not os.path.exists(folder_path):
        print(f"\n❌ Carpeta no encontrada: {folder}")
        continue
    
    print(f"\n📁 {folder.upper()}/")
    print("-" * 40)
    
    for img_file in sorted(os.listdir(folder_path)):
        if not img_file.endswith(".png"):
            continue
        
        img_path = os.path.join(folder_path, img_file)
        img = Image.open(img_path)
        w, h = img.size
        
        # Estimar número de frames basado en aspecto
        aspect = w / h
        if aspect > 3.5:
            estimated_frames = 4
        elif aspect > 2.5:
            estimated_frames = 3
        elif aspect > 1.5:
            estimated_frames = 2
        else:
            estimated_frames = 1
        
        frame_width = w // estimated_frames if estimated_frames > 1 else w
        
        print(f"  📄 {img_file}")
        print(f"     Tamaño: {w}x{h} px")
        print(f"     Aspecto: {aspect:.2f}")
        print(f"     Frames estimados: {estimated_frames}")
        print(f"     Tamaño frame: {frame_width}x{h} px")
        print()

print("=" * 60)
