# Testing & CI — Loopialike

## Estructura

```
tests/
  test_smoke.gd              # Smoke tests: autoloads, escenas, datos
  test_math_sanity.gd        # Sanity tests: JSON, escenas, matemáticas
  test_gameplay_integration.gd # Integración: GameManager, pools, databases
  autopilot/
    AutopilotRunner.gd       # Bot que juega partidas reales en headless

scripts/ci/
  run_gut_headless.sh         # Ejecuta todos los tests GUT
  smoke_headless.sh           # Ejecuta solo smoke tests
  autopilot_headless.sh       # Ejecuta el autopiloto de gameplay

.github/workflows/ci.yml     # GitHub Actions pipeline
```

## Ejecutar tests localmente

### Prerequisitos
- Godot 4.5.1 en PATH (o exportar `GODOT_BIN`)
- GUT instalado en `project/addons/gut/`

### Tests GUT (todos)
```bash
cd project
godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit -glog=2 -gignore_pause -ginclude_subdirs
```

### Solo smoke tests
```bash
cd project
godot --headless -s res://addons/gut/gut_cmdln.gd -gtest=res://tests/test_smoke.gd -gexit
```

### Autopiloto (simula 2 partidas de 2 minutos cada una)
```bash
cd project
godot --headless -s res://tests/autopilot/AutopilotRunner.gd -- --autopilot-runs=2 --autopilot-duration=120
```

Parámetros del autopiloto:
- `--autopilot-runs=N` — Número de partidas a simular (default: 2)
- `--autopilot-duration=N` — Duración en segundos por partida (default: 120)
- `--autopilot-headless=true` — Modo headless (default: true)

## CI Pipeline

El pipeline de GitHub Actions (`.github/workflows/ci.yml`) ejecuta en cada push/PR:

1. **Setup**: Descarga Godot 4.5.1 headless
2. **Import**: Importa recursos del proyecto
3. **GUT Tests**: Ejecuta todos los tests unitarios
4. **Smoke Tests**: Verifica que autoloads y escenas cargan
5. **Autopiloto**: Simula 2 partidas completas monitorizando:
   - Orphan nodes (leak detection)
   - Object count growth rate
   - Enemy count overflow
   - Player HP negative
   - Crashes/errores de GDScript
   - Auto-selección de upgrades en level-ups

## Qué monitoriza el autopiloto

| Check | Descripción | Umbral |
|-------|-------------|--------|
| Orphan nodes | Nodos sin padre en el árbol | >200 = warning |
| Object growth | Tasa de crecimiento de objetos | >20/s = warning |
| Enemy overflow | Enemigos activos simultáneos | >500 = warning |
| Negative HP | HP del jugador < 0 | Cualquier caso = error |
| Game Over | Detecta pantalla de Game Over | Informativo |

## Reporte

El autopiloto genera `user://autopilot_report.json` con datos detallados de cada run:
- Duración, frames, level-ups manejados
- Errores y warnings con timestamps
- Samples de object count y orphan count
- Stats del juego si disponibles
