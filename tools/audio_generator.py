import os
import json
import time
import requests
import subprocess
import logging
import argparse
from pathlib import Path
from dotenv import load_dotenv

# Setup Logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Load environment variables
load_dotenv()

STABLE_AUDIO_API_KEY = os.getenv("STABLE_AUDIO_API_KEY")
ELEVENLABS_API_KEY = os.getenv("ELEVENLABS_API_KEY")

# API Endpoints
STABLE_AUDIO_URL = "https://api.stability.ai/v2beta/stable-audio/generate" # Updated for sk- keys
ELEVENLABS_SFX_URL = "https://api.elevenlabs.io/v1/sound-generation"
ELEVENLABS_TTS_URL = "https://api.elevenlabs.io/v1/text-to-speech"

OUTPUT_DIR = Path("project/audio")

def generate_elevenlabs_sfx(prompt, duration_seconds=2.0):
    """Generate SFX using ElevenLabs API"""
    if not ELEVENLABS_API_KEY:
        logging.error("Missing ELEVENLABS_API_KEY")
        return None

    headers = {
        "xi-api-key": ELEVENLABS_API_KEY,
        "Content-Type": "application/json"
    }
    
    payload = {
        "text": prompt,
        "duration_seconds": min(max(0.5, duration_seconds), 22.0),
        "prompt_influence": 0.5
    }

    try:
        response = requests.post(ELEVENLABS_SFX_URL, headers=headers, json=payload)
        if response.status_code == 200:
            return response.content
        else:
            logging.error(f"ElevenLabs SFX Error {response.status_code}: {response.text}")
            return None
    except Exception as e:
        logging.error(f"ElevenLabs Exception: {e}")
        return None

def generate_stable_audio(prompt, duration_seconds=2.0):
    """Generate Audio using Stability AI V2 API"""
    if not STABLE_AUDIO_API_KEY:
        logging.error("Missing STABLE_AUDIO_API_KEY")
        return None

    # V2 API uses multipart/form-data usually, or correct headers for JSON
    headers = {
        "Authorization": f"Bearer {STABLE_AUDIO_API_KEY}",
        "Accept": "audio/*" 
    }

    # Using json body for V2beta is supported for text-to-audio
    # Note: V2beta requires 'prompt' and 'seconds_total'
    payload = {
        "prompt": prompt,
        "seconds_total": int(duration_seconds) if duration_seconds > 1 else 1, # Must be int often in V2? Checking doc.. keep float safe or int
        "steps": 25,
        "output_format": "mp3" # V2 API often returns mp3 by default, we request what we can
    }
    
    # Actually, robust V2 implementation uses multipart data usually
    # Let's try JSON first as it's cleaner, if fail, switch to multipart
    
    try:
        # Important: Stability API expects multipart for some endpoints, but let's try standard JSON post first
        # Double check: Stable Audio Core is `https://api.stability.ai/v2beta/stable-audio/generate`
        # It accepts JSON.
        
        response = requests.post(
            STABLE_AUDIO_URL, 
            headers={"Authorization": f"Bearer {STABLE_AUDIO_API_KEY}", "Accept": "audio/*"}, 
            json=payload
        )
        
        if response.status_code == 200:
            return response.content
        else:
            logging.error(f"Stable Audio Error {response.status_code}: {response.text}")
            return None

    except Exception as e:
        logging.error(f"Stable Audio Exception: {e}")
        return None

