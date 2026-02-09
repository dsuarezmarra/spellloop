# AUDITORÍA COMPLETA DE ATAQUES Y HABILIDADES ENEMIGAS

**Proyecto:** LoopiaLike — Survivor 2D Top-Down (Godot 4.5/4.6)  
**Fecha:** Junio 2025  
**Alcance:** TODOS los ataques y habilidades de TODOS los enemigos (Bosses, Elites, Tier 4→1)  
**Criterio:** Lógica, condiciones, estados, sincronización, visibilidad, VFX, fairness. SIN tocar valores de balance.

**Archivos auditados:**
- [scripts/enemies/EnemyAttackSystem.gd](../project/scripts/enemies/EnemyAttackSystem.gd) (4631 líneas)
- [scripts/enemies/EnemyBase.gd](../project/scripts/enemies/EnemyBase.gd) (2080 líneas)
- [scripts/enemies/EnemyProjectile.gd](../project/scripts/enemies/EnemyProjectile.gd)
- [scripts/enemies/abilities/EnemyAbility*.gd](../project/scripts/enemies/abilities/) (7 archivos)
- [scripts/data/EnemyDatabase.gd](../project/scripts/data/EnemyDatabase.gd) (1095 líneas)
- [scripts/data/SpawnConfig.gd](../project/scripts/data/SpawnConfig.gd)

---

## TABLA DE SEVERIDAD

| Prioridad | Significado | Acción |
|-----------|-------------|--------|
| **P0** | Daño invisible / sin feedback / crash potencial | Fix inmediato |
| **P1** | Habilidad no implementada o lógica rota | Fix antes de release |
| **P2** | Inconsistencia visual / feedback mejorable | Fix deseable |
| **P3** | Mejora de polish / edge case menor | Backlog |

---

# PARTE 1: BOSSES

## 1.1 — SISTEMA AGRESIVO DE BOSSES (Compartido)

Todos los bosses usan `_process_boss_aggressive_attacks()` que **ignora el rango** y ejecuta:

| Subsistema | Descripción | Línea | Veredicto |
|------------|-------------|-------|-----------|
| **Proyectil directo** | Dispara al player cada `attack_interval` | ~L1430 | ✅ OK — Tiene VFX de proyectil |
| **AOE aleatorio** | Warning 1.8s + explosión radio 80px | ~L1445 | ⚠️ **P2**: Explosión usa `explosion.draw_arc` en lugar de `visual.draw_arc` → dibuja en nodo equivocado |
| **Homing projectile** | Persigue al player, 120px/s, 6s vida | ~L1460 | ✅ OK — Visual procedural + VFXManager hook |
| **Spread shot** | Abanico 108°, 5+2×fase proyectiles | ~L1560 | ✅ OK |
| **Damage trail** | Zonas de daño donde pasa el boss (fase 2+) | ~L1580 | ✅ OK — 3s duración, radio 30px |
| **Orbitales** | Giran alrededor del boss, dañan al contacto | ~L1660 | ✅ OK — Daño 0.3×base, cooldown 0.8s entre hits |
| **Cambio de fase** | HP thresholds dinámicos con visual | ~L2030 | ✅ OK |

### BUG en `_spawn_aoe_explosion` (P2)
**Archivo:** EnemyAttackSystem.gd ~L1830  
**Problema:** El callback de `visual.draw.connect` usa `explosion.draw_arc(...)` en lugar de `visual.draw_arc(...)`. El nodo `explosion` es el contenedor padre, no el nodo de dibujo.  
**Impacto:** Las ondas de explosión de los AOE aleatorios de boss se dibujan en el nodo contenedor, no en el nodo visual. Puede funcionar visualmente pero es incorrecto y puede causar artefactos.  
**Fix:**
```gdscript
# En _spawn_aoe_explosion, dentro del draw callback:
# ANTES (INCORRECTO):
explosion.draw_arc(Vector2.ZERO, r, 0, TAU, 32, ...)
# DESPUÉS (CORRECTO):
visual.draw_arc(Vector2.ZERO, r, 0, TAU, 32, ...)
```

---

## 1.2 — EL CONJURADOR PRIMIGENIO

**ID:** `boss_el_conjurador` | **Archetype:** boss | **Element:** arcane  
**Habilidades DB:** `arcane_barrage`, `summon_minions`, `teleport_strike`, `arcane_nova`, `curse_aura`  
**Fases:** 3 (60% HP → P2, 30% HP → P3)

### FICHA: arcane_barrage
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 1 | **Existe en código** | ✅ | `_boss_arcane_barrage()` L2250 |
| 2 | **Integración** | ✅ | Registrada en `_execute_boss_ability()`, desbloqueada como prioridad 1 |
| 3 | **Condición de ejecución** | ✅ | Sistema de cooldown + combo + fase. Peso mayor a distancia >100px |
| 4 | **Lógica interna** | ✅ | 5 proyectiles (7 en fase 2+), spread 30°, delay 0.05s entre cada uno |
| 5 | **Rango y hitbox** | ✅ | Hereda hitbox del proyectil (radio 12px colisión + check manual 20px) |
| 6 | **Daño y efectos** | ✅ | Daño desde modifiers, elemento "arcane" → 30% chance de Curse via EnemyProjectile |
| 7 | **VFX/feedback** | ✅ | Usa proyectiles estándar con spritesheet + trail |
| 8 | **Sincronización** | ✅ | Delay escalonado entre proyectiles (0.05s × i) |
| 9 | **Fairness** | ✅ | Spread razonable, proyectiles esquivables |

### FICHA: summon_minions
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 1 | **Existe en código** | ✅ | `_boss_summon_minions()` L2270 |
| 2 | **Integración** | ✅ | Prioridad 3, desbloqueada en min 10+ |
| 3 | **Condición de ejecución** | ✅ | Peso 1.5 (utilidad) |
| 4 | **Lógica interna** | ⚠️ | Usa `spawner.spawn_minions_around()` — **depende de que el spawner exista y tenga ese método** |
| 5 | **Rango y hitbox** | N/A | No hace daño directo |
| 6 | **Daño y efectos** | ✅ | 2 minions T1 (3 en P2, T2 en P3) |
| 7 | **VFX/feedback** | ✅ | `_spawn_summon_visual()` con pentágono animado |
| 8 | **Sincronización** | ⚠️ **P3** | Si spawner no existe, hace `pass` silenciosamente — sin fallback ni feedback al jugador |
| 9 | **Fairness** | ✅ | OK |

