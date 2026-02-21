# Bug Report ? LoopiaLike (Non-Core)
## Categorías: Combat & Weapons, UI Scripts, Data & Managers
### Bugs #15 ? #32 (core/ ya escaneado, #1?#14)

---

## #15 ? CRITICAL: LoopiaLikePlayer tiene DOS métodos `_process()` ? el segundo anula al primero

**Archivo:** `scripts/entities/LoopiaLikePlayer.gd`
**Líneas:** ~línea 50 (primer `_process`) y ~línea 690 (segundo `_process`)

**Código problemático:**
```gdscript
# Primer _process (~línea 50) ? MOVIMIENTO, BARRERAS, FOOTSTEPS
func _process(delta: float) -> void:
    if not wizard_player: return
    _handle_movement(delta)
    _enforce_zone_barriers()
    _update_footstep_timer(delta)
    _update_orbital_overheat(delta)
    ...

# Segundo _process (~línea 690) ? SOLO VISUAL DE I-FRAMES
func _process(_delta) -> void:
    _update_iframes_visual()
```

**Qué falla:** En GDScript, si se declaran dos funciones con el mismo nombre, la **segunda definición silenciosamente reemplaza a la primera**. Esto significa que **todo el procesamiento de movimiento, barreras de zona, footsteps y orbital overheat es CÓDIGO MUERTO**. Solo se ejecuta `_update_iframes_visual()`.

**Impacto:** El movimiento del jugador, las barreras de zona y el sistema de overheat orbital **no funcionan** a través de este `_process`. Si el movimiento funciona en el juego, es porque lo maneja otro nodo (probablemente WizardPlayer internamente), pero la lógica de barreras y overheat definitivamente se pierde.

**Fix sugerido:**
```gdscript
# Fusionar el contenido del segundo _process en el primero
func _process(delta: float) -> void:
    if not wizard_player: return
    _handle_movement(delta)
    _enforce_zone_barriers()
    _update_footstep_timer(delta)
    _update_orbital_overheat(delta)
    _update_iframes_visual()  # ? Añadir aquí
    ...
# ELIMINAR el segundo _process
```

**Seguridad del fix:** ? Seguro ? solo fusionar funcionalidad perdida.

---

## #16 ? CRITICAL: SimpleProjectile._handle_hit duplica la lógica de DamageCalculator inline

**Archivo:** `scripts/weapons/SimpleProjectile.gd`
**Líneas:** ~830?920 (`_handle_hit`)

**Código problemático:**
```gdscript
func _handle_hit(body):
    ...
    # DUPLICA la lógica de DamageCalculator manualmente:
    if player_stats.get_stat("sharpshooter") > 0:
        ...
    if player_stats.get_stat("brawler") > 0:
        ...
    if player_stats.get_stat("executioner") > 0:
        ...
    if player_stats.get_stat("full_hp_bonus") > 0:
        ...
    # Combustion, russian roulette, bleed... todo inline
```

**Qué falla:** `DamageCalculator.calculate_final_damage()` centraliza los bonos de daño, y `ChainProjectile` y `OrbitalManager` lo usan correctamente. Pero `SimpleProjectile` (el tipo de proyectil MÁS COMÚN) tiene su propia copia inline de esta lógica. Cualquier cambio en `DamageCalculator` (nuevos bonos, correcciones de fórmulas) **no se aplicará** a los proyectiles simples.

**Impacto:** Inconsistencia de daño entre tipos de proyectil. Si se añade un nuevo bono en `DamageCalculator`, los proyectiles simples no lo aplicarán.

**Fix sugerido:**
```gdscript
func _handle_hit(body):
    ...
    var final_damage = DamageCalculator.calculate_final_damage(
        base_damage, player_stats, body, element
    )
    body.take_damage(final_damage, element_name, owner_ref)
```

**Seguridad del fix:** ?? Requiere verificación ? la lógica inline puede tener divergencias intencionales (combustion, russian roulette) que no están en DamageCalculator. Revisar y migrar cualquier bono faltante a DamageCalculator primero.

---

