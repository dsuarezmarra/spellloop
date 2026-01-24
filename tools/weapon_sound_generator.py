#!/usr/bin/env python3
"""
Weapon Sound Generator for Spellloop
Generates unique cast sounds for each weapon using ElevenLabs API.
"""

import os
import json
import time
import subprocess
from pathlib import Path
from dotenv import load_dotenv
import requests

load_dotenv()

ELEVENLABS_API_KEY = os.getenv("ELEVENLABS_API_KEY")
ELEVENLABS_SFX_URL = "https://api.elevenlabs.io/v1/sound-generation"

PROJECT_ROOT = Path(__file__).parent.parent
OUTPUT_DIR = PROJECT_ROOT / "project" / "audio" / "sfx" / "weapons"

# 10 Base Weapons + 45 Fusions = 55 unique weapon sounds
WEAPON_SOUNDS = {
    # ═══════════════════════════════════════════════════════════════════════════════
    # 10 BASE WEAPONS
    # ═══════════════════════════════════════════════════════════════════════════════
    "sfx_weapon_fire_wand": "magical fantasy game projectile sound, fiery whoosh, flame crackle cast, warm explosive launch, arcade game, short impactful",
    "sfx_weapon_ice_wand": "magical fantasy game projectile sound, frosty crystalline launch, ice shard cast, cold whoosh, winter magic, arcade game, short impactful",
    "sfx_weapon_lightning_wand": "magical fantasy game projectile sound, electric zap cast, thunder crackle launch, sparking energy, storm magic, arcade game, short impactful",
    "sfx_weapon_arcane_orb": "magical fantasy game projectile sound, mystical orb summon, purple energy swirl, ethereal magic cast, arcade game, short impactful",
    "sfx_weapon_shadow_dagger": "magical fantasy game projectile sound, dark whisper throw, shadow blade swoosh, stealthy magical launch, arcade game, short impactful",
    "sfx_weapon_nature_staff": "magical fantasy game projectile sound, leafy nature whoosh, vine growth cast, organic magical launch, forest magic, arcade game, short impactful",
    "sfx_weapon_wind_blade": "magical fantasy game projectile sound, gusty air slash, wind cutter whoosh, breezy magical launch, arcade game, short impactful",
    "sfx_weapon_earth_spike": "magical fantasy game projectile sound, rocky rumble summon, stone emergence, ground breaking magic cast, arcade game, short impactful",
    "sfx_weapon_light_beam": "magical fantasy game projectile sound, radiant light beam, holy energy cast, bright divine launch, arcade game, short impactful",
    "sfx_weapon_void_pulse": "magical fantasy game projectile sound, void energy surge, dark matter pulse, cosmic distortion cast, arcade game, short impactful",
    
    # ═══════════════════════════════════════════════════════════════════════════════
    # 45 FUSION WEAPONS
    # ═══════════════════════════════════════════════════════════════════════════════
    "sfx_weapon_steam_cannon": "magical fantasy game projectile sound, steam explosion launch, pressurized vapor blast, industrial magic cast, arcade game, powerful short",
    "sfx_weapon_storm_caller": "magical fantasy game projectile sound, thunder storm summon, wind and lightning combined, tempest magic cast, arcade game, powerful short",
    "sfx_weapon_soul_reaper": "magical fantasy game projectile sound, ghostly scythe swing, soul extraction dark magic, spectral launch, arcade game, eerie short",
    "sfx_weapon_cosmic_barrier": "magical fantasy game projectile sound, cosmic energy shield, starlight orb summon, celestial protection cast, arcade game, mystical short",
    "sfx_weapon_rift_quake": "magical fantasy game projectile sound, dimensional earthquake, void rift opening, reality tear cast, arcade game, powerful short",
    "sfx_weapon_frostvine": "magical fantasy game projectile sound, ice and nature combined, frozen vine growth, frosty plant magic cast, arcade game, organic short",
    "sfx_weapon_hellfire": "magical fantasy game projectile sound, dark flame ignition, demonic fire launch, infernal shadow cast, arcade game, sinister short",
    "sfx_weapon_thunder_spear": "magical fantasy game projectile sound, divine lightning javelin, holy thunder throw, zeus-like cast, arcade game, powerful short",
    "sfx_weapon_void_storm": "magical fantasy game projectile sound, void tornado summon, dark wind vortex, cosmic storm cast, arcade game, ominous short",
    "sfx_weapon_crystal_guardian": "magical fantasy game projectile sound, crystal formation, gem barrier summon, protective stone magic, arcade game, shimmering short",
    "sfx_weapon_frozen_thunder": "magical fantasy game projectile sound, ice lightning hybrid, frozen electric bolt, arctic storm cast, arcade game, crackling short",
    "sfx_weapon_frost_orb": "magical fantasy game projectile sound, icy orb summon, frozen sphere launch, cold magical orbit, arcade game, crystalline short",
    "sfx_weapon_frostbite": "magical fantasy game projectile sound, ice dagger throw, frozen shadow blade, biting cold cast, arcade game, sharp short",
    "sfx_weapon_blizzard": "magical fantasy game projectile sound, snowstorm launch, icy wind blast, winter tempest cast, arcade game, howling short",
    "sfx_weapon_glacier": "magical fantasy game projectile sound, massive ice formation, frozen pillar summon, arctic magic cast, arcade game, deep short",
    "sfx_weapon_aurora": "magical fantasy game projectile sound, northern lights beam, rainbow ice ray, beautiful cold cast, arcade game, ethereal short",
    "sfx_weapon_absolute_zero": "magical fantasy game projectile sound, ultimate freeze pulse, time-stopping cold, absolute cold cast, arcade game, intense short",
    "sfx_weapon_plasma": "magical fantasy game projectile sound, superheated plasma bolt, fire lightning fusion, sci-fi magic cast, arcade game, sizzling short",
    "sfx_weapon_inferno_orb": "magical fantasy game projectile sound, flaming orb summon, fire sphere orbit, burning magical cast, arcade game, crackling short",
    "sfx_weapon_wildfire": "magical fantasy game projectile sound, spreading flame launch, living fire magic, nature fire cast, arcade game, wild short",
    "sfx_weapon_firestorm": "magical fantasy game projectile sound, fire tornado summon, flame tempest launch, burning wind cast, arcade game, roaring short",
    "sfx_weapon_volcano": "magical fantasy game projectile sound, volcanic eruption, magma burst summon, lava magic cast, arcade game, explosive short",
    "sfx_weapon_solar_flare": "magical fantasy game projectile sound, sun beam launch, solar explosion, blazing holy cast, arcade game, brilliant short",
    "sfx_weapon_dark_flame": "magical fantasy game projectile sound, void fire ignition, dark burning launch, shadow flame cast, arcade game, sinister short",
    "sfx_weapon_arcane_storm": "magical fantasy game projectile sound, magical lightning orbs, purple electric summon, mystic storm cast, arcade game, crackling short",
    "sfx_weapon_dark_lightning": "magical fantasy game projectile sound, shadow thunder bolt, dark electric dagger, corrupted storm cast, arcade game, menacing short",
    "sfx_weapon_thunder_bloom": "magical fantasy game projectile sound, nature lightning hybrid, electric flower summon, storm growth cast, arcade game, lively short",
    "sfx_weapon_seismic_bolt": "magical fantasy game projectile sound, earth lightning strike, ground thunder impact, tectonic storm cast, arcade game, rumbling short",
    "sfx_weapon_void_bolt": "magical fantasy game projectile sound, void lightning chain, dark dimension bolt, cosmic electric cast, arcade game, otherworldly short",
    "sfx_weapon_shadow_orbs": "magical fantasy game projectile sound, dark sphere summon, shadow satellite orbit, spectral magic cast, arcade game, mysterious short",
    "sfx_weapon_life_orbs": "magical fantasy game projectile sound, healing orb summon, nature sphere orbit, life magic cast, arcade game, gentle short",
    "sfx_weapon_wind_orbs": "magical fantasy game projectile sound, air sphere summon, wind satellite orbit, gusty magic cast, arcade game, breezy short",
    "sfx_weapon_cosmic_void": "magical fantasy game projectile sound, space orb summon, void dimension orbit, cosmic dark cast, arcade game, deep short",
    "sfx_weapon_phantom_blade": "magical fantasy game projectile sound, ghost wind slash, spectral blade throw, ethereal cut cast, arcade game, whooshing short",
    "sfx_weapon_stone_fang": "magical fantasy game projectile sound, obsidian dagger throw, stone blade launch, earth shadow cast, arcade game, sharp short",
    "sfx_weapon_twilight": "magical fantasy game projectile sound, light shadow blade, dusk energy throw, balanced magic cast, arcade game, mystical short",
    "sfx_weapon_abyss": "magical fantasy game projectile sound, deep void dagger, abyssal darkness throw, ultimate shadow cast, arcade game, haunting short",
    "sfx_weapon_pollen_storm": "magical fantasy game projectile sound, flower wind blast, nature pollen swirl, healing wind cast, arcade game, organic short",
    "sfx_weapon_gaia": "magical fantasy game projectile sound, earth mother summon, nature stone emergence, primal earth cast, arcade game, grounding short",
    "sfx_weapon_solar_bloom": "magical fantasy game projectile sound, sun flower beam, light nature ray, photosynthesis magic cast, arcade game, brilliant short",
    "sfx_weapon_decay": "magical fantasy game projectile sound, rotting void pulse, nature corruption spread, death growth cast, arcade game, ominous short",
    "sfx_weapon_sandstorm": "magical fantasy game projectile sound, desert tornado launch, sand wind blast, arid storm cast, arcade game, gritty short",
    "sfx_weapon_prism_wind": "magical fantasy game projectile sound, rainbow wind slash, light refraction blade, colorful gust cast, arcade game, shimmering short",
    "sfx_weapon_radiant_stone": "magical fantasy game projectile sound, glowing earth pillar, light crystal emergence, holy stone cast, arcade game, brilliant short",
    "sfx_weapon_eclipse": "magical fantasy game projectile sound, sun and moon alignment, light void beam, cosmic balance cast, arcade game, powerful short"
}