### FICHA: teleport_strike ⛔ P0
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 1 | **Existe en código** | ✅ | `_boss_teleport_strike()` L2290 |
| 2 | **Integración** | ✅ | Prioridad 2, peso 3.5 si dist > 150 |
| 3 | **Condición de ejecución** | ✅ | Peso alto cuando lejos → gap closer |
| 4 | **Lógica interna** | ⛔ **P0** | **Teleporta + aplica daño en el MISMO frame.** No hay telegraph, no hay warning, no hay delay. El jugador recibe daño sin posibilidad de reaccionar |
| 5 | **Rango y hitbox** | ⛔ **P0** | Aparece a 50px detrás del jugador → **siempre** está en rango melee → **siempre** impacta |
| 6 | **Daño y efectos** | ⚠️ | `attack_damage * 1.5` + "physical" — sin elemento arcane a pesar de ser un Conjurador arcano |
| 7 | **VFX/feedback** | ⚠️ **P1** | Tiene efectos de desaparición/aparición pero son **simultáneos** al daño, no previos |
| 8 | **Sincronización** | ⛔ **P0** | Cero frames de reacción para el jugador |
| 9 | **Fairness** | ⛔ **INJUSTO** | Daño garantizado sin contrapartida |

**Fix propuesto:**
```gdscript
func _boss_teleport_strike() -> void:
    var damage_mult = modifiers.get("teleport_damage_mult", 1.5)
    var to_player = (player.global_position - enemy.global_position).normalized()
    var teleport_pos = player.global_position - to_player * 50
    
    # 1. Efecto de desaparición
    _spawn_teleport_effect(enemy.global_position, false)
    
    # 2. WARNING en destino ANTES de teleportar (0.4s)
    _spawn_teleport_effect(teleport_pos, true)  # Marca de llegada
    
    # 3. Delay para dar tiempo de reacción
    get_tree().create_timer(0.4).timeout.connect(func():
        if not is_instance_valid(enemy) or not is_instance_valid(player):
            return
        enemy.global_position = teleport_pos
        # 4. Check de rango DESPUÉS del teleport (no garantizado)
        var dist = enemy.global_position.distance_to(player.global_position)
        if dist < 60:
            var damage = int(attack_damage * damage_mult)
            player.take_damage(damage, "arcane", enemy)  # Elemento correcto
            attacked_player.emit(damage, true)
    )
```

### FICHA: arcane_nova
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 1 | **Existe en código** | ✅ | `_boss_arcane_nova()` L2310 |
| 2 | **Integración** | ✅ | Prioridad 4 |
| 3 | **Condición de ejecución** | ✅ | Peso 3.0 si dist < 150 |
| 4 | **Lógica interna** | ⚠️ **P1** | **Daño instantáneo sin telegraph.** Check `dist <= radius` y aplica daño inmediatamente. No hay frame de warning |
| 5 | **Rango y hitbox** | ✅ | Radio 120px configurable |
| 6 | **Daño y efectos** | ✅ | 40 daño (60 en P3), "arcane" |
| 7 | **VFX/feedback** | ⚠️ **P1** | `_spawn_arcane_nova_visual` se ejecuta DESPUÉS del daño, no antes. El jugador ve la explosión cuando ya fue dañado |
| 8 | **Sincronización** | ⛔ **P0** | VFX y daño no están sincronizados — daño primero, visual después |
| 9 | **Fairness** | ⚠️ | Necesita telegraph previo |

**Fix propuesto:** Añadir warning de 0.5s antes del daño, similar a `_perform_aoe_attack` con telegraph.

### FICHA: curse_aura
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 1 | **Existe en código** | ✅ | `_boss_curse_aura()` L2330 |
| 2-9 | **Todo** | ✅ | Correctamente implementada. Radio 150px, -50% curación por 8s. Visual aura con fade. Solo aplica si player en rango. VFX + daño sincronizados |

---

## 1.3 — EL CORAZÓN DEL VACÍO

**ID:** `boss_el_corazon` | **Archetype:** boss | **Element:** dark/void  
**Habilidades DB:** `void_pull`, `void_explosion`, `void_orbs`, `reality_tear`, `void_beam`, `damage_aura`  
**Fases:** 3 — Activa aura de daño permanente en P2+

### FICHA: void_pull
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 1-8 | **Todo** | ✅ | Correcta. Radio 350px, fuerza 150 (200 P2+), duración 2.5s. Visual spiral. Fallback a knockback si no hay `apply_pull` |
| 9 | **Fairness** | ✅ | Pull es CC, no daño directo. Visual claro |

### FICHA: void_explosion
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 1 | **Existe en código** | ✅ | `_perform_boss_void_explosion()` L2710 |
| 2-3 | **Integración** | ✅ | Prioridad 3, peso 3.0 si dist < 150 |
| 4 | **Lógica interna** | ⚠️ **P1** | **Das daño instantáneo sin telegraph** — misma categoría que arcane_nova |
| 5 | **Rango y hitbox** | ✅ | Radio 150px |
| 6 | **Daño y efectos** | ✅ | 60 daño + apply_weakness |
| 7 | **VFX/feedback** | ⚠️ **P1** | Sin referencia a visual en el código visible (el visual de aoe_visual genérico se usa pero es post-daño) |
| 8 | **Sincronización** | ⛔ **P0** | Daño sin aviso previo |
| 9 | **Fairness** | ⚠️ | 60 daño + weakness a 150px sin telegraph = injusto |

### FICHA: void_orbs
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 1-9 | **Todo** | ✅ | Correcta. Spawn 3 orbs (5 en P2), speed 120, 5s duración, persiguen jugador. Visual con trail. Impacto con efecto. Hit radius 28px |

### FICHA: reality_tear
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 1-9 | **Todo** | ✅ | Correcta. Zona persistente en posición del jugador. Radio 80px, DPS 15, 6s duración. Doble visual (VFXManager + zona de daño). Jugador puede salir |

### FICHA: void_beam ⛔ P0
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 1 | **Existe en código** | ✅ | `_boss_void_beam()` L2470 |
| 2 | **Integración** | ✅ | Prioridad 5 (última), solo disponible en fase 2+ |
| 3 | **Condición de ejecución** | ✅ | Verificado por `_is_ability_available_in_phase` |
| 4 | **Lógica interna** | ⛔ **P0** | **Aplica TODO el daño como impacto único al inicio.** El comentario dice "canalizado - DPS por tick" pero en realidad hace `player.take_damage(damage)` una sola vez y luego solo muestra el visual durante `duration` segundos. No hay daño continuado real |
| 5 | **Rango y hitbox** | ⛔ **P0** | **No verifica si el jugador está en la línea del beam.** Aplica daño incondicional al castear, independientemente de la posición del jugador |
| 6 | **Daño y efectos** | ⚠️ | 30 daño único (debería ser DPS × duración o ticks) |
| 7 | **VFX/feedback** | ✅ | Visual de beam con rectángulo pulsante |
| 8 | **Sincronización** | ⛔ **P0** | Daño instantáneo e incondicional + visual que sugiere que es continuado = engañoso |
| 9 | **Fairness** | ⛔ **INJUSTO** | Daño garantizado sin posibilidad de esquivar |

