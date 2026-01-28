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
        print(f"{ft:.1f}ms (FPS: {fps})")
        # Print breakdown of counters
        keys = list(ctx.keys())
        keys.sort()
        for k in keys:
            print(f"   - {k}: {ctx[k]}")
        
        # Print recent events if available
        events = s.get("recent_events", [])
        if events:
            print("   Context Events:")
            for e in events[-3:]: # Last 3
                print(f"   - {e.get('event')} (t={e.get('timestamp')})")
        print("-" * 40)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        analyze_log(sys.argv[1])
    else:
        # Fallback to current dir search
        files = glob.glob("*.jsonl")
        if files:
            analyze_log(files[-1])
        else:
            print("Usage: python validate_perf_logs.py <path_to_log_file>")
            print("Or run in a directory with .jsonl files.")
