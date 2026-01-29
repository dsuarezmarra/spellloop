# Global Balance Map (Full Matrix)
Generated: 2026-01-29T11:21:04.496933

## Summary Metrics
- **Total Unique Items Tested**: 143
- **Pass Rate (0 Bugs)**: 100.0% (143)
- **Design Violation Rate**: 34.3% (49)
- **Bug Rate**: 0.0% (0)

## Top 20 Extreme Departures (Potential Balance/Logic Issues)
| Item | Delta % | Actual | Expected | Class |
| :--- | :--- | :--- | :--- | :--- |
| storm_caller | 233.3% | 180.0 | 54.0 | DESIGN_VIOLATION |
| light_beam | 150.0% | 50.0 | 20.0 | DESIGN_VIOLATION |
| pacifist | 144.4% | 44.0 | 18.0 | DESIGN_VIOLATION |
| shadow_orbs | 100.0% | 0.0 | 40.0 | DESIGN_VIOLATION |
| life_orbs | 100.0% | 0.0 | 35.0 | DESIGN_VIOLATION |
| wind_orbs | 100.0% | 0.0 | 30.0 | DESIGN_VIOLATION |
| cosmic_void | 100.0% | 0.0 | 50.0 | DESIGN_VIOLATION |
| near_sighted | 83.3% | 77.0 | 42.0 | DESIGN_VIOLATION |
| crystal_guardian | 75.0% | 15.0 | 60.0 | DESIGN_VIOLATION |
| cursed_gambler_2 | 70.0% | 34.0 | 20.0 | DESIGN_VIOLATION |
| thunder_spear | 66.7% | 75.0 | 45.0 | DESIGN_VIOLATION |
| blizzard | 65.0% | 84.0 | 240.0 | DESIGN_VIOLATION |
| fire_wand | 58.3% | 38.0 | 24.0 | DESIGN_VIOLATION |
| dark_flame | 55.4% | 30.0 | 67.2 | DESIGN_VIOLATION |
| gaia | 55.3% | 82.0 | 52.8 | DESIGN_VIOLATION |
| sandstorm | 53.7% | 100.0 | 216.0 | DESIGN_VIOLATION |
| cursed_heavy_weapons_2 | 50.0% | 42.0 | 28.0 | DESIGN_VIOLATION |
| absolute_zero | 47.9% | 35.0 | 67.2 | DESIGN_VIOLATION |
| radiant_stone | 47.9% | 40.0 | 76.8 | DESIGN_VIOLATION |
| plasma | 47.7% | 65.0 | 44.0 | DESIGN_VIOLATION |

