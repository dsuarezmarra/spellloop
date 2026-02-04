#!/usr/bin/env python3
"""
Auditoría EXHAUSTIVA de iconos - Parte 2
Busca items sin campo icon y analiza scripts de armas
"""
import os
import re

project_path = r'c:\git\spellloop\project'

# Database files
db_files = [
    os.path.join(project_path, 'scripts', 'data', 'UpgradeDatabase.gd'),
    os.path.join(project_path, 'scripts', 'data', 'WeaponDatabase.gd'),
    os.path.join(project_path, 'scripts', 'data', 'WeaponUpgradeDatabase.gd'),
    os.path.join(project_path, 'scripts', 'data', 'CharacterDatabase.gd'),
]

print('='*80)
print('ITEMS SIN CAMPO "icon" DEFINIDO')
print('='*80)

for db_file in db_files:
    if not os.path.exists(db_file):
        continue
    
    with open(db_file, 'r', encoding='utf-8') as f:
        content = f.read()
        lines = content.split('\n')
    
    # Find all item/upgrade blocks
    in_block = False
    block_lines = []
    block_start = 0
    brace_count = 0
    current_id = None
    current_name = None
    
    items_without_icon = []
    
    for i, line in enumerate(lines, 1):
        # Track opening of item block
        if '"id":' in line and '{' in lines[i-2:i][0] if i > 1 else False:
            block_start = i
            
        # Find ID
        if '"id":' in line:
            match = re.search(r'"id":\s*"([^"]+)"', line)
            if match:
                current_id = match.group(1)
                current_name = None
                brace_count = 1
                in_block = True
                block_lines = []
                block_start = i
                
        if in_block:
            block_lines.append(line)
            brace_count += line.count('{') - line.count('}')
            
            # Find name
            if '"name":' in line and not current_name:
                match = re.search(r'"name":\s*"([^"]+)"', line)
                if match:
                    current_name = match.group(1)
            
            # Block ended
            if brace_count <= 0:
                # Check if this block has an icon
                block_text = '\n'.join(block_lines)
                if '"icon":' not in block_text and current_id:
                    # Exclude level upgrade dictionaries (they use numbers as keys)
                    if not current_id.isdigit():
                        items_without_icon.append({
                            'id': current_id,
                            'name': current_name or 'unknown',
                            'file': os.path.basename(db_file),
                            'line': block_start
                        })
                
                in_block = False
                current_id = None
                current_name = None
    
    if items_without_icon:
        print(f'\n{os.path.basename(db_file)}:')
        for item in items_without_icon:
            print(f'  - Line {item["line"]}: ID="{item["id"]}", Name="{item["name"]}"')

# Now search for icon references in weapon scripts
print('\n')
print('='*80)
print('BUSQUEDA EN SCRIPTS DE ARMAS (weapons/*.gd)')
print('='*80)

weapons_path = os.path.join(project_path, 'scripts', 'weapons')
if os.path.exists(weapons_path):
    for root, dirs, files in os.walk(weapons_path):
        for f in files:
            if f.endswith('.gd'):
                filepath = os.path.join(root, f)
                with open(filepath, 'r', encoding='utf-8') as file:
                    lines = file.readlines()
                
                for i, line in enumerate(lines, 1):
                    # Look for icon assignments or get_icon functions
                    if 'icon' in line.lower() and ('res://' in line or 'get_icon' in line or 'func' in line):
                        if 'icon' in line:
                            print(f'{f}:{i} -> {line.strip()[:100]}')

# Search for texture_path assignments
print('\n')
print('='*80)
print('BUSQUEDA DE texture_path EN BASES DE DATOS')
print('='*80)

for db_file in db_files:
    if not os.path.exists(db_file):
        continue
    
    with open(db_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    for i, line in enumerate(lines, 1):
        if '"texture_path":' in line:
            match = re.search(r'"texture_path":\s*"([^"]+)"', line)
            if match:
                path = match.group(1)
                # Check if file exists
                file_path = path.replace('res://', project_path + os.sep).replace('/', os.sep)
                exists = os.path.exists(file_path)
                status = '✓' if exists else 'X FALTANTE'
                print(f'{os.path.basename(db_file)}:{i} -> {path} [{status}]')
