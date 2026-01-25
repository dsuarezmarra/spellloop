import os
import json
import re
import csv
import sys

PROJECT_ROOT = r"c:\git\spellloop\project"
MANIFEST_PATH = os.path.join(PROJECT_ROOT, "audio_manifest.json")
HARDCODED_PATHS = {
    "res://assets/audio/sfx/pickups/sfx_coin_pickup.wav" # From AudioManager.gd
}

AUDIO_EXTENSIONS = {'.wav', '.ogg', '.mp3', '.flac', '.aiff'}

def get_res_path(abs_path):
    return "res://" + os.path.relpath(abs_path, PROJECT_ROOT).replace("\\", "/")

def scan_audio_files():
    audio_files = []
    for root, _, files in os.walk(PROJECT_ROOT):
        # Skip .godot folder
        if ".godot" in root:
            continue
        for file in files:
            if os.path.splitext(file)[1].lower() in AUDIO_EXTENSIONS:
                abs_path = os.path.join(root, file)
                audio_files.append({
                    'abs_path': abs_path,
                    'res_path': get_res_path(abs_path)
                })
    return audio_files

def load_manifest():
    if not os.path.exists(MANIFEST_PATH):
        print(f"ERROR: Manifest not found at {MANIFEST_PATH}")
        return {}, set()
    
    with open(MANIFEST_PATH, 'r', encoding='utf-8') as f:
        try:
            data = json.load(f)
        except json.JSONDecodeError as e:
            print(f"ERROR: Failed to parse manifest: {e}")
            return {}, set()
            
    manifest_paths = set()
    manifest_ids = set()
    
    for key, entry in data.items():
        manifest_ids.add(key)
        if "files" in entry:
            for path in entry["files"]:
                manifest_paths.add(path)
                
    return manifest_ids, manifest_paths

def scan_code_refs():
    direct_refs = set()
    used_ids = set()
    
    # Regex patterns
    # Matches res://... .audio_ext
    res_pattern = re.compile(r'res://[^"\n\r]*\.(' + '|'.join([ext[1:] for ext in AUDIO_EXTENSIONS]) + r')')
    # Matches AudioManager.play("id") etc
    # We look for play, play_fixed, play_music with a string literal
    play_pattern = re.compile(r'AudioManager\.(play|play_fixed|play_music)\s*\(\s*["\']([^"\']+)["\']')
    
    for root, _, files in os.walk(PROJECT_ROOT):
        if ".godot" in root:
            continue
            
        for file in files:
            ext = os.path.splitext(file)[1].lower()
            if ext in ['.gd', '.tscn', '.tres', '.json', '.cfg']:
                # Skip manifest itself to avoid self-reference counting
                if os.path.basename(file) == "audio_manifest.json":
                    continue
                    
                path = os.path.join(root, file)
                try:
                    with open(path, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                        
                        # Find Direct Refs
                        for match in res_pattern.finditer(content):
                            direct_refs.add(match.group(0))
                            
                        # Find IDs (only in scripts usually, but maybe scenes calling methods)
                        if ext == '.gd':
                            for match in play_pattern.finditer(content):
                                used_ids.add(match.group(2))
                except Exception as e:
                    print(f"Warning reading {file}: {e}")
                    
    return direct_refs, used_ids

def main():
    print(f"Scanning project: {PROJECT_ROOT}")
    
    # 1. Inventory
    audio_files = scan_audio_files()
    audio_res_paths = {a['res_path'] for a in audio_files}
    
    # 2. Evidence Layers
    manifest_ids, manifest_paths = load_manifest()
    direct_refs, used_ids_code = scan_code_refs()
    
    # 3. Analyze IDs
    # IDs used in code that are NOT in manifest
    missing_ids = used_ids_code - manifest_ids
    
    # 4. Classification
    classification = []
    
    used_count = 0
    unused_count = 0
    
    # Valid manifest paths (that actually exist)
    # We track this to report "manifest paths not found"
    missing_files_in_manifest = manifest_paths - audio_res_paths
    
    for audio in audio_files:
        p = audio['res_path']
        evidence = []
        is_used = False
        
        # Layer 1: Manifest
        if p in manifest_paths:
            is_used = True
            evidence.append("MANIFEST")
            
        # Layer 2: Direct Ref
        if p in direct_refs:
            is_used = True
            evidence.append("DIRECT_REF")
            
        # Layer 4: Hardcoded
        if p in HARDCODED_PATHS:
            is_used = True
            evidence.append("HARDCODED")
            
        # Determine Status
        status = "NO_USADO"
        if is_used:
            status = "USADO"
            used_count += 1
        else:
            unused_count += 1
            
        classification.append({
            'original_path': p,
            'status': status,
            'evidence_type': "+".join(evidence) if evidence else "NONE",
            'abs_path': audio['abs_path']
        })

    # Report
    print("-" * 50)
    print(f"MANIFEST LOCATION: {MANIFEST_PATH}")
    print("-" * 50)
    print(f"Total Audio Files Found: {len(audio_files)}")
    print(f"Total Paths in Manifest: {len(manifest_paths)}")
    print(f"  - Valid: {len(manifest_paths - missing_files_in_manifest)}")
    print(f"  - Missing/Invalid: {len(missing_files_in_manifest)}")
    if missing_files_in_manifest:
         print(f"    Missing files: {list(missing_files_in_manifest)[:5]}...")
    print("-" * 50)
    print(f"Used IDs found in code: {len(used_ids_code)}")
    print(f"  - IDs valid in Manifest: {len(used_ids_code & manifest_ids)}")
    print(f"  - IDs MISSING from Manifest: {len(missing_ids)}")
    if missing_ids:
        print(f"    Warning: Missing IDs: {list(missing_ids)}")
    print("-" * 50)
    print(f"CLASSIFICATION PREVIEW:")
    print(f"  USADO: {used_count}")
    print(f"  NO USADO: {unused_count}")
    print("-" * 50)
    
    # Write CSV
    csv_path = os.path.join(PROJECT_ROOT, "audio_audit_preview.csv")
    with open(csv_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['original_path', 'status', 'evidence_type'])
        writer.writeheader()
        for c in classification:
            writer.writerow({
                'original_path': c['original_path'],
                'status': c['status'],
                'evidence_type': c['evidence_type']
            })
            
    print(f"CSV Report generated at: {csv_path}")

if __name__ == "__main__":
    main()
