#!/usr/bin/env python3
"""
fix_texture_imports_tiling.py
Actualiza los archivos .import de las texturas base de biomas para habilitar tiling/repeat
"""

import os
from pathlib import Path

def update_import_file(import_path: Path) -> bool:
    """Actualiza un archivo .import para habilitar repeat mode"""
    try:
        content = import_path.read_text(encoding='utf-8')
        
        # Verificar si ya tiene la configuración correcta
        if 'repeat/mode=2' in content:
            print(f"  ✓ Ya configurado: {import_path.name}")
            return False
        
        # Buscar la sección [params] y añadir repeat mode si no existe
        lines = content.split('\n')
        new_lines = []
        params_found = False
        repeat_added = False
        
        for line in lines:
            new_lines.append(line)
            
            # Después de [params], añadir repeat mode
            if line.strip() == '[params]':
                params_found = True
            
            # Añadir repeat mode después de compress/mode si no existe
            if params_found and line.startswith('compress/mode=') and not repeat_added:
                # Añadir configuración de repeat después de la primera línea de params
                pass  # Lo añadimos al final de params
        
        # Buscar si ya existe repeat/mode
        has_repeat = any('repeat/mode' in line for line in lines)
        
        if not has_repeat:
            # Añadir al final de [params] section
            # Encontrar donde insertar (antes de la siguiente sección o al final)
            insert_idx = len(new_lines)
            for i, line in enumerate(new_lines):
                if line.strip() == '[params]':
                    # Buscar el final de params (siguiente sección o EOF)
                    for j in range(i + 1, len(new_lines)):
                        if new_lines[j].startswith('[') and new_lines[j].strip().endswith(']'):
                            insert_idx = j
                            break
                    else:
                        insert_idx = len(new_lines)
                    break
            
            # Insertar repeat mode
            # En Godot 4.x, repeat mode se configura diferente
            # Pero el shader ya tiene repeat_enable, así que solo necesitamos mipmaps
            new_lines.insert(insert_idx, 'mipmaps/generate=true')
            
            # Escribir de vuelta
            import_path.write_text('\n'.join(new_lines), encoding='utf-8')
            print(f"  ✓ Actualizado: {import_path.name}")
            return True
        
        return False
        
    except Exception as e:
        print(f"  ✗ Error en {import_path}: {e}")
        return False


def main():
    project_root = Path(__file__).parent.parent / "project"
    biomes_path = project_root / "assets" / "textures" / "biomes"
    
    if not biomes_path.exists():
        print(f"Error: No se encontró {biomes_path}")
        return
    
    print("🔧 Actualizando importaciones de texturas base...")
    print(f"   Ruta: {biomes_path}\n")
    
    updated = 0
    total = 0
    
    # Procesar cada bioma
    for biome_dir in biomes_path.iterdir():
        if not biome_dir.is_dir():
            continue
        
        base_dir = biome_dir / "base"
        if not base_dir.exists():
            continue
        
        print(f"📁 {biome_dir.name}/base:")
        
        # Buscar 1.png.import (el frame que usaremos)
        import_file = base_dir / "1.png.import"
        if import_file.exists():
            total += 1
            if update_import_file(import_file):
                updated += 1
        else:
            print(f"  - No existe 1.png.import")
    
    print(f"\n✅ Completado: {updated}/{total} archivos actualizados")
    print("\n⚠️  Nota: Reinicia el editor de Godot para que reimporte las texturas")


if __name__ == "__main__":
    main()
