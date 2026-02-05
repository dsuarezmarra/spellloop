"""
Script para procesar todos los spritesheets de VFX en batch.
Utiliza process_spritesheet_smart.py para cada archivo.
"""

import subprocess
import os
from pathlib import Path

# Configuración base
BACKUP_DIR = r"C:\git\loopialike\project\assets\vfx\abilities\_originals_backup"
OUTPUT_DIR = r"C:\git\loopialike\project\assets\vfx\abilities"
SCRIPT = r"C:\git\loopialike\project\tools\process_spritesheet_smart.py"

# Configuración de cada tipo de asset
# Formato: (cols, rows, frame_w, frame_h)
CONFIGS = {
    # Projectiles: 4x2, 64x64
    "projectiles": (4, 2, 64, 64),
    
    # AOE pequeños (stomp, nova, etc.): 4x2, 128x128
    "aoe_small": (4, 2, 128, 128),
    
    # AOE grandes (zones): 4x2, 256x256
    "aoe_large": (4, 2, 256, 256),
    
    # Beams: 6x2, 192x64
    "beams": (6, 2, 192, 64),
    
    # Telegraphs: 4x2, 128x128
    "telegraphs": (4, 2, 128, 128),
    
    # Auras: 6x2, 128x128
    "auras": (6, 2, 128, 128),
    
    # Boss específicos: 4x2, 192x192
    "boss": (4, 2, 192, 192),
}

# Mapeo de archivos a configuraciones
FILE_CONFIGS = {
    # Projectiles
    "projectile_fire_spritesheet.png": "projectiles",
    "projectile_ice_spritesheet.png": "projectiles",
    "projectile_arcane_spritesheet.png": "projectiles",
    "projectile_void_spritesheet.png": "projectiles",
    "projectile_poison_spritesheet.png": "projectiles",
    "projectile_void_homing_spritesheet.png": "projectiles",
    
    # AOE pequeños (stomp, nova, blast, explosion)
    "aoe_fire_stomp_spritesheet.png": "aoe_small",
    "aoe_arcane_nova_spritesheet.png": "aoe_small",
    "aoe_ground_slam_spritesheet.png": "aoe_small",
    "aoe_rune_blast_spritesheet.png": "aoe_small",
    "aoe_void_explosion_spritesheet.png": "aoe_small",
    
    # AOE grandes (zones, impact)
    "aoe_fire_zone_spritesheet.png": "aoe_large",
    "aoe_meteor_impact_spritesheet.png": "aoe_large",
    "aoe_freeze_zone_spritesheet.png": "aoe_large",
    
    # Beams
    "beam_flame_breath_spritesheet.png": "beams",
    "beam_void_beam_spritesheet.png": "beams",
    
    # Telegraphs
    "telegraph_charge_line_spritesheet.png": "telegraphs",
    "telegraph_circle_warning_spritesheet.png": "telegraphs",
    "telegraph_meteor_warning_spritesheet.png": "telegraphs",
    "telegraph_rune_prison_spritesheet.png": "telegraphs",
    
    # Auras
    "aura_buff_corruption_spritesheet.png": "auras",
    "aura_damage_void_spritesheet.png": "auras",
    "aura_elite_floor_spritesheet.png": "auras",
    "aura_enrage_spritesheet.png": "auras",
    
    # Boss específicos
    "boss_summon_circle_spritesheet.png": "boss",
    "boss_reality_tear_spritesheet.png": "boss",
    "boss_void_pull_spritesheet.png": "boss",
    "boss_rune_shield_spritesheet.png": "boss",
}

def find_all_spritesheets():
    """Encuentra todos los spritesheets en el directorio de backup."""
    spritesheets = []
    for root, dirs, files in os.walk(BACKUP_DIR):
        for file in files:
            if file.endswith('.png'):
                input_path = os.path.join(root, file)
                # Calcular ruta de salida manteniendo estructura
                rel_path = os.path.relpath(input_path, BACKUP_DIR)
                output_path = os.path.join(OUTPUT_DIR, rel_path)
                spritesheets.append((input_path, output_path, file))
    return spritesheets

def process_spritesheet(input_path, output_path, filename):
    """Procesa un spritesheet individual."""
    # Obtener configuración
    config_type = FILE_CONFIGS.get(filename)
    if not config_type:
        print(f"⚠ Sin configuración para: {filename}")
        return False
    
    cols, rows, frame_w, frame_h = CONFIGS[config_type]
    
    # Asegurar que el directorio de salida existe
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    # Ejecutar el procesador
    cmd = [
        "python", SCRIPT,
        input_path, output_path,
        str(cols), str(rows), str(frame_w), str(frame_h)
    ]
    
    print(f"\n{'='*60}")
    print(f"Procesando: {filename}")
    print(f"Config: {config_type} ({cols}x{rows}, {frame_w}x{frame_h})")
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode == 0:
        print(result.stdout)
        return True
    else:
        print(f"❌ ERROR:")
        print(result.stderr)
        return False

def main():
    print("="*60)
    print("PROCESAMIENTO BATCH DE SPRITESHEETS VFX")
    print("="*60)
    
    spritesheets = find_all_spritesheets()
    print(f"\nEncontrados: {len(spritesheets)} spritesheets")
    
    success = 0
    failed = 0
    
    for input_path, output_path, filename in spritesheets:
        if process_spritesheet(input_path, output_path, filename):
            success += 1
        else:
            failed += 1
    
    print("\n" + "="*60)
    print("RESUMEN:")
    print(f"  ✓ Exitosos: {success}")
    print(f"  ✗ Fallidos: {failed}")
    print("="*60)

if __name__ == "__main__":
    main()
