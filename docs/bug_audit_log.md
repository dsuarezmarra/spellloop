# Bug Audit Log — Sesión 9 (Auditoría Autónoma Completa)

> Generado automáticamente. Auditor: GitHub Copilot (Claude Opus 4.6)
> Fecha de inicio: Sesión 9
> Motor: Godot 4.5.1, GDScript

---

## Resumen Ejecutivo

| Ronda | Bugs Fixeados | Commit | Prioridad |
|-------|--------------|--------|-----------|
| R1 | 8 | `693bdf6a` | 4× P0, 4× P1 |
| R2 | 6 | `3cb4f328` | 2× P0, 4× P1 |
| Coin Fix | 1 | `a96510c7` | P0 (regresión R2-5) |
| R3 | 4 | `f4ae855e` | 3× P0, 1× P1 |
| R4 | 5 | `dde1374f` | 3× P1, 2× P2 |
| R5 | 5 | `67d57e80` | 1× P0, 1× P1, 3× P2 |
| R6 | 2 | `f53a1cb1` | 1× P1, 1× P2 |
| R7 | 6 | `7c5abd62` | 2× P1, 4× P2 |
| R8 | 6 | `e286590e` | 3× P1, 3× P2 |
| R9 | 3 | `78d0e2b4` | 1× P1, 2× P2 |
| R10 | 3 | `6613d35d` | 1× P0, 1× P1, 1× P2 |
| R11 | 3 | `e416d0cc` | 1× P1, 2× P2 |
| R12 | 3 | `a6be276c` | 1× P0, 2× P1 |
| R13 | 3 | `a4d22e04` | 2× P1, 1× P2 |
| R14 | 1 | *(pending)* | 1× P1 |
| **Total** | **59** | **15 commits** | **9× P0, 25× P1, 19× P2** |

---

## Round 1 — Commit `693bdf6a`

### R1-1 (P0): TreasureChest double queue_free
- **Archivo:** `scripts/interactables/TreasureChest.gd`
- **Bug:** `queue_free()` llamado sin guard → double free crash
- **Fix:** Añadir `_is_freed` guard

### R1-2 (P0): SimpleChestPopup await sin guard
- **Archivo:** `scripts/ui/SimpleChestPopup.gd`
- **Bug:** `await` no verificaba si el nodo seguía en el árbol
- **Fix:** Añadir `is_inside_tree()` guards después de awaits

### R1-3 (P0): ShopChestPopup await sin guard
- **Archivo:** `scripts/ui/ShopChestPopup.gd`
- **Bug:** Mismo patrón que R1-2
- **Fix:** Añadir `is_inside_tree()` guards

### R1-4 (P0): BeamVisualEffect double dissipate
- **Archivo:** `scripts/vfx/BeamVisualEffect.gd`
- **Bug:** `dissipate()` podía ejecutarse dos veces
- **Fix:** Añadir `_is_dissipating` guard

### R1-5 (P1): gold_mult consumido sin aplicar
- **Archivo:** `scripts/core/ExperienceManager.gd`
- **Bug:** Multiplicador de oro leído pero no aplicado
- **Fix:** Aplicar multiplicador al calcular valor final

### R1-6 (P1): range_mult no aplicado a armas
- **Archivo:** `scripts/core/ExperienceManager.gd`
- **Bug:** `pickup_range` no se aplicaba
- **Fix:** Corregir aplicación del multiplicador

### R1-7 (P1): Chain damage bypasses DamageCalculator
- **Archivo:** `scripts/weapons/projectiles/SimpleProjectile.gd`
- **Bug:** Daño de cadena aplicado crudo sin pasar por DamageCalculator
- **Fix:** Usar `DamageCalculator.calculate_final_damage()` + `apply_damage_with_effects()`

### R1-8 (P1): cooldown_reduction en vez de attack_speed_mult
- **Archivo:** `scripts/weapons/BaseWeapon.gd`
- **Bug:** Stat incorrecto leído para calcular cooldown de ataque
- **Fix:** Cambiar a `attack_speed_mult`

---

## Round 2 — Commit `3cb4f328`

### R2-1 (P0): Level-up post-mortem
- **Archivo:** `scripts/game/Game.gd`
- **Bug:** Panel de level-up podía abrirse después de morir
- **Fix:** Guard `game_running` antes de mostrar panel

