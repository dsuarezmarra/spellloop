from PIL import Image
import os

# Config: path -> (target_width, target_height)
targets = {
    r"c:\git\loopialike\project\assets\vfx\abilities\player\buffs\vfx_player_frost_nova_spritesheet.png": (512, 256),
    r"c:\git\loopialike\project\assets\vfx\abilities\player\heal\vfx_player_heal_spritesheet.png": (512, 256),
    r"c:\git\loopialike\project\assets\vfx\abilities\player\revive\vfx_player_revive_spritesheet.png": (768, 384),
    r"c:\git\loopialike\project\assets\vfx\abilities\player\shield\vfx_player_shield_absorb_spritesheet.png": (512, 256),
    r"c:\git\loopialike\project\assets\vfx\abilities\player\soul_link\vfx_player_soul_link_spritesheet.png": (512, 256)
}

print("Resizing VFX files...")
for f, size in targets.items():
    try:
        if os.path.exists(f):
            with Image.open(f) as img:
                print(f"Resizing {os.path.basename(f)} from {img.size} to {size}")
                # Use LANCZOS for best resizing quality
                resized = img.resize(size, Image.Resampling.LANCZOS)
                resized.save(f)
                print("Saved.")
        else:
            print(f"{os.path.basename(f)}: NOT FOUND")
    except Exception as e:
        print(f"{os.path.basename(f)}: Error {e}")
