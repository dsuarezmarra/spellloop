#!/usr/bin/env python3
"""
batch_process_lava_decor.py
Procesa y renombra automáticamente las decoraciones de Lava.
"""

import os
import sys
from pathlib import Path

# Añadir directorio actual al path para importar fix_spritesheet_dimensions
sys.path.insert(0, os.path.dirname(__file__))
from fix_spritesheet_dimensions import fix_spritesheet

def main():
    base_path = Path("../project/assets/textures/biomes/Lava/decor/")
    
    # Mapeo: archivo_origen -> (nombre_final, frames_esperados)
    # Orden basado en las imágenes adjuntadas por el usuario
    file_mapping = [
        ("unnamed-removebg-preview.png", "lava_decor2_sheet_f6_256.png", 6),       # Llamas cristalinas
        ("unnamed-removebg-preview (1).png", "lava_decor3_sheet_f7_256.png", 7),   # Flor de fuego
        ("unnamed-removebg-preview (2).png", "lava_decor4_sheet_f12_256.png", 12), # Volcanes
        ("unnamed-removebg-preview (3).png", "lava_decor5_sheet_f6_256.png", 6),   # Volcán pequeño
        ("unnamed-removebg-preview (4).png", "lava_decor6_sheet_f8_256.png", 8),   # Piscina lava
        ("unnamed-removebg-preview (5).png", "lava_decor7_sheet_f6_256.png", 6),   # Fogata
        ("unnamed-removebg-preview (6).png", "lava_decor8_sheet_f12_256.png", 12), # Grietas magma
    ]
    
    print("\n" + "="*70)
    print("PROCESAMIENTO EN BATCH - DECORACIONES LAVA")
    print("="*70 + "\n")
    
    for source_name, target_name, expected_frames in file_mapping:
        source_path = base_path / source_name
        temp_path = base_path / f"temp_{target_name}"
        final_path = base_path / target_name
        
        if not source_path.exists():
            print(f"⚠️ No encontrado: {source_name} (saltando)")
            continue
        
        print(f"\n{'─'*70}")
        print(f"📄 Procesando: {source_name}")
        print(f"   → Destino: {target_name}")
        print(f"   → Frames esperados: {expected_frames}")
        print(f"{'─'*70}")
        
        # Renombrar temporalmente al formato correcto para que fix_spritesheet lo procese
        source_path.rename(temp_path)
        
        # Procesar con fix_spritesheet
        try:
            result = fix_spritesheet(str(temp_path), str(final_path), backup=False)
            
            if result:
                # Eliminar archivo temporal si el procesamiento fue exitoso
                if temp_path.exists():
                    temp_path.unlink()
                print(f"✅ Completado: {target_name}\n")
            else:
                # Si falló, restaurar nombre original
                if temp_path.exists() and not final_path.exists():
                    temp_path.rename(source_path)
                print(f"❌ Error al procesar: {source_name}\n")
                
        except Exception as e:
            print(f"❌ Excepción al procesar {source_name}: {e}")
            # Restaurar nombre original en caso de error
            if temp_path.exists() and not final_path.exists():
                temp_path.rename(source_path)
    
    print("\n" + "="*70)
    print("RESUMEN FINAL")
    print("="*70)
    
    # Listar todos los archivos finales
    print("\n📁 Archivos en la carpeta de decoraciones:")
    for file in sorted(base_path.glob("lava_decor*_sheet_f*_256.png")):
        size = file.stat().st_size / 1024
        print(f"  ✅ {file.name} ({size:.1f} KB)")
    
    # Listar archivos no procesados
    remaining = list(base_path.glob("unnamed-*.png"))
    if remaining:
        print("\n⚠️ Archivos sin procesar:")
        for file in remaining:
            print(f"  ❓ {file.name}")
    
    print("\n" + "="*70 + "\n")

if __name__ == "__main__":
    main()
