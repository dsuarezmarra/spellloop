import os
try:
    from PIL import Image
except ImportError:
    print("PIL missing")
    import sys; sys.exit(1)

directory = r'C:\Users\Usuario\.gemini\antigravity\brain\3762163f-b80c-4102-9cb1-7e1dc0992c85'
candidates = [
    "main_capsule_1771007656522.png",
    "library_capsule_600x900_1771094627224.png",
    "small_capsule_231x87_1771073509340.png"
]

print("--- PIL CHECK ---")
for f in candidates:
    path = os.path.join(directory, f)
    if os.path.exists(path):
        try:
            with Image.open(path) as img:
                print(f"{f}: {img.width}x{img.height} ({img.format})")
        except Exception as e:
            print(f"{f}: invalid image ({e})")
    else:
        print(f"{f}: not found")
print("--- END ---")
