import os
import json
import re
import sys
from pathlib import Path

# Paths (adjusting for script location tools/ -> project root)
PROJECT_ROOT = Path(__file__).parent.parent / "project"
AUDIO_TREE_PATH = PROJECT_ROOT / "audio_tree_current.txt"
MANIFEST_PATH = PROJECT_ROOT / "audio_manifest.json"
REPORT_PATH = PROJECT_ROOT.parent / "docs" / "audio_rehook_report.md"
REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)

# Regex for finding audio refs
REF_REGEX = re.compile(r'(res://audio/[^"\']+\.(?:mp3|wav|ogg|tscn|tres))', re.IGNORECASE)
ID_CALL_REGEX = re.compile(r'AudioManager\.(?:play|play_fixed|play_music)\s*\(\s*["\']([^"\']+)["\']', re.IGNORECASE)

def load_tree():
    """Load existing audio files from tree snapshot."""
    valid_paths = set()
    if not AUDIO_TREE_PATH.exists():
        print(f"Error: {AUDIO_TREE_PATH} not found.")
        return valid_paths
    
    with open(AUDIO_TREE_PATH, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line: continue
            # Format: relative_path|size
            path_part = line.split('|')[0]
            # Convert to res:// format if not already
            if not path_part.startswith("res://"):
                full_path = "res://" + path_part.replace("\\", "/")
            valid_paths.add(full_path)
    return valid_paths

def load_manifest():
    if not MANIFEST_PATH.exists():
        print(f"Error: {MANIFEST_PATH} not found.")
        return {}
    with open(MANIFEST_PATH, 'r', encoding='utf-8') as f:
        return json.load(f)

def scan_codebase():
    """Scan all text files for references."""
    refs = [] # List of (file, line, type, content)
    
    extensions = {'.gd', '.tscn', '.tres', '.json', '.cfg'}
    
    for root, dirs, files in os.walk(PROJECT_ROOT):
        for file in files:
            path = Path(root) / file
            if path.suffix not in extensions:
                continue
            
            # Skip the manifest itself and the input files
            if path.resolve() == MANIFEST_PATH.resolve() or path.name == "audio_tree_current.txt":
                continue

            try:
                rel_path = path.relative_to(PROJECT_ROOT)
                with open(path, 'r', encoding='utf-8', errors='ignore') as f:
                    for i, line in enumerate(f, 1):
                        # check path refs
                        for match in REF_REGEX.findall(line):
                            refs.append({
                                'file': str(rel_path),
                                'line': i,
                                'type': 'path',
                                'value': match,
                                'context': line.strip()
                            })
                        # check id calls
                        for match in ID_CALL_REGEX.findall(line):
                            refs.append({
                                'file': str(rel_path),
                                'line': i,
                                'type': 'id',
                                'value': match,
                                'context': line.strip()
                            })
            except Exception as e:
                print(f"Could not read {path}: {e}")
                
    return refs

def find_replacement(missing_path, valid_paths):
    """Refined matching logic."""
    missing_name = Path(missing_path).name # includes extension
    missing_stem = Path(missing_path).stem # no extension
    
    candidates = []
    
    for valid in valid_paths:
        v_name = Path(valid).name
        v_stem = Path(valid).stem
        
        # 1. Exact Name (ignoring folder)
        if v_name == missing_name:
            return valid, "Exact Name Match"
            
        # 2. Same stem, different extension
        if v_stem == missing_stem:
            candidates.append((valid, "Extension Match"))

        # 3. Family/Prefix Matching (sfx_ui_cancel -> sfx_ui_back)
        # This is harder to genericize, but let's try prefix
        if missing_stem in v_stem and "sfx" in missing_stem:
             candidates.append((valid, "Partial Contain Match"))

    # Select best candidate
    if candidates:
        # Prioritize extension match
        ext_match = next((c for c in candidates if c[1] == "Extension Match"), None)
        if ext_match: return ext_match
        
        return candidates[0]

    return None, "No Match"

def main():
    print("Loading data...")
    existing_files = load_tree()
    manifest = load_manifest()
    
    print("Scanning codebase...")
    code_refs = scan_codebase()
    
    report_lines = []
    report_lines.append("# Audio Rehook Report")
    report_lines.append("")
    
    # 1. Manifest Health
    report_lines.append("## 1. Manifest Health Check")
    manifest_issues = []
    ids_to_disable = []
    manifest_replacements = {} # old_path -> new_path
    
    for key, data in manifest.items():
        files = data.get("files", [])
        new_files = []
        changed = False
        
        for f in files:
            if f not in existing_files:
                new_f, method = find_replacement(f, existing_files)
                if new_f:
                    manifest_issues.append(f"- ID `{key}`: `{f}` missing. -> Found replacement `{new_f}` ({method})")
                    new_files.append(new_f)
                    changed = True
                    manifest_replacements[f] = new_f
                else:
                    manifest_issues.append(f"- ID `{key}`: `{f}` missing. -> **NO REPLACEMENT**")
                    ids_to_disable.append(key)
            else:
                new_files.append(f)
        
        if len(files) == 0:
             manifest_issues.append(f"- ID `{key}`: No files defined.")
             ids_to_disable.append(key)

    if not manifest_issues:
        report_lines.append("No manifest issues found.")
    else:
        report_lines.extend(manifest_issues)

    # 2. Code Reference Health
    report_lines.append("")
    report_lines.append("## 2. Code Reference Check")
    
    code_issues = []
    
    # Check IDs
    defined_ids = set(manifest.keys())
    # Addids that are in the audit but might be missing
    
    path_replacements = {} # old -> new
    
    for ref in code_refs:
        if ref['type'] == 'id':
            if ref['value'] not in defined_ids:
                code_issues.append(f"- Missing ID `{ref['value']}` in `{ref['file']}:{ref['line']}`")
        elif ref['type'] == 'path':
            path_val = ref['value']
            if path_val not in existing_files:
                # Is it already mapped in manifest replacements?
                if path_val in manifest_replacements:
                    new_p = manifest_replacements[path_val]
                    code_issues.append(f"- Broken Path `{path_val}` in `{ref['file']}` -> Known Replacement: `{new_p}`")
                    path_replacements[path_val] = new_p
                else:
                    # Try to find fresh
                    new_p, method = find_replacement(path_val, existing_files)
                    if new_p:
                        code_issues.append(f"- Broken Path `{path_val}` in `{ref['file']}` -> Found: `{new_p}` ({method})")
                        path_replacements[path_val] = new_p
                    else:
                        code_issues.append(f"- Broken Path `{path_val}` in `{ref['file']}` -> **DEAD LINK**")

    if not code_issues:
        report_lines.append("No code reference issues found.")
    else:
        report_lines.extend(code_issues)

    # 3. Summary of Actions
    report_lines.append("")
    report_lines.append("## 3. Plan of Action")
    report_lines.append("### Manifest Updates")
    if manifest_replacements:
        report_lines.append(f"- Update {len(manifest_replacements)} file paths in `audio_manifest.json`.")
    if ids_to_disable:
        report_lines.append(f"- Disable/Remove {len(ids_to_disable)} IDs in manifest: {', '.join(ids_to_disable)}")
        
    report_lines.append("### Code Updates")
    if path_replacements:
        report_lines.append(f"- Replace {len(path_replacements)} direct file paths in code/resources.")
        
    # Write Report
    with open(REPORT_PATH, 'w', encoding='utf-8') as f:
        f.write("\n".join(report_lines))
    
    print(f"Report generated at {REPORT_PATH}")
    
    # Save a JSON map for the agent to use
    plan = {
        "manifest_replacements": manifest_replacements,
        "path_replacements": path_replacements,
        "ids_to_disable": ids_to_disable
    }
    with open(PROJECT_ROOT / "audio_fix_plan.json", 'w') as f:
        json.dump(plan, f, indent=2)

if __name__ == "__main__":
    main()
