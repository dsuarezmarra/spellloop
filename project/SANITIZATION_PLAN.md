# 🧹 Plan de Sanitización del Proyecto Spellloop

## 📊 Auditoría Actual del Proyecto

### Estado Actual (Después de Testing)
✅ Sistema de popup funcional
✅ Sistema de items operativo
✅ Sistema de cofres implementado
✅ Pero: **Mucho código obsoleto, archivos huérfanos, documentación duplicada**

---

## 🎯 Fases de Sanitización (Ordenadas por Prioridad)

### FASE 1: ANÁLISIS Y MAPEO (Hoy)
- [ ] Listar todos los archivos .gd
- [ ] Identificar archivos no referenciados
- [ ] Mapear escenas activas vs. obsoletas
- [ ] Catalogar documentación duplicada

### FASE 2: LIMPIEZA DE CÓDIGO OBSOLETO (Inmediato)
- [ ] Eliminar archivos .gd no usados
- [ ] Eliminar escenas .tscn no referenciadas
- [ ] Limpiar archivos de test temporales

### FASE 3: SANITIZACIÓN DE DOCUMENTACIÓN (Rápido)
- [ ] Consolidar markdown duplicados
- [ ] Organizar /docs adecuadamente
- [ ] Crear índice de documentación

### FASE 4: OPTIMIZACIÓN DE ESTRUCTURA (Después)
- [ ] Reorganizar carpetas lógicamente
- [ ] Agrupar sistemas relacionados
- [ ] Mejorar nomenclatura

### FASE 5: LIMPIEZA DE ASSETS (Opcional)
- [ ] Audio no utilizado
- [ ] Sprites obsoletos
- [ ] Datos de configuración desactualizados

---

## 📁 FASE 1: ANÁLISIS ACTUAL

### Scripts Potencialmente Obsoletos (a verificar)
```
scripts/core/
  ├─ AudioManager.gd          → ¿Usado?
  ├─ AudioManagerSimple.gd    → ¿Duplicado?
  ├─ LocalizationManager.gd   → ¿Vs. Localization.gd?
  ├─ ScaleManager.gd          → ¿Usado?
  └─ ...otros managers

scripts/entities/
  ├─ Entity.gd                → Base class ¿Usada?
  ├─ Player.gd                → ¿Vs. SimplePlayer/SimplePlayerIsaac?
  ├─ SimplePlayer.gd          → Múltiples versiones?
  ├─ SimplePlayerIsaac.gd     → ¿Coexisten?
  ├─ SimpleEnemy.gd           → Múltiples versiones?
  └─ SimpleEnemyIsaac.gd      → ¿Coexisten?

scripts/test/
  ├─ (¿Archivos de test que deberían estar en /scenes/test/)
  └─ Múltiples archivos de testing
```

### Escenas Potencialmente Obsoletas
```
scenes/
  ├─ characters/Player.tscn       → ¿Usada? (vs code setup)
  └─ test/CleanRoomTest.tscn      → ¿Para testing? ¿Mantener?
```

### Documentación Duplicada/Obsoleta
```
project/
  ├─ DUNGEON_SYSTEM_README.md
  ├─ DUNGEON_SYSTEM_READY.md
  ├─ ERRORES_CORREGIDOS.md
  ├─ ROOM_SYSTEM_ISAAC.md
  ├─ POPUP_DEBUG_FIXES.md         ← RECIENTE (mantener para referencia)
  ├─ FIX_POPUP_BUTTONS_SUMMARY.md ← RECIENTE (consolidar)
  ├─ TESTING_CHECKLIST.md         ← RECIENTE (consolidar)
  └─ ...muchos más (.md files)

docs/
  ├─ actualizacion-dimensiones.md
  ├─ colision-borde-absoluto.md
  ├─ colision-ultra-fina.md
  ├─ dimensiones-sistema.md
  ├─ isaac-system-status.md
  ├─ paredes-optimizadas.md
  ├─ problema-solucionado.md
  ├─ texturas-magicas.md
  └─ (Archivos técnicos/históricos)
```

