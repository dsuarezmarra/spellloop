# Análisis de Runs - 10 Feb 2026

## Resumen de las 4 runs analizadas

| Run ID | Personaje | Duración (juego) | Nivel | Kills | Score | Killed by |
|--------|-----------|-------------------|-------|-------|-------|-----------|
| 698b1b76 | storm_caller | 1m 55s | 4 | 80 | 3,754 | tier_1_duende_sombrio |
| 698b28af | storm_caller | 2m 52s | 8 | 229 | 7,521 | tier_1_esqueleto_aprendiz |
| 698b41fe | storm_caller | 3m 0s | 8 | 203 | 7,497 | tier_1_murcielago_etereo |
| 698b44f2 | storm_caller | 1m 55s | 6 | 131 | 4,907 | tier_1_esqueleto_aprendiz |

## Observaciones de Gameplay

### Balance
- **Arma dominante**: `lightning_wand` domina con 89-100% del daño en TODAS las runs. Las armas secundarias (`shadow_dagger`, `arcane_orb`) contribuyen menos del 11%.
- **Supervivencia corta**: Todas las runs terminan entre el minuto 2 y 3 de juego. El jugador nunca llega a Phase 2.
- **Sin bosses**: 0 bosses killed en 4 runs. 1-2 élites encontrados (élites de duende_sombrio y murcielago_etereo).
- **0 cofres abiertos**: En 4 runs consecutivas, ningún cofre normal/élite/boss fue abierto.
- **0 fusiones**: Ninguna fusión obtenida.
- **0 rerolls** (excepto 1 en run 698b44f2).
- **Healing: 0**: hp_regen y life_steal son 0 en todas las builds. Sin fuentes de curación.

### Muerte típica
- Muerte por daño melee de un tier_1 básico (esqueleto, duende, murciélago).
- Ventanas de daño de 1-4 hits en 0-3 segundos — el jugador no tiene tiempo de reaccionar.
- Daño del esqueleto_aprendiz: 6-32 por hit (32 es excesivo para un tier_1 básico).

### Performance
- 0 spikes de 33ms o 66ms en TODAS las runs — performance impecable.

---

## Bugs Detectados y Corregidos

### Bug Crítico: Pantalla Púrpura/Magenta al recibir daño

**Síntoma**: La pantalla se cubre completamente de púrpura/magenta cuando enemigos dark/void/arcane (élites o bosses) golpean al jugador, haciendo imposible jugar.

**Causas raíz (RONDA 3)**:

1. **`BasePlayer._play_damage_flash()`** — El sprite del jugador (z_index 50) se teñía con `Color(1.0, 0.5, 1.0)` = magenta puro a alpha completo + valores HDR (2.0) en otros colores.
   - **Fix**: Eliminados valores HDR, dark/void/shadow cambiado a lavanda suave `Color(0.8, 0.6, 0.8)`, duración reducida 0.2→0.15s.

2. **`BasePlayer._apply_status_flash()`** — Curse (`Color(0.6, 0.4, 0.7)`) y weakness (`Color(0.8, 0.5, 0.9)`) parpadeaban púrpura continuamente durante SEGUNDOS cuando activos, con threshold `> 0` (50% del tiempo en púrpura).
   - **Fix**: Colores cambiados a lavanda suave, threshold subido a `> 0.3` (menos tiempo púrpura), frecuencia de pulso `3.0 → 4.0`.

3. **`EnemyAttackSystem._spawn_boss_impact_effect()`** — Ondas de choque con alpha 0.6 y cruz con alpha 0.7 — excesivamente opacos.
   - **Fix**: Wave alpha 0.6→0.25, cross alpha 0.7→0.3, grosor de líneas reducido.

4. **`VFX_AOE_Impact._draw_fallback()`** — Color HARDCODEADO a púrpura `Color(0.8, 0.3, 1)` para TODOS los fallbacks AOE, sin importar el elemento.
   - **Fix**: Cambiado a naranja/blanco neutro `Color(1.0, 0.6, 0.3)`, radius clamped a 150px máx, reducidas capas de 3 a 2.

