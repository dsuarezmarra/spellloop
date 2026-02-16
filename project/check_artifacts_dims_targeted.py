import os
import struct

def get_dims(filepath):
    try:
        with open(filepath, 'rb') as f:
            head = f.read(24)
            if head[:8] == b'\x89\x50\x4E\x47\x0D\x0A\x1A\x0A':
                w = struct.unpack('>I', head[16:20])[0]
                h = struct.unpack('>I', head[20:24])[0]
                return (w, h)
    except:
        pass
    return None

directory = r'C:\Users\Usuario\.gemini\antigravity\brain\3762163f-b80c-4102-9cb1-7e1dc0992c85'
candidates = [
    "main_capsule_1771007656522.png",
    "library_capsule_600x900_1771094627224.png",
    "small_capsule_231x87_1771073509340.png",
    "hero_image_1771073584547.png"
]

for f in candidates:
    path = os.path.join(directory, f)
    if os.path.exists(path):
        dims = get_dims(path)
        print(f"{f}: {dims[0]}x{dims[1]}" if dims else f"{f}: Unknown")
    else:
        print(f"{f}: Not Found")
