import os
import re

def audit_icons():
    base_dir = r"project/assets/icons"
    files_to_check = [
        r"project/scripts/data/WeaponDatabase.gd",
        r"project/scripts/data/UpgradeDatabase.gd",
        r"project/scripts/data/WeaponUpgradeDatabase.gd"
    ]
    
    missing_files = set()
    found_files = set()
    
    pattern = re.compile(r'res://assets/icons/([^"]+\.png)')
    
    print(f"Auditing icons in {len(files_to_check)} files...")
    
    for file_path in files_to_check:
        if not os.path.exists(file_path):
            print(f"Skipping missing file: {file_path}")
            continue
            
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            matches = pattern.findall(content)
            for icon_name in matches:
                full_path = os.path.join(base_dir, icon_name)
                if not os.path.exists(full_path):
                    missing_files.add(icon_name)
                else:
                    found_files.add(icon_name)

    print(f"Found {len(found_files)} valid icons.")
    print(f"Found {len(missing_files)} MISSING icons:")
    print("-" * 30)
    for missing in sorted(missing_files):
        print(f"MISSING: {missing}")
    print("-" * 30)

if __name__ == "__main__":
    audit_icons()
