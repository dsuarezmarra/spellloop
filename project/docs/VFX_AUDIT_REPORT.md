# 🎨 VFX Audit Report - Spellloop

**Fecha:** 5 de Febrero 2026  
**Estado:** ⚠️ REQUIERE ATENCIÓN

---

## 📊 Resumen Ejecutivo

Los **28 spritesheets VFX** fueron procesados correctamente, pero **NINGUNO está siendo usado en el juego**. El código actual usa:
- **Dibujo procedural** (draw_line, draw_circle, draw_arc)
- **Assets faltantes** que causan errores silenciosos
- **Un único asset estático** para élites

---

## 🔴 Problemas Críticos

### 1. Assets Referenciados que NO EXISTEN

| Archivo Referenciado | Usado En | Estado |
|---------------------|----------|--------|
| `res://assets/vfx/explosion_magic_sheet.png` | VFX_AOE_Impact.gd | ❌ NO EXISTE |
| `res://assets/vfx/circle_warning_rune.png` | WarningIndicator.gd | ❌ NO EXISTE |
| `res://assets/sprites/projectiles/enemy_projectiles.png` | EnemyProjectile.gd | ❌ NO EXISTE |
| `res://assets/sprites/vfx/explosion_impact.png` | Varios scripts | ❌ NO EXISTE |

**Impacto:** Los efectos AOE, warnings y proyectiles enemigos no muestran visuales (fallback a `queue_free()` silencioso).

### 2. Spritesheets Procesados NO Enganchados

Todos los siguientes spritesheets están en disco pero no se referencian en código:

#### Projectiles (6 archivos) - `assets/vfx/abilities/projectiles/`
- `projectile_fire_spritesheet.png` (256×128, 4×2 grid)
- `projectile_ice_spritesheet.png`
- `projectile_arcane_spritesheet.png`
- `projectile_void_spritesheet.png`
- `projectile_void_homing_spritesheet.png`
- `projectile_poison_spritesheet.png`

#### AOE (8 archivos) - `assets/vfx/abilities/aoe/`
- `aoe_fire_stomp_spritesheet.png` (512×256, 4×2 grid)
- `aoe_fire_zone_spritesheet.png` (1024×512, 4×2 grid)
- `aoe_meteor_impact_spritesheet.png` (1024×512)
- `aoe_arcane_nova_spritesheet.png` (512×256)
- `aoe_freeze_zone_spritesheet.png` (1024×512)
- `aoe_void_explosion_spritesheet.png` (512×256)
- `aoe_ground_slam_spritesheet.png` (512×256)
- `aoe_rune_blast_spritesheet.png` (512×256)

#### Auras (4 archivos) - `assets/vfx/abilities/auras/`
- `aura_buff_corruption_spritesheet.png` (768×256, 6×2 grid)
- `aura_damage_void_spritesheet.png`
- `aura_elite_floor_spritesheet.png`
- `aura_enrage_spritesheet.png`

#### Beams (2 archivos) - `assets/vfx/abilities/beams/`
- `beam_flame_breath_spritesheet.png` (1152×128, 6×2 grid)
- `beam_void_beam_spritesheet.png`

#### Telegraphs (4 archivos) - `assets/vfx/abilities/telegraphs/`
- `telegraph_circle_warning_spritesheet.png` (512×256, 4×2 grid)
- `telegraph_meteor_warning_spritesheet.png`
- `telegraph_charge_line_spritesheet.png`
- `telegraph_rune_prison_spritesheet.png`

#### Boss Specific (4 archivos) - `assets/vfx/abilities/boss_specific/`
- `boss_summon_circle_spritesheet.png` (768×384, 4×2 grid)
- `boss_reality_tear_spritesheet.png`
- `boss_void_pull_spritesheet.png`
- `boss_rune_shield_spritesheet.png`

---

## 🟡 Problemas de Lógica Detectados

### 3. VFX_AOE_Impact.gd - Fallback Silencioso

```gdscript
# Línea 7-8: Si la textura no existe, simplemente se elimina sin visual
var tex = load("res://assets/vfx/explosion_magic_sheet.png")
if tex:
    # ... setup visual ...
else:
    queue_free()  # ⚠️ FALLBACK SILENCIOSO - sin efecto visual
```

