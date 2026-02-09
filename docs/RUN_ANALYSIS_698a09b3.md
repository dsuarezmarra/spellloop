# Informe de Análisis Completo — Run 698a09b3-453d

> **Fecha de la Run**: 2026-02-09 17:22  
> **Personaje**: Storm Caller  
> **Versión**: 0.1.0-alpha (Godot 4.5.1-stable)  
> **Duración**: 94 minutos (sin evento de muerte registrado — partida abandonada/crasheada)  
> **Seed**: 0 (no aleatorizada)  
> **Armas iniciales**: ninguna (`starting_weapons: []`)

---

## 1. Resumen Ejecutivo

La run muestra una partida de 94 minutos con el Storm Caller que alcanzó DPS extremos (~4M/s en pico). Se identifican **7 bugs críticos**, **5 problemas de balance**, **3 problemas de telemetría** y **4 oportunidades de mejora**. El jugador es efectivamente inmortal desde el minuto 56 (60% dodge + HP>1000) pero el juego registra HP=1.0 desde el minuto 86 (inconsistencia de datos).

---

## 2. Lo Que Está Bien

### 2.1 Rendimiento Excelente
- **0 spikes de 33ms** y **0 spikes de 66ms** en los 94 minutos completos
- El juego mantiene fluidez perfecta incluso con frozen_thunder a ~1M DPS y miles de enemigos spawneados
- Sin problemas de rendimiento a pesar de 10 armas activas simultáneamente

### 2.2 Progresión de Armas Coherente
```
t=1-5min:   1 arma  (lightning_wand ~50 DPS)
t=6min:     3 armas (shadow_dagger, ice_wand añadidas)
t=8min:     5 armas (+wind_blade, unknown)
t=9min:     8 armas (+earth_spike, arcane_orb, shadow_orbs)
t=16min:    Fusión frozen_thunder (lightning+ice → 7709 DPS instantáneo)
t=21min:    10 armas (máximo alcanzado)
```
- La fusión `frozen_thunder` funciona correctamente como power spike masivo
- Las armas secundarias escalan bien como soporte

### 2.3 Sistema de Upgrades Funcional
- **60 mejoras elegidas** sin errores de aplicación en la mayoría
- **192 auditorías de upgrade** pasaron con `verdict: OK` en su mayoría
- El audit trail es detallado, registrando `before`, `after`, `delta`, `expected`
- Los weapon audits (33) y global weapon upgrades (21) se verifican correctamente

### 2.4 Escalado Infinito
- El sistema infinite scaling funciona: la run no crashea por duración
- Las fases de boss se ejecutan cada 5 minutos (18 bosses en 94 min)
- Hay 59 elites spawneados, bien distribuidos

---

## 3. Bugs Críticos

### 🔴 BUG-01: Armadura Negativa (-939) — `unique_glass_mage`
**Severidad: CRÍTICA**

El upgrade "Mago de Cristal" aplica `armor: -999 (add)`. Cuando el jugador tiene 40 de armadura:
```
40 + (-999) = -959 armor
```
Después se aplican 2x "Blindaje" (+10 cada uno) → **-939 armor**.

**Impacto**: Con armor negativo, `take_damage()` calcula:
```gdscript
var effective_damage = maxf(1.0, amount - armor)
# Si armor=-939 y amount=10: effective_damage = maxf(1.0, 10-(-939)) = 949
```
**¡El jugador recibe 949 de daño por un golpe de 10!** La armadura negativa actúa como amplificador de daño masivo.

**Causa raíz**: La descripción dice "armadura = 0" pero el efecto es `add -999`, no `set 0`.

**Fix necesario**: Cambiar el efecto a `{"stat": "armor", "value": 0, "operation": "set"}` O añadir un `clamp(0, ...)` a armor en `get_stat()`.

### 🔴 BUG-02: `max_health = 1.0` desde minuto 86 pero jugador sobrevive
**Severidad: ALTA**

El upgrade "Pacto de Cristal" (`unique_glass_cannon`) establece `max_health = 1.0` y activa `is_glass_cannon`. El registro muestra:
```
t=85min: HP=2484.37 (¡MÁXIMO de la partida!)
t=86min: HP=1.0
t=87-94min: HP=1.0
```
El jugador no muere porque tiene 53% dodge + `low_hp_damage_bonus`. Pero `max_health=1.0` con `armor=-939` significa que cualquier hit que no se esquive hace daño amplificado sobre 1 HP.

