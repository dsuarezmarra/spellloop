from pathlib import Path
import subprocess
import shutil
import sys

ROOT = Path("audio/sfx")
TARGET_SR = "48000"

def ffprobe_codec(p: Path) -> str:
    cmd = ["ffprobe", "-v", "error", "-select_streams", "a:0",
           "-show_entries", "stream=codec_name", "-of", "default=nk=1:nw=1", str(p)]
    try:
        out = subprocess.check_output(cmd, text=True).strip()
        return out
    except Exception:
        return "unknown"

def convert_in_place(src: Path):
    tmp = src.with_suffix(src.suffix + ".tmp.wav")
    cmd = [
        "ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
        "-i", str(src),
        "-ar", TARGET_SR,
        "-ac", "1",
        "-c:a", "pcm_s16le",
        "-af", "afade=t=in:st=0:d=0.01,afade=t=out:st=0:d=0.02",
        str(tmp)
    ]
    subprocess.check_call(cmd)
    shutil.move(str(tmp), str(src))

def main():
    if not ROOT.exists():
        print(f"ERROR: {ROOT} not found")
        sys.exit(1)

    files = [p for p in ROOT.rglob("*.wav") if p.is_file()]
    print(f"Found {len(files)} .wav files under {ROOT}")

    fixed = 0
    failed = 0

    for p in files:
        try:
            with open(p, "rb") as f:
                header = f.read(4)
        except Exception:
            failed += 1
            continue

        if header != b"RIFF":
            codec = ffprobe_codec(p)
            print(f"Fixing non-RIFF WAV: {p} (codec={codec})")
            try:
                convert_in_place(p)
                fixed += 1
            except Exception as e:
                print(f"FAILED: {p} -> {e}")
                failed += 1

    print(f"Done. Fixed: {fixed}, Failed: {failed}")

if __name__ == "__main__":
    main()
