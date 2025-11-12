# 🎮 GUÍA: Viewport, Escalado y Multi-Resolución

## ❌ PROBLEMA ENCONTRADO

Tu juego tenía problemas de escalado porque:

1. **Faltaba configuración de `stretch/aspect`** → Causaba barras negras en 4K
2. **Scripts usaban coordenadas físicas** → Los elementos se veían pequeños/grandes según resolución
3. **Spawn de enemigos usaba distancias absolutas** → No escalaban correctamente

---

## ✅ CONFIGURACIÓN CORRECTA (project.godot)

```ini
[display]
window/size/viewport_width=1920
window/size/viewport_height=1080
window/size/mode=2
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
```

### **Por qué esta configuración:**

- **`window/stretch/mode="canvas_items"`**: Escala elementos 2D automáticamente (mejor calidad visual que `viewport`)
- **`window/stretch/aspect="expand"`**: Usa toda la pantalla sin barras negras, expandiendo el área visible en pantallas más anchas

---

## 🎯 CÓMO USAR VIEWPORT CORRECTAMENTE

### ❌ **INCORRECTO** (lo que estabas haciendo):
```gdscript
# Esto devuelve el tamaño FÍSICO de la ventana (3840x2160 en 4K)
var size = get_viewport_rect().size
```

### ✅ **CORRECTO**:
```gdscript
# Esto devuelve el tamaño LÓGICO del viewport (siempre 1920x1080)
var size = get_viewport().get_visible_rect().size
```

---

## 🔧 SCRIPTS QUE NECESITAN CORRECCIÓN

### 1. **Scripts de Test de Decoraciones**

Archivos afectados:
- `test_snow_decorations.gd`
- `test_lava_decorations.gd`
- `test_arcanewastes_decorations.gd`

**Cambiar:**
```gdscript
# ANTES (línea ~14)
var viewport_size = get_viewport_rect().size

# DESPUÉS
var viewport_size = get_viewport().get_visible_rect().size
```

### 2. **EnemyManager - Spawn Distance**

El `spawn_distance` de 600px es correcto para 1920x1080, pero deberías considerar hacerlo dinámico:

```gdscript
# En EnemyManager.gd - función _ready() o initialize()
func _calculate_spawn_distance():
	var viewport = get_viewport()
	if viewport:
		var viewport_size = viewport.get_visible_rect().size
		# Spawnear enemigos un poco fuera del borde visible
		# Usar el lado más pequeño como referencia
		var reference_size = min(viewport_size.x, viewport_size.y)
		spawn_distance = reference_size * 0.6  # 60% del lado menor
		print("[EnemyManager] Spawn distance ajustada: %.1f" % spawn_distance)
```

### 3. **ScaleManager - Ya está bien implementado**

Tu `ScaleManager.gd` ya usa `get_viewport().get_visible_rect().size` ✅

---

## 📊 COMPARACIÓN: Stretch Modes y Aspect Modes

### **Stretch Modes:**

| Mode | Uso | Calidad Visual | Performance |
|------|-----|----------------|-------------|
| `disabled` | Apps no-juego | N/A | Mejor |
| `canvas_items` | **Juegos 2D (RECOMENDADO)** | ⭐⭐⭐⭐⭐ | Buena |
| `viewport` | Pixel art estricto | ⭐⭐⭐ | Mejor |

### **Aspect Modes:**

| Mode | Comportamiento | Mejor para |
|------|----------------|-----------|
| `keep` | Barras negras para mantener aspect ratio | Juegos con UI fija |
| `expand` | **Expande viewport, sin barras (RECOMENDADO)** | **Top-down, roguelikes** |
| `ignore` | Estira todo (distorsiona) | ❌ Nunca usar |
| `keep_width` | Expande verticalmente | Juegos verticales |
| `keep_height` | Expande horizontalmente | Platformers horizontales |

---

## 🎮 CÓMO FUNCIONA `expand` EN TU JUEGO

Con `aspect="expand"`:

- **Pantalla 1080p (16:9)**: Ve 1920x1080 del mundo
- **Pantalla 4K (16:9)**: Ve 1920x1080 del mundo (escalado 2x)
- **Pantalla ultrawide (21:9)**: Ve ~2520x1080 del mundo (más ancho, mismo alto)
- **Pantalla 4:3**: Ve 1920x~1440 del mundo (más alto, mismo ancho)

**Ventajas:**
- ✅ Los sprites mantienen su tamaño relativo
- ✅ No hay barras negras
- ✅ Los jugadores con pantallas más anchas ven más mundo (ventaja mínima en top-down)
- ✅ Perfecto para roguelites donde no hay ventaja competitiva

---

## 🚀 CARACTERÍSTICAS QUE TE FALTAN (Basado en roguelites similares)

### 1. **Sistema de Cámara con Shake**
```gdscript
# Para impactos, explosiones, daño
func camera_shake(intensity: float, duration: float):
	# Implementar trauma-based camera shake
	pass
```

