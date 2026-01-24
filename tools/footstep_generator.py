#!/usr/bin/env python3
"""
Footstep Sound Generator
Generates essential footstep sounds for different biomes.
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
OUTPUT_DIR = PROJECT_ROOT / "project" / "audio" / "sfx" / "gameplay"

FOOTSTEP_SOUNDS = {
    "sfx_footstep_grass": "footsteps on grass, soft rustle, walking on lawn, nature sound, short distinct step",
    "sfx_footstep_stone": "footsteps on stone, hard concrete step, dungeon floor walking, solid impact, short distinct step",
    "sfx_footstep_sand": "footsteps on sand, gritty crunch, desert walking, soft ground impact, short distinct step",
    "sfx_footstep_snow": "footsteps on snow, cold crunch, winter walking, compressed snow sound, short distinct step"
}

def generate_elevenlabs_sfx(prompt: str, duration_seconds: float = 1.0) -> bytes | None:
    headers = {
        "xi-api-key": ELEVENLABS_API_KEY,
        "Content-Type": "application/json"
    }
    
    payload = {
        "text": prompt,
        "duration_seconds": duration_seconds, 
        "prompt_influence": 0.4
    }
    
    for attempt in range(2):
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
                time.sleep(5)
            else:
                print(f"   API error {response.status_code}: {response.text[:100]}")
        except Exception as e:
            print(f"   Request failed: {e}")
            
    return None

def post_process_audio(input_path: Path, output_path: Path) -> bool:
    """Convert to OGG and normalize, trimming to be very short."""
    try:
        cmd = [
            "ffmpeg", "-y",
            "-i", str(input_path),
            "-ar", "48000",
            "-ac", "1",
            "-c:a", "libvorbis",
            "-q:a", "4",
            "-af", "silenceremove=start_periods=1:start_duration=0:start_threshold=-50dB,areverse,silenceremove=start_periods=1:start_duration=0:start_threshold=-50dB,areverse,loudnorm=I=-20:TP=-1.5:LRA=7",
            str(output_path)
        ]
        result = subprocess.run(cmd, capture_output=True, timeout=10)
        return result.returncode == 0 and output_path.exists()
    except:
        return False

def generate_footsteps():
    if not ELEVENLABS_API_KEY:
        print("Error: No API Key")
        return

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    
    print(f"Generating {len(FOOTSTEP_SOUNDS)} footstep types...")
    
    for sfx_id, prompt in FOOTSTEP_SOUNDS.items():
        print(f"[{sfx_id}]")
        output_file = OUTPUT_DIR / f"{sfx_id}.ogg"
        
        if output_file.exists():
             print("  Skip (Exists)")
             continue
             
        audio_data = generate_elevenlabs_sfx(prompt, 1.5) # Generate slightly longer then trim
        if audio_data:
            temp_path = output_file.with_suffix(".mp3")
            temp_path.write_bytes(audio_data)
            
            if post_process_audio(temp_path, output_file):
                print("  Success")
                temp_path.unlink()
            else:
                print("  Convert failed")
        else:
            print("  Gen failed")
            
        time.sleep(1)

if __name__ == "__main__":
    generate_footsteps()
