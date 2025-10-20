# 🧪 MANUAL DE PRUEBA Y VALIDACIÓN

## 📋 Pre-Requisitos
- Godot 4.5.1 instalado
- Proyecto Spellloop abierto
- Consola de Godot disponible (F8)

## 🚀 PRUEBA 1: INICIALIZACIÓN BÁSICA

### Pasos
1. Abre SpellloopMain.tscn en Godot
2. Presiona F5 (Play)
3. Observa la consola

### Validación
- [ ] Se ve "🧙‍♂️ Iniciando Spellloop Game..."
- [ ] Se ve "[VisualCalibrator] Inicializando calibrador visual..."
- [ ] Se ve "[DifficultyManager] Inicializado"
- [ ] Se ve "[GlobalVolumeController] Inicializado"
- [ ] Se ve "[DebugOverlay] Inicializado"
- [ ] No aparecen errores rojos en consola

## 🎮 PRUEBA 2: PLAYER Y MOVIMIENTO

### Pasos
1. Observa la pantalla
2. Presiona WASD para mover
3. Observa que el player se queda centrado

### Validación
- [ ] Player aparece en el centro de la pantalla (visualmente)
- [ ] El mundo se desplaza cuando presionas WASD
- [ ] Player NO se mueve de la pantalla
- [ ] Movimiento es inmediato (sin inercia)
- [ ] Animaciones cambian según dirección (arriba/abajo/izquierda/derecha)
- [ ] Barra de vida verde visible arriba del player

## 👹 PRUEBA 3: ENEMIGOS

### Pasos
1. Presiona F5 (durante el juego)
2. Observa si aparecen enemigos

### Validación
- [ ] Aparecen 4 enemigos en los bordes
- [ ] Los enemigos tienen sprites visibles
- [ ] Los enemigos se mueven hacia el player
- [ ] Se ve en consola: "[EnemyManager] Spawned skeleton at..."
- [ ] Enemigos pueden tocarse entre sí

## 🌍 PRUEBA 4: BIOMAS

### Pasos
1. Genera múltiples chunks (muévete bastante)
2. Observa los colores del terreno
3. Presiona Ctrl+2 en consola

### Validación
- [ ] El terreno tiene varios colores (al menos 2-3 tipos)
- [ ] Hay transiciones suaves entre colores
- [ ] Algunos chunks son más oscuros (abismo)
- [ ] Algunos son azules (hielo)
- [ ] Algunos son verdes (bosque)

## 💚 PRUEBA 5: DEBUG OVERLAY

### Pasos
1. Presiona F3 durante el juego
2. Observa la esquina superior izquierda
3. Presiona F3 de nuevo para ocultarlo

### Validación
- [ ] Aparece etiqueta con "FPS: XX"
- [ ] Aparece "Enemies: XX"
- [ ] Aparece "Chunks: XX"
- [ ] El FPS está sobre 60 (idealmente)
- [ ] Los números actualizan en tiempo real
- [ ] Se puede toglear con F3

## ⚙️ PRUEBA 6: CONFIGURACIÓN Y PERSISTENCIA

### Pasos
1. Abre OptionsMenu (si está implementado)
2. Ajusta volumen a 50%
3. Cierra el juego
4. Reabre el juego
5. Verifica volumen

### Validación
- [ ] Se creó user://visual_calibration.cfg
- [ ] Se creó user://volume_config.cfg
- [ ] El volumen se mantiene después de reiniciar
- [ ] La calibración se aplica automáticamente

## 🎯 PRUEBA 7: DIFICULTAD PROGRESIVA

### Pasos
1. Nota cantidad de enemigos a 0:30
2. Espera 2-3 minutos
3. Nota cantidad de enemigos ahora
4. Presiona Ctrl+1 en consola (telemetría)

### Validación
- [ ] Hay más enemigos después de 2-3 minutos
- [ ] Enemigos se mueven más rápido
- [ ] Cada minuto la dificultad aumenta
- [ ] Se ve "[DifficultyManager] Dificultad aumentada a nivel X"

## 💣 PRUEBA 8: BOSS EVENT

### Pasos
1. Espera 5+ minutos en el juego (real: ~30 seg de espera)
2. Observa si aparece un enemigo más grande
3. Verifica consola

### Validación
- [ ] Aparece enemy evento boss
- [ ] Se ve "[DifficultyManager] ¡Evento de Boss en minuto 5!"
- [ ] El boss se puede ver en pantalla
- [ ] El boss se persigue como otros enemigos

## 🎨 PRUEBA 9: EFECTOS DE PARTÍCULAS

### Pasos
1. Identifica código que crea efectos
2. Modifica código temporalmente para crear efectos
3. Observa partículas

### Validación
- [ ] Se ven efectos de fuego (rojo/naranja)
- [ ] Se ven efectos de hielo (azul)
- [ ] Se ven efectos de rayo (amarillo)
- [ ] Se ven efectos arcanos (púrpura)
- [ ] Los efectos desaparecen después de ~1 segundo
- [ ] Sin lag visibleinclusode múltiples efectos

