import json

events = [json.loads(l) for l in open('upgrade_audit.jsonl', 'r', encoding='utf-8') if l.strip()]

# Find glass cannon / borde muerte upgrades
print("=== GLASS CANNON / BORDE DE LA MUERTE ===")
for e in events:
    name = e.get('name', '')
    eid = e.get('id', '')
    if 'borde' in name.lower() or 'muerte' in name.lower() or 'glass' in eid.lower() or 'death' in eid.lower():
        print(json.dumps(e, indent=2, ensure_ascii=False)[:600])
        print('---')

# Find armor changes
print("\n=== ARMOR CHANGES ===")
for e in events:
    checks = e.get('checks', [])
    for c in checks:
        if c.get('stat', '') == 'armor':
            n = e.get('name', '?')
            i = e.get('id', '?')
            b = c.get('before', '?')
            a = c.get('after', '?')
            d = c.get('delta', '?')
            s = c.get('status', '?')
            print(f"  {n} [{i}]: {b} -> {a} (delta={d}) status={s}")

# Find max_health changes
print("\n=== MAX_HEALTH CHANGES ===")
for e in events:
    checks = e.get('checks', [])
    for c in checks:
        if c.get('stat', '') == 'max_health':
            n = e.get('name', '?')
            i = e.get('id', '?')
            b = c.get('before', '?')
            a = c.get('after', '?')
            d = c.get('delta', '?')
            s = c.get('status', '?')
            print(f"  {n} [{i}]: {b} -> {a} (delta={d}) status={s}")

# Find any WARN or FAIL verdicts
print("\n=== VERDICTS: WARN/FAIL ===")
for e in events:
    v = e.get('verdict', 'OK')
    if v not in ('OK', None):
        print(f"  {e.get('name', '?')} [{e.get('id')}]: verdict={v}")
        for c in e.get('checks', []):
            if c.get('status', 'OK') != 'OK':
                print(f"    check={c.get('check')}: {c.get('detail', '')[:200]}")

# Count upgrade categories
from collections import Counter
cats = Counter(e.get('category', 'unknown') for e in events if e.get('event') == 'upgrade_audit')
print(f"\n=== UPGRADE CATEGORIES ===")
for k, v in cats.most_common():
    print(f"  {k}: {v}")

# Stats that went negative
print("\n=== NEGATIVE STAT VALUES ===")
for e in events:
    for c in e.get('checks', []):
        after = c.get('after')
        if isinstance(after, (int, float)) and after < 0:
            print(f"  {e.get('name', '?')} [{e.get('id')}]: {c.get('stat')}={after}")