## #17 ? CRITICAL: BasePlayer procesa grit/frost_nova/soul_link/thorns DOS VECES por evento de daño

**Archivo:** `scripts/entities/BasePlayer.gd`
**Líneas:** ~870?940 (`_process_post_damage_effects`) y ~1800?1900 (`_on_health_damaged`)

**Código problemático:**
```gdscript
# Ruta 1: Cola de daño anti-shotgun ? _process_frame_damage ? _process_post_damage_effects
func _process_post_damage_effects(damage: int, ...):
    # Grit check ? reduce daño
    # Frost nova ? congela enemigos cercanos
    # Soul link ? cura basado en daño
    # Thorns ? refleja daño al atacante

# Ruta 2: Señal health_changed ? _on_health_damaged
func _on_health_damaged(current_hp, max_hp, damage_amount):
    # Grit check ? misma lógica duplicada
    # Frost nova ? misma lógica duplicada
    # Soul link ? misma lógica duplicada
    # Thorns ? misma lógica duplicada
```

**Qué falla:** Ambas rutas se ejecutan para el mismo evento de daño:
1. El sistema anti-shotgun en `_process()` llama `_process_post_damage_effects()`
2. `HealthComponent` emite `health_changed` que invoca `_on_health_damaged()`

Resultado: **Grit se aplica 2 veces** (doble reducción), **Frost Nova se activa 2 veces** (doble congelación), **Soul Link cura el doble**, y **Thorns refleja el doble de daño**.

**Fix sugerido:**
```gdscript
# Eliminar la lógica de grit/frost_nova/soul_link/thorns de _on_health_damaged
# y dejar que _process_post_damage_effects sea la ÚNICA ruta
func _on_health_damaged(current_hp, max_hp, damage_amount):
    # Solo actualizar HUD y efectos visuales aquí
    update_health_bar()
    _flash_damage()
    # NO procesar grit/frost_nova/soul_link/thorns
```

**Seguridad del fix:** ? Seguro ? los efectos deben procesarse una sola vez.

---

## #18 ? HIGH: Game.gd usa `position` en vez de `death_position` para spawnear cofres

**Archivo:** `scripts/game/Game.gd`
**Línea:** ~1175

**Código problemático:**
```gdscript
func _on_enemy_died(death_position: Vector2, enemy_type: String, ...):
    ...
    if spawn_chest:
        _spawn_reward_chest(position, rewards)  # ? BUG: usa 'position' del nodo Game
```

**Qué falla:** `position` se refiere a la propiedad `position` del nodo `Game` (probablemente `Vector2.ZERO`), no al parámetro `death_position` donde murió el enemigo. **Todos los cofres de recompensa aparecen en la esquina (0,0)** en vez de donde murió el enemigo.

**Fix sugerido:**
```gdscript
_spawn_reward_chest(death_position, rewards)
```

**Seguridad del fix:** ? Seguro ? corrección trivial.

---

## #19 ? HIGH: EnemyBase plague bearer llama `apply_freeze()` con 1 argumento en vez de 2

**Archivo:** `scripts/enemies/EnemyBase.gd`
**Línea:** dentro de `_on_health_died`, sección plague bearer

**Código problemático:**
```gdscript
# Plague Bearer: al morir, congela enemigos cercanos
for nearby_enemy in nearby_enemies:
    nearby_enemy.apply_freeze(duration)  # ? BUG: falta el argumento 'amount'
```

**Qué falla:** `apply_freeze()` requiere dos argumentos: `(amount: float, duration: float)`. Pasar solo `duration` causa un error en runtime que silenciosamente falla, y la mecánica plague bearer **no congela a nadie**.

**Fix sugerido:**
```gdscript
nearby_enemy.apply_freeze(0.5, duration)  # amount=0.5 (50% slow), duration
```

**Seguridad del fix:** ? Seguro ? el valor de `amount` debe calibrarse según balance.

---

## #20 ? HIGH: BaseWeapon._create_chain_projectile aplica `+1` duplicado al chain count

**Archivo:** `scripts/weapons/BaseWeapon.gd`
**Línea:** ~730 (`_create_chain_projectile`)

