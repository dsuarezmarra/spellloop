import os
import json
import wave
import struct
import math
from pathlib import Path

MANIFEST_PATH = Path("tools/generation_manifest.json")
AUDIO_DIR = Path("audio")
RUNTIME_MANIFEST_PATH = Path("audio_manifest.json")

def read_wav_properties(file_path):
    try:
        with wave.open(str(file_path), 'rb') as wav:
            channels = wav.getnchannels()
            width = wav.getsampwidth()
            rate = wav.getframerate()
            frames = wav.getnframes()
            
            # Basic RMS/Peak check (scan first 1 second or 48k frames to save time if huge)
            # For validation we scan a chunk
            scan_frames = min(frames, 48000 * 5) 
            raw_data = wav.readframes(scan_frames)
            
            max_amp = 0
            sum_squares = 0
            sample_count = len(raw_data) // width
            
            # Assuming 16-bit
            if width == 2:
                fmt = f"<{sample_count}h" 
                samples = struct.unpack(fmt, raw_data)
                for s in samples:
                    val = abs(s)
                    if val > max_amp:
                        max_amp = val
                    sum_squares += s * s
            
            rms = math.sqrt(sum_squares / sample_count) if sample_count > 0 else 0
            
            # Convert to dBFS (16bit max is 32768)
            peak_db = 20 * math.log10(max_amp / 32768.0) if max_amp > 0 else -99.0
            rms_db = 20 * math.log10(rms / 32768.0) if rms > 0 else -99.0
            
            return {
                "channels": channels,
                "bit_depth": width * 8,
                "sample_rate": rate,
                "peak_db": peak_db,
                "rms_db": rms_db,
                "valid": True
            }
    except Exception as e:
        return {"valid": False, "error": str(e)}

