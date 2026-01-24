import json

# Define the full asset scope
MANIFEST = []

def add_entry(category, name, prompt, engine="elevenlabs", duration=None, variations=1):
    entry = {
        "category": category,
        "name": name,
        "prompt": prompt,
        "engine": engine,
        "variations": variations
    }
    if duration:
        entry["duration"] = duration
    MANIFEST.append(entry)

# 1. GAMEPLAY FEEDBACK
gameplay_prompts = {
    "sfx_player_hurt": ("Generic low grunt, breath knocked out, anime style male voice", "elevenlabs"),
    "sfx_player_death": ("Heartbeat stopping effect, low boom, high pitched ear ringing fade, tinnitus", "elevenlabs"),
    "sfx_player_heal": ("Magical ascending chimes, holy glitter sound, divine healing, rpg potion", "elevenlabs"),
    "sfx_player_revive": ("Epic angelic choir chord, rising orchestral swell, resurrection fanfare", "elevenlabs"),
    "sfx_shield_absorb": ("Sci-fi energy deflection, metallic forcefield hum impact, shield block", "elevenlabs"),
    "sfx_shield_break": ("Shattering glass mixed with power down fizzle, energy shield broken", "elevenlabs"),
    "sfx_turret_lock": ("Heavy mechanical latching sound, hydraulic piston lock, metallic clunk", "elevenlabs"),
    "sfx_barrier_hit": ("Low frequency force field bounce, rubbery distortion, magic barrier impact", "elevenlabs")
}

for name, (prompt, engine) in gameplay_prompts.items():
    dur = 4.0 if "death" in name else 1.5
    vars = 6 if "hurt" in name else 4
    add_entry("sfx/gameplay", name, f"{prompt}, high fidelity, game sfx", engine, duration=dur, variations=vars)

# 2. STATUS LOOPS
status_loops = {
    "sfx_status_burn_loop": "Cracking fire, sizzling flesh loop, camp fire, burning texture",
    "sfx_status_poison_loop": "Boiling liquid, bubbling mud loop, acid, toxic sludge",
    "sfx_status_freeze_loop": "Ice cracking tension, cold wind whistle loop, freezing atmosphere",
    "sfx_status_curse_loop": "Eerie whispers, reverse audio reverb loop, dark magic aura"
}
for name, prompt in status_loops.items():
    add_entry("sfx/status", name, f"{prompt}, seamless loop, consistent texture", "stable_audio", duration=10.0, variations=1)

# 3. WEAPONS - BASIC ELEMENTS
elements = {
    "ice": ("High pitched ice shattering sound, sharp glass breaking", "Crunchy ice impact, freezing sound, cold snap"),
    "fire": ("Fireball whoosh, torch swing, ignition sound", "Explosion, fire crackle, scorch mark sound"),
    "lightning": ("Electric zap, tesla coil spark, high voltage snap", "Thunder crack, static discharge, electric pop"),
    "arcane": ("Magical synth chime, mana release, soft sparkle woosh", "Soft magical thud, ethereal chime, resonant ping"),
    "shadow": ("Sharp metal swish, assassin blade throw, air cut", "Wet slice, critical hit sound, fabric tearing"),
    "nature": ("Leaves rustle swish, wood creak, organic swing", "Wood crack, branch snap, organic thud"),
    "void": ("Reverse suction sound, bass pulse, dark energy release", "Deep sub bass thud, distorted reality impact")
}

for elem, (cast_p, imp_p) in elements.items():
    add_entry("sfx/weapons", f"sfx_{elem}_cast", f"{cast_p}, magical anime, game sfx", "elevenlabs", duration=1.0, variations=4)
    add_entry("sfx/weapons", f"sfx_{elem}_hit", f"{imp_p}, magical anime, game sfx", "elevenlabs", duration=1.0, variations=4)

