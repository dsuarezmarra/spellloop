import os
import sys

# Try importing PIL
try:
    from PIL import Image
    print("PIL imported successfully")
except ImportError as e:
    print(f"PIL import failed: {e}")
    Image = None

directory = r'C:\Users\Usuario\.gemini\antigravity\brain\3762163f-b80c-4102-9cb1-7e1dc0992c85'
candidates = [
    "main_capsule_1771007656522.png",
    "library_capsule_600x900_1771094627224.png",
    "small_capsule_231x87_1771073509340.png",
    "hero_image_1771073584547.png"
]

print(f"Checking directory: {directory}")

for f in candidates:
    path = os.path.join(directory, f)
    print(f"--- Checking {f} ---")
    if os.path.exists(path):
        print(f"File exists. Size: {os.path.getsize(path)} bytes")
        if Image:
            try:
                with Image.open(path) as img:
                    print(f"Dimensions: {img.width}x{img.height}")
                    print(f"Format: {img.format}")
            except Exception as e:
                print(f"PIL Error: {e}")
        else:
            print("Skipping dimension check (PIL missing)")
    else:
        print("File NOT found")
