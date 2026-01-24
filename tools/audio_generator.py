#!/usr/bin/env python3
"""
Audio Generator for Spellloop
Generates SFX using ElevenLabs API with post-processing pipeline.
"""

import os
import json
import time
import subprocess
import struct
import math
from pathlib import Path
from dotenv import load_dotenv
import requests

# Load environment variables
load_dotenv()

# Configuration
ELEVENLABS_API_KEY = os.getenv("ELEVENLABS_API_KEY")
ELEVENLABS_SFX_URL = "https://api.elevenlabs.io/v1/sound-generation"

PROJECT_ROOT = Path(__file__).parent.parent
OUTPUT_DIR = PROJECT_ROOT / "project" / "audio"
MANIFEST_PATH = Path(__file__).parent / "generation_manifest.json"

# Audio specs
TARGET_SAMPLE_RATE = 48000
TARGET_BIT_DEPTH = 16
TARGET_CHANNELS = 1  # Mono for SFX

def check_api_keys():
    """Verify API keys are present."""
    if not ELEVENLABS_API_KEY:
        print("ERROR: ELEVENLABS_API_KEY not found in .env")
        print(f"Please add your API key to: {PROJECT_ROOT / '.env'}")
        return False
    print(f"[OK] ElevenLabs API key found")
    return True

def generate_elevenlabs_sfx(prompt: str, duration_seconds: float = 2.0) -> bytes | None:
    """Generate SFX using ElevenLabs Sound Generation API."""
    headers = {
        "xi-api-key": ELEVENLABS_API_KEY,
        "Content-Type": "application/json"
    }
    
    payload = {
        "text": prompt,
        "duration_seconds": min(duration_seconds, 22.0),  # Max 22s
        "prompt_influence": 0.3
    }
    
    for attempt in range(3):
        try:
            response = requests.post(
                ELEVENLABS_SFX_URL,
                headers=headers,
                json=payload,
                timeout=60
            )
            
            if response.status_code == 200:
                return response.content
            elif response.status_code == 429:
                wait_time = 10 * (attempt + 1)
                print(f"   Rate limited. Waiting {wait_time}s...")
                time.sleep(wait_time)
            else:
                print(f"   API error {response.status_code}: {response.text[:100]}")
                if attempt < 2:
                    time.sleep(2)
                    
        except Exception as e:
            print(f"   Request failed: {e}")
            if attempt < 2:
                time.sleep(2)
    
    return None

def check_ffmpeg_available() -> bool:
    """Check if ffmpeg is available in PATH."""
    try:
        result = subprocess.run(
            ["ffmpeg", "-version"],
            capture_output=True,
            timeout=5
        )
        return result.returncode == 0
    except:
        return False

FFMPEG_AVAILABLE = None  # Will be set on first check

def post_process_audio(input_path: Path, output_path: Path) -> bool:
    """
    Post-process audio with ffmpeg if available.
    Otherwise, just copy the raw file.
    """
    global FFMPEG_AVAILABLE
    
    if FFMPEG_AVAILABLE is None:
        FFMPEG_AVAILABLE = check_ffmpeg_available()
        if not FFMPEG_AVAILABLE:
            print("   [INFO] ffmpeg not found - using raw audio files")
    
    if not FFMPEG_AVAILABLE:
        # Just use the raw file as-is (already MP3 from ElevenLabs)
        import shutil
        try:
            shutil.copy(input_path, output_path)
            return output_path.exists()
        except Exception as e:
            print(f"   Copy failed: {e}")
            return False
    
    try:
        # Build ffmpeg command
        cmd = [
            "ffmpeg", "-y", "-i", str(input_path),
            # Audio filters
            "-af", ",".join([
                # Remove silence at start/end
                "silenceremove=start_periods=1:start_silence=0.01:start_threshold=-50dB",
                "areverse",
                "silenceremove=start_periods=1:start_silence=0.01:start_threshold=-50dB", 
                "areverse",
                # Normalize to -1dB peak
                "loudnorm=I=-16:LRA=11:TP=-1",
                # Add 10ms fade in/out to prevent clicks
                "afade=t=in:st=0:d=0.01",
                "afade=t=out:st=-0.01:d=0.01"
            ]),
            # Output format
            "-ar", str(TARGET_SAMPLE_RATE),
            "-ac", str(TARGET_CHANNELS),
            "-sample_fmt", "s16",
            "-c:a", "pcm_s16le",
            str(output_path)
        ]
        
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=30
        )
        
        if result.returncode == 0 and output_path.exists():
            return True
        else:
            print(f"   ffmpeg error: {result.stderr[:200] if result.stderr else 'Unknown'}")
            return False
            
    except subprocess.TimeoutExpired:
        print("   ffmpeg timeout")
        return False
    except Exception as e:
        print(f"   Post-processing failed: {e}")
        return False

