# Reporte de Ajuste de Validación de Estados (DoT)

## 1. Resumen de Cambios

### Bug Fixes
- **EnemyBase.gd**: Se corrigió `take_damage` que ignoraba el parámetro `_element` y forzaba "physical". Ahora pasa el elemento correcto a `HealthComponent`.

### Mechanical Oracle (Mejora de Validación)
- **Logica Temporal**: Se añadió soporte para ventanas de tiempo dinámicas en `ItemTestRunner`.
- **Cálculo de DoT**: `verify_simulation_results` ahora calcula el daño esperado por Burn y Bleed:
  - `expected_dot_damage = (damage_per_tick * ticks) * chance_factor`
  - Se añade al total esperado para evitar falsos positivos de "daño excesivo".
- **Breakdown**: La validación ahora retorna un desglose detallado:
  ```json
  "breakdown": {
      "initial_hit_damage": 100,
      "dot_damage_burn": 40,
      "total_damage": 140,
      "window_seconds": 2.0
  }
  ```
- **Medición Real**: Se implementó `track_enemy` con snapshots de HP inicial/final para validación paralela.

### Determinismo
- **RNG**: Se fuerza `seed(1337)` en `ItemTestRunner` para asegurar consistencia en `randf()` global.
- **Ventana Dinámica**: El tiempo de test se ajusta automáticamente:
  - Base: 1.0s
  - AOE: 1.2s
  - BEAM: 1.5s
  - ORBIT: 2.0s
  - Si hay Burn/Bleed: Mínimo 2.0s para capturar ticks.

## 2. Estados Faltantes (GAP Analysis)
Tras revisar `EnemyBase.gd` y `ProjectileFactory.gd`, se confirma que los siguientes estados **NO ESTÁN IMPLEMENTADOS**:
- **Poison (Veneno)**: No existe lógica de tick ni aplicación.
- **Curse (Maldición)**: No existe.

Se deben marcar los items que prometen estos efectos como "NOT SUPPORTED" o implementar la lógica en `EnemyBase`.

## 3. Unit Tests
Se creó `scripts/tests/TestStatusEffects.gd` para validar independientemente que los ticks de Burn y Bleed funcionan en el tiempo esperado (0.5s intervalo).

## 4. Próximos Pasos (Phase 5)
- Ejecutar suite completa con `FULL_MATRIX_ENABLED`.
- Revisar items con "Design Violation" previos; muchos deberían pasar ahora al contar el daño DoT.
- Implementar "Poison" si es necesario para items de naturaleza tóxica.