### R2-2 (P0): Boundary damage float sin convertir a int
- **Archivo:** `scripts/game/Game.gd`
- **Bug:** Daño de boundary acumulado como float, causaba error en `take_damage()`
- **Fix:** Convertir a `int()` antes de aplicar

### R2-3 (P1): Chest gold no usa add_coins()
- **Archivo:** `scripts/core/ItemManager.gd`
- **Bug:** Handler de oro en cofres no usaba `add_coins()` (no emitía señales)
- **Fix:** Cambiar a `add_coins()`

### R2-4 (P1): xp_on_reroll property name incorrecto
- **Archivo:** `scripts/ui/LevelUpPanel.gd`
- **Bug:** Property name mal referenciado → no se aplicaba XP al rerollear
- **Fix:** Corregir nombre de variable

### R2-5 (P1): CoinPickup double collection
- **Archivo:** `scripts/pickups/CoinPickup.gd`
- **Bug:** `_on_body_entered` podía ejecutarse dos veces
- **Fix:** Guard `_is_collected`

### R2-6 (P1): Reroll spend_coins() no llamado
- **Archivo:** `scripts/ui/LevelUpPanel.gd`
- **Bug:** Rerolls de pago no descontaban monedas
- **Fix:** Llamar `spend_coins()` al hacer reroll pagado

---

## Coin Fix — Commit `a96510c7`

### Regresión de R2-5: Pool reuse no reseteaba _is_collected
- **Archivo:** `scripts/pickups/CoinPickup.gd`
- **Bug:** El guard `_is_collected` añadido en R2-5 no se reseteaba en `initialize()` → monedas recicladas del pool eran intocables
- **Fix:** `_is_collected = false` al inicio de `initialize()`

---

## Round 3 — Commit `f4ae855e`

### R3-1 (P0): EnemyBase _is_dead nunca reseteado en pool
- **Archivo:** `scripts/enemies/EnemyBase.gd`
- **Bug:** Enemigos reciclados del pool mantenían `_is_dead = true` → zombies invisibles
- **Fix:** `_is_dead = false` + `_generation_id += 1` + `_reset_status_effects()` en `initialize_from_database()`

### R3-2 (P0): ItemManager modify_stat() crash
- **Archivo:** `scripts/core/ItemManager.gd`
- **Bug:** Llamada a `modify_stat()` inexistente → crash al aplicar upgrades
- **Fix:** Cambiar a `add_stat()`

### R3-3 (P0): TreasureChest.new() en vez de instantiate()
- **Archivo:** `scripts/core/ItemManager.gd`
- **Bug:** `TreasureChest.new()` creaba nodo vacío sin escena → cofre sin colisión/visual
- **Fix:** Precargar escena y usar `_chest_scene.instantiate()`

### R3-4 (P1): Timer lambdas corruptas en enemigos reciclados
- **Archivo:** `scripts/enemies/EnemyBase.gd`
- **Bug:** Lambdas de timers capturaban `self` → callbacks ejecutaban en enemigos reciclados
- **Fix:** Pattern `_generation_id`: lambda captura `gen` local, compara con `_generation_id`

---

## Round 4 — Commit `dde1374f`

### R4-1 (P1): DoT ticks esquivables/mitigables
- **Archivo:** `scripts/entities/players/BasePlayer.gd`
- **Bug:** `_apply_burn_tick()` y `_apply_poison_tick()` llamaban `take_damage()` sin `is_pre_mitigated=true` → DoT podía ser esquivado, absorbido por escudo, reducido por armadura
- **Fix:** Pasar tercer argumento `true` en ambas funciones

### R4-2 (P1): Turret Mode bonuses muertos para armas
- **Archivo:** `scripts/core/AttackManager.gd`
- **Bug:** Turret Mode añadía +25% damage y +50% atk speed a `PlayerStats.get_stat()`, pero armas leen de `GlobalWeaponStats` via `AttackManager`
- **Fix:** Inyectar bonuses de Turret en `_get_combined_global_stats()`

### R4-3 (P1): Growth weapon stats muertos
- **Archivos:** `scripts/core/PlayerStats.gd`, `scripts/core/AttackManager.gd`
- **Bug:** Growth añadía temp modifiers a PlayerStats para stats de armas, invisibles para las armas
- **Fix:** Nuevo helper `get_growth_weapon_bonuses()` + inyección en AttackManager

### R4-4 (P2): HealthComponent.damaged señal con valor raw
- **Archivo:** `scripts/components/HealthComponent.gd`
- **Bug:** `damaged.emit(amount, ...)` usaba daño pre-mitigación
- **Fix:** Cambiar a `damaged.emit(final_damage, ...)`

