import os
import json
import re
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent / "project"
MANIFEST_PATH = PROJECT_ROOT / "audio_manifest.json"
AUDIO_DIR = PROJECT_ROOT / "audio"
DOCS_DIR = PROJECT_ROOT.parent / "docs"

# Regex for finding ID calls
# AudioManager.play("id")
# AudioManager.play_fixed("id")
# AudioManager.play_music("id")
ID_CALL_REGEX = re.compile(r'AudioManager\.(?:play|play_fixed|play_music)\s*\(\s*["\']([^"\']+)["\']', re.IGNORECASE)

def get_used_ids():
    used_ids = {} # id -> list of {file, line, context}
    
    extensions = {'.gd', '.tscn', '.tres'}
    
    for root, dirs, files in os.walk(PROJECT_ROOT):
        for name in files:
            fpath = Path(root) / name
            if fpath.suffix not in extensions: continue
            
            try:
                rel_path = fpath.relative_to(PROJECT_ROOT)
                with open(fpath, 'r', encoding='utf-8', errors='ignore') as f:
                    for i, line in enumerate(f, 1):
                        for match in ID_CALL_REGEX.findall(line):
                            audio_id = match
                            if audio_id not in used_ids:
                                used_ids[audio_id] = []
                            
                            context = "code"
                            if "music" in audio_id.lower(): context = "music"
                            elif "ui" in audio_id.lower(): context = "ui"
                            elif "gameplay" in str(rel_path).lower(): context = "gameplay"
                            
                            used_ids[audio_id].append({
                                "file": str(rel_path),
                                "line": i,
                                "context": context,
                                "snippet": line.strip()
                            })
            except Exception:
                pass
                
    return used_ids

def get_existing_files():
    files = set()
    for root, dirs, filenames in os.walk(AUDIO_DIR):
        for name in filenames:
            if name.endswith(".import"): continue
            full_path = Path(root) / name
            rel_path = full_path.relative_to(PROJECT_ROOT)
            files.add("res://" + str(rel_path).replace("\\", "/"))
    return files

def load_manifest():
    if not MANIFEST_PATH.exists(): return {}
    with open(MANIFEST_PATH, 'r', encoding='utf-8') as f:
        return json.load(f)

def generate_reports():
    print("Scanning usage...")
    used_ids_map = get_used_ids()
    print("Scanning files...")
    existing_files = get_existing_files()
    print("Loading manifest...")
    manifest = load_manifest()
    
    # 1. USED_AUDIO_IDS.md
    lines = ["# Used Audio IDs Audit", "", "| ID | Context | Location |", "|---|---|---|"]
    
    sorted_ids = sorted(used_ids_map.keys())
    for aid in sorted_ids:
        for usage in used_ids_map[aid]:
            lines.append(f"| `{aid}` | {usage['context']} | `{usage['file']}:{usage['line']}` |")
            
    with open(PROJECT_ROOT.parent / "USED_AUDIO_IDS.md", "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
        
    # 2. AUDIO_GAPS_REPORT.md
    gaps_lines = ["# Audio Gaps & Issues Report", ""]
    
    # Classification
    missing_in_manifest = []
    manifest_empty_files = []
    manifest_broken_paths = []
    
    # Check used vs manifest
    for aid in sorted_ids:
        if aid not in manifest:
            missing_in_manifest.append(aid)
            
    # Check manifest health
    for aid, data in manifest.items():
        files = data.get("files", [])
        if not files:
            manifest_empty_files.append(aid)
        else:
            for f in files:
                if f not in existing_files:
                    manifest_broken_paths.append(f"ID `{aid}` -> Path `{f}`")
                    
    gaps_lines.append(f"## IDs Used but Missing in Manifest ({len(missing_in_manifest)})")
    if missing_in_manifest:
        for mid in missing_in_manifest:
            gaps_lines.append(f"- `{mid}` (Used in {len(used_ids_map[mid])} places)")
    else:
        gaps_lines.append("None.")
        
    gaps_lines.append(f"\n## IDs in Manifest with Empty Files ({len(manifest_empty_files)})")
    if manifest_empty_files:
        for mid in manifest_empty_files:
            gaps_lines.append(f"- `{mid}`")
    else:
        gaps_lines.append("None.")

    gaps_lines.append(f"\n## Broken File Paths in Manifest ({len(manifest_broken_paths)})")
    if manifest_broken_paths:
        for err in manifest_broken_paths:
            gaps_lines.append(f"- {err}")
    else:
        gaps_lines.append("None.")
        
    with open(PROJECT_ROOT.parent / "AUDIO_GAPS_REPORT.md", "w", encoding="utf-8") as f:
        f.write("\n".join(gaps_lines))
        
    print("Reports generated.")

if __name__ == "__main__":
    generate_reports()
