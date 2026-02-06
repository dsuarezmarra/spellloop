# Balance Pass 3: Meta Diversity & Competitive Scoring

## Resumen Ejecutivo

Pass 3 se enfoca en:
1. **Meta Diversity**: Nerfs a outliers dominantes, buffs a opciones débiles
2. **Elite Fairness**: Límite de habilidades y restricciones de combos
3. **Late Progression**: Bonus XP para elites/bosses en Phase 3
4. **Competitive Scoring**: Nueva fórmula que premia acción y penaliza pasividad

---

## A) Meta Diversity - Cambios de Balance

### ARMAS NERFEADAS

| Arma | Stat | Antes | Después | Cambio |
|------|------|-------|---------|--------|
| Shadow Dagger | effect_value (curse) | 1.50x | 1.30x | -13% |
| Lightning Wand | damage | 15 | 13 | -13% |

**Justificación:**
- Shadow Dagger: El multiplicador 1.5x de curse con pierce hacía S-tier automático
- Lightning Wand: 15 dmg + 2 chains gratis = 45 dmg efectivo, doble de otras uncommon

### ARMAS BUFFEADAS

| Arma | Stat | Antes | Después | Cambio |
|------|------|-------|---------|--------|
| Void Pulse | damage | 18 | 22 | +22% |
| Void Pulse | cooldown | 2.5s | 2.3s | -8% |

**Justificación:**
- Void Pulse: DPS de 7.2 era muy bajo para Rare tier. El pull no compensaba.

### UPGRADES NERFEADOS

| Upgrade | Stat | Antes | Después | Cambio |
|---------|------|-------|---------|--------|
| Doble o Nada | multicast_chance | 0.20 | 0.17 | -15% |
| Doble o Nada | max_stacks | 3 | 2 | -33% |
| Flujo Arcano | attack_speed_mult | 1.45x | 1.40x | -3% |
| Flujo Arcano | max_stacks | 2 | 1 | -50% |
| Evolución | growth/min | 2% | 1.5% | -25% |
| Devastación | overkill_damage | 100% | 75% | -25% |

**Justificación:**
- Doble o Nada: 60% multicast a max stacks = 1.6x DPS pasivo
- Flujo Arcano: Doble dipping con otros attack speed creaba builds degeneradas
- Evolución: +120% a todo en 30 min era inevitable divergencia
- Devastación: Cascada exponencial en hordas densas

### UPGRADES BUFFEADOS

| Upgrade | Stat | Antes | Después | Cambio |
|---------|------|-------|---------|--------|
| Impacto | knockback_mult | 1.30x | 1.40x | +8% |

---

## B) Elite Fairness

### Cambios Implementados

**Antes:**
- Tier 4+ tenían TODAS las 6 habilidades simultáneas
- No había restricciones de combo

**Después:**
- Máximo **4 habilidades** por elite
- Selección aleatoria del pool según tier
- **Exclusión mutua**: Nova y Summon no pueden coexistir
- **Penalización de combo**: Dash + Rage reduce daño de dash en 30%

### Pool de Habilidades por Tier

| Tier | Habilidades Disponibles |
|------|------------------------|
| 1 | slam, dash |
| 2 | slam, dash, rage, nova |
| 3 | slam, dash, rage, nova, shield, summon |
| 4+ | Mismo que tier 3, pero se eligen 4 al azar |

### Combos Prohibidos

| Combo | Razón | Solución |
|-------|-------|----------|
| Nova + Summon | Overwhelm: oleada de proyectiles + minions | Exclusión mutua |
| Dash + Rage | Spike de daño doble | Dash hace -30% dmg |

---

## C) Late Progression

### Cambio de XP en Phase 3

**Problema:** En Phase 3 (90+ min), los niveles eran extremadamente lentos. Los elites/bosses que debían dar progreso no eran suficientemente recompensantes.

**Solución:**
- Elites y Bosses dan **+25% XP** en Phase 3

**Impacto esperado:**
- ~1 nivel cada 30-45 min en Phase 3 (antes era 45-60+ min)
- Incentiva cazar elites en endurance
- NO afecta Phase 1/2 (mantiene curva competitiva)

---

## D) Scoring Competitivo

### Fórmula Anterior

```
score = time*10 + level*500 + kills*25 + gold
```

**Problemas:**
- Tiempo lineal = tank AFK gana solo por sobrevivir
- Kills lineales = farm infinito
- No considera elites/bosses
- No penaliza daño recibido

### Nueva Fórmula

```gdscript
# Tiempo con diminishing después de 60 min
time_score = time_seconds * 8  (si t <= 60 min)
time_score = 28800 + (t - 3600) * 4  (si t > 60 min)

# Kills con sqrt (evita farm infinito)
kills_score = sqrt(kills) * 100

# Objetivos de alto valor
elite_score = elites * 750
boss_score = bosses * 3000

# Nivel
level_score = level * 400

# Penalización por daño
damage_penalty = damage_taken / 20

# Bonus por actividad
if kills_per_min > 30: score *= 1.10

final_score = time + kills + elites + bosses + level + gold*0.5 - penalty
```

### Ejemplos de Puntuación

#### Run A: Promedio (40 min)
```
Tiempo: 40 min = 2400s * 8 = 19,200
Kills: 800 → sqrt(800)*100 = 2,828
Elites: 3 * 750 = 2,250
Bosses: 0 * 3000 = 0
Level: 25 * 400 = 10,000
Damage: 2000/20 = -100
Gold: 500 * 0.5 = 250

Total = ~34,428 pts
```

