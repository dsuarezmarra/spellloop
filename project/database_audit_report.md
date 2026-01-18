# Database Audit Report
**Date:** 2026-01-18
**Audited Files:** `WeaponDatabase.gd`, `WeaponUpgradeDatabase.gd`, `UpgradeDatabase.gd`, `BossDatabase.gd`, `EnemyDatabase.gd`, `RaresDatabase.gd`, `LootManager.gd`.

## 1. Summary of Changes
- **Fixed Typo in `LootManager.gd`**: Renamed `CHEST_WIEGHTS` to `CHEST_WEIGHTS` to prevent potential runtime errors.
- **Verified Logic**: Confirmed proper implementation of `all_mult` stat in `BaseWeapon.gd`.

## 2. Detailed Findings

### A. Weapon Database (`WeaponDatabase.gd`)
*   **Status**: Healthy
*   **Observations**:
    *   `arcane_orb` set to 0.0 cooldown. Verified as handled correctly by `ready_to_fire` logic in `BaseWeapon` (fires every frame).
    *   `light_beam` uses 999.0 speed for hitscan/instant effects. Correct.
    *   `void_pulse` uses negative knockback (-200.0) for pull effect. Correct.
    *   **Note**: Level 8 upgrades for `ice_wand` and `fire_wand` utilize `all_mult`, which was verified to be correctly implemented in `BaseWeapon.gd`.

### B. Enemy Database (`EnemyDatabase.gd`)
*   **Status**: Functional with minor warnings
*   **Warnings**:
    *   `tier_1_duende_sombrio`: Modifiers use `hp: 0.6`. With `base_hp: 12`, this results in `7.2` HP. `HealthComponent` uses integers, so this will truncate to `7`. This is acceptable but imprecise.
    *   **Recommendation**: Future balancing should ensure modifiers result in whole numbers or switch HealthComponent to floats if sub-1 HP matters.

### C. Loot System (`LootManager.gd` & `BossDatabase.gd`)
*   **Status**: Functional but Inconsistent
*   **Issues**:
    *   **Loot Logic Duplication**: `LootManager.get_chest_loot` for BOSS chests uses hardcoded logic (Jackpot system) and completely ignores `BossDatabase.gd`.
    *   `BossDatabase.gd` is *only* used for "Shop Boss Items".
    *   **Result**: Changing loot tables in `BossDatabase.gd` will **NOT** affect drops from actual Boss Chests, only what appears in the Shop.
    *   **Fixed**: Corrected variable name `CHEST_WIEGHTS` -> `CHEST_WEIGHTS` in `LootManager.gd`.

### D. Upgrades (`UpgradeDatabase.gd`)
*   **Status**: Functional
*   **Inconsistencies**:
    *   `utility_luck_1` uses a prefixed ID while others use simple IDs (e.g., `speed_1`). Purely cosmetic as long as references match.
    *   `lifesteal_1` starts at Tier 2. This is confusing naming (usually `_1` implies Tier 1) but functionally valid.

### E. Character Database (`CharacterDatabase.gd`)
*   **Status**: Good
*   **Observations**:
    *   `starting_weapon` references are correct.
    *   Passives are defined as data objects; implementation depends on `PlayerStats`.

## 3. Critical Fixes Applied
1.  **LootManager.gd**:
    *   Fixed typo `CHEST_WIEGHTS` -> `CHEST_WEIGHTS`. This was a dormant bug that would likely crash if accessed.

## 4. Recommendations
1.  **Unify Boss Loot**: Refactor `LootManager._generate_boss_loot` to actually use `BossDatabase.gd` so that loot tables are centralized and not hardcoded in the manager.
2.  **Standardize IDs**: Renaming `utility_luck_1` to `luck_1` and aligning generic upgrades to start at Tier 1 (or rename `lifesteal_1` to `lifesteal_tier2`) would improve readability.
3.  **Float HP**: Consider rounding float HP calculations in `EnemyBase` initialization to avoid implicit truncation confusion.