**Código problemático:**
```gdscript
var chain_count = projectile_count + 1 + 1  # ? duplicado +1
```

**Qué falla:** Un `+ 1` extra fue añadido (probablemente en un merge o fix incompleto). Esto hace que los proyectiles de cadena reboten **una vez más de lo previsto**, lo que amplifica el DPS de armas chain sin intención.

**Fix sugerido:**
```gdscript
var chain_count = projectile_count + 1  # Solo un +1
```

**Seguridad del fix:** ?? Verificar si el balance actual depende del +1 extra (si lo tiene, ajustar balance tras el fix).

---

## #21 ? HIGH: TreasureChest._on_shop_popup_closed llama `queue_free()` DOS VECES

**Archivo:** `scripts/interactables/TreasureChest.gd`
**Líneas:** ~620?630

**Código problemático:**
```gdscript
func _on_shop_popup_closed(purchased: bool):
    is_opened = true
    if not purchased:
        create_opening_effect()
    # Destruir cofre
    await get_tree().create_timer(0.5).timeout
    queue_free()

    # Destruir cofre  ? DUPLICADO
    await get_tree().create_timer(0.5).timeout
    queue_free()
```

**Qué falla:** Después del primer `queue_free()`, el nodo se marca para destrucción. El segundo `await` se ejecuta en un nodo que ya está siendo destruido, causando potencialmente:
- Error de referencia inválida
- Doble liberación de memoria

**Fix sugerido:** Eliminar el bloque duplicado:
```gdscript
func _on_shop_popup_closed(purchased: bool):
    is_opened = true
    if not purchased:
        create_opening_effect()
    await get_tree().create_timer(0.5).timeout
    queue_free()
```

**Seguridad del fix:** ? Seguro ? eliminación de duplicado obvio.

---

## #22 ? MEDIUM: TreasureChest._apply_item tiene match arm duplicado para "healing"

**Archivo:** `scripts/interactables/TreasureChest.gd`
**Líneas:** ~510 y ~660

**Código problemático:**
```gdscript
func _apply_item(item: Dictionary):
    match item_type:
        "healing":                    # ? Primer match (línea ~510)
            var amount = item.get("amount", 20)
            if player_ref and player_ref.has_method("heal"):
                player_ref.heal(amount)
        ...
        "healing", "health_boost":    # ? Segundo match (línea ~660) ? INALCANZABLE para "healing"
            var amount = item.get("amount", 0)
            ...
```

**Qué falla:** El primer `"healing"` captura todos los items de tipo "healing". El segundo brazo `"healing", "health_boost"` nunca se ejecutará para `"healing"` (solo para `"health_boost"`). El primer brazo usa `amount` default de 20, mientras el segundo usa 0. Items de tipo `"health_boost"` usarán la lógica del segundo brazo con default 0, lo cual puede no curar nada si `amount` no está en el diccionario.

**Fix sugerido:**
```gdscript
# Eliminar el primer "healing" y unificar:
"healing", "health_boost":
    var amount = item.get("amount", 20)
    if player_ref and player_ref.has_method("heal"):
        player_ref.heal(amount)
    elif player_ref and "health_component" in player_ref:
        if player_ref.health_component.has_method("heal"):
            player_ref.health_component.heal(amount)
```

**Seguridad del fix:** ? Seguro.

---

## #23 ? MEDIUM: SimpleProjectile._get_player() tiene código inalcanzable después de `return null`

**Archivo:** `scripts/weapons/SimpleProjectile.gd`
**Líneas:** ~815?825

**Código problemático:**
```gdscript
func _get_player():
    ...
    return null
    # === CÓDIGO INALCANZABLE ===
    _spawn_hit_effect()      # Nunca se ejecuta
    # pierce checking...     # Nunca se ejecuta
```

**Qué falla:** Líneas de código después de un `return` incondicional que nunca se ejecutan. Probablemente es resultado de un refactoring incompleto donde se movió lógica entre funciones.

**Impacto:** Código muerto que confunde el mantenimiento. Si `_spawn_hit_effect()` y la verificación de pierce eran importantes, están perdidos.

