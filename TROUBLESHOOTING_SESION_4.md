# 🔧 TROUBLESHOOTING RÁPIDO - SESIÓN 4

**Uso:** Si algo no funciona, mira aquí primero  
**Tiempo:** 2-5 minutos para resolver

---

## 🆘 PROBLEMAS COMUNES Y SOLUCIONES

### ❌ "Compilation error: Identifier not declared"

**Síntomas:**
```
Error: Identifier "BiomeTextureGeneratorEnhanced" not declared
```

**Solución:**
1. Verifica que `BiomeTextureGeneratorEnhanced.gd` existe en:
   ```
   project/scripts/core/BiomeTextureGeneratorEnhanced.gd
   ```
2. Si no existe, crear el archivo desde [CAMBIOS_SESION_4.md](CAMBIOS_SESION_4.md)
3. Reload GDScript (F5 y cierra, luego abre de nuevo)

---

### ❌ "Weapons: 0" en monitor pero no hay errores

**Síntomas:**
```
Monitor muestra: Weapons: 0
Consola muestra: [GameManager] DEBUG líneas...
Pero weapon count no aumenta
```

**Debug steps:**
1. Abre consola (View → Output)
2. Busca estos mensajes:
   ```
   ✓ Si ves "attack_manager válido: false" → Problem en AttackManager
   ✓ Si ves "weapon válido: false" → Problem en IceWand.gd no carga
   ✓ Si ves "weapon.projectile_scene válido: false" → Problem en IceProjectile.tscn no existe
   ✓ Si ves "Armas después de equip: 0" → Problem en equip_weapon() method
   ```

**Soluciones por caso:**

**Caso A: attack_manager es null**
```
Probable causa: AttackManager no está inicializado en GameManager
Solución:
1. Buscar en GameManager.gd: attack_manager = 
2. Verificar que esa línea existe y no está comentada
3. Verificar la ruta al script
```

**Caso B: weapon es null**
```
Probable causa: IceWand.gd no carga correctamente
Solución:
1. Verificar que IceWand.gd existe en project/scripts/entities/
2. Abrir archivo y verificar: "class_name IceWand"
3. No debe tener errores de sintaxis
4. Reload Godot
```

**Caso C: projectile_scene es null**
```
Probable causa: IceProjectile.tscn no existe o ruta incorrecta
Solución:
1. Crear IceProjectile.tscn en project/scripts/entities/
2. Verificar que carga IceProjectile.gd script
3. La ruta en GameManager debe ser: "res://scripts/entities/IceProjectile.tscn"
```

**Caso D: equip_weapon resulta en 0 armas**
```
Probable causa: equip_weapon() en AttackManager no agrega a array
Solución:
1. Abrir AttackManager.gd
2. Buscar función: func equip_weapon(weapon)
3. Verificar que hace: weapons.append(weapon)
4. Verificar que weapons es Array
```

---

### ❌ No hay proyectiles visibles

**Síntomas:**
```
Monitor muestra: Weapons: 1 ✓
Consola muestra: [IceProjectile] ❄️ Proyectil de hielo creado ✓
Pero NO VES nada en pantalla ❌
```

**Debug steps:**

**1. Verificar que se está disparando**
```
Espera a estar cerca de un enemigo
El juego debe disparar automáticamente
Si no dispara: revisar AttackManager.tick() o attack_timer
```

**2. Verificar que proyectil se crea**
```
En consola, busca: "[IceProjectile] ❄️ Proyectil de hielo creado"
Si ves múltiples: ✅ Proyectiles se crean
Si no ves ninguno: ❌ ProjectileBase no se instancia
```

**3. Si se crea pero no se ve**
```
Probable causa: Problema en IceProjectile._create_icicle_visual()
Solución:
1. Verificar que se agrega sprite al nodo
2. Verificar que imagen tiene pixels (no blanca)
3. Verificar que sprite.visible = true (default)
4. Verificar z_index (debe ser visible sobre terreno)

Debug code:
// Agregar a _ready() en IceProjectile.gd:
print("[IceProjectile] Sprite creado: ", visual_node)
print("[IceProjectile] Sprite visible: ", visual_node.visible if visual_node else "null")
print("[IceProjectile] Sprite z_index: ", visual_node.z_index if visual_node else "null")
```

