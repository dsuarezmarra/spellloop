#!/usr/bin/env python3
"""Analyze run data files for comprehensive report."""
import json
import sys
import os
from collections import Counter, defaultdict

RUN_DIR = r"C:\Users\Usuario\AppData\Roaming\Godot\app_userdata\Loopialike\runs\run_698a09b3-453d"

def load_jsonl(filename):
    path = os.path.join(RUN_DIR, filename)
    events = []
    with open(path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if line:
                try:
                    events.append(json.loads(line))
                except json.JSONDecodeError as ex:
                    events.append({"_parse_error": str(ex), "_raw": line[:200]})
    return events

def analyze_audit():
    print("=" * 60)
    print("AUDIT.JSONL ANALYSIS")
    print("=" * 60)
    events = load_jsonl("audit.jsonl")
    
    # Event types
    c = Counter(e.get('event', '_parse_error') for e in events)
    print(f"\nTotal events: {len(events)}")
    print("Event types:")
    for k, v in c.most_common():
        print(f"  {k}: {v}")
    
    # Parse errors
    errors = [e for e in events if '_parse_error' in e]
    if errors:
        print(f"\nPARSE ERRORS: {len(errors)}")
        for e in errors[:3]:
            print(f"  {e['_parse_error']}")
    
    # Run start
    for e in events:
        if e.get('event') == 'run_start':
            print(f"\nRUN START:")
            print(f"  character: {e.get('character_id')}")
            print(f"  seed: {e.get('seed')}")
            print(f"  starting_weapons: {e.get('starting_weapons')}")
            print(f"  session: {e.get('session_id')}")
            break
    
    # Run end
    for e in events:
        if e.get('event') == 'run_end':
            d = e.get('data', {})
            print(f"\nRUN END:")
            print(f"  time: {e.get('timestamp_ms', 0)/1000:.1f}s ({e.get('timestamp_ms', 0)/60000:.1f}min)")
            print(f"  death_cause: {d.get('death_cause', 'N/A')}")
            print(f"  final_level: {d.get('final_level')}")
            print(f"  total_kills: {d.get('total_kills')}")
            print(f"  damage_dealt: {d.get('damage_dealt')}")
            print(f"  damage_taken: {d.get('damage_taken')}")
            print(f"  bosses_killed: {d.get('bosses_killed')}")
            print(f"  elites_killed: {d.get('elites_killed')}")
            print(f"  gold_earned: {d.get('gold_earned')}")
            print(f"  xp_total: {d.get('xp_total')}")
            print(f"  healing_done: {d.get('healing_done')}")
            break
    
    # Minute snapshots analysis
    snaps = [e for e in events if e.get('event') == 'minute_snapshot']
    print(f"\nMINUTE SNAPSHOTS: {len(snaps)}")
    
    if snaps:
        # Track stat progression
        print("\n--- STAT PROGRESSION ---")
        for snap in snaps:
            t = snap.get('t_min', '?')
            d = snap.get('data', {})
            ps = d.get('player_stats', {})
            ws = d.get('weapons', [])
            eco = d.get('economy', {})
            perf = d.get('performance', d.get('peerformance', {}))
            
            weapon_info = []
            for w in ws:
                wid = w.get('weapon_id', '?')
                dps = w.get('dps_last_60s', 0)
                weapon_info.append(f"{wid}({dps:.0f}dps)")
            
            spike33 = perf.get('spikes_33ms', 0)
            spike66 = perf.get('spikes_66ms', 0)
            
            print(f"  t={t}min: HP={ps.get('max_health')}, Spd={ps.get('move_speed')}, "
                  f"CritCh={ps.get('crit_chance')}, DmgMult={ps.get('damage_mult')}, "
                  f"Dodge={ps.get('dodge_chance')}, LifeStl={ps.get('life_steal')}, "
                  f"HPReg={ps.get('hp_regen')}, Armor={ps.get('armor')} | "
                  f"Weapons=[{', '.join(weapon_info)}] | "
                  f"Spikes33={spike33},66={spike66} | "
                  f"Fusions={eco.get('fusions', 0)}, Rerolls={eco.get('rerolls', 0)}, "
                  f"Chests={eco.get('chests', {})}")
        
        # Enemies analysis from last few snapshots
        print("\n--- ENEMY THREATS (last snapshot) ---")
        last = snaps[-1]
        enemies = last.get('data', {}).get('enemies_dangerous', [])
        for en in enemies:
            atks = en.get('top_attacks', [])
            atk_str = ', '.join(f"{a['attack_id']}({a['damage']}dmg/{a['hits']}hits)" for a in atks)
            print(f"  {en.get('enemy_name')}: dmg_to_player={en.get('damage_to_player')}, "
                  f"hits={en.get('hits_to_player')}, spawns={en.get('spawns')}, "
                  f"kills_caused={en.get('kills_caused')} | attacks=[{atk_str}]")
    
    # Level up events
    levelups = [e for e in events if e.get('event') == 'level_up']
    print(f"\nLEVEL UP EVENTS: {len(levelups)}")
    for lu in levelups:
        d = lu.get('data', {})
        print(f"  Level {d.get('level')}: t={lu.get('timestamp_ms', 0)/1000:.0f}s, "
              f"offered={d.get('offered_upgrades')}, chosen={d.get('chosen_upgrade')}")
    
    # Boss/elite events
    boss_events = [e for e in events if 'boss' in e.get('event', '').lower()]
    elite_events = [e for e in events if 'elite' in e.get('event', '').lower()]
    print(f"\nBOSS EVENTS: {len(boss_events)}")
    for be in boss_events:
        print(f"  {be.get('event')}: t={be.get('timestamp_ms',0)/1000:.0f}s, data={be.get('data',{})}")
    print(f"ELITE EVENTS: {len(elite_events)}")
    for ee in elite_events:
        print(f"  {ee.get('event')}: t={ee.get('timestamp_ms',0)/1000:.0f}s")
    
    # Phase events
    phase_events = [e for e in events if 'phase' in e.get('event', '').lower()]
    print(f"\nPHASE EVENTS: {len(phase_events)}")
    for pe in phase_events:
        d = pe.get('data', {})
        print(f"  {pe.get('event')}: t={pe.get('timestamp_ms',0)/1000:.0f}s, phase={d.get('phase')}, "
              f"current_wave={d.get('current_wave')}")
    
    # Death/player events
    death_events = [e for e in events if 'death' in e.get('event', '').lower() or 'died' in e.get('event', '').lower()]
    print(f"\nDEATH EVENTS: {len(death_events)}")
    for de in death_events:
        print(f"  {de.get('event')}: t={de.get('timestamp_ms',0)/1000:.0f}s, data={json.dumps(de.get('data',{}), ensure_ascii=False)[:300]}")
    
    return events, snaps

def analyze_balance():
    print("\n" + "=" * 60)
    print("BALANCE.JSONL ANALYSIS")
    print("=" * 60)
    events = load_jsonl("balance.jsonl")
    
    c = Counter(e.get('event', e.get('type', '_unknown')) for e in events)
    print(f"\nTotal entries: {len(events)}")
    print("Entry types:")
    for k, v in c.most_common():
        print(f"  {k}: {v}")
    
    # Parse errors
    errors = [e for e in events if '_parse_error' in e]
    if errors:
        print(f"\nPARSE ERRORS: {len(errors)}")
        for e in errors[:5]:
            print(f"  {e['_parse_error']}")
            print(f"  Raw: {e.get('_raw', '')[:100]}")
    
    # DPS tracking
    dps_events = [e for e in events if 'dps' in e.get('event', '').lower() or 'weapon' in e.get('event', '').lower()]
    if dps_events:
        print(f"\nDPS/Weapon events: {len(dps_events)}")
        # Show last few
        for de in dps_events[-3:]:
            print(f"  {json.dumps(de, ensure_ascii=False)[:200]}")
    
    # Difficulty/scaling events
    diff_events = [e for e in events if 'difficulty' in e.get('event', '').lower() or 'scaling' in e.get('event', '').lower()]
    if diff_events:
        print(f"\nDifficulty/Scaling events: {len(diff_events)}")
    
    # Sample first and last entries
    print(f"\n--- FIRST 3 ENTRIES ---")
    for e in events[:3]:
        print(f"  {json.dumps(e, ensure_ascii=False)[:300]}")
    
    print(f"\n--- LAST 3 ENTRIES ---")
    for e in events[-3:]:
        print(f"  {json.dumps(e, ensure_ascii=False)[:300]}")
    
    return events

def analyze_upgrade_audit():
    print("\n" + "=" * 60)
    print("UPGRADE_AUDIT.JSONL ANALYSIS")
    print("=" * 60)
    events = load_jsonl("upgrade_audit.jsonl")
    
    c = Counter(e.get('event', e.get('type', '_unknown')) for e in events)
    print(f"\nTotal entries: {len(events)}")
    print("Entry types:")
    for k, v in c.most_common():
        print(f"  {k}: {v}")
    
    # Parse errors
    errors = [e for e in events if '_parse_error' in e]
    if errors:
        print(f"\nPARSE ERRORS: {len(errors)}")
        for e in errors[:5]:
            print(f"  {e['_parse_error']}")
    
    # Upgrade selections
    selections = [e for e in events if e.get('event') in ('upgrade_selected', 'upgrade_chosen', 'selection')]
    applies = [e for e in events if e.get('event') in ('upgrade_applied', 'apply', 'applied')]
    offers = [e for e in events if e.get('event') in ('upgrade_offered', 'offer', 'offered', 'level_up_options')]
    
    print(f"\nOffers: {len(offers)}, Selections: {len(selections)}, Applications: {len(applies)}")
    
    # Weapon upgrades
    weapon_ups = [e for e in events if 'weapon' in json.dumps(e.get('data', e), ensure_ascii=False).lower() 
                  and e.get('event') not in ('_parse_error',)]
    
    # Find unique upgrades taken
    upgrades_taken = []
    for e in events:
        data = e.get('data', e)
        chosen = data.get('chosen', data.get('chosen_upgrade', data.get('upgrade_id', None)))
        if chosen:
            upgrades_taken.append(chosen)
    
    if upgrades_taken:
        print(f"\nUpgrades taken ({len(upgrades_taken)}):")
        uc = Counter(upgrades_taken)
        for k, v in uc.most_common():
            print(f"  {k}: {v}x")
    
    # Sample entries
    print(f"\n--- FIRST 3 ENTRIES ---")
    for e in events[:3]:
        print(f"  {json.dumps(e, ensure_ascii=False)[:300]}")
    
    print(f"\n--- LAST 3 ENTRIES ---")
    for e in events[-3:]:
        print(f"  {json.dumps(e, ensure_ascii=False)[:300]}")
    
    # Check for anomalies
    print("\n--- ANOMALY CHECK ---")
    # Duplicate upgrades that shouldn't be duplicated
    # Stats that go negative or unreasonable
    for e in events:
        data = e.get('data', e)
        # Check for negative values
        for key in ('value', 'amount', 'damage', 'hp'):
            val = data.get(key)
            if isinstance(val, (int, float)) and val < 0:
                print(f"  NEGATIVE VALUE: {key}={val} in {e.get('event', '?')}")
    
    return events

def analyze_detailed_snapshots(snaps):
    """Deeper analysis of minute snapshots for balance issues."""
    print("\n" + "=" * 60)
    print("DETAILED BALANCE ANALYSIS")
    print("=" * 60)
    
    if not snaps:
        print("No snapshots available")
        return
    
    # Track stat growth over time
    print("\n--- STAT GROWTH RATE ---")
    first = snaps[0].get('data', {}).get('player_stats', {})
    last = snaps[-1].get('data', {}).get('player_stats', {})
    t_first = snaps[0].get('t_min', 1)
    t_last = snaps[-1].get('t_min', 1)
    duration = t_last - t_first if t_last > t_first else 1
    
    for stat in ['max_health', 'move_speed', 'crit_chance', 'crit_damage', 'damage_mult', 
                 'dodge_chance', 'life_steal', 'hp_regen', 'armor', 'damage_reduction', 'attack_speed_mult']:
        v_first = first.get(stat, 0)
        v_last = last.get(stat, 0)
        if isinstance(v_first, (int, float)) and isinstance(v_last, (int, float)):
            delta = v_last - v_first
            rate = delta / duration if duration > 0 else 0
            flag = ""
            # Flag potentially OP stats
            if stat == 'dodge_chance' and v_last > 0.5: flag = " [!HIGH]"
            if stat == 'life_steal' and v_last > 0.3: flag = " [!HIGH]"
            if stat == 'damage_mult' and v_last > 3.0: flag = " [!HIGH]"
            if stat == 'crit_chance' and v_last > 0.6: flag = " [!HIGH]"
            if stat == 'move_speed' and v_last < 80: flag = " [!LOW - might feel sluggish]"
            if stat == 'move_speed' and v_last > 400: flag = " [!HIGH - too fast?]"
            print(f"  {stat}: {v_first} -> {v_last} (delta={delta:+.2f}, rate={rate:+.3f}/min){flag}")
    
    # DPS analysis over time
    print("\n--- DPS PROGRESSION ---")
    for snap in snaps:
        t = snap.get('t_min', 0)
        weapons = snap.get('data', {}).get('weapons', [])
        total_dps = sum(w.get('dps_last_60s', 0) for w in weapons)
        total_dmg = sum(w.get('damage_total', 0) for w in weapons)
        weapon_count = len(weapons)
        print(f"  t={t}min: total_dps={total_dps:.1f}, total_dmg={total_dmg}, weapons={weapon_count}")
    
    # Enemy threat analysis
    print("\n--- ENEMY THREAT EVOLUTION ---")
    for snap in snaps[-5:]:
        t = snap.get('t_min', 0)
        enemies = snap.get('data', {}).get('enemies_dangerous', [])
        total_dmg_to_player = sum(e.get('damage_to_player', 0) for e in enemies)
        total_hits = sum(e.get('hits_to_player', 0) for e in enemies)
        total_player_kills = sum(e.get('kills_caused', 0) for e in enemies)
        print(f"  t={t}min: total_enemy_dmg={total_dmg_to_player}, total_hits={total_hits}, "
              f"player_deaths_caused={total_player_kills}")
    
    # Performance analysis
    print("\n--- PERFORMANCE ANALYSIS ---")
    spike_33_total = 0
    spike_66_total = 0
    for snap in snaps:
        t = snap.get('t_min', 0)
        perf = snap.get('data', {}).get('performance', snap.get('data', {}).get('peerformance', {}))
        s33 = perf.get('spikes_33ms', 0)
        s66 = perf.get('spikes_66ms', 0)
        spike_33_total += s33
        spike_66_total += s66
        if s33 > 0 or s66 > 0:
            print(f"  t={t}min: spikes_33ms={s33}, spikes_66ms={s66}")
    
    if spike_33_total == 0 and spike_66_total == 0:
        print("  No performance spikes detected - EXCELLENT")
    else:
        print(f"  TOTAL: spikes_33ms={spike_33_total}, spikes_66ms={spike_66_total}")
    
    # Economy analysis
    print("\n--- ECONOMY ANALYSIS ---")
    for snap in snaps:
        t = snap.get('t_min', 0)
        eco = snap.get('data', {}).get('economy', {})
        chests = eco.get('chests', {})
        print(f"  t={t}min: fusions={eco.get('fusions', 0)}, rerolls={eco.get('rerolls', 0)}, "
              f"chests(N={chests.get('normal', 0)},E={chests.get('elite', 0)},B={chests.get('boss', 0)})")

if __name__ == "__main__":
    print("LOOPIALIKE RUN ANALYSIS")
    print(f"Run: 698a09b3-453d")
    print(f"Date: 2026-02-09")
    print()
    
    audit_events, snaps = analyze_audit()
    balance_events = analyze_balance()
    upgrade_events = analyze_upgrade_audit()
    analyze_detailed_snapshots(snaps)
    
    print("\n" + "=" * 60)
    print("ANALYSIS COMPLETE")
    print("=" * 60)
