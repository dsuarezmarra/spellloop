import os
import struct
import json

def get_dims(filepath):
    try:
        with open(filepath, 'rb') as f:
            head = f.read(24)
            if head[:8] == b'\x89\x50\x4E\x47\x0D\x0A\x1A\x0A':
                w = struct.unpack('>I', head[16:20])[0]
                h = struct.unpack('>I', head[20:24])[0]
                return [w, h]
            elif head[:2] == b'\xff\xd8':
                return "JPEG"
    except:
        pass
    return None

directory = r'c:\git\loopialike\project\docs\steam\assets'
files_to_check = [
    "Client Icon.png",
    "Community Icon.png",
    "Hero Image.png",
    "Library Capsule.png",
    "Logo.png",
    "Main Capsule.png",
    "Small Capsule.png"
]

results = {}
for f in files_to_check:
    path = os.path.join(directory, f)
    if os.path.exists(path):
        dims = get_dims(path)
        results[f] = dims if dims else "Unknown"
    else:
        results[f] = "Missing"

with open(r'c:\git\loopialike\project\assets_dims.json', 'w') as f:
    json.dump(results, f, indent=2)