### Archivos PowerShell Auxiliares
```
project/
  ├─ final_background_cleaner.ps1        → ¿Necesario?
  ├─ remove_background_smart.ps1         → ¿Necesario?
  ├─ run_game.bat                        → Mantener (lanzador)
  ├─ run_spellloop.ps1                   → ¿Duplicado?
  └─ validate_project.ps1 / .py          → ¿Necesario?

root/
  └─ run_collision_test.ps1              → ¿Obsoleto?
```

---

## 🔍 AUDITORÍA DETALLADA NECESARIA

### Paso 1: Identificar código no referenciado
```bash
# Archivos .gd huérfanos:
- Buscar cada .gd en todo el codebase
- Si no aparece en ningún .tscn, .gd o autoload → HUÉRFANO
```

### Paso 2: Mapear jerarquía de escenas
```
main.tscn (o la escena principal activa)
  └─ Hace referencia a qué scripts/escenas?
     └─ Cuál es la cadena completa de dependencias?
```

### Paso 3: Catalogar documentación
```
¿Documento describe qué sistema?
¿Está obsoleto (mencionan código que ya no existe)?
¿Es histórico (fue una solución que luego cambió)?
¿Debe consolidarse con otro?
```

---

## 🗑️ ARCHIVOS PROBABLES A ELIMINAR

### Con ALTA Confianza (99%)
```
project/
├─ ERRORES_CORREGIDOS.md              (Histórico)
├─ run_collision_test.ps1             (A nivel root, parece test)
├─ final_background_cleaner.ps1       (Scripts de procesamiento de assets)
├─ remove_background_smart.ps1        (Scripts de procesamiento de assets)
└─ icon.svg.import                    (Archivo de importación de Godot)

root/
└─ run_collision_test.ps1
```

### Con MEDIA Confianza (70%)
```
scripts/entities/
├─ SimplePlayer.gd                    (¿vs SimplePlayerIsaac?)
├─ SimpleEnemy.gd                     (¿vs SimpleEnemyIsaac?)
└─ Player.gd                          (¿vs SimplePlayer/SimplePlayerIsaac?)

scripts/core/
├─ AudioManagerSimple.gd              (¿vs AudioManager?)
└─ LocalizationManager.gd             (¿vs Localization?)

scripts/test/
├─ (Verificar si son realmente necesarios)
```

### Con BAJA Confianza (40%)
```
scripts/core/
├─ ScaleManager.gd                    (Usado en inicialización?)
└─ InputManager.gd                    (¿Redundante vs InputMap?)

scenes/test/
└─ CleanRoomTest.tscn                 (¿Para debugging? ¿Mantener?)
```

---

## 📚 DOCUMENTACIÓN A REORGANIZAR

### Mantener en ROOT
```
/project/
├─ README.md (o crear uno)
├─ CHANGELOG.md
└─ DEVELOPMENT_SETUP.md
```

### Mover a /docs/
```
/docs/
├─ SYSTEMS/
│  ├─ dungeon-system.md
│  ├─ chest-system.md
│  ├─ item-system.md
│  ├─ spell-system.md
│  └─ combat-system.md
├─ ARCHITECTURE/
│  ├─ folder-structure.md
│  ├─ signal-flow.md
│  └─ scene-hierarchy.md
├─ GUIDES/
│  ├─ adding-new-items.md
│  ├─ adding-new-spells.md
│  ├─ testing-checklist.md
│  └─ debugging-tips.md
└─ HISTORY/
   ├─ solutions-to-known-issues.md
   └─ archived-attempts.md
```

### Archivar en /docs/ARCHIVED/
```
/docs/ARCHIVED/
├─ colision-borde-absoluto.md
├─ colision-ultra-fina.md
├─ problema-solucionado.md
└─ texturas-magicas.md
```

---

## 🔧 ESTRATEGIA DE LIMPIEZA

### OPCIÓN A: Agresiva (Recomendada)
1. Eliminar archivos huérfanos confirmados (99%)
2. Consolidar duplicados (70%)
3. Reorganizar documentación
4. **Tiempo:** 1-2 horas
5. **Riesgo:** Bajo (verificamos antes de borrar)