5. **`_spawn_void_explosion_visual()`** — Radio sin clamp (multiplicador 1.3×), 6+ capas de púrpura con alphas que sumados cubrían la pantalla.
   - **Fix**: Radius clamped a 120px máx, capas reducidas, alphas reducidos 50-70%, partículas reducidas.

6. **`_get_element_color()` en EnemyAttackSystem** — Dark `Color(0.6, 0.1, 0.9, 0.4)` y arcane `Color(0.9, 0.3, 1.0, 0.4)` eran muy saturados y con alpha 0.4.
   - **Fix**: Dark → `Color(0.5, 0.2, 0.7, 0.25)`, arcane → `Color(0.7, 0.3, 0.9, 0.25)`. Alpha reducido 0.4→0.25.

7. **`EnemyProjectile._get_element_color()`** — Dark `Color(0.6, 0.15, 0.9)` y arcane `Color(0.9, 0.3, 1.0)` muy brillantes.
   - **Fix**: Dark → `Color(0.5, 0.3, 0.7)`, arcane → `Color(0.7, 0.4, 0.9)`. Escala de sprite 0.5→0.35, modulate alpha 1.0→0.7.

8. **`VFXManager._spawn_fallback_beam()`** — Color default `Color(0.8, 0.2, 1)` = púrpura, grosor 8+16px, alpha completo.
   - **Fix**: Default cambiado a naranja `Color(1.0, 0.6, 0.2)`, alpha total ×0.6, z_index 8→5, grosor 6+12px.

9. **`VFXManager._get_beam_color()`** — void/dark beams: `Color(0.6, 0.15, 0.9)`, arcane: `Color(0.9, 0.3, 1.0)`.
   - **Fix**: void/dark → `Color(0.5, 0.25, 0.7)`, arcane → `Color(0.7, 0.35, 0.9)`.

10. **`_spawn_aoe_visual()` sin clamp de radius** — `actual_radius = radius * size_mult` sin límite.
    - **Fix**: `actual_radius = minf(radius * size_mult, 150.0)`.

### Bugs de Telemetría (5 fixes)

| Bug | Archivo | Causa | Fix |
|-----|---------|-------|-----|
| `score_final: 0` | BalanceTelemetry.gd | Lee `"score_final"` pero contexto usa `"score_total"` | Cambiar a `context.get("score_total", 0)` |
| `xp_earned_total: 0` | ExperienceManager.gd | Guard `BalanceDebugger.enabled` (false por defecto) | Eliminar `.enabled` del guard |
| `level t_min: 0.0` | ExperienceManager.gd | Grupo `"game"` no existe + propiedad `run_time` no existe | Usar `current_scene.game_time` |
| Upgrade `id: "unknown"` | UpgradeAuditor.gd | Fallback solo a "unknown", no intenta campo `name` | Fallback chain: `id` → `name` → `"unknown"` |
| `starting_weapons: []` | Game.gd | Race condition: lee weapons antes de `await` del equip | `call_deferred("_start_balance_telemetry")` |

---

## Archivos Modificados

| Archivo | Cambios |
|---------|---------|
| `BasePlayer.gd` | Flash daño: colores sin HDR, dark→lavanda; Status flash: curse/weakness→lavanda, threshold 0.3 |
| `EnemyAttackSystem.gd` | Boss impact: alphas reducidos; Void explosion: radius clamp 120, capas-; AoE visual: radius clamp 150; Element colors: alpha 0.4→0.25 |
| `EnemyProjectile.gd` | Element colors suavizados; Hit effect: escala 0.5→0.35, modulate alpha 0.7 |
| `VFXManager.gd` | Beam fallback: default naranja, alpha ×0.6, z_index 5; Beam colors: void/arcane suavizados |
| `VFX_AOE_Impact.gd` | Fallback: color naranja/blanco en vez de púrpura, radius clamp 150, 2 capas |
| `BalanceTelemetry.gd` | score_final key fix |
| `ExperienceManager.gd` | XP tracking guard fix, level timeline time fix |
| `UpgradeAuditor.gd` | Upgrade ID fallback chain |
| `Game.gd` | starting_weapons race condition fix |
