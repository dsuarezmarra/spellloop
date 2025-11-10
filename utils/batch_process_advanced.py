#!/usr/bin/env python3
"""
batch_process_advanced.py
Procesa las decoraciones con algoritmo avanzado de centros de masa.
"""

from pathlib import Path
from fix_spritesheet_advanced import process_spritesheet_advanced

def main():
    base_path = Path("../project/assets/textures/biomes/Lava/decor/")
    
    # Mapeo: archivo_origen -> (nombre_final, frames_esperados, descripción)
    file_mapping = [
        ("unnamed-removebg-preview (1).png", "lava_decor3_sheet_f7_256.png", 7, "Flor de fuego"),
        ("unnamed-removebg-preview (2).png", "lava_decor4_sheet_f12_256.png", 12, "Volcanes"),
        ("unnamed-removebg-preview (3).png", "lava_decor5_sheet_f6_256.png", 6, "Volcán pequeño"),
        ("unnamed-removebg-preview (4).png", "lava_decor6_sheet_f8_256.png", 8, "Piscina lava"),
        ("unnamed-removebg-preview (5).png", "lava_decor7_sheet_f6_256.png", 6, "Fogata"),
        ("unnamed-removebg-preview (6).png", "lava_decor8_sheet_f12_256.png", 12, "Grietas magma"),
    ]
    
    print("\n" + "="*70)
    print("PROCESAMIENTO AVANZADO (CENTROS DE MASA) - DECORACIONES LAVA")
    print("="*70)
    
    success_count = 0
    error_count = 0
    
    for source_name, target_name, expected_frames, description in file_mapping:
        source_path = base_path / source_name
        final_path = base_path / target_name
        
        if not source_path.exists():
            print(f"\n⚠️ No encontrado: {source_name} (saltando)")
            continue
        
        print(f"\n{'─'*70}")
        print(f"📝 {description}")
        print(f"   {source_name} → {target_name}")
        print(f"{'─'*70}")
        
        try:
            result = process_spritesheet_advanced(
                str(source_path),
                str(final_path),
                expected_frames,
                frame_size=256,
                padding=4
            )
            
            if result:
                success_count += 1
                print(f"  ✅ Éxito\n")
            else:
                error_count += 1
                print(f"  ❌ Fallo\n")
                
        except Exception as e:
            print(f"❌ Excepción: {e}")
            import traceback
            traceback.print_exc()
            error_count += 1
    
    print("\n" + "="*70)
    print("RESUMEN")
    print("="*70)
    print(f"  ✅ Éxitos: {success_count}")
    print(f"  ❌ Errores: {error_count}")
    print("="*70 + "\n")
    
    # Listar archivos finales
    print("📁 Todas las decoraciones:")
    for file in sorted(base_path.glob("lava_decor*_sheet_f*_256.png")):
        size = file.stat().st_size / 1024
        print(f"  ✓ {file.name} ({size:.1f} KB)")
    
    print("\n" + "="*70 + "\n")

if __name__ == "__main__":
    main()
