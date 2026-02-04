
import os
import re
import json

PROJECT_ROOT = r"c:\git\spellloop\project"

DATABASES = [
    {
        "path": r"c:\git\spellloop\project\scripts\data\WeaponDatabase.gd",
        "type": "Weapon/Fusion",
        "dict_names": ["WEAPONS", "FUSIONS"]
    },
    {
        "path": r"c:\git\spellloop\project\scripts\data\UpgradeDatabase.gd",
        "type": "Upgrade",
        "dict_names": ["UPGRADES", "CURSED_UPGRADES", "UNIQUE_UPGRADES", "GENERIC_LEVEL_UPGRADES"]
    },
    {
        "path": r"c:\git\spellloop\project\scripts\data\WeaponUpgradeDatabase.gd",
        "type": "WeaponUpgrade",
        "dict_names": ["GLOBAL_UPGRADES", "SPECIFIC_UPGRADES"] # WEAPON_SPECIFIC_UPGRADES has nested integers, skipping for now or adding special handler if needed
    },
    {
        "path": r"c:\git\spellloop\project\scripts\data\CharacterDatabase.gd",
        "type": "Character",
        "dict_names": ["CHARACTERS"]
    }
]

def resolve_res_path(res_path):
    if not res_path:
        return None
    if res_path.startswith("res://"):
        return os.path.join(PROJECT_ROOT, res_path.replace("res://", "").replace("/", os.sep))
    return None

def parse_database(db_info):
    file_path = db_info["path"]
    if not os.path.exists(file_path):
        print(f"Error: Database not found: {file_path}")
        return []

    print(f"Parsing {os.path.basename(file_path)}...")
    with open(file_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    results = []
    
    current_dict = None
    brace_level = 0
    in_dict = False
    
    # Simple state machine
    # 0: Searching for Dictionary start
    # 1: Inside Dictionary (brace_level 1)
    # 2: Inside Item (brace_level 2)
    
    current_item = {}
    current_key = None
    
    for line in lines:
        stripped = line.strip()
        
        # Check for dict start
        if not in_dict:
            for d in db_info["dict_names"]:
                # Matches: const DICT = { or var DICT = {
                if f" {d}" in line and (" = {" in line or ": Dictionary = {" in line or ":={" in line):
                    current_dict = d
                    in_dict = True
                    brace_level = 0
                    # Count initial braces in this line
                    brace_level += line.count("{") - line.count("}")
                    print(f"  Found dictionary: {d}")
                    break
            continue
        
        # We are inside a dictionary
        # Track braces
        open_braces = line.count("{")
        close_braces = line.count("}")
        
        prev_level = brace_level
        brace_level += (open_braces - close_braces)
        
        # Detect start of an item: "key": {
        if brace_level == 2 and prev_level == 1:
            # New item started
            # Extract key
            m = re.search(r'"([^"]+)":\s*{', stripped)
            if m:
                current_key = m.group(1)
                current_item = {"id": current_key} # Default ID to key
        
        # Detect end of an item
        if brace_level == 1 and prev_level == 2:
            # Item closed, save it
            if current_item:
                 # Extract fields from accumulated lines? No, we parse line by line
                 pass
            
            # Post-process item
            obj_id = current_item.get("id", current_key)
            icon = current_item.get("icon")
            
            status = "MISSING_ICON_FIELD"
            icon_exists = False
            if icon:
                local = resolve_res_path(icon)
                if local and os.path.exists(local):
                    status = "OK"
                    icon_exists = True
                else:
                    status = "FILE_NOT_FOUND"
            
            results.append({
                "source": os.path.basename(file_path),
                "dictionary": current_dict,
                "type": db_info["type"],
                "id": obj_id,
                "name": current_item.get("name"),
                "description": current_item.get("description"),
                "icon_path": icon,
                "status": status,
                "exists": icon_exists
            })
            current_item = {}
            current_key = None

        # Capture fields if inside item (level 2)
        if brace_level == 2:
            # Regex for "key": "value"
            # Simple string fields
            m_str = re.search(r'"(id|name|description|icon)":\s*"([^"]+)"', stripped)
            if m_str:
                current_item[m_str.group(1)] = m_str.group(2)

        # Check for dict end
        if brace_level == 0:
            in_dict = False
            current_dict = None

    return results

def main():
    all_items = []
    for db in DATABASES:
        all_items.extend(parse_database(db))
    
    total = len(all_items)
    ok = sum(1 for i in all_items if i["status"] == "OK")
    print(f"Audit Complete. Found {total} items. OK: {ok}")
    
    out_path = os.path.join(os.getcwd(), "audit_results.json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(all_items, f, indent=2)

if __name__ == "__main__":
    main()
