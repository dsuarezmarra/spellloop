# 🎨 VFX ↔ Gameplay — Auditoría Exhaustiva

> **Fecha**: 8 de febrero de 2026  
> **Motor**: Godot 4.5.1 / GDScript  
> **Objetivo**: Corregir hooks VFX incorrectos, detectar placeholders, generar Asset Gap Pack con prompts IA, plan de implementación seguro.  
> **Restricción**: NO se toca balance numérico. Solo VFX, sincronización, integraciones y placeholders.

---

## ÍNDICE

1. [C) Inventario Automático](#c-inventario-automático)
2. [D) Auditoría Funcional + Visual](#d-auditoría-funcional--visual)
3. [E) Placeholders y Asset Gap Pack](#e-placeholders-y-asset-gap-pack)
4. [F) Implementación y Validación](#f-implementación-y-validación)

---

# C) INVENTARIO AUTOMÁTICO

## C.1 — VFX Assets Existentes (35 archivos)

| Categoría | Ruta | Tipo |
|-----------|------|------|
| **AOE** | `aoe/arcane/aoe_arcane_nova_spritesheet.png` | AOE impact (4×2, 128×128) |
| | `aoe/earth/aoe_ground_slam_spritesheet.png` | AOE impact (4×2, 128×128) |
| | `aoe/earth/aoe_elite_slam_spritesheet.png` | AOE impact (4×2, 153×204) |
| | `aoe/fire/aoe_damage_zone_fire_spritesheet.png` | Persistent zone (4×2, 153×204) |
| | `aoe/fire/aoe_fire_stomp_spritesheet.png` | AOE impact (4×2, 128×128) |
| | `aoe/fire/aoe_fire_zone_spritesheet.png` | Persistent zone (4×2, 256×256) |
| | `aoe/fire/aoe_meteor_impact_spritesheet.png` | AOE impact (4×2, 256×256) |
| | `aoe/ice/aoe_freeze_zone_spritesheet.png` | Persistent zone (4×2, 256×256) |
| | `aoe/rune/aoe_rune_blast_spritesheet.png` | AOE impact (4×2, 128×128) |
| | `aoe/void/aoe_damage_zone_void_spritesheet.png` | Persistent zone (4×2, 153×204) |
| | `aoe/void/aoe_void_explosion_spritesheet.png` | AOE impact (4×2, 128×128) |
| **AURA** | `auras/aura_buff_corruption_spritesheet.png` | Loop aura (6×2, 128×128) |
| | `auras/aura_damage_void_spritesheet.png` | Loop aura (6×2, 128×128) |
| | `auras/aura_elite_floor_spritesheet.png` | Loop aura (6×2, 128×128) |
| | `auras/aura_elite_rage_spritesheet.png` | Loop aura (4×2, 153×204) |
| | `auras/aura_elite_rare_spritesheet.png` | Loop aura (6×2, 128×128) |
| | `auras/aura_elite_shield_spritesheet.png` | Loop aura (4×2, 153×204) |
| | `auras/aura_enrage_spritesheet.png` | Loop aura (6×2, 128×128) |
| **BEAM** | `beams/beam_flame_breath_spritesheet.png` | Beam segment (6×2, 192×64) |
| | `beams/beam_void_beam_spritesheet.png` | Beam segment (6×2, 192×64) |
| **BOSS** | `boss_specific/conjurador/boss_summon_circle_spritesheet.png` | Boss FX (4×2, 192×192) |
| | `boss_specific/corazon_vacio/boss_reality_tear_spritesheet.png` | Boss FX (4×2, 192×192) |
| | `boss_specific/corazon_vacio/boss_void_pull_spritesheet.png` | Boss FX (4×2, 192×192) |
| | `boss_specific/guardian_runas/boss_rune_shield_spritesheet.png` | Boss FX (4×2, 192×192) |
| | `boss_specific/minotauro/boss_orbital_spritesheet.png` | Boss FX (4×2, 153×204) |
| | `boss_specific/minotauro/boss_phase_change_spritesheet.png` | Boss FX (4×2, 153×204) |
| **PROJ** | `projectiles/arcane/projectile_arcane_spritesheet.png` | Projectile (4×2, 64×64) |
| | `projectiles/fire/projectile_fire_spritesheet.png` | Projectile (4×2, 64×64) |
| | `projectiles/ice/projectile_ice_spritesheet.png` | Projectile (4×2, 64×64) |
| | `projectiles/poison/projectile_poison_spritesheet.png` | Projectile (4×2, 64×64) |
| | `projectiles/void/projectile_homing_orb_spritesheet.png` | Projectile (4×2, 153×204) |
| | `projectiles/void/projectile_void_homing_spritesheet.png` | Projectile (4×2, 64×64) |
| | `projectiles/void/projectile_void_spritesheet.png` | Projectile (4×2, 64×64) |
| **TELE** | `telegraphs/telegraph_charge_line_spritesheet.png` | Warning (4×2, 128×128) |
| | `telegraphs/telegraph_circle_warning_spritesheet.png` | Warning (4×2, 128×128) |
| | `telegraphs/telegraph_meteor_warning_spritesheet.png` | Warning (4×2, 128×128) |
| | `telegraphs/telegraph_rune_prison_spritesheet.png` | Warning (4×2, 128×128) |
| **ROOT** | `aura_elite_subtle.png` | Static sprite (single) |

### ⚠️ PROBLEMA CRÍTICO: Tamaño de spritesheets

**TODOS los 28 spritesheets** dentro de `abilities/` tienen tamaño real **612×408** px, pero sus tamaños esperados (frame_size × grid) son diferentes. Las imágenes fueron generadas por IA sin reescalar al formato correcto del spritesheet.

**Consecuencia**: Cuando `VFXManager.create_animated_sprite()` intenta recortarlas con `AtlasTexture` usando los `frame_size` definidos en config, las regiones no coinciden → los frames se ven **cortados, desplazados o vacíos**.

---

## C.2 — VFX Referenciados por Código

| Archivo | Assets Referenciados | Método |
|---------|---------------------|--------|
| `VFXManager.gd` | Todos los 35 assets (via configs) | `load()` / `preload()` con `VFX_BASE_PATH` |
| `WarningIndicator.gd` | 4 telegraphs | Directo `preload()` |
| `VFX_AOE_Impact.gd` | 8 AOE spritesheets | Directo `preload()` |
| `EnemyProjectile.gd` | 5 projectile + 6 impact spritesheets | Directo `preload()` |
| `EnemyBase.gd` | `aura_elite_subtle.png`, `aura_elite_floor.png` (ruta vieja) | Directo |

---

## C.3 — VFX Huérfanos (assets que existen pero NUNCA se usan realmente)

| Asset | Registrado en | ¿Llamado en código? | Motivo |
|-------|---------------|---------------------|--------|
| `aoe_fire_zone_spritesheet.png` | AOE_CONFIG["fire_zone"] | ❌ NUNCA | No hay habilidad que llame `spawn_aoe("fire_zone")` |
| `aoe_meteor_impact_spritesheet.png` | AOE_CONFIG["meteor_impact"] | ❌ NUNCA | `_spawn_meteor_impact` usa procedural, no VFXManager |
| `projectile_void_homing_spritesheet.png` | PROJECTILE_CONFIG["void_homing"] | ❌ NUNCA | Nunca referenciado por EAS ni EnemyProjectile |
| `aura_buff_corruption_spritesheet.png` | AURA_CONFIG["buff_corruption"] | ❌ NUNCA | `_boss_curse_aura` usa procedural |
| `aura_damage_void_spritesheet.png` | AURA_CONFIG["damage_void"] | ❌ NUNCA | Ninguna habilidad la usa |
| `aura_elite_floor_spritesheet.png` | AURA_CONFIG["elite_floor"] | ❌ INDIRECTO | `EnemyBase` usa imagen estática diferente en vez de spritesheet animado |
| `aura_elite_rare_spritesheet.png` | AURA_CONFIG["elite_rare"] | ❌ NUNCA | Ninguna habilidad la usa |
| `beam_flame_breath_spritesheet.png` | BEAM_CONFIG["flame_breath"] | ❌ NUNCA | `_spawn_breath_visual` es 100% procedural |
| `beam_void_beam_spritesheet.png` | BEAM_CONFIG["void_beam"] | ❌ NUNCA | `_spawn_void_beam_visual` es 100% procedural |
| `telegraph_circle_warning_spritesheet.png` | TELEGRAPH_CONFIG["circle_warning"] | ❌ NUNCA | `_spawn_aoe_warning` es procedural |
| `boss_reality_tear_spritesheet.png` | BOSS_CONFIG["reality_tear"] | ❌ NUNCA | `_boss_reality_tear` usa `_spawn_damage_zone` |

**Total: 11 assets huérfanos** (registrados en VFXManager pero jamás invocados).

---

## C.4 — Habilidades sin VFX (100% procedural sin equivalente registrado)

| Habilidad | Script | Función | Tipo Enemy |
|-----------|--------|---------|------------|
| Elite Dash | EnemyAttackSystem.gd | `_spawn_elite_dash_visual_start/trail` | Elite |
| Elite Nova | EnemyAttackSystem.gd | `_spawn_elite_nova_visual` | Elite |
| Elite Summon | EnemyAttackSystem.gd | `_spawn_elite_summon_visual` | Elite |
| Boss Teleport | EnemyAttackSystem.gd | `_spawn_teleport_effect` | Boss |
| Boss Curse Aura | EnemyAttackSystem.gd | `_spawn_curse_aura_visual` | Boss |
| Boss Counter Stance | EnemyAttackSystem.gd | `_spawn_counter_stance_visual` | Boss |
| Boss Impact | EnemyAttackSystem.gd | `_spawn_boss_impact_effect` | Boss |
| Orb Impact | EnemyAttackSystem.gd | `_spawn_orb_impact_effect` | Boss |
| Melee Slash | EnemyAttackSystem.gd | `_emit_melee_effect` | Normal |
| Player Thorns | BasePlayer.gd | (no existe) | Player |
| Player Shield Active | BasePlayer.gd | (no existe) | Player |
| Player Stun VFX | BasePlayer.gd | (no existe, solo flash) | Player |
| Player Slow VFX | BasePlayer.gd | (no existe, solo flash) | Player |
| Player Weakness VFX | BasePlayer.gd | (no existe, solo flash) | Player |
| Player Curse VFX | BasePlayer.gd | (no existe, solo flash) | Player |

---

# D) AUDITORÍA FUNCIONAL + VISUAL

## D.1 — Problemas Críticos (P0)

### ISSUE-001: Spritesheets con tamaño incorrecto (28 archivos)
- **ID**: SPRITESHEET_SIZE_MISMATCH
- **Afecta**: Todas las habilidades que usan VFXManager  
- **Trigger**: Cualquier llamada a `spawn_aoe()`, `spawn_beam()`, etc.
- **Gameplay**: No lo rompe (tiene fallback procedural)
- **VFX actual**: Los sprites se ven cortados/desplazados porque el atlas region no coincide con el tamaño real (612×408 vs esperado)
- **VFX esperado**: Frames correctamente recortados del spritesheet
- **Fix propuesto**: Reescalar los 28 PNGs a sus tamaños correctos (hframes×frame_size.x, vframes×frame_size.y)
- **Riesgo**: BAJO — solo resize de imágenes, no cambia código
- **Validación**: Ejecutar cualquier habilidad AOE/beam y verificar que la animación se vea correcta

### ISSUE-002: `flame_breath` beam asset NUNCA se usa
- **ID**: BEAM_FLAME_BREATH_ORPHAN
- **Afecta**: `_spawn_breath_visual()` y `_spawn_flame_breath_visual()` en EnemyAttackSystem
- **Trigger**: Ataque "breath" de Minotauro de Fuego y serpientes
- **VFX actual**: Polígono naranja procedural (`draw_colored_polygon` con 9 vértices cono)
- **VFX esperado**: Spritesheet animado `beam_flame_breath_spritesheet.png` (existe, nunca se llama)
- **Fix propuesto**: Hook `VFXManager.spawn_beam("flame_breath", ...)` al inicio de `_spawn_breath_visual()`, con fallback procedural actual
- **Riesgo**: BAJO
- **Validación**: Enfrentar serpiente de fuego o Minotauro, verificar cono de fuego

### ISSUE-003: `void_beam` beam asset NUNCA se usa
- **ID**: BEAM_VOID_BEAM_ORPHAN
- **Afecta**: `_spawn_void_beam_visual()` en EnemyAttackSystem
- **Trigger**: Ataque "void beam" del Corazón del Vacío
- **VFX actual**: Dos rectángulos (`draw_rect`) morados
- **VFX esperado**: Spritesheet animado `beam_void_beam_spritesheet.png` (existe, nunca se llama)
- **Fix propuesto**: Hook `VFXManager.spawn_beam("void_beam", ...)` al inicio de `_spawn_void_beam_visual()`, con fallback procedural actual
- **Riesgo**: BAJO
- **Validación**: Enfrentar Corazón del Vacío fase con void beam

### ISSUE-004: `meteor_impact` AOE asset NUNCA se usa
- **ID**: AOE_METEOR_IMPACT_ORPHAN
- **Afecta**: `_spawn_meteor_impact()` en EnemyAttackSystem
- **Trigger**: Meteoro del Minotauro de Fuego
- **VFX actual**: Círculos procedurales naranjas expandiéndose
- **VFX esperado**: Spritesheet animado `aoe_meteor_impact_spritesheet.png` (existe, nunca se llama)
- **Fix propuesto**: Hook `VFXManager.spawn_aoe("meteor_impact", ...)` al inicio de `_spawn_meteor_impact()`, con fallback procedural
- **Riesgo**: BAJO
- **Validación**: Enfrentar Minotauro, esperar lluvia de meteoros

### ISSUE-005: `circle_warning` telegraph NUNCA se usa
- **ID**: TELEGRAPH_CIRCLE_WARNING_ORPHAN
- **Afecta**: `_spawn_aoe_warning()` en EnemyAttackSystem
- **Trigger**: Warning genérico antes de AOE de boss
- **VFX actual**: Arcos y círculos procedurales rojos
- **VFX esperado**: Spritesheet animado `telegraph_circle_warning_spritesheet.png` (existe, nunca se llama)
- **Fix propuesto**: Hook `VFXManager.spawn_circle_warning(...)` al inicio de `_spawn_aoe_warning()`, con fallback procedural
- **Riesgo**: BAJO
- **Validación**: Enfrentar boss, esperar que lance AOE aleatorio

---

## D.2 — Fichas de Auditoría: Habilidades de Boss

### FICHA-B01: Minotauro — Flame Breath
| Campo | Valor |
|-------|-------|
| **ID** | `boss_flame_breath` |
| **Boss** | Minotauro de Fuego |
| **Trigger** | Fase 2+ del Minotauro, ataque de aliento |
| **Gameplay** | Cono de daño fuego delante del boss, dura ~0.5s |
| **Source** | `EnemyAttackSystem._boss_flame_breath()` L2564 |
| **VFX actual** | `_spawn_breath_visual()` → procedural `draw_colored_polygon` (cono naranja) |
| **VFX esperado** | `VFXManager.spawn_beam("flame_breath", ...)` con spritesheet animado |
| **Asset** | `beam_flame_breath_spritesheet.png` ✅ EXISTE (612×408, necesita resize a 1152×128) |
| **Estado** | ❌ **MISSING HOOK** |
| **Fix** | Añadir `_try_spawn_via_vfxmanager("flame_breath", "beam", ...)` al inicio de `_spawn_breath_visual()` |
| **Riesgo** | Bajo |

### FICHA-B02: Corazón del Vacío — Void Beam
| Campo | Valor |
|-------|-------|
| **ID** | `boss_void_beam` |
| **Boss** | Corazón del Vacío |
| **Trigger** | Ataque de haz de vacío |
| **Gameplay** | Línea de daño vacío desde boss hasta player |
| **Source** | `EnemyAttackSystem._boss_void_beam()` L2435 |
| **VFX actual** | `_spawn_void_beam_visual()` → procedural `draw_rect` ×2 (rectángulo morado) |
| **VFX esperado** | `VFXManager.spawn_beam("void_beam", ...)` |
| **Asset** | `beam_void_beam_spritesheet.png` ✅ EXISTE (612×408, necesita resize a 1152×128) |
| **Estado** | ❌ **MISSING HOOK** |
| **Fix** | Igual que flame_breath |
| **Riesgo** | Bajo |

### FICHA-B03: Minotauro — Meteor Call
| Campo | Valor |
|-------|-------|
| **ID** | `boss_meteor_call` |
| **Boss** | Minotauro de Fuego |
| **Trigger** | Fase 2+, invoca lluvia de meteoros |
| **Gameplay** | Warning circular → meteoro cae → AOE daño + burn |
| **Source** | `EnemyAttackSystem._boss_meteor_call()` L2593 |
| **VFX actual** | Warning: ✅ VFXManager `meteor_warning`. Impacto: ❌ procedural |
| **VFX esperado** | Warning: OK. Impacto: `VFXManager.spawn_aoe("meteor_impact", ...)` |
| **Asset** | `aoe_meteor_impact_spritesheet.png` ✅ EXISTE |
| **Estado** | ⚠️ **PARTIAL** — warning OK, impact MISSING |
| **Fix** | Añadir hook VFXManager en `_spawn_meteor_impact()` |
| **Riesgo** | Bajo |

### FICHA-B04: Corazón del Vacío — Curse Aura
| Campo | Valor |
|-------|-------|
| **ID** | `boss_curse_aura` |
| **Boss** | Corazón del Vacío (Conjurador también) |
| **Trigger** | Activación de aura de maldición |
| **Gameplay** | Aura persistente que debilita al player en rango |
| **Source** | `EnemyAttackSystem._boss_curse_aura()` L2370 |
| **VFX actual** | `_spawn_curse_aura_visual()` → procedural (6 círculos morados orbitando) |
| **VFX esperado** | `VFXManager.spawn_aura("buff_corruption", enemy)` |
| **Asset** | `aura_buff_corruption_spritesheet.png` ✅ EXISTE |
| **Estado** | ❌ **MISSING HOOK** |
| **Fix** | Añadir VFXManager call en `_boss_curse_aura()` |
| **Riesgo** | Bajo |

### FICHA-B05: Conjurador — Teleport Strike
| Campo | Valor |
|-------|-------|
| **ID** | `boss_teleport_strike` |
| **Boss** | Conjurador Primigenio |
| **Trigger** | Teleport → golpe melee |
| **Gameplay** | Desaparece → aparece junto al player → golpe |
| **Source** | `EnemyAttackSystem._boss_teleport_strike()` L2331 |
| **VFX actual** | `_spawn_teleport_effect()` → procedural (círculo morado) |
| **VFX esperado** | Efecto de "desvanecimiento" + "materialización" |
| **Asset** | ❌ NO EXISTE |
| **Estado** | ❌ **PLACEHOLDER** |
| **Fix** | Necesita asset nuevo (ver Asset Gap Pack E-05) |
| **Riesgo** | Medio (asset requerido) |

### FICHA-B06: Guardián de Runas — Counter Stance
| Campo | Valor |
|-------|-------|
| **ID** | `boss_counter_stance` |
| **Boss** | Guardián de Runas |
| **Trigger** | Entra en postura de contraataque |
| **Gameplay** | Refleja daño durante N segundos |
| **Source** | `EnemyAttackSystem._boss_counter_stance()` L2442 |
| **VFX actual** | `_spawn_counter_stance_visual()` → procedural (arco + 2 líneas) |
| **VFX esperado** | Aura/escudo brillante indicando estado de counter |
| **Asset** | ❌ NO EXISTE |
| **Estado** | ❌ **PLACEHOLDER** |
| **Fix** | Necesita asset nuevo (ver Asset Gap Pack E-07) |
| **Riesgo** | Medio |

---

## D.3 — Fichas de Auditoría: Habilidades Elite

### FICHA-E01: Elite Dash
| Campo | Valor |
|-------|-------|
| **ID** | `elite_dash` |
| **Enemigo** | Cualquier élite |
| **Trigger** | Carga rápida hacia el player |
| **VFX actual** | Procedural: arcos + trail de polígonos |
| **VFX esperado** | Motion lines / afterimage trail |
| **Asset** | ❌ NO EXISTE |
| **Estado** | ❌ **PLACEHOLDER** |

### FICHA-E02: Elite Nova
| Campo | Valor |
|-------|-------|
| **ID** | `elite_nova` |
| **Enemigo** | Cualquier élite |
| **Trigger** | Explosión AOE alrededor del élite |
| **VFX actual** | Procedural: arcos expandiéndose |
| **VFX esperado** | Podría reusar `aoe_arcane_nova_spritesheet.png` (ya mapeado en ABILITY_TO_AOE pero no usado) |
| **Asset** | ✅ EXISTE (mapeado como fallback) |
| **Estado** | ⚠️ **HOOK MISSING** — asset existe y está mapeado pero la función no lo usa |

### FICHA-E03: Elite Summon
| Campo | Valor |
|-------|-------|
| **ID** | `elite_summon` |
| **Enemigo** | Cualquier élite |
| **Trigger** | Invoca minions |
| **VFX actual** | Procedural: pentáculo con círculos |
| **VFX esperado** | Podría reusar `boss_summon_circle_spritesheet.png` |
| **Asset** | ✅ EXISTE en boss_specific |
| **Estado** | ⚠️ **HOOK MISSING** — asset existe, no se usa |

### FICHA-E04: Elite Aura Base
| Campo | Valor |
|-------|-------|
| **ID** | `elite_base_aura` |
| **Enemigo** | Todos los élites |
| **Trigger** | Al spawn del élite |
| **VFX actual** | `EnemyBase.gd` L553 → Sprite2D estática `aura_elite_subtle.png` con tweens de rotación |
| **VFX esperado** | AnimatedSprite2D con spritesheet `aura_elite_floor_spritesheet.png` (loop) via VFXManager |
| **Asset** | ✅ EXISTE ambos (sutil estática + spritesheet animado), pero usa la estática |
| **Estado** | ⚠️ **SUBÓPTIMO** — tiene asset animado mejor, usa el estático |

---

## D.4 — Fichas de Auditoría: Enemigos Normales

### FICHA-N01: Melee Attack Slash
| Campo | Valor |
|-------|-------|
| **ID** | `melee_slash` |
| **Enemigo** | Todos (normal) |
| **Trigger** | Ataque melee, en rango |
| **VFX actual** | `_emit_melee_effect()` → procedural (arcos + círculos) |
| **VFX esperado** | Slash spritesheet animado |
| **Asset** | ❌ NO EXISTE |
| **Estado** | ❌ **PLACEHOLDER** |

### FICHA-N02: Breath Attack
| Campo | Valor |
|-------|-------|
| **ID** | `normal_breath` |
| **Enemigo** | Serpientes de fuego, dragones menores |
| **Trigger** | Ataque de aliento |
| **VFX actual** | Procedural cono |
| **VFX esperado** | `VFXManager.spawn_beam("flame_breath", ...)` |
| **Asset** | ✅ EXISTE (beam_flame_breath_spritesheet.png) |
| **Estado** | ❌ **MISSING HOOK** — mismo issue que FICHA-B01 |

### FICHA-N03: Ranged Projectile
| Campo | Valor |
|-------|-------|
| **ID** | `ranged_projectile` |
| **Enemigo** | Magos, arqueros |
| **Trigger** | Ataque a distancia |
| **VFX actual** | `EnemyProjectile.gd` → Sprite2D con spritesheet por elemento |
| **VFX esperado** | Correcto |
| **Asset** | ✅ 5 elementos cubiertos |
| **Estado** | ✅ **OK** (excepto lightning/physical que usan fallback arcane) |

---

## D.5 — Fichas: VFX del Jugador

### FICHA-P01: Thorns (Espinas)
| Campo | Valor |
|-------|-------|
| **ID** | `player_thorns` |
| **Trigger** | Jugador recibe daño con thorns activo |
| **VFX actual** | NINGUNO (solo FloatingText sobre el enemigo) |
| **VFX esperado** | Flash de espinas en el jugador + partículas rebotando |
| **Asset** | ❌ NO EXISTE (carpeta `player/thorns/` vacía con .gitkeep) |
| **Estado** | ❌ **MISSING** |

### FICHA-P02: Shield Activo
| Campo | Valor |
|-------|-------|
| **ID** | `player_shield_active` |
| **Trigger** | Jugador tiene shield_amount > 0 |
| **VFX actual** | Solo barra azul sobre HP + flash al absorber |
| **VFX esperado** | Aura/burbuja azul semitransparente alrededor del jugador |
| **Asset** | ❌ NO EXISTE (carpeta `player/shield/` vacía con .gitkeep) |
| **Estado** | ❌ **MISSING** |

### FICHA-P03: Status — Stun
| Campo | Valor |
|-------|-------|
| **ID** | `player_stun_vfx` |
| **Trigger** | `apply_stun()` |
| **VFX actual** | Flash amarillo en sprite, FloatingText "STUN" |
| **VFX esperado** | Estrellas/pájaros orbitando la cabeza |
| **Asset** | ❌ NO EXISTE |
| **Estado** | ⚠️ **PLACEHOLDER** (funcional pero minimal) |

### FICHA-P04: Status — Slow
| Campo | Valor |
|-------|-------|
| **ID** | `player_slow_vfx` |
| **Trigger** | `apply_slow()` |
| **VFX actual** | Flash azul hielo en sprite |
| **VFX esperado** | Cadenas/hielo en los pies del jugador |
| **Asset** | ❌ NO EXISTE |
| **Estado** | ⚠️ **PLACEHOLDER** |

### FICHA-P05: EnemyProjectile — Trail
| Campo | Valor |
|-------|-------|
| **ID** | `enemy_projectile_trail` |
| **Trigger** | EnemyProjectile en vuelo |
| **VFX actual** | `trail_positions` array se mantiene pero `visual_node` (Sprite2D) no tiene `_draw()` callback |
| **VFX esperado** | Trail de partículas o polyline detrás del proyectil |
| **Asset** | N/A (code fix) |
| **Estado** | ❌ **BROKEN** — trail no se renderiza |

---

# E) PLACEHOLDERS Y ASSET GAP PACK

## E.0 — Prioridades

| Prioridad | Criterio |
|-----------|----------|
| **P0** | Assets que existen pero están rotos (reescalar) o hooks que faltan para assets existentes |
| **P1** | Assets que faltan para habilidades de boss/elite visibles frecuentemente |
| **P2** | Assets que faltan para efectos de jugador (debuffs, defensivos) |
| **P3** | Nice-to-have (melee slash general, trail de proyectiles, etc.) |

---

## E.1 — P0: Reescalado de Spritesheets (28 archivos)

No requiere generación IA — requiere un script de reescalado.

| Asset | Tamaño Actual | Tamaño Correcto | Grid |
|-------|--------------|-----------------|------|
| `aoe_arcane_nova_spritesheet.png` | 612×408 | 512×256 | 4×2 @128×128 |
| `aoe_fire_stomp_spritesheet.png` | 612×408 | 512×256 | 4×2 @128×128 |
| `aoe_void_explosion_spritesheet.png` | 612×408 | 512×256 | 4×2 @128×128 |
| `aoe_ground_slam_spritesheet.png` | 612×408 | 512×256 | 4×2 @128×128 |
| `aoe_rune_blast_spritesheet.png` | 612×408 | 512×256 | 4×2 @128×128 |
| `aoe_fire_zone_spritesheet.png` | 612×408 | 1024×512 | 4×2 @256×256 |
| `aoe_freeze_zone_spritesheet.png` | 612×408 | 1024×512 | 4×2 @256×256 |
| `aoe_meteor_impact_spritesheet.png` | 612×408 | 1024×512 | 4×2 @256×256 |
| `aoe_damage_zone_fire_spritesheet.png` | 612×408 | 612×408 | 4×2 @153×204 ✅ OK |
| `aoe_damage_zone_void_spritesheet.png` | 612×408 | 612×408 | 4×2 @153×204 ✅ OK |
| `aoe_elite_slam_spritesheet.png` | 612×408 | 612×408 | 4×2 @153×204 ✅ OK |
| `aura_buff_corruption_spritesheet.png` | 612×408 | 768×256 | 6×2 @128×128 |
| `aura_damage_void_spritesheet.png` | 612×408 | 768×256 | 6×2 @128×128 |
| `aura_elite_floor_spritesheet.png` | 612×408 | 768×256 | 6×2 @128×128 |
| `aura_elite_rare_spritesheet.png` | 612×408 | 768×256 | 6×2 @128×128 |
| `aura_enrage_spritesheet.png` | 612×408 | 768×256 | 6×2 @128×128 |
| `aura_elite_rage_spritesheet.png` | 612×408 | 612×408 | 4×2 @153×204 ✅ OK |
| `aura_elite_shield_spritesheet.png` | 612×408 | 612×408 | 4×2 @153×204 ✅ OK |
| `beam_flame_breath_spritesheet.png` | 612×408 | 1152×128 | 6×2 @192×64 |
| `beam_void_beam_spritesheet.png` | 612×408 | 1152×128 | 6×2 @192×64 |
| `telegraph_charge_line_spritesheet.png` | 612×408 | 512×256 | 4×2 @128×128 |
| `telegraph_circle_warning_spritesheet.png` | 612×408 | 512×256 | 4×2 @128×128 |
| `telegraph_meteor_warning_spritesheet.png` | 612×408 | 512×256 | 4×2 @128×128 |
| `telegraph_rune_prison_spritesheet.png` | 612×408 | 512×256 | 4×2 @128×128 |
| `boss_summon_circle_spritesheet.png` | 612×408 | 768×384 | 4×2 @192×192 |
| `boss_reality_tear_spritesheet.png` | 612×408 | 768×384 | 4×2 @192×192 |
| `boss_void_pull_spritesheet.png` | 612×408 | 768×384 | 4×2 @192×192 |
| `boss_rune_shield_spritesheet.png` | 612×408 | 768×384 | 4×2 @192×192 |
| `boss_orbital_spritesheet.png` | 612×408 | 612×408 | 4×2 @153×204 ✅ OK |
| `boss_phase_change_spritesheet.png` | 612×408 | 612×408 | 4×2 @153×204 ✅ OK |

**7 assets ya están en el tamaño correcto** (153×204 × 4×2 = 612×408). **21 necesitan reescalado**.

---

## E.2 — P0: Hooks faltantes para assets existentes (código)

Estos fixes son cambios mínimos de código — los assets ya existen.

| # | Hook | Fix Requerido |
|---|------|---------------|
| FIX-01 | `_spawn_breath_visual()` | Añadir `VFXManager.spawn_beam("flame_breath", ...)` como primer intento |
| FIX-02 | `_spawn_void_beam_visual()` | Añadir `VFXManager.spawn_beam("void_beam", ...)` como primer intento |
| FIX-03 | `_spawn_meteor_impact()` | Añadir `VFXManager.spawn_aoe("meteor_impact", ...)` como primer intento |
| FIX-04 | `_spawn_aoe_warning()` | Añadir `VFXManager.spawn_circle_warning(...)` como primer intento |
| FIX-05 | `_spawn_curse_aura_visual()` | Añadir `VFXManager.spawn_aura("buff_corruption", ...)` como primer intento |
| FIX-06 | `_spawn_elite_nova_visual()` | Añadir `VFXManager.spawn_aoe("arcane_nova", ...)` — ya mapeado |
| FIX-07 | `_spawn_elite_summon_visual()` | Añadir `VFXManager.spawn_boss_vfx("summon_circle", ...)` |
| FIX-08 | `_boss_reality_tear()` | Añadir `VFXManager.spawn_boss_vfx("reality_tear", ...)` |
| FIX-09 | EnemyBase aura élite | Cambiar a `VFXManager.spawn_elite_aura(self)` con spritesheet animado |

---

## E.3 — P1: Assets Faltantes para Boss/Elite

### E-01: `vfx_elite_dash_trail_spritesheet.png`
- **Carpeta**: `assets/vfx/abilities/aoe/elite/`
- **Specs**: 512×128 px, 4×2 grid (frame 128×64), one-shot, alpha bg
- **Estilo**: Cartoon/funko pop top-down, afterimage trail azulado-blanco
- **Integración**: `_spawn_elite_dash_visual_start()`, z_index=50, dur=0.3s
- **Prompt IA**:

```
TOP-DOWN 2D game spritesheet, 4 columns x 2 rows animation grid, 512x128 pixels total.
A cartoon "speed dash" motion trail effect: blue-white energy streaks and afterimages
showing fast horizontal movement. Frame 1: initial charge with compressed energy rings.
Frame 2-4: elongated motion lines with fading afterimages. Frame 5-7: dissipating streaks.
Frame 8: faint wisps fading out. Transparent background (alpha channel).
Funko Pop / chibi game art style, top-down perspective, bright saturated colors.
Pixel art friendly, clean edges, no anti-aliasing artifacts.
DO NOT INCLUDE TEXT. DO NOT INCLUDE WATERMARKS.
Filename: vfx_elite_dash_trail_spritesheet.png
```

### E-02: `vfx_boss_teleport_spritesheet.png`
- **Carpeta**: `assets/vfx/abilities/boss_specific/conjurador/`
- **Specs**: 768×384 px, 4×2 grid (frame 192×192), one-shot, alpha bg
- **Estilo**: Arcane portal / shimmer effect, morado con partículas arcanas
- **Integración**: `_spawn_teleport_effect()`, z_index=50, dur=0.5s
- **Prompt IA**:

```
TOP-DOWN 2D game spritesheet, 4 columns x 2 rows animation grid, 768x384 pixels total.
An arcane teleportation portal effect for a wizard boss character. Frame 1: small purple
energy spiral forming. Frame 2-3: expanding arcane circle with glowing runes. Frame 4:
full portal flash with bright center. Frame 5-6: character materializing with arcane
particles. Frame 7-8: energy dissipating into sparkles. Transparent background.
Dark purple (#6B21A8) and violet (#8B5CF6) with bright magenta core (#E879F9).
Funko Pop / cartoon game art style, top-down perspective.
DO NOT INCLUDE TEXT. DO NOT INCLUDE WATERMARKS.
Filename: vfx_boss_teleport_spritesheet.png
```

### E-03: `vfx_boss_counter_stance_spritesheet.png`
- **Carpeta**: `assets/vfx/abilities/boss_specific/guardian_runas/`
- **Specs**: 768×384 px, 4×2 grid (frame 192×192), loop, alpha bg
- **Estilo**: Shield rúnico brillante, naranja-dorado
- **Integración**: `_spawn_counter_stance_visual()`, z_index=50, dur=loop
- **Prompt IA**:

```
TOP-DOWN 2D game spritesheet, 4 columns x 2 rows LOOPING animation grid, 768x384 pixels total.
A mystical "counter stance" defensive shield aura for a rune guardian boss. Frame 1-8:
Glowing hexagonal runic barrier rotating slowly around a central point, with pulsing
golden-orange runes (#F59E0B, #D97706) floating at the edges. Subtle energy ripples
emanating outward. The animation should loop seamlessly (frame 8 transitions to frame 1).
Transparent background. Funko Pop / cartoon game art style, top-down perspective.
DO NOT INCLUDE TEXT. DO NOT INCLUDE WATERMARKS.
Filename: vfx_boss_counter_stance_spritesheet.png
```

### E-04: `vfx_boss_melee_impact_spritesheet.png`
- **Carpeta**: `assets/vfx/abilities/aoe/boss/`
- **Specs**: 512×256 px, 4×2 grid (frame 128×128), one-shot, alpha bg
- **Estilo**: Heavy slash/impact, ondas de choque
- **Integración**: `_spawn_boss_impact_effect()`, z_index=50, dur=0.3s
- **Prompt IA**:

```
TOP-DOWN 2D game spritesheet, 4 columns x 2 rows animation grid, 512x256 pixels total.
A powerful melee boss impact shockwave effect. Frame 1: initial impact star burst
with white flash. Frame 2-3: expanding shockwave ring with debris particles.
Frame 4-5: secondary ring with energy crackles. Frame 6-7: dissipating particles.
Frame 8: fading dust cloud. White and warm yellow (#FCD34D) with orange (#F97316)
accents. Transparent background. Funko Pop / cartoon game art style, top-down view.
DO NOT INCLUDE TEXT. DO NOT INCLUDE WATERMARKS.
Filename: vfx_boss_melee_impact_spritesheet.png
```

### E-05: `vfx_orb_impact_spritesheet.png`
- **Carpeta**: `assets/vfx/abilities/aoe/void/`
- **Specs**: 512×256 px, 4×2 grid (frame 128×128), one-shot, alpha bg
- **Estilo**: Void orb detonación, morado oscuro
- **Integración**: `_spawn_orb_impact_effect()`, z_index=50, dur=0.3s
- **Prompt IA**:

```
TOP-DOWN 2D game spritesheet, 4 columns x 2 rows animation grid, 512x256 pixels total.
A dark void orb explosion impact. Frame 1: small implosion with dark core.
Frame 2-3: reverse explosion with dark purple tendrils reaching outward.
Frame 4-5: void energy ring expanding with black particles. Frame 6-7: tendrils
retracting. Frame 8: fading dark smoke. Deep purple (#581C87) and black with
bright violet (#A855F7) edge highlights. Transparent background.
Funko Pop / cartoon game art style, top-down perspective.
DO NOT INCLUDE TEXT. DO NOT INCLUDE WATERMARKS.
Filename: vfx_orb_impact_spritesheet.png
```

---

## E.4 — P2: Assets Faltantes para Player

### E-06: `vfx_player_thorns_spritesheet.png`
- **Carpeta**: `assets/vfx/abilities/player/thorns/`
- **Specs**: 512×256 px, 4×2 grid (frame 128×128), one-shot, alpha bg
- **Integración**: `BasePlayer.gd` dentro de lógica de thorns, z_index=60, dur=0.3s
- **Prompt IA**:

```
TOP-DOWN 2D game spritesheet, 4 columns x 2 rows animation grid, 512x256 pixels total.
A thorn/spike damage reflection effect around a character. Frame 1: sharp spikes emerging
from the character's outline. Frame 2-3: spikes extending outward with green energy.
Frame 4: full spike ring with bright flash. Frame 5-7: spikes retracting with fading
green particles. Frame 8: last wisps disappearing. Green (#22C55E) and dark green (#15803D)
with bright yellow (#FDE047) flash on impact. Transparent background.
Funko Pop / cartoon game art style, top-down perspective.
DO NOT INCLUDE TEXT. DO NOT INCLUDE WATERMARKS.
Filename: vfx_player_thorns_spritesheet.png
```

### E-07: `vfx_player_shield_aura_spritesheet.png`
- **Carpeta**: `assets/vfx/abilities/player/shield/`
- **Specs**: 768×256 px, 6×2 grid (frame 128×128), loop, alpha bg
- **Integración**: `BasePlayer.gd` cuando shield_amount > 0, z_index=60, loop
- **Prompt IA**:

```
TOP-DOWN 2D game spritesheet, 6 columns x 2 rows LOOPING animation grid, 768x256 pixels total.
A magical shield bubble aura surrounding a character, viewed from top-down. Frame 1-12:
Semi-transparent blue (#3B82F6) crystalline barrier gently pulsing and rotating.
Subtle hexagonal facets visible on the surface. Small sparkle particles floating along
the edges. The animation loops seamlessly (frame 12 connects to frame 1).
Transparent background. Funko Pop / cartoon game art style, top-down perspective.
DO NOT INCLUDE TEXT. DO NOT INCLUDE WATERMARKS.
Filename: vfx_player_shield_aura_spritesheet.png
```

### E-08: `vfx_player_stun_spritesheet.png`
- **Carpeta**: `assets/vfx/abilities/player/debuffs/`
- **Specs**: 768×256 px, 6×2 grid (frame 128×128), loop, alpha bg
- **Integración**: `BasePlayer.apply_stun()`, z_index=70, loop durante stun
- **Prompt IA**:

```
TOP-DOWN 2D game spritesheet, 6 columns x 2 rows LOOPING animation grid, 768x256 pixels total.
Cartoon "stunned" status effect: yellow stars and small birds orbiting in a circle
above a character's head position (top-down view, so the circle is seen from above).
Frame 1-12: 3-4 bright yellow (#FBBF24) cartoon stars rotating clockwise with trailing
sparkle particles. The stars wobble slightly. Loop seamless (frame 12 → frame 1).
Transparent background. Funko Pop / chibi game art style, top-down perspective.
DO NOT INCLUDE TEXT. DO NOT INCLUDE WATERMARKS.
Filename: vfx_player_stun_spritesheet.png
```

### E-09: `vfx_player_slow_spritesheet.png`
- **Carpeta**: `assets/vfx/abilities/player/debuffs/`
- **Specs**: 768×256 px, 6×2 grid (frame 128×128), loop, alpha bg
- **Integración**: `BasePlayer.apply_slow()`, z_index=-1, loop durante slow
- **Prompt IA**:

```
TOP-DOWN 2D game spritesheet, 6 columns x 2 rows LOOPING animation grid, 768x256 pixels total.
An ice/frost slow debuff effect beneath a character (top-down view). Frame 1-12:
Ice crystals and frost patches spreading and pulsing on the ground around the
character's feet. Light blue (#93C5FD) and white icy particles with subtle shimmer.
Frost creeping outward then retracting slightly in a breathing pattern.
Loop seamless. Transparent background.
Funko Pop / cartoon game art style, top-down perspective.
DO NOT INCLUDE TEXT. DO NOT INCLUDE WATERMARKS.
Filename: vfx_player_slow_spritesheet.png
```

---

## E.5 — P3: Nice-to-Have

### E-10: `vfx_melee_slash_spritesheet.png`
- **Carpeta**: `assets/vfx/abilities/aoe/elite/`
- **Specs**: 512×256 px, 4×2 grid (frame 128×128), one-shot
- **Prompt IA**:

```
TOP-DOWN 2D game spritesheet, 4 columns x 2 rows animation grid, 512x256 pixels total.
A melee slash arc attack effect seen from top-down. Frame 1: thin blade trail starting.
Frame 2-3: wide crescent arc slash with speed lines. Frame 4: full arc with bright
white flash at the tip. Frame 5-7: arc fading with energy dissipation.
Frame 8: faint ghost trail. White and light gray with red (#EF4444) edge glow.
Transparent background. Cartoon game art style, top-down.
DO NOT INCLUDE TEXT. DO NOT INCLUDE WATERMARKS.
Filename: vfx_melee_slash_spritesheet.png
```

### E-11: `projectile_lightning_spritesheet.png`
- **Carpeta**: `assets/vfx/abilities/projectiles/lightning/`
- **Specs**: 256×128 px, 4×2 grid (frame 64×64), loop
- **Prompt IA**:

```
TOP-DOWN 2D game spritesheet, 4 columns x 2 rows LOOPING animation grid, 256x128 pixels total.
A small lightning bolt projectile orb flying through the air (top-down view). Frame 1-8:
Bright electric yellow-white orb with crackling lightning arcs. Small electrical sparks
jumping around the orb. The arcs shift position each frame for a flickering effect.
Loop seamless. Electric blue (#60A5FA) and bright yellow (#FBBF24) with white (#FFFFFF)
core. Transparent background. Cartoon pixel art style, ~64x64 per frame.
DO NOT INCLUDE TEXT. DO NOT INCLUDE WATERMARKS.
Filename: projectile_lightning_spritesheet.png
```

---

# F) IMPLEMENTACIÓN Y VALIDACIÓN

## F.1 — Plan por Fases

### Fase 1: Fixes de hooks (sin crear assets nuevos)
**Tiempo estimado: 1-2 horas**

| # | Archivo | Cambio | Impacto |
|---|---------|--------|---------|
| 1 | `EnemyAttackSystem.gd` | Hook VFXManager en `_spawn_breath_visual()` | flame_breath sprite activado |
| 2 | `EnemyAttackSystem.gd` | Hook VFXManager en `_spawn_void_beam_visual()` | void_beam sprite activado |
| 3 | `EnemyAttackSystem.gd` | Hook VFXManager en `_spawn_meteor_impact()` | meteor_impact sprite activado |
| 4 | `EnemyAttackSystem.gd` | Hook VFXManager en `_spawn_aoe_warning()` | circle_warning sprite activado |
| 5 | `EnemyAttackSystem.gd` | Hook VFXManager en `_spawn_curse_aura_visual()` | curse aura sprite activado |
| 6 | `EnemyAttackSystem.gd` | Hook VFXManager en `_spawn_elite_nova_visual()` | elite nova usa aoe:arcane_nova |
| 7 | `EnemyAttackSystem.gd` | Hook VFXManager en `_spawn_elite_summon_visual()` | elite summon usa boss:summon_circle |
| 8 | `EnemyAttackSystem.gd` | Hook VFXManager en `_boss_reality_tear()` | reality_tear sprite activado |
| 9 | `EnemyBase.gd` | Cambiar aura élite a VFXManager.spawn_elite_aura() | AnimatedSprite2D en vez de estática |

> **Nota**: Todos los hooks mantienen el fallback procedural existente (patrón `if VFXManager.method(): return` + fallback)

### Fase 2: Reescalado de spritesheets
**Tiempo estimado: 30 min**

Script Python para reescalar los 21 PNGs con tamaño incorrecto a sus tamaños esperados. No cambia código.

### Fase 3: Reemplazo de placeholders (tras generar assets)
**Tiempo estimado: 2-3 horas**

| # | Asset | Integración |
|---|-------|-------------|
| 1 | `vfx_elite_dash_trail_spritesheet.png` | Registrar en VFXManager, hook en `_spawn_elite_dash_visual_start()` |
| 2 | `vfx_boss_teleport_spritesheet.png` | Registrar en BOSS_CONFIG, hook en `_spawn_teleport_effect()` |
| 3 | `vfx_boss_counter_stance_spritesheet.png` | Registrar en BOSS_CONFIG, hook en `_spawn_counter_stance_visual()` |
| 4 | `vfx_boss_melee_impact_spritesheet.png` | Registrar en AOE_CONFIG, hook en `_spawn_boss_impact_effect()` |
| 5 | `vfx_orb_impact_spritesheet.png` | Registrar en AOE_CONFIG, hook en `_spawn_orb_impact_effect()` |
| 6 | `vfx_player_thorns_spritesheet.png` | Integrar en BasePlayer thorns logic |
| 7 | `vfx_player_shield_aura_spritesheet.png` | Integrar en BasePlayer shield visual |
| 8 | `vfx_player_stun_spritesheet.png` | Integrar en BasePlayer `apply_stun()` |
| 9 | `vfx_player_slow_spritesheet.png` | Integrar en BasePlayer `apply_slow()` |

### Fase 4: Optimización
**Tiempo estimado: 1 hora**

| # | Área | Cambio |
|---|------|--------|
| 1 | EnemyAttackSystem draws | Verificar que fallback procedurales no se ejecutan cuando VFXManager tiene éxito |
| 2 | EnemyProjectile trail | Decidir: arreglar trail (GPUParticles2D trail como player projectiles) o eliminar código muerto |
| 3 | EnemyProjectile dead code | Eliminar funciones `_draw_*_projectile()` procedurales no usadas (L253-L450) |
| 4 | VFXPool extension | Considerar añadir pool para AOE impacts frecuentes de enemigos |

---

## F.2 — VFX Debug Mode (Mínimo)

Propuesta de implementación como toggle en DebugOverlay existente:

```gdscript
# En VFXManager.gd — añadir al final

var DEBUG_VFX := false
var _debug_log: Array[Dictionary] = []

func _log_vfx_spawn(type: String, category: String, position: Vector2, path: String, is_fallback: bool) -> void:
    if not DEBUG_VFX:
        return
    var entry := {
        "time": Time.get_ticks_msec(),
        "type": type,
        "category": category,
        "position": position,
        "asset": path,
        "fallback": is_fallback
    }
    _debug_log.append(entry)
    if _debug_log.size() > 200:
        _debug_log.pop_front()
    print("[VFX] %s:%s → %s %s" % [category, type, path.get_file(), "(FALLBACK)" if is_fallback else ""])
```

**Activación**: Tecla F9 en DebugOverlay, o variable en settings.

---

## F.3 — Checklist QA Manual

### 10 Habilidades Representativas

| # | Habilidad | Qué verificar | Cómo provocar |
|---|-----------|----------------|----------------|
| 1 | **Elite Slam** | AOE impacto animado en suelo, escala correcta | Encontrar élite, dejar que ataque |
| 2 | **Elite Rage Aura** | Aura animada alrededor del élite (no estática) | Élite entra en rage |
| 3 | **Boss Flame Breath** | Cono de fuego con spritesheet (no polígono plano) | Minotauro fase 2 |
| 4 | **Boss Void Beam** | Línea de vacío con spritesheet (no rectángulo plano) | Corazón del Vacío |
| 5 | **Boss Meteor** | Warning con spritesheet + impacto con spritesheet | Minotauro fase 2, esperar meteoros |
| 6 | **Boss Summon Circle** | Círculo de invocación animado | Conjurador invocando |
| 7 | **Ranged Projectile (fire)** | Proyectil con sprite de fuego, impacto con sprite | Mago de fuego dispara |
| 8 | **Player Hit Effect** | Partículas CPUParticles al golpear enemigo | Atacar cualquier enemigo |
| 9 | **Player Burn DoT** | Partículas de fuego + ticks de daño visibles | Recibir ataque de fuego |
| 10 | **Telegraph Circle Warning** | Círculo rojo animado antes de AOE boss | Boss lanza AOE aleatorio |

### Verificaciones por efecto:
- [ ] Telegraph/warning: ¿Visible antes del daño? ¿Escala coincide con hitbox?
- [ ] Cast/travel: ¿Animación fluida? ¿Dirección correcta?
- [ ] Impact: ¿Se muestra en la posición correcta? ¿Duración apropiada?
- [ ] Persistent: ¿Loopea correctamente? ¿Se limpia al expirar?
- [ ] Layer/z_index: ¿Debajo del personaje (-1) o encima (50/55)?
- [ ] Performance: ¿FPS estable con 5+ élites en pantalla?
- [ ] Escala: ¿El VFX coincide con el radio real del daño?

---

# RESUMEN EJECUTIVO

## Conteo de Issues

| Severidad | Cantidad | Descripción |
|-----------|----------|-------------|
| **P0 — Crítico** | 5 | 3 hooks de beam/aoe faltantes + 1 telegraph no usado + 21 spritesheets mal dimensionados |
| **P1 — Importante** | 9 | 4 hooks de elite/boss faltantes + 5 assets por generar (boss/elite) |
| **P2 — Moderado** | 4 | 4 assets player por generar (thorns, shield, stun, slow) |
| **P3 — Bajo** | 3 | Melee slash, lightning projectile, enemy trail fix |

## Archivos a Modificar

| Archivo | Cambios Previstos |
|---------|------------------|
| `EnemyAttackSystem.gd` | 8 hooks VFXManager nuevos (Fase 1) |
| `EnemyBase.gd` | 1 cambio aura élite (Fase 1) |
| `VFXManager.gd` | Registrar 5-7 nuevos configs (Fase 3) |
| `BasePlayer.gd` | 4 integraciones VFX player (Fase 3) |
| 21 archivos PNG | Reescalado (Fase 2) |

## VFX Huérfanos — Propuesta

| Asset | Propuesta |
|-------|-----------|
| `fire_zone` | **REUSAR** para `_spawn_damage_zone()` fire variant |
| `meteor_impact` | **ACTIVAR** hook en `_spawn_meteor_impact()` (FIX-03) |
| `void_homing` | **REUSAR** como visual alternativo de homing orb, o **ELIMINAR** |
| `buff_corruption` | **ACTIVAR** hook en `_boss_curse_aura()` (FIX-05) |
| `damage_void` | **REUSAR** para boss void aura damage zone |
| `elite_floor` | **ACTIVAR** en EnemyBase elite aura (FIX-09) |
| `elite_rare` | **REUSAR** para variante rara de élite aura |
| `flame_breath` | **ACTIVAR** hook en `_spawn_breath_visual()` (FIX-01) |
| `void_beam` | **ACTIVAR** hook en `_spawn_void_beam_visual()` (FIX-02) |
| `circle_warning` | **ACTIVAR** hook en `_spawn_aoe_warning()` (FIX-04) |
| `reality_tear` | **ACTIVAR** hook en `_boss_reality_tear()` (FIX-08) |

**11 de 11 huérfanos pueden activarse o reusarse** — no se recomienda eliminar ninguno.
