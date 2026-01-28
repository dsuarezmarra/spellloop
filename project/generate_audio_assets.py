import os
import json
import urllib.request
import urllib.error
import time
import sys

# API KEYS
ELEVENLABS_API_KEY = "f930a72409d436749fdda7d6e1dd1d3fd0bb97205ffcc2af9acff6ade983a8ce"
STABLE_AUDIO_API_KEY = "sk-Wcc1CeV6cmAFg04Ei9p7omRzqVCJLF6T5ddbmglrPWt4EEnN"

# PATHS
PROJECT_ROOT = "c:/git/spellloop/project"
SFX_DIR = os.path.join(PROJECT_ROOT, "audio/sfx/coins")
MUSIC_DIR = os.path.join(PROJECT_ROOT, "audio/music/gameplay")

def ensure_dir(path):
    if not os.path.exists(path):
        os.makedirs(path)

def generate_elevenlabs_sfx():
    print("Generating Coin SFX with ElevenLabs...")
    url = "https://api.elevenlabs.io/v1/sound-generation"
    headers = {
        "xi-api-key": ELEVENLABS_API_KEY,
        "Content-Type": "application/json"
    }
    data = {
        "text": "Retro 8-bit video game coin pickup sound, high pitched chime, super mario style, magical, shiny",
        "duration_seconds": 1.0,
        "prompt_influence": 0.5
    }
    
    try:
        req = urllib.request.Request(url, data=json.dumps(data).encode('utf-8'), headers=headers, method='POST')
        with urllib.request.urlopen(req) as response:
            if response.status == 200:
                audio_data = response.read()
                output_path = os.path.join(SFX_DIR, "sfx_coin_pickup.mp3")
                ensure_dir(SFX_DIR)
                with open(output_path, "wb") as f:
                    f.write(audio_data)
                print(f"Success! Saved to {output_path}")
            else:
                print(f"Error: {response.status} - {response.reason}")
    except Exception as e:
        print(f"ElevenLabs Failed: {e}")

def generate_stable_audio_track(prompt, output_filename):
    print(f"Generating Music Track '{output_filename}' with Stable Audio...")
    url = "https://api.stability.ai/v2beta/audio/generate"
    
    # Multipart form data construction is complex with urllib.
    # We will use a boundary for multipart.
    boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW'
    headers = {
        "Authorization": f"Bearer {STABLE_AUDIO_API_KEY}",
        "Content-Type": f"multipart/form-data; boundary={boundary}",
        "Accept": "audio/*" 
    }
    
    # Prompt fields
    fields = {
        "prompt": prompt,
        "seconds_total": "90", # 1.5 mins loop
        "steps": "20", # Default is mostly fine
        "output_format": "mp3"
    }
    
    # Build body
    body = []
    for key, value in fields.items():
        body.append(f'--{boundary}')
        body.append(f'Content-Disposition: form-data; name="{key}"')
        body.append('')
        body.append(str(value))
    
    body.append(f'--{boundary}--')
    body.append('')
    body_str = '\r\n'.join(body)
    
    try:
        req = urllib.request.Request(url, data=body_str.encode('utf-8'), headers=headers, method='POST')
        with urllib.request.urlopen(req) as response:
            if response.status == 200:
                 # Check if JSON or Audio
                content_type = response.headers.get('Content-Type')
                if 'application/json' in content_type:
                    # Parse JSON to find seed or error, but wait, usually it returns binary for audio?
                    # The v2beta/audio/generate returns binary if Accept is audio/*
                    # But Stability API sometimes returns { "finish_reason": "SUCCESS", "seed": ... } with "video" (base64) for video.
                    # For audio, documentation says "Returns the generated audio file".
                    audio_data = response.read()
                    output_path = os.path.join(MUSIC_DIR, output_filename)
                    ensure_dir(MUSIC_DIR)
                    with open(output_path, "wb") as f:
                        f.write(audio_data)
                    print(f"Success! Saved to {output_path}")
                else:
                    audio_data = response.read()
                    output_path = os.path.join(MUSIC_DIR, output_filename)
                    ensure_dir(MUSIC_DIR)
                    with open(output_path, "wb") as f:
                        f.write(audio_data)
                    print(f"Success! Saved to {output_path}")
            else:
                 print(f"Error: {response.status} - {response.reason}")
                 print(response.read())

    except urllib.error.HTTPError as e:
        print(f"Stable Audio Failed: {e.code} - {e.reason}")
        print(e.read())
    except Exception as e:
        print(f"Stable Audio Error: {e}")

def main():
    # 1. Coin SFX
    generate_elevenlabs_sfx()
    
    # 2. Music Tracks
    prompts = [
        ("Action roguelike gameplay music, fast paced, electronic orchestral hybrid, magical, intense, vampire survivors style, loopable", "music_gameplay_var1.mp3"),
        ("Dark fantasy survival music, ominous, synthesizer, driving drums, epic, retro game style, intense, loopable", "music_gameplay_var2.mp3"),
        ("High energy arcade battle music, chiptune influence, orchestral hits, fast tempo, exciting, magical, loopable", "music_gameplay_var3.mp3"),
        ("Ethereal magical combat music, mysterious, crystal sounds, driving bassline, electronic, epic, loopable", "music_gameplay_var4.mp3")
    ]
    
    for prompt, filename in prompts:
        generate_stable_audio_track(prompt, filename)
        time.sleep(2) # be nice to rate limits

if __name__ == "__main__":
    main()