**Fix sugerido:** Eliminar las líneas inalcanzables o moverlas donde corresponda.

**Seguridad del fix:** ? Seguro ? solo eliminar dead code.

---

## #24 ? MEDIUM: BaseWeapon.get_cooldown_progress() puede dividir entre cero

**Archivo:** `scripts/weapons/BaseWeapon.gd`
**Línea:** ~950

**Código problemático:**
```gdscript
func get_cooldown_progress() -> float:
    return current_cooldown / cooldown  # ? Si cooldown == 0 ? INF o NaN
```

**Qué falla:** Armas orbitales y ciertos tipos pueden tener `cooldown = 0.0`. Dividir por cero produce `INF` o `NaN`, que puede propagarse a la UI (barras de cooldown) y causar artifacts visuales o crashes.

**Fix sugerido:**
```gdscript
func get_cooldown_progress() -> float:
    if cooldown <= 0.0:
        return 0.0
    return current_cooldown / cooldown
```

**Seguridad del fix:** ? Seguro.

---

## #25 ? MEDIUM: ProjectileFactory._create_base_projectile retorna null silenciosamente

**Archivo:** `scripts/weapons/ProjectileFactory.gd`
**Línea:** ~dentro de `_create_base_projectile`

**Código problemático:**
```gdscript
static func _create_base_projectile(...):
    if not ProjectilePool.instance:
        return null  # ? Sin log, sin fallback
```

**Qué falla:** Si `ProjectilePool.instance` no existe (e.g., durante inicialización temprana, tests, o si el autoload no cargó), todos los intentos de crear proyectiles fallan silenciosamente. El caller (BaseWeapon) no verifica este null, lo que causa un crash posterior cuando intenta llamar métodos en el proyectil `null`.

**Fix sugerido:**
```gdscript
static func _create_base_projectile(...):
    if not ProjectilePool.instance:
        push_warning("[ProjectileFactory] ProjectilePool.instance es null ? creando proyectil sin pool")
        var fallback = Area2D.new()
        # configurar manualmente...
        return fallback
```

**Seguridad del fix:** ?? El fallback debe replicar la configuración mínima del pool.

---

## #26 ? MEDIUM: AOEEffect._create_aoe_visual usa await que puede crashear si el nodo es liberado

**Archivo:** `scripts/weapons/ProjectileFactory.gd`
**Línea:** dentro de `AOEEffect._create_aoe_visual`

**Código problemático:**
```gdscript
func _create_aoe_visual():
    ...
    await get_tree().create_timer(duration).timeout
    # Si el nodo fue liberado durante el await,
    # get_tree() retorna null ? crash
    queue_free()
```

**Qué falla:** Si el `AOEEffect` es liberado (por limpieza de escena, cambio de escena, etc.) durante el `await`, al reanudarse la coroutine, `get_tree()` retorna `null` y `queue_free()` falla. En Godot 4.5, esto genera un error silencioso o crash.

**Fix sugerido:**
```gdscript
await get_tree().create_timer(duration).timeout
if is_instance_valid(self):
    queue_free()
```

**Seguridad del fix:** ? Seguro.

---

## #27 ? MEDIUM: ChainProjectile usa await en `_execute_chain_sequence` ? crash si liberado

**Archivo:** `scripts/weapons/ChainProjectile.gd`
**Línea:** dentro de `_execute_chain_sequence`

**Código problemático:**
```gdscript
func _execute_chain_sequence():
    for target in chain_targets:
        await get_tree().create_timer(chain_delay).timeout
        # Si el ChainProjectile fue liberado durante este await...
        _chain_to_target(target)
```

**Qué falla:** Misma vulnerabilidad que #26. Si el proyectil se destruye durante el chain (por limpieza de escena, pool return, etc.), la coroutine crashea.

**Fix sugerido:**
```gdscript
for target in chain_targets:
    await get_tree().create_timer(chain_delay).timeout
    if not is_instance_valid(self):
        return
    if not is_instance_valid(target):
        continue
    _chain_to_target(target)
```

**Seguridad del fix:** ? Seguro.

---

