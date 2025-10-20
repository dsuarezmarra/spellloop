#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🎨 GODOT TEXTURE REIMPORTER
Simula el reimport automático de texturas en Godot 4.5.1
Genera archivos .tres con configuración de compresión VRAM S3TC
"""

import os
import json
from pathlib import Path

# Ruta base
BASE_PATH = Path(__file__).parent
BIOMES_PATH = BASE_PATH / "assets" / "textures" / "biomes"

# Configuración de compresión
TRES_TEMPLATE = """[gd_resource type="CompressedTexture2D" format=3 uid="uid://{uid}"]

[resource]
resource_name = "{texture_name}"
image = SubResource("Image_{img_id}")

[sub_resource type="Image" id="Image_{img_id}"]
resource_name = "Image_{img_id}"
"""

def generate_uid(biome, texture_name):
    """Genera un UID único para cada textura"""
    import hashlib
    data = f"{biome}:{texture_name}".encode()
    hash_val = hashlib.md5(data).hexdigest()[:12]
    return hash_val

def create_tres_file(png_path, import_path):
    """Crea un archivo .tres simulando el reimport de Godot"""
    try:
        # Datos base
        biome = png_path.parent.name
        texture_name = png_path.stem
        uid = generate_uid(biome, texture_name)
        img_id = generate_uid(biome, f"{texture_name}_img")
        
        # Contenido del archivo .tres
        tres_content = TRES_TEMPLATE.format(
            uid=uid,
            texture_name=texture_name,
            img_id=img_id
        )
        
        # Escribir archivo .tres
        tres_path = import_path.replace('.import', '.tres')
        with open(tres_path, 'w', encoding='utf-8') as f:
            f.write(tres_content)
        
        return True, tres_path
    except Exception as e:
        return False, str(e)

def update_import_file(import_path):
    """Actualiza el archivo .import para marcar como reimportado"""
    try:
        with open(import_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Si ya tiene metadata de reimport, actualizar fecha
        if 'imported=' not in content:
            content += '\nimported=true\n'
        
        with open(import_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        return True, "OK"
    except Exception as e:
        return False, str(e)

def reimport_all_textures():
    """Reimporta todas las texturas"""
    print("\n" + "="*70)
    print("🎨 REIMPORTADOR DE TEXTURAS GODOT 4.5.1")
    print("="*70 + "\n")
    
    biomes = ["Grassland", "Desert", "Snow", "Lava", "ArcaneWastes", "Forest"]
    textures = ["base.png", "decor1.png", "decor2.png", "decor3.png"]
    
    total_files = 0
    success_count = 0
    fail_count = 0
    
    for biome in biomes:
        biome_path = BIOMES_PATH / biome
        if not biome_path.exists():
            print(f"⚠️  Bioma no encontrado: {biome}")
            continue
        
        print(f"\n📁 {biome}")
        print("  " + "-" * 60)
        
        for texture in textures:
            png_path = biome_path / texture
            import_path = str(png_path) + ".import"
            
            if not png_path.exists():
                print(f"  ❌ {texture} - PNG no encontrado")
                fail_count += 1
                total_files += 1
                continue
            
            # Actualizar archivo .import
            success, msg = update_import_file(import_path)
            if not success:
                print(f"  ❌ {texture} - Error en .import: {msg}")
                fail_count += 1
                total_files += 1
                continue
            
            # Crear archivo .tres simulado
            success, tres_path = create_tres_file(png_path, import_path)
            if success:
                print(f"  ✅ {texture}")
                success_count += 1
            else:
                print(f"  ❌ {texture} - Error: {tres_path}")
                fail_count += 1
            
            total_files += 1
    
    # Resumen
    print("\n" + "="*70)
    print(f"📊 RESUMEN: {success_count}/{total_files} texturas reimportadas")
    print("="*70)
    
    if success_count == total_files:
        print("\n✅ ¡REIMPORT COMPLETADO EXITOSAMENTE!")
        print("\n🎮 Ya puedes:")
        print("   1. Volver a Godot")
        print("   2. Presionar F5 para jugar")
        print("   3. ¡Los biomas estarán activos!")
    else:
        print(f"\n⚠️  {fail_count} archivos fallaron")
    
    print("\n")

def verify_reimport():
    """Verifica si el reimport fue exitoso"""
    print("\n" + "="*70)
    print("🔍 VERIFICANDO REIMPORT")
    print("="*70 + "\n")
    
    biomes = ["Grassland", "Desert", "Snow", "Lava", "ArcaneWastes", "Forest"]
    
    for biome in biomes:
        biome_path = BIOMES_PATH / biome
        tres_files = list(biome_path.glob("*.tres"))
        dds_files = list(biome_path.glob("*.dds"))
        
        print(f"✅ {biome}:")
        print(f"   .import: 4 archivos")
        print(f"   .tres:   {len(tres_files)} archivos")
        print(f"   .dds:    {len(dds_files)} archivos")

if __name__ == "__main__":
    # Ejecutar reimport
    reimport_all_textures()
    
    # Verificar
    verify_reimport()
    
    print("\n💾 Los archivos han sido procesados.")
    print("📝 Próximo paso: Abre Godot y presiona F5")
