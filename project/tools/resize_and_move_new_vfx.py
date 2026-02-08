"""
Resize new VFX spritesheets to their expected dimensions and move to correct folders.
Run: python tools/resize_and_move_new_vfx.py
"""
import os
import shutil
from PIL import Image

VFX_ROOT = os.path.join(os.path.dirname(__file__), "..", "assets", "vfx")
ABILITIES = os.path.join(VFX_ROOT, "abilities")

# Map: source filename -> (target_subfolder, target_filename, width, height)
ASSETS = {
    "vfx_elite_dash_trail_spritesheet.png": (
        "aoe/elite", "vfx_elite_dash_trail_spritesheet.png", 512, 128
    ),
    "vfx_boss_teleport_spritesheet.png": (
        "boss_specific/conjurador", "vfx_boss_teleport_spritesheet.png", 768, 384
    ),
    "vfx_boss_counter_stance_spritesheet.png": (
        "boss_specific/guardian_runas", "vfx_boss_counter_stance_spritesheet.png", 768, 384
    ),
    "vfx_boss_melee_impact_spritesheet.png": (
        "aoe/boss", "vfx_boss_melee_impact_spritesheet.png", 512, 256
    ),
    "vfx_orb_impact_spritesheet.png": (
        "aoe/void", "vfx_orb_impact_spritesheet.png", 512, 256
    ),
    "vfx_player_thorns_spritesheet.png": (
        "player/thorns", "vfx_player_thorns_spritesheet.png", 512, 256
    ),
    "vfx_player_shield_aura_spritesheet.png": (
        "player/shield", "vfx_player_shield_aura_spritesheet.png", 768, 256
    ),
    "vfx_player_stun_spritesheet.png": (
        "player/debuffs", "vfx_player_stun_spritesheet.png", 768, 256
    ),
    "vfx_player_slow_spritesheet.png": (
        "player/debuffs", "vfx_player_slow_spritesheet.png", 768, 256
    ),
    "vfx_melee_slash_spritesheet.png": (
        "aoe/elite", "vfx_melee_slash_spritesheet.png", 512, 256
    ),
    "projectile_lightning_spritesheet.png": (
        "projectiles/lightning", "projectile_lightning_spritesheet.png", 256, 128
    ),
}

def main():
    processed = 0
    for src_name, (subfolder, dst_name, w, h) in ASSETS.items():
        src_path = os.path.join(VFX_ROOT, src_name)
        if not os.path.exists(src_path):
            print(f"  SKIP (not found): {src_name}")
            continue

        dst_dir = os.path.join(ABILITIES, subfolder)
        os.makedirs(dst_dir, exist_ok=True)
        dst_path = os.path.join(dst_dir, dst_name)

        img = Image.open(src_path)
        orig_size = img.size

        if orig_size != (w, h):
            img = img.resize((w, h), Image.LANCZOS)
            print(f"  RESIZE {src_name}: {orig_size[0]}x{orig_size[1]} -> {w}x{h}")
        else:
            print(f"  OK (size correct): {src_name}")

        img.save(dst_path, "PNG")
        img.close()

        # Remove original from vfx root
        os.remove(src_path)
        print(f"  MOVED -> {os.path.relpath(dst_path, VFX_ROOT)}")
        processed += 1

    print(f"\nDone: {processed}/{len(ASSETS)} assets processed.")

if __name__ == "__main__":
    main()
