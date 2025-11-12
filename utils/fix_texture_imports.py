#!/usr/bin/env python3
"""
fix_texture_imports.py
Corrige los archivos .import de las texturas para desactivar el filtrado.
Esto elimina las rayas negras entre tiles seamless.
"""

from pathlib import Path
import re

def fix_import_file(import_path):
    """
    Modifica un archivo .import para agregar texture_filter=0 (Nearest Neighbor).
    """
    content = import_path.read_text(encoding='utf-8')
    
    # Verificar si ya tiene la configuración
    if 'detect_3d/compress_to=1' in content:
        # Reemplazar o agregar después de compress_to
        if not re.search(r'texture_filter\s*=', content):
            # Agregar texture_filter después de detect_3d/compress_to
            content = content.replace(
                'detect_3d/compress_to=1',
                'detect_3d/compress_to=1\ntexture_filter=0'
            )
            print(f"  ✅ Actualizado: {import_path.name}")
            import_path.write_text(content, encoding='utf-8')
            return True
        else:
            # Ya tiene texture_filter, actualizar valor
            content = re.sub(
                r'texture_filter\s*=\s*\d+',
                'texture_filter=0',
                content
            )
            print(f"  ✅ Corregido: {import_path.name}")
            import_path.write_text(content, encoding='utf-8')
            return True
    
    return False

def main():
    project_root = Path(__file__).parent.parent / "project"
    biomes_path = project_root / "assets" / "textures" / "biomes"
    
    if not biomes_path.exists():
        print(f"❌ No se encontró la carpeta de biomas: {biomes_path}")
        return
    
    print("=" * 70)
    print("CORRIGIENDO ARCHIVOS .import DE TEXTURAS")
    print("=" * 70)
    print()
    
    # Procesar cada bioma
    biomes = ["Snow", "Lava", "ArcaneWastes"]
    total_fixed = 0
    
    for biome in biomes:
        base_path = biomes_path / biome / "base"
        if not base_path.exists():
            print(f"⚠️  No existe: {base_path}")
            continue
        
        print(f"📁 {biome}/base")
        
        # Buscar todos los .import de spritesheets
        import_files = list(base_path.glob("*_sheet_*.png.import"))
        
        if not import_files:
            print(f"  ⚠️  No se encontraron archivos .import")
            continue
        
        for import_file in import_files:
            if fix_import_file(import_file):
                total_fixed += 1
        
        print()
    
    print("=" * 70)
    print(f"✅ {total_fixed} archivos actualizados")
    print("=" * 70)
    print()
    print("NOTA: Es necesario recargar el proyecto en Godot para que")
    print("      los cambios surtan efecto.")
    print()

if __name__ == "__main__":
    main()
