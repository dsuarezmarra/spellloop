import os
import sys
import subprocess
import json
from pathlib import Path

# Fix Configuration
SILENCE_THRESHOLD = "-45dB"
PEAK_TARGET = "-1dB"

def fix_audio_files(file_list_path):
    print("=======================================")
    print("   AUDIO FIXER: SILENCE & GAIN")
    print("=======================================")
    
    if not Path(file_list_path).exists():
        print(f"❌ Input file list not found: {file_list_path}")
        return

    with open(file_list_path, "r", encoding="utf-8") as f:
        files_to_fix = json.load(f) # Assuming list of strings (paths)

    # If it's a list of full objects (like missing assets), extract names? 
    # validate_audio exports a list of strings "path/to/file.wav (RMS...)" often?
    # Let's check validate_audio output format.
    # It appends: "filename (rms db)". logic needs to extract clean path.
    
    clean_paths = []
    for entry in files_to_fix:
        # validate_audio appends debug info like "file.wav (-60dB)"
        # We need to split by space if it exists
        clean_path = entry.split(" (")[0]
        clean_paths.append(Path(clean_path))

    print(f"🔧 Processing {len(clean_paths)} files...")
    
    success_count = 0
    
    for file_path in clean_paths:
        if not file_path.exists():
            print(f"⚠️ File not found: {file_path}")
            continue
            
        print(f"Processing: {file_path.name}...")
        
        temp_out = file_path.with_suffix(".temp.wav")
        
        # 1. Remove Silence
        # 2. Normalize
        # 3. Ensure Format (48k, mono)
        
        cmd = [
            "ffmpeg", "-y",
            "-i", str(file_path),
            "-af", 
            f"silenceremove=stop_periods=-1:stop_duration=0.1:stop_threshold={SILENCE_THRESHOLD}:start_periods=1:start_duration=0.1:start_threshold={SILENCE_THRESHOLD},alimiter=limit={PEAK_TARGET}",
            "-ar", "48000",
            "-ac", "1",
            "-c:a", "pcm_s16le",
            str(temp_out)
        ]
        
        try:
            # Suppress output unless error
            subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
            
            # Verify result is not empty
            if temp_out.exists() and temp_out.stat().st_size > 44: # > header
                # Overwrite original
                temp_out.replace(file_path)
                success_count += 1
                # print("   ✅ Fixed")
            else:
                print("   ❌ Trimmed file is empty (pure silence?)")
                if temp_out.exists(): temp_out.unlink()
                
        except subprocess.CalledProcessError as e:
            print(f"   ❌ FFMPEG Error: {e.stderr.decode()}")
            if temp_out.exists(): temp_out.unlink()
            
    print(f"\n🎉 Finished. Fixed {success_count}/{len(clean_paths)} files.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python tools/fix_silence_and_gain.py <jsons_list_path>")
    else:
        fix_audio_files(sys.argv[1])
