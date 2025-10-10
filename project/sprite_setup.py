# sprite_setup.py - Script para convertir sprites a formato Godot
import base64
from PIL import Image
import io

# Función para crear archivos .import para Godot
def create_godot_import_file(sprite_path):
    import_content = f'''[remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://b{hash(sprite_path) % 1000000000}"
path="res://.godot/imported/{sprite_path.split('/')[-1]}.{sprite_path.split('.')[-1]}-{hash(sprite_path) % 1000000}.ctex"
metadata={{
"vram_texture": false
}}

[deps]

source_file="{sprite_path}"
dest_files=["res://.godot/imported/{sprite_path.split('/')[-1]}.{sprite_path.split('.')[-1]}-{hash(sprite_path) % 1000000}.ctex"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
'''
    return import_content

print("Script de setup de sprites creado")
print("Los sprites se cargarán automáticamente cuando estén en /sprites/wizard/")