def check_api_key():
    if not ELEVENLABS_API_KEY:
        print("ERROR: ELEVENLABS_API_KEY not found in .env")
        return False
    print(f"[OK] ElevenLabs API key found")
    return True

def generate_elevenlabs_sfx(prompt: str, duration_seconds: float = 2.0) -> bytes | None:
    headers = {
        "xi-api-key": ELEVENLABS_API_KEY,
        "Content-Type": "application/json"
    }
    
    payload = {
        "text": prompt,
        "duration_seconds": min(duration_seconds, 5.0),  # Keep weapon sounds short
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

def post_process_audio(input_path: Path, output_path: Path) -> bool:
    """Convert to OGG and normalize."""
    try:
        cmd = [
            "ffmpeg", "-y",
            "-i", str(input_path),
            "-ar", "48000",
            "-ac", "1",  # Mono for SFX
            "-c:a", "libvorbis",
            "-q:a", "5",
            "-af", "loudnorm=I=-18:TP=-1.5:LRA=7",
            str(output_path)
        ]
        result = subprocess.run(cmd, capture_output=True, timeout=30)
        return result.returncode == 0 and output_path.exists()
    except:
        return False

def generate_weapon_sound(sfx_id: str, prompt: str) -> bool:
    output_file = OUTPUT_DIR / f"{sfx_id}_01.ogg"
    
    # Skip if already exists
    if output_file.exists() and output_file.stat().st_size > 1000:
        print(f"   [SKIP] Already exists: {output_file.name}")
        return True
    
    print(f"   Generating: {sfx_id}")
    
    audio_data = generate_elevenlabs_sfx(prompt, 2.0)
    if not audio_data:
        print(f"   [FAIL] Generation failed for {sfx_id}")
        return False
    
    # Save raw MP3 first
    temp_path = output_file.with_suffix(".mp3")
    temp_path.parent.mkdir(parents=True, exist_ok=True)
    temp_path.write_bytes(audio_data)
    
    # Convert to OGG
    if post_process_audio(temp_path, output_file):
        temp_path.unlink()
        print(f"   [OK] Created: {output_file.name}")
        return True
    else:
        # Keep MP3 as fallback
        output_file = temp_path
        print(f"   [OK] Created (MP3): {temp_path.name}")
        return True

def main():
    print("=" * 60)
    print("SPELLLOOP WEAPON SOUND GENERATOR")
    print(f"Generating {len(WEAPON_SOUNDS)} unique weapon sounds")
    print("=" * 60)
    
    if not check_api_key():
        return
    
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    
    success_count = 0
    fail_count = 0
    
    for sfx_id, prompt in WEAPON_SOUNDS.items():
        print(f"\n[{sfx_id}]")
        if generate_weapon_sound(sfx_id, prompt):
            success_count += 1
        else:
            fail_count += 1
        
        # Rate limiting
        time.sleep(1.5)
    
    print("\n" + "=" * 60)
    print("WEAPON SOUND GENERATION COMPLETE")
    print(f"  Success: {success_count}")
    print(f"  Failed:  {fail_count}")
    print("=" * 60)

if __name__ == "__main__":
    main()