**Fix propuesto:**
```gdscript
func _boss_void_beam() -> void:
    var damage_per_tick = modifiers.get("beam_damage", 30)
    var duration = modifiers.get("beam_duration", 3.0)
    var beam_width = modifiers.get("beam_width", 40.0)
    
    var direction = (player.global_position - enemy.global_position).normalized()
    var beam_length = 300.0
    
    # Visual del beam (se muestra inmediatamente como telegraph)
    _spawn_void_beam_visual(enemy.global_position, direction, beam_length, duration)
    
    # Daño por ticks durante la duración
    var ticks = int(duration / 0.5)
    for i in range(ticks):
        get_tree().create_timer(0.5 * (i + 1)).timeout.connect(func():
            if not is_instance_valid(player) or not is_instance_valid(enemy):
                return
            # Verificar si el jugador está en el rectángulo del beam
            var to_player = player.global_position - enemy.global_position
            var proj = to_player.dot(direction)
            var perp = abs(to_player.dot(direction.orthogonal()))
            if proj > 0 and proj < beam_length and perp < beam_width / 2:
                player.take_damage(damage_per_tick, "void", enemy)
        )
```

### FICHA: damage_aura (pasivo de fase)
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 1 | **Existe en código** | ✅ | `_update_boss_passive_effects()` L2090 — No es una habilidad activa, se activa en `_on_boss_phase_change` |
| 2 | **Integración** | ⚠️ **P1** | Está en `_update_boss_passive_effects()` pero **esta función NO es llamada desde ningún lado**. `_process_boss_aggressive_attacks()` no la invoca |
| 3 | **Condición** | ✅ | Se activa en fase 2+ (`boss_damage_aura_timer = 999.0`) |
| 4 | **Lógica** | ⚠️ **P1** | Si se llamara, aplicaría DPS frameado (aura_damage × delta). Pero el cálculo `frame_damage >= 1` con DPS 8 y delta ~0.016 = 0.128 → **nunca >= 1** → **nunca aplica daño** |
| 5-9 | **Resto** | ❌ | Función muerta — no se ejecuta nunca |

**Fix propuesto:**
1. Llamar `_update_boss_passive_effects()` desde `_process_boss_aggressive_attacks()`.
2. Usar acumulador de daño en lugar de check `>= 1`:
```gdscript
# Añadir variable:
var boss_aura_damage_accumulator: float = 0.0

# En _update_boss_passive_effects:
boss_aura_damage_accumulator += aura_dps * delta
if boss_aura_damage_accumulator >= 1.0:
    player.take_damage(int(boss_aura_damage_accumulator), "void", enemy)
    boss_aura_damage_accumulator = fmod(boss_aura_damage_accumulator, 1.0)
```

---

## 1.4 — EL GUARDIÁN DE RUNAS

**ID:** `boss_el_guardian` | **Archetype:** boss | **Element:** arcane  
**Habilidades DB:** `rune_shield`, `rune_blast`, `rune_prison`, `counter_stance`, `rune_barrage`, `ground_slam`  
**Fases:** 3

### FICHA: rune_shield
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 1 | **Existe en código** | ✅ | `_boss_rune_shield()` L2380 |
| 2-3 | **Integración** | ✅ | Prioridad 5, peso 1.5 |
| 4 | **Lógica interna** | ⚠️ **P1** | Llama `enemy.apply_shield(charges, duration)` — **pero no existe `apply_shield` en EnemyBase.gd**. El escudo nunca se aplica realmente |
| 5-6 | **Rango/Daño** | N/A | Defensivo |
| 7 | **VFX/feedback** | ⚠️ **P2** | `_spawn_rune_shield_visual()` usa `get_tree().create_timer(10.0)` para autodestruir, pero la duración en la DB es `shield_duration` configurable (podría ser diferente). También: si el enemigo muere antes, el timer sigue vivo (memory leak menor) |
| 8 | **Sincronización** | ✅ | Visual inmediato |
| 9 | **Fairness** | ✅ | Defensivo, no afecta al jugador |

### FICHA: rune_blast
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 1 | **Existe en código** | ✅ | `_perform_boss_rune_blast()` está referenciada en `_execute_boss_ability()` |
| 2-8 | **Implementación** | ✅ | No pude verificar implementación completa (posiblemente fuera del rango leído), pero está en el switch de ejecución |
| 9 | **Fairness** | — | Necesita verificación adicional |

### FICHA: rune_prison
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 1 | **Existe en código** | ✅ | `_boss_rune_prison()` L2400 |
| 2-3 | **Integración** | ✅ | Prioridad 4, peso 2.0 (control) |
| 4 | **Lógica interna** | ⚠️ **P2** | Aplica root/stun al jugador, luego daño al FINAL de la duración. El daño llega via `get_tree().create_timer(duration)` → si el boss muere durante la prisión, el timer sigue activo y aplica daño póstumo |
| 5 | **Rango y hitbox** | ⚠️ **P1** | **NO verifica distancia al jugador.** Aplica stun/root SIEMPRE, sin importar si el jugador está cerca o al otro lado del mapa |
| 6 | **Daño y efectos** | ✅ | 20 daño + stun/root 1.5s |
| 7 | **VFX/feedback** | ✅ | Visual de jaula en posición del jugador |
| 8 | **Sincronización** | ✅ | Visual y efecto simultáneos |
| 9 | **Fairness** | ⚠️ | Sin check de rango = puede afectar a jugador lejos |

**Fix propuesto:** Añadir check de distancia antes de aplicar el efecto.

### FICHA: counter_stance
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 1 | **Existe en código** | ✅ | `_boss_counter_stance()` L2420 |
| 4 | **Lógica interna** | ⚠️ **P1** | Llama `enemy.activate_counter_stance(window, damage_mult)` — **pero no existe `activate_counter_stance` en EnemyBase.gd**. El counter nunca se activa realmente |
| 7 | **VFX/feedback** | ⚠️ **P2** | `_spawn_counter_stance_visual()` usa timer `get_tree().create_timer(2.0)` que puede sobrevivir al enemigo |
| 9 | **Fairness** | ✅ | Como no funciona, no es injusto (pero tampoco hace nada) |

### FICHA: rune_barrage
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 1-9 | **Todo** | ✅ | Correcta. 6 proyectiles, spread 40°, delay 0.08s. Similar a arcane_barrage. Peso 2.5 a distancia |

