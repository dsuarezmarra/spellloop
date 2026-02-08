"""
Resize the 8 remaining 612x408 VFX spritesheets to their correct target dimensions.
Each asset is a grid of animation frames that needs to be resized to match
the expected frame_size × grid dimensions in VFXManager.gd configs.
"""
from PIL import Image
import os
import shutil

BASE = r"c:\git\loopialike\project\assets\vfx\abilities"

# Format: (relative_path, target_width, target_height, description)
ASSETS_TO_RESIZE = [
    # AOE assets (4h × 2v grids)
    ("aoe/earth/aoe_elite_slam_spritesheet.png",    512,  256, "128×128 frames, AOE slam"),
    ("aoe/fire/aoe_damage_zone_fire_spritesheet.png", 1024, 512, "256×256 frames, damage zone"),
    ("aoe/void/aoe_damage_zone_void_spritesheet.png", 1024, 512, "256×256 frames, damage zone"),
    
    # Aura assets (4h × 2v grids — NOT 6×2 like standard auras)
    ("auras/aura_elite_rage_spritesheet.png",       512,  256, "128×128 frames, elite rage aura"),
    ("auras/aura_elite_shield_spritesheet.png",     512,  256, "128×128 frames, elite shield aura"),
    
    # Boss assets (4h × 2v grids)
    ("boss_specific/minotauro/boss_orbital_spritesheet.png",      768, 384, "192×192 frames, boss orbital"),
    ("boss_specific/minotauro/boss_phase_change_spritesheet.png", 768, 384, "192×192 frames, boss phase change"),
    
    # Projectile (4h × 2v grid — special homing orb, bigger than normal projectiles)
    ("projectiles/void/projectile_homing_orb_spritesheet.png", 512, 256, "128×128 frames, homing orb"),
]

def main():
    backup_dir = os.path.join(BASE, "_originals_backup")
    
    resized = 0
    errors = 0
    
    for rel_path, target_w, target_h, desc in ASSETS_TO_RESIZE:
        full_path = os.path.join(BASE, rel_path)
        
        if not os.path.exists(full_path):
            print(f"  SKIP (not found): {rel_path}")
            continue
        
        try:
            img = Image.open(full_path)
            w, h = img.size
            
            if w == target_w and h == target_h:
                print(f"  OK (already correct): {rel_path} ({w}×{h})")
                img.close()
                continue
            
            # Backup original if not already backed up
            backup_path = os.path.join(backup_dir, rel_path)
            backup_parent = os.path.dirname(backup_path)
            if not os.path.exists(backup_path):
                os.makedirs(backup_parent, exist_ok=True)
                shutil.copy2(full_path, backup_path)
                print(f"  Backed up: {rel_path}")
            
            # Resize using LANCZOS for quality
            resized_img = img.resize((target_w, target_h), Image.LANCZOS)
            resized_img.save(full_path)
            
            print(f"  RESIZED: {rel_path} ({w}×{h} → {target_w}×{target_h}) [{desc}]")
            
            img.close()
            resized_img.close()
            resized += 1
            
        except Exception as e:
            print(f"  ERROR: {rel_path}: {e}")
            errors += 1
    
    print(f"\nDone: {resized} resized, {errors} errors")

if __name__ == "__main__":
    main()