### R4-5 (P2): HealthComponent double FloatingText en player
- **Archivo:** `scripts/components/HealthComponent.gd`
- **Bug:** HealthComponent spawneaba FloatingText para todos los Node2D, pero BasePlayer ya genera el suyo → números dobles
- **Fix:** Excluir player con `not owner_node.is_in_group("player")`

---

## Round 5 — Commit `67d57e80`

### R5-1 (P0): Estado de arquetipo no reseteado en pool reuse
- **Archivo:** `scripts/enemies/EnemyBase.gd`
- **Bug:** Enemigos reciclados mantenían `is_phased`, `is_charging`, collision layer desactivada, todos los timers de arquetipo → enemigos permanentemente intangibles/unkillables
- **Fix:** Reset completo de estado de arquetipo en `initialize_from_database()`

### R5-2 (P1): EnemyManager cleanup bloqueado en modo WaveManager
- **Archivo:** `scripts/core/EnemyManager.gd`
- **Bug:** `_cleanup_dead_enemies()`, `_process_enemy_despawn()` y `_process_zombie_sweep()` gateados por `spawning_enabled` → con WaveManager activo, no corrían
- **Fix:** Mover las 3 funciones fuera del guard de `spawning_enabled`

### R5-3 (P2): Fire trail tween vinculado al enemigo
- **Archivo:** `scripts/enemies/EnemyBase.gd`
- **Bug:** `create_tween()` (self) en vez de `trail.create_tween()` → tween muere si el enemigo se recicla antes que el trail expire
- **Fix:** Crear tween en el trail node

### R5-4 (P2): reroll base inflado en stats de run
- **Archivo:** `scripts/game/Game.gd`
- **Bug:** `total_rerolls = reroll_count + 3` pero base real es 2
- **Fix:** Cambiar a `+ 2`

### R5-5 (P2): Trail archetype sin case en _setup_archetype_behavior
- **Archivo:** `scripts/enemies/EnemyBase.gd`
- **Bug:** Faltaba case `"trail"` → no reseteaba trail_timer
- **Fix:** Añadir case con `trail_timer = 0.0`

---

## Round 6 — Commit `f53a1cb1`

### R6-1 (P1): OrbitalManager chain damage bypasses DamageCalculator
- **Archivo:** `scripts/weapons/projectiles/OrbitalManager.gd`
- **Bug:** `_apply_chain_damage()` aplicaba daño crudo sin pasar por DamageCalculator (mismo bug que FIX-P1 en SimpleProjectile, pero nunca portado)
- **Fix:** Portar pattern de SimpleProjectile: `calculate_final_damage()` + `apply_damage_with_effects()`

### R6-2 (P2): OrbitalManager sin crit propagation ni bleed
- **Archivo:** `scripts/weapons/projectiles/OrbitalManager.gd`
- **Bug:** Hit principal orbital no propagaba `is_crit` metadata ni aplicaba `bleed_on_hit_chance`
- **Fix:** Añadir `set_meta("last_hit_was_crit", ...)` y check de bleed_on_hit_chance

---

## Round 7 — Commit `7c5abd62`

### R7-1 (P1): Orbital Overheat nunca se activa
- **Archivo:** `scripts/entities/LoopiaLikePlayer.gd`
- **Bug:** `_has_active_orbitals()` buscaba nodo hijo `"WeaponManager"` que no existe → siempre retornaba false → chip damage de orbitales era código muerto
- **Fix:** Cambiar a `AttackManager` via grupo, verificar `target_type == ORBIT`

### R7-2 (P1): Boss partículas huérfanas (memory leak)
- **Archivo:** `scripts/components/AnimatedBossSprite.gd`
- **Bug:** `_setup_particles()` añadía partículas al padre del padre → no se destruían con el boss → 8 nodos huérfanos por boss en partidas largas
- **Fix:** Añadir `_exit_tree()` con cleanup de partículas

### R7-3 (P2): CoinPickup z_index en _exit_tree (no-op)
- **Archivo:** `scripts/pickups/CoinPickup.gd`
- **Bug:** `z_index = 5` dentro de `_exit_tree()` → no tiene efecto
- **Fix:** Mover a `_ready()` después de `add_to_group("coins")`