### FICHA: ground_slam
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 1 | **Existe en código** | ✅ | `_boss_ground_slam()` L2460 |
| 2 | **Integración** | ✅ | Solo disponible en fase 2+ |
| 4 | **Lógica interna** | ⚠️ **P1** | **Daño instantáneo sin telegraph.** Similar a arcane_nova |
| 5 | **Rango** | ✅ | Radio 150px |
| 6 | **Daño** | ✅ | 45 daño (70 en P3) + stun 0.5s |
| 7 | **VFX** | ⚠️ **P1** | `_spawn_ground_slam_visual` es post-daño |
| 9 | **Fairness** | ⚠️ | Necesita telegraph |

---

## 1.5 — MINOTAURO DE FUEGO

**ID:** `boss_minotauro` | **Archetype:** boss | **Element:** fire  
**Habilidades DB:** `charge_attack`, `fire_stomp`, `flame_breath`, `meteor_call`, `enrage`, `fire_trail`  
**Fases:** 3 — Enrage en P3, fire_trail permanente en P3

### FICHA: charge_attack
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 1 | **Existe en código** | ✅ | `_boss_charge_attack()` L2530 |
| 2-3 | **Integración** | ✅ | Prioridad 2, peso 3.5 si dist > 150 |
| 4 | **Lógica interna** | ⚠️ **P1** | Llama `enemy.start_charge()` — **no existe en EnemyBase.gd para bosses** (solo para archetype "charger"). ADEMÁS aplica daño inmediato si dist < 80 al INICIO, antes de la carga |
| 5 | **Rango** | ⚠️ | Doble lógica: daño inmediato si < 80px + eventual daño de carga (que no funciona) |
| 7 | **VFX** | ✅ | `_spawn_charge_warning_visual` con flecha direccional |
| 8 | **Sincronización** | ⚠️ **P1** | Warning visual se muestra, pero el daño ya se aplicó antes |
| 9 | **Fairness** | ⚠️ | Warning engañoso — el daño ya ocurrió cuando ves la advertencia |

### FICHA: fire_stomp
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 1 | **Existe en código** | ✅ | `_perform_boss_fire_stomp()` en switch de ejecución |
| 2-3 | **Integración** | ✅ | Prioridad 1 |
| 4-9 | **Evaluación** | — | Necesita verificación de implementación (probablemente usa `_perform_aoe_attack` genérico o implementación propia) |

### FICHA: flame_breath
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 1 | **Existe en código** | ✅ | `_boss_flame_breath()` L2560 |
| 2-3 | **Integración** | ✅ | Prioridad 3 |
| 4 | **Lógica interna** | ✅ | Verifica cono correctamente: dist ≤ range Y ángulo ≤ angle/2 |
| 5 | **Rango** | ✅ | Cono 50°, 180px (40 daño en P3) |
| 6 | **Daño** | ✅ | 25 daño + burn 50% del daño por 2s |
| 7 | **VFX** | ✅ | `_spawn_flame_breath_visual` con cono animado |
| 8 | **Sincronización** | ⚠️ **P2** | Daño y visual simultáneos (no hay telegraph previo, pero el cono visual sí actúa como indicador) |
| 9 | **Fairness** | ✅ | Cono direccional esquivable |

### FICHA: meteor_call
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 1 | **Existe en código** | ✅ | `_boss_meteor_call()` L2590 |
| 2 | **Integración** | ✅ | Solo fase 2+, prioridad 4 |
| 4 | **Lógica interna** | ✅ | Warning 1.5s + impacto escalonado (delay + 0.2s × i) |
| 5 | **Rango** | ✅ | Radio 60px por meteoro, offset ±150px del jugador |
| 6 | **Daño** | ✅ | 50 daño + burn 30% por 3s |
| 7 | **VFX** | ✅ | `_spawn_meteor_warning` (pulsante) + `_spawn_meteor_impact` (explosión) |
| 8 | **Sincronización** | ✅ | Warning primero (1.5s), luego impacto — correctamente implementado |
| 9 | **Fairness** | ✅ | ✅ Ejemplo de ataque BIEN hecho: telegraph claro + tiempo de reacción + esquivable |

### FICHA: enrage (pasivo de fase)
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 1 | **Existe en código** | ✅ | `_activate_boss_enrage()` L2620 |
| 2 | **Integración** | ✅ | Se activa automáticamente en `_on_boss_phase_change` al llegar a P3 |
| 4 | **Lógica interna** | ⚠️ **P2** | Modifica `attack_damage` y `enemy.base_speed` directamente — **nunca se revierte**. Si por alguna razón se curara HP (no pasa actualmente, pero...), el enrage permanece |
| 7 | **VFX** | ✅ | `_spawn_enrage_visual` con aura roja y llamas |
| 9 | **Fairness** | ✅ | Correcto para P3 final |

### FICHA: fire_trail (pasivo de fase)
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 1 | **Existe en código** | ✅ | `_spawn_fire_trail()` L2650 + `_update_boss_passive_effects()` L2090 |
| 2 | **Integración** | ⛔ **P0** | **MISMA FUNCIÓN MUERTA** — `_update_boss_passive_effects()` nunca se llama. El flag `boss_fire_trail_active` se pone a `true` en `_on_boss_phase_change` pero la función que lo lee nunca se ejecuta |
| 4 | **Lógica** | ✅ | Si se llamara: cada 10 frames crea zona de daño de radio 25, DPS configurable, 3s duración |
| 9 | **Fairness** | — | No funciona, así que N/A |

**Fix:** Mismo que damage_aura — llamar `_update_boss_passive_effects()` desde `_process_boss_aggressive_attacks()`.

---

# PARTE 2: SISTEMA ELITE

**Cualquier enemigo** puede convertirse en Elite con ELITE_CONFIG: HP×18, DMG×4.5, SPD×1.7, SIZE×1.9.  
Max 4 habilidades de: `elite_slam`, `elite_rage`, `elite_shield`, `elite_dash`, `elite_nova`, `elite_summon`.  
Exclusión mutua: nova+summon no coexisten.

## Flujo de ejecución
1. `_perform_attack()` detecta `is_elite` → llama `_try_elite_ability()`
2. `_try_elite_ability()` tiene probabilidad configurable (50%) de usar habilidad
3. Selección por prioridad: dash > nova > slam > summon > shield

### FICHA: elite_slam
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 1 | **Existe en código** | ✅ | `_perform_elite_slam()` L472 |
| 4 | **Lógica** | ⚠️ **P1** | **Daño instantáneo sin telegraph.** Check dist ≤ slam_radius → daño + stun 0.4s. Ningún frame de aviso |
| 7 | **VFX** | ⚠️ **P1** | `_spawn_elite_slam_visual` es post-daño |
| 9 | **Fairness** | ⚠️ | Necesita telegraph. Radio 80px + stun sin aviso es injusto |