## #28 ? MEDIUM: EnemyAttackSystem._perform_melee_attack no verifica null de player

**Archivo:** `scripts/enemies/EnemyAttackSystem.gd`
**Línea:** ~1090

**Código problemático:**
```gdscript
func _perform_melee_attack() -> void:
    if not player.has_method("take_damage"):  # ? crash si player es null
        return
    ...
    _apply_melee_effects()  # ? También accede a player sin null check
```

**Qué falla:** Si `player` es `null` (jugador muerto, liberado de la escena), acceder a `player.has_method()` genera un crash. Otras funciones del mismo archivo (como `_perform_ranged_attack`) sí verifican `if not player: return` primero.

**Fix sugerido:**
```gdscript
func _perform_melee_attack() -> void:
    if not is_instance_valid(player) or not player.has_method("take_damage"):
        return
```

**Seguridad del fix:** ? Seguro.

---

## #29 ? MEDIUM: CombatSystemIntegration.gd crea PlayerStats/AttackManager duplicados

**Archivo:** `scripts/game/CombatSystemIntegration.gd`
**Líneas:** ~50?80

**Código problemático:**
```gdscript
# CombatSystemIntegration crea:
var player_stats = PlayerStatsScript.new()
var attack_manager = AttackManagerScript.new()

# PERO Game.gd TAMBIÉN crea:
func _create_player_stats():
    player_stats = ps_script.new()
    ...
```

**Qué falla:** Si `CombatSystemIntegration` está activo junto con `Game.gd`, habrá **dos instancias de PlayerStats** y potencialmente **dos AttackManagers**, causando estado dividido: las mejoras aplicadas a uno no se reflejan en el otro.

**Impacto:** Probablemente `CombatSystemIntegration` es legacy/no usado, pero si algún sistema lo referencia, crea una inconsistencia silenciosa.

**Fix sugerido:** Verificar si `CombatSystemIntegration.gd` está en uso. Si no, eliminarlo o desactivarlo. Si sí, unificar con `Game.gd`.

**Seguridad del fix:** ?? Requiere verificación de si está instanciado en alguna escena.

---

## #30 ? MEDIUM: Game.gd `_collect_complete_run_data` usa contadores legacy para rerolls/banishes

**Archivo:** `scripts/game/Game.gd`
**Línea:** ~1622

**Código problemático:**
```gdscript
run_data["rerolls_used"] = 3 - remaining_rerolls
run_data["banishes_used"] = 2 - remaining_banishes
```

**Qué falla:** Los comentarios en `_on_reroll_used()` y `_on_banish_used()` dicen explícitamente que `remaining_rerolls`/`remaining_banishes` **ya no se usan** y que `PlayerStats.current_rerolls` es la fuente de verdad. Sin embargo, `_collect_complete_run_data` aún lee estas variables legacy, que pueden no estar actualizadas.

**Fix sugerido:**
```gdscript
var total_rerolls = 3  # o player_stats.base_rerolls
var total_banishes = 2  # o player_stats.base_banishes
if player_stats:
    run_data["rerolls_used"] = total_rerolls - player_stats.current_rerolls
    run_data["banishes_used"] = total_banishes - player_stats.current_banishes
```

**Seguridad del fix:** ?? Depende de la estructura de PlayerStats.

---

## #31 ? LOW: BasePlayer tiene dos métodos `create_health_bar()` con implementaciones diferentes

**Archivo:** `scripts/entities/BasePlayer.gd`
**Líneas:** ~1200 y ~1550

**Código problemático:**
```gdscript
# Versión 1 (~1200): Simplificada, sin shield bar
func create_health_bar():
    health_bar = ProgressBar.new()
    health_bar.position = Vector2(-25, 35)
    ...

# Versión 2 (~1550): Completa, con shield bar
func create_health_bar():
    health_bar = ProgressBar.new()
    shield_bar = ProgressBar.new()
    ...
```