### R7-4 (P2): WaveManager tweens infinitos del elite warning
- **Archivo:** `scripts/managers/WaveManager.gd`
- **Bug:** Tweens creados con `create_tween()` (self/WaveManager) → rotation_tween con `set_loops()` infinito seguía activo tras `queue_free()` del warning
- **Fix:** Usar `warning.create_tween()` para que mueran con el nodo

### R7-5 (P2): WaveManager double cleanup race condition
- **Archivo:** `scripts/managers/WaveManager.gd`
- **Bug:** cleanup_timer y `_complete_elite_spawn` ambos hacían queue_free del warning simultáneamente
- **Fix:** Eliminar cleanup_timer duplicado

### R7-6 (P2): SaveManager slot vacío sin datos por defecto
- **Archivo:** `scripts/core/SaveManager.gd`
- **Bug:** `set_active_slot()` con slot vacío → `current_save_data = {}` + `is_data_loaded = true` → accesos posteriores fallan
- **Fix:** Inicializar con `DEFAULT_SAVE_DATA.duplicate(true)` si empty

---

## Round 8 — Commit `e286590e`

### R8-1 (P1): Boss orbitals usan `orbital.position` con `top_level=true`
- **Archivo:** `scripts/enemies/EnemyAttackSystem.gd`
- **Bug:** Orbitales de boss posicionados con `.position` relativo, pero `top_level=true` → se colocan relativos al mundo, no al boss
- **Fix:** Usar `orbital.global_position = enemy.global_position + offset`

### R8-2 (P1): Damage zone timer sin guard de enemy freed
- **Archivo:** `scripts/enemies/EnemyAttackSystem.gd`
- **Bug:** Timer lambda de damage zone usa `enemy` como source sin verificar `is_instance_valid(enemy)`
- **Fix:** `var source = enemy if is_instance_valid(enemy) else null`

### R8-3 (P1): Elite rage inflación permanente de stats
- **Archivo:** `scripts/enemies/EnemyAttackSystem.gd`
- **Bug:** Rage re-aplicaba multiplicador sobre stats ya enragidos → inflación acumulativa permanente
- **Fix:** Restaurar `pre_rage_damage` antes de re-aplicar; verificar meta existente

### R8-4 (P2): ProjectilePool element_type por defecto "ice" en vez de "physical"
- **Archivo:** `scripts/weapons/projectiles/ProjectilePool.gd`
- **Bug:** `_reset_projectile()` seteaba `element_type = "ice"` como default
- **Fix:** Cambiar a `element_type = "physical"`

### R8-5 (P2): MainMenu format fallback
- **Archivo:** `scripts/ui/MainMenu.gd`
- **Bug:** `_format_time()` sin fallback en else → crash potencial
- **Fix:** Añadir fallback format en bloque else (ya estaba corregido por scan)

### R8-8 (P2): FloatingText call_deferred race condition
- **Archivo:** `scripts/ui/FloatingText.gd`
- **Bug:** `root.call_deferred("add_child", instance)` causaba timing issues con textos flotantes
- **Fix:** Usar `root.add_child(instance)` directamente

---

## Round 9 — Commit `78d0e2b4`

### R9-1 (P1): cleanup_boss() no reseteaba estado de boss en pool
- **Archivo:** `scripts/enemies/EnemyAttackSystem.gd`
- **Bug:** Al reciclar un boss, `cleanup_boss()` solo limpiaba orbitales/efectos y seteaba `is_boss_enemy = false`, pero dejaba 17+ variables de estado (phase, cooldowns, scaling, enraged, timers, etc.) con valores del boss anterior
- **Fix:** Resetear todos: `boss_scaling_config={}`, `boss_current_phase=1`, `boss_ability_cooldowns={}`, `boss_enraged=false`, `boss_fire_trail_active=false`, `boss_damage_aura_timer=0.0`, `_boss_aura_damage_accumulator=0.0`, `boss_unlocked_abilities=[]`, `boss_combo_count=0`, `boss_combo_timer=0.0`, `boss_global_cooldown=0.0`, `boss_homing_projectile_timer=0.0`, `boss_random_aoe_timer=0.0`, `boss_spread_shot_timer=0.0`, `boss_orbital_spawned=false`, `elite_rage_active=false`

