# Item Validation Summary
Date: 2026-01-31T01:10:43
Run ID: scope_weapon_specific_2383440737
Total Tests: 27
- Passed: 0
- Violations: 5
- Bugs: 0
- Parse Errors: 0

## Status Verification Results
| Item ID | Status | Result | Details |
|---|---|---|---|
| specific_damage_1 | slow | ✅ | No details |
| specific_damage_2 | slow | ✅ | No details |
| specific_damage_3 | slow | ✅ | No details |
| specific_attack_speed_1 | slow | ✅ | No details |
| specific_attack_speed_2 | slow | ✅ | No details |
| specific_projectile_1 | slow | ✅ | No details |
| specific_projectile_2 | slow | ✅ | No details |
| ice_wand_frost_nova | slow | ✅ | No details |
| ice_wand_deep_freeze | slow | ✅ | No details |
| fire_wand_inferno | slow | ✅ | No details |
| fire_wand_spread | slow | ✅ | No details |
| lightning_wand_chain_master | slow | ✅ | No details |
| lightning_wand_overcharge | slow | ✅ | No details |
| shadow_dagger_assassin | slow | ✅ | No details |
| shadow_dagger_multi | slow | ✅ | No details |
| nature_staff_overgrowth | slow | ✅ | No details |
| arcane_orb_expansion | slow | ✅ | No details |
| ice_wand | slow | ✅ | No details |
| fire_wand | burn | ✅ | No details |
| earth_spike | stun | ❌ | No details |

## Metadata
- **Started At**: 2026-01-31T01:10:43
- **Git Commit**: ea3ef713
- **Duration**: 87176 ms
- **Seed**: 1337
- **Scheduled Tests**: 27
- **Parsed Tests**: 27
- **Parse Errors**: 0

## Metrics
- **Total Valid Items**: 27
- **% Passed**: 0.0% (0)
- **% Design Violations**: 18.5% (5)
- **Bugs Detected**: 0

## Top 20 Most Extreme Deltas
| Item | Delta %% | Actual | Expected |
| :--- | :--- | :--- | :--- |
| void_pulse | 100.0% | 0.0 | 32.0 |
| earth_spike | 100.0% | 0.0 | 40.0 |
| wind_blade | 100.0% | 0.0 | 24.0 |
| shadow_dagger | 100.0% | 0.0 | 7.0 |
| arcane_orb | 100.0% | 0.0 | 16.0 |
| light_beam | 0.0% | 20.0 | 20.0 |
| nature_staff | 0.0% | 18.0 | 18.0 |
| lightning_wand | 0.0% | 45.0 | 45.0 |
| fire_wand | 0.0% | 15.0 | 15.0 |
| ice_wand | 0.0% | 14.0 | 14.0 |
| arcane_orb_expansion | 0.0% | 14.0 | 14.0 |
| nature_staff_overgrowth | 0.0% | 14.0 | 14.0 |
| shadow_dagger_multi | 0.0% | 14.0 | 14.0 |
| shadow_dagger_assassin | 0.0% | 14.0 | 14.0 |
| lightning_wand_overcharge | 0.0% | 14.0 | 14.0 |
| lightning_wand_chain_master | 0.0% | 14.0 | 14.0 |
| fire_wand_spread | 0.0% | 14.0 | 14.0 |
| fire_wand_inferno | 0.0% | 14.0 | 14.0 |
| ice_wand_deep_freeze | 0.0% | 14.0 | 14.0 |
| ice_wand_frost_nova | 0.0% | 14.0 | 14.0 |

## Scope Coverage
- WEAPON_SPECIFIC: 27

## Failures (Bugs & Violations)
- **specific_damage_1**: ["CONTRACT: unknown - Expected: ?, Actual: 1.0"]
- **specific_damage_2**: ["CONTRACT: unknown - Expected: ?, Actual: 1.0"]
- **specific_damage_3**: ["CONTRACT: unknown - Expected: ?, Actual: 1.0"]
- **specific_attack_speed_1**: ["CONTRACT: unknown - Expected: ?, Actual: 1.0"]
- **specific_attack_speed_2**: ["CONTRACT: unknown - Expected: ?, Actual: 1.0"]
- **specific_projectile_1**: ["CONTRACT: unknown - Expected: ?, Actual: 0.0"]
- **specific_projectile_2**: ["CONTRACT: unknown - Expected: ?, Actual: 0.0"]
- **ice_wand_frost_nova**: ["CONTRACT: unknown - Expected: ?, Actual: 0.0", "CONTRACT: unknown - Expected: ?, Actual: 1.0"]
- **ice_wand_deep_freeze**: ["CONTRACT: unknown - Expected: ?, Actual: 0.0", "CONTRACT: unknown - Expected: ?, Actual: 0.0"]
- **fire_wand_inferno**: ["CONTRACT: unknown - Expected: ?, Actual: 1.0", "CONTRACT: unknown - Expected: ?, Actual: 0.0"]
- **fire_wand_spread**: ["CONTRACT: unknown - Expected: ?, Actual: 0.0"]
- **lightning_wand_chain_master**: ["CONTRACT: unknown - Expected: ?, Actual: 0.0"]
- **lightning_wand_overcharge**: ["CONTRACT: unknown - Expected: ?, Actual: 1.0", "CONTRACT: unknown - Expected: ?, Actual: 1.0"]
- **shadow_dagger_assassin**: ["CONTRACT: unknown - Expected: ?, Actual: 2.0", "CONTRACT: unknown - Expected: ?, Actual: 0.05"]
- **shadow_dagger_multi**: ["CONTRACT: unknown - Expected: ?, Actual: 0.0"]
- **nature_staff_overgrowth**: ["CONTRACT: unknown - Expected: ?, Actual: 0.0", "CONTRACT: unknown - Expected: ?, Actual: 1.0"]
- **arcane_orb_expansion**: ["CONTRACT: unknown - Expected: ?, Actual: 0.0", "CONTRACT: unknown - Expected: ?, Actual: 1.0"]
- **ice_wand**: []
- **fire_wand**: []
- **lightning_wand**: []
- **arcane_orb**: ["[ORBIT] Hit Expected 16.0 vs Actual 0.0 (Delta 100.0%) -> DESIGN_VIOLATION"]
- **shadow_dagger**: ["[SIMPLE] Hit Expected 7.0 vs Actual 0.0 (Delta 100.0%) -> DESIGN_VIOLATION"]
- **nature_staff**: []
- **wind_blade**: ["[MULTI] Hit Expected 24.0 vs Actual 0.0 (Delta 100.0%) -> DESIGN_VIOLATION"]
- **earth_spike**: ["Status Fail [stun]: unknown", "[AOE] Hit Expected 40.0 vs Actual 0.0 (Delta 100.0%) -> DESIGN_VIOLATION"]
- **light_beam**: []
- **void_pulse**: ["[AOE] Hit Expected 32.0 vs Actual 0.0 (Delta 100.0%) -> DESIGN_VIOLATION"]