**El jugador sobrevive 8 minutos más** — esto sugiere que `dodge_chance` de 0.6 (60% capped) + posiblemente shield o algún otro mecanismo impide los hits.

**Problema de diseño**: Un jugador con HP=1 y Armor=-939 debería morir instantáneamente al primer hit no esquivado. La supervivencia de 8 minutos más sugiere que los enemigos casi nunca logran acertar, lo que indica que el escalado de dificultad no escala con el poder del jugador.

### 🔴 BUG-03: Economía de cofres y fusiones = 0 durante toda la partida
**Severidad: ALTA**

```
94 minutos de juego:
  Cofres normales abiertos: 0
  Cofres de elite: 0
  Cofres de boss: 0
  Fusiones realizadas: 0
  Rerolls usados: 0
```

Esto es imposible en una run de 94 minutos. Hay dos posibilidades:
1. **Los contadores de telemetría no se incrementan** (bug de tracking)
2. **Los cofres nunca aparecen** (bug de gameplay)

Dado que el jugador tiene 10 armas y 60 upgrades, es probable que los cofres SÍ aparezcan pero la telemetría no lo registra.

### 🔴 BUG-04: Falta evento `run_end` — run sin cierre
**Severidad: ALTA**

El audit log tiene 95 eventos: 1 `run_start` + 94 `minute_snapshot`. No hay:
- `run_end` (muerte o abandono)
- `level_up` events
- `boss_spawned` / `boss_defeated` events
- `phase_changed` events
- `death` events

El balance.jsonl SÍ tiene `boss_spawned` (18) y `elite_spawned` (59) y `upgrade_pick` (60). Esto indica que **audit.jsonl solo registra snapshots y start, pero NO registra eventos individuales de gameplay**.

### 🔴 BUG-05: `boss_spawned.enemy_id = None` en todos los bosses
**Severidad: MEDIA**

Los 18 eventos de boss en balance.jsonl tienen `enemy_id: None`:
```
t=5.0min: boss_spawned → enemy_id=None
t=10.0min: boss_spawned → enemy_id=None
...
t=90.1min: boss_spawned → enemy_id=None
```
No se puede saber qué boss apareció. La telemetría de bosses está rota.

### 🔴 BUG-06: 140 de 192 upgrades categorizadas como "unknown"
**Severidad: MEDIA**

```
Categorías de upgrades:
  unknown: 140  (72.9%)
  unique: 20
  offensive: 16
  defensive: 10
  utility: 5
  cursed: 1
```
El 73% de las mejoras aplicadas no tienen categoría asignada. Esto impide análisis de build diversity.

### 🔴 BUG-07: 6 auditorías con `verdict: FAIL`
**Severidad: MEDIA**

Upgrades que fallan su auditoría:
| Upgrade | ID | Fallo |
|---------|-----|-------|
| Caos Primigenio | unknown | `gws_stat_change`: Stat no cambió como se esperaba |
| Dilatación Temporal | unknown | `gws_stat_change`: Stat no cambió como se esperaba |
| Vampiro Energético | unknown | 5 stats no cambiaron como se esperaba |
| Vampiro Energético | unknown | `stat_change`: Before=1.000, After=1.000, Expected=0.000 |
| Ángel Guardián | unique_guardian_angel | `stat_change`: Before=1.000, After=1.000, Expected=-1.000 |
| Cazador de Tesoros | unique_treasure_hunter | `stat_change`: Before=3.000, After=3.000, Expected=3.750 |

Estos indican que los efectos de esos upgrades **no se aplican correctamente**.

---

## 4. Problemas de Balance

### ⚠️ BAL-01: `frozen_thunder` domina al 99%+ del DPS total
```
t=16min: frozen_thunder = 97.5% del DPS total (7709/7902)
t=60min: frozen_thunder = 98.8% del DPS total (866473/877008)
t=94min: frozen_thunder = 99.1% del DPS total (1922553/1939567)
```
Las otras 9 armas son irrelevantes. `earth_spike` ocasionalmente contribuye (~2-5%) y `shadow_orbs` algo, pero el resto genera 0 DPS literal.

**Propuesta**: Reducir la base o el scaling de fusiones, o buffear las armas base para que sigan siendo relevantes.

### ⚠️ BAL-02: Velocidad de movimiento sin cap efectivo
```
t=1min:  174.0
t=24min: 531.7 (3x base!)
t=28min: 750.0 (capped)
```
La velocidad llega a 750 y se queda ahí. Los speed toggles alternan 500 ↔ 750 (Vidrio Pesado multiplica×0.5 movespeed).

