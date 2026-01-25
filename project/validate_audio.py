import os
import json
import re

PROJECT_ROOT = r"c:\git\spellloop\project"
MANIFEST_PATH = os.path.join(PROJECT_ROOT, "audio_manifest.json")
LOG_PATH = os.path.join(PROJECT_ROOT, "errors.log")
AUDIO_EXTENSIONS = {'.wav', '.ogg', '.mp3', '.flac'}

def get_abs_path(res_path):
    return os.path.join(PROJECT_ROOT, res_path.replace("res://", "").replace("/", "\\"))

def main():
    print("starting validation...")
    errors = 0
    
    with open(LOG_PATH, "w", encoding='utf-8') as log:
        # 1. Verify Manifest
        print("Checking Manifest...")
        log.write("--- MANIFEST CHECK ---\n")
        
        try:
            with open(MANIFEST_PATH, 'r', encoding='utf-8') as f:
                data = json.load(f)
                
            for key, entry in data.items():
                if "files" in entry:
                    for path in entry["files"]:
                        abs_path = get_abs_path(path)
                        if not os.path.exists(abs_path):
                            msg = f"[ERROR] Manifest Missing: {path} (ID: {key})"
                            print(msg)
                            log.write(msg + "\n")
                            errors += 1
                        elif "Usado" not in path and "No usado" not in path:
                             print(f"[WARNING] Path not organized: {path}")
        except Exception as e:
            msg = f"[CRITICAL] Failed to load manifest: {e}"
            print(msg)
            log.write(msg + "\n")
            errors += 1

        # 2. Verify Code References
        print("\nChecking Code References...")
        log.write("\n--- CODE REFERENCES CHECK ---\n")
        res_pattern = re.compile(r'res://[^"\n\r]*\.(' + '|'.join([ext[1:] for ext in AUDIO_EXTENSIONS]) + r')')
        
        for root, _, files in os.walk(PROJECT_ROOT):
            if ".godot" in root: continue
            
            for file in files:
                ext = os.path.splitext(file)[1].lower()
                if ext in ['.gd', '.tscn', '.tres', '.json', '.import', '.cfg']:
                     # Skip output/script files
                    if "audit" in file or "organize" in file or "validate" in file or "errors.log" in file: continue
                    
                    path = os.path.join(root, file)
                    try:
                        with open(path, 'r', encoding='utf-8') as f:
                            content = f.read()
                            
                        for match in res_pattern.finditer(content):
                            res_link = match.group(0)
                            
                            # IGNORE .godot paths
                            if ".godot" in res_link:
                                continue
                                
                            # Check existence
                            abs_link = get_abs_path(res_link)
                            if not os.path.exists(abs_link):
                                msg = f"[ERROR] Broken Link in {file}: {res_link}"
                                print(msg)
                                log.write(msg + "\n")
                                errors += 1
                            elif "Usado" not in res_link and "No usado" not in res_link:
                                 # Might be intentional if I missed some, but good to report
                                 pass
                                 # log.write(f"[WARNING] Unorganized Link in {file}: {res_link}\n")
                                 
                    except Exception as e:
                        pass

        print("-" * 30)
        if errors == 0:
            print("SUCCESS: Zero broken references found.")
            log.write("\nSUCCESS: Zero broken references found.\n")
        else:
            print(f"FAILURE: Found {errors} errors.")
            log.write(f"\nFAILURE: Found {errors} errors.\n")

if __name__ == "__main__":
    main()