def main(final_mode=False, export_missing=None, export_silence=None):
    print("=======================================")
    print(f"   AUDIO ASSET VALIDATION REPORT {'(FINAL MODE)' if final_mode else ''}")
    print("=======================================")
    
    if not MANIFEST_PATH.exists():
        print("❌ Generation manifest missing.")
        return

    with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
        gen_manifest = json.load(f)

    expected_count = 0
    found_count = 0
    missing_files = []
    invalid_files = []
    clipping_files = []
    silence_files = []
    
    runtime_manifest = {}

    print(f"🔍 Auditing {len(gen_manifest)} asset groups...")
    
    missing_assets_list = []
    silent_assets_list = []

    for item in gen_manifest:
        category = item["category"]
        name = item["name"]
        variations = item.get("variations", 1)
        
        group_files = []
        
        for i in range(variations):
            suffix = f"_{i+1:02d}" if variations > 1 else ""
            filename = f"{name}{suffix}.wav"
            file_path = AUDIO_DIR / category / filename
            expected_count += 1
            
            is_missing = False
            
            if not file_path.exists():
                missing_files.append(str(file_path))
                is_missing = True
            elif file_path.stat().st_size == 0:
                missing_files.append(str(file_path) + " (ZERO BYTE)")
                try:
                    os.remove(file_path)
                except:
                    pass
                is_missing = True
            
            if is_missing:
                # Create one-shot recovery entry
                recovery_entry = item.copy()
                recovery_entry["name"] = f"{name}{suffix}" 
                recovery_entry["variations"] = 1
                missing_assets_list.append(recovery_entry)
                continue
                
            found_count += 1
            
            # Checking Audio Properties
            props = read_wav_properties(file_path)
            
            if not props["valid"]:
                invalid_files.append(f"{filename}: {props.get('error')}")
                continue
                
            # Quality Gates
            failures = []
            if props["channels"] != 1 and "music" not in category:
                failures.append(f"Stereo SFX ({props['channels']}ch)")
            if props["sample_rate"] != 44100 and props["sample_rate"] != 48000:
                failures.append(f"Rate {props['sample_rate']}")
            if props["bit_depth"] != 16:
                 failures.append(f"BitDepth {props['bit_depth']}")
                 
            if failures:
                invalid_files.append(f"{filename}: {', '.join(failures)}")
                
            # Level Checks
            if props["peak_db"] > -0.2:
                clipping_files.append(f"{filename} ({props['peak_db']:.1f} dB)")
            
            if props["rms_db"] < -50.0: # Silence Threshold
                silence_str = f"{filename} ({props['rms_db']:.1f} dB)"
                silence_files.append(silence_str)
                
                # Create recovery entry for silent file
                # Check for -70dB threshold for aggressive regeneration?
                # User said: "regenerar solo los que sigan 'muertos' (los -80 dB o peor)"
                # "Para los que queden por debajo de -70 dB... regenerarlos con prompts más agresivos"
                # We will export ALL < -50dB here, and let the generator decide or specific arg?
                # Actually, let's filter here -> if exporting silence for regeneration, export the object.
                
                silent_recovery_entry = item.copy()
                silent_recovery_entry["name"] = f"{name}{suffix}"
                silent_recovery_entry["variations"] = 1
                silent_recovery_entry["current_db"] = props["rms_db"] # Pass DB to generator for logic
                
                # Check if we should add simple list or objects
                # We need a separate list for object export, reusing silence_files for display is fine
                # But for export_silence JSON, we want objects.
                # Let's add to a new list 'silent_assets_list'
                if "silent_assets_list" not in locals(): silent_assets_list = []
                silent_assets_list.append(silent_recovery_entry)

            # Add to runtime manifest paths
            # res://audio/category/filename
            godot_path = f"res://audio/{category}/{filename}"
            group_files.append(godot_path)
        
        if group_files:
            runtime_manifest[name] = {
                "files": group_files,
                "volume_db": -2.0 if "music" in category else 0.0,
                "pitch_scale": [0.95, 1.05] if "music" not in category else [1.0, 1.0],
                "bus": "Music" if "music" in category else "SFX"
            }

    # Summary
    print(f"\n📊 SUMMARY:")
    print(f"   Expected: {expected_count}")
    print(f"   Found:    {found_count}")
    print(f"   Missing:  {len(missing_files)}")
    print(f"   Invalid:  {len(invalid_files)}")
    
    if missing_files:
        print("\n❌ MISSING / ZERO-BYTE FILES:")
        for f in missing_files[:10]: # Limit output
            print(f"   - {f}")
        if len(missing_files) > 10:
            print(f"   ... and {len(missing_files)-10} more.")
            
    if invalid_files:
        print("\n⚠️ FORMAT WARNINGS:")
        for f in invalid_files[:10]:
            print(f"   - {f}")
            
    if clipping_files:
        print(f"\n🔊 CLIPPING DETECTED ({len(clipping_files)} files):")
        # Just a warning, stable audio can be loud
    
    if silence_files:
        print(f"\n🔇 SILENCE DETECTED ({len(silence_files)} files):")
        for f in silence_files:
           print(f"   - {f}")

    # Generate Runtime JSON
    with open(RUNTIME_MANIFEST_PATH, "w", encoding="utf-8") as f:
        json.dump(runtime_manifest, f, indent=2)
    print(f"\n✅ Generated runtime manifest: {RUNTIME_MANIFEST_PATH}")
    
    # Generate README
    readme_content = f"""# Audio Assets Report
    
## Status
- **Total Sounds**: {len(runtime_manifest)} groups ({found_count} files)
- **Missing**: {len(missing_files)}
- **Format Issues**: {len(invalid_files)}

## Setup
1. Ensure `.env` has valid keys.
2. Run `python tools/audio_generator.py` to fill missing gaps.
3. Run `python tools/validate_audio.py` to verify.

## Godot Usage
```gdscript
AudioManager.play("sfx_player_hurt")
AudioManager.play_music("music_boss_loop")
```
"""
    with open("README_AUDIO.md", "w", encoding="utf-8") as f:
        f.write(readme_content)

    if export_missing and missing_assets_list:
        with open(export_missing, "w", encoding="utf-8") as f:
            json.dump(missing_assets_list, f, indent=2)
        print(f"\n📝 Exported {len(missing_assets_list)} missing entries to {export_missing}")

    if export_silence and silent_assets_list:
        with open(export_silence, "w", encoding="utf-8") as f:
            json.dump(silent_assets_list, f, indent=2)
        print(f"\n🔊 Exported {len(silent_assets_list)} silent entries to {export_silence}")

    if final_mode and (missing_files or invalid_files):
        print("\n❌ FINAL VALIDATION FAILED")
        sys.exit(1)
    elif final_mode:
        print("\n✅ FINAL VALIDATION PASSED")
        sys.exit(0)

if __name__ == "__main__":
    import argparse
    import sys
    
    parser = argparse.ArgumentParser()
    parser.add_argument("--final", action="store_true", help="Fail with exit code 1 if assets missing")
    parser.add_argument("--export-missing", type=str, help="Path to export missing assets JSON")
    parser.add_argument("--export-silence", type=str, help="Path to export silent files list")
    args = parser.parse_args()
    
    main(final_mode=args.final, export_missing=args.export_missing, export_silence=args.export_silence)
