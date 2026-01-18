
file_path = r"c:\git\spellloop\project\scripts\core\PlayerStats.gd"

print(f"Scanning {file_path} for duplicates...")

try:
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    definitions = {}
    for i, line in enumerate(lines):
        if "func _update_shield_regen" in line:
            print(f"Found _update_shield_regen at line {i+1}: {line.strip()}")
        if "func" in line and "(" in line:
             name = line.split("func")[1].split("(")[0].strip()
             if name in definitions:
                 print(f"DUPLICATE FOUND: {name} at line {i+1} (previous at {definitions[name]})")
             definitions[name] = i+1

except Exception as e:
    print(f"Error: {e}")
