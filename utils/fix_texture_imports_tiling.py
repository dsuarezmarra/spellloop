"""
Configurar archivos .import para tiles seamless
- texture_filter = 0 (NEAREST - sin blur)
- texture_repeat = 2 (ENABLED - permite wrap/tiling)
"""
import os
import re

def fix_import_file(import_path):
    """Actualiza un archivo .import para tiling seamless"""
    if not os.path.exists(import_path):
        print(f"  ⚠️  No existe: {import_path}")
        return False
    
    with open(import_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Buscar la sección [params]
    if '[params]' not in content:
        print(f"  ⚠️  No tiene sección [params]")
        return False
    
    # Actualizar o agregar texture_filter
    if re.search(r'^flags/texture_filter\s*=', content, re.MULTILINE):
        content = re.sub(
            r'^flags/texture_filter\s*=.*$',
            'flags/texture_filter=0',
            content,
            flags=re.MULTILINE
        )
    else:
        # Agregar después de [params]
        content = content.replace('[params]', '[params]\nflags/texture_filter=0')
    
    # Actualizar o agregar texture_repeat
    if re.search(r'^flags/texture_repeat\s*=', content, re.MULTILINE):
        content = re.sub(
            r'^flags/texture_repeat\s*=.*$',
            'flags/texture_repeat=2',
            content,
            flags=re.MULTILINE
        )
    else:
        # Agregar después de texture_filter
        content = content.replace(
            'flags/texture_filter=0',
            'flags/texture_filter=0\nflags/texture_repeat=2'
        )
    
    with open(import_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    return True

def main():
    print("\n" + "="*70)
    print("CONFIGURANDO ARCHIVOS .import PARA TILING SEAMLESS")
    print("="*70)
    
    base_path = r"c:\git\spellloop\project\assets\textures\biomes"
    biomes = ["Snow", "Lava", "ArcaneWastes"]
    
    updated = 0
    
    for biome in biomes:
        biome_base = os.path.join(base_path, biome, "base")
        print(f"\n📁 {biome}/base")
        
        if not os.path.exists(biome_base):
            print(f"  ⚠️  Carpeta no existe")
            continue
        
        # Buscar archivos .import de spritesheets
        for file in os.listdir(biome_base):
            if file.endswith("_sheet_f8_512.png.import") or file.endswith("_sheet_f8_510.png.import"):
                import_path = os.path.join(biome_base, file)
                if fix_import_file(import_path):
                    print(f"  ✅ Actualizado: {file}")
                    updated += 1
    
    print("\n" + "="*70)
    print(f"✅ {updated} archivos actualizados")
    print("="*70)
    print("\n⚠️  IMPORTANTE: Recargar proyecto en Godot para aplicar cambios")
    print("="*70)

if __name__ == "__main__":
    main()