**4. Si proyectil se mueve pero no se ve**
```
Probable causa: Color del sprite es blanco o transparente
Solución:
1. En IceProjectile.gd, verificar colores:
   - Color(0.6, 0.8, 1.0) = Azul claro ✓
   - Color(1.0, 1.0, 1.0) = Blanco (no visible sobre cielo)
   - Color(0, 0, 0, 0) = Transparente (no se ve)
```

---

### ❌ Enemigos siguen siendo grandes

**Síntomas:**
```
Ejecutas F5 y enemigos NO se ven más pequeños
```

**Solución:**
```
1. ¿Cambió VisualCalibrator? Verificar línea:
   var base_scale = get_enemy_scale() * 0.5

2. Si está correcto pero no se ve cambio:
   - Eliminar archivo de configuración guardado
   - Ruta: user://visual_calibration.cfg
   - Comandos:
     * En Godot: Perforce/Save → Clear local saves
     * O manualmente: Buscar la carpeta user:// en tu PC
   
3. Reiniciar Godot completamente:
   - Cierra Godot
   - Elimina archivo guardado (paso 2)
   - Abre Godot de nuevo
   - F5

4. Si sigue igual:
   - Verificar que EnemyBase._ready() se ejecuta
   - Verificar que lee el scale correcto
   - Debug: Agregar print en EnemyBase._ready():
     print("Enemy scale: ", enemy_scale)
```

---

### ❌ Texturas siguen siendo aburridas

**Síntomas:**
```
Los chunks se ven con colores sólidos, sin detalle
```

**Verificación:**
1. ¿Existe BiomeTextureGeneratorEnhanced.gd?
   ```
   project/scripts/core/BiomeTextureGeneratorEnhanced.gd
   ```

2. ¿Está siendo usado? Buscar en consola:
   ```
   [BiomeTextureGeneratorEnhanced] ✨ Inicializado
   ```

3. Si no aparece:
   - InfiniteWorldManager no está usando el nuevo generador
   - Verificar que se modificó get_or_create_biome_texture()
   - Debe tener: `var generator = BiomeTextureGeneratorEnhanced.new()`

4. Si aparece pero texturas siguen aburridas:
   - Verificar que BIOME_COLORS tiene valores correctos
   - Los valores deben estar entre 0.0 y 1.0
   - Ejemplo: Color(0.95, 0.88, 0.65) = Arena dorada

---

### ❌ Controles debug no funcionan

**Síntomas:**
```
Presionas F3 pero nada pasa
```

**Pasos de debug:**

**1. ¿Tiene foco la ventana?**
```
Clic dentro de la ventana del juego
Luego presiona F3
```

**2. ¿Está activo QuickCombatDebug?**
```
En consola, presiona F3 y busca:
[QuickCombatDebug] Tecla F3 presionada

Si aparece ✓ → Debug se ejecuta pero algo más está mal
Si NO aparece ✗ → QuickCombatDebug no está corriendo
```

**3. Si QuickCombatDebug no se ejecuta**
```
Verificar que:
1. El script existe: project/scripts/tools/QuickCombatDebug.gd
2. Está en la escena o autoload
3. _input() se define correctamente
4. Controles están mapeados a F3/F4/F5 (no D/P/L)
```

**4. If F3 funciona pero no abre monitor**
```
Verificar que CombatSystemMonitor.tscn existe
Verificar que se instancia en QuickCombatDebug
Debug: Agregar print() antes de instancia
```

---

### ❌ "RefCounted" error en consola

**Síntomas:**
```
Error: Attempted to free RefCounted object
```

**Causa:** Código anterior llamaba `.free()` en Resource

