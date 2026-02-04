
import os
import re

# Mapping of ID -> Icon Filename
ICON_MAP = {
    # Core Weapons
    "ice_wand": "weapon_ice_wand.png",
    "fire_wand": "weapon_fire_wand.png",
    "lightning_wand": "weapon_lightning_wand.png",
    "arcane_orb": "weapon_arcane_orb.png",

    # Fusions (Set 16)
    "frozen_thunder": "fusion_frozen_thunder.png",
    "frost_orb": "fusion_frost_orb.png",
    "frostbite": "fusion_frostbite.png",
    "blizzard": "fusion_blizzard.png",
    "glacier": "fusion_glacier.png",
    "aurora": "fusion_aurora.png",
    "absolute_zero": "fusion_absolute_zero.png",
    "plasma": "fusion_plasma.png",

    # Fusions (Set 17)
    "inferno_orb": "fusion_inferno_orb.png",
    "wildfire": "fusion_wildfire.png",
    "firestorm": "fusion_firestorm.png",
    "volcano": "fusion_volcano.png",
    "solar_flare": "fusion_solar_flare.png",
    "dark_flame": "fusion_dark_flame.png",
    "arcane_storm": "fusion_arcane_storm.png",
    "dark_lightning": "fusion_dark_lightning.png",
    "thunder_bloom": "fusion_thunder_bloom.png",
    "seismic_bolt": "fusion_seismic_bolt.png",
    "void_bolt": "fusion_void_bolt.png",
    "shadow_orbs": "fusion_shadow_orbs.png",

    # Fusions (Set 18)
    "life_orbs": "fusion_life_orbs.png",
    "wind_orbs": "fusion_wind_orbs.png",
    "cosmic_void": "fusion_cosmic_void.png",
    "phantom_blade": "fusion_phantom_blade.png",
    "stone_fang": "fusion_stone_fang.png",
    "twilight": "fusion_twilight.png",
    "abyss": "fusion_abyss.png",
    "pollen_storm": "fusion_pollen_storm.png",
    "gaia": "fusion_gaia.png",
    "solar_bloom": "fusion_solar_bloom.png",
    "decay": "fusion_decay.png",
    "sandstorm": "fusion_sandstorm.png",

    # Fusions (Set 19)
    "prism_wind": "fusion_prism_wind.png",
    "radiant_stone": "fusion_radiant_stone.png",
    "eclipse": "fusion_eclipse.png",

    # Upgrades
    "sharpshooter": "upgrade_sharpshooter.png",
    "giant_slayer": "upgrade_giant_slayer.png",
    "combustion": "upgrade_combustion.png",
    "elite_damage_1": "upgrade_giant_slayer.png", # Reuse for related
    "elite_damage_2": "upgrade_giant_slayer.png",
    "elite_damage_3": "upgrade_giant_slayer.png"
}

FILES_TO_PATCH = [
    r"c:\git\spellloop\project\scripts\data\WeaponDatabase.gd",
    r"c:\git\spellloop\project\scripts\data\UpgradeDatabase.gd"
]

def patch_file(filepath):
    print(f"Patching {filepath}...")
    if not os.path.exists(filepath):
        print("  File not found!")
        return

    with open(filepath, "r", encoding="utf-8") as f:
        lines = f.readlines()

    new_lines = []
    current_id = None
    
    # Regex to capture ID definition: "id": "some_id",
    id_pattern = re.compile(r'^\s*"id":\s*"([^"]+)",')
    # Regex to capture Icon definition: "icon": "...",
    icon_pattern = re.compile(r'^(\s*)"icon":\s*".*",') # Group 1 captures indentation

    for line in lines:
        # Check for ID
        match_id = id_pattern.search(line)
        if match_id:
            current_id = match_id.group(1)
            new_lines.append(line)
            continue

        # Check for Icon
        match_icon = icon_pattern.search(line)
        if match_icon:
            if current_id and current_id in ICON_MAP:
                indent = match_icon.group(1)
                new_filename = ICON_MAP[current_id]
                new_line = f'{indent}"icon": "res://assets/icons/{new_filename}",\n'
                new_lines.append(new_line)
                print(f"  Updated {current_id} -> {new_filename}")
            else:
                new_lines.append(line)
        else:
            new_lines.append(line)

    with open(filepath, "w", encoding="utf-8") as f:
        f.writelines(new_lines)

def main():
    for f in FILES_TO_PATCH:
        patch_file(f)
    print("Database patch complete.")

if __name__ == "__main__":
    main()
