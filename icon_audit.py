#!/usr/bin/env python3
"""
Auditoría exhaustiva de iconos de items, armas, fusiones y upgrades
"""
import os
import re

# Paths
project_path = r'c:\git\spellloop\project'
icons_path = os.path.join(project_path, 'assets', 'icons')

# Get all existing icon files
existing_icons = set()
if os.path.exists(icons_path):
    for f in os.listdir(icons_path):
        if f.endswith('.png'):
            existing_icons.add(f)

print(f'Total iconos existentes en carpeta: {len(existing_icons)}')
print()

# Database files to scan
db_files = [
    os.path.join(project_path, 'scripts', 'data', 'UpgradeDatabase.gd'),
    os.path.join(project_path, 'scripts', 'data', 'WeaponDatabase.gd'),
    os.path.join(project_path, 'scripts', 'data', 'WeaponUpgradeDatabase.gd'),
    os.path.join(project_path, 'scripts', 'data', 'CharacterDatabase.gd'),
]

# Patterns
icon_pattern = re.compile(r'"icon":\s*"(res://assets/icons/[^"]+)"')
id_pattern = re.compile(r'"id":\s*"([^"]+)"')
name_pattern = re.compile(r'"name":\s*"([^"]+)"')

all_icons_defined = {}
for db_file in db_files:
    if not os.path.exists(db_file):
        print(f'Archivo no encontrado: {db_file}')
        continue
    
    print(f'Escaneando: {os.path.basename(db_file)}')
    
    with open(db_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    current_id = None
    current_name = None
    
    for i, line in enumerate(lines, 1):
        # Find ID
        id_match = id_pattern.search(line)
        if id_match:
            current_id = id_match.group(1)
            current_name = None
        
        # Find name
        name_match = name_pattern.search(line)
        if name_match and not current_name:
            current_name = name_match.group(1)
        
        # Find icon
        icon_match = icon_pattern.search(line)
        if icon_match:
            icon_path = icon_match.group(1)
            if icon_path not in all_icons_defined:
                all_icons_defined[icon_path] = []
            all_icons_defined[icon_path].append({
                'file': os.path.basename(db_file),
                'line': i,
                'id': current_id or 'unknown',
                'name': current_name or 'unknown'
            })

print(f'\nTotal rutas de iconos unicas referenciadas: {len(all_icons_defined)}')

# Check missing icons
missing_icons = []
for icon_path, usages in all_icons_defined.items():
    filename = icon_path.replace('res://assets/icons/', '')
    if filename not in existing_icons:
        missing_icons.append({
            'path': icon_path,
            'filename': filename,
            'usages': usages
        })

print(f'Iconos faltantes: {len(missing_icons)}')
print()

if missing_icons:
    print('='*80)
    print('ICONOS FALTANTES (definidos en codigo pero NO existen en disco)')
    print('='*80)
    for item in sorted(missing_icons, key=lambda x: x['filename']):
        print(f'\n  X {item["filename"]}')
        print(f'    Path: {item["path"]}')
        for u in item['usages']:
            print(f'    - {u["file"]}:{u["line"]} -> ID: {u["id"]}, Name: {u["name"]}')

# Now list icons that exist but aren't referenced
print('\n')
print('='*80)
print('ICONOS HUERFANOS (existen en disco pero NO se usan en ninguna DB)')
print('='*80)
used_filenames = set()
for icon_path in all_icons_defined.keys():
    used_filenames.add(icon_path.replace('res://assets/icons/', ''))

orphan_icons = existing_icons - used_filenames
print(f'Total iconos huerfanos: {len(orphan_icons)}')
for icon in sorted(orphan_icons):
    print(f'  ? {icon}')