### R9-2 (P2): SimpleProjectile + ChainProjectile ignoran status_duration_mult
- **Archivos:** `scripts/weapons/projectiles/SimpleProjectile.gd`, `scripts/weapons/projectiles/ChainProjectile.gd`
- **Bug:** `_apply_effect()` y `_apply_chain_effect()` usaban `effect_duration` crudo sin aplicar el multiplicador de duración de status del jugador
- **Fix:** Llamar `ProjectileFactory.get_modified_effect_duration(tree, effect_duration)` al inicio de ambas funciones; actualizado las 12 ramas de match en ChainProjectile para usar `mod_duration`

### R9-3 (P2): Boss AOE timer lambda sin guard de enemy freed/reciclado
- **Archivo:** `scripts/enemies/EnemyAttackSystem.gd`
- **Bug:** `_boss_spawn_random_aoe()` crea timer de 1.8s cuya lambda solo verificaba `is_instance_valid(player)`, no el enemy — si el boss moría/reciclaba durante el delay, la lambda usaba el enemy reciclado como source del daño
- **Fix:** Capturar `_aoe_enemy_ref`, añadir guards `is_instance_valid(_aoe_enemy_ref)` y `is_boss_enemy`

---

## Patrones Sistémicos Identificados

### 1. Pool Reuse sin Reset Completo
El patrón más recurrente. Enemigos, monedas, y projectiles se reciclan desde pools pero sus estados internos no se reseteaban:
- `_is_dead`, `_is_collected` flags
- Status effects (burn, freeze, slow, etc.)
- Archetype state (is_phased, is_charging, collision layers)
- Timer lambdas capturando `self` sin generation guard

### 2. Arquitectura Split PlayerStats ↔ GlobalWeaponStats
Bonuses añadidos a PlayerStats (Turret Mode, Growth) eran invisibles para armas que leen exclusivamente de GlobalWeaponStats. Requirió inyección explícita en `AttackManager._get_combined_global_stats()`.

### 3. DamageCalculator Bypass
Múltiples rutas de daño (chain, orbital, DoT) aplicaban daño crudo sin pasar por el pipeline centralizado, perdiendo crit, bleed, status effects, audit logging.

### 4. Tweens/Timers vinculados al nodo incorrecto
Tweens creados con `create_tween()` en `self` que animaban nodos hijos → persistían después de la destrucción del hijo.

---

## Round 10 — Commit `6613d35d`

### R10-1 (P0): LootManager current_scene.get_tree() crash
- **Archivo:** `scripts/managers/LootManager.gd`
- **Bug:** `Engine.get_main_loop().current_scene.get_tree()` — `Engine.get_main_loop()` ya ES el SceneTree; `.current_scene` puede ser `null` durante transiciones → crash
- **Fix:** Usar `Engine.get_main_loop() as SceneTree` directamente (2 call sites)

### R10-2 (P1): ProjectileFactory AOEEffect resource leak
- **Archivo:** `scripts/weapons/ProjectileFactory.gd`
- **Bug:** AOEEffect con `_use_enhanced=true` (ruta VFXManager) nunca ejecuta `queue_free()` — `_process()` sale antes del check de lifetime cuando se usa visual enhanced
- **Fix:** Añadir `await create_timer(duration + 0.5).timeout` + `queue_free()` con guard `is_instance_valid`

### R10-3 (P2): BaseWeapon sin propiedad rarity
- **Archivo:** `scripts/weapons/BaseWeapon.gd`
- **Bug:** No se propagaba `rarity` de WeaponDatabase → todas las armas mostraban "Common" en Pause Menu
- **Fix:** Añadir `var rarity = "common"`, extraer de datos de WeaponDatabase, override `"legendary"` para fusiones

---

## Round 11 — Commit `e416d0cc`

### R11-1 (P1): VFXManager DEBUG_VFX left enabled
- **Archivo:** `scripts/core/VFXManager.gd`
- **Bug:** `DEBUG_VFX = true` dejado activo → print() spam en cada VFX spawn (cientos/segundo)
- **Fix:** `DEBUG_VFX = false`

### R11-2 (P2): GameHUD _process running without boss
- **Archivo:** `scripts/ui/GameHUD.gd`
- **Bug:** `show_boss_bar()` activa `set_process(true)` pero nunca se desactiva → _process corre cada frame innecesariamente
- **Fix:** `set_process(false)` en `_ready()` y `hide_boss_bar()`

### R11-3 (P2): WaveManager phase transition stale wave state
- **Archivo:** `scripts/managers/WaveManager.gd`
- **Bug:** `_enter_phase()` reseteaba wave_sequence/index pero no wave_in_progress ni enemies_to_spawn_in_wave
- **Fix:** Resetear ambos en transición de fase

