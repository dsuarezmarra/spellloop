from PIL import Image
import os

files = [
    r"c:\git\loopialike\project\assets\vfx\abilities\player\buffs\vfx_player_frost_nova_spritesheet.png",
    r"c:\git\loopialike\project\assets\vfx\abilities\player\heal\vfx_player_heal_spritesheet.png",
    r"c:\git\loopialike\project\assets\vfx\abilities\player\revive\vfx_player_revive_spritesheet.png",
    r"c:\git\loopialike\project\assets\vfx\abilities\player\shield\vfx_player_shield_absorb_spritesheet.png",
    r"c:\git\loopialike\project\assets\vfx\abilities\player\soul_link\vfx_player_soul_link_spritesheet.png"
]

with open("vfx_dims.txt", "w") as out:
    for f in files:
        try:
            if os.path.exists(f):
                with Image.open(f) as img:
                    out.write(f"{os.path.basename(f)}: {img.size}\n")
            else:
                out.write(f"{os.path.basename(f)}: NOT FOUND\n")
        except Exception as e:
            out.write(f"{os.path.basename(f)}: Error {e}\n")
