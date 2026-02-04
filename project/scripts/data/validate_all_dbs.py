import re
import os

def validate_file(path, report_file):
    report_file.write(f"Scanning {os.path.basename(path)}...\n")
    try:
        with open(path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception as e:
        report_file.write(f"  ❌ Failed to read file: {e}\n")
        return

    current_key = None
    has_id = False
    found_errors = False
    
    for i, line in enumerate(lines):
        line = line.strip()
        
        # Regex for key definition: "key": {
        # Matches typical GDScript dictionary key assignment at top level or indented
        key_match = re.match(r'"([^"]+)":\s*{', line)
        if key_match:
            # If we were processing a previous key, check if it had an ID
            if current_key and not has_id:
                report_file.write(f"  ❌ Line {i}: Key '{current_key}' is MISSING 'id' field!\n")
                found_errors = True
            
            current_key = key_match.group(1)
            has_id = False
            continue
            
        if current_key:
            # Check for id field. 
            # Note: simplistic check, assumes "id": "val" is on its own line or closely follows
            if '"id":' in line:
                has_id = True
            # End of dict block
            elif line.startswith('},'):
                if not has_id:
                    report_file.write(f"  ❌ Line {i}: Key '{current_key}' is MISSING 'id' field!\n")
                    found_errors = True
                current_key = None
                has_id = False
                
    # Check the very last entry if file ends without comma/bracket logic behaving as expected
    if current_key and not has_id:
        report_file.write(f"  ❌ EOF: Key '{current_key}' is MISSING 'id' field!\n")
        found_errors = True
        
    if not found_errors:
        report_file.write("  ✅ All entries have IDs.\n")
    report_file.write("-" * 40 + "\n")

if __name__ == "__main__":
    output_path = r"c:\git\spellloop\project\scripts\data\validation_report.txt"
    print(f"Writing report to {output_path}")
    with open(output_path, "w", encoding="utf-8") as f:
        validate_file(r"c:\git\spellloop\project\scripts\data\UpgradeDatabase.gd", f)
        validate_file(r"c:\git\spellloop\project\scripts\data\WeaponUpgradeDatabase.gd", f)