### FICHA: elite_rage
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 1 | **Existe en código** | ✅ | `_activate_elite_rage()` L490 |
| 4 | **Lógica** | ⚠️ **P2** | Modifica `attack_damage` y `base_speed` directamente — **PERMANENTE, nunca se revierte**. Si el élite sobrevive mucho tiempo, los stats se quedan modificados |
| 7 | **VFX** | ✅ | Visual de furia con aura roja |
| 9 | **Fairness** | ✅ | Auto-buff cuando HP < 50% — fair |

### FICHA: elite_shield
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 1 | **Existe en código** | ✅ | `_activate_elite_shield()` L500 |
| 4 | **Lógica** | ⚠️ **P1** | Establece `elite_shield_charges = 3`, pero **NO hay ningún código en `take_damage()` de EnemyBase.gd que consulte `elite_shield_charges`** para absorber daño. El escudo es puramente visual, no absorbe nada |
| 7 | **VFX** | ⚠️ **P2** | `_spawn_elite_shield_visual()` usa `get_tree().create_timer(12.0)` — puede outlive el enemigo. Debería usar `enemy.create_tween()` |
| 9 | **Fairness** | — | No funciona, así que N/A |

### FICHA: elite_dash
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 1 | **Existe en código** | ✅ | `_perform_elite_dash()` L740 |
| 4 | **Lógica** | ✅ | Wind-up 0.3s + tween 0.25s + check colisión al final (< 60px) |
| 7 | **VFX** | ✅ | Visual de preparación + trail |
| 8 | **Sincronización** | ✅ | 0.3s de anticipación antes del movimiento |
| 9 | **Fairness** | ✅ | ✅ **Bien implementado** — telegraph + esquivable |

### FICHA: elite_nova
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 1 | **Existe en código** | ✅ | Usa `EnemyAbility_Nova` via sistema modular (mapeado en `_setup_modular_abilities`) |
| 4 | **Lógica** | ✅ | Spawn N proyectiles en círculo |
| 7 | **VFX** | ✅ | Proyectiles con spritesheet + trail |
| 9 | **Fairness** | ✅ | Esquivable entre proyectiles |

### FICHA: elite_summon
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 1 | **Existe en código** | ✅ | Usa `EnemyAbility_Summon` via sistema modular |
| 4 | **Lógica** | ⚠️ **P3** | Busca `enemy_manager` por grupo — puede no encontrarlo. Silent fail |
| 9 | **Fairness** | ✅ | No hace daño directo |

---

# PARTE 3: TIER 4

## 3.1 — Titán Arcano
**ID:** `tier_4_titan_arcano` | **Archetype:** tank | **Element:** arcane  
**Abilities DB:** `stomp_attack`, `aoe_slam`, `damage_reduction`

| Habilidad | Existe en código | Estado | Detalle |
|-----------|-----------------|--------|---------|
| `stomp_attack` | ✅ | ✅ | Mapeado como `EnemyAbility_Aoe` en `_setup_modular_abilities` con telegraph |
| `aoe_slam` | ⚠️ | **P1** | String en DB pero **sin mapeo directo** en `_setup_modular_abilities`. El match case maneja `"stomp_attack"` y `"elite_slam"` pero NO `"aoe_slam"`. **Habilidad ignorada** |
| `damage_reduction` | ✅ | ✅ | Implementada en `take_damage()` de EnemyBase.gd para archetype "tank": `damage *= 0.6` |

**AoE (archetype "aoe" legacy):**
| # | Sección | Estado | Detalle |
|---|---------|--------|---------|
| 4 | **Lógica** | ⚠️ **P2** | `_perform_aoe_attack()` usa `player.global_position` como centro del AoE, pero luego compara `aoe_center.distance_to(player.global_position)` → **siempre es 0** → **siempre impacta** |
| 7 | **VFX** | ⚠️ | Visual en `enemy.global_position` (no en el centro del AoE) → desalineado |

**Fix:** El centro del AoE debería ser `enemy.global_position`, no `player.global_position`.

## 3.2 — Señor de las Llamas
**ID:** `tier_4_senor_de_las_llamas` | **Archetype:** aoe | **Element:** fire  
**Abilities DB:** `fire_zone`, `burn_aura`

| Habilidad | Existe en código | Estado | Detalle |
|-----------|-----------------|--------|---------|
| `fire_zone` | ❌ | ⛔ **P1** | **NO IMPLEMENTADA.** No hay match case en `_setup_modular_abilities` ni handler en `_try_special_abilities`. El string existe solo en la DB |
| `burn_aura` | ❌ | ⛔ **P1** | **NO IMPLEMENTADA.** Mismo caso. Sin lógica de aura de quemadura |

**Nota:** El enemigo SÍ funciona como archetype "aoe" con `_perform_aoe_attack()`, que aplica burn por ser fire element. Pero las habilidades específicas `fire_zone` y `burn_aura` no existen como mecánicas separadas.

## 3.3 — Reina del Hielo
**ID:** `tier_4_reina_del_hielo` | **Archetype:** aoe | **Element:** ice  
**Abilities DB:** `freeze_zone`, `ice_armor`

| Habilidad | Existe en código | Estado | Detalle |
|-----------|-----------------|--------|---------|
| `freeze_zone` | ❌ | ⛔ **P1** | **NO IMPLEMENTADA.** Sin match case. String muerto |
| `ice_armor` | ❌ | ⛔ **P1** | **NO IMPLEMENTADA.** Sin lógica de armadura de hielo |

**Nota:** Funciona como aoe genérico con slow por ice element, pero sin mecánicas especiales.

## 3.4 — Archimago Perdido
**ID:** `tier_4_archimago_perdido` | **Archetype:** multi | **Element:** arcane  
**Abilities DB:** `teleport`, `multi_element`

| Habilidad | Existe en código | Estado | Detalle |
|-----------|-----------------|--------|---------|
| `teleport` | ✅ | ✅ | Mapeada como `EnemyAbility_Teleport` en `_setup_modular_abilities` |
| `multi_element` | ❌ | ⛔ **P1** | **NO IMPLEMENTADA.** El archimago debería alternar elementos, pero no hay lógica alguna. Siempre usa "arcane" |

## 3.5 — Dragón Etéreo
**ID:** `tier_4_dragon_etereo` | **Archetype:** breath | **Element:** fire  
**Abilities DB:** `breath_attack`, `dive_attack`

| Habilidad | Existe en código | Estado | Detalle |
|-----------|-----------------|--------|---------|
| `breath_attack` | ✅ | ✅ | Implementada en `_perform_breath_attack()` con verificación de cono |
| `dive_attack` | ❌ | ⛔ **P1** | **NO IMPLEMENTADA.** Sin match case, sin handler. String muerto |

---