#### Run B: Buena (90 min, alta acción)
```
Tiempo: 90 min = 28,800 + 1,800*4 = 36,000
Kills: 2500 → sqrt(2500)*100 = 5,000
Elites: 10 * 750 = 7,500
Bosses: 3 * 3000 = 9,000
Level: 45 * 400 = 18,000
Damage: 8000/20 = -400
Gold: 2000 * 0.5 = 1,000
Kill rate: 2500/90 = 27.7 (no bonus)

Total = ~76,100 pts
```

#### Run C: Endurance Tank (4h, acción baja)
```
Tiempo: 240 min = 28,800 + 10,800*4 = 72,000
Kills: 1200 → sqrt(1200)*100 = 3,464
Elites: 15 * 750 = 11,250
Bosses: 4 * 3000 = 12,000
Level: 35 * 400 = 14,000
Damage: 25000/20 = -1,250
Gold: 800 * 0.5 = 400
Kill rate: 1200/240 = 5 (no bonus, muy bajo)

Total = ~111,864 pts
```

#### Run D: Endurance Agresiva (4h, alta acción)
```
Tiempo: 240 min = 72,000
Kills: 6000 → sqrt(6000)*100 = 7,745
Elites: 25 * 750 = 18,750
Bosses: 8 * 3000 = 24,000
Level: 55 * 400 = 22,000
Damage: 15000/20 = -750
Gold: 3500 * 0.5 = 1,750
Kill rate: 6000/240 = 25 (no bonus)

Total = ~145,495 pts
```

### Análisis

| Run | Tiempo | Playstyle | Score |
|-----|--------|-----------|-------|
| A | 40 min | Promedio | 34K |
| B | 90 min | Agresivo | 76K |
| C | 4h | Tank pasivo | 112K |
| D | 4h | Agresivo | 145K |

**Observaciones:**
- Run D (4h agresiva) supera significativamente a Run C (4h pasiva)
- Run B (90 min agresiva) obtiene buen score competitivo
- El tiempo sigue importando, pero la actividad marca diferencia
- La penalización de daño evita estrategias "tank AFK"

---

## E) Validación de 6 Arquetipos

### 1. Tank Sustain
- **Viabilidad 30/60**: ✅ Alta (regen/armor/shield stack)
- **Potencial endurance**: ✅ Alto (diminishing returns del daño enemigo en P3)
- **Riesgo de exploit**: ⚠️ Medio - Penalización de damage_taken mitiga AFK
- **Cambios aplicados**: Penalización de scoring, nerf a Flujo Arcano

### 2. Glass Cannon Burst
- **Viabilidad 30/60**: ⚠️ Media (requiere skill de evasión)
- **Potencial endurance**: ❌ Bajo (one-shot en late)
- **Riesgo de exploit**: ✅ Bajo
- **Cambios aplicados**: Nerf a Shadow Dagger/Lightning

### 3. DoT/Status
- **Viabilidad 30/60**: ✅ Alta (burns/poisons scalan bien)
- **Potencial endurance**: ✅ Alto (daño % escala con HP enemigo)
- **Riesgo de exploit**: ⚠️ Medio - Growth nerf ayuda
- **Cambios aplicados**: Buffs a debilitar stats de status duration

### 4. Melee
- **Viabilidad 30/60**: ⚠️ Media (requiere sustain)
- **Potencial endurance**: ⚠️ Medio
- **Riesgo de exploit**: ✅ Bajo
- **Cambios aplicados**: Buff a knockback para mejor control

### 5. Ranged Projectile Spam
- **Viabilidad 30/60**: ✅ Alta
- **Potencial endurance**: ✅ Alto (con multicast/attack speed)
- **Riesgo de exploit**: ⚠️ Alto antes, Medio ahora
- **Cambios aplicados**: Nerf a Doble o Nada y Flujo Arcano

### 6. Control/Utility
- **Viabilidad 30/60**: ✅ Alta (slow/stun/pull)
- **Potencial endurance**: ✅ Alto (crowd control siempre útil)
- **Riesgo de exploit**: ✅ Bajo
- **Cambios aplicados**: Buff a Void Pulse

---

## Archivos Modificados

1. **WeaponDatabase.gd** - Nerfs/buffs a armas
2. **UpgradeDatabase.gd** - Nerfs/buffs a upgrades
3. **EnemyDatabase.gd** - Elite fairness system
4. **Game.gd** - Nueva fórmula de scoring + XP bonus Phase 3
5. **RankingScreen.gd** - Fallback scoring actualizado

---

## Plan de Test Manual

### Pre-requisitos
1. Activar BalanceDebugger con F10
2. Anotar métricas cada 15 minutos

### Tests Requeridos

1. **Run de 30 minutos (Tank)**
   - Verificar que el score no sea excesivamente alto
   - Confirmar penalización de daño funciona

2. **Run de 30 minutos (Glass Cannon)**
   - Verificar viabilidad post-nerfs
   - Comparar score con tank equivalente

3. **Run de 60+ minutos**
   - Verificar transición a Phase 2
   - Confirmar elite fairness (máx 4 abilities)

4. **Run de 90+ minutos (si posible)**
   - Verificar bonus XP en Phase 3
   - Confirmar elites no tienen Nova+Summon

5. **Verificación de combos de elite**
   - Observar que Nova y Summon no aparezcan juntos
   - Observar que Dash+Rage tenga daño reducido

### Métricas a Trackear

- Score final
- Kills totales
- Elites/Bosses killed
- Damage taken
- Nivel alcanzado
- Tiempo sobrevivido
