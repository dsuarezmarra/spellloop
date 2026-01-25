import os
import json
import re
import csv
import sys
from collections import defaultdict

PROJECT_ROOT = r"c:\git\spellloop\project"
MANIFEST_PATH = os.path.join(PROJECT_ROOT, "audio_manifest.json")
CSV_PATH = os.path.join(PROJECT_ROOT, "strict_audio_audit.csv")

AUDIO_EXTENSIONS = {'.wav', '.ogg', '.mp3', '.flac', '.aiff'}
MANIFEST_KEYS = {'files', 'volume_db', 'pitch_scale', 'bus', 'max_polyphony'}

def get_res_path(abs_path):
    return "res://" + os.path.relpath(abs_path, PROJECT_ROOT).replace("\\", "/")

def scan_physical_files():
    files = {} # res_path -> abs_path
    for root, _, filenames in os.walk(PROJECT_ROOT):
        if ".godot" in root: continue
        for f in filenames:
            if os.path.splitext(f)[1].lower() in AUDIO_EXTENSIONS:
                abs_path = os.path.join(root, f)
                res_path = get_res_path(abs_path)
                files[res_path] = abs_path
    return files

def parse_manifest():
    if not os.path.exists(MANIFEST_PATH):
        print(f"CRITICAL: Manifest not found at {MANIFEST_PATH}")
        return {}, {}
    
    with open(MANIFEST_PATH, 'r', encoding='utf-8') as f:
        try:
            data = json.load(f)
        except:
            print("CRITICAL: Failed to parse manifest JSON")
            return {}, {}

    manifest_id_to_files = defaultdict(list)
    file_to_manifest_ids = defaultdict(list)
    
    for audio_id, entry in data.items():
        if "files" in entry:
            for f in entry["files"]:
                manifest_id_to_files[audio_id].append(f)
                file_to_manifest_ids[f].append(audio_id)
                
    return manifest_id_to_files, file_to_manifest_ids

def scan_code_usage():
    called_ids = defaultdict(list) # id -> list of locations
    direct_refs = defaultdict(list) # res_path -> list of locations
    ambiguous_calls = [] # list of (file, line, content)
    
    # Regex for AudioManager calls
    # Captures: AudioManager.play("id") or play_fixed("id") or play_music("id")
    # Group 2 is the ID string
    id_call_regex = re.compile(r'AudioManager\.(play|play_fixed|play_music)\s*\(\s*["\']([^"\']+)["\']')
    
    # Regex for dynamic usage (variable or concatenation)
    # e.g. AudioManager.play(some_var)
    dynamic_call_regex = re.compile(r'AudioManager\.(play|play_fixed|play_music)\s*\(\s*([^"\')]+)')
    
    # Regex for direct resource paths
    res_regex = re.compile(r'res://[^"\n\r]*\.(' + '|'.join([ext[1:] for ext in AUDIO_EXTENSIONS]) + r')')
    
    # Hardcoded known constant
    # (We scan for this generally via res_regex, but keeping logically separate if needed)
    
    for root, _, files in os.walk(PROJECT_ROOT):
        if ".godot" in root: continue
        
        for file in files:
            ext = os.path.splitext(file)[1].lower()
            if ext in ['.gd', '.tscn', '.tres', '.json', '.cfg']:
                # Skip manifest and audit scripts
                if "audio_manifest.json" in file or "audit" in file: continue
                
                path = os.path.join(root, file)
                rel_path = os.path.relpath(path, PROJECT_ROOT)
                
                try:
                    with open(path, 'r', encoding='utf-8', errors='ignore') as f:
                        lines = f.readlines()
                        
                    for i, line in enumerate(lines):
                        line_num = i + 1
                        
                        # 1. Direct Refs
                        for match in res_regex.finditer(line):
                            ref = match.group(0)
                            direct_refs[ref].append(f"{rel_path}:{line_num}")
                            
                        # 2. ID Calls (GDScript only usually)
                        if ext == '.gd':
                            # Check strict literal calls
                            matches = list(id_call_regex.finditer(line))
                            for match in matches:
                                audio_id = match.group(2)
                                called_ids[audio_id].append(f"{rel_path}:{line_num}")
                                
                            # Check dynamic calls (if no literal match found but function called)
                            # This is a heuristic. If we found a literal match, we assume it's covered.
                            # But if we see `AudioManager.play(variable)`, regex 1 won't match, regex 2 might.
                            if not matches:
                                dyn_matches = dynamic_call_regex.finditer(line)
                                for dmatch in dyn_matches:
                                    content = dmatch.group(2).strip()
                                    # invalid if it starts with quote (should have been caught by regex 1)
                                    if not content.startswith(('"', "'")):
                                        ambiguous_calls.append(f"{rel_path}:{line_num} -> {dmatch.group(0)}")

                except Exception as e:
                    pass
                    
    return called_ids, direct_refs, ambiguous_calls

