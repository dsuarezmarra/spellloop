import os
from pathlib import Path

AUDIO_DIR = Path("audio")

def audit_riff():
    print("🔍 Scanning for invalid WAV headers...")
    deleted_count = 0
    total_count = 0
    
    for root, dirs, files in os.walk(AUDIO_DIR):
        for file in files:
            if file.endswith(".wav"):
                total_count += 1
                path = Path(root) / file
                try:
                    with open(path, "rb") as f:
                        header = f.read(4)
                    
                    if header != b'RIFF':
                        print(f"❌ Invalid Header: {file} ({header}) -> DELETING")
                        path.unlink()
                        deleted_count += 1
                except Exception as e:
                    print(f"❌ Error reading {file}: {e}")

    print(f"✅ Audit Complete. Scanned {total_count}. Deleted {deleted_count} invalid files.")

if __name__ == "__main__":
    audit_riff()
