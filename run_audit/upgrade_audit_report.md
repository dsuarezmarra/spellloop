# Upgrade Audit Report

**Run ID:** `6997666e-2b6f`
**Total Pickups:** 90
**Results:** ✅ OK: 88 | ❌ FAIL: 1 | ⚠️ WARN: 0 | 💀 DEAD: 1

## ❌ FAILED (1)

### Caos Primordial `chaos`
- Type: player_upgrade | Pickup #88
- **FAIL** `max_health`: Stat NO cambió. Before=1.000, After=1.000, Expected=0.800
  - Before: `1.000` → After: `1.000` (Expected: `0.800`)

## 💀 DEAD STATS (1)

Estos upgrades modifican stats que **no tienen consumidor en el código gameplay**:

- `unique_aoe_devastator` (Devastador de Área)
  - `aoe_damage_mult`: Stat se almacena (0.00→0.40) pero NO tiene consumidor en gameplay
  - `single_target_mult`: Stat se almacena (1.00→0.80) pero NO tiene consumidor en gameplay

## ✅ PASSED (88)

- `Poder` — damage_mult(+0.20)
- `Varita de Rayo Nv.1 → 2` — lightning_wand
- `Varita de Rayo Nv.2 → 3` — lightning_wand
- `Tiro Certero` — long_range_damage_bonus(+0.50)
- `Varita de Rayo Nv.3 → 4` — lightning_wand
- `Filo Mortal` — damage_flat(+8.00)
- `Onda Expansiva` — area_mult
- `Varita de Hielo Nv.1 → 2` — ice_wand
- `Poder Menor` — damage_mult(+0.10)
- `Varita de Rayo Nv.4 → 5` — lightning_wand
- `Varita de Hielo Nv.2 → 3` — ice_wand
- `Cazador Paciente` — damage_vs_slowed(+0.25)
- `Varita de Rayo Nv.7 → 8` — lightning_wand
- `Varita de Hielo Nv.3 → 4` — ice_wand
- `Largo Alcance` — range_mult
- `Varita de Hielo Nv.4 → 5` — ice_wand
- `Absorción` — kill_heal(+2.00)
- `Poder` — damage_mult
- `Velocidad` — move_speed(+17.40)
- `Inversor (Investor)` — damage_per_gold(+0.01)
- `Varita de Hielo Nv.6 → 7` — ice_wand
- `Más Opciones` — levelup_options(+1.00)
- `Aniquilación` — crit_damage
- `Varita de Hielo Nv.7 → 8` — ice_wand
- `Trueno Congelado` — frozen_thunder lightning_wand + ice_wand
- `Celeridad` — attack_speed_mult(+0.25)
- `Toque Ardiente` — burn_chance(+0.10)
- `Poder Menor` — damage_mult(+0.10)
- `Devorador` — kill_heal(+4.00)
- `Señor del Magnetismo` — pickup_range(+210.00) xp_mult(+0.50) move_speed(+40.02)
- `Varita de Fuego Nv.2 → 3` — fire_wand
- `Varita de Fuego Nv.3 → 4` — fire_wand
- `Sed de Sangre` — life_steal(+0.12)
- `Campo Gravitacional` — pickup_range_flat(+100.00)
- `Proyectil Extra` — extra_projectiles(+1.00)
- `Fortaleza de Hierro` — armor(+20.00)
- `Varita de Rayo Nv.2 → 3` — lightning_wand
- `Varita de Fuego Nv.4 → 5` — fire_wand
- `Maestría del Golpe` — crit_chance
- `Reacción en Cadena` — overkill_damage(+0.50)
- `Filo Afilado` — damage_flat(+3.00)
- `Imán Vital` — heal_on_pickup(+1.00)
- `Poder Mayor` — damage_mult(+0.35)
- `Iluminación` — xp_mult(+0.75)
- `Varita de Rayo Nv.3 → 4` — lightning_wand
- `Erudición` — xp_mult(+0.75)
- `Varita de Rayo Nv.4 → 5` — lightning_wand
- `Varita de Rayo Nv.5 → 6` — lightning_wand
- `Proyectil Extra` — extra_projectiles(+1.00)
- `Celeridad` — move_speed(+43.36)
- `Proyectil Extra` — extra_projectiles(+1.00)
- `Varita de Hielo Nv.7 → 8` — ice_wand
- `Imán Vital` — heal_on_pickup(+1.00)
- `Poder Superior` — damage_mult(+0.50)
- `Dilatación Temporal` — enemy_slow_aura(+0.25) attack_speed_mult move_speed(+54.19)
- `Trueno Congelado Nv.1 → 2` — frozen_thunder
- `Francotirador` — crit_chance(+0.50) crit_damage(+1.00) projectile_speed_mult(+0.30)
- `Venganza Divina` — thorns_percent(+0.50) thorns_stun(+0.30)
- `Velocidad de la Luz` — attack_speed_mult(+0.40)
- `Trueno Congelado Nv.2 → 3` — frozen_thunder
- `Trueno Congelado Nv.3 → 4` — frozen_thunder
- `Maldición del Tiempo` — status_duration_mult(+0.75)
- `Devastación Mortal` — damage_mult(+1.00) damage_taken_mult
- `Devastación Mortal` — damage_taken_mult(+0.50)
- `Crono-Salto` — chrono_jump_active(+1.00)
- `Poder Superior` — damage_mult(+0.50)
- `Nova de Escarcha` — freeze_chance status_duration_mult area_mult(+0.25)
- `Nova de Escarcha` — freeze_chance(+0.30) status_duration_mult(+0.75)
- `Crecimiento` — growth(+0.01)
- `Fusión Elemental` — burn_chance(+0.15) freeze_chance(+0.15) bleed_chance(+0.15) damage_vs_burning(+0.50) damage_vs_frozen(+0.50)
- `Berserker Puro` — damage_mult life_steal attack_speed_mult
- `Rey Midas` — pickup_range(+315.00) coin_value_mult(+0.50)
- `Vidrio Pesado` — damage_mult move_speed(-135.48)
- `Furia del Berserker` — damage_mult attack_speed_mult max_health(-12.75)
- `Devastación` — overkill_damage(+0.50)
- `Rayo de Plasma` — plasma fire_wand + lightning_wand
- `Tiro Certero` — long_range_damage_bonus(+0.50)
- `Pacto de Cristal` — damage_mult is_glass_cannon max_health(-71.25)
- `Rayo de Plasma Nv.1 → 2` — plasma
- `Velocidad del Viento` — move_speed(+54.19)
- `Pacto de Sangre` — blood_pact max_health(+0.00)
- `Poder Mayor` — damage_mult(+0.35)
- `Aflicción Persistente` — status_duration_mult(+0.15)
- `Espinas Venenosas` — thorns_percent(+0.20)
- `Poder Mayor` — damage_mult(+0.35)
- `Tormenta de Acero` — attack_speed_mult
- `Maestro de Explosiones` — explosion_chance(+0.25) explosion_damage(+50.00)
- `Cañón Frágil` — damage_mult damage_taken_mult(+0.45)
