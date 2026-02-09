# INFORME FINAL — Run 698a09b3-453d (Storm Caller)

> **Fecha de la run**: 2026-02-09 17:22:11  
> **Versión del juego**: 0.1.0-alpha (Godot 4.5.1-stable)  
> **Personaje**: Storm Caller  
> **Duración**: ~94 minutos (sin evento `run_end` — partida cerrada/crasheada)  
> **Seed**: 0 (determinística)  
> **Armas iniciales**: ninguna  
> **Informe generado**: 2026-02-09 — análisis automatizado con trazabilidad a código fuente

---

## ÍNDICE

1. [Resumen Ejecutivo](#1-resumen-ejecutivo)
2. [Lo que funciona bien](#2-lo-que-funciona-bien)
3. [Bugs Críticos](#3-bugs-críticos)
4. [Fallos de Auditoría de Upgrades](#4-fallos-de-auditoría-de-upgrades)
5. [Problemas de Balance](#5-problemas-de-balance)
6. [Problemas de Telemetría / Datos Sucios](#6-problemas-de-telemetría--datos-sucios)
7. [Fallos Desconocidos / Comportamientos Sospechosos](#7-fallos-desconocidos--comportamientos-sospechosos)
8. [Propuestas de Mejora](#8-propuestas-de-mejora)
9. [Plan de Acción](#9-plan-de-acción)
10. [Cronología Detallada](#10-cronología-detallada)
11. [Anexo: Datos Crudos](#11-anexo-datos-crudos)

---

## 1. Resumen Ejecutivo

La run muestra una partida de **94 minutos** con el Storm Caller que alcanza DPS extremos (~4M/s en pico con `frozen_thunder`). Se identifican:

| Categoría | Cantidad |
|-----------|----------|
| Bugs Críticos | **7** |
| Fallos de Auditoría (FAIL) | **6 de 246** upgrades (2.4%) |
| Problemas de Balance | **5** |
| Problemas de Telemetría | **5** |
| Comportamientos Sospechosos | **4** |
| Propuestas de Mejora | **12** |

**Hallazgo principal**: El jugador se vuelve **efectivamente inmortal** desde el minuto ~56 (60% dodge + HP alto), y el escalado de dificultad **no compensa** el poder del jugador. Los enemigos Tier 3 y Tier 4 con cientos de spawns no hacen **ningún daño** registrado. La fusión `frozen_thunder` concentra **99%+ del DPS total**, haciendo irrelevantes las otras 9 armas.

---

## 2. Lo que funciona bien

### 2.1 Rendimiento perfecto
- **0 spikes de 33ms** y **0 spikes de 66ms** en 94 minutos completos
- El motor mantiene fluidez total incluso con `frozen_thunder` generando 50,000+ DPS, 10 armas activas, y cientos de enemigos Tier 4 simultáneos
- El campo `performance.top_scopes` está siempre vacío (sin bottlenecks)

### 2.2 Sistema de auditoría de upgrades
- **240 de 246 auditorías** pasan con `verdict: OK` (97.6% éxito)
- El trail detalla `before`, `after`, `delta`, `expected` para cada stat modificado
- Se detectan correctamente caps aplicados (gold_mult capped a 3.0, damage_mult soft-capped)
- El sistema de UpgradeAuditor (`UpgradeAuditor.gd`) es robusto y bien diseñado

### 2.3 Progresión de armas coherente
```
t=1-5min:  1 arma   (lightning_wand ~50 DPS)
t=6min:    3 armas   (+shadow_dagger, ice_wand)
t=8min:    5 armas   (+wind_blade, arma "unknown")
t=9min:    8 armas   (+earth_spike, arcane_orb, shadow_orbs)
t=16min:   FUSIÓN    frozen_thunder (lightning+ice → 7,709 DPS instantáneo)
t=21min:   10 armas  (máximo alcanzado con shadow_orbs)
```

### 2.4 Fusión frozen_thunder
- La fusión funciona correctamente como power spike masivo
- El DPS escala de forma consistente: 7,709 → 14,106 → 32,241 → 50,272 → 53,819
- El sistema de fusiones es el gran diferenciador del juego

### 2.5 Sistema de caps funcional
Los STAT_LIMITS en `PlayerStats.gd` L578-600 funcionan correctamente:
- `damage_mult`: Soft-cap 3.0x → hard-cap 5.0x con diminishing returns (50% eficiencia)
- `dodge_chance`: Cap 0.60 (60%) — verificado en datos
- `move_speed`: Cap 500 (+path bonus 50% → 750 efectivo)
- `attack_speed_mult`: Cap 3.0x
- `xp_mult` / `gold_mult`: Cap 3.0x

### 2.6 Escalado infinito sin crashes
- La run de 94 minutos no crashea por duración
- 18 bosses spawneados cada ~5 minutos
- 59 elites spawneados correctamente
- Tier progression: T1 → T2 → T3 → T4 funciona

---

## 3. Bugs Críticos

### BUG-01: Armadura negativa (-939) amplifica daño recibido

**Severidad**: CRÍTICA  
**Archivos afectados**: `PlayerStats.gd` L1530, `UpgradeDatabase.gd` L2470

**Problema**: El upgrade `unique_glass_mage` ("Mago de Cristal") aplica `{"stat": "armor", "value": -999, "operation": "add"}`. Con 60 de armadura acumulada:
```
60 + (-999) = -939 armor
```

En `take_damage()` (PlayerStats.gd L1530):
```gdscript
var effective_damage = maxf(1.0, amount - armor)
# Si armor=-939 y amount=10: maxf(1.0, 10-(-939)) = 949
```

**Impacto**: Cada golpe de 10 de daño se convierte en **949 de daño**. La armadura negativa actúa como multiplicador de daño masivo.

**Causa raíz**: La descripción dice "armadura = 0" pero el efecto es `add -999`, no `set 0`. Además, `armor` **no está en STAT_LIMITS** (L578-600), por lo que no se clampea.

**Evidencia en datos**:
```
t=40min: armor = -879
t=41min: armor = -879 (tras aplicar Mago de Cristal)
t=44min: armor = -959
t=94min: armor = -939 (final)
```

---

### BUG-02: `max_health = 1.0` pero jugador sobrevive 8 minutos más

**Severidad**: ALTA  
**Archivos afectados**: `PlayerStats.gd` L1011-1015, `UpgradeDatabase.gd` L2412

**Problema**: `unique_glass_cannon` ("Pacto de Cristal") establece `is_glass_cannon = 1`, que fuerza `max_health = 1.0` en `get_stat()`:
```gdscript
if stat_name == "max_health":
    var is_glass = stats.get("is_glass_cannon", 0.0) + ...
    if is_glass > 0:
        return 1.0
```

**Datos**:
```
t=85min: HP = 2,484.37 (máximo de la partida)
t=86min: HP = 1.0      (Pacto de Cristal activado)
t=87-94min: HP = 1.0   (sobrevive 8 minutos con HP=1 y armor=-939)
```

Con HP=1 y armor=-939, cualquier golpe no esquivado debería matar instantáneamente. La supervivencia de 8+ minutos indica que:
1. El dodge de 60% es extremadamente efectivo
2. Los enemigos T4 **nunca logran impactar** (spawns masivos, 0 hits)
3. El sistema de escudo probablemente absorbe los pocos hits

---

### BUG-03: Contadores de economía siempre a 0 en audit.jsonl

**Severidad**: ALTA  
**Archivo afectado**: `RunAuditTracker.gd`

**Problema**: En los 94 minute_snapshot del audit log:
```json
"economy": {"chests": {"boss": 0, "elite": 0, "normal": 0}, "fusions": 0, "rerolls": 0}
```

Los contadores nunca se incrementan, pero el balance.jsonl SÍ registra `rerolls_total: 2` y el jugador tiene 10 armas + 60 upgrades (que implican cofres abiertos).

**Causa probable**: `RunAuditTracker` no recibe las señales de cofres/fusiones, o las recibe pero no las acumula en su snapshot. El balance.jsonl usa un tracker diferente (`BalanceTelemetry`) que sí funciona.

---

### BUG-04: Falta evento `run_end`

**Severidad**: ALTA  
**Archivo afectado**: `BalanceTelemetry.gd` L156

**Problema**: El audit.jsonl contiene 1 `run_start` + 94 `minute_snapshot`, sin ningún:
- `run_end`
- `death`
- `session_end`

La función `end_run()` en BalanceTelemetry.gd L156 existe, pero nunca fue llamada. Esto indica que la partida terminó de forma anormal (crash, alt-F4, o scene change sin cleanup).

---

### BUG-05: `enemy_id` vacío/null para bosses en telemetría de balance

**Severidad**: MEDIA  
**Archivo afectado**: `WaveManager.gd` L555-558, `BalanceTelemetry.gd` L419-430

**Problema**: Los 18 eventos `boss_spawned` en balance.jsonl no tienen `enemy_id` resuelto. En WaveManager, el `log_boss_spawned()` envía:
```gdscript
BalanceTelemetry.log_boss_spawned({
    "boss_id": boss_id,  # Este sí tiene valor
    "phase": current_phase
})
```

Pero en el balance log aparece como campo `enemy_id: None`. El campo `boss_id` SÍ existe en los datos pero se loguea bajo otro nombre.

---

### BUG-06: 73% de upgrades categorizadas como "unknown"

**Severidad**: MEDIA  
**Archivo afectado**: `UpgradeAuditor.gd`

**Distribución de categorías en la run**:
```
unknown:    140  (72.9%)
unique:      20
offensive:   16
defensive:   10
utility:      5
cursed:       1
```

La mayoría de Global Weapon Upgrades se auditan con `id: "unknown"` porque el UpgradeAuditor recibe el upgrade como `global_weapon_upgrade` sin resolver el `id` del catálogo.

---

### BUG-07: Arma fantasma sin `weapon_id` con DPS

**Severidad**: MEDIA  
**Archivos afectados**: `DamageCalculator.gd` L125, `EnemyBase.gd` L1424-1428

**Problema dual**:

1. **DamageCalculator.gd L125**: `var weapon_id = "unknown"` — hardcoded, nunca se actualiza desde el proyectil
2. **EnemyBase.gd L1424-1428**: `var weapon_id := "unknown"` — solo se popula si `_attacker.has_meta("weapon_id")`

En los datos hay dos armas fantasmas con DPS real:
- `weapon_id: "unknown"` — genera hasta 687 DPS (probablemente GlobalWeaponStats damage)
- `weapon_id: ""` — siempre ~0 DPS, 50% crit rate con 8 crits/16 hits (arma zombie)

La arma con `weapon_id: ""` sugiere un slot vacío o arma eliminada tras fusión que permanece en la lista de armas activas.

---

## 4. Fallos de Auditoría de Upgrades

### 6 upgrades con `verdict: FAIL` (de 246 total)

| # | Upgrade | ID | Stats que fallan | Causa raíz |
|---|---------|-----|-----------------|------------|
| 1 | **Caos Primigenio** | chaos | `armor: -10 add` no se aplica | El auditor GWS intenta verificar como Global Weapon Stat, pero `armor` es un player stat directo. El efecto SÍ se aplica (via `apply_upgrade`), pero el auditor lo comprueba en el pipeline equivocado |
| 2 | **Dilatación Temporal** | unique_time_dilation | `enemy_slow_aura: +0.25` no cambia | El stat `enemy_slow_aura` tiene lógica especial en `get_stat()` (L1052) que lee `chrono_jump_active`. Sin `chrono_jump_active= 1`, el `add 0.25` se guarda pero `get_stat` no lo refleja directamente |
| 3 | **Vampiro Energético** (GWS audit) | unique_energy_vampire | 5 stats: max_shield, shield_amount, shield_regen, life_steal, shield_regen_delay | El auditor GWS intenta verificar stats de `PlayerStats` como si fueran Global Weapon Stats — pipeline incorrecto |
| 4 | **Vampiro Energético** (player audit) | unique_energy_vampire | `shield_regen_delay: before=1.0, after=1.0, expected=0.0` | Ya está en su mínimo por STAT_LIMITS (min=1.0). Aplicar `-1.0` no baja de 1.0 por el clamp |
| 5 | **Ángel Guardián** | unique_guardian_angel | `shield_regen_delay: before=1.0, after=1.0, expected=-1.0` | Mismo problema: delay ya clampeado a min 1.0, `-2.0 add` no puede bajar más |
| 6 | **Cazador de Tesoros** | unique_treasure_hunter | `xp_mult: before=3.0, after=3.0, expected=3.75` | `xp_mult` capped a 3.0 en STAT_LIMITS. El `×1.25` multiplicaría a 3.75, pero el cap lo mantiene en 3.0 |

**Diagnóstico**:
- **Fallos 4, 5, 6**: Son **falsos positivos** del auditor — los stats están correctamente clampeados por STAT_LIMITS, pero el auditor no considera los caps al calcular el `expected`. **El juego funciona bien, el auditor necesita ajuste.**
- **Fallos 1, 2, 3**: Son **problemas de routing** del auditor — confunde player stats con global weapon stats.

---

## 5. Problemas de Balance

### BAL-01: `frozen_thunder` acapara 99%+ del DPS

```
Evolución del % DPS de frozen_thunder:
t=16min: 97.5%  (7,709 de 7,902 DPS total)
t=20min: 98.3%
t=30min: 98.9%
t=60min: 99.0%
t=94min: 99.1%  (1,922,553 de 1,939,567 DPS total)
```

Las otras 9 armas son **completamente irrelevantes** tras la fusión. `earth_spike` contribuye ~2% ocasionalmente, `shadow_orbs` algo, pero el resto genera literalmente 0 DPS en los últimos 30 minutos.

**Propuesta**: El power spike de fusión es demasiado extremo. Considerar:
- Reducir multiplicador base de fusiones
- Buff a armas base para que escalen con el nivel del jugador
- Sinergia entre armas en vez de dominancia total

---

### BAL-02: Dodge 60% + HP alto = invulnerabilidad práctica

```
Evolución dodge y daño recibido:
t=30min: dodge=0.13, damage_received_total=286
t=56min: dodge=0.53, damage_received_total=286 (¡sin daño nuevo en 26 minutos!)
t=94min: dodge=0.60, damage_received_total=286 (¡sin daño nuevo en 64 minutos!)

94 minutos de juego:
  Hits totales al jugador: 25
  Damage total del enemigo: 286
  Muertes causadas por enemigos: 0
```

**25 hits en 94 minutos, 0 desde el minuto 30**. Los enemigos Tier 3 y Tier 4 con cientos de spawns no impactan ni una vez. El problema no es solo el dodge — es que los **enemigos no atacan efectivamente**.

---

### BAL-03: Enemigos T3/T4 completamente inofensivos

```
Enemigos con 0 damage y 0 hits (en 94 minutos):
- Corruptor Alado (T3): 164 spawns, 0 hits, 0 damage
- Serpiente de Fuego (T3): 112 spawns, 0 hits, 0 damage
- Elemental de Hielo (T3): 144 spawns, 0 hits, 0 damage
- Caballero del Vacío (T3): 132 spawns, 0 hits, 0 damage
- Titán Arcano (T4): 503+ spawns, 0 hits, 0 damage
- Reina del Hielo (T4): 525+ spawns, 0 hits, 0 damage
- Dragón Etéreo (T4): 565+ spawns, 0 hits, 0 damage
- Archimago Perdido (T4): 547+ spawns, 0 hits, 0 damage
- El Conjurador Primigenio (Boss): 1 spawn, 0 hits, 0 damage
```

**Miles de enemigos spawneados sin lograr un solo hit**. Esto indica que:
1. Mueren instantáneamente antes de poder atacar (frozen_thunder DPS demasiado alto)
2. No tienen mecánicas de ataque efectivas contra un jugador con move_speed 500-750
3. El escalado de dificultad (`difficulty_mult` = 1.0 siempre) **nunca se activa**

---

### BAL-04: Escalado de dificultad estático

```json
"difficulty": {
    "elite_mult": 1.0,
    "enemy_dmg_mult": 1.0,
    "enemy_hp_mult": 1.0,
    "spawn_mult": 1.0,
    "speed_mult": 1.0
}
```

**Todos los multiplicadores en 1.0 durante los 94 minutos**. No hay ningún escalado dinámico. El jugador se hace exponencialmente más fuerte, pero los enemigos mantienen las mismas stats base.

---

### BAL-05: `crit_damage` sin cap efectivo

```
Evolución de crit_damage:
t=1min:  2.0
t=30min: 5.1
t=60min: 9.9
t=94min: 13.16 (¡6.58x la base!)
```

`crit_damage` no tiene entrada en STAT_LIMITS. Con 32.9% crit_chance y 13.16x crit_damage, el DPS efectivo se multiplica por un factor enorme. Comparado con `damage_mult` que sí tiene hard-cap 5.0x, `crit_damage` es el stat que más escala sin control.

---

## 6. Problemas de Telemetría / Datos Sucios

### TEL-01: audit.jsonl solo graba snapshots

El audit.jsonl tiene 95 líneas: 1 `run_start` + 94 `minute_snapshot`. No registra:
- `level_up` (60 level ups no logueados)
- `upgrade_picked` 
- `boss_spawned` / `boss_defeated`
- `chest_opened`
- `fusion_completed`
- `weapon_obtained`
- `death` / `run_end`

Mientras tanto, balance.jsonl SÍ registra `upgrade_pick` (60), `boss_spawned` (18), `elite_spawned` (59). **Hay duplicación parcial e inconsistencias entre los dos logs**.

---

### TEL-02: Codificación UTF-8 corrupta en nombres de enemigos

Múltiples nombres aparecen con caracteres mojibake:
```
"MurciÃ©lago EtÃ©reo" → debería ser "Murciélago Etéreo"
"Duende SombrÃo"     → debería ser "Duende Sombrío"
"El CorazÃ³n del VacÃo" → debería ser "El Corazón del Vacío"
"TitÃ¡n Arcano"      → debería ser "Titán Arcano"
"DragÃ³n EtÃ©reo"    → debería ser "Dragón Etéreo"
```

Los datos se escriben como UTF-8 pero con la codificación de caracteres española (tildes/eñes) corrupta. Probablemente el archivo se guarda sin BOM o con encoding incorrecto.

---

### TEL-03: Doble dos puntos (::) en JSON serializado

Múltiples líneas contienen `"kills_caused"::0` o `"hits_to_player"::5` (doble `:`) lo que produce **JSON inválido**. Esto podría causar parsing errors si los datos se procesan automáticamente.

```json
"kills_caused"::0    // ERROR - doble :
"hits_to_player"::5  // ERROR - doble :
```

---

### TEL-04: Datos de combate en snapshots permanecen congelados

Desde el minuto 16 (`frozen_thunder`), muchas armas muestran `dps_last_60s: 0.0` permanentemente:
```
lightning_wand: DPS=0 desde t=17 (arma reemplazada por fusión, pero permanece en lista)
ice_wand: DPS=0 desde t=17
earth_spike: DPS=0 desde t=17 (excepto breves picos)
```

Las armas que fueron "ingrediente" de una fusión deberían eliminarse de la lista de armas activas, o marcarse como `fused_into: "frozen_thunder"`.

---

### TEL-05: Counters de daño/kills son "rolling" pero no se usan

En `BalanceTelemetry.gd` L436-465, los métodos `add_damage_dealt()`, `add_kill()`, etc. incrementan counters rolling (`_damage_dealt_last_60s`), pero `log_minute_snapshot()` usa fuentes autoritativas directas (`BalanceDebugger`, `Game.run_stats`) en vez de estos counters. **Son código muerto funcional**.

---

## 7. Fallos Desconocidos / Comportamientos Sospechosos

### SOSPECHOSO-01: Arma con 50% crit rate y 0 weapon_id

Existe una entrada en TODOS los snapshots desde t=8:
```json
{"crit_rate": 0.5, "crits_total": 8, "damage_total": 53, "dps_last_60s": 0.0,
 "hits_total": 16, "kills": 0, "weapon_id": "", "weapon_name": ""}
```

- 16 hits con 8 crits (exactamente 50% crit rate)
- 53 de daño total en toda la partida
- No gana más hits/crits tras los primeros 8 minutos

Esto parece una **arma zombie** — posiblemente restos de un arma que fue fusionada o eliminada pero cuyo slot permanece activo en la serialización.

---

### SOSPECHOSO-02: `max_health` baja de 2,484 a 1 instantáneamente

```
t=85: max_health = 2,484.37
t=86: max_health = 1.0
```

El flag `is_glass_cannon` se activa y fuerza `return 1.0` en `get_stat("max_health")`. Pero esto no escala `current_health` a 1 — el jugador podría tener `current_health = 2484` internamente pero `max_health = 1`. Verificar si la lógica de heal/damage usa `max_health` correctamente cuando es menor que `current_health`.

---

### SOSPECHOSO-03: Estadísticas de daño de "unknown" enemigo nunca se resetean

El enemigo `unknown` acumula daño (190 total, 11 hits) desde los primeros minutos y **nunca cambia** en el resto de la partida:
```
t=11: enemy "unknown" → 95 damage, 9 hits
t=12: enemy "unknown" → 190 damage, 11 hits
t=94: enemy "unknown" → 190 damage, 11 hits (¡70 minutos sin cambio!)
```

Los ataques del enemigo "unknown" son: ice(66), arcane(50), dark(45), fire(29×7). Estos parecen ser ataques de un boss u enemigo que no logró identificarse correctamente.

---

### SOSPECHOSO-04: `damage_dealt_total` y `damage_taken_total` siempre 0 en balance

En todos los snapshots del balance.jsonl:
```json
"damage_dealt_total": 0,
"damage_done_last_60s": 0,
"damage_taken_total": 0
```

Pero el audit.jsonl SÍ tiene datos de DPS por arma (millones de daño). Los counters de `BalanceDebugger` como fuente autoritativa parecen no estar conectados.

---

## 8. Propuestas de Mejora

### FIX-01: Añadir `armor` a STAT_LIMITS con mínimo 0

**Archivo**: `PlayerStats.gd` L578-600  
**Cambio**: Añadir `"armor": {"min": 0.0, "max": 999.0}` a STAT_LIMITS

Esto evita que `unique_glass_mage` amplifique daño. Si la intención es "armadura = 0", usar `operation: "set"` en vez de `add -999`.

---

### FIX-02: Corregir efecto de `unique_glass_mage`

**Archivo**: `UpgradeDatabase.gd` L2470  
**Cambio**: Reemplazar `{"stat": "armor", "value": -999, "operation": "add"}` por `{"stat": "armor", "value": 0, "operation": "set"}`

La descripción dice "armadura = 0", no "armadura -999".

---

### FIX-03: Resolver `weapon_id: "unknown"` en DamageCalculator

**Archivo**: `DamageCalculator.gd` L125  
**Cambio**: En vez de `var weapon_id = "unknown"`, obtener el ID del meta del atacante:
```gdscript
var weapon_id = ""
if target.has_meta("last_attacker_weapon_id"):
    weapon_id = target.get_meta("last_attacker_weapon_id")
```

---

### FIX-04: Asegurar `weapon_id` en meta de proyectiles

**Archivo**: `EnemyBase.gd` L1424-1428, `SimpleProjectile.gd` L638  
**Cambio**: Garantizar que todos los proyectiles tengan `set_meta("weapon_id", ...)` al crearse en `ProjectileFactory`.

---

### FIX-05: Añadir `crit_damage` a STAT_LIMITS

**Archivo**: `PlayerStats.gd` L578-600  
**Cambio**: Añadir `"crit_damage": {"min": 1.0, "max": 8.0}` o similar para evitar escalado sin control.

---

### FIX-06: Auditor debe considerar STAT_LIMITS al calcular `expected`

**Archivo**: `UpgradeAuditor.gd`  
**Cambio**: Cuando calcula el valor `expected`, aplicar los mismos caps de STAT_LIMITS para no reportar falsos FAIL cuando el valor está correctamente clampeado.

---

### FIX-07: Corregir codificación UTF-8 en serialización de telemetría

**Archivos**: `RunAuditTracker.gd`, `BalanceTelemetry.gd`  
**Cambio**: Asegurar que los archivos JSONL se escriban con codificación UTF-8 correcta. Verificar que `FileAccess.open()` use `WRITE` sin flags de codificación legacy.

---

### FIX-08: Limpiar JSON inválido (doble ::)

**Archivo**: Serialización en `RunAuditTracker.gd`  
**Cambio**: Investigar dónde se genera el `::` doble. Probablemente un bug en la concatenación de strings al serializar el JSON manualmente en vez de usar `JSON.stringify()`.

---

### FIX-09: Activar escalado de dificultad dinámico

**Archivo**: `WaveManager.gd` (sección de difficulty scaling)  
**Cambio**: Los multiplicadores de dificultad están en 1.0 estático. Implementar escalado basado en:
- Tiempo de juego
- DPS del jugador
- Nivel del jugador
- Número de armas/fusiones

---

### FIX-10: Eliminar armas fusionadas de la lista activa

**Archivos**: `AttackManager.gd`, `RunAuditTracker.gd`  
**Cambio**: Cuando dos armas se fusionan, marcar las componentes como `status: "fused"` y excluirlas de los snapshots de telemetría.

---

### FIX-11: Registrar `run_end` en todos los paths de salida

**Archivo**: `BalanceTelemetry.gd` L156  
**Cambio**: Llamar `end_run()` desde:
- `_notification(NOTIFICATION_WM_CLOSE_REQUEST)`
- Scene change handlers
- Crash handlers (si es posible en Godot)

---

### FIX-12: Conectar BalanceDebugger con counters de daño/kills

**Archivo**: `BalanceTelemetry.gd` L252-260  
**Cambio**: Los fields `damage_dealt_total`, `damage_taken_total` en los balance snapshots usan `BalanceDebugger` como fuente, pero llegan como 0. Verificar que `BalanceDebugger` reciba las señales de daño.

---

## 9. Plan de Acción

### Fase 1: Bugs Críticos (implementar ahora)

| Prioridad | ID | Acción | Archivo | Complejidad |
|-----------|-----|--------|---------|-------------|
| P0 | FIX-01 | Añadir `armor` a STAT_LIMITS min=0 | PlayerStats.gd | Trivial |
| P0 | FIX-02 | Corregir efecto glass_mage: `set 0` en vez de `add -999` | UpgradeDatabase.gd | Trivial |
| P0 | FIX-05 | Añadir `crit_damage` a STAT_LIMITS con max razonable | PlayerStats.gd | Trivial |

### Fase 2: Calidad de Datos (siguiente sprint)

| Prioridad | ID | Acción | Archivo | Complejidad |
|-----------|-----|--------|---------|-------------|
| P1 | FIX-03 | Resolver weapon_id "unknown" en DamageCalculator | DamageCalculator.gd | Bajo |
| P1 | FIX-04 | Asegurar weapon_id en meta de proyectiles | ProjectileFactory.gd, EnemyBase.gd | Bajo |
| P1 | FIX-06 | Auditor considere STAT_LIMITS en expected | UpgradeAuditor.gd | Medio |
| P1 | FIX-07 | Corregir codificación UTF-8 | RunAuditTracker.gd | Bajo |
| P1 | FIX-08 | Limpiar JSON con :: dobles | RunAuditTracker.gd | Bajo |
| P1 | FIX-11 | Registrar run_end siempre | BalanceTelemetry.gd | Bajo |

### Fase 3: Balance de Juego (diseño)

| Prioridad | ID | Acción | Archivo | Complejidad |
|-----------|-----|--------|---------|-------------|
| P2 | FIX-09 | Activar escalado de dificultad dinámico | WaveManager.gd | Alto |
| P2 | FIX-10 | Limpiar armas fusionadas de listas | AttackManager.gd | Medio |
| P2 | FIX-12 | Conectar BalanceDebugger con daño/kills | BalanceTelemetry.gd | Medio |
| P3 | BAL-01 | Rebalancear fusiones vs armas base | WeaponDatabase | Alto |
| P3 | BAL-02 | Revisar eficacia de ataques enemigos | EnemyBase.gd | Alto |

---

## 10. Cronología Detallada

| Min | DPS Total | Armas | HP | Armor | Dodge | Crit Dmg | Move Speed | Evento Notable |
|-----|-----------|-------|----|-------|-------|----------|------------|----------------|
| 1 | 21 | 1 | 85 | 0 | 0% | 2.0 | 174 | Solo lightning_wand |
| 3 | 68 | 1 | 87 | 0 | 3% | 2.0 | 174 | Primeros upgrades |
| 5 | 68 | 1 | 99 | 0 | 3% | 2.0 | 191 | Boss 1 (El Corazón del Vacío) |
| 6 | 90 | 3 | 100 | 0 | 3% | 2.0 | 196 | +shadow_dagger, ice_wand |
| 8 | 448 | 5 | 102 | 0 | 3% | 2.0 | 201 | +wind_blade, arma unknown |
| 10 | 459 | 8 | 105 | 0 | 6% | 2.2 | 220 | +earth_spike, arcane_orb |
| 12 | 996 | 8 | 116 | 0 | 3% | 2.44 | 244 | Power spike por upgrades |
| 16 | **7,902** | 9 | 124 | 20 | 3% | 2.6 | 338 | **FUSIÓN frozen_thunder** |
| 18 | 32,633 | 9 | 80 | 17 | 3% | 2.68 | 232 | Pérdida de HP (cursed?) |
| 21 | 39,765 | 10 | 67 | 14 | 3% | 2.8 | 340 | +shadow_orbs (10 armas cap) |
| 26 | 51,116 | 10 | 171 | 15 | 3% | 3.0 | 364 | Stats empiezan a escalar |
| 29 | 54,428 | 10 | 354 | 24 | 3% | 4.8 | 750 | Move speed capped |
| 41 | - | 10 | 634 | **-879** | 23% | - | 750 | **ARMOR NEGATIVA** (glass_mage) |
| 56 | 499,618 | 10 | 1,305 | -949 | **53%** | 9.44 | 750 | Casi inmortal |
| 77 | 1,161,177 | 10 | 2,287 | -939 | 53% | 11.44 | 750 | Peak HP zone |
| 85 | 1,342,995 | 10 | **2,484** | -939 | 53% | 12.06 | 750 | **MÁXIMO HP** |
| 86 | 2,756,806 | 10 | **1.0** | -939 | 53% | 12.08 | 750 | **Pacto de Cristal** |
| 90 | 4,031,963 | 10 | 1.0 | -939 | **60%** | 13.0 | 750 | Peak DPS |
| 94 | 1,939,567 | 10 | 1.0 | -939 | 60% | 13.16 | 750 | **Fin de datos** |

---

## 11. Anexo: Datos Crudos

### Estado final del jugador (minuto 94)

```
Stats:
  max_health: 1.0 (is_glass_cannon)
  armor: -939.0
  dodge_chance: 0.60 (capped)
  crit_chance: 0.329
  crit_damage: 13.16
  damage_mult: 5.0 (hard capped)
  attack_speed_mult: 3.0 (capped)
  move_speed: 750.0 (capped)
  damage_reduction: 0.0
  hp_regen: 0.0
  life_steal: 0.0

Armas (10):
  frozen_thunder:  DPS ~53,000 (99.1% del total)
  lightning_wand:  DPS 0 (fusionada → zombie)
  earth_spike:     DPS ~75
  wind_blade:      DPS ~9
  shadow_dagger:   DPS 0
  ice_wand:        DPS 0 (fusionada → zombie)
  arcane_orb:      DPS 0
  shadow_orbs:     DPS ~193
  "unknown":       DPS ~335
  "" (fantasma):   DPS 0

Economía:
  Score: 190,920
  Gold total: 551,573
  Kills total: 19,512
  Bosses killed: 18
  Elites killed: 59
  Level: 61
  Rerolls: 2

Top upgrades (por stacks):
  gold_bag: 31 stacks
  gold_bag_shop: 28 stacks
  full_potion: 21 stacks
  shield_2: 3
  damage_3: 3
  low_hp_damage_1: 3
  status_duration_2: 3
  luck_3: 3
  crit_damage_2: 3
  damage_reduction_2: 3
```

### Archivos fuente de la run

| Archivo | Tamaño | Líneas | Contenido |
|---------|--------|--------|-----------|
| meta.json | 532 B | 1 | Metadata: personaje, versión, seed |
| audit.jsonl | 391 KB | 95 | 1 run_start + 94 minute_snapshot |
| balance.jsonl | 200 KB | 234 | 1 start + 95 snapshots + 60 picks + 18 bosses + 59 elites |
| upgrade_audit.jsonl | 97 KB | 247 | 240 OK + 6 FAIL audits |

---

*Informe generado el 2026-02-09 por análisis automatizado de telemetría y código fuente de Loopialike v0.1.0-alpha.*

---

## 12. Fixes Aplicados (Post-Análisis)

Tras el análisis se implementaron los siguientes cambios directamente en el código fuente:

### P0 — Críticos (Aplicados)

| Fix | Archivo | Cambio |
|-----|---------|--------|
| **FIX-01** | `PlayerStats.gd` L579 | Añadido `"armor": {"min": 0.0, "max": 999.0}` a `STAT_LIMITS` — impide armor negativo |
| **FIX-02** | `UpgradeDatabase.gd` ~L2470 | `unique_glass_mage` armor cambiado de `{"value": -999, "operation": "add"}` a `{"value": 0, "operation": "set"}` |
| **FIX-05** | `PlayerStats.gd` L579 | Añadido `"crit_damage": {"min": 1.0, "max": 8.0}` a `STAT_LIMITS` — cap de 800% crit |

### P1 — Telemetría y Auditoría (Aplicados)

| Fix | Archivo | Cambio |
|-----|---------|--------|
| **FIX-03** | `DamageCalculator.gd` L19-22, L125 | Añadido parámetro `attacker: Node = null` para extraer `weapon_id` correctamente |
| **FIX-04** | `OrbitalManager.gd`, `ChainProjectile.gd`, `ProjectileFactory.gd` | 4 callers actualizados para pasar `self` como `attacker` |
| **FIX-06** | `UpgradeAuditor.gd` L332-365 | `audit_global_weapon_upgrade()` ahora: (a) salta stats que no son `WEAPON_STATS`, (b) detecta caps con lógica `was_capped` |
| **FIX-11** | `Game.gd` L420, L972-981 | Conectada señal `quit_to_menu_pressed` + handler `_on_quit_to_menu()` + safety net `_exit_tree()` para registrar `run_end` |

### P2 — Calidad de Datos (Aplicados)

| Fix | Archivo | Cambio |
|-----|---------|--------|
| **FIX-ENEMY-NAME** | `BasePlayer.gd` L785 | `enemy_name` en `report_damage_to_player()` ahora usa `enemy_data.name` en vez del `enemy_id` técnico |

### Descartados (No son bugs reales)

| Issue | Resultado |
|-------|-----------|
| **FIX-07 (UTF-8 mojibake)** | Los archivos originales son UTF-8 válidos. La corrupción fue causada por la copia con PowerShell (doble-encoding). Sin cambio necesario. |
| **FIX-08 (doble :: en JSON)** | No existe en ningún archivo. Fue un artefacto visual del terminal. Sin cambio necesario. |

### Pendientes (Propuestos, no implementados)

| Fix | Prioridad | Descripción |
|-----|-----------|-------------|
| BAL-01 | P3 | Rebalanceo de fusiones vs armas base (requiere playtesting) |
| BAL-02 | P3 | Revisión de eficacia de ataque enemigo (requiere diseño) |

### Fase 3 — Aplicados (2ª ronda)

| Fix | Archivo(s) | Cambio |
|-----|------------|--------|
| **FIX-09** | `DifficultyManager.gd` | (1) Lazy retry para `game_manager` en `_process()` — corrige causa raíz de multiplicadores en 1.0. (2) Sistema adaptativo: `performance_factor` (0.7–1.3) basado en DPS/daño recibido, alimentado por BalanceTelemetry cada minuto. (3) Expuesto en `get_scaling_snapshot()`. |
| **FIX-10** | `RunAuditTracker.gd`, `AttackManager.gd` | `AuditWeaponStats` + campos `consumed_by_fusion`/`fused_into`. Nuevo método `report_fusion_completed()`. `_get_top_weapons()` filtra componentes fusionados. `AttackManager.fuse_weapons()` notifica al tracker antes de eliminar. |
| **FIX-12** | `BalanceDebugger.gd` | Eliminados guards `if not enabled: return` de TODOS los métodos de colección de datos (`log_damage_dealt`, `log_damage_taken`, `log_heal`, `log_elite_spawn/death`, `log_xp_gained`, `log_level_up`, `log_difficulty_scaling`). `enabled` ahora solo controla el overlay UI y prints de debug. Los contadores siempre se acumulan. |
| **SOSP-02** | `PlayerStats.gd` L1198-1207 | `_on_stat_changed()` ahora maneja `is_glass_cannon` y `blood_pact`: al activarse, clampa `current_health` a `get_stat("max_health")` (= 1.0) y emite `health_changed`. |
| **FIX-09b** | `BalanceTelemetry.gd` | Nuevo bridge `_update_adaptive_difficulty()` que alimenta `DifficultyManager.update_performance_factor()` con DPS estimado, daño recibido y kills tras cada snapshot de minuto. |

### Resumen de archivos modificados

| Archivo | Líneas afectadas |
|---------|------------------|
| `project/scripts/core/PlayerStats.gd` | +2 entries en STAT_LIMITS, +handler glass_cannon/blood_pact en `_on_stat_changed()` |
| `project/scripts/data/UpgradeDatabase.gd` | 1 efecto reescrito (glass_mage) |
| `project/scripts/weapons/projectiles/DamageCalculator.gd` | Signatura + audit hook refactorizado |
| `project/scripts/weapons/projectiles/OrbitalManager.gd` | 2 callsites actualizados |
| `project/scripts/weapons/projectiles/ChainProjectile.gd` | 1 callsite actualizado |
| `project/scripts/weapons/ProjectileFactory.gd` | 2 callsites actualizados (BeamEffect, AOEEffect) |
| `project/scripts/debug/UpgradeAuditor.gd` | audit_global_weapon_upgrade reescrito con cap-awareness |
| `project/scripts/game/Game.gd` | +signal connect, +_on_quit_to_menu(), +_exit_tree() |
| `project/scripts/entities/players/BasePlayer.gd` | enemy_name resolve con display name |
| `project/scripts/core/DifficultyManager.gd` | Lazy retry game_manager, performance_factor adaptativo, reset+snapshot actualizado |
| `project/scripts/debug/BalanceTelemetry.gd` | Bridge `_update_adaptive_difficulty()` tras snapshot de minuto |
| `project/scripts/debug/BalanceDebugger.gd` | Eliminados guards `if not enabled` de log functions (siempre coleccionan datos) |
| `project/scripts/debug/RunAuditTracker.gd` | +`consumed_by_fusion`/`fused_into` en AuditWeaponStats, +`report_fusion_completed()`, filtro en `_get_top_weapons()` |
| `project/scripts/core/AttackManager.gd` | Notificación a RunAuditTracker al fusionar armas |

*Fixes aplicados el 2026-02-09 como parte del plan de acción del informe.*
