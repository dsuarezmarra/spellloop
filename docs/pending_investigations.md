# Pending Investigations — Post-Auditoría

> Bugs de baja prioridad, posibles mejoras o áreas que requieren revisión manual (testing en juego).

---

## P2 Dejados Pendientes

### INV-1: Soft cap damage_mult vestigial en PlayerStats
- **Archivo:** `scripts/core/PlayerStats.gd` (función `get_stat`)
- **Descripción:** `get_stat("damage_mult")` tiene lógica de soft cap pero las armas no leen de PlayerStats. El soft cap solo afectaría a daño de contacto del player (si existe).
- **Acción:** Verificar si hay rutas de daño que lean `damage_mult` de PlayerStats directamente. Si no, el soft cap es código muerto.
- **Prioridad:** Baja

### INV-2: Investor/Momentum bonus duplicado latente
- **Archivo:** `scripts/core/PlayerStats.gd`, `scripts/core/AttackManager.gd`
- **Descripción:** `get_dynamic_damage_bonus()` calcula el bonus y se inyecta en AttackManager. Pero `get_stat("damage_mult")` también añade el mismo bonus inline. Si alguna ruta de daño lee de ambas fuentes, habría duplicación.
- **Acción:** Auditar todas las rutas de daño que lean `damage_mult` de PlayerStats vs GlobalWeaponStats.
- **Prioridad:** Baja

### INV-3: LoopiaLikeMagicProjectile (código muerto)
- **Archivo:** `scripts/magic/` (si existe)
- **Descripción:** `class_name LoopiaLikeMagicProjectile` declarado pero nunca instanciado por ningún otro script.
- **Acción:** Confirmar si es código legacy que puede eliminarse.
- **Prioridad:** Muy baja

### INV-4: _on_warning_cleanup() ahora sin caller
- **Archivo:** `scripts/managers/WaveManager.gd`
- **Descripción:** Tras el fix R7-5, `_on_warning_cleanup()` ya no se llama desde ningún sitio (el cleanup_timer fue eliminado). La función sigue existiendo.
- **Acción:** Eliminar la función muerta en un cleanup pass.
- **Prioridad:** Muy baja

---

## Áreas para Testing Manual

### TEST-1: Turret Mode efectividad
- **Fix R4-2** inyectó +25% damage y +50% atk speed de Turret Mode en AttackManager.
- **Validar:** Comprobar que Turret Mode ahora realmente aumenta DPS de armas.

### TEST-2: Growth scaling en armas
- **Fix R4-3** inyectó weapon stats de Growth en AttackManager.
- **Validar:** Comprobar que tras pasar varios minutos, las armas escalan correctamente con Growth.

### TEST-3: Orbital Overheat
- **Fix R7-1** reactivó el sistema de Orbital Overheat.
- **Validar:** Comprobar que con orbitales equipados, cerca de enemigos, el player recibe chip damage periódico. Verificar que el balance de daño es razonable.

### TEST-4: DoT consistencia
- **Fix R4-1** hizo que DoT sea pre-mitigado (no esquivable, no reducido por armadura).
- **Validar:** Comprobar que burn/poison ticks siempre aplican el daño correcto sin interacción con dodge/armor/shield.

### TEST-5: Save slot vacío
- **Fix R7-6** inicializa slots vacíos con datos por defecto.
- **Validar:** Crear nuevo save, seleccionar slot vacío, verificar que todo funciona correctamente.

### TEST-6: Boss particle cleanup
- **Fix R7-2** añadió `_exit_tree()` cleanup para partículas de boss.
- **Validar:** Matar varios bosses en una partida, verificar que no se acumulan nodos huérfanos (Monitor → Objects → Node count debería estabilizarse).

---

## Notas Arquitecturales

### Recomendación: Centralizar daño via DamageCalculator.apply_damage_with_effects()
Tres rondas de fixes (R1-7, R6-1, R6-2) corrigieron bypasses del pipeline centralizado. Se recomienda:
1. Documentar que **toda nueva ruta de daño** debe usar `DamageCalculator.apply_damage_with_effects()`
2. Crear un lint/grep CI check que detecte llamadas directas a `take_damage()` fuera de DamageCalculator

### Recomendación: Pool Reset Checklist
Cada nuevo tipo que se recicle desde pools debe implementar un reset completo. Checklist:
- [ ] Todos los flags booleanos (is_dead, is_collected, is_phased, etc.)
- [ ] Todos los timers y cooldowns
- [ ] Generation ID + lambda guards
- [ ] Status effects
- [ ] Collision layers/masks
- [ ] Visual state (modulate, scale, rotation)
