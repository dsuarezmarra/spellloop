# QA Automation Deliverables - Contract Validation System

**Fecha**: Auto-generado
**Proyecto**: Spellloop (Godot 4.5.1)
**Alcance**: 341 items validados por contrato

---

## 📦 Entregables Implementados

### 1. CalibrationSuite.gd ✅
**Ubicación**: `scripts/debug/item_validation/CalibrationSuite.gd`

Suite de calibración con ~20 items representativos para detectar falsos positivos:

| Categoría | Items | Propósito |
|-----------|-------|-----------|
| **Aditivos** | 5 | Validar `baseline + value = actual` |
| **Multiplicativos** | 5 | Validar `baseline * value = actual` |
| **DoTs** | 3 | Burn, Bleed, Poison timing/damage |
| **Status CC** | 3 | Slow, Freeze, Stun duración |
| **Event Triggers** | 2 | on_hit, on_kill, on_damage_taken |
| **Temporal** | 2 | per_minute scaling |

**Tolerancias Configuradas**:
- Aditivos: ±0.001 (precisión float32)
- Multiplicativos: ±0.01 (error de cadena)
- Daño: ±5% (timing variance)
- Status Duration: ±50ms (physics tick rate)
- Status Ticks: 0 (estricto)

**Uso**:
```gdscript
var suite = CalibrationSuite.new()
var report = suite.run_calibration_suite()
print("Pass rate: %.1f%%" % (report.pass_rate * 100))
```

---

### 2. Simulación de Eventos (ItemTestRunner) ✅
**Ubicación**: `scripts/debug/item_validation/ItemTestRunner.gd`

Funciones añadidas para simular eventos de juego:

| Función | Parámetros | Propósito |
|---------|------------|-----------|
| `simulate_on_hit()` | count, env, item | Simula N impactos |
| `simulate_on_kill()` | count, env, item | Simula N kills |
| `simulate_on_pickup()` | count, env, item | Simula N recogidas |
| `simulate_time_passed()` | seconds, env, item | Simula paso de tiempo |
| `_detect_required_events()` | item | Infiere eventos requeridos |
| `_should_skip_for_events()` | item | Determina si skip es necesario |

**Configuración**:
```gdscript
var event_simulation_enabled: bool = true  # Toggle global
var simulated_hits: int = 10               # on_hit count
var simulated_kills: int = 5               # on_kill count
var simulated_time_seconds: float = 60.0   # time_passed
var simulated_pickups: int = 3             # on_pickup count
```

**Tests SKIPPED**:
Los tests que requieren eventos no simulados se marcan como `SKIPPED` (no `FAIL`):
```
| Item | Scope | Required Events | Reason |
| soul_link | PLAYER_ONLY | on_damage_taken | Event simulation disabled |
```

---

### 3. RNG Determinista ✅
**Ubicación**: `scripts/debug/item_validation/ItemTestRunner.gd`

```gdscript
var deterministic_seed: bool = true  # Habilitar seed fijo
var test_seed: int = 1337            # Seed configurable

# En _ready():
if deterministic_seed:
    seed(test_seed)
else:
    var random_seed = Time.get_ticks_usec()
    seed(random_seed)
    test_seed = random_seed
```

**Reportes incluyen**:
- `test_seed`: Seed usado en la ejecución
- `deterministic_seed`: Si estaba habilitado
- Reproducibilidad garantizada para debugging

---

### 4. ReportWriter - Categoría SKIPPED ✅
**Ubicación**: `scripts/debug/item_validation/ReportWriter.gd`

Nuevas categorías en `generate_contract_validation_report()`:

| Categoría | Emoji | Descripción |
|-----------|-------|-------------|
| PASS | ✅ | Contrato cumplido |
| CONTRACT_VIOLATION | 🟠 | No hace lo que dice |
| SIDE_EFFECT | 🟡 | Efectos no declarados |
| DESIGN_VIOLATION | 🟣 | Valores fuera de tolerancia |
| BUG | 🔴 | Comportamiento inesperado |
| **SKIPPED** | ⏭️ | Requiere eventos no simulados |

---

## 🚀 Ejecución del Full Sweep

### Comando Directo
```powershell
# Desde c:\git\spellloop\project
godot --headless --path . res://scripts/debug/item_validation/TestRunner.tscn --run-full
```

### Script PowerShell (Recomendado)
```powershell
cd c:\git\spellloop\tools
.\run_full_validation.ps1 -Mode full
```

### Modos Disponibles
```powershell
# Quick pilot (25 items)
.\run_full_validation.ps1 -Mode quick

# Por scope específico
.\run_full_validation.ps1 -Mode scope -Scope WEAPON_SPECIFIC

# Con batching
.\run_full_validation.ps1 -Mode full -BatchSize 50 -Offset 100
```

---

## 📊 Reportes Generados

Ubicación: `%APPDATA%\Godot\app_userdata\Spellloop\test_reports\`

| Archivo | Contenido |
|---------|-----------|
| `contract_validation_report_*.md` | Validación completa por contrato |
| `calibration_report_*.md` | Resultados de calibración |
| `full_cycle_report_*.md` | Resumen por scope |
| `item_validation_summary_*.md` | Resumen ejecutivo |
| `index_YYYY-MM-DD.md` | Índice diario de ejecuciones |

---

## 🔧 Fixes de Alta Severidad

### Ya Aplicados (Sesión Anterior)
1. **GlobalWeaponStats.multiply_stat** - Semántica corregida para evitar escalado exponencial
2. **AudioManager music idempotency** - Evita reiniciar track si ya está sonando

### Pendientes (Requiere Full Sweep)
Los bugs de categoría `BUG` y `CONTRACT_VIOLATION` se identificarán tras ejecutar:
```powershell
.\run_full_validation.ps1 -Mode full
```

El reporte generará sección "Action Items" con prioridades P0-P3.

---

## 📋 Checklist de Entrega

- [x] CalibrationSuite.gd con ~20 items representativos
- [x] Simulación de eventos (on_hit, on_kill, on_pickup, time_passed)
- [x] RNG determinista configurable (`deterministic_seed=true`)
- [x] Categoría SKIPPED en reportes con razones
- [x] Documentación de tolerancias con justificación
- [ ] Full Sweep 341 items (pendiente ejecución)
- [ ] Fixes de alta severidad (pendiente resultados)

---

*Documento generado para QA Automation Lead - Spellloop*