## Failure/Violation Details
- **cursed_gambler_2**: ['[SIMPLE] Hit Expected 20.0 vs Actual 34.0 (Delta 70.0%) -> DESIGN_VIOLATION']
- **cursed_scatter_1**: ['[MULTI] Hit Expected 48.0 vs Actual 26.0 (Delta 45.8%) -> DESIGN_VIOLATION']
- **arcane_orb**: ['[ORBIT] Hit Expected 40.0 vs Actual 24.0 (Delta 40.0%) -> DESIGN_VIOLATION']
- **light_beam**: ['[BEAM] Hit Expected 20.0 vs Actual 50.0 (Delta 150.0%) -> DESIGN_VIOLATION']
- **cursed_scatter_2**: ['[MULTI] Hit Expected 66.0 vs Actual 37.0 (Delta 43.9%) -> DESIGN_VIOLATION']
- **near_sighted**: ['[SIMPLE] Hit Expected 42.0 vs Actual 77.0 (Delta 83.3%) -> DESIGN_VIOLATION']
- **lightning_wand**: ['[CHAIN] Hit Expected 30.0 vs Actual 42.0 (Delta 40.0%) -> DESIGN_VIOLATION']
- **crystal_guardian**: ['[ORBIT] Hit Expected 60.0 vs Actual 15.0 (Delta 75.0%) -> DESIGN_VIOLATION']
- **arcane_storm**: ['[ORBIT] Hit Expected 45.0 vs Actual 65.0 (Delta 44.4%) -> DESIGN_VIOLATION']
- **wildfire**: ['[MULTI] Hit Expected 117.0 vs Actual 78.0 (Delta 33.3%) -> DESIGN_VIOLATION']
- **shadow_orbs**: ['[ORBIT] Hit Expected 40.0 vs Actual 0.0 (Delta 100.0%) -> DESIGN_VIOLATION']
- **heavy_glass**: ['[SIMPLE] Hit Expected 42.0 vs Actual 53.0 (Delta 26.2%) -> DESIGN_VIOLATION']
- **pacifist**: ['[SIMPLE] Hit Expected 18.0 vs Actual 44.0 (Delta 144.4%) -> DESIGN_VIOLATION']
- **cursed_glass_cannon_2**: ['[SIMPLE] Hit Expected 42.0 vs Actual 53.0 (Delta 26.2%) -> DESIGN_VIOLATION']
- **cursed_heavy_weapons_1**: ['[SIMPLE] Hit Expected 28.0 vs Actual 38.0 (Delta 35.7%) -> DESIGN_VIOLATION']
- **cursed_heavy_weapons_2**: ['[SIMPLE] Hit Expected 28.0 vs Actual 42.0 (Delta 50.0%) -> DESIGN_VIOLATION']
- **fire_wand**: ['[SIMPLE] Hit Expected 24.0 vs Actual 38.0 (Delta 58.3%) -> DESIGN_VIOLATION']
- **shadow_dagger**: ['[SIMPLE] Hit Expected 21.0 vs Actual 14.0 (Delta 33.3%) -> DESIGN_VIOLATION']
- **nature_staff**: ['[MULTI] Hit Expected 54.0 vs Actual 43.0 (Delta 20.4%) -> DESIGN_VIOLATION']
- **wind_blade**: ['[MULTI] Hit Expected 48.0 vs Actual 66.0 (Delta 37.5%) -> DESIGN_VIOLATION']
- **earth_spike**: ['[AOE] Hit Expected 48.0 vs Actual 30.0 (Delta 37.5%) -> DESIGN_VIOLATION']
- **steam_cannon**: ['[AOE] Hit Expected 90.0 vs Actual 64.0 (Delta 28.9%) -> DESIGN_VIOLATION']
- **storm_caller**: ['[CHAIN] Hit Expected 54.0 vs Actual 180.0 (Delta 233.3%) -> DESIGN_VIOLATION']
- **soul_reaper**: ['[MULTI] Hit Expected 160.0 vs Actual 120.0 (Delta 25.0%) -> DESIGN_VIOLATION']
- **rift_quake**: ['[AOE] Hit Expected 48.0 vs Actual 40.0 (Delta 16.7%) -> DESIGN_VIOLATION']
- **thunder_spear**: ['[BEAM] Hit Expected 45.0 vs Actual 75.0 (Delta 66.7%) -> DESIGN_VIOLATION']
- **void_storm**: ['[AOE] Hit Expected 67.2 vs Actual 42.0 (Delta 37.5%) -> DESIGN_VIOLATION']
- **blizzard**: ['[MULTI] Hit Expected 240.0 vs Actual 84.0 (Delta 65.0%) -> DESIGN_VIOLATION']
- **glacier**: ['[AOE] Hit Expected 52.8 vs Actual 71.0 (Delta 34.5%) -> DESIGN_VIOLATION']
- **absolute_zero**: ['[AOE] Hit Expected 67.2 vs Actual 35.0 (Delta 47.9%) -> DESIGN_VIOLATION']
- **plasma**: ['[CHAIN] Hit Expected 44.0 vs Actual 65.0 (Delta 47.7%) -> DESIGN_VIOLATION']
- **inferno_orb**: ['[ORBIT] Hit Expected 45.0 vs Actual 27.0 (Delta 40.0%) -> DESIGN_VIOLATION']
- **firestorm**: ['[MULTI] Hit Expected 160.0 vs Actual 112.0 (Delta 30.0%) -> DESIGN_VIOLATION']
- **volcano**: ['[AOE] Hit Expected 72.0 vs Actual 60.0 (Delta 16.7%) -> DESIGN_VIOLATION']
- **solar_flare**: ['[BEAM] Hit Expected 50.0 vs Actual 70.0 (Delta 40.0%) -> DESIGN_VIOLATION']
- **dark_flame**: ['[AOE] Hit Expected 67.2 vs Actual 30.0 (Delta 55.4%) -> DESIGN_VIOLATION']
- **dark_lightning**: ['[MULTI] Hit Expected 140.0 vs Actual 112.0 (Delta 20.0%) -> DESIGN_VIOLATION']
- **seismic_bolt**: ['[AOE] Hit Expected 57.6 vs Actual 48.0 (Delta 16.7%) -> DESIGN_VIOLATION']
- **life_orbs**: ['[ORBIT] Hit Expected 35.0 vs Actual 0.0 (Delta 100.0%) -> DESIGN_VIOLATION']
- **wind_orbs**: ['[ORBIT] Hit Expected 30.0 vs Actual 0.0 (Delta 100.0%) -> DESIGN_VIOLATION']
- **cosmic_void**: ['[ORBIT] Hit Expected 50.0 vs Actual 0.0 (Delta 100.0%) -> DESIGN_VIOLATION']
- **phantom_blade**: ['[MULTI] Hit Expected 216.0 vs Actual 144.0 (Delta 33.3%) -> DESIGN_VIOLATION']
- **pollen_storm**: ['[MULTI] Hit Expected 220.0 vs Actual 139.0 (Delta 36.8%) -> DESIGN_VIOLATION']
- **gaia**: ['[AOE] Hit Expected 52.8 vs Actual 82.0 (Delta 55.3%) -> DESIGN_VIOLATION']
- **decay**: ['[AOE] Hit Expected 62.4 vs Actual 44.0 (Delta 29.5%) -> DESIGN_VIOLATION']
- **sandstorm**: ['[MULTI] Hit Expected 216.0 vs Actual 100.0 (Delta 53.7%) -> DESIGN_VIOLATION']
- **prism_wind**: ['[MULTI] Hit Expected 150.0 vs Actual 175.0 (Delta 16.7%) -> DESIGN_VIOLATION']
- **radiant_stone**: ['[AOE] Hit Expected 76.8 vs Actual 40.0 (Delta 47.9%) -> DESIGN_VIOLATION']
- **eclipse**: ['[BEAM] Hit Expected 50.0 vs Actual 70.0 (Delta 40.0%) -> DESIGN_VIOLATION']