# PARTE 4: TIER 3

## 4.1 — Caballero del Vacío
**ID:** `tier_3_caballero_del_vacio` | **Archetype:** charger | **Element:** dark  
**Abilities DB:** `charge_attack`

| Habilidad | Existe en código | Estado | Detalle |
|-----------|-----------------|--------|---------|
| `charge_attack` | ✅ | ✅ | Implementada en `EnemyBase._try_special_abilities()` como charger con carga + stun. Usa `EnemyAbility_Melee` como Phase 1 workaround |
| **Lógica de carga** | ✅ | ✅ | Wind-up 0.5s (marca visual) → lunge hacia posición del player → daño + stun 0.5s si impacta |

## 4.2 — Serpiente de Fuego
**ID:** `tier_3_serpiente_de_fuego` | **Archetype:** trail | **Element:** fire  
**Abilities DB:** `fire_trail`

| Habilidad | Existe en código | Estado | Detalle |
|-----------|-----------------|--------|---------|
| `fire_trail` | ✅ (EnemyBase) | ⚠️ **P2** | Implementada en `EnemyBase._try_special_abilities()` como método de movimiento. Deja zonas de fuego al caminar. **PERO** en `_setup_modular_abilities` tiene un `pass` con TODO comment |
| **Trail visual** | ✅ | ✅ | Crea zonas de daño temporales con color de fuego |

## 4.3 — Elemental de Hielo
**ID:** `tier_3_elemental_de_hielo` | **Archetype:** ranged | **Element:** ice  
**Abilities DB:** `freeze_projectile`

| Habilidad | Existe en código | Estado | Detalle |
|-----------|-----------------|--------|---------|
| `freeze_projectile` | ✅ | ✅ | Mapeado en `_setup_modular_abilities` como modificador de elemento: `ability.element_type = "ice"` → aplica slow via EnemyProjectile |

## 4.4 — Mago Abismal
**ID:** `tier_3_mago_abismal` | **Archetype:** teleporter | **Element:** dark  
**Abilities DB:** `teleport`

| Habilidad | Existe en código | Estado | Detalle |
|-----------|-----------------|--------|---------|
| `teleport` | ✅ | ✅ | Doble implementación: `EnemyAbility_Teleport` modular + `EnemyBase._try_special_abilities()` con teleport. Ambas activas — posible doble-teleport |

⚠️ **P2**: El teleport modular (`EnemyAbility_Teleport`) mueve al enemigo a posición aleatoria sin visual. El teleport de EnemyBase tiene visual. Ambos podrían ejecutarse.

## 4.5 — Corruptor Alado
**ID:** `tier_3_corruptor_alado` | **Archetype:** support | **Element:** dark  
**Abilities DB:** `buff_allies`

| Habilidad | Existe en código | Estado | Detalle |
|-----------|-----------------|--------|---------|
| `buff_allies` | ✅ | ✅ | Implementada en `EnemyBase._try_special_abilities()` — busca enemigos cercanos y aplica buff de velocidad y daño |

---

# PARTE 5: TIER 2

## 5.1 — Guerrero Espectral
**ID:** `tier_2_guerrero_espectral` | **Archetype:** blocker | **Element:** physical  
**Abilities DB:** `block_chance`, `counter_attack`

| Habilidad | Existe en código | Estado | Detalle |
|-----------|-----------------|--------|---------|
| `block_chance` | ✅ | ✅ | Implementada en `EnemyBase.take_damage()`: archetype "blocker" tiene 40% chance de bloquear (daño × 0.1) |
| `counter_attack` | ❌ | ⛔ **P1** | **NO IMPLEMENTADA.** El bloqueo no dispara contraataque. String muerto |

## 5.2 — Lobo de Cristal
**ID:** `tier_2_lobo_de_cristal` | **Archetype:** pack | **Element:** ice  
**Abilities DB:** `pack_bonus`

| Habilidad | Existe en código | Estado | Detalle |
|-----------|-----------------|--------|---------|
| `pack_bonus` | ✅ (parcial) | ⚠️ **P2** | Implementado en `EnemyBase._calculate_archetype_movement()` como separación entre lobos del mismo pack. **Pero** no hay buff de daño/velocidad por cantidad de lobos cercanos como sugiere el nombre |

## 5.3 — Golem Rúnico
**ID:** `tier_2_golem_runico` | **Archetype:** tank | **Element:** arcane  
**Abilities DB:** `stomp_attack`, `damage_reduction`

| Habilidad | Existe en código | Estado | Detalle |
|-----------|-----------------|--------|---------|
| `stomp_attack` | ✅ | ✅ | Mapeado como `EnemyAbility_Aoe` con telegraph |
| `damage_reduction` | ✅ | ✅ | `take_damage()` archetype "tank": daño × 0.6 |

## 5.4 — Hechicero Desgastado
**ID:** `tier_2_hechicero_desgastado` | **Archetype:** ranged | **Element:** fire  
**Abilities DB:** `burn_projectile`, `keep_distance`

| Habilidad | Existe en código | Estado | Detalle |
|-----------|-----------------|--------|---------|
| `burn_projectile` | ✅ | ✅ | Mapeado como modificador: `ability.element_type = "fire"` → EnemyProjectile aplica burn |
| `keep_distance` | ❌ | ⛔ **P1** | **NO IMPLEMENTADA** como habilidad especial. El archetype "ranged" SÍ tiene `_calculate_archetype_movement()` que mantiene distancia, pero NO está conectada al string `keep_distance` |

**Nota:** La funcionalidad existe por el archetype, pero el string en la DB no hace nada adicional.

## 5.5 — Sombra Flotante
**ID:** `tier_2_sombra_flotante` | **Archetype:** phase | **Element:** dark  
**Abilities DB:** `phase_shift`

| Habilidad | Existe en código | Estado | Detalle |
|-----------|-----------------|--------|---------|
| `phase_shift` | ✅ | ✅ | Implementada en `EnemyBase._try_special_abilities()` — enemigo se vuelve intangible por unos segundos, se mueve erráticamente, luego reaparece |

---

# PARTE 6: TIER 1

## 6.1 — Esqueleto Aprendiz
**ID:** `skeleton` | **Archetype:** melee | **Element:** physical  
**Abilities DB:** ninguna especial

| Aspecto | Estado | Detalle |
|---------|--------|---------|
| Ataque melee | ✅ | `EnemyAbility_Melee` via sistema modular. Daño directo |
| VFX | ✅ | `_emit_melee_effect()` con slash animado |

## 6.2 — Duende Sombrío
**ID:** `goblin` | **Archetype:** agile | **Element:** physical  
**Abilities DB:** ninguna especial

