import os
import json
import glob
from datetime import datetime

APPDATA_DIR = os.path.join(os.environ['APPDATA'], 'Godot', 'app_userdata', 'Spellloop', 'test_reports')
PROJECT_PATH = r"C:\git\spellloop\project"
TIMESTAMP = datetime.now().strftime("%Y-%m-%dT%H-%M-%S")
GLOBAL_FINAL_MD = os.path.join(PROJECT_PATH, f"global_balance_map_FINAL.md")

def aggregate():
    # Find all reports from today (2026-01-29)
    list_of_files = glob.glob(os.path.join(APPDATA_DIR, "item_validation_report_2026-01-29*.jsonl"))
    print("Found %d reports for today." % len(list_of_files))
    
    all_results = {} # Use dict to deduplicate by item_id
    
    for f in sorted(list_of_files):
        print("Processing: %s" % os.path.basename(f))
        with open(f, 'r', encoding='utf-8', errors='replace') as file:
            for line in file:
                if line.strip():
                    try:
                        res = json.loads(line)
                        item_id = res.get("item_id")
                        # We keep the latest result for each item_id
                        all_results[item_id] = res
                    except Exception as e:
                        print("Error parsing line in %s: %s" % (f, e))

    results_list = list(all_results.values())
    total = len(results_list)
    if total == 0:
        print("No results found.")
        return

    passed = 0
    violations = 0
    bugs = 0
    deltas = []
    
    for res in results_list:
        is_success = res.get("success", False)
        item_id = res.get("item_id", "unknown")
        
        subtests = res.get("subtests", [])
        has_violation = False
        has_bug = False
        
        for sub in subtests:
            res_data = sub.get("res", {})
            code = res_data.get("result_code", "PASS")
            if code == "BUG": has_bug = True
            elif code == "DESIGN_VIOLATION": has_violation = True
            
            if sub.get("type") == "mechanical_damage":
                delta = res_data.get("delta_percent", 0.0)
                deltas.append({
                    "id": item_id, 
                    "delta": delta, 
                    "actual": res_data.get("actual"), 
                    "expected": res_data.get("expected"),
                    "code": code
                })
        
        if has_bug: bugs += 1
        elif has_violation: violations += 1
        
        # In current ItemTestRunner logic, success=True unless code=BUG.
        if is_success: passed += 1

    # Sort deltas by magnitude
    deltas.sort(key=lambda x: abs(x['delta']), reverse=True)
    top_20 = deltas[:20]

    with open(GLOBAL_FINAL_MD, 'w', encoding='utf-8') as f:
        f.write("# Global Balance Map (Full Matrix)\n")
        f.write(f"Generated: {datetime.now().isoformat()}\n\n")
        
        f.write("## Summary Metrics\n")
        f.write(f"- **Total Unique Items Tested**: {total}\n")
        f.write(f"- **Pass Rate (0 Bugs)**: {(passed/total*100):.1f}% ({passed})\n")
        f.write(f"- **Design Violation Rate**: {(violations/total*100):.1f}% ({violations})\n")
        f.write(f"- **Bug Rate**: {(bugs/total*100):.1f}% ({bugs})\n\n")
        
        f.write("## Top 20 Extreme Departures (Potential Balance/Logic Issues)\n")
        f.write("| Item | Delta % | Actual | Expected | Class |\n")
        f.write("| :--- | :--- | :--- | :--- | :--- |\n")
        for d in top_20:
            f.write(f"| {d['id']} | {d['delta']*100:.1f}% | {d['actual']:.1f} | {d['expected']:.1f} | {d['code']} |\n")
            
        f.write("\n## Failure/Violation Details\n")
        for res in results_list:
            if not res.get("success") or res.get("failures"):
                f.write(f"- **{res['item_id']}**: {res['failures']}\n")

    print("\n>>> Global report saved to: %s" % GLOBAL_FINAL_MD)

if __name__ == "__main__":
    aggregate()
