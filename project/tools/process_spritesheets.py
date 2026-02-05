#!/usr/bin/env python3
"""
Spritesheet Processor for VFX Abilities
========================================
Procesa spritesheets generados por Gemini AI para adaptarlos a las especificaciones exactas del juego.

Fases:
1. Backup de originales
2. Diagnóstico (dimensiones actuales vs esperadas)
3. Análisis de frames (detección de contenido, centro de masas)
4. Recorte y recentrado
5. Reconstrucción del spritesheet

Autor: Copilot
Fecha: 5 de febrero de 2026
"""

import os
import shutil
from pathlib import Path
from PIL import Image
import json
from datetime import datetime

# =============================================================================
# CONFIGURACIÓN - Especificaciones de cada spritesheet
# =============================================================================

SPECS = {
    # PROYECTILES (4x2 grid, 64x64 per frame = 256x128 total)
    "projectile_fire_spritesheet.png": {"grid": (4, 2), "frame_size": (64, 64), "sheet_size": (256, 128)},
    "projectile_ice_spritesheet.png": {"grid": (4, 2), "frame_size": (64, 64), "sheet_size": (256, 128)},
    "projectile_arcane_spritesheet.png": {"grid": (4, 2), "frame_size": (64, 64), "sheet_size": (256, 128)},
    "projectile_void_spritesheet.png": {"grid": (4, 2), "frame_size": (64, 64), "sheet_size": (256, 128)},
    "projectile_poison_spritesheet.png": {"grid": (4, 2), "frame_size": (64, 64), "sheet_size": (256, 128)},
    "projectile_void_homing_spritesheet.png": {"grid": (4, 2), "frame_size": (64, 64), "sheet_size": (256, 128)},
    
    # AOE PEQUEÑO (4x2 grid, 128x128 per frame = 512x256 total)
    "aoe_fire_stomp_spritesheet.png": {"grid": (4, 2), "frame_size": (128, 128), "sheet_size": (512, 256)},
    "aoe_rune_blast_spritesheet.png": {"grid": (4, 2), "frame_size": (128, 128), "sheet_size": (512, 256)},
    "aoe_ground_slam_spritesheet.png": {"grid": (4, 2), "frame_size": (128, 128), "sheet_size": (512, 256)},
    "aoe_meteor_impact_spritesheet.png": {"grid": (4, 2), "frame_size": (128, 128), "sheet_size": (512, 256)},
    
    # AOE GRANDE (4x2 grid, 256x256 per frame = 1024x512 total)
    "aoe_fire_zone_spritesheet.png": {"grid": (4, 2), "frame_size": (256, 256), "sheet_size": (1024, 512)},
    "aoe_freeze_zone_spritesheet.png": {"grid": (4, 2), "frame_size": (256, 256), "sheet_size": (1024, 512)},
    "aoe_arcane_nova_spritesheet.png": {"grid": (4, 2), "frame_size": (256, 256), "sheet_size": (1024, 512)},
    "aoe_void_explosion_spritesheet.png": {"grid": (4, 2), "frame_size": (256, 256), "sheet_size": (1024, 512)},
    
    # BEAMS
    "beam_flame_breath_spritesheet.png": {"grid": (4, 2), "frame_size": (64, 64), "sheet_size": (256, 256)},
    "beam_void_beam_spritesheet.png": {"grid": (8, 1), "frame_size": (64, 64), "sheet_size": (512, 64)},
    
    # TELEGRAPHS (4x2 grid, 64x64 per frame = 256x128 total)
    "telegraph_circle_warning_spritesheet.png": {"grid": (4, 2), "frame_size": (64, 64), "sheet_size": (256, 128)},
    "telegraph_charge_line_spritesheet.png": {"grid": (4, 2), "frame_size": (64, 64), "sheet_size": (256, 128)},
    "telegraph_meteor_warning_spritesheet.png": {"grid": (4, 2), "frame_size": (64, 64), "sheet_size": (256, 128)},
    "telegraph_rune_prison_spritesheet.png": {"grid": (4, 2), "frame_size": (64, 64), "sheet_size": (256, 128)},
    
    # AURAS GRANDES (4x2 grid, 128x128 per frame = 512x256 total)
    "aura_elite_floor_spritesheet.png": {"grid": (4, 2), "frame_size": (128, 128), "sheet_size": (512, 256)},
    "aura_damage_void_spritesheet.png": {"grid": (4, 2), "frame_size": (128, 128), "sheet_size": (512, 256)},
    "aura_enrage_spritesheet.png": {"grid": (4, 2), "frame_size": (128, 128), "sheet_size": (512, 256)},
    
    # AURA PEQUEÑA (4x2 grid, 64x64 per frame = 256x128 total)
    "aura_buff_corruption_spritesheet.png": {"grid": (4, 2), "frame_size": (64, 64), "sheet_size": (256, 128)},
    
    # BOSS ESPECÍFICOS
    "boss_summon_circle_spritesheet.png": {"grid": (4, 2), "frame_size": (128, 128), "sheet_size": (512, 256)},
    "boss_void_pull_spritesheet.png": {"grid": (4, 2), "frame_size": (256, 256), "sheet_size": (1024, 512)},
    "boss_reality_tear_spritesheet.png": {"grid": (4, 2), "frame_size": (128, 128), "sheet_size": (512, 256)},
    "boss_rune_shield_spritesheet.png": {"grid": (4, 2), "frame_size": (128, 128), "sheet_size": (512, 256)},
}

