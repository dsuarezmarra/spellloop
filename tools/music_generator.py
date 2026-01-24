#!/usr/bin/env python3
"""
Music Generator for Spellloop
Generates music loops using Stability AI's Stable Audio API.
"""

import os
import json
import time
import subprocess
from pathlib import Path
from dotenv import load_dotenv
import requests

# Load environment variables
load_dotenv()

# Configuration
STABLE_AUDIO_API_KEY = os.getenv("STABLE_AUDIO_API_KEY")
# Corrected endpoint for Stable Audio v2beta
STABLE_AUDIO_URL = "https://api.stability.ai/v2beta/audio/text-to-audio"

PROJECT_ROOT = Path(__file__).parent.parent
OUTPUT_DIR = PROJECT_ROOT / "project" / "audio" / "music"
MANIFEST_PATH = Path(__file__).parent / "music_manifest.json"

# Music specifications - magical anime roguelike aesthetic
MUSIC_ASSETS = {
    "music_menu": {
        "prompt": "Epic orchestral fantasy menu music, magical anime style, mystical atmosphere, soft chimes, ethereal choir, sweeping strings, 120 BPM, loop ready",
        "duration": 60.0,
        "output_file": "music_menu_01.ogg"
    },
    "music_gameplay_zone1": {
        "prompt": "Action fantasy battle music, fast-paced arcade combat, magical anime roguelike, energetic drums, heroic brass, 140 BPM, intense but fun, loop ready",
        "duration": 90.0,
        "output_file": "music_gameplay_zone1_01.ogg"
    },
    "music_gameplay_zone2": {
        "prompt": "Dark forest combat music, mysterious and action-packed, fantasy adventure, tribal drums, haunting flutes, 130 BPM, loop ready",
        "duration": 90.0,
        "output_file": "music_gameplay_zone2_01.ogg"
    },
    "music_gameplay_zone3": {
        "prompt": "Ice realm combat music, epic and cold, crystalline sounds, powerful drums, sweeping strings, orchestral fantasy action, 135 BPM, loop ready",
        "duration": 90.0,
        "output_file": "music_gameplay_zone3_01.ogg"
    },
    "music_boss": {
        "prompt": "Epic boss battle music, intense dramatic orchestral, heavy drums, choir chants, dark fantasy anime style, climactic and powerful, 150 BPM, loop ready",
        "duration": 90.0,
        "output_file": "music_boss_01.ogg"
    },
    "music_victory": {
        "prompt": "Victory fanfare, triumphant orchestral celebration, magical sparkles, heroic brass, joyful and satisfying, short fanfare",
        "duration": 8.0,
        "output_file": "music_victory_01.ogg"
    },
    "music_gameover": {
        "prompt": "Game over music, sad but hopeful orchestral piece, soft piano, gentle strings, melancholic fantasy, short piece",
        "duration": 10.0,
        "output_file": "music_gameover_01.ogg"
    }
}

def check_api_key():
    """Verify API key is present."""
    if not STABLE_AUDIO_API_KEY:
        print("ERROR: STABLE_AUDIO_API_KEY not found in .env")
        print(f"Please add your API key to: {PROJECT_ROOT / '.env'}")
        return False
    print(f"[OK] Stable Audio API key found: {STABLE_AUDIO_API_KEY[:10]}...")
    return True

def generate_stable_audio(prompt: str, duration_seconds: float = 60.0) -> bytes | None:
    """Generate music using Stability AI Stable Audio API v2beta."""
    headers = {
        "Authorization": f"Bearer {STABLE_AUDIO_API_KEY}",
        "Accept": "audio/*"
    }
    
    # Multipart form data for v2beta API
    files = {
        "prompt": (None, prompt),
        "duration": (None, str(min(duration_seconds, 180.0))),
        "output_format": (None, "mp3")
    }
    
    for attempt in range(3):
        try:
            print(f"   Calling Stable Audio API (attempt {attempt + 1})...")
            response = requests.post(
                STABLE_AUDIO_URL,
                headers=headers,
                files=files,
                timeout=180  # Long timeout for music generation
            )
            
            if response.status_code == 200:
                return response.content
            elif response.status_code == 429:
                wait_time = 30 * (attempt + 1)
                print(f"   Rate limited. Waiting {wait_time}s...")
                time.sleep(wait_time)
            elif response.status_code == 401:
                print(f"   Authentication error: {response.text[:200]}")
                return None
            else:
                print(f"   API error {response.status_code}: {response.text[:200]}")
                if attempt < 2:
                    time.sleep(5)
                    
        except Exception as e:
            print(f"   Request failed: {e}")
            if attempt < 2:
                time.sleep(5)
    
    return None

def convert_to_ogg(input_path: Path, output_path: Path) -> bool:
    """Convert audio to OGG Vorbis 48kHz stereo."""
    try:
        cmd = [
            "ffmpeg", "-y",
            "-i", str(input_path),
            "-ar", "48000",
            "-ac", "2",  # Stereo for music
            "-c:a", "libvorbis",
            "-q:a", "6",  # Good quality
            "-af", "loudnorm=I=-14:TP=-1:LRA=11",  # Music LUFS target
            str(output_path)
        ]
        
        result = subprocess.run(cmd, capture_output=True, timeout=60)
        return result.returncode == 0 and output_path.exists()
    except Exception as e:
        print(f"   Conversion failed: {e}")
        return False

def generate_music_asset(asset_id: str, config: dict) -> bool:
    """Generate a single music asset."""
    output_path = OUTPUT_DIR / config["output_file"]
    
    # Skip if already exists
    if output_path.exists() and output_path.stat().st_size > 10000:
        print(f"   [SKIP] Already exists: {output_path.name}")
        return True
    
    print(f"   Generating: {asset_id}")
    print(f"   Prompt: {config['prompt'][:80]}...")
    
    # Generate audio
    audio_data = generate_stable_audio(config["prompt"], config["duration"])
    
    if not audio_data:
        print(f"   [FAIL] Generation failed for {asset_id}")
        return False
    
    # Save raw MP3 first
    temp_path = output_path.with_suffix(".mp3")
    temp_path.parent.mkdir(parents=True, exist_ok=True)
    temp_path.write_bytes(audio_data)
    print(f"   [OK] Raw audio saved: {temp_path.name} ({len(audio_data)} bytes)")
    
    # Convert to OGG if output should be OGG
    if config["output_file"].endswith(".ogg"):
        if convert_to_ogg(temp_path, output_path):
            temp_path.unlink()  # Remove temp MP3
            print(f"   [OK] Converted to OGG: {output_path.name}")
            return True
        else:
            # Keep MP3 as fallback
            output_path = temp_path
            print(f"   [WARN] Kept as MP3: {output_path.name}")
            return True
    
    return True

def main():
    """Main entry point."""
    print("=" * 60)
    print("SPELLLOOP MUSIC GENERATOR")
    print("Using Stability AI Stable Audio API")
    print("=" * 60)
    
    if not check_api_key():
        return
    
    # Create output directory
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    
    # Generate all music assets
    success_count = 0
    fail_count = 0
    
    for asset_id, config in MUSIC_ASSETS.items():
        print(f"\n[{asset_id}]")
        if generate_music_asset(asset_id, config):
            success_count += 1
        else:
            fail_count += 1
        
        # Rate limiting pause
        time.sleep(2)
    
    print("\n" + "=" * 60)
    print(f"MUSIC GENERATION COMPLETE")
    print(f"  Success: {success_count}")
    print(f"  Failed:  {fail_count}")
    print("=" * 60)

if __name__ == "__main__":
    main()
