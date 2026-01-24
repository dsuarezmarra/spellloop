#!/usr/bin/env python3
"""
Music Generator
Generates background music loops for the game.
"""

import os
import time
import subprocess
from pathlib import Path
from dotenv import load_dotenv
import requests

load_dotenv()

ELEVENLABS_API_KEY = os.getenv("ELEVENLABS_API_KEY")
ELEVENLABS_SFX_URL = "https://api.elevenlabs.io/v1/sound-generation"

PROJECT_ROOT = Path(__file__).parent.parent
OUTPUT_DIR = PROJECT_ROOT / "project" / "audio" / "music"

MUSIC_TRACKS = {
    "music_intro_theme": {
        "prompt": "Fantasy game title screen music, magical, mysterious, orchestral, harp and strings, loopable, adventure start",
        "category": "menu"
    },
    "music_gameplay_loop": {
        "prompt": "Action game background music, fast paced, rhythmic, survival mode, electronic orchestral hybrid, looping, energetic",
        "category": "gameplay"
    },
    "music_boss_theme": {
        "prompt": "Boss battle music, epic, intense, dramatic, heavy percussion, orchestral, dangerous, fast tempo, looping",
        "category": "bosses"
    }
}

def generate_elevenlabs_music(prompt: str, duration_seconds: float = 22.0) -> bytes | None:
    headers = {
        "xi-api-key": ELEVENLABS_API_KEY,
        "Content-Type": "application/json"
    }
    
    payload = {
        "text": prompt,
        "duration_seconds": duration_seconds, 
        "prompt_influence": 0.5
    }
    
    for attempt in range(2):
        try:
            response = requests.post(
                ELEVENLABS_SFX_URL,
                headers=headers,
                json=payload,
                timeout=90
            )
            
            if response.status_code == 200:
                print(f"  Generated {len(response.content)} bytes")
                return response.content
            elif response.status_code == 429:
                print("  Rate limited, waiting...")
                time.sleep(5)
            else:
                print(f"   API error {response.status_code}: {response.text[:100]}")
        except Exception as e:
            print(f"   Request failed: {e}")
            
    return None

def post_process_music(input_path: Path, output_path: Path) -> bool:
    """Convert to MP3/OGG and normalize for music (softer than SFX)."""
    # Music target: -14 LUFS (Spotify standard) or lower for BG
    try:
        cmd = [
            "ffmpeg", "-y",
            "-i", str(input_path),
            "-ar", "44100",
            "-ac", "2",
            "-af", "loudnorm=I=-14:TP=-1.5:LRA=11,fade=t=in:st=0:d=1,fade=t=out:st=20:d=2", # Fade edges for looping safety
            str(output_path)
        ]
        result = subprocess.run(cmd, capture_output=True, timeout=30)
        return result.returncode == 0 and output_path.exists()
    except Exception as e:
        print(f"  FFmpeg error: {e}")
        return False

def generate_music():
    if not ELEVENLABS_API_KEY:
        print("Error: No API Key")
        return

    print(f"Generating {len(MUSIC_TRACKS)} music tracks...")
    
    for track_id, data in MUSIC_TRACKS.items():
        category = data["category"]
        prompt = data["prompt"]
        
        target_dir = OUTPUT_DIR / category
        target_dir.mkdir(parents=True, exist_ok=True)
        
        output_file = target_dir / f"{track_id}.mp3" # Use MP3 for music compatibility
        
        print(f"[{track_id}]")
        if output_file.exists():
             print("  Skip (Exists)")
             continue
             
        audio_data = generate_elevenlabs_music(prompt, 22.0)
        if audio_data:
            temp_path = output_file.with_suffix(".temp.mp3")
            temp_path.write_bytes(audio_data)
            
            if post_process_music(temp_path, output_file):
                print("  Success")
                temp_path.unlink()
            else:
                print("  Convert failed, keeping temp")
                # Keep temp as fallback if ffmpeg fails
                temp_path.rename(output_file)
        else:
            print("  Gen failed")
            
        time.sleep(2)

if __name__ == "__main__":
    generate_music()