### 2. **Screen Space Effects**
- **Vignette** cuando el jugador tiene poca vida
- **Chromatic aberration** en eventos importantes
- **Screen flash** en daño/pickup importante

### 3. **Zoom Dinámico**
```gdscript
# Zoom out cuando hay muchos enemigos
# Zoom in durante momentos dramáticos
func adjust_camera_zoom(target_zoom: float, duration: float):
	pass
```

### 4. **Parallax Backgrounds**
- Capas de fondo que se mueven a diferentes velocidades
- Añade profundidad visual al mundo 2D

### 5. **Screen Bounds Detection**
```gdscript
# Para UI, minimapa, etc
func is_position_on_screen(world_pos: Vector2) -> bool:
	var viewport = get_viewport()
	var camera_pos = get_viewport().get_camera_2d().get_screen_center_position()
	var viewport_size = viewport.get_visible_rect().size
	var half_size = viewport_size / 2
	
	var screen_rect = Rect2(
		camera_pos - half_size,
		viewport_size
	)
	return screen_rect.has_point(world_pos)
```

### 6. **Adaptive UI Scaling**
```gdscript
# UI que se adapta a diferentes aspect ratios
# Anclar elementos críticos a esquinas/bordes
```

### 7. **Performance Scaling**
```gdscript
# Reducir calidad de partículas en pantallas grandes
# Ajustar render distance según resolución
func adjust_quality_for_resolution():
	var viewport_size = get_viewport().get_visible_rect().size
	var pixel_count = viewport_size.x * viewport_size.y
	
	if pixel_count > 2073600:  # Mayor a 1080p
		# Reducir densidad de partículas
		ParticleManager.quality_multiplier = 0.75
```

### 8. **Debug Overlay con Info de Viewport**
```gdscript
# Mostrar en pantalla (útil para debugging)
func _on_draw_debug():
	var viewport = get_viewport()
	var logical_size = viewport.get_visible_rect().size
	var window_size = get_window().size
	var scale_factor = window_size / logical_size
	
	draw_string(font, Vector2(10, 30), 
		"Logical: %dx%d | Window: %dx%d | Scale: %.2f" % [
			logical_size.x, logical_size.y,
			window_size.x, window_size.y,
			scale_factor.x
		])
```

### 9. **Settings Menu - Resolution Options**
```gdscript
# Permitir al jugador cambiar:
# - Fullscreen vs Windowed
# - VSync on/off
# - FPS cap
# - UI Scale (multiplier sobre el default)
```

### 10. **HiDPI Support**
```gdscript
# Detectar pantallas de alta densidad
func get_display_scale() -> float:
	var screen_dpi = DisplayServer.screen_get_dpi()
	if screen_dpi > 150:
		return 2.0  # Retina/HiDPI
	return 1.0
```

---

## 📝 CHECKLIST DE CORRECCIÓN INMEDIATA

- [ ] Verificar que `project.godot` tenga `stretch/mode="canvas_items"` y `stretch/aspect="expand"`
- [ ] Cambiar `get_viewport_rect().size` por `get_viewport().get_visible_rect().size` en:
  - [ ] `test_snow_decorations.gd`
  - [ ] `test_lava_decorations.gd`
  - [ ] `test_arcanewastes_decorations.gd`
- [ ] (Opcional) Hacer spawn_distance dinámico en `EnemyManager.gd`
- [ ] Probar en diferentes resoluciones (1080p, 4K, ultrawide)
- [ ] Verificar que los enemigos spawneen correctamente en el borde de la cámara

---

## 🎯 COMANDOS DE PRUEBA

```gdscript
# Agregar a DebugOverlay o crear script de prueba
func test_viewport_info():
	var viewport = get_viewport()
	var window = get_window()
	
	print("=== VIEWPORT INFO ===")
	print("Logical size: ", viewport.get_visible_rect().size)
	print("Window size: ", window.size)
	print("Content scale mode: ", window.content_scale_mode)
	print("Content scale aspect: ", window.content_scale_aspect)
	print("Stretch enabled: ", viewport.get_visible_rect().size != window.size)
```

---

## 🔗 REFERENCIAS

- [Godot Docs - Multiple Resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html)
- Juegos similares que usan `expand`:
  - **Vampire Survivors** (top-down, aspect expansion)
  - **Brotato** (top-down roguelike)
  - **20 Minutes Till Dawn** (top-down survival)

---

## ⚡ PRÓXIMOS PASOS RECOMENDADOS

1. **Implementar camera shake system** (mayor impacto visual)
2. **Añadir screen flash effects** (feedback de daño/pickup)
3. **Crear adaptive spawn system** (que use viewport bounds reales)
4. **Implementar minimap que se adapte** (esquina superior derecha, siempre visible)
5. **Añadir settings menu** (calidad gráfica, resolución, fullscreen)

---

¡Con estos cambios tu juego escalará perfectamente en cualquier resolución! 🎮✨
