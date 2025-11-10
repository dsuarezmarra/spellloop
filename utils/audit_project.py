#!/usr/bin/env python3
"""
Auditoría profunda del proyecto Spellloop
Identifica archivos obsoletos, duplicados, scripts de test antiguos, etc.
"""

import os
import re
from pathlib import Path
from collections import defaultdict

PROJECT_ROOT = Path(__file__).parent.parent / "project"

# Archivos/clases conocidos como OBSOLETOS
OBSOLETE_FILES = [
    "BiomeChunkApplier.gd",  # Reemplazado por BiomeChunkApplierOrganic.gd
    "BiomeGenerator.gd",     # Reemplazado por BiomeGeneratorOrganic.gd
    "test_organic_biomes.gd", # Test antiguo
    "test_organic_biomes.tscn",
    "test_biome_dithering.gd",  # Test antiguo
    "test_biome_dithering.tscn",
    "verify_decor_dimensions.gd",  # Test temporal
    "verify_decor_dimensions.tscn",
]

# Documentación obsoleta
OBSOLETE_DOCS = [
    "ANALISIS_PROFUNDO_PROBLEMA_BIOMAS.md",
    "AUDIT_COMPLETION_SUMMARY.txt",
    "AUDIT_SUMMARY.md",
    "BIOME_DELIVERY_SUMMARY.txt",
    "BIOME_INTEGRATION_AUTOMATED.md",
    "BIOME_INTEGRATION_COMPLETE.md",
    "BIOME_INTEGRATION_GUIDE.md",
    "BIOME_SYSTEM_COMPLETE.md",
    "BIOME_SYSTEM_FINAL_STATUS.md",
    "BIOME_SYSTEM_FIX_REPORT.md",
    "BIOME_SYSTEM_SANITIZATION.md",
    "BIOME_SYSTEM_STATUS.md",
    "BLENDING_ANALYSIS.md",
    "CAMBIOS_REALIZADOS.md",
    "CLEANUP_DASHBOARD.md",
    "CLEANUP_FINAL_REPORT.md",
    "CLEANUP_SUMMARY_20OCT2025.md",
    "CODE_AUDIT_REPORT.md",
    "CODE_STRUCTURE.md",
    "COMPLETION_REPORT.md",
    "CORRECCIONES_BIOMAS.md",
    "FIX_BIOME_VISIBILITY.md",
    "FIX_REPORT_20OCT2025.md",
    "ORGANIC_IMPLEMENTATION_READY.md",
    "ORGANIC_SHAPES_PROPOSAL.md",
    "ORGANIC_SYSTEM_READY.md",
    "ORGANIC_TRANSITION_ANALYSIS.md",
    "README_AUDIT_FINAL.txt",
    "README_AUDIT.md",
    "README_BIOMES.md",  # Reemplazado por README_BIOMES_ORGANIC.md
    "REAL_BLENDING_SYSTEM.md",
    "SESSION_SUMMARY_20OCT2025.md",
    "SISTEMA_COMPLETADO.md",
    "SYNC_STATUS.md",
    "TEXTURE_TILING_SOLUTION.md",
    "VALIDATION_BIOME_INTEGRATION.md",
    "REFACTORIZACION_BIOMAS_RESUMEN.md",  # Ya está en SISTEMA_ORGANICO_VORONOI_COMPLETO.md
    "BORDES_ORGANICOS_IMPLEMENTACION.md",  # Obsoleto, ya implementado
]

# Scripts/archivos de debugging temporal
TEMP_DEBUG_FILES = [
    "automate_godot_integration.py",
    "autorun_log.txt",
    "debug_movement_test.bat",
    "debug_movement.gd",
    "diagnostics_run.txt",
    "full_logs.txt",
    "generate_biome_textures.py",
    "generate_biome_textures_fix.py",
    "godot_run_output.txt",
    "godot_test_output.txt",
    "parse_log.txt",
    "reimport_textures.py",
    "run_biome_test.bat",
    "run_movement_test.ps1",
    "smoke_out.txt",
    "smoke_started.txt",
    "validate_fixes.ps1",
    "validate_fixes.py",
    "validate_syntax.py",
    "verify_out.txt",
    "verify_started.txt",
    "verify_textures.py",
    "verify_verbose_out.txt",
]

# Clases que probablemente no se usan
SUSPICIOUS_CLASSES = [
    "BiomeTextureGenerator",
    "BiomeTextureGeneratorV2",
    "BiomeTextureGeneratorEnhanced",
    "BiomeTextureGeneratorMosaic",
    "InfiniteWorldManagerTileMap",  # Si usamos InfiniteWorldManager
    "OrganicBiomeTransition",  # Si no se usa
    "OrganicShapeGenerator",  # Si no se usa
]

def find_files_by_pattern(root: Path, pattern: str) -> list:
    """Encuentra archivos que coincidan con un patrón"""
    results = []
    for file in root.rglob(pattern):
        if ".godot" not in str(file):  # Ignorar carpeta de Godot
            results.append(file)
    return results

