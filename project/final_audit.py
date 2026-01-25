import os
import json
import csv

PROJECT_ROOT = r"c:\git\spellloop\project"
MANIFEST_PATH = os.path.join(PROJECT_ROOT, "audio_manifest.json")
OUTPUT_CSV = os.path.join(PROJECT_ROOT, "final_audio_audit.csv")

def audit():
    print(f"Auditing from {PROJECT_ROOT}...")
    
    with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
        manifest = json.load(f)
        
    results = []
    
    # 1. Check all files in manifest exist
    for audio_id, entry in manifest.items():
        files = entry.get("files", [])
        if not files:
            results.append({"Status": "ERROR", "ID": audio_id, "Message": "No files defined"})
            continue
            
        for path in files:
            if path.startswith("res://"):
                rel_path = path.replace("res://", "")
                abs_path = os.path.join(PROJECT_ROOT, rel_path.replace("/", "\\"))
                
                if not os.path.exists(abs_path):
                    results.append({"Status": "MISSING", "ID": audio_id, "Message": path})
                else:
                    results.append({"Status": "OK", "ID": audio_id, "Message": path})
            else:
                 results.append({"Status": "INVALID_PATH", "ID": audio_id, "Message": path})

    # Output to CSV
    with open(OUTPUT_CSV, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["Status", "ID", "Message"])
        writer.writeheader()
        writer.writerows(results)
        
    print(f"Audit complete. Results saved to {OUTPUT_CSV}")
    
    # Summary to console
    missing = [r for r in results if r["Status"] == "MISSING"]
    if missing:
        print(f"❌ FOUND {len(missing)} MISSING FILES:")
        for m in missing:
            print(f"  - {m['ID']}: {m['Message']}")
    else:
        print("✅ No missing files found in manifest.")

if __name__ == "__main__":
    audit()