## 🎙️ PRUEBA 10: AUDIO

### Pasos
1. Verifica que existan buses en AudioBusLayout
2. Ajusta volúmenes en código o UI
3. Reproduce algunos sonidos

### Validación
- [ ] AudioBusLayout tiene buses: Master, Music, SFX, UI
- [ ] GlobalVolumeController accesible vía get_tree()
- [ ] Los métodos set_master_volume() funcionan
- [ ] Los cambios de volumen se guardan

## 🔍 PRUEBA 11: HOTKEYS DE DEBUG

### Pasos
Durante el juego, presiona:

1. **F3** - Toggle overlay
2. **F4** - Debug info
3. **F5** - Spawn enemigos
4. **Ctrl+1** - Telemetría
5. **Ctrl+2** - World offset
6. **Ctrl+3** - EnemiesRoot

### Validación
- [ ] F3 muestra/oculta overlay
- [ ] F4 imprime en consola árbol del player
- [ ] F5 crea 4 enemigos
- [ ] Ctrl+1 activa telemetría
- [ ] Ctrl+2 imprime offset del mundo
- [ ] Ctrl+3 lista enemigos activos

## 🛑 PRUEBA 12: RENDIMIENTO

### Pasos
1. Presiona F3 (debug overlay)
2. Spawna 20+ enemigos (presiona F5 varias veces)
3. Observa FPS en overlay
4. Nota si hay lag

### Validación
- [ ] FPS se mantiene sobre 60 con 50+ enemigos
- [ ] No hay stuttering visible
- [ ] CPU no sube al 100%
- [ ] Consola no tiene warnings de performance

## ✨ PRUEBA 13: CARACTERÍSTICAS AVANZADAS

### Calibración Visual
```gdscript
# En SpellloopGame._ready()
var vc = get_tree().root.get_node("VisualCalibrator")
print("Player scale: ", vc.get_player_scale())
print("Enemy scale: ", vc.get_enemy_scale())
```

Validación:
- [ ] Player scale es ~0.25
- [ ] Enemy scale es ~0.2
- [ ] Scales son diferentes según resolución

### BiomeTextureGenerator
```gdscript
var btg = load("res://scripts/core/BiomeTextureGenerator.gd").new()
var biome = btg.get_biome_at_position(Vector2(100, 100))
var name = btg.get_biome_name(biome)
print("Biome: ", name)
```

Validación:
- [ ] Retorna tipo de bioma
- [ ] Nombre es uno de: Arena, Bosque, Hielo, Fuego, Abismo
- [ ] Color corresponde al bioma

### DifficultyManager
```gdscript
var dm = get_tree().root.get_node("DifficultyManager")
print("Dificultad: ", dm.get_difficulty_level())
print("Elapsed: ", dm.get_elapsed_time())
print("Speed mult: ", dm.enemy_speed_multiplier)
```

Validación:
- [ ] Dificultad es entero positivo
- [ ] Elapsed aumenta con el tiempo
- [ ] Speed multiplier es > 1.0

## 📝 REGISTRO DE PRUEBAS

| Prueba | Estado | Notas |
|--------|--------|-------|
| 1. Inicialización | [ ] | |
| 2. Player/Movimiento | [ ] | |
| 3. Enemigos | [ ] | |
| 4. Biomas | [ ] | |
| 5. Debug Overlay | [ ] | |
| 6. Config/Persistencia | [ ] | |
| 7. Dificultad | [ ] | |
| 8. Boss Event | [ ] | |
| 9. Partículas | [ ] | |
| 10. Audio | [ ] | |
| 11. Hotkeys | [ ] | |
| 12. Rendimiento | [ ] | |
| 13. Avanzado | [ ] | |

## 🔧 TROUBLESHOOTING

### "Module not found" error
**Solución**: Verifica que los scripts estén en las rutas correctas
```
scripts/core/VisualCalibrator.gd
scripts/core/DifficultyManager.gd
scripts/core/BiomeTextureGenerator.gd
scripts/core/GlobalVolumeController.gd
```

### Audio no funciona
**Solución**: Crea AudioBusLayout con buses:
- Master
- Music
- SFX  
- UI

### FPS bajo
**Solución**: 
1. Reduce spawn_rate en EnemyManager
2. Reduce MAX_SIMULTANEOUS_EFFECTS en ParticleManager
3. Verifica driver GPU

### Sprites no aparecen
**Solución**: Verifica que sprites_index.json tenga rutas correctas

## ✅ CHECKLIST FINAL

- [ ] Todas las 13 pruebas pasadas
- [ ] 0 errores en consola
- [ ] 0 warnings críticos
- [ ] FPS > 60
- [ ] Todos los hotkeys funcionan
- [ ] Config se guarda/carga correctamente
- [ ] Biomas son visibles
- [ ] Enemigos spawnan y atacan
- [ ] Boss spawns cada 5 minutos
- [ ] Partículas funcionan sin lag

**Si todas las pruebas pasan: ✅ JUEGO LISTO PARA PRODUCCIÓN**

---

Última actualización: Octubre 2025