**Propuesta**: El cap de 750 funciona, pero la velocidad sube demasiado rápido. Considerar reducir el cap o el rate de escalado.

### ⚠️ BAL-03: Dodge de 60% + HP scaling = invulnerabilidad práctica
```
t=30min: dodge=0.13 (bien)
t=35min: dodge=0.23 (aceptable)
t=56min: dodge=0.53 (casi cap)
t=91min: dodge=0.60 (cap alcanzado)
```
Con 60% dodge y 2400+ HP, el jugador es prácticamente inmortal. Los enemigos hacen 286 damage total acumulado en 94 minutos vs millones de HP.

### ⚠️ BAL-04: Daño enemigo acumulado ridículamente bajo
```
94 minutos de juego:
  Daño total de enemigos al jugador: 286
  Hits totales al jugador: 25
  Muertes del jugador causadas por enemigos: 0
```
**25 hits en 94 minutos** es absurdo. Hay 3394 spawns de Titán Arcano con 0 hits. Los bosses spawneados tampoco hacen daño registrado. El escalado de dificultad no compensa la escalada del jugador. 

### ⚠️ BAL-05: `damage_mult` capped a 5.0 pero `crit_damage` a 13.16 sin cap
```
damage_mult: 1.0 → 5.0 (capped — bien)
crit_damage: 2.0 → 13.16 (¡sin cap visible!)
attack_speed_mult: 1.0 → 3.0 (sin cap explícito)
```
El crit_damage a 13.16x es un multiplicador masivo que, combinado con 32.9% crit chance, da un DPS efectivo enorme.

---

## 5. Problemas de Telemetría

### 📊 TEL-01: audit.jsonl solo registra snapshots
El archivo audit.jsonl debería registrar eventos individuales (level_up, boss_spawned, upgrade_picked, chest_opened, etc.) pero solo contiene `run_start` + 94 `minute_snapshot`. Compárese con balance.jsonl que SÍ registra `upgrade_pick`, `boss_spawned`, `elite_spawned`.

**Acción**: Verificar que `TelemetryManager._log_audit_event()` se llame para todos los eventos de gameplay.

### 📊 TEL-02: Arma reportada como "unknown" con DPS significativo
```
t=58min: unknown(10338dps)
t=68min: unknown(19028dps)
t=90min: unknown(60060dps)
```
Hay un arma sin `weapon_id` que genera DPS real. Probablemente un arma cuyo ID no se resuelve correctamente en la serialización del snapshot.

### 📊 TEL-03: Arma fantasma con 0 DPS permanente
```
Hay una entrada "(0dps)" sin ID en TODOS los snapshots desde t=8min.
```
Esto indica un slot de arma vacío o un arma eliminada/fallida que permanece en la lista.

---

## 6. Propuestas de Mejora

### 🔧 FIX-01: Clampear armor a mínimo 0
```gdscript
# En PlayerStats.get_stat():
if stat_name == "armor":
    return maxf(0.0, base_value + temp_bonus)
```
**Impacto**: Evita que "Mago de Cristal" amplifique daño. La descripción dice "armadura=0", no "armadura negativa".

### 🔧 FIX-02: Corregir "Mago de Cristal" en UpgradeDatabase
```gdscript
# Cambiar de:
{"stat": "armor", "value": -999, "operation": "add"}
# A:
{"stat": "armor", "value": 0, "operation": "set"}
```

### 🔧 FIX-03: Añadir `category` a upgrades con "unknown"
Revisar `UpgradeDatabase.gd` y asignar categorías correctas. El 73% sin categoría imposibilita el análisis de diversidad de builds.

### 🔧 FIX-04: Registrar `enemy_id` en eventos de boss
En el sistema de telemetría de balance, el campo `enemy_id` llega como `null` para todos los bosses.

### 🔧 FIX-05: Registrar contadores de cofres y fusiones
Los contadores `economy.chests` y `economy.fusions` están a 0 permanente. Verificar que se incrementen cuando ocurren.

### 🔧 FIX-06: Registrar eventos individuales en audit.jsonl
Crear/verificar hooks para: level_up, upgrade_selected, boss_spawned, boss_defeated, chest_opened, weapon_obtained, fusion_completed.

### 🔧 FIX-07: Limpiar arma fantasma "(0dps)"
Investigar qué arma sin ID aparece en los snapshots y eliminarla de la lista de armas activas.

### 🔧 FIX-08: Investigar audit failures de upgrades
6 upgrades fallan su auditoría — sus efectos no se aplican. Especialmente "Vampiro Energético" (5 stats fallan) y "Ángel Guardián" (flag no se activa).

