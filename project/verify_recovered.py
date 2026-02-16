import os
try:
    from PIL import Image
except:
    import sys; sys.exit(1)

directory = r'c:\git\loopialike\project\docs\steam\assets'
candidates = {
    "lib_candidate.png": (600, 900),
    "small_candidate.png": (231, 87),
    "main_candidate.png": (616, 353)
}

print("--- VERIFYING ---")
for f, (tw, th) in candidates.items():
    path = os.path.join(directory, f)
    if os.path.exists(path):
        try:
            with Image.open(path) as img:
                match = "MATCH" if (img.width == tw and img.height == th) else "MISMATCH"
                print(f"{f}: {img.width}x{img.height} -> {match}")
        except Exception as e:
            print(f"{f}: Error {e}")
    else:
        print(f"{f}: Missing")
print("--- END ---")