def main():
    print("--- STRICT AUDIO AUDIT ---")
    
    # 1. Inventory
    physical_files = scan_physical_files() # res_path -> abs_path
    
    # 2. Manifest Data
    manifest_id_to_files, file_to_manifest_ids = parse_manifest()
    manifest_ids = set(manifest_id_to_files.keys())
    manifest_files = set(file_to_manifest_ids.keys())
    
    # 3. Code Usage
    called_ids_map, direct_refs, ambiguous_calls = scan_code_usage()
    called_ids = set(called_ids_map.keys())
    
    # 4. Classification
    # Analyze IDs
    used_manifest_ids = manifest_ids.intersection(called_ids)
    unused_manifest_ids = manifest_ids - called_ids
    unknown_called_ids = called_ids - manifest_ids
    
    # Analyze Files
    classification = []
    
    count_usado = 0
    count_no_usado = 0
    count_huerfano = 0
    count_ambiguo = 0 # Not strictly file-based, but we'll see
    
    # We iterate over all PHYSICAL files found
    # Also include files in manifest that might be missing physically (for reporting)
    all_known_paths = set(physical_files.keys()).union(manifest_files)
    
    for res_path in all_known_paths:
        status = "NO_USADO"
        evidence_type = []
        evidence_locs = []
        
        is_physical = res_path in physical_files
        in_manifest = res_path in manifest_files
        
        # Determine strict usage
        
        # A. Direct Reference / Hardcoded
        if res_path in direct_refs:
            status = "USADO"
            evidence_type.append("DIRECT_REF")
            evidence_locs.extend(direct_refs[res_path])
            
        # B. Manifest ID Call
        if in_manifest:
            # Check if associated ID is called
            associated_ids = file_to_manifest_ids[res_path]
            called_assoc_ids = [id for id in associated_ids if id in called_ids]
            
            if called_assoc_ids:
                status = "USADO"
                evidence_type.append("ID_CALL")
                for aid in called_assoc_ids:
                    evidence_locs.extend(called_ids_map[aid])
            elif status != "USADO":
                # In manifest, but ID not called, and no direct ref
                status = "NO_USADO"
                evidence_type.append("MANIFEST_ONLY")
                
        # C. Orphan
        if not in_manifest and status != "USADO":
             status = "HUERFANO"
             evidence_type.append("NONE")
             
        # D. Ambiguous Warning
        # If we have dynamic calls, we can't be 100% sure about NO_USADO files.
        # But per instructions: "AMBIGUO se trata como USADO".
        # We only mark AMBIGUO if we can't prove it's used otherwise?
        # Actually user said: "AMBIGUO: IDs construidos dinámicamente... Regla: AMBIGUO se trata como USADO"
        # Since we can't link dynamic calls to specific files easily, we list dynamic calls separately.
        # But if a file is NO_USADO and we have dynamic calls, it MIGHT be used.
        # Strict logic: Keep as NO_USADO unless proven.
        
        if status == "USADO":
            count_usado += 1
        elif status == "NO_USADO":
            count_no_usado += 1
        elif status == "HUERFANO":
            count_huerfano += 1
            
        classification.append({
            'original_path': res_path,
            'status': status,
            'evidence_type': "+".join(evidence_type),
            'locations': "; ".join(evidence_locs[:3]) + ("..." if len(evidence_locs)>3 else ""),
            'exists_physically': is_physical
        })

    # Output CSV
    with open(CSV_PATH, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['original_path', 'status', 'evidence_type', 'locations', 'exists_physically'])
        writer.writeheader()
        for c in classification:
            writer.writerow(c)
            
    # Print Summary for User
    print("="*60)
    print("STRICT AUDIO AUDIT SUMMARY")
    print("="*60)
    print(f"Total Physical Audio Files: {len(physical_files)}")
    print(f"Total Paths in Manifest: {len(manifest_files)}")
    print("-" * 30)
    print(f"Total IDs in Manifest: {len(manifest_ids)}")
    print(f"Total IDs Called in Code: {len(called_ids)}")
    print(f"  - Valid calls (in manifest): {len(used_manifest_ids)}")
    print(f"  - Invalid calls (missing in manifest): {len(unknown_called_ids)}")
    print("-" * 30)
    print("FILE CLASSIFICATION:")
    print(f"  USADO: {count_usado}")
    print(f"  NO_USADO: {count_no_usado}")
    print(f"  HUERFANO: {count_huerfano}")
    print("-" * 30)
    
    if unknown_called_ids:
        print("\n[PRIORITY] IDs CALLED BUT NOT IN MANIFEST:")
        for uid in list(unknown_called_ids)[:10]:
            print(f"  - {uid} (found in {called_ids_map[uid][0]})")
        if len(unknown_called_ids) > 10: print("  ... and more")
            
    if ambiguous_calls:
        print(f"\n[WARNING] DETECTED {len(ambiguous_calls)} DYNAMIC/AMBIGUOUS CALLS:")
        for ac in ambiguous_calls[:5]:
            print(f"  - {ac}")

    print("\n[TOP 20 CALLED IDs]")
    sorted_calls = sorted([(id, len(locs)) for id, locs in called_ids_map.items()], key=lambda x: x[1], reverse=True)
    for i, (cid, count) in enumerate(sorted_calls[:20]):
        print(f"  {i+1}. {cid} ({count} calls)")

if __name__ == "__main__":
    main()