---

## 7. Plan de Acción

| Prioridad | ID | Acción | Archivos | Complejidad |
|-----------|-----|--------|----------|-------------|
| P0-CRITICO | FIX-01 | Clamp armor ≥ 0 en `get_stat()` | PlayerStats.gd | Trivial |
| P0-CRITICO | FIX-02 | Corregir efecto "Mago de Cristal" | UpgradeDatabase.gd | Trivial |
| P1-ALTO | FIX-04 | Boss `enemy_id` en telemetría | TelemetryManager.gd / BalanceTelemetry | Bajo |
| P1-ALTO | FIX-05 | Contadores de cofres/fusiones | TelemetryManager.gd | Bajo |
| P1-ALTO | FIX-08 | Investigar 6 audit failures | UpgradeDatabase.gd + PlayerStats.gd | Medio |
| P2-MEDIO | FIX-03 | Categorizar upgrades "unknown" | UpgradeDatabase.gd | Medio |
| P2-MEDIO | FIX-06 | Eventos individuales en audit.jsonl | TelemetryManager.gd | Medio |
| P2-MEDIO | FIX-07 | Limpiar arma fantasma | AttackManager.gd | Bajo |
| P3-DISEÑO | BAL-01 | Rebalancear fusiones vs base weapons | WeaponDatabase/Balance | Alto |
| P3-DISEÑO | BAL-03 | Revisar dodge cap vs enemy accuracy | PlayerStats.gd + EnemyAttack | Medio |
| P3-DISEÑO | BAL-04 | Escalado de dificultad vs player power | WaveManager + DifficultyManager | Alto |

---

## 8. Cronología Detallada de la Run

| Minuto | DPS Total | Armas | HP | Armor | Dodge | Evento Notable |
|--------|-----------|-------|----|-------|-------|----------------|
| 1 | 21 | 1 | 85 | 0 | 0% | Solo lightning_wand |
| 5 | 68 | 1 | 99 | 0 | 3% | Primer boss spawn |
| 6 | 90 | 3 | 100 | 0 | 3% | +shadow_dagger, ice_wand |
| 8 | 448 | 5 | 102 | 0 | 3% | +wind_blade, unknown |
| 9 | 459 | 8 | 103 | 0 | 3% | +earth_spike, arcane_orb |
| 12 | 996 | 8 | 116 | 0 | 3% | Power spike por level ups |
| 16 | **7,902** | 9 | 124 | 20 | 3% | **FUSIÓN frozen_thunder** |
| 21 | 39,765 | 10 | 67 | 14 | 3% | 10 armas (cap) |
| 26 | 51,116 | 10 | 171 | 15 | 3% | Stats empiezan a escalar |
| 30 | 58,497 | 10 | 361 | 25 | 13% | Dodge sube |
| 41 | 177,728 | 10 | 634 | **-879** | 23% | **ARMOR NEGATIVA** (Mago de Cristal) |
| 44 | 181,521 | 10 | 876 | -959 | 23% | damage_mult = 5.0 (cap) |
| 56 | **499,618** | 10 | 1305 | -949 | **53%** | Segundo power spike |
| 77 | 1,161,177 | 10 | 2287 | -939 | 53% | Peak HP |
| 85 | 1,342,995 | 10 | **2484** | -939 | 53% | **MÁXIMO HP** |
| 86 | 2,756,806 | 10 | **1.0** | -939 | 53% | **Pacto de Cristal** (glass cannon) |
| 90 | 4,031,963 | 10 | 1.0 | -939 | **60%** | Peak DPS |
| 94 | 1,939,567 | 10 | 1.0 | -939 | 60% | **Fin de datos** (sin run_end) |

---

## 9. Datos Crudos de la Run

- **Archivo**: `C:\Users\Usuario\AppData\Roaming\Godot\app_userdata\Loopialike\runs\run_698a09b3-453d\`
- **audit.jsonl**: 391 KB, 95 líneas (1 start + 94 snapshots)
- **balance.jsonl**: 200 KB, 233 líneas (1 start + 95 snapshots + 60 picks + 18 bosses + 59 elites)
- **upgrade_audit.jsonl**: 97 KB, 246 líneas (192 audits + 33 weapon audits + 21 global weapon upgrades)
- **meta.json**: 532 bytes (metadata de la run)

---

*Informe generado el 2026-02-09 por análisis automatizado de telemetría de Loopialike.*
