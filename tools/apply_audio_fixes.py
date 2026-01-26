import json
import os
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent / "project"
FIX_PLAN_PATH = PROJECT_ROOT / "audio_fix_plan.json"
MANIFEST_PATH = PROJECT_ROOT / "audio_manifest.json"

def apply_fixes():
    print("Loading fix plan...")
    with open(FIX_PLAN_PATH, 'r') as f:
        plan = json.load(f)

    manifest_replacements = plan.get("manifest_replacements", {})
    ids_to_disable = set(plan.get("ids_to_disable", []))
    path_replacements = plan.get("path_replacements", {})

    # 1. Update Manifest
    print("Updating Audio Manifest...")
    with open(MANIFEST_PATH, 'r', encoding='utf-8') as f:
        manifest = json.load(f)

    updated_manifest_count = 0
    disabled_count = 0
    
    for key, entry in manifest.items():
        files = entry.get("files", [])
        new_files = []
        is_modified = False
        
        # Check if ID should be disabled (unless we found a fix for some of its files)
        # However, the plan "ids_to_disable" lists keys where *no* replacement was found for *any* file?
        # Actually my audit script added to ids_to_disable if *any* file was missing and had no replacement.
        # But wait, looking at the report:
        # ID sfx_streak: ...01 missing -> NO REPLACEMENT
        # ID sfx_streak: ...02 missing -> NO REPLACEMENT
        # ...
        # If I have partial replacements, I should keep the good files.
        # But the audit script said "ID ... missing -> NO".
        
        # Let's process per file
        for fpath in files:
            if fpath in manifest_replacements:
                new_files.append(manifest_replacements[fpath])
                is_modified = True
                updated_manifest_count += 1
            else:
                # If path is NOT in replacements, check if it was marked as missing?
                # My audit script logic: if missing and no replacement -> ids_to_disable.
                # So if it's in ids_to_disable list (which is a list of keys, but duplicate keys allowed in the printed list, effectively a set of keys with issues),
                # we need to be careful. The json input for ids_to_disable is a LIST of keys. 
                # If a key is in ids_to_disable, it means AT LEAST ONE file was missing with no replacement.
                # But if some files were valid, they aren't "missing".
                # The audit script was:
                # for ... if missing: find_replacement... else: ids_to_disable.append(key)
                
                # So I should check availability again? Or assume if not in manifest_replacements AND the key is in ids_to_disable, then this specific file is the bad one?
                # Actually, simply:
                # new_files = [manifest_replacements.get(f, f) for f in files]
                # Then, traverse new_files. If I can't verify existence easily here (I don't have the tree loaded), I might rely on the plan.
                # But the plan didn't give me the "keep valid files" list.
                # Logic: The user wants "NO crashea... Dejar el sonido como 'silencioso'".
                # So for the keys in "ids_to_disable", I should empty the list IF I can't guarantee validity?
                # BETTER APPROACH:
                # The audit script put keys in `ids_to_disable` if they had *unresolvable* missing files.
                # It did NOT put them there if *all* missing files were resolved.
                # So if a key is in ids_to_disable, it has at least one dead reference.
                # We should remove the dead references. References NOT in `manifest_replacements` are either:
                # a) Already valid
                # b) Dead and unreplaceable
                # Since I don't have the "already valid" list here easily without reloading the tree...
                # I will trust the "Source of Truth" philosophy:
                # "Si no existe, es que NO lo queremos".
                # I will read the tree again to filter.
                pass
        
    # Re-verify against tree to be safe
    tree_path = PROJECT_ROOT / "audio_tree_current.txt"
    valid_paths = set()
    with open(tree_path, 'r', encoding='utf-8') as f:
         for line in f:
            if not line.strip(): continue
            p = line.split('|')[0]
            if not p.startswith("res://"): p = "res://" + p.replace("\\", "/")
            valid_paths.add(p)

    for key, entry in manifest.items():
        original_files = entry.get("files", [])
        final_files = []
        
        for fpath in original_files:
            # 1. Apply replacement if exists
            current_path = manifest_replacements.get(fpath, fpath)
            
            # 2. Check validity
            if current_path in valid_paths:
                final_files.append(current_path)
            else:
                # It's dead and has no replacement
                print(f"Dropping dead file for {key}: {current_path}")
        
        entry["files"] = final_files
        
        # If files became empty, that's fine (silence)
        if not final_files and original_files:
            disabled_count += 1
            
    with open(MANIFEST_PATH, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, indent=2)
    
    print(f"Manifest updated. {disabled_count} IDs became empty/silent.")

    # 2. Update Codebase (Path Replacements)
    print("Updating Codebase Paths...")
    for old_p, new_p in path_replacements.items():
        # This is a brute force scan for the string, but limited to the file identified in report?
        # The JSON plan doesn't link path_replacement to file. It just says "replace this string".
        # Searching globally for the string is safer if the string is unique. `res://...` usually is.
        # usage: replace string in all files in PROJECT_ROOT.
        for root, dirs, files in os.walk(PROJECT_ROOT):
            for filename in files:
                if filename.endswith((".gd", ".tscn", ".tres", ".json", ".cfg")):
                    filepath = Path(root) / filename
                    if filepath.resolve() == MANIFEST_PATH.resolve(): continue
                    
                    try:
                        with open(filepath, 'r', encoding='utf-8') as f:
                            content = f.read()
                        
                        if old_p in content:
                            new_content = content.replace(old_p, new_p)
                            with open(filepath, 'w', encoding='utf-8') as f:
                                f.write(new_content)
                            print(f"Updated {filepath.name}")
                    except Exception as e:
                        print(f"Error reading {filepath}: {e}")

if __name__ == "__main__":
    apply_fixes()