**Impacto:** Ataques AOE ejecutan sin feedback visual.

### 4. WarningIndicator.gd - Asset Faltante

```gdscript
# Línea 31: Intenta cargar textura que no existe
_rune_sprite.texture = load("res://assets/vfx/circle_warning_rune.png")
```

**Impacto:** Los telegraphs de warning no muestran la textura de runa.

### 5. EnemyProjectile.gd - Atlas Inexistente

```gdscript
# Línea 63: Atlas de proyectiles no existe
var tex = load("res://assets/sprites/projectiles/enemy_projectiles.png")
```

**Impacto:** Proyectiles enemigos no tienen visual o usan fallback.

---

## 🟢 Lo que SÍ Funciona

### Sistema de Dibujo Procedural
El código en `EnemyAttackSystem.gd` tiene implementaciones **procedurales completas** para:
- ✅ `_spawn_fire_stomp_visual()` - Ondas de fuego con llamas animadas
- ✅ `_spawn_void_explosion_visual()` - Espirales púrpura con absorción
- ✅ `_spawn_arcane_nova_visual()` - Círculos arcanos expandiéndose
- ✅ `_spawn_void_pull_visual()` - Vórtice de atracción
- ✅ `_spawn_rune_blast_visual()` - Runas brillantes
- ✅ `_spawn_curse_aura_visual()` - Aura oscura pulsante
- ✅ `_spawn_void_beam_visual()` - Rayo canalizado

**Estos efectos procedurales funcionan pero no usan los spritesheets.**

### Asset de Élite
- ✅ `assets/vfx/aura_elite_floor.png` existe y es usado por EnemyBase.gd

---

## 📋 Plan de Integración Recomendado

### Opción A: Reemplazar Código Procedural con Spritesheets

1. **Crear VFXManager autoload** que mapee habilidades a spritesheets
2. **Actualizar `_spawn_*_visual()` functions** para usar AnimatedSprite2D
3. **Crear escenas .tscn reutilizables** para cada tipo de VFX

### Opción B: Mantener Procedural + Usar Spritesheets como Overlay

1. Añadir sprites como **capa adicional** sobre el dibujo procedural
2. Menor impacto en código existente
3. Mejora visual incremental

### Opción C: Crear Assets Faltantes

1. Copiar/renombrar spritesheets procesados a rutas esperadas:
   - `aoe_arcane_nova_spritesheet.png` → `explosion_magic_sheet.png`
   - `telegraph_circle_warning_spritesheet.png` → `circle_warning_rune.png`
   
2. Crear `enemy_projectiles.png` atlas combinando los 6 proyectiles

---

## 🔧 Archivos a Modificar

| Archivo | Cambio Necesario |
|---------|-----------------|
| [VFX_AOE_Impact.gd](../scripts/vfx/VFX_AOE_Impact.gd) | Usar spritesheet correcto + manejo de error |
| [WarningIndicator.gd](../scripts/vfx/WarningIndicator.gd) | Usar telegraph spritesheets |
| [EnemyProjectile.gd](../scripts/enemies/EnemyProjectile.gd) | Usar projectile spritesheets |
| [EnemyAttackSystem.gd](../scripts/enemies/EnemyAttackSystem.gd) | Integrar spritesheets en `_spawn_*_visual()` |
| [EnemyAbility_Aoe.gd](../scripts/enemies/abilities/EnemyAbility_Aoe.gd) | Pasar tipo de VFX al spawner |

---

## 📊 Estadísticas

- **Spritesheets procesados:** 28
- **Spritesheets usados en código:** 0
- **Assets faltantes referenciados:** 4
- **Funciones VFX procedurales:** 15+
- **Habilidades de Boss implementadas:** 25+

---

## ✅ Próximos Pasos Sugeridos

1. [ ] Decidir estrategia de integración (A, B o C)
2. [ ] Crear assets faltantes o actualizar rutas
3. [ ] Implementar VFXManager para manejo centralizado
4. [ ] Actualizar escenas VFX existentes
5. [ ] Testear en juego cada tipo de habilidad

---

*Reporte generado automáticamente por auditoría de código*
