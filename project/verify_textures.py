#!/usr/bin/env python3
"""
Verificador de texturas seamless para Spellloop
Valida que las texturas generen seamlessly sin costuras visibles cuando se repiten
"""

import os
from PIL import Image
from pathlib import Path
import json

BIOME_DIR = Path("assets/textures/biomes")

def verify_seamless(image_path, tolerance=30):
    """
    Verifica si una imagen es seamless comparando bordes opuestos.
    Retorna True si los bordes son compatibles (diferencia promedio < tolerance).
    """
    try:
        img = Image.open(image_path).convert("RGB")
        w, h = img.size
        
        # Comparar borde superior con inferior
        top_edge = list(img.crop((0, 0, w, 1)).getdata())
        bottom_edge = list(img.crop((0, h-1, w, h)).getdata())
        
        # Comparar borde izquierdo con derecho
        left_edge = list(img.crop((0, 0, 1, h)).getdata())
        right_edge = list(img.crop((w-1, 0, w, h)).getdata())
        
        # Calcular diferencia promedio
        def avg_diff(edge1, edge2):
            if len(edge1) != len(edge2):
                return float('inf')
            diff = 0
            for p1, p2 in zip(edge1, edge2):
                r1, g1, b1 = p1 if isinstance(p1, tuple) else (p1, p1, p1)
                r2, g2, b2 = p2 if isinstance(p2, tuple) else (p2, p2, p2)
                diff += abs(r1 - r2) + abs(g1 - g2) + abs(b1 - b2)
            return diff / (len(edge1) * 3) if len(edge1) > 0 else 0
        
        top_bottom_diff = avg_diff(top_edge, bottom_edge)
        left_right_diff = avg_diff(left_edge, right_edge)
        
        is_seamless = top_bottom_diff < tolerance and left_right_diff < tolerance
        
        return {
            "seamless": is_seamless,
            "top_bottom_diff": round(top_bottom_diff, 2),
            "left_right_diff": round(left_right_diff, 2),
            "tolerance": tolerance
        }
    except Exception as e:
        return {
            "seamless": False,
            "error": str(e)
        }

def main():
    """Verifica todas las texturas generadas."""
    
    print("\n🔍 Verificador de Texturas Seamless - Spellloop")
    print("=" * 70)
    
    if not BIOME_DIR.exists():
        print(f"❌ Directorio no encontrado: {BIOME_DIR}")
        return
    
    # Cargar configuración
    config_path = BIOME_DIR / "biome_textures_config.json"
    if config_path.exists():
        with open(config_path) as f:
            config = json.load(f)
    else:
        print(f"⚠️  No se encontró {config_path}")
        config = None
    
    total_files = 0
    seamless_count = 0
    issues = []
    
    # Verificar cada bioma
    biome_dirs = sorted([d for d in BIOME_DIR.iterdir() if d.is_dir() and d.name != "__pycache__"])
    
    for biome_path in biome_dirs:
        biome_name = biome_path.name
        print(f"\n📦 {biome_name}")
        print("-" * 70)
        
        png_files = sorted(biome_path.glob("*.png"))
        
        for png_file in png_files:
            total_files += 1
            result = verify_seamless(png_file)
            
            status = "✅" if result.get("seamless", False) else "⚠️ "
            
            if result.get("seamless"):
                seamless_count += 1
                print(f"  {status} {png_file.name:<20} - Seamless")
            else:
                print(f"  {status} {png_file.name:<20} - Diferencias: "
                      f"V={result.get('top_bottom_diff', 'N/A')}, "
                      f"H={result.get('left_right_diff', 'N/A')}")
                issues.append({
                    "file": str(png_file),
                    "top_bottom_diff": result.get('top_bottom_diff', 'N/A'),
                    "left_right_diff": result.get('left_right_diff', 'N/A')
                })
    
    # Resumen
    print("\n" + "=" * 70)
    print("📊 RESUMEN DE VERIFICACIÓN")
    print("=" * 70)
    print(f"\n✓ Total de archivos: {total_files}")
    print(f"✓ Seamless verificados: {seamless_count}/{total_files}")
    print(f"✓ Percentage: {(seamless_count/total_files*100):.1f}%")
    
    if issues:
        print(f"\n⚠️  Archivos con diferencias detectadas ({len(issues)}):")
        for issue in issues:
            print(f"   • {issue['file']}")
            print(f"     Vertical: {issue['top_bottom_diff']}, Horizontal: {issue['left_right_diff']}")
    else:
        print("\n✅ ¡TODAS las texturas son seamless!")
    
    # Información de configuración
    if config:
        print(f"\n📋 Configuración JSON:")
        print(f"   • Versión: {config['metadata']['version']}")
        print(f"   • Biomas configurados: {len(config['biomes'])}")
        for biome in config['biomes']:
            print(f"     - {biome['name']:15} ({biome['color_base']})")
    
    print("\n🚀 Próximos pasos:")
    print("   1. Las texturas están listas en assets/textures/biomes/")
    print("   2. Abre el proyecto en Godot")
    print("   3. Selecciona cada PNG y configura con:")
    print("      • Filter: Linear")
    print("      • Mipmaps: ON")
    print("      • Compress: VRAM Compressed (VRAM S3TC)")
    print("      • Click: Reimport")
    print("   4. Conecta BiomeChunkApplier a InfiniteWorldManager")
    print("   5. ¡Prueba los biomas en el juego!")
    print("\n")

if __name__ == "__main__":
    main()
