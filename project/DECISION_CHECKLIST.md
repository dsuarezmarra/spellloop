# 🔑 DECISIONES NECESARIAS - Checklist para la Sanitización

## Contesta estas preguntas para que podamos proceder:

---

## ❓ PREGUNTA 1: DUNGEON SYSTEM

**El sistema Dungeon/Room aparece en estos archivos:**
```
RoomScene.gd
RoomManager.gd
RoomTransitionManager.gd
RoomData.gd
RewardSystem.gd
DungeonSystem.gd
DungeonGenerator.gd
```

**¿Cuál es tu intención?**

- [ ] **A) MANTENER** - Está activo, lo necesitaré en el futuro
- [ ] **B) ARCHIVAR** - Es histórico, no lo uso, pero podría necesitarlo
- [ ] **C) ELIMINAR** - Ya no lo necesito, bórralo todo

---

## ❓ PREGUNTA 2: TEST SCRIPTS

**Los scripts de test que se eliminarían:**
```
TestParserFix.gd
TestItemsDefinitions.gd
TestEmptyFix.gd
SimpleRoomTest.gd
CleanRoomSystem.gd
WallSystemTest.gd
UltraFineCollisionTest.gd
GameTester.gd
test_spellloop.gd
test_dungeon_quick.gd
syntax_test.gd
```

**¿Qué prefieres?**

- [ ] **A) ELIMINAR TODO** - No los necesito
- [ ] **B) MOVER A DEPRECATED** - Podría revisarlos luego
- [ ] **C) MANTENER EN SCRIPTS** - Los uso regularmente

---

## ❓ PREGUNTA 3: SCENES OBSOLETAS

**Scenes que se eliminarían:**
```
scenes/characters/Player.tscn        (Antigua, usas código)
scenes/test/CleanRoomTest.tscn
scenes/test/SpellloopTest.tscn
scenes/test/TestScene.tscn
scenes/ui/ChestPopup.tscn           (Usas SimpleChestPopup)
```

**¿Confirmas?**

- [ ] **SÍ** - Eliminar todas
- [ ] **NO** - Mantener "por si acaso"
- [ ] **PARCIAL** - Dejar algunas (cuáles?)

---

## ❓ PREGUNTA 4: DOCUMENTACIÓN

**Markdown históricos que se moverían a /docs/ARCHIVED/:**
```
DUNGEON_SYSTEM_README.md
DUNGEON_SYSTEM_READY.md
ERRORES_CORREGIDOS.md
ROOM_SYSTEM_ISAAC.md
+ contenido en /docs/ técnico antiguo
```

**¿Y los RECIENTES que MANTENEMOS en /docs/SYSTEMS/:**
```
POPUP_DEBUG_FIXES.md
FIX_POPUP_BUTTONS_SUMMARY.md
TESTING_CHECKLIST.md
SOLUTION_EXPLAINED.md
VISUAL_SUMMARY.md
```

**¿Está bien así?**

- [ ] **SÍ** - Perfecto
- [ ] **NO** - Cambiar algo (qué?)
- [ ] **NO SÉ** - Explicaré lo que necesito

---

## ❓ PREGUNTA 5: POWERTOOLS

**Scripts auxiliares:**
```
project/run_spellloop.ps1            (Redundante con run_game.bat?)
project/validate_project.ps1         (¿Lo usas?)
project/validate_project.py          (¿Lo usas?)
root/run_collision_test.ps1          (Test antiguo, eliminar)
project/final_background_cleaner.ps1 (¿Lo usas?)
project/remove_background_smart.ps1  (¿Lo usas?)
```

**¿Cuáles necesitas?**

- [ ] Mantener solo `run_game.bat` (borra el resto)
- [ ] Mantener todos (son útiles)
- [ ] Me da igual (borra los que no uses)

---

## ✅ PREGUNTA 6: CONFIRMACIÓN FINAL

**Después de limpiar, el proyecto tendría:**

- ✅ 70 scripts activos (no 90+)
- ✅ 15 scenes (no 20)
- ✅ 0 archivos en root (orden)
- ✅ Documentación clara en /docs/
- ✅ Sistema DEPRECATED para historiales
- ✅ 25% menos código inútil

**¿Vamos adelante?**

- [ ] **SÍ** - Hazlo ahora
- [ ] **NO** - Espero más
- [ ] **PARCIAL** - Primero esto, luego el resto

---

## 📋 RESPUESTAS RÁPIDAS

Si no quieres escribir mucho, solo escribe:

| Pregunta | Respuesta Rápida |
|----------|------------------|
| 1. Dungeon | A / B / C |
| 2. Tests | A / B / C |
| 3. Scenes | SÍ / NO / PARCIAL |
| 4. Docs | SÍ / NO / PARCIAL |
| 5. Tools | Opción 1, 2, o 3 |
| 6. Adelante | SÍ / NO / PARCIAL |

Ejemplo:
```
1. A (mantener)
2. B (mover a deprecated)
3. SÍ (eliminar todas)
4. SÍ (está bien)
5. Opción 1 (solo run_game.bat)
6. SÍ (vamos adelante)
```

---

## 🎯 TIMELINE

**Dependiendo de tus respuestas:**

- Si responder 15-20 min
- Si confirmas TODO: 1.5 horas ejecución
- Si hay dudas: 3-4 horas (más cautela)

---

## 🚀 LISTO CUANDO TÚ DIGAS

Contesta estas preguntas y empezamos inmediatamente.

Espero tus respuestas 👇