# =============================================================================
# RUTAS
# =============================================================================

BASE_PATH = Path(r"C:\git\loopialike\project\assets\vfx\abilities")
BACKUP_PATH = BASE_PATH / "_originals_backup"
REPORT_PATH = BASE_PATH / "_processing_report.json"

# =============================================================================
# FUNCIONES DE UTILIDAD
# =============================================================================

def get_all_spritesheets():
    """Encuentra todos los spritesheets en la estructura de carpetas."""
    files = {}
    for filepath in BASE_PATH.rglob("*.png"):
        if "_originals_backup" not in str(filepath):
            files[filepath.name] = filepath
    return files


def create_backup():
    """Crea backup de todos los originales."""
    print("\n" + "="*60)
    print("FASE 1: CREANDO BACKUP DE ORIGINALES")
    print("="*60)
    
    BACKUP_PATH.mkdir(exist_ok=True)
    files = get_all_spritesheets()
    
    for name, filepath in files.items():
        # Mantener estructura de subcarpetas en backup
        rel_path = filepath.relative_to(BASE_PATH)
        backup_file = BACKUP_PATH / rel_path
        backup_file.parent.mkdir(parents=True, exist_ok=True)
        
        if not backup_file.exists():
            shutil.copy2(filepath, backup_file)
            print(f"  ✓ Backup: {rel_path}")
        else:
            print(f"  · Ya existe: {rel_path}")
    
    print(f"\n  Backup guardado en: {BACKUP_PATH}")
    return files


def analyze_image(filepath, spec):
    """Analiza una imagen y devuelve información detallada."""
    img = Image.open(filepath)
    
    # Convertir a RGBA si no lo es
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    
    actual_size = img.size
    expected_size = spec["sheet_size"]
    grid = spec["grid"]
    frame_size = spec["frame_size"]
    
    # Calcular tamaño de celda actual (si la imagen tiene dimensiones diferentes)
    actual_cell_w = actual_size[0] / grid[0]
    actual_cell_h = actual_size[1] / grid[1]
    
    # Analizar cada frame para detectar contenido
    frames_info = []
    for row in range(grid[1]):
        for col in range(grid[0]):
            # Posición en la imagen actual
            x = int(col * actual_cell_w)
            y = int(row * actual_cell_h)
            w = int(actual_cell_w)
            h = int(actual_cell_h)
            
            # Extraer celda
            cell = img.crop((x, y, x + w, y + h))
            
            # Calcular bounding box del contenido (píxeles no transparentes)
            bbox = get_content_bbox(cell)
            
            # Calcular centro de masas
            center = get_center_of_mass(cell) if bbox else None
            
            frames_info.append({
                "index": row * grid[0] + col,
                "row": row,
                "col": col,
                "position": (x, y, w, h),
                "content_bbox": bbox,
                "center_of_mass": center,
                "has_content": bbox is not None
            })
    
    return {
        "actual_size": actual_size,
        "expected_size": expected_size,
        "size_match": actual_size == expected_size,
        "scale_factor": (expected_size[0] / actual_size[0], expected_size[1] / actual_size[1]),
        "grid": grid,
        "expected_frame_size": frame_size,
        "actual_cell_size": (actual_cell_w, actual_cell_h),
        "frames": frames_info,
        "total_frames": len(frames_info),
        "frames_with_content": sum(1 for f in frames_info if f["has_content"])
    }