### OPCIÓN B: Conservadora
1. Solo eliminar lo más obvio (99%)
2. Mover a carpeta `/DEPRECATED/` lo dudoso
3. Reorganizar documentación
4. **Tiempo:** 30 minutos
5. **Riesgo:** Mínimo (nada se pierde)

### OPCIÓN C: Refactorización Completa
1. Todo lo anterior +
2. Renombrar scripts con nomenclatura coherente
3. Reorganizar folders por feature
4. **Tiempo:** 4-6 horas
5. **Riesgo:** Medio (requiere testing exhaustivo)

---

## ⚙️ MIS RECOMENDACIONES

### AHORA (30 minutos)
**Haz:** Crear análisis automatizado

```bash
# Script para encontrar archivos no referenciados
# Verificar qué .gd/tscn se usan realmente
```

### LUEGO (1-2 horas)
**Haz:** OPCIÓN B (Conservadora)
- Eliminar lo obvio
- Mover lo dudoso a `/DEPRECATED/`
- Consolidar documentación

**Razón:** Buen balance entre limpieza y seguridad

### FINALMENTE (4-6 horas, cuando sea necesario)
**Haz:** OPCIÓN C (Refactorización)
- Reorganizar completamente
- Mejorar nomenclatura
- Crear estructura profesional

---

## 📋 MIS PREGUNTAS ANTES DE CONTINUAR

1. **¿Cuál es la escena principal del juego?** 
   - main.tscn, spellloop.tscn, ¿otra?
   - Esto es crítico para mapear dependencias

2. **¿Qué sistemas son CRÍTICOS?**
   - Dungeon: ¿Activo o histórico?
   - Room system: ¿Activo o histórico?
   - Isaac system: ¿Qué es?

3. **¿Quieres mantener escenas de test?**
   - CleanRoomTest.tscn, test scripts, etc.
   - ¿O eliminar completamente?

4. **¿Scripts de procesamiento de assets?**
   - Los .ps1 de background removal
   - ¿Necesarios o basura?

5. **¿Audio y visuals?**
   - ¿Hay assets no usados?
   - ¿O todo se está usando?

---

## 🚀 SIGUIENTE PASO (RECOMENDADO)

Te propongo hacer esto **AHORA**:

```
1. Analizar proyecto automáticamente
   - Encontrar archivos .gd no referenciados
   - Encontrar escenas no referenciadas
   - Crear reporte de duplicados

2. Mostrar resultados
   - "Estos archivos son 100% seguros eliminar"
   - "Estos son probables duplicados"
   - "Estos son históricos/documentación"

3. Decidir juntos
   - Qué eliminar
   - Qué mover a DEPRECATED
   - Qué reorganizar
```

---

## 📊 ESTIMACIONES

| Tarea | Tiempo | Dificultad |
|-------|--------|-----------|
| Análisis automatizado | 15 min | ⭐ |
| Eliminar (99% confianza) | 15 min | ⭐ |
| Consolidar documentación | 30 min | ⭐⭐ |
| Reorganizar folders | 1 hora | ⭐⭐ |
| Testing después de cambios | 1 hora | ⭐⭐⭐ |
| **TOTAL (OPCIÓN B)** | **2 horas** | **⭐⭐** |

---

## ✅ CHECKLIST FINAL

Después de sanitización:
- [ ] Sin archivos .gd huérfanos
- [ ] Sin documentación duplicada
- [ ] Folder structure clara y coherente
- [ ] Nombres de archivos consistentes
- [ ] Solo código activo/necesario
- [ ] Testing pasa sin problemas
- [ ] Proyecto está 30-40% más pequeño

---

**¿Qué prefieres?**
1. **Análisis completo** (me dices qué encontramos)
2. **Limpieza agresiva** (OPCIÓN A - borro lo obvio)
3. **Limpieza conservadora** (OPCIÓN B - menos riesgo)
4. **Otra estrategia**

**Recomendación:** Empezar con **Análisis** para ver qué tenemos exactamente.
