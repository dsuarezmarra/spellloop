#!/usr/bin/env python3
# Quick fix script for string multiplication errors

import os
import re

def fix_string_multiplication(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Fix patterns like "=" * 40 or "-" * 40
        content = re.sub(r'"([=\-])"\s*\*\s*(\d+)', r'"\1".repeat(\2)', content)
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"Fixed {file_path}")
        return True
    except Exception as e:
        print(f"Error fixing {file_path}: {e}")
        return False

# Files to fix
files = [
    r'c:\Users\dsuarez1\git\spellloop\project\scripts\systems\MasterController.gd',
    r'c:\Users\dsuarez1\git\spellloop\project\scripts\systems\IntegrationValidator.gd'
]

for file_path in files:
    if os.path.exists(file_path):
        fix_string_multiplication(file_path)
    else:
        print(f"File not found: {file_path}")