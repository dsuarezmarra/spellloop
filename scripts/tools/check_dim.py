from PIL import Image
import os

path = r"project/assets/sprites/players/frost_mage/walk/walk_down_strip.png"
if os.path.exists(path):
    img = Image.open(path)
    print(f"Image: {path}")
    print(f"Format: {img.format}")
    print(f"Size: {img.size}")
    print(f"Mode: {img.mode}")
else:
    print("File not found")