---

## Round 12 — Commit `a6be276c`

### R12-1 (P0): UIVisualHelper confetti crash
- **Archivo:** `scripts/ui/UIVisualHelper.gd`
- **Bug:** `timer.timeout.connect(particles.queue_free)` — particles puede liberarse antes del timer → crash
- **Fix:** Lambda con `is_instance_valid(particles)` guard

### R12-2 (P1): GameOverScreen total damage ignora audit data
- **Archivo:** `scripts/ui/GameOverScreen.gd`
- **Bug:** `_get_total_damage_dealt()` verificaba `_run_active` que es `false` al llegar a Game Over → siempre usaba fallback; porcentajes por arma no coincidían con total
- **Fix:** Eliminar check de `_run_active`, alinear con `_get_weapon_audit_stats()`

### R12-3 (P1): Reroll cost exponencial incluye rerolls gratuitos
- **Archivo:** `scripts/ui/LevelUpPanel.gd`
- **Bug:** Con 2 rerolls gratis usados, primer reroll de pago costaba `10×2²=40` en vez de `10×2⁰=10` — free rerolls inflaban el exponente
- **Fix:** Capturar `_initial_free_rerolls` al abrir panel; restar en 3 puntos de cálculo de coste

---

## Round 13 — Commit `a4d22e04`

### R13-1 (P1): WizardPlayer cast_spell() permite mana negativo
- **Archivo:** `scripts/entities/players/WizardPlayer.gd`
- **Bug:** `cast_spell()` restaba mana sin verificar si hay suficiente → mana negativo
- **Fix:** Calcular coste primero, return si `mana < cost`, luego restar

### R13-2 (P2): MagicProjectile glow_tween conflicto con destroy tween
- **Archivo:** `scripts/magic/LoopiaLikeMagicProjectile.gd`
- **Bug:** `glow_tween` (loop infinito) animaba `sprite.modulate` mientras destroy tween intentaba fade de la misma propiedad
- **Fix:** `glow_tween.kill()` antes de crear el tween de destrucción

### R13-3 (P1): UIManager close_current_modal() crash en modal freed
- **Archivo:** `scripts/core/UIManager.gd`
- **Bug:** `modal_stack` podía contener nodos liberados; acceso a `.name` sin guard → crash
- **Fix:** Guard `is_instance_valid(modal)` con cleanup de estado y procesamiento de cola

---

## Ronda 14 — Deep Scan de archivos grandes

> Archivos escaneados en profundidad:
> - EnemyAttackSystem.gd (4805 líneas, COMPLETO — 20+ timer callbacks verificados)
> - PauseMenu.gd (2825 líneas, COMPLETO — UI only, sin bugs lógicos)
> - RankingScreen.gd (2526 líneas, COMPLETO — UI only, sin bugs lógicos)
> - CharacterSelectScreen.gd (878 líneas, COMPLETO — UI only)
> - ProjectileVisualManager.gd (1597 líneas, COMPLETO — config data + functions)
> - ArenaManager.gd (1480 líneas, COMPLETO — zone/barrier management)
> - EnemyAbility_*.gd (8 archivos, guards verificados)
> - EnemyProjectile.gd (415 líneas, guards verificados)
> - ChestSpawner.gd, EnemyPool.gd, VFXPool.gd, PickupPool.gd (guards verificados)
> - DifficultyManager.gd, SpawnBudgetManager.gd, GlobalWeaponStats.gd, GameCamera.gd (sin timers)

### R14-1 (P1): _spawn_meteor_impact() usa enemy sin is_instance_valid en timer callback
- **Archivo:** `scripts/enemies/EnemyAttackSystem.gd`
- **Línea:** 4707
- **Bug:** `_spawn_meteor_impact()` usa `enemy` directamente en `player.take_damage(damage, "fire", enemy)` sin verificar `is_instance_valid(enemy)`. Esta función es llamada desde un timer callback en `_boss_meteor_call()` (línea 2786) via `create_timer(delay + i * 0.2)`, por lo que `enemy` puede estar freed cuando el timer se dispara. Todos los demás 20+ timer callbacks en el archivo ya tienen guards correctos.
- **Fix:** `var source = enemy if is_instance_valid(enemy) else null; player.take_damage(damage, "fire", source)` — patrón ya establecido en `_spawn_damage_zone()` línea 3999
