# 🧪 GUÍA DE PRUEBAS RÁPIDAS - Spellloop

## ✅ Checklist de Verificación

### 1. **Cargue del Proyecto**
- [ ] Godot abre sin crash
- [ ] No hay errores críticos de parseo (algunos warnings son OK)
- [ ] Escena SpellloopMain carga correctamente

### 2. **Biomas Visuales** 🎨
Presiona PLAY (F5) y verifica cada bioma:

**Bioma 1: GRASSLAND (Verde)**
- [ ] Fondo base: Verde pasto
- [ ] Patrón: Pequeños rectángulos verdes más oscuros
- [ ] Decoraciones: Arbustos, flores, árboles pequeños

**Bioma 2: DESERT (Amarillo/Beige)**
- [ ] Fondo base: Arena amarilla
- [ ] Patrón: Puntos/círculos dispersos
- [ ] Decoraciones: Cactus, rocas, púas de arena

**Bioma 3: SNOW (Blanco/Azul)**
- [ ] Fondo base: Nieve blanca
- [ ] Patrón: Pequeños copos hexagonales
- [ ] Decoraciones: Cristales de hielo, montículos

**Bioma 4: LAVA (Rojo/Negro)**
- [ ] Fondo base: Rojo oscuro
- [ ] Patrón: Líneas sinusoidales (grietas)
- [ ] Decoraciones: Rocas de lava, púas de fuego

**Bioma 5: ARCANE_WASTES (Violeta)**
- [ ] Fondo base: Violeta mágico
- [ ] Patrón: Runas/estrellas
- [ ] Decoraciones: Cristales arcanos, púas mágicas

**Bioma 6: FOREST (Verde Oscuro)**
- [ ] Fondo base: Verde oscuro
- [ ] Patrón: Líneas/ramas
- [ ] Decoraciones: Árboles, arbustos densos

### 3. **Movimiento** 🎮
En la escena, prueba:
- [ ] Presiona **W** - El mundo debería moverse hacia abajo
- [ ] Presiona **A** - El mundo debería moverse hacia la derecha
- [ ] Presiona **S** - El mundo debería moverse hacia arriba
- [ ] Presiona **D** - El mundo debería moverse hacia la izquierda
- [ ] Mueve mientras los chunks se cargan/descargan dinámicamente

**Indicador de éxito**: El jugador permanece en el centro y el mundo se mueve alrededor.

### 4. **Generación de Chunks** 📦
Mientras te mueves:
- [ ] Los chunks se generan dinámicamente (máximo 9 activos)
- [ ] No hay freezes/lags al cargar nuevos chunks
- [ ] Los chunks cambios de bioma al cruzar fronteras
- [ ] Los cofres aparecen en los chunks generados
- [ ] Los enemigos spawn correctamente

### 5. **Enemigos y Combat** ⚔️
- [ ] Los enemigos aparecen en el mapa
- [ ] Los projectiles de hielo se disparan
- [ ] El daño se aplica correctamente
- [ ] Los knockbacks funcionan
- [ ] Los enemigos mueren y dan exp

### 6. **UI** 🖥️
- [ ] Minimapa circular visible
- [ ] Health bar del jugador visible
- [ ] Cooldowns de armas funcionales
- [ ] Debug info visible (si está activado)

## 🔍 Qué Buscar

### ✅ Señales de Éxito
- Biomas con patrones visuales diferenciados
- Movimiento suave del mundo
- Carga dinámica de chunks sin freezes
- Transiciones suaves entre biomas

### ❌ Señales de Problemas
- Si el mundo **NO se mueve**: Ver logs para "chunks_root is null"
- Si los biomas se ven **planos**: Patrón procedural puede no estar renderizando
- Si hay **lag/freezes**: Problema de densidad de decoraciones
- Si los chunks **no cargan**: Error en BiomeGenerator.generate_chunk_async()

## 📝 Logs a Monitorear

En Output Console, busca:
```
[SpellloopGame] ✅ chunks_root asignado: ChunksRoot
[InfiniteWorldManager] 🎮 Sistema de chunks inicializado
[InfiniteWorldManager] 🔄 Chunks activos: 9 (central: (0, 0))
[InfiniteWorldManager] ✨ Chunk (x, y) generado
[BiomeGenerator] ✅ Inicializado
```

## 🎯 Próximas Acciones

Si TODO funciona:
1. ✅ Celebra - El sistema está funcionando
2. 📸 Toma screenshots de diferentes biomas
3. 📊 Documenta rendimiento (FPS, lag)

Si algo NO funciona:
1. 🔍 Busca el error en Output Console
2. 📋 Nota qué exactamente no funciona
3. 💬 Comparte el log conmigo

---
**Duración estimada de pruebas**: 5-10 minutos
**Objetivo**: Verificar que todos los sistemas funcionan juntos

¡Buena suerte! 🍀
