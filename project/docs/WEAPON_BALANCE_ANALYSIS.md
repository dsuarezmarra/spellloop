# 📊 ANÁLISIS DE BALANCE DE ARMAS - LOOPIALIKE

**Fecha:** 4 de enero de 2026  
**Versión:** 1.0

Este documento contiene un análisis exhaustivo del balance de todas las armas del juego, incluyendo cálculos de DPS, comparativas de efectividad y recomendaciones de ajustes.

---

## 📋 ÍNDICE

1. [Armas Base - Análisis](#armas-base---análisis)
2. [Armas Fusión - Análisis](#armas-fusión---análisis)
3. [Conclusiones y Recomendaciones](#conclusiones-y-recomendaciones)

---

## ⚔️ ARMAS BASE - ANÁLISIS

### Tabla Comparativa de Stats Base

| Arma | Daño | Cooldown | DPS Base | Proyectiles | Pierce | Área | Efecto | Valor Efecto |
|------|------|----------|----------|-------------|--------|------|--------|--------------|
| **Ice Wand** | 10 | 1.4s | 7.14 | 1 | 0 | 1.0 | Slow | 30% x 2s |
| **Fire Wand** | 12 | 1.6s | 7.50 | 1 | 0 | 1.2 | Burn | 3 dmg/tick x 4s |
| **Lightning Wand** | 15 | 1.8s | 8.33 | 1 | 0 | 1.0 | Chain | 2 saltos |
| **Arcane Orb** | 8 | 0.0s* | ∞ (contacto) | 3 | 999 | 1.0 | None | - |
| **Shadow Dagger** | 7 | 0.9s | 7.78 | 1 | 3 | 0.8 | None | - |
| **Nature Staff** | 9 | 1.0s | 9.00 | 2 | 0 | 1.0 | Lifesteal | 1 HP/kill |
| **Wind Blade** | 6 | 1.2s | 5.00 | 3 | 1 | 1.0 | Knockback+ | 1.5x |
| **Earth Spike** | 20 | 1.8s | 11.11 | 1 (AOE) | 999 | 1.5 | Stun | 0.5s |
| **Light Beam** | 25 | 2.0s | 12.50 | 1 | 999 | 0.5 | Crit Chance | 20% |
| **Void Pulse** | 18 | 2.5s | 7.20 | 1 (AOE) | 999 | 2.0 | Pull | 150 fuerza |

*\* Arcane Orb es un arma orbital con daño por contacto continuo*

---

### 📈 ANÁLISIS DPS EFECTIVO

El DPS base no cuenta toda la historia. Necesitamos calcular el **DPS Efectivo** considerando:
- Proyectiles múltiples
- Pierce (enemigos atravesados)
- Daño por efectos (DoT)
- Área de efecto

#### Fórmula de DPS Efectivo:
```
DPS_Efectivo = (Daño × Proyectiles × min(Pierce+1, 3) + DañoEfecto) / Cooldown
```

| Arma | DPS Base | Multiplicador | DPS Efectivo | Tier |
|------|----------|---------------|--------------|------|
| **Ice Wand** | 7.14 | ×1.0 | **7.14** | C |
| **Fire Wand** | 7.50 | ×1.5 (burn: ~4.5 DPS extra) | **12.00** | B |
| **Lightning Wand** | 8.33 | ×3.0 (2 chains = 3 hits) | **25.00** | A+ |
| **Arcane Orb** | ~24.0* | ×3 orbes, ticks/seg | **24.00** | A |
| **Shadow Dagger** | 7.78 | ×4 (3 pierce = 4 hits) | **31.11** | A+ |
| **Nature Staff** | 9.00 | ×2 proyectiles | **18.00** | B+ |
| **Wind Blade** | 5.00 | ×3 proj × 2 pierce | **30.00** | A+ |
| **Earth Spike** | 11.11 | ×2.5 (AOE avg 2.5 enemies) | **27.78** | A |
| **Light Beam** | 12.50 | ×3 (pierce infinito) + 20% crit | **45.00** | S |
| **Void Pulse** | 7.20 | ×2.5 (AOE) | **18.00** | B+ |

*\* Arcane Orb calcula como: 8 dmg × 3 orbes × ~1 hit/seg = 24 DPS*

---

### ⚠️ PROBLEMAS DE BALANCE DETECTADOS EN ARMAS BASE

#### 🔴 ARMAS SOBREPOTENCIADAS (NERFS NECESARIOS)

##### 1. **LIGHT BEAM** - Tier S (Extremadamente fuerte)
- **Problema:** 25 daño base + pierce infinito + 20% crit = ~45 DPS efectivo
- **Comparación:** Casi el doble de DPS que la media (~25 DPS)
- **Recomendación:** 
  - Reducir daño de 25 → 20
  - O aumentar cooldown de 2.0s → 2.5s

##### 2. **SHADOW DAGGER** - Tier A+ (Ligeramente fuerte)
- **Problema:** Cooldown muy bajo (0.9s) con 3 pierce
- **Comparación:** DPS efectivo de 31 con solo 7 de daño base
- **Recomendación:** 
  - Aumentar cooldown de 0.9s → 1.1s
  - O reducir pierce de 3 → 2

##### 3. **LIGHTNING WAND** - Tier A+ (Fuerte con chain)
- **Problema:** 2 saltos adicionales = 3× el daño efectivo
- **Estado:** Aceptable pero en el límite superior
- **Recomendación:** Monitorear, posible reducción de chain a 1

---

#### 🟡 ARMAS EQUILIBRADAS (OK)

| Arma | Estado | Notas |
|------|--------|-------|
| **Fire Wand** | ✅ Equilibrada | El burn compensa el cooldown alto |
| **Arcane Orb** | ✅ Equilibrada | Requiere estar cerca de enemigos |
| **Nature Staff** | ✅ Equilibrada | 2 proyectiles homing + heal |
| **Earth Spike** | ✅ Equilibrada | Alto daño pero lento |
| **Void Pulse** | ✅ Equilibrada | Pull es muy útil pero CD alto |

---

#### 🔵 ARMAS DÉBILES (BUFFS NECESARIOS)

##### 1. **ICE WAND** - Tier C (Muy débil)
- **Problema:** Solo 7.14 DPS efectivo, el más bajo del juego
- **Comparación:** Menos de 1/3 del DPS promedio
- **Recomendación:** 
  - **Opción A:** Aumentar daño de 10 → 14
  - **Opción B:** Reducir cooldown de 1.4s → 1.0s
  - **Opción C:** Aumentar slow de 30% → 50%
  - **Preferida:** Opción A (daño 10 → 14) + Opción C (slow 30% → 40%)

##### 2. **WIND BLADE** - Tier C (Daño bajo)
- **Problema:** Solo 6 de daño base, el más bajo
- **Nota:** El alto número de proyectiles compensa parcialmente
- **Recomendación:** 
  - Aumentar daño de 6 → 8

---

### 📊 RESUMEN DE CAMBIOS RECOMENDADOS - ARMAS BASE

```
NERFS:
├── Light Beam:     damage 25 → 20, cooldown 2.0s → 2.3s
├── Shadow Dagger:  pierce 3 → 2, cooldown 0.9s → 1.0s
└── Lightning Wand: chain 2 → 1 (monitorear)

BUFFS:
├── Ice Wand:       damage 10 → 14, slow 30% → 40%
└── Wind Blade:     damage 6 → 8
```

---

## 🔮 ARMAS FUSIÓN - ANÁLISIS

### Tabla Completa de Fusiones (45 total)

| Fusión | Componentes | Daño | CD | DPS Base | Proj | Pierce | Área | Efecto Principal |
|--------|-------------|------|-----|----------|------|--------|------|------------------|
| Steam Cannon | Ice + Fire | 25 | 0.8s | 31.25 | 1 | 0 | 2.0 | Steam (slow+DoT) |
| Storm Caller | Lightning + Wind | 18 | 1.0s | 18.00 | 5 | 0 | 1.2 | Chain 2 |
| Soul Reaper | Shadow + Nature | 12 | 0.5s | 24.00 | 3 | 5 | 1.0 | Lifesteal 2 |
| Cosmic Barrier | Arcane + Light | 20 | 0.0s* | ~60.0 | 5 | 999 | 1.5 | Crit 25% |
| Rift Quake | Earth + Void | 40 | 2.5s | 16.00 | 1 | 999 | 3.0 | Stun 1.0s |
| Frostvine | Ice + Nature | 14 | 0.8s | 17.50 | 3 | 1 | 1.2 | Freeze 80% |
| Hellfire | Fire + Shadow | 15 | 0.6s | 25.00 | 2 | 4 | 1.0 | Burn 6/5s |
| Thunder Spear | Lightning + Light | 45 | 2.2s | 20.45 | 1 | 999 | 0.8 | Crit 35% |
| Void Storm | Void + Wind | 22 | 1.8s | 12.22 | 1 | 999 | 2.5 | Pull 200 |
| Crystal Guardian | Earth + Arcane | 16 | 0.0s* | ~48.0 | 4 | 3 | 1.3 | Stun 0.3s |
| Frozen Thunder | Ice + Lightning | 18 | 1.0s | 18.00 | 1 | 0 | 1.1 | Freeze+Chain |
| Frost Orb | Ice + Arcane | 10 | 0.0s* | ~30.0 | 4 | 999 | 1.2 | Slow 40% |
| Frostbite | Ice + Shadow | 11 | 0.5s | 22.00 | 2 | 4 | 0.9 | Slow 45% |
| Blizzard | Ice + Wind | 8 | 0.6s | 13.33 | 5 | 2 | 1.5 | Slow 35% |
| Glacier | Ice + Earth | 22 | 1.6s | 13.75 | 1 | 999 | 1.8 | Freeze 70% |
| Aurora | Ice + Light | 28 | 1.8s | 15.56 | 1 | 999 | 0.7 | Freeze 60% |
| Absolute Zero | Ice + Void | 20 | 2.2s | 9.09 | 1 | 999 | 2.2 | Freeze 90% |
| Plasma | Fire + Lightning | 22 | 1.2s | 18.33 | 1 | 0 | 1.4 | Burn+Chain |
| Inferno Orb | Fire + Arcane | 12 | 0.0s* | ~36.0 | 4 | 999 | 1.3 | Burn 4/3s |
| Wildfire | Fire + Nature | 13 | 0.9s | 14.44 | 3 | 1 | 1.1 | Burn 5/4.5s |
| Firestorm | Fire + Wind | 10 | 0.65s | 15.38 | 4 | 2 | 1.3 | Burn 3.5/3s |
| Volcano | Fire + Earth | 30 | 2.0s | 15.00 | 1 | 999 | 2.0 | Burn 6/4s |
| Solar Flare | Fire + Light | 35 | 1.9s | 18.42 | 1 | 999 | 0.8 | Burn 8/3s |
| Dark Flame | Fire + Void | 24 | 2.3s | 10.43 | 1 | 999 | 2.3 | Burn 7/5s |
| Arcane Storm | Lightning + Arcane | 14 | 0.0s* | ~42.0 | 4 | 0 | 1.0 | Chain 1 |
| Dark Lightning | Lightning + Shadow | 14 | 0.5s | 28.00 | 2 | 3 | 0.9 | Chain 2 |
| Thunder Bloom | Lightning + Nature | 16 | 1.1s | 14.55 | 2 | 0 | 1.0 | Lifesteal+Chain |
| Seismic Bolt | Lightning + Earth | 28 | 1.7s | 16.47 | 1 | 0 | 1.8 | Stun 0.6s |
| Void Bolt | Lightning + Void | 26 | 2.0s | 13.00 | 1 | 999 | 1.5 | Pull 100 |
| Shadow Orbs | Arcane + Shadow | 10 | 0.0s* | ~40.0 | 5 | 2 | 1.0 | Mark +25% |
| Life Orbs | Arcane + Nature | 9 | 0.0s* | ~27.0 | 4 | 999 | 1.1 | Lifesteal 3 |
| Wind Orbs | Arcane + Wind | 8 | 0.0s* | ~32.0 | 5 | 999 | 1.0 | Knockback 1.8x |
| Cosmic Void | Arcane + Void | 16 | 0.0s* | ~48.0 | 4 | 999 | 1.8 | Mark 1.5x |
| Phantom Blade | Shadow + Wind | 9 | 0.35s | 25.71 | 4 | 5 | 0.9 | Bleed 3/2s |
| Stone Fang | Shadow + Earth | 14 | 0.55s | 25.45 | 2 | 4 | 1.0 | Stun 0.3s |
| Twilight | Shadow + Light | 16 | 0.45s | 35.56 | 2 | 4 | 0.9 | Crit 30% |
| Abyss | Shadow + Void | 18 | 0.6s | 30.00 | 3 | 5 | 1.2 | Blind 2s |
| Pollen Storm | Nature + Wind | 7 | 0.65s | 10.77 | 5 | 2 | 1.3 | Lifesteal 1 |
| Gaia | Nature + Earth | 22 | 1.5s | 14.67 | 2 | 999 | 1.8 | Lifesteal 2 |
| Solar Bloom | Nature + Light | 30 | 1.8s | 16.67 | 1 | 999 | 0.7 | Lifesteal 5 |
| Decay | Nature + Void | 20 | 2.0s | 10.00 | 1 | 999 | 2.4 | Lifesteal 4 |
| Sandstorm | Wind + Earth | 12 | 0.8s | 15.00 | 6 | 3 | 1.6 | Blind 40% |
| Prism Wind | Wind + Light | 18 | 0.6s | 30.00 | 3 | 2 | 1.0 | Crit 25% |
| Radiant Stone | Earth + Light | 32 | 1.9s | 16.84 | 1 | 999 | 2.0 | Stun 0.8s |
| Eclipse | Light + Void | 50 | 2.5s | 20.00 | 1 | 999 | 2.5 | Execute 25% |

*\* Las armas orbitales (CD 0.0s) calculan DPS como: daño × proyectiles × hits_por_segundo*

---

### 📈 CÁLCULO DE DPS EFECTIVO - FUSIONES

Usando la misma fórmula que para armas base, pero considerando que las fusiones deberían ser ~2-3x más fuertes que sus componentes.

#### Ranking de DPS Efectivo (de mayor a menor):

| Rank | Fusión | DPS Efectivo | Componentes | Estado |
|------|--------|--------------|-------------|--------|
| 1 | **Cosmic Barrier** | ~180.0 | Arcane + Light | 🔴 OP |
| 2 | **Cosmic Void** | ~144.0 | Arcane + Void | 🔴 OP |
| 3 | **Arcane Storm** | ~126.0 | Lightning + Arcane | 🔴 OP |
| 4 | **Inferno Orb** | ~108.0 | Fire + Arcane | 🟡 Alto |
| 5 | **Shadow Orbs** | ~100.0 | Arcane + Shadow | 🟡 Alto |
| 6 | **Crystal Guardian** | ~96.0 | Earth + Arcane | 🟡 Alto |
| 7 | **Life Orbs** | ~81.0 | Arcane + Nature | 🟡 Alto |
| 8 | **Wind Orbs** | ~80.0 | Arcane + Wind | 🟡 Alto |
| 9 | **Frost Orb** | ~75.0 | Ice + Arcane | 🟡 Alto |
| 10 | **Twilight** | ~71.1 | Shadow + Light | 🔴 OP |
| 11 | **Dark Lightning** | ~56.0 | Lightning + Shadow | 🟡 Alto |
| 12 | **Steam Cannon** | ~55.0 | Ice + Fire | 🟡 Alto |
| 13 | **Phantom Blade** | ~51.4 | Shadow + Wind | ✅ OK |
| 14 | **Stone Fang** | ~50.9 | Shadow + Earth | ✅ OK |
| 15 | **Soul Reaper** | ~48.0 | Shadow + Nature | ✅ OK |
| 16 | **Hellfire** | ~50.0 | Fire + Shadow | ✅ OK |
| 17 | **Prism Wind** | ~45.0 | Wind + Light | ✅ OK |
| 18 | **Abyss** | ~45.0 | Shadow + Void | ✅ OK |
| 19 | **Frostbite** | ~44.0 | Ice + Shadow | ✅ OK |
| 20 | **Sandstorm** | ~45.0 | Wind + Earth | ✅ OK |
| 21 | **Storm Caller** | ~40.5 | Lightning + Wind | ✅ OK |
| 22 | **Rift Quake** | ~40.0 | Earth + Void | ✅ OK |
| 23 | **Volcano** | ~37.5 | Fire + Earth | ✅ OK |
| 24 | **Thunder Spear** | ~35.8 | Lightning + Light | ✅ OK |
| 25 | **Plasma** | ~36.7 | Fire + Lightning | ✅ OK |
| 26 | **Glacier** | ~34.4 | Ice + Earth | ✅ OK |
| 27 | **Solar Flare** | ~32.2 | Fire + Light | ✅ OK |
| 28 | **Thunder Bloom** | ~29.1 | Lightning + Nature | ✅ OK |
| 29 | **Wildfire** | ~28.9 | Fire + Nature | ✅ OK |
| 30 | **Frostvine** | ~35.0 | Ice + Nature | ✅ OK |
| 31 | **Gaia** | ~29.3 | Nature + Earth | ✅ OK |
| 32 | **Aurora** | ~27.2 | Ice + Light | ✅ OK |
| 33 | **Seismic Bolt** | ~24.7 | Lightning + Earth | 🔵 Bajo |
| 34 | **Firestorm** | ~30.8 | Fire + Wind | ✅ OK |
| 35 | **Solar Bloom** | ~25.0 | Nature + Light | 🔵 Bajo |
| 36 | **Radiant Stone** | ~25.3 | Earth + Light | 🔵 Bajo |
| 37 | **Blizzard** | ~26.7 | Ice + Wind | 🔵 Bajo |
| 38 | **Eclipse** | ~25.0 | Light + Void | 🔵 Bajo |
| 39 | **Dark Flame** | ~20.9 | Fire + Void | 🔵 Débil |
| 40 | **Void Storm** | ~24.4 | Void + Wind | 🔵 Débil |
| 41 | **Void Bolt** | ~20.8 | Lightning + Void | 🔵 Débil |
| 42 | **Decay** | ~20.0 | Nature + Void | 🔵 Débil |
| 43 | **Pollen Storm** | ~21.5 | Nature + Wind | 🔵 Débil |
| 44 | **Absolute Zero** | ~18.2 | Ice + Void | 🔵 Muy Débil |

---

### ⚠️ PROBLEMAS DE BALANCE DETECTADOS EN FUSIONES

#### 🔴 FUSIONES SOBREPOTENCIADAS (NERFS URGENTES)

##### 1. **COSMIC BARRIER** - ~180 DPS (Extremadamente OP)
- **Problema:** 5 orbes × 20 daño × pierce infinito + 25% crit
- **Comparación:** 4x más DPS que la fusión promedio (~45 DPS)
- **Recomendación:**
  ```
  damage: 20 → 12
  projectile_count: 5 → 4
  effect_value (crit): 0.25 → 0.15
  ```

##### 2. **COSMIC VOID** - ~144 DPS (Muy OP)
- **Problema:** 4 orbes × 16 daño × área 1.8 + mark damage bonus
- **Recomendación:**
  ```
  damage: 16 → 10
  area: 1.8 → 1.3
  ```

##### 3. **ARCANE STORM** - ~126 DPS (Muy OP)
- **Problema:** 4 orbes × 14 daño + chain extra
- **Recomendación:**
  ```
  damage: 14 → 9
  projectile_count: 4 → 3
  ```

##### 4. **TWILIGHT** - ~71 DPS (OP)
- **Problema:** Cooldown extremadamente bajo (0.45s) con 2 proyectiles + pierce + crit
- **Recomendación:**
  ```
  cooldown: 0.45s → 0.65s
  pierce: 4 → 3
  ```

##### 5. **Otras fusiones orbitales (Arcane combinations)**
Todas las fusiones con Arcane Orb tienden a ser muy fuertes debido a la naturaleza de daño continuo:
- **Inferno Orb, Shadow Orbs, Crystal Guardian, Life Orbs, Wind Orbs, Frost Orb**
- **Recomendación general:** Reducir daño base de TODAS las fusiones orbitales en 20-30%

---

#### 🔵 FUSIONES DÉBILES (BUFFS NECESARIOS)

##### 1. **ABSOLUTE ZERO** - ~18 DPS (Muy Débil)
- **Problema:** Cooldown muy alto (2.2s) para solo 20 de daño
- **A favor:** Tiene freeze 90%, pero el CD limita demasiado
- **Recomendación:**
  ```
  damage: 20 → 28
  cooldown: 2.2s → 1.8s
  ```

##### 2. **POLLEN STORM** - ~21 DPS (Débil)
- **Problema:** Solo 7 de daño base, muy bajo para una fusión
- **Recomendación:**
  ```
  damage: 7 → 11
  effect_value (lifesteal): 1 → 2
  ```

##### 3. **DECAY** - ~20 DPS (Débil)
- **Problema:** CD de 2.0s para solo 20 daño
- **Recomendación:**
  ```
  damage: 20 → 26
  cooldown: 2.0s → 1.7s
  ```

##### 4. **VOID BOLT** - ~21 DPS (Débil)
- **Problema:** Alto CD (2.0s) con solo 26 daño
- **Recomendación:**
  ```
  damage: 26 → 32
  cooldown: 2.0s → 1.6s
  ```

##### 5. **DARK FLAME** - ~21 DPS (Débil)
- **Problema:** CD muy alto (2.3s) limita demasiado el DPS
- **Recomendación:**
  ```
  cooldown: 2.3s → 1.8s
  damage: 24 → 28
  ```

##### 6. **VOID STORM** - ~24 DPS (Débil)
- **Problema:** CD de 1.8s alto para un arma de área
- **Recomendación:**
  ```
  damage: 22 → 28
  cooldown: 1.8s → 1.5s
  ```

##### 7. **BLIZZARD** - ~27 DPS (Ligeramente débil)
- **Problema:** Solo 8 de daño, muy bajo
- **Recomendación:**
  ```
  damage: 8 → 12
  ```

##### 8. **SEISMIC BOLT** - ~25 DPS (Ligeramente débil)
- **Problema:** CD alto para una fusión sin pierce
- **Recomendación:**
  ```
  damage: 28 → 32
  cooldown: 1.7s → 1.4s
  ```

---

## 📋 CONCLUSIONES Y RECOMENDACIONES

### Resumen de Cambios Propuestos

#### ARMAS BASE

```gdscript
# NERFS
"light_beam": {
    "damage": 25 → 20,
    "cooldown": 2.0 → 2.3
}
"shadow_dagger": {
    "pierce": 3 → 2,
    "cooldown": 0.9 → 1.0
}

# BUFFS
"ice_wand": {
    "damage": 10 → 14,
    "effect_value": 0.30 → 0.40  # slow
}
"wind_blade": {
    "damage": 6 → 8
}
```

#### FUSIONES - NERFS CRÍTICOS

```gdscript
# COSMIC BARRIER (arcane_orb + light_beam)
"cosmic_barrier": {
    "damage": 20 → 12,
    "projectile_count": 5 → 4,
    "effect_value": 0.25 → 0.15
}

# COSMIC VOID (arcane_orb + void_pulse)
"cosmic_void": {
    "damage": 16 → 10,
    "area": 1.8 → 1.3
}

# ARCANE STORM (lightning_wand + arcane_orb)
"arcane_storm": {
    "damage": 14 → 9,
    "projectile_count": 4 → 3
}

# TWILIGHT (shadow_dagger + light_beam)
"twilight": {
    "cooldown": 0.45 → 0.65,
    "pierce": 4 → 3
}

# Reducción general para fusiones orbitales:
# inferno_orb.damage: 12 → 9
# shadow_orbs.damage: 10 → 8
# crystal_guardian.damage: 16 → 12
# life_orbs.damage: 9 → 7
# wind_orbs.damage: 8 → 6
# frost_orb.damage: 10 → 8
```

#### FUSIONES - BUFFS NECESARIOS

```gdscript
# ABSOLUTE ZERO
"absolute_zero": {
    "damage": 20 → 28,
    "cooldown": 2.2 → 1.8
}

# POLLEN STORM
"pollen_storm": {
    "damage": 7 → 11,
    "effect_value": 1 → 2
}

# DECAY
"decay": {
    "damage": 20 → 26,
    "cooldown": 2.0 → 1.7
}

# VOID BOLT
"void_bolt": {
    "damage": 26 → 32,
    "cooldown": 2.0 → 1.6
}

# DARK FLAME
"dark_flame": {
    "cooldown": 2.3 → 1.8,
    "damage": 24 → 28
}

# VOID STORM
"void_storm": {
    "damage": 22 → 28,
    "cooldown": 1.8 → 1.5
}

# BLIZZARD
"blizzard": {
    "damage": 8 → 12
}

# SEISMIC BOLT
"seismic_bolt": {
    "damage": 28 → 32,
    "cooldown": 1.7 → 1.4
}
```

---

### 📊 Tabla de Balance Post-Cambios (Proyección)

#### Armas Base - DPS Efectivo Proyectado

| Arma | DPS Actual | DPS Proyectado | Cambio |
|------|------------|----------------|--------|
| Ice Wand | 7.14 | **14.00** | +96% ✅ |
| Fire Wand | 12.00 | 12.00 | = |
| Lightning Wand | 25.00 | 25.00 | = (monitorear) |
| Arcane Orb | 24.00 | 24.00 | = |
| Shadow Dagger | 31.11 | **22.00** | -29% ✅ |
| Nature Staff | 18.00 | 18.00 | = |
| Wind Blade | 30.00 | **26.67** | -11% ✅ |
| Earth Spike | 27.78 | 27.78 | = |
| Light Beam | 45.00 | **26.09** | -42% ✅ |
| Void Pulse | 18.00 | 18.00 | = |

**Rango objetivo:** 15-30 DPS efectivo ✅

#### Fusiones - Muestra de DPS Proyectado

| Fusión | DPS Actual | DPS Proyectado | Cambio |
|--------|------------|----------------|--------|
| Cosmic Barrier | ~180 | ~65 | -64% ✅ |
| Twilight | ~71 | ~44 | -38% ✅ |
| Absolute Zero | ~18 | ~31 | +72% ✅ |
| Pollen Storm | ~21 | ~34 | +62% ✅ |

**Rango objetivo fusiones:** 35-70 DPS efectivo ✅

---

### 🎯 Notas Finales

1. **Las fusiones orbitales son inherentemente más fuertes** debido a su naturaleza de daño continuo. Esto es intencional pero debe estar controlado.

2. **Las fusiones con Void tienden a ser más débiles** porque el efecto Pull es muy situacional. Compensar con más daño/menos CD.

3. **El sistema de niveles amplifica los desbalances** - un arma OP nivel 8 será 2.5x más OP. Por eso es crítico balancear bien el nivel 1.

4. **Considerar el contexto de juego:**
   - Armas con CC (stun, freeze) pueden tener menos DPS
   - Armas con sustain (lifesteal) pueden tener menos DPS
   - Armas AOE son mejores contra hordas, single-target contra bosses

5. **Iterar después de testing** - estos son cálculos teóricos. El balance real se ajusta jugando.

---

**Documento preparado para revisión de balance**  
**Próximo paso:** Implementar cambios en WeaponDatabase.gd
