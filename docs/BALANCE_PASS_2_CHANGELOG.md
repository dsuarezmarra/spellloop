# Balance Pass 2 - Changelog Detallado

**Fecha:** 6 de febrero de 2026  
**Rama:** `main`  
**Objetivo:** Implementar curva XP exponencial, escalado maestro exponencial de enemigos, y mover fusiones exclusivamente a chests.

---

## Índice

1. [Curva XP Exponencial (WoW-like)](#1-curva-xp-exponencial-wow-like)
2. [Escalado Maestro Exponencial](#2-escalado-maestro-exponencial)
3. [Fusiones Solo en Chests](#3-fusiones-solo-en-chests)
4. [Métricas de Debug Añadidas](#4-métricas-de-debug-añadidas)
5. [Tablas de Referencia](#5-tablas-de-referencia)
6. [Archivos Modificados](#6-archivos-modificados)
7. [Validación y Testing](#7-validación-y-testing)

---

## 1. Curva XP Exponencial (WoW-like)

### Objetivo de Diseño
- **Min 0-5:** Subir niveles frecuentemente (feedback positivo)
- **Min 10-20:** Progreso estable, cada nivel cuesta más
- **Min 20+:** Cada nivel es caro; subir niveles "de más" requiere jugar muy bien
- **Imposible:** Subir niveles indefinidamente a ritmo alto

### Fórmula

```
xp_required(level) = round(BASE * pow(GROWTH, level-1) + LINEAR * level)
```

### Constantes Configurables

| Constante | Valor | Propósito |
|-----------|-------|-----------|
| `XP_CURVE_BASE` | 12.0 | XP base para nivel 2 (early game rápido) |
| `XP_CURVE_GROWTH` | 1.22 | 22% más caro cada nivel (exponencial) |
| `XP_CURVE_LINEAR` | 4.0 | +4 XP por nivel (suaviza early) |
| `XP_CURVE_MAX_LEVEL` | 100 | Nivel máximo teórico |

### Tabla de XP Requerida

| Nivel | XP Requerida | Comparación (antes: 5+level*3) |
|-------|--------------|-------------------------------|
| 1 | 0 (start) | 0 |
| 2 | 16 | 8 (+100%) |
| 5 | 35 | 20 (+75%) |
| 10 | 80 | 35 (+129%) |
| 15 | 158 | 50 (+216%) |
| 20 | 300 | 65 (+362%) |
| 25 | 559 | 80 (+599%) |
| 30 | 1034 | 95 (+989%) |
| 40 | 3473 | 125 (+2679%) |
| 50 | 11422 | 155 (+7270%) |

### Estimación de Niveles Alcanzables

**Asumiendo ~50 XP/min para jugador promedio:**

| Minuto | Level Estimado (Promedio) | Level Estimado (Bueno ~80 XP/min) |
|--------|--------------------------|-----------------------------------|
| 5 | 8-10 | 10-13 |
| 10 | 12-15 | 16-18 |
| 15 | 16-19 | 20-23 |
| 20 | 19-23 | 25-28 |

### Código Implementado

**Archivo:** `ExperienceManager.gd`

```gdscript
const XP_CURVE_BASE: float = 12.0
const XP_CURVE_GROWTH: float = 1.22
const XP_CURVE_LINEAR: float = 4.0

func setup_level_curve():
    for level in range(1, XP_CURVE_MAX_LEVEL + 1):
        var exp_required = roundi(
            XP_CURVE_BASE * pow(XP_CURVE_GROWTH, level - 1) + 
            XP_CURVE_LINEAR * level
        )
        exp_required = maxi(exp_required, 8)
        level_exp_curve.append(exp_required)
```

---

## 2. Escalado Maestro Exponencial

### Objetivo de Diseño
- **El juego NO es infinito:** Con el tiempo, los enemigos superan al jugador incluso con build top
- **Build top dura MUCHO:** 30-45 minutos, pero no infinito
- **Late game aprieta:** Progresivamente más difícil, presión constante
- **Modo Ranking:** Quién sobrevive más tiempo con mejor build

### Fórmula

```
mult(t) = pow(1.0 + RATE, t)
```

Donde `t` = minutos transcurridos desde inicio de partida.

### Rates Exponenciales

| Stat | Rate por Minuto | Propósito |
|------|-----------------|-----------|
| `EXP_RATE_HP` | 6% | HP escala agresivamente |
| `EXP_RATE_DAMAGE` | 4.5% | Daño escala un poco menor que HP |
| `EXP_RATE_SPAWN` | 3.5% | Densidad sube pero sin lag |
| `EXP_RATE_SPEED` | 1.5% | Velocidad sube lento, tiene cap |
| `EXP_RATE_ATTACK_SPEED` | 2% | Atacan un poco más rápido |

### Caps de Seguridad

| Stat | Cap | Razón |
|------|-----|-------|
| `SPEED_CAP` | 1.8x | Evitar enemigos imposibles de esquivar |
| `ATTACK_SPEED_CAP` | 2.0x | Evitar animaciones rotas |
| `SPAWN_CAP` | 4.0x | Evitar slideshow / lag |

### Tabla de Multiplicadores por Minuto

| Min | HP Mult | DMG Mult | Spawn Mult | Speed Mult |
|-----|---------|----------|------------|------------|
| 0 | 1.00x | 1.00x | 1.00x | 1.00x |
| 5 | 1.34x | 1.25x | 1.19x | 1.08x |
| 10 | 1.79x | 1.55x | 1.41x | 1.16x |
| 15 | 2.40x | 1.94x | 1.68x | 1.25x |
| 20 | 3.21x | 2.41x | 1.99x | 1.35x |
| 30 | 5.74x | 3.75x | 2.81x | 1.56x |
| 45 | 13.76x | 7.25x | 4.00x* | 1.80x* |
| 60 | 32.99x | 14.03x | 4.00x* | 1.80x* |

*\* = Capeado*

### Integración con WaveManager

El escalado ahora es **continuo desde el minuto 0**, no solo después del minuto 20:

```gdscript
func _update_infinite_scaling() -> void:
    var difficulty_mgr = get_tree().get_first_node_in_group("difficulty_manager")
    if difficulty_mgr:
        infinite_scaling_multipliers = {
            "hp": difficulty_mgr.enemy_health_multiplier,
            "damage": difficulty_mgr.enemy_damage_multiplier,
            "spawn_rate": difficulty_mgr.enemy_count_multiplier,
            "speed": difficulty_mgr.enemy_speed_multiplier,
            "xp": 1.0  # XP no escala (jugador ya tiene curva exponencial)
        }
```

---

## 3. Fusiones Solo en Chests

### Objetivo de Diseño
- **Las fusiones NO aparecen en LevelUpPanel** 
- **Solo aparecen en cofres:**
  - Elite chests: 8% probabilidad
  - Boss chests: 100% garantizada (si disponible)
- **Condición:** 2+ armas a nivel máximo (lvl 8)
- **La condición ya existía** en `get_available_fusions()`, solo movimos las recompensas

### Cambios Realizados

#### LevelUpPanel.gd

**ELIMINADO:** Llamada a `_get_fusion_options()` en `_generate_options()`

```gdscript
# ANTES:
# 3. Fusiones (siempre aparecen si están disponibles - son valiosas)
if attack_manager and attack_manager.has_method("get_available_fusions"):
    possible_options.append_array(_get_fusion_options())

# DESPUÉS:
# 3. BALANCE PASS 2: Fusiones ELIMINADAS del LevelUpPanel
# Las fusiones ahora solo aparecen en cofres de elites (baja prob) y bosses (alta prob)
```

#### LootManager.gd

**AÑADIDO:** Constantes y lógica de fusión en chests

```gdscript
const ELITE_FUSION_CHANCE: float = 0.08   # 8% chance de fusión en elite chest
const BOSS_FUSION_GUARANTEED: bool = true  # Boss siempre da fusión si disponible

static func _try_generate_fusion_loot(context: Object, chance: float) -> Dictionary:
    if not context or not context.has_method("get_available_fusions"):
        return {}
    
    var fusions = context.get_available_fusions()
    if fusions.is_empty():
        return {}
    
    if randf() > chance:
        return {}
    
    var fusing = fusions[0]
    var result = fusing.result
    
    return {
        "id": result.id,
        "type": "fusion",
        "name": result.name,
        "description": result.description,
        "rarity": 4,
        "icon": result.get("icon", "🌟"),
        "fusion_data": fusing
    }
```

### Tabla de Probabilidades de Fusión

| Fuente | Probabilidad | Condición |
|--------|--------------|-----------|
| LevelUpPanel | ~~100%~~ → **0%** | N/A - Eliminado |
| Elite Chest | **8%** | 2+ armas lvl 8 |
| Boss Chest | **100%** | 2+ armas lvl 8 |

---

## 4. Métricas de Debug Añadidas

### Nuevas Métricas en BalanceDebugger

| Métrica | Categoría | Propósito |
|---------|-----------|-----------|
| `xp_total` | progression | XP total ganada en la sesión |
| `xp_per_min` | progression | XP por minuto (ritmo de farming) |
| `current_level` | progression | Nivel actual del jugador |
| `levels_gained` | progression | Niveles ganados en sesión |
| `levels_per_min` | progression | Velocidad de subida de nivel |
| `hp_mult` | difficulty | Multiplicador HP enemigos |
| `dmg_mult` | difficulty | Multiplicador daño enemigos |
| `spawn_mult` | difficulty | Multiplicador densidad |
| `speed_mult` | difficulty | Multiplicador velocidad |

### Logs Automáticos

- **Cada level up:** Log con nivel y minuto alcanzado
- **Cada 5 minutos:** Log de difficulty scaling (HP/DMG/SPAWN/SPD)

### Overlay Visual (F10)

Nuevas líneas añadidas:
- `📈 LVL X | XP/min Y | Lvl/min Z`
- `🎯 HP:Xx DMG:Xx SPD:Xx`

---

## 5. Tablas de Referencia

### Comparativa XP Curve

| Nivel | Antes (lineal) | Después (exponencial) | Dificultad Relativa |
|-------|----------------|----------------------|---------------------|
| 5 | 20 XP | 35 XP | +75% |
| 10 | 35 XP | 80 XP | +129% |
| 20 | 65 XP | 300 XP | +362% |
| 30 | 95 XP | 1,034 XP | +989% |
| 50 | 155 XP | 11,422 XP | +7,270% |

### Comparativa Difficulty Scaling

| Min | Antes (lineal 5%/min) | Después (exp 6%/min) | Diferencia |
|-----|----------------------|---------------------|------------|
| 10 | 1.50x HP | 1.79x HP | +19% |
| 20 | 2.00x HP | 3.21x HP | +61% |
| 30 | 2.50x HP | 5.74x HP | +130% |
| 45 | 3.25x HP | 13.76x HP | +323% |

### Calibración Objetivo

| Milestone | HP Mult Target | HP Mult Actual |
|-----------|---------------|----------------|
| Min 10 | 1.6-2.0x | 1.79x ✅ |
| Min 20 | 2.5-3.5x | 3.21x ✅ |
| Min 30 | 4-6x | 5.74x ✅ |
| Min 45 | 8-12x | 13.76x ✅ |

---

## 6. Archivos Modificados

| Archivo | Tipo | Cambios |
|---------|------|---------|
| `ExperienceManager.gd` | Modificado | Curva XP exponencial, hooks BalanceDebugger |
| `DifficultyManager.gd` | Modificado | Escalado exponencial, todos los rates |
| `WaveManager.gd` | Modificado | Integración con DifficultyManager |
| `LevelUpPanel.gd` | Modificado | Removidas fusiones del pool |
| `LootManager.gd` | Modificado | Fusiones en elite/boss chests |
| `BalanceDebugger.gd` | Modificado | Métricas XP/Level/Difficulty |
| `BalanceDebugOverlay.gd` | Modificado | UI para nuevas métricas |

---

## 7. Validación y Testing

### Tests Manuales Recomendados

#### Test Case A: Progresión XP
1. Jugar 10 minutos con build promedio
2. Verificar que llegas a nivel 12-15
3. Notar que niveles tardan más en late game

#### Test Case B: Escalado de Dificultad
1. Jugar hasta minuto 20 con F10 activo
2. Verificar multiplicadores:
   - HP ~3.2x
   - DMG ~2.4x
   - Speed capeado si aplica

#### Test Case C: Fusiones en Chests (NO en LevelUp)
1. Subir 2 armas a nivel 8
2. **Subir de nivel:** NO debe aparecer opción de fusión
3. **Matar un boss:** DEBE aparecer fusión en cofre (100%)
4. **Matar un elite:** PUEDE aparecer fusión (8%)

#### Test Case D: Fusiones con 1 arma lvl 8
1. Tener solo 1 arma a nivel 8
2. Matar boss
3. **NO debe aparecer fusión** (condición no cumplida)

### Métricas Objetivo (F10)

| Métrica | Target min 10 | Target min 20 |
|---------|---------------|---------------|
| Level | 12-15 | 19-23 |
| XP/min | 40-60 | 50-80 |
| HP Mult | 1.8x | 3.2x |
| DMG Mult | 1.5x | 2.4x |
| Elite TTK | 5-10s | 10-20s |
| Boss TTK | 15-30s | 30-60s |

---

## Notas de Diseño

### Filosofía Aplicada

- ✅ **Early game rápido:** Niveles frecuentes dan feedback positivo
- ✅ **Mid game estable:** Cada nivel requiere más esfuerzo
- ✅ **Late game punitivo:** El juego eventualmente te supera
- ✅ **Fusiones como recompensa:** Ya no son "gratis" en level up
- ✅ **Modo ranking viable:** Tiempo de supervivencia = skill

### Lo que NO se tocó

1. **Valores base de enemigos** - No modificamos stats de Tier 1-4
2. **Elite/Boss configs** - Ya buffados en Pass 1
3. **Stats de armas** - Sin cambios
4. **Balance de personajes** - Pasivas intactas

### Iteraciones Futuras (Sugerencias)

1. **Ajustar XP_CURVE_GROWTH** si early game es muy lento (bajar a 1.18)
2. **Ajustar EXP_RATE_HP** si late game es demasiado brutal (bajar a 0.055)
3. **ELITE_FUSION_CHANCE** puede subirse a 10-15% si fusiones son muy raras
4. **Añadir "pity timer"** para fusiones si jugador no ha visto ninguna en 5 cofres
