import json
import sys
import os
import glob
from collections import defaultdict

def analyze_log(filepath):
    print(f"Analyzing: {filepath}")
    spikes = []
    fps_history = []
    
    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            try:
                entry = json.loads(line)
                if entry.get("event") == "perf_spike":
                    spikes.append(entry)
                elif "fps" in entry.get("counters", {}): # Depending on log format
                   pass # History logging logic if full stream
            except:
                continue

    print(f"Found {len(spikes)} spikes.")
    
    # Top Spikes
    spikes.sort(key=lambda x: x.get("frame_time_ms", 0), reverse=True)
    
    print("\n--- TOP 5 LAG SPIKES ---")
    for s in spikes[:5]:
        ft = s.get("frame_time_ms", 0)
        fps = s.get("fps", 0)
        ctx = s.get("counters", {})
        print(f"{ft:.1f}ms (FPS: {fps}) | Enemies: {ctx.get('enemies_alive')} | Proj: {ctx.get('projectiles_alive')}")

if __name__ == "__main__":
    log_dir = os.path.expanduser("~/.godot/app_userdata/Spellloop/perf_logs")
    # Adjust for Windows specific path if needed, usually %APPDATA%/Godot/... or local "user://"
    # For now, simplistic input or glob
    
    files = glob.glob("*.jsonl")
    if files:
        analyze_log(files[-1])
    else:
        print("No log files found in current dir. Provide path as argument.")