# 4. FUSIONS (45)
fusions = {
    "steam_cannon": "Violent steam release, high pressure hiss, explosion",
    "frozen_thunder": "Cracking ice followed by an electric snap, thunder freeze",
    "frost_orb": "Ethereal synth chime with a underlying cold wind layer",
    "frostbite": "Sharp icicle stab mixed with a ghostly whisper",
    "blizzard": "Howling wind gale with sleet impact texture",
    "glacier": "Massive deep ice shift, like a glacier calving (heavy bass)",
    "aurora": "Beautiful shimmering glass veil, high frequency magical hum",
    "absolute_zero": "All sound being sucked out (reverse audio) then a freezing snap",
    "plasma_bolt": "Sci-fi energy weapon, thick superheated electric arc",
    "inferno_orb": "Burning low pad loop with magical twinkles",
    "hellfire": "Demonic roar mixed with crackling fire",
    "wildfire": "Fast spreading fire crackle, dry wood combustion",
    "firestorm": "Roaring tornado of fire, heavy wind buffeting",
    "volcano": "Deep seismic rumble + explosive lava splatter",
    "solar_flare": "Intense high pitched laser burn, Sci-fi heat beam",
    "dark_flame": "Low distorted fire, deep bass rumble, evil fire",
    "storm_caller": "Rolling thunder strike, heavy rain ambiance sting",
    "arcane_storm": "Electric zaps mixed with crystal bell chimes",
    "dark_lightning": "Distorted electric synth, glitchy digital tear",
    "thunder_bloom": "Organic wood cracking with an electric overlay",
    "seismic_bolt": "Heavy rock impact with a high pitched static discharge",
    "thunder_spear": "Sharp, instant divine thunderclap. Very loud and punchy",
    "void_bolt": "Deep bass sub-drop followed by a static pop",
    "shadow_orbs": "Spooky minor key chime, dark ambient pad",
    "soul_reaper": "Wailing ghost scream, soul draining effect",
    "crystal_guardian": "Heavy resonant crystal hum, stone grinding",
    "life_orbs": "Positive major key chime, organic bubbly sound",
    "wind_orbs": "Fast flute-like whistle, airy synth pad",
    "cosmic_barrier": "Sci-fi forcefield hum, angelic choir chord",
    "cosmic_void": "Deep space drone, pulsating low frequency signal",
    "phantom_blade": "High pitched spectral whistle, air cutting blade",
    "stone_fang": "Deep stone scrape with a dark reverb tail",
    "twilight": "Perfect harmony of a high bell and low bass drone",
    "abyss": "Terrifying deep guttural growl, abyss ambiance",
    "pollen_storm": "Soft shaker/maraca sound, swirling leaves",
    "gaia": "Deep forest movement, tree falling massive impact",
    "solar_bloom": "Photosynthesis sound, high pitched warm synth swell",
    "decay": "Wet decomposition squelch, rotting sound (gross/organic)",
    "sandstorm": "Dry sand hissing, coarse friction noise",
    "prism_wind": "Crystal glass wind chimes, light passing through prism",
    "void_storm": "Vacuum cleaner from hell, intense suction wind",
    "radiant_stone": "Heavy stone impact with a holy flash sound",
    "rift_quake": "Tearing reality sound, deep earth groan",
    "eclipse": "The Inception braaam sound. Epic, massive, final",
    "frostvine": "Ice forming rapidly on wood, freezing plant texture"
}

for name, prompt in fusions.items():
    add_entry("sfx/fusions", f"sfx_fusion_{name}", f"{prompt}, magical anime, game sfx", "elevenlabs", duration=2.5, variations=1)

# 5. UI & LEVEL UP
ui_prompts = {
    "sfx_ui_click": "Short crisp woodblock, UI click, japanese mobile game style",
    "sfx_ui_hover": "Very short high pitched soft bubble pop, subtle tick",
    "sfx_ui_confirm": "Positive chime, magical sparkle, rising pitch, ping",
    "sfx_ui_cancel": "Soft low thud, wood bonk, negative UI",
    "sfx_ui_error": "Soft round buzzer, negative sound, eh-eh",
}
for name, prompt in ui_prompts.items():
    add_entry("sfx/ui", name, prompt, "elevenlabs", duration=0.5, variations=4)

