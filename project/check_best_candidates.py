import os
import struct

def check(name):
    path = os.path.join(r'C:\Users\Usuario\.gemini\antigravity\brain\3762163f-b80c-4102-9cb1-7e1dc0992c85', name)
    try:
        with open(path, 'rb') as f:
            head = f.read(24)
            if head[:8] == b'\x89\x50\x4E\x47\x0D\x0A\x1A\x0A':
                w = struct.unpack('>I', head[16:20])[0]
                h = struct.unpack('>I', head[20:24])[0]
                print(f"{name}: {w}x{h}")
            else:
                print(f"{name}: Not PNG")
    except Exception as e:
        print(f"{name}: Error {e}")

candidates = [
    "main_capsule_1771007656522.png",
    "library_capsule_600x900_1771094627224.png",
    "small_capsule_231x87_1771073509340.png"
]

print("--- RESULTS ---")
for c in candidates:
    check(c)
print("--- END ---")
