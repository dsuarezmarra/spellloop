from PIL import Image
import os

snow_path = r'c:\git\spellloop\project\assets\textures\biomes\Snow\base\snow_base_animated_sheet_f8_512.png'
lava_path = r'c:\git\spellloop\project\assets\textures\biomes\Lava\base\lava_base_animated_sheet_f8_512.png'

snow = Image.open(snow_path)
lava = Image.open(lava_path)

print("="*70)
print("COMPARACIÓN SPRITESHEETS")
print("="*70)
print(f"\nSnow: {snow.size} {snow.mode}")
print(f"Lava: {lava.size} {lava.mode}")
print(f"\n✅ Dimensiones iguales: {snow.size == lava.size}")
print(f"✅ Modo igual: {snow.mode == lava.mode}")

snow_size = os.path.getsize(snow_path) / (1024*1024)
lava_size = os.path.getsize(lava_path) / (1024*1024)

print(f"\nSnow archivo: {snow_size:.2f} MB")
print(f"Lava archivo: {lava_size:.2f} MB")
print("="*70)