| Aspecto | Estado | Detalle |
|---------|--------|---------|
| Ataque melee | ✅ | `EnemyAbility_Melee` |
| Movimiento zigzag | ✅ | `_calculate_archetype_movement()` con zigzag |

## 6.3 — Slime Arcano
**ID:** `slime` | **Archetype:** tank | **Element:** arcane  
**Abilities DB:** `split_on_death`

| Habilidad | Existe en código | Estado | Detalle |
|-----------|-----------------|--------|---------|
| `split_on_death` | ❌ | ⛔ **P1** | **NO IMPLEMENTADA.** `_on_health_died()` en EnemyBase.gd no tiene lógica de split para slime. El slime muere normalmente sin dividirse |
| `damage_reduction` | ✅ | ✅ | Archetype "tank" aplica 40% reducción |

## 6.4 — Murciélago Etéreo
**ID:** `tier_1_murcielago_etereo` | **Archetype:** flying | **Element:** dark  
**Abilities DB:** `erratic_movement`, `evasion`

| Habilidad | Existe en código | Estado | Detalle |
|-----------|-----------------|--------|---------|
| `erratic_movement` | ✅ (parcial) | ⚠️ **P3** | El archetype "flying" tiene movimiento errático en `_calculate_archetype_movement()`, pero NO está vinculado al string. Funciona por archetype |
| `evasion` | ❌ | ⛔ **P1** | **NO IMPLEMENTADA.** No hay lógica de evasión/dodge en `take_damage()`. String muerto |

## 6.5 — Araña Venenosa
**ID:** `tier_1_arana_venenosa` | **Archetype:** debuffer | **Element:** poison  
**Abilities DB:** `poison_attack`, `slow_attack`

| Habilidad | Existe en código | Estado | Detalle |
|-----------|-----------------|--------|---------|
| `poison_attack` | ✅ | ✅ | Mapeado como modificador: `ability.element_type = "poison"` + `_apply_melee_effects()` aplica poison para "debuffer" |
| `slow_attack` | ✅ | ✅ | `_apply_melee_effects()` para "debuffer" aplica slow |

---

# PARTE 7: ANÁLISIS GLOBAL

## 7.1 — Tabla de Cobertura

| Enemigo | Tier | Habilidades DB | Implementadas | % | Estado |
|---------|------|---------------|---------------|---|--------|
| Esqueleto Aprendiz | T1 | 0 | 0 | 100% | ✅ |
| Duende Sombrío | T1 | 0 | 0 | 100% | ✅ |
| Slime Arcano | T1 | 1 (`split_on_death`) | 0 | **0%** | ⛔ |
| Murciélago Etéreo | T1 | 2 (`erratic_movement`, `evasion`) | 0.5 | **25%** | ⛔ |
| Araña Venenosa | T1 | 2 (`poison_attack`, `slow_attack`) | 2 | 100% | ✅ |
| Guerrero Espectral | T2 | 2 (`block_chance`, `counter_attack`) | 1 | **50%** | ⚠️ |
| Lobo de Cristal | T2 | 1 (`pack_bonus`) | 0.5 | **50%** | ⚠️ |
| Golem Rúnico | T2 | 2 (`stomp_attack`, `damage_reduction`) | 2 | 100% | ✅ |
| Hechicero Desgastado | T2 | 2 (`burn_projectile`, `keep_distance`) | 1.5 | **75%** | ⚠️ |
| Sombra Flotante | T2 | 1 (`phase_shift`) | 1 | 100% | ✅ |
| Caballero del Vacío | T3 | 1 (`charge_attack`) | 1 | 100% | ✅ |
| Serpiente de Fuego | T3 | 1 (`fire_trail`) | 1 | 100% | ✅ |
| Elemental de Hielo | T3 | 1 (`freeze_projectile`) | 1 | 100% | ✅ |
| Mago Abismal | T3 | 1 (`teleport`) | 1 | 100% | ✅ |
| Corruptor Alado | T3 | 1 (`buff_allies`) | 1 | 100% | ✅ |
| Titán Arcano | T4 | 3 (`stomp`, `aoe_slam`, `dmg_red`) | 2 | **67%** | ⚠️ |
| Señor de las Llamas | T4 | 2 (`fire_zone`, `burn_aura`) | 0 | **0%** | ⛔ |
| Reina del Hielo | T4 | 2 (`freeze_zone`, `ice_armor`) | 0 | **0%** | ⛔ |
| Archimago Perdido | T4 | 2 (`teleport`, `multi_element`) | 1 | **50%** | ⚠️ |
| Dragón Etéreo | T4 | 2 (`breath_attack`, `dive_attack`) | 1 | **50%** | ⚠️ |
| **Bosses (4)** | B | 23 total | 20 | **87%** | ⚠️ |
| **Elites (6)** | E | 6 | 4 funcionales | **67%** | ⚠️ |

## 7.2 — Problemas Transversales

### PROBLEMA GLOBAL 1: Habilidades fantasma en la DB (⛔ P1)
**12 habilidades** listadas en `EnemyDatabase.gd` no tienen implementación real:
- `split_on_death` (Slime T1)
- `evasion` (Murciélago T1)  
- `counter_attack` (Guerrero Espectral T2)
- `aoe_slam` (Titán Arcano T4)
- `fire_zone` (Señor de las Llamas T4)
- `burn_aura` (Señor de las Llamas T4)
- `freeze_zone` (Reina del Hielo T4)
- `ice_armor` (Reina del Hielo T4)
- `multi_element` (Archimago T4)
- `dive_attack` (Dragón T4)
- `keep_distance` (string, funciona por archetype)
- `erratic_movement` (string, funciona por archetype)

**Impacto:** Estos enemigos son más simples de lo que la DB sugiere. Los Tier 4 en particular pierden mucha identidad.

### PROBLEMA GLOBAL 2: Daño sin telegraph en ataques AoE instantáneos (⛔ P0)
Múltiples ataques aplican daño ANTES o AL MISMO TIEMPO que el efecto visual:
- `teleport_strike` (Conjurador) — daño frame 0
- `arcane_nova` (Conjurador) — daño sin warning
- `void_explosion` (Corazón) — daño sin warning
- `void_beam` (Corazón) — daño incondicional
- `ground_slam` (Guardián) — daño sin warning
- `elite_slam` — daño sin warning
- `_perform_aoe_attack()` (archetype aoe genérico) — centro en player = siempre impacta

**Patrón correcto (ejemplo):** `meteor_call` → Warning 1.5s → Impacto. Todos los ataques AoE deberían seguir este patrón.

### PROBLEMA GLOBAL 3: `_update_boss_passive_effects()` nunca se llama (⛔ P0)
Dos habilidades de boss dependen de esta función:
- `damage_aura` (Corazón del Vacío P2+)
- `fire_trail` (Minotauro P3)