def find_references(root: Path, class_name: str) -> list:
    """Busca referencias a una clase en archivos .gd"""
    references = []
    for gd_file in root.rglob("*.gd"):
        if ".godot" in str(gd_file):
            continue
        
        try:
            content = gd_file.read_text(encoding="utf-8")
            if class_name in content:
                # Contar líneas donde aparece
                lines = [i+1 for i, line in enumerate(content.split("\n")) if class_name in line]
                references.append((gd_file, lines))
        except Exception as e:
            print(f"Error leyendo {gd_file}: {e}")
    
    return references

def analyze_class_usage(root: Path, class_file: str) -> dict:
    """Analiza si una clase se usa en el proyecto"""
    class_path = root / "scripts" / "core" / class_file
    
    if not class_path.exists():
        return {"exists": False}
    
    # Extraer el nombre de la clase
    class_name = class_file.replace(".gd", "")
    
    # Buscar referencias
    refs = find_references(root, class_name)
    
    # Filtrar auto-referencias (la clase mencionándose a sí misma)
    external_refs = [(f, lines) for f, lines in refs if f.name != class_file]
    
    return {
        "exists": True,
        "path": class_path,
        "references": len(external_refs),
        "files": external_refs
    }

def main():
    print("=" * 80)
    print("AUDITORÍA PROFUNDA DEL PROYECTO SPELLLOOP")
    print("=" * 80)
    print()
    
    # ========== FASE 1: ARCHIVOS OBSOLETOS ==========
    print("FASE 1: ARCHIVOS OBSOLETOS CONOCIDOS")
    print("-" * 80)
    
    obsolete_found = []
    for filename in OBSOLETE_FILES:
        files = find_files_by_pattern(PROJECT_ROOT, filename)
        if files:
            for file in files:
                obsolete_found.append(file)
                print(f"❌ {file.relative_to(PROJECT_ROOT)}")
    
    print(f"\nTotal: {len(obsolete_found)} archivos obsoletos\n")
    
    # ========== FASE 2: DOCUMENTACIÓN OBSOLETA ==========
    print("FASE 2: DOCUMENTACIÓN OBSOLETA")
    print("-" * 80)
    
    docs_found = []
    for doc in OBSOLETE_DOCS:
        files = find_files_by_pattern(PROJECT_ROOT, doc)
        if files:
            for file in files:
                docs_found.append(file)
                print(f"📄 {file.relative_to(PROJECT_ROOT)}")
    
    print(f"\nTotal: {len(docs_found)} documentos obsoletos\n")
    
    # ========== FASE 3: ARCHIVOS TEMPORALES ==========
    print("FASE 3: ARCHIVOS TEMPORALES/DEBUG")
    print("-" * 80)
    
    temp_found = []
    for temp in TEMP_DEBUG_FILES:
        files = find_files_by_pattern(PROJECT_ROOT, temp)
        if files:
            for file in files:
                temp_found.append(file)
                print(f"🔧 {file.relative_to(PROJECT_ROOT)}")
    
    print(f"\nTotal: {len(temp_found)} archivos temporales\n")
    
    # ========== FASE 4: CLASES SOSPECHOSAS ==========
    print("FASE 4: ANÁLISIS DE CLASES SOSPECHOSAS")
    print("-" * 80)
    
    suspicious_found = []
    for class_name in SUSPICIOUS_CLASSES:
        class_file = f"{class_name}.gd"
        analysis = analyze_class_usage(PROJECT_ROOT, class_file)
        
        if analysis["exists"]:
            refs = analysis["references"]
            if refs == 0:
                print(f"⚠️  {class_file} - SIN REFERENCIAS (probablemente no se usa)")
                suspicious_found.append(analysis["path"])
            elif refs <= 2:
                print(f"⚠️  {class_file} - {refs} referencias (uso mínimo)")
                for ref_file, lines in analysis["files"]:
                    print(f"     → {ref_file.relative_to(PROJECT_ROOT)} líneas: {lines}")
            else:
                print(f"✅ {class_file} - {refs} referencias (en uso activo)")
    
    print(f"\nTotal: {len(suspicious_found)} clases sin uso\n")
    
    # ========== RESUMEN FINAL ==========
    print("=" * 80)
    print("RESUMEN FINAL")
    print("=" * 80)
    print(f"Archivos obsoletos:      {len(obsolete_found)}")
    print(f"Documentación obsoleta:  {len(docs_found)}")
    print(f"Archivos temporales:     {len(temp_found)}")
    print(f"Clases sin uso:          {len(suspicious_found)}")
    print(f"TOTAL A ELIMINAR:        {len(obsolete_found) + len(docs_found) + len(temp_found) + len(suspicious_found)}")
    print()
    
    # Guardar lista de archivos a eliminar
    output_file = PROJECT_ROOT.parent / "FILES_TO_DELETE.txt"
    with open(output_file, "w", encoding="utf-8") as f:
        f.write("# Archivos identificados para eliminación\n")
        f.write("# Generado por audit_project.py\n\n")
        
        f.write("## Archivos obsoletos\n")
        for file in obsolete_found:
            f.write(f"{file}\n")
        
        f.write("\n## Documentación obsoleta\n")
        for file in docs_found:
            f.write(f"{file}\n")
        
        f.write("\n## Archivos temporales\n")
        for file in temp_found:
            f.write(f"{file}\n")
        
        f.write("\n## Clases sin uso\n")
        for file in suspicious_found:
            f.write(f"{file}\n")
    
    print(f"✅ Lista guardada en: {output_file}")

if __name__ == "__main__":
    main()