# Level Up
add_entry("sfx/ui", "sfx_slot_spin_loop", "Mechanical reel spinning loop, rapid clicking, slot machine", "elevenlabs", duration=4.0, variations=1)
add_entry("sfx/ui", "sfx_slot_stop", "Heavy metallic clunk, bell ding, slot stop", "elevenlabs", duration=0.8, variations=4)
add_entry("sfx/ui", "sfx_rarity_common", "Simple high tick, coin ping", "elevenlabs", duration=1.0, variations=3)
add_entry("sfx/ui", "sfx_rarity_legendary", "Holy choir major chord fanfare, epic reveal", "elevenlabs", duration=3.0, variations=3)

# C-Major Scale
for i in range(1, 9):
    add_entry("sfx/coins", f"sfx_streak_{i:02d}", f"Magical coin pickup chime, note {i} of C Major scale, clean sine wave", "elevenlabs", duration=1.0, variations=1)

# 6. BIOMES (Ambience + Footsteps)
biomes = ["ArcaneWastes", "Death", "Desert", "Forest", "Grassland", "Lava", "Snow"]
for bpm in biomes:
    # Ambience
    add_entry(f"sfx/footsteps/{bpm}", f"sfx_ambience_{bpm.lower()}_loop", f"Ambience loop for {bpm} biome, magical atmosphere, background noise", "stable_audio", duration=30.0, variations=1)
    # Footsteps Ground
    add_entry(f"sfx/footsteps/{bpm}", f"sfx_footstep_{bpm.lower()}_ground", f"Footstep on {bpm} ground surface, running, foley", "stable_audio", duration=0.3, variations=8)
    # Footsteps Path
    add_entry(f"sfx/footsteps/{bpm}_path", f"sfx_footstep_{bpm.lower()}_path", f"Footstep on stone path in {bpm}, hard surface, running", "stable_audio", duration=0.3, variations=8)

# 7. ENEMIES
enemy_types = ["flesh", "bone", "slime", "ghost", "armor"]
for et in enemy_types:
    add_entry("sfx/enemies", f"sfx_hit_{et}", f"Impact sound on {et} material, hit feedback, damage", "elevenlabs", duration=0.5, variations=6)
    add_entry("sfx/enemies", f"sfx_death_{et}", f"Death sound of {et} creature, collapsing, destruction", "elevenlabs", duration=1.5, variations=4)

add_entry("sfx/enemies", "sfx_enemy_spawn", "Soft poof, mud squelch spawn, monster appearing", "elevenlabs", duration=1.0, variations=4)
add_entry("sfx/enemies", "sfx_elite_spawn", "Orchestral brass sting, danger alarm, mini boss spawn", "elevenlabs", duration=2.5, variations=3)
add_entry("sfx/enemies", "sfx_boss_alarm", "Air raid siren mixed with heartbeat, boss warning", "elevenlabs", duration=4.0, variations=2)

# 8. MUSIC
music_tracks = {
    "music_menu_theme": "Orchestral fantasy menu theme, harps, light flutes, magical atmosphere, hopeful",
    "music_gameplay_start": "Energetic battle theme start, orchestral staccato strings, driving percussion",
    "music_gameplay_intense": "Intense epic battle music, brass swells, fast tempo, anime fight",
    "music_boss_intro": "Ominous orchestral sting, low brass blast, danger panic",
    "music_boss_loop": "High stakes boss music, gothic choir, heavy percussion, rapid tempo",
    "music_victory": "Final Fantasy style victory fanfare, trumpets, triumphant, major key",
    "music_defeat": "Sad emotional piano chord, fading into a somber wind sound"
}
for name, prompt in music_tracks.items():
    dur = 5.0 if "stinger" in name or "intro" in name else 60.0 # Shorten for demo, user asked for loops so 60s is good for stability
    add_entry("music", name, f"{prompt}, seamless loop, high fidelity", "stable_audio", duration=dur, variations=1)

# WRITE TO FILE
with open("tools/generation_manifest.json", "w", encoding="utf-8") as f:
    json.dump(MANIFEST, f, indent=2)

print(f"✅ Generated manifest with {len(MANIFEST)} entries.")