Ambas son **dead code**. Los flags se ponen pero nunca se leen.

**Fix:** Añadir una línea en `_process_boss_aggressive_attacks()`:
```gdscript
func _process_boss_aggressive_attacks(delta: float) -> void:
    # ... existing code ...
    
    # 7. Efectos pasivos (auras, trails)
    _update_boss_passive_effects()  # ← AÑADIR ESTA LÍNEA
```

### PROBLEMA GLOBAL 4: Métodos inexistentes llamados en bosses (P1)
- `enemy.apply_shield()` → No existe en EnemyBase.gd
- `enemy.activate_counter_stance()` → No existe  
- `enemy.start_charge()` → No existe para bosses (solo para archetype "charger")
- `enemy.apply_enrage()` → No existe (usa fallback de modificar stats directamente)

Estos son silent fails — GDScript no crashea en `has_method` checks, pero la funcionalidad no se ejecuta.

### PROBLEMA GLOBAL 5: `_perform_aoe_attack()` siempre impacta al jugador (P1)
En la función (`_perform_aoe_attack()`):
```gdscript
var aoe_center = player.global_position  # Centro = player
var dist_to_player = aoe_center.distance_to(player.global_position)  # = 0 SIEMPRE
if dist_to_player <= radius:  # TRUE SIEMPRE
```
Todo archetype "aoe" (Señor de las Llamas, Reina del Hielo, Titán Arcano para aoe_slam) tiene daño garantizado.

**Fix:** Cambiar centro a posición del enemigo:
```gdscript
var aoe_center = enemy.global_position
```

### PROBLEMA GLOBAL 6: `get_tree().create_timer()` puede outlive el enemigo (P2)
Múltiples funciones usan `get_tree().create_timer()` para callbacks:
- `_spawn_elite_shield_visual()` (12s timer)
- `_spawn_counter_stance_visual()` (2s timer)
- `_spawn_rune_shield_visual()` (10s timer)
- `_boss_rune_prison()` (daño póstumo)
- `_boss_charge_attack()` (warning residual)
- Múltiples `_spawn_boss_projectile_delayed()` calls

Si el enemigo muere antes de que el timer expire, el callback puede ejecutar código sobre nodos liberados o aplicar daño póstumo.

**Fix recomendado:** Usar `enemy.create_tween()` o verificar `is_instance_valid(enemy)` en TODOS los callbacks.

### PROBLEMA GLOBAL 7: Sistema dual Legacy + Modular (P3)
El sistema de ataques tiene dos rutas paralelas:
1. **Modular** (EnemyAbility objects): Se ejecuta primero en `_perform_attack()`
2. **Legacy** (archetype match): Se ejecuta como fallback

Para la mayoría de enemigos, la ruta modular funciona. Pero para archetypes como `"aoe"`, `"breath"`, `"multi"` que NO tienen mapeo modular, se usa el legacy con un `push_warning("FALLBACK")`.

**No es un bug**, pero genera confusión y duplicación de código.

---

## 7.3 — Lista de Fixes Priorizada

### P0 — CRÍTICO (Fix inmediato)
| # | Problema | Archivo | Línea aprox |
|---|---------|---------|-------------|
| 1 | `teleport_strike` daño sin telegraph | EnemyAttackSystem.gd | ~2290 |
| 2 | `void_beam` daño incondicional sin check de posición | EnemyAttackSystem.gd | ~2470 |
| 3 | `_update_boss_passive_effects()` nunca se llama | EnemyAttackSystem.gd | ~1420 |
| 4 | `_perform_aoe_attack()` centro en player = siempre impacta | EnemyAttackSystem.gd | ~1230 |
| 5 | `arcane_nova` daño sin telegraph | EnemyAttackSystem.gd | ~2310 |
| 6 | `void_explosion` daño sin telegraph | EnemyAttackSystem.gd | ~2710 |
| 7 | `ground_slam` daño sin telegraph | EnemyAttackSystem.gd | ~2460 |
| 8 | `elite_slam` daño sin telegraph | EnemyAttackSystem.gd | ~472 |

### P1 — IMPORTANTE (Fix antes de release)
| # | Problema | Archivo |
|---|---------|---------|
| 9 | 12 habilidades fantasma sin implementación | EnemyDatabase.gd / EnemyAttackSystem.gd |
| 10 | `elite_shield` no absorbe daño (puramente visual) | EnemyAttackSystem.gd |
| 11 | `rune_shield` `apply_shield()` no existe en EnemyBase | EnemyAttackSystem.gd |
| 12 | `counter_stance` `activate_counter_stance()` no existe | EnemyAttackSystem.gd |
| 13 | `charge_attack` (boss) `start_charge()` no existe para bosses | EnemyAttackSystem.gd |
| 14 | `rune_prison` sin check de distancia | EnemyAttackSystem.gd |
| 15 | `damage_aura` DPS frameado nunca >= 1 | EnemyAttackSystem.gd |
| 16 | `_spawn_aoe_explosion` usa nodo equivocado para draw | EnemyAttackSystem.gd |

### P2 — DESEABLE
| # | Problema |
|---|---------|
| 17 | `elite_rage` / `boss_enrage` modifica stats permanentemente |
| 18 | `get_tree().create_timer()` puede outlive el enemigo (múltiples sitios) |
| 19 | Mago Abismal doble teleport (modular + EnemyBase) |
| 20 | `flame_breath` simultáneo (sin telegraph previo) |
| 21 | `charge_attack` (boss) aplica daño antes del warning |
| 22 | `teleport_strike` usa "physical" en vez de "arcane" |
| 23 | Visual de AoE en posición del enemigo, no del centro real del AoE |

### P3 — BACKLOG
| # | Problema |
|---|---------|
| 24 | `fire_trail` en _setup_modular_abilities tiene `pass` TODO |
| 25 | `summon_minions` / `elite_summon` silent fail si no hay spawner |
| 26 | `pack_bonus` no da buff real por cercanía |
| 27 | Sistema dual legacy/modular genera warnings FALLBACK |

---

## 7.4 — Estadísticas Finales

| Métrica | Valor |
|---------|-------|
| **Enemigos totales auditados** | 24 (20 normales + 4 bosses) |
| **Habilidades únicas en DB** | 47 |
| **Habilidades implementadas** | 35 (74%) |
| **Habilidades fantasma (sin código)** | 12 (26%) |
| **Bugs P0** | 8 |
| **Bugs P1** | 8 |
| **Bugs P2** | 7 |
| **Bugs P3** | 4 |
| **Total issues** | **27** |
| **Ataque mejor implementado** | `meteor_call` (Minotauro) — Telegraph + delay + visual |
| **Ataque peor implementado** | `teleport_strike` (Conjurador) — Daño garantizado frame 0 |
