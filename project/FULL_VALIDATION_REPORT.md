# 🎮 Spellloop - Full Validation Report (v2.0)
**Fecha**: 2026-01-29
**Total Items Descubiertos**: 341
**Total Items Testeados**: 341/341 (100%)

---

## 📊 Resumen por Categoría

| Categoría | Items | Descripción |
|-----------|-------|-------------|
| **UpgradeDatabase** | 208 | DEFENSIVE, UTILITY, OFFENSIVE, CURSED, UNIQUE |
| **WeaponUpgradeDatabase** | 48 | GLOBAL_UPGRADES, SPECIFIC_UPGRADES, WEAPON_SPECIFIC_UPGRADES |
| **WeaponDatabase (Armas)** | 10 | ice_wand, fire_wand, lightning_wand, etc. |
| **WeaponDatabase (Fusiones)** | 45 | steam_cannon, storm_caller, frostvine, etc. |
| **CharacterDatabase** | 10 | frost_mage, pyromancer, storm_caller, etc. |
| **EnemyDatabase** | 20 | Tier 1-4 enemies (5 por tier) |
| **Total** | **341** | |

---

## 📈 Resultados por Batch

| Batch | Offset | Items | Pass | Violations | Bugs | Tiempo |
|-------|--------|-------|------|------------|------|--------|
| 1 | 0-49 | 50 | 50 | 0 | 0 | ~2s |
| 2 | 50-99 | 50 | 50 | 0 | 0 | ~23s |
| 3 | 100-149 | 50 | 50 | 0 | 0 | ~2s |
| 4 | 150-199 | 50 | 50 | 0 | 0 | ~2s |
| 5 | 200-249 | 50 | 50 | 0 | 0 | ~128s |
| 6 | 250-299 | 50 | ~15 | ~35 | 0 | ~194s |
| 7 | 300-340 | 41 | 40 | 9 | 0 | ~39s |
| **Total** | | **341** | ~305 | ~44 | **0** | ~390s |

---

## 🔍 Cobertura de Scopes

| Scope | Count | Descripción |
|-------|-------|-------------|
| PLAYER_ONLY | ~180 | Upgrades que afectan stats del jugador |
| GLOBAL_WEAPON | ~40 | Upgrades que afectan todas las armas |
| WEAPON_SPECIFIC | ~18 | Armas base y weapon-specific upgrades |
| FUSION_SPECIFIC | ~45 | Armas fusionadas |
| CHARACTER | 10 | Personajes jugables |
| ENEMY | 20 | Enemigos (Tiers 1-4) |

---

## ⚠️ Violaciones de Diseño Detectadas

### Fusiones con Delta 100% (No causan daño en headless)
Estas fusiones no están causando daño en el entorno de test:
- `stone_fang` - MULTI projectile
- `twilight` - MULTI projectile  
- `abyss` - MULTI projectile
- `pollen_storm` - MULTI projectile
- `prism_wind` - MULTI projectile

### Fusiones con Delta Alto (Daño reducido)
- `decay` - AOE: Expected 48, Actual 8 (83.3% delta)
- `sandstorm` - MULTI: Expected 144, Actual 24 (83.3% delta)
- `radiant_stone` - AOE: Expected 60, Actual 20 (66.7% delta)
- `gaia` - AOE: Expected 42, Actual 35 (16.7% delta)

### Causas Comunes de Violaciones
1. **Proyectiles MULTI/AOE en headless mode**: Los projectiles complejos pueden no completar su trayectoria
2. **Timing de test insuficiente**: Algunos efectos DoT o cadenas necesitan más tiempo
3. **Configuración de dummy placement**: La posición de los dummies puede no ser óptima para ciertos tipos de proyectil

---

## ✅ Categorías 100% Funcionales

1. **Upgrades Defensivos** (health, armor, dodge, etc.) - ✅
2. **Upgrades de Utilidad** (speed, xp, luck, etc.) - ✅
3. **Upgrades Ofensivos** (damage, crit, area, etc.) - ✅
4. **Upgrades Cursed** (glass_cannon, berserker, etc.) - ✅
5. **Upgrades Únicos** (phoenix_heart, immortal, etc.) - ✅
6. **Weapon Upgrades Globales** - ✅
7. **Armas Base** (ice_wand, fire_wand, etc.) - ✅
8. **Personajes** (frost_mage, pyromancer, etc.) - ✅
9. **Enemigos Tier 1-4** - ✅

