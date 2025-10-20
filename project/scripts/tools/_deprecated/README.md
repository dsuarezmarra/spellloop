# Tools Deprecated Scripts

Este directorio contiene scripts de **testing, debugging y desarrollo** que fueron utilizados para verificar sistemas durante el desarrollo pero que NO se ejecutan en el game loop normal.

## Contenido

### Scripts de Testing Manual (Testing-Only)

#### QuickTest.gd
- **Uso**: `godot --headless --script QuickTest.gd`
- **Propósito**: Testing rápido de sistemas core
- **Impacto en juego**: NINGUNO - No se ejecuta en gameplay
- **Puede eliminarse**: ✅ SÍ - Solo testing manual

#### smoke_test.gd
- **Uso**: Testing de carga de scripts
- **Propósito**: Smoke testing - verificar que scripts críticos cargan correctamente
- **Impacto en juego**: NINGUNO
- **Puede eliminarse**: ✅ SÍ - Solo testing manual

#### check_scripts.gd
- **Propósito**: Verificar carga de todos los scripts del proyecto
- **Impacto en juego**: NINGUNO
- **Puede eliminarse**: ✅ SÍ - Solo testing manual

#### check_tscn_resources.gd
- **Propósito**: Auditoría de recursos en archivos .tscn
- **Impacto en juego**: NINGUNO
- **Puede eliminarse**: ✅ SÍ - Solo testing manual

#### test_resource_load.gd
- **Propósito**: Testing de carga de recursos
- **Impacto en juego**: NINGUNO
- **Puede eliminarse**: ✅ SÍ - Solo testing manual

#### test_scene_load.gd
- **Propósito**: Testing de carga de escenas
- **Impacto en juego**: NINGUNO
- **Puede eliminarse**: ✅ SÍ - Solo testing manual

#### test_scene_load_g_main.gd
- **Propósito**: Testing específico de escena principal
- **Impacto en juego**: NINGUNO
- **Puede eliminarse**: ✅ SÍ - Solo testing manual

#### verify_scenes_verbose.gd
- **Propósito**: Versión verbose (detallada) de verificación de escenas
- **Impacto en juego**: NINGUNO - Deprecated en favor de verify_scenes.gd
- **Puede eliminarse**: ✅ SÍ - Versión deprecated

#### _run_main_check.gd
- **Propósito**: Verificación manual de escena principal
- **Impacto en juego**: NINGUNO
- **Puede eliminarse**: ✅ SÍ - Solo testing manual

#### auto_run.gd
- **Uso**: `godot --script auto_run.gd`
- **Propósito**: Ejecutar automáticamente escena principal para testing
- **Impacto en juego**: NINGUNO
- **Puede eliminarse**: ✅ SÍ - Solo testing manual

#### parse_check.gd
- **Propósito**: Verificación de parsing de scripts
- **Impacto en juego**: NINGUNO
- **Puede eliminarse**: ✅ SÍ - Solo testing manual

### Scripts de Debug (Cargados Dinámicamente)

⚠️ **NOTA**: Los siguientes scripts ESTÁN CARGADOS DINÁMICAMENTE desde `SpellloopGame.gd` pero principalmente para debugging. Se pueden considerar deprecados en favor de un sistema de feature flags.

#### WorldMovementDiagnostics.gd
- **Estado**: Activo pero DEBUG
- **Uso**: Diagnóstico continuo de movimiento del mundo
- **Línea de carga**: `SpellloopGame._run_combat_diagnostics()`
- **Impacto**: Bajo - Principalmente telemetría
- **Recomendación**: Puede deshabilitarse via flag en SpellloopGame

#### CombatDiagnostics.gd
- **Estado**: Activo pero DEBUG
- **Uso**: Diagnóstico del sistema de combate
- **Línea de carga**: `SpellloopGame._run_combat_diagnostics()`
- **Impacto**: Bajo - Principalmente telemetría
- **Recomendación**: Puede deshabilitarse via flag

#### CombatSystemMonitor.gd
- **Estado**: Activo pero DEBUG
- **Uso**: Monitor en UI del sistema de combate
- **Línea de carga**: `SpellloopGame.create_ui_layer()`
- **Impacto**: Bajo - Mostrador en pantalla
- **Recomendación**: Puede deshabilitarse via flag

#### QuickCombatDebug.gd
- **Estado**: Activo pero DEBUG
- **Uso**: Debug rápido vía hotkeys (D/P/L)
- **Línea de carga**: `SpellloopGame.create_ui_layer()`
- **Impacto**: Bajo - Controles de debug
- **Recomendación**: Puede deshabilitarse via flag

### Scripts de Verificación

#### verify_scenes.gd
- **Estado**: Cargado dinámicamente por SpellloopGame
- **Uso**: Verificación de que todas las escenas cargan correctamente
- **Línea de carga**: `SpellloopGame._run_verification()`
- **Impacto**: Bajo - Solo al startup si DEBUG
- **Puede deshabilitarse**: ✅ SÍ - Mediante feature flag

## Recomendaciones

### Corto Plazo (Inmediato)
- ✅ Mantener todos como están
- ✅ Solo usar en testing manual via --script

### Mediano Plazo (1-2 versiones)
- 🔄 Implementar sistema de feature flags para debug scripts
- 🔄 Mover verify_scenes.gd a verificación condicional (solo en DEV builds)
- 🔄 Consolidar WorldMovementDiagnostics, CombatDiagnostics, CombatSystemMonitor en un único DebugManager

### Largo Plazo (Futuro)
- 🗑️ Eliminar scripts de testing manual (QuickTest, smoke_test, etc.)
- 🗑️ Consolidar todo debug en un sistema profesional de telemetría
- 🗑️ Implementar comandos de consola in-game para debug

## Impacto de Eliminar

| Script | Crítico | Fácil de Recuperar |
|---|---|---|
| QuickTest.gd | ❌ NO | ✅ SÍ |
| smoke_test.gd | ❌ NO | ✅ SÍ |
| check_scripts.gd | ❌ NO | ✅ SÍ |
| check_tscn_resources.gd | ❌ NO | ✅ SÍ |
| test_resource_load.gd | ❌ NO | ✅ SÍ |
| test_scene_load.gd | ❌ NO | ✅ SÍ |
| test_scene_load_g_main.gd | ❌ NO | ✅ SÍ |
| verify_scenes_verbose.gd | ❌ NO | ✅ SÍ |
| _run_main_check.gd | ❌ NO | ✅ SÍ |
| auto_run.gd | ❌ NO | ✅ SÍ |
| parse_check.gd | ❌ NO | ✅ SÍ |
| WorldMovementDiagnostics.gd | ⚠️ BAJO (debug) | ✅ SÍ |
| CombatDiagnostics.gd | ⚠️ BAJO (debug) | ✅ SÍ |
| CombatSystemMonitor.gd | ⚠️ BAJO (debug) | ✅ SÍ |
| QuickCombatDebug.gd | ⚠️ BAJO (debug) | ✅ SÍ |

## Historial

- **20 Oct 2025**: Archivos deprecated movidos a `_deprecated/` durante auditoría completa
- Ver `docs/audit_report.txt` para detalles completos

---

*Documentación generada: 20 de octubre de 2025*
*Auditoría: Spellloop Code Quality Audit*