**Solución:**
```
✅ Ya está fixed en Sesión 4
✅ CombatDiagnostics.gd línea 124 removió .free()
✅ No debe haber más errores de este tipo

Si aún ves el error:
1. Buscar ".free()" en todos los archivos GDScript
2. Si es en Resource/RefCounted → cambiar a comentario
3. Si es en Node2D → cambiar a .queue_free()
```

---

## 🔍 CÓMO LEER LA CONSOLA

### Localización de Consola
```
Godot UI:
View → Output Console

O: View → Panels → Output Console
```

### Filtrar mensajes importantes
```
Buscar (Ctrl+F en Output):
[GameManager]    → Mensajes de main game logic
[IceProjectile]  → Mensajes de proyectil
[IceWand]        → Mensajes de arma
DEBUG:           → Mensajes de debug
ERROR:           → Errores críticos
```

### Copiar mensajes para reportar
```
1. En Output, selecciona el texto (Ctrl+A)
2. Copia (Ctrl+C)
3. Pega en archivo de reporte
4. Resalta las líneas importantes
```

---

## 📱 TABLA DE REFERENCIA RÁPIDA

| Problema | Clave de Búsqueda | Archivo |
|----------|-------------------|---------|
| Weapons 0 | DEBUG: | GameManager.gd |
| No proyectiles | ❄️ Proyectil | IceProjectile.gd |
| Enemigos grandes | scale * 0.5 | VisualCalibrator.gd |
| Texturas aburridas | BiomeTextureGeneratorEnhanced | InfiniteWorldManager.gd |
| Controles no funcionan | KEY_F3 | QuickCombatDebug.gd |
| RefCounted error | .free() | CombatDiagnostics.gd |

---

## 🆘 SI TODO FALLA

**Opción 1: Reset Configuration**
```
1. Cierra Godot
2. Elimina: user://visual_calibration.cfg
3. Abre Godot
4. Borra proyecto de Recent Projects si aparece
5. Abre proyecto nuevamente
6. F5
```

**Opción 2: Check Compilation**
```
1. En Godot: Script → Check Syntax
2. Debería marcar error en archivo problemático
3. Arregla errores de sintaxis
4. Intenta F5 de nuevo
```

**Opción 3: Verify Files Exist**
```
project/scripts/entities/IceWand.gd                        ✓
project/scripts/entities/IceProjectile.gd                  ✓
project/scripts/entities/IceProjectile.tscn                ✓
project/scripts/core/BiomeTextureGeneratorEnhanced.gd      ✓
project/scripts/core/GameManager.gd                        ✓ (modificado)
project/scripts/core/VisualCalibrator.gd                   ✓ (modificado)
project/scripts/core/InfiniteWorldManager.gd               ✓ (modificado)
```

**Opción 4: Report Bug**
```
Si nada funciona:
1. Toma screenshot de la consola
2. Copia los primeros 30 mensajes de console
3. Reporta exactamente qué paso # falló:
   Step 1: Ejecuté F5
   Step X: [aquí está el problema]
   Step N: Error mostrado
```

---

## ✅ VERIFICACIÓN FINAL

**Antes de reportar "no funciona":**

- [ ] ¿Presionaste F5?
- [ ] ¿Abriste consola?
- [ ] ¿Esperaste 5 segundos a que cargue?
- [ ] ¿Viste mensajes [GameManager] DEBUG?
- [ ] ¿Moviste el jugador con WASD?
- [ ] ¿Presionaste F3 para abrir monitor?
- [ ] ¿Revisaste TODOS los mensajes de consola?

Si todos SÍ → Reúne datos y reporta exactamente:
```
"Presioné F5 y en consola veo: [lista exacta de mensajes]"
"El monitor muestra: [valores específicos]"
"En pantalla veo: [descripción visual]"
"Esperado vs. Real: [diferencia específica]"
```

---

**Versión:** 1.0  
**Última actualización:** Sesión 4  
**Próximo:** Usar esto si algo no funciona en las pruebas