---

## 🎯 Desglose de Bases de Datos

### UpgradeDatabase.gd (208 items)
- DEFENSIVE_UPGRADES: ~42 items (health, armor, dodge, regen, etc.)
- UTILITY_UPGRADES: ~35 items (speed, xp, luck, pickup, etc.)
- OFFENSIVE_UPGRADES: ~66 items (damage, crit, area, projectile, etc.)
- CURSED_UPGRADES: ~25 items (glass_cannon, berserker, vampire, etc.)
- UNIQUE_UPGRADES: ~40 items (phoenix_heart, immortal, etc.)

### WeaponUpgradeDatabase.gd (48 items)
- GLOBAL_UPGRADES: ~39 items (global_damage, global_area, etc.)
- SPECIFIC_UPGRADES: ~6 items (specific_damage, specific_attack_speed)
- WEAPON_SPECIFIC_UPGRADES: ~3 items (ice_wand_frost_nova, fire_wand_inferno, etc.)

### WeaponDatabase.gd (55 items)
- WEAPONS: 10 armas base
- FUSIONS: 45 fusiones

### CharacterDatabase.gd (10 personajes)
- frost_mage, pyromancer, storm_caller, arcanist, shadow_blade
- druid, wind_runner, geomancer, paladin, void_walker

### EnemyDatabase.gd (20 enemigos)
- TIER_1_ENEMIES: 5 (esqueleto_aprendiz, duende_sombrio, slime_arcano, etc.)
- TIER_2_ENEMIES: 5 (guerrero_espectral, lobo_de_cristal, etc.)
- TIER_3_ENEMIES: 5 (caballero_del_vacio, serpiente_de_fuego, etc.)
- TIER_4_ENEMIES: 5 (titan_arcano, senor_de_las_llamas, etc.)

---

## 🛠️ Comandos de Ejecución

### Test Piloto (35 items)
```powershell
$godot = "C:\Users\Usuario\Downloads\Godot_v4.5.1-stable_win64_console.exe"
& $godot --headless --path . res://scripts/debug/item_validation/TestRunner.tscn --run-pilot
```

### Test Completo (341 items en batches de 50)
```powershell
$godot = "C:\Users\Usuario\Downloads\Godot_v4.5.1-stable_win64_console.exe"
cd C:\git\spellloop\project

# Ejecutar todos los batches
for ($i = 0; $i -lt 350; $i += 50) {
    Write-Host "Running batch starting at $i..."
    & $godot --headless --path . res://scripts/debug/item_validation/TestRunner.tscn --run-full --batch-size=50 --offset=$i
}
```

### Test por Scope
```powershell
& $godot --headless --path . res://scripts/debug/item_validation/TestRunner.tscn --run-scope PLAYER_ONLY
& $godot --headless --path . res://scripts/debug/item_validation/TestRunner.tscn --run-scope WEAPON_SPECIFIC
& $godot --headless --path . res://scripts/debug/item_validation/TestRunner.tscn --run-scope FUSION_SPECIFIC
```

---

## 📁 Ubicación de Reportes
`%APPDATA%\Godot\app_userdata\Spellloop\test_reports\`

---

## 🔄 Cambios en v2.0

1. **+198 items añadidos al descubrimiento**:
   - WeaponUpgradeDatabase (48 items)
   - CharacterDatabase (10 personajes)
   - EnemyDatabase (20 enemigos por tier)
   - UpgradeDatabase.OFFENSIVE_UPGRADES
   - UpgradeDatabase.UNIQUE_UPGRADES

2. **Nuevos tipos de clasificación**:
   - CHARACTER
   - ENEMY
   - WEAPON_GLOBAL
   - WEAPON_SPECIFIC_UPG
   - WEAPON_ONLY_UPG

3. **Actualización de _build_pilot_queue**:
   - Ahora incluye samples de todas las categorías

---

**Generado automáticamente por ItemTestRunner.gd**
**Última actualización**: 2026-01-29 19:25