def get_content_bbox(img):
    """Obtiene el bounding box del contenido no transparente."""
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    
    # Obtener canal alpha
    alpha = img.split()[3]
    
    # Encontrar bounding box de píxeles no transparentes
    bbox = alpha.getbbox()
    return bbox


def get_center_of_mass(img):
    """Calcula el centro de masas del contenido no transparente."""
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    
    alpha = img.split()[3]
    pixels = alpha.load()
    width, height = alpha.size
    
    total_weight = 0
    sum_x = 0
    sum_y = 0
    
    for y in range(height):
        for x in range(width):
            weight = pixels[x, y]
            if weight > 0:
                total_weight += weight
                sum_x += x * weight
                sum_y += y * weight
    
    if total_weight == 0:
        return None
    
    return (sum_x / total_weight, sum_y / total_weight)


def process_spritesheet(filepath, spec, analysis):
    """Procesa un spritesheet: extrae frames, recentra y reconstruye."""
    img = Image.open(filepath)
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    
    grid = spec["grid"]
    target_frame_size = spec["frame_size"]
    target_sheet_size = spec["sheet_size"]
    
    actual_cell_w = img.size[0] / grid[0]
    actual_cell_h = img.size[1] / grid[1]
    
    processed_frames = []
    
    for frame_info in analysis["frames"]:
        col = frame_info["col"]
        row = frame_info["row"]
        
        # Extraer celda original
        x = int(col * actual_cell_w)
        y = int(row * actual_cell_h)
        w = int(actual_cell_w)
        h = int(actual_cell_h)
        
        cell = img.crop((x, y, x + w, y + h))
        
        # Procesar el frame
        processed = process_single_frame(cell, target_frame_size, frame_info)
        processed_frames.append(processed)
    
    # Reconstruir spritesheet
    new_sheet = Image.new("RGBA", target_sheet_size, (0, 0, 0, 0))
    
    for i, frame in enumerate(processed_frames):
        col = i % grid[0]
        row = i // grid[0]
        x = col * target_frame_size[0]
        y = row * target_frame_size[1]
        new_sheet.paste(frame, (x, y))
    
    return new_sheet


def process_single_frame(cell, target_size, frame_info):
    """Procesa un frame individual: detecta contenido, centra y reescala si es necesario."""
    bbox = frame_info["content_bbox"]
    
    if bbox is None:
        # Frame vacío - devolver frame transparente del tamaño objetivo
        return Image.new("RGBA", target_size, (0, 0, 0, 0))
    
    # Extraer solo el contenido
    content = cell.crop(bbox)
    content_w, content_h = content.size
    
    # Verificar si el contenido es más grande que el tamaño objetivo
    if content_w > target_size[0] or content_h > target_size[1]:
        # Escalar hacia abajo manteniendo proporción
        scale = min(target_size[0] / content_w, target_size[1] / content_h)
        # Dejar un pequeño margen (95% del espacio disponible)
        scale *= 0.95
        new_w = int(content_w * scale)
        new_h = int(content_h * scale)
        content = content.resize((new_w, new_h), Image.Resampling.LANCZOS)
        content_w, content_h = content.size
    
    # Crear frame del tamaño objetivo y centrar el contenido
    new_frame = Image.new("RGBA", target_size, (0, 0, 0, 0))
    
    # Calcular posición para centrar
    paste_x = (target_size[0] - content_w) // 2
    paste_y = (target_size[1] - content_h) // 2
    
    new_frame.paste(content, (paste_x, paste_y))
    
    return new_frame


