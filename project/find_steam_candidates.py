import os

# Try importing PIL
try:
    from PIL import Image
except ImportError:
    print("PIL missing")
    sys.exit(1)

directory = r'C:\Users\Usuario\.gemini\antigravity\brain\3762163f-b80c-4102-9cb1-7e1dc0992c85'

TARGETS = {
    'Header': (460, 215),
    'Small': (231, 87),
    'Main': (616, 353),
    'Hero': (3840, 1240),
    'Hero_Alt': (1920, 620),
    'Library': (600, 900)
}

print(f"Scanning {directory} for Steam assets...")

matches = []
close_calls = []

files = [f for f in os.listdir(directory) if f.lower().endswith(('.png', '.jpg', '.jpeg'))]

for f in files:
    path = os.path.join(directory, f)
    try:
        with Image.open(path) as img:
            w, h = img.width, img.height
            
            # Check for exact/close matches
            matched = False
            for name, (tw, th) in TARGETS.items():
                if abs(w - tw) < 20 and abs(h - th) < 20: # Tolerance
                    matches.append(f"{name}: {f} ({w}x{h})")
                    matched = True
            
            if not matched:
                # Check aspect ratio
                ratio = w / h
                for name, (tw, th) in TARGETS.items():
                    target_ratio = tw / th
                    if abs(ratio - target_ratio) < 0.1:
                        close_calls.append(f"{name} (Ratio): {f} ({w}x{h})")
                        
    except Exception as e:
        print(f"Error checking {f}: {e}")

print("\n--- EXACT / CLOSE MATCHES ---")
for m in matches:
    print(m)

print("\n--- ASPECT RATIO MATCHES ---")
for c in close_calls:
    if "Header" not in c: # Skip headers if too many
        print(c)
