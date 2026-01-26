import os
import json
from pathlib import Path
import sys

# Exit codes
MATCH_OK = 0
MATCH_ERROR = 1

PROJECT_ROOT = Path(__file__).parent.parent / "project"
MANIFEST_PATH = PROJECT_ROOT / "audio_manifest.json"

def get_all_resource_files():
    files = set()
    for root, dirs, filenames in os.walk(PROJECT_ROOT):
        for name in filenames:
            full_path = Path(root) / name
            rel_path = full_path.relative_to(PROJECT_ROOT)
            res_path = "res://" + str(rel_path).replace("\\", "/")
            files.add(res_path)
    return files

def validate():
    with open("validation_errors.log", "w", encoding="utf-8") as log_file:
        def log(msg):
            print(msg)
            try:
                log_file.write(str(msg) + "\n")
            except Exception:
                pass

        log("Gathering existing files...")
        existing_files = get_all_resource_files()
        
        errors = 0
        
        # 1. Validate Manifest
        log("\n--- Validating Manifest ---")
        if not MANIFEST_PATH.exists():
            log("CRITICAL: Manifest not found!")
            sys.exit(MATCH_ERROR)
            
        with open(MANIFEST_PATH, 'r', encoding='utf-8') as f:
            manifest = json.load(f)
            
        for key, entry in manifest.items():
            files = entry.get("files", [])
            for fpath in files:
                if fpath not in existing_files:
                    log(f"[Manifest] Error: ID '{key}' points to missing file '{fpath}'")
                    errors += 1
                    
        # 2. Validate Codebase Direct References
        log("\n--- Validating Codebase Direct References ---")
        
        extensions_to_scan = {'.gd', '.tscn', '.tres', '.json', '.cfg'}
        
        for root, dirs, filenames in os.walk(PROJECT_ROOT):
            for name in filenames:
                fpath = Path(root) / name
                if fpath.suffix not in extensions_to_scan: continue
                if fpath.resolve() == MANIFEST_PATH.resolve(): continue
                # Skip the audit/fix/validate tools themselves
                if "validate_audio_refs" in name or "audio_audit" in name: continue

                try:
                    with open(fpath, 'r', encoding='utf-8', errors='ignore') as f:
                        lines = f.readlines()
                    
                    for i, line in enumerate(lines, 1):
                        start_idx = 0
                        while True:
                            idx = line.find("res://audio/", start_idx)
                            if idx == -1: break
                            
                            end_idx = idx
                            # Heuristic end
                            while end_idx < len(line) and line[end_idx] not in ('"', "'", "\n", ",", "<", ")", " ", "}"):
                                end_idx += 1
                                
                            path_str = line[idx:end_idx].strip()
                            # Strip trailing punctuation if caught
                            if path_str.endswith('"') or path_str.endswith("'"): path_str = path_str[:-1]
                            
                            if not path_str:
                                start_idx = end_idx
                                continue

                            # Check existence
                            if path_str not in existing_files and not path_str.endswith(".import"):
                                # check if directory
                                if not any(f.startswith(path_str) for f in existing_files):
                                     log(f"[Code] Broken Path in {name}:{i}: {path_str}")
                                     errors += 1
                            
                            start_idx = end_idx
                except Exception as e:
                    # log(f"Error reading {fpath}: {e}")
                    pass

        log(f"\nValidation Complete. Errors: {errors}")
        if errors > 0:
            sys.exit(MATCH_ERROR)
        else:
            log("SUCCESS: All Audio References Valid.")
            sys.exit(MATCH_OK)

if __name__ == "__main__":
    validate()