def diagnose_all(files):
    """Fase de diagnóstico: analiza todos los archivos."""
    print("\n" + "="*60)
    print("FASE 2: DIAGNÓSTICO")
    print("="*60)
    
    report = {
        "timestamp": datetime.now().isoformat(),
        "files_found": len(files),
        "files_with_specs": 0,
        "files_without_specs": [],
        "size_mismatches": [],
        "analyses": {}
    }
    
    for name, filepath in files.items():
        if name not in SPECS:
            report["files_without_specs"].append(name)
            print(f"  ⚠ Sin spec: {name}")
            continue
        
        report["files_with_specs"] += 1
        spec = SPECS[name]
        
        try:
            analysis = analyze_image(filepath, spec)
            report["analyses"][name] = analysis
            
            status = "✓" if analysis["size_match"] else "⚠"
            actual = f"{analysis['actual_size'][0]}x{analysis['actual_size'][1]}"
            expected = f"{analysis['expected_size'][0]}x{analysis['expected_size'][1]}"
            
            if not analysis["size_match"]:
                report["size_mismatches"].append({
                    "file": name,
                    "actual": analysis["actual_size"],
                    "expected": analysis["expected_size"]
                })
            
            print(f"  {status} {name}")
            print(f"      Actual: {actual} | Esperado: {expected} | Frames con contenido: {analysis['frames_with_content']}/{analysis['total_frames']}")
            
        except Exception as e:
            print(f"  ✗ Error en {name}: {e}")
            report["analyses"][name] = {"error": str(e)}
    
    return report


def process_all(files, report):
    """Fase de procesamiento: procesa todos los archivos."""
    print("\n" + "="*60)
    print("FASE 3: PROCESAMIENTO")
    print("="*60)
    
    processed = 0
    errors = 0
    
    for name, filepath in files.items():
        if name not in SPECS:
            continue
        
        if name not in report["analyses"] or "error" in report["analyses"][name]:
            continue
        
        spec = SPECS[name]
        analysis = report["analyses"][name]
        
        try:
            print(f"  Procesando: {name}...", end=" ")
            
            new_sheet = process_spritesheet(filepath, spec, analysis)
            
            # Guardar (sobrescribir original)
            new_sheet.save(filepath, "PNG")
            
            # Verificar resultado
            verify = Image.open(filepath)
            if verify.size == spec["sheet_size"]:
                print(f"✓ {verify.size[0]}x{verify.size[1]}")
                processed += 1
            else:
                print(f"⚠ Tamaño inesperado: {verify.size}")
                
        except Exception as e:
            print(f"✗ Error: {e}")
            errors += 1
    
    return processed, errors


def main():
    """Función principal."""
    print("\n" + "="*60)
    print("   SPRITESHEET PROCESSOR - VFX ABILITIES")
    print("="*60)
    print(f"  Directorio: {BASE_PATH}")
    print(f"  Specs definidos: {len(SPECS)} archivos")
    
    # FASE 1: Backup
    files = create_backup()
    
    if not files:
        print("\n  ✗ No se encontraron archivos para procesar.")
        return
    
    # FASE 2: Diagnóstico
    report = diagnose_all(files)
    
    # Guardar reporte
    with open(REPORT_PATH, "w", encoding="utf-8") as f:
        # Convertir tipos no serializables
        serializable_report = json.loads(json.dumps(report, default=str))
        json.dump(serializable_report, f, indent=2, ensure_ascii=False)
    print(f"\n  Reporte guardado: {REPORT_PATH}")
    
    # FASE 3: Procesamiento
    print("\n" + "-"*60)
    confirm = input("  ¿Continuar con el procesamiento? (s/n): ").strip().lower()
    
    if confirm == "s":
        processed, errors = process_all(files, report)
        
        print("\n" + "="*60)
        print("   RESUMEN FINAL")
        print("="*60)
        print(f"  Archivos procesados: {processed}")
        print(f"  Errores: {errors}")
        print(f"  Backup en: {BACKUP_PATH}")
        print("="*60)
    else:
        print("\n  Procesamiento cancelado. Solo se creó el backup.")


if __name__ == "__main__":
    main()
