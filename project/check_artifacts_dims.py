import os

# Use PIL if installed, otherwise basic struct
try:
    from PIL import Image
    def get_dims(filepath):
        try:
            with Image.open(filepath) as img:
                return (img.width, img.height)
        except:
            return None
except ImportError:
    import struct
    def get_dims(filepath):
        try:
            with open(filepath, 'rb') as f:
                head = f.read(24)
                if len(head) < 24: return None
                if head[:8] == b'\x89\x50\x4E\x47\x0D\x0A\x1A\x0A': # PNG Check
                    w = struct.unpack('>I', head[16:20])[0]
                    h = struct.unpack('>I', head[20:24])[0]
                    return (w, h)
                return None
        except:
            return None

directory = r'C:\Users\Usuario\.gemini\antigravity\brain\3762163f-b80c-4102-9cb1-7e1dc0992c85'

try:
    files = os.listdir(directory)
    images = [f for f in files if f.lower().endswith(('.png', '.jpg', '.jpeg'))]

    print(f"Found {len(images)} images in artifacts dir")
    print("-" * 65)
    print(f"{'Filename':<50} | {'Dimensions':<15}")
    print("-" * 65)

    for f in images:
        path = os.path.join(directory, f)
        dims = get_dims(path)
        if dims:
            print(f"{f:<50} | {dims[0]}x{dims[1]}")
        else:
            # Maybe it's not a valid PNG/JPG or struct check failed
            print(f"{f:<50} | Unknown")

except Exception as e:
    print(f"Error: {e}")
