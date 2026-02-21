"""
clean_debug_prints.py
Elimina líneas de debug comentadas muertas en archivos .gd de Loopialike.

Patrones eliminados:
  - Líneas que SOLO contienen: # Debug desactivado: ...
  - Líneas que SOLO contienen: # print(...) o #print(...)
  - Líneas vacías generadas al eliminar las anteriores (máx 2 consecutivas)

NO elimina:
  - Comentarios reales que explican código
  - Bloques de comentario multi-línea
  - Prints activos
"""

import re
import os
from pathlib import Path

SCRIPTS_DIR = Path(r"c:\git\loopialike\project\scripts")

# Patrones de líneas a eliminar (la línea completa es el comentario)
DEAD_PATTERNS = [
    re.compile(r'^\s*# Debug desactivado:.*$'),
    re.compile(r'^\s*# print\(.*'),
    re.compile(r'^\s*#print\(.*'),
    # Balance debug logs desactivados
    re.compile(r'^\s*# Balance Debug:.*$'),
    re.compile(r'^\s*# Debug LOGS\s*$'),
    re.compile(r'^\s*# PRINT DEBUG\s*$'),
]

total_files = 0
total_removed = 0
modified_files = []

for gd_file in SCRIPTS_DIR.rglob("*.gd"):
    original = gd_file.read_text(encoding='utf-8')
    lines = original.splitlines(keepends=True)
    
    new_lines = []
    removed_in_file = 0
    
    for line in lines:
        stripped = line.rstrip('\r\n')
        should_remove = any(p.match(stripped) for p in DEAD_PATTERNS)
        if should_remove:
            removed_in_file += 1
        else:
            new_lines.append(line)
    
    if removed_in_file > 0:
        # Collapse triple+ blank lines into double blank lines
        collapsed = []
        blank_run = 0
        for line in new_lines:
            if line.strip() == '':
                blank_run += 1
                if blank_run <= 2:
                    collapsed.append(line)
            else:
                blank_run = 0
                collapsed.append(line)
        
        new_content = ''.join(collapsed)
        gd_file.write_text(new_content, encoding='utf-8')
        modified_files.append((gd_file.name, removed_in_file))
        total_removed += removed_in_file
        total_files += 1

print(f"\n✅ Limpieza completada:")
print(f"   Archivos modificados: {total_files}")
print(f"   Líneas eliminadas: {total_removed}")
print(f"\nDetalle por archivo:")
for name, count in sorted(modified_files, key=lambda x: -x[1]):
    print(f"   {count:3d}  {name}")