**Qué falla:** La segunda definición anula la primera (como con `_process` en bug #15). Pero aquí el impacto es menor: la versión más completa (con shield bar) es la que se ejecuta, lo que probablemente es lo deseado.

**Impacto:** Código muerto confuso, pero funcionalmente correcto si la versión 2 es la deseada.

**Fix sugerido:** Eliminar la versión 1 (simplificada).

**Seguridad del fix:** ? Seguro.

---

## #32 ? LOW: EnemyBase.get_info() retorna variable `hp` potencialmente stale

**Archivo:** `scripts/enemies/EnemyBase.gd`
**Línea:** dentro de `get_info()`

**Código problemático:**
```gdscript
func get_info() -> Dictionary:
    return {
        ...
        "hp": hp,  # ? Variable de instancia, puede estar desincronizada
        ...
    }
```

**Qué falla:** `hp` es una variable de instancia que puede no estar sincronizada con `health_component.current_health` (la fuente real de verdad). Si el daño se procesa a través de `HealthComponent`, `hp` puede ser stale.

**Fix sugerido:**
```gdscript
"hp": health_component.current_health if health_component else hp,
```

**Seguridad del fix:** ? Seguro.

---

## Resumen

| # | Severidad | Archivo | Bug |
|---|-----------|---------|-----|
| 15 | ?? CRITICAL | LoopiaLikePlayer.gd | Dos `_process()` ? movimiento es código muerto |
| 16 | ?? CRITICAL | SimpleProjectile.gd | Duplica DamageCalculator inline ? desincronización |
| 17 | ?? CRITICAL | BasePlayer.gd | Grit/frost_nova/soul_link/thorns se procesan 2x |
| 18 | ?? HIGH | Game.gd | `position` en vez de `death_position` ? cofres en (0,0) |
| 19 | ?? HIGH | EnemyBase.gd | `apply_freeze(duration)` ? falta argumento `amount` |
| 20 | ?? HIGH | BaseWeapon.gd | `+1 +1` duplicado en chain count |
| 21 | ?? HIGH | TreasureChest.gd | `queue_free()` duplicado en shop popup close |
| 22 | ?? MEDIUM | TreasureChest.gd | Match arm "healing" duplicado ? segundo inalcanzable |
| 23 | ?? MEDIUM | SimpleProjectile.gd | Código inalcanzable después de `return null` |
| 24 | ?? MEDIUM | BaseWeapon.gd | División por cero en `get_cooldown_progress()` |
| 25 | ?? MEDIUM | ProjectileFactory.gd | Retorna `null` silenciosamente sin pool |
| 26 | ?? MEDIUM | ProjectileFactory.gd | `await` en AOEEffect ? crash si nodo liberado |
| 27 | ?? MEDIUM | ChainProjectile.gd | `await` en chain sequence ? crash si liberado |
| 28 | ?? MEDIUM | EnemyAttackSystem.gd | Melee attack sin null check de `player` |
| 29 | ?? MEDIUM | CombatSystemIntegration.gd | Crea PlayerStats/AttackManager duplicados |
| 30 | ?? MEDIUM | Game.gd | Usa contadores legacy para rerolls/banishes |
| 31 | ?? LOW | BasePlayer.gd | Dos `create_health_bar()` ? primera es código muerto |
| 32 | ?? LOW | EnemyBase.gd | `get_info()` retorna `hp` potencialmente stale |

---

### Notas de cobertura

**Archivos completamente leídos (16):**
BaseWeapon.gd, ProjectileFactory.gd, WeaponFusionManager.gd, EnemyBase.gd, EnemyProjectile.gd, HealthComponent.gd, DamageCalculator.gd, SimpleProjectile.gd, ChainProjectile.gd, OrbitalManager.gd, LoopiaLikePlayer.gd, BasePlayer.gd, CombatSystemIntegration.gd, EnemyPool.gd, SpawnBudgetManager.gd, Game.gd

**Archivos parcialmente leídos (8):**
EnemyAttackSystem.gd (2400/4770), LevelUpPanel.gd (1200/2311), WaveManager.gd (300/1211), LootManager.gd (786/786 ?), GameHUD.gd (650/650 ?), GameOverScreen.gd (300/423), TreasureChest.gd (750/750 ?)

**Excluidos del escaneo:** `scripts/core/` (ya escaneado, bugs #1?#14)