def main():
    print("=======================================")
    print("   SPELLLOOP AUDIO PIPELINE EXECUTION")
    print("=======================================")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--only-missing", type=str, help="Path to missing assets manifest")
    args = parser.parse_args()

    print("=======================================")
    print("   SPELLLOOP AUDIO PIPELINE EXECUTION")
    print("=======================================")

    if not STABLE_AUDIO_API_KEY and not ELEVENLABS_API_KEY:
        print("❌ CRITICAL: No API Keys found in .env")
        print("   Please create a file at: c:\\git\\spellloop\\.env")
        print("   Add lines: STABLE_AUDIO_API_KEY=... and ELEVENLABS_API_KEY=...")
        return

    # Load Manifest
    if args.only_missing:
        manifest_path = Path(args.only_missing)
        print(f"🔧 RESUME MODE: Loading missing assets from {manifest_path}")
    else:
        manifest_path = Path("tools/generation_manifest.json")
    
    if not manifest_path.exists():
        print(f"❌ Manifest not found: {manifest_path}")
        return

    with open(manifest_path, "r", encoding="utf-8") as f:
        manifest = json.load(f)

    print(f"📂 Processing {len(manifest)} assets...")

    for item in manifest:
        category = item["category"]
        name = item["name"]
        prompt = item["prompt"]
        duration = item.get("duration", 2.0)
        variations = item.get("variations", 1)
        engine = item.get("engine", "stable_audio")

        # Create dir
        target_dir = OUTPUT_DIR / category
        target_dir.mkdir(parents=True, exist_ok=True)

        for i in range(variations):
            suffix = f"_{i+1:02d}" if variations > 1 else ""
            filename = f"{name}{suffix}.wav"
            file_path = target_dir / filename

            if file_path.exists():
                print(f"⏩ {filename} exists. Skipping.")
                continue

            # Determine prompt strategy based on previous silence?
            # If item has 'current_db' from validation export, and it's low, boost it.
            current_prompt = prompt
            if item.get("current_db", 0) < -60.0:
                print(f"   🔥 Aggressive mode active for {filename} (Prev: {item.get('current_db')} dB)")
                current_prompt += ", very loud, punchy, close-mic, strong transient, no ambient noise, not subtle, high energy arcade SFX"

            print(f"🎵 Generating {filename} [{engine}]...")
            
            # PIPELINE: Generate -> Save MP3 -> Normalize -> WAV -> Verify -> Retry?
            
            def process_generation(gen_prompt, attempt=1):
                audio_raw = None
                if engine == "elevenlabs":
                    audio_raw = generate_elevenlabs_sfx(gen_prompt, duration)
                else:
                    audio_raw = generate_stable_audio(gen_prompt, duration)
                
                if not audio_raw: return False

                # Save temp
                temp_mp3 = file_path.with_suffix(f".temp_{attempt}.mp3")
                temp_wav = file_path.with_suffix(f".temp_{attempt}.wav")
                
                with open(temp_mp3, "wb") as f:
                    f.write(audio_raw)
                
                # FFMPEG Processing: Trim + Normalize + Convert
                # silenceremove=-45dB, alimiter=-1dB
                try:
                    cmd = [
                        "ffmpeg", "-y", "-i", str(temp_mp3),
                        "-af", "silenceremove=stop_periods=-1:stop_duration=0.1:stop_threshold=-45dB:start_periods=1:start_duration=0.1:start_threshold=-45dB,alimiter=limit=-1dB",
                        "-ar", "48000", "-ac", "1", "-c:a", "pcm_s16le",
                        str(temp_wav)
                    ]
                    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    
                    # Verification: RIFF + Size
                    if temp_wav.exists() and temp_wav.stat().st_size > 44:
                        # Success: Move to final
                        if file_path.exists(): file_path.unlink()
                        temp_wav.replace(file_path)
                        if temp_mp3.exists(): temp_mp3.unlink()
                        print(f"   ✅ Saved & Processed ({file_path.stat().st_size} bytes)")
                        return True
                    else:
                        print("   ❌ Trimmed file is empty/invalid.")
                        if temp_wav.exists(): temp_wav.unlink()
                        if temp_mp3.exists(): temp_mp3.unlink()
                        return False
                        
                except Exception as e:
                    print(f"   ❌ Processing failed: {e}")
                    if temp_mp3.exists(): temp_mp3.unlink()
                    return False

            # Attempt 1
            if process_generation(current_prompt, attempt=1):
                time.sleep(0.5)
                continue
            
            # Attempt 2: Aggressive Prompt if failed (or if it was silent result? processing checks size/validity)
            # If processing returned False, it means generation failed or result was empty.
            # Retry with "punchy" prompt if not already used
            print("   ⚠️ First attempt failed. Retrying with aggressive prompt...")
            aggressive_prompt = current_prompt + ", very loud, punchy, start immediately, high impact"
            if not process_generation(aggressive_prompt, attempt=2):
                print(f"   ❌ FAILED to generate {filename} after retry.")

    print("\n🎉 BATCH COMPLETE.")

if __name__ == "__main__":
    main()