def analyze_audio_quality(file_path: Path) -> dict:
    """Analyze audio file for quality metrics."""
    try:
        import wave
        with wave.open(str(file_path), 'rb') as wav:
            frames = wav.getnframes()
            rate = wav.getframerate()
            width = wav.getsampwidth()
            
            if frames == 0:
                return {"valid": False, "reason": "empty"}
            
            # Read samples
            raw = wav.readframes(min(frames, rate * 5))
            sample_count = len(raw) // width
            
            if width == 2 and sample_count > 0:
                samples = struct.unpack(f"<{sample_count}h", raw)
                
                # Calculate metrics
                max_amp = max(abs(s) for s in samples)
                sum_sq = sum(s*s for s in samples)
                rms = math.sqrt(sum_sq / sample_count)
                
                peak_db = 20 * math.log10(max_amp / 32768.0) if max_amp > 0 else -99
                rms_db = 20 * math.log10(rms / 32768.0) if rms > 0 else -99
                
                return {
                    "valid": True,
                    "duration": frames / rate,
                    "peak_db": peak_db,
                    "rms_db": rms_db,
                    "is_silent": rms_db < -50,
                    "is_clipping": peak_db > -0.5
                }
                
    except Exception as e:
        return {"valid": False, "reason": str(e)}
    
    return {"valid": False, "reason": "unknown"}

def generate_single_asset(category: str, name: str, prompt: str, variation: int = 0) -> bool:
    """Generate a single audio asset."""
    global FFMPEG_AVAILABLE
    
    # Check ffmpeg once
    if FFMPEG_AVAILABLE is None:
        FFMPEG_AVAILABLE = check_ffmpeg_available()
    
    # Build filename - use .mp3 if no ffmpeg, .wav if ffmpeg available
    suffix = f"_{variation:02d}" if variation > 0 else ""
    ext = ".wav" if FFMPEG_AVAILABLE else ".mp3"
    filename = f"{name}{suffix}{ext}"
    
    # Build output path
    output_dir = OUTPUT_DIR / category
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / filename
    
    # Skip if exists
    if output_path.exists() and output_path.stat().st_size > 1000:
        print(f"   [SKIP] {filename} exists")
        return True
    
    print(f"   Generating {filename}...")
    
    # Generate audio
    audio_data = generate_elevenlabs_sfx(prompt, duration_seconds=2.0)
    
    if not audio_data:
        print(f"   [FAIL] API returned no data")
        return False
    
    if len(audio_data) < 1000:
        print(f"   [FAIL] Audio data too small ({len(audio_data)} bytes)")
        return False
    
    if FFMPEG_AVAILABLE:
        # Save raw audio temporarily and post-process
        temp_path = output_path.with_suffix(".tmp.mp3")
        temp_path.write_bytes(audio_data)
        
        # Post-process
        success = post_process_audio(temp_path, output_path)
        
        # Cleanup temp
        if temp_path.exists():
            temp_path.unlink()
        
        if not success:
            print(f"   [FAIL] Post-processing failed")
            return False
    else:
        # Save raw MP3 directly
        output_path.write_bytes(audio_data)
    
    # Verify file was created
    if not output_path.exists() or output_path.stat().st_size < 1000:
        print(f"   [FAIL] Output file invalid")
        return False
    
    print(f"   [OK] {filename} ({output_path.stat().st_size / 1024:.1f} KB)")
    return True

def run_generation():
    """Main generation loop."""
    print("=" * 60)
    print("SPELLLOOP AUDIO GENERATOR")
    print("=" * 60)
    
    # Check prerequisites
    if not check_api_keys():
        return False
    
    # Load manifest
    if not MANIFEST_PATH.exists():
        print(f"ERROR: Manifest not found: {MANIFEST_PATH}")
        return False
    
    with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
        manifest = json.load(f)
    
    print(f"Loaded {len(manifest)} asset definitions")
    print(f"Output directory: {OUTPUT_DIR}")
    print("-" * 60)
    
    # Stats
    total = 0
    success = 0
    failed = 0
    skipped = 0
    
    # Process each asset
    for item in manifest:
        category = item["category"]
        name = item["name"]
        prompt = item["prompt"]
        variations = item.get("variations", 1)
        
        print(f"\n[{category}] {name} ({variations} variations)")
        
        for v in range(variations):
            total += 1
            var_num = v + 1 if variations > 1 else 0
            
            result = generate_single_asset(category, name, prompt, var_num)
            
            if result:
                success += 1
            else:
                failed += 1
            
            # Rate limiting - be nice to the API
            if result:
                time.sleep(0.5)
            else:
                time.sleep(1)
    
    # Summary
    print("\n" + "=" * 60)
    print("GENERATION COMPLETE")
    print("=" * 60)
    print(f"Total assets:    {total}")
    print(f"Success:         {success}")
    print(f"Failed:          {failed}")
    print(f"Success rate:    {100*success/total:.1f}%" if total > 0 else "N/A")
    
    return failed == 0

if __name__ == "__main__":
    import sys
    success = run_generation()
    sys.exit(0 if success else 1)
