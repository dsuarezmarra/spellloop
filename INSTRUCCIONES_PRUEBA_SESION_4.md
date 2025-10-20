# 🧪 INSTRUCCIONES DE PRUEBA - SESIÓN 4

**Objetivo:** Verificar que todos los cambios funcionan correctamente

---

## 📋 PRE-REQUISITOS

- [ ] Godot 4.5.1 abierto con el proyecto Spellloop
- [ ] Consola de salida visible (View → Output Console)
- [ ] Editor listo para ejecutar (F5)

---

## 🎮 PASO 1: INICIAR JUEGO

**Acción:** Presiona **F5** para ejecutar el juego

**Qué observar:**
```
1. El juego debe cargar sin errores de compilación
2. El jugador debe aparecer en el centro de la pantalla
3. Enemigos deben estar presentes alrededor
4. Chunks deben cargar con texturas mejoradas
```

**En consola esperamos ver:**
```
[BiomeTextureGeneratorEnhanced] ✨ Inicializado con texturas Funko Pop
[InfiniteWorldManager] ✨ Bioma 'arena' textura Funko Pop generada
[InfiniteWorldManager] ✨ Bioma 'bosque' textura Funko Pop generada
...
[GameManager] DEBUG: Equipando varita de hielo...
[GameManager] DEBUG: attack_manager válido: true
[GameManager] DEBUG: weapon válido: true
[GameManager] DEBUG: weapon.projectile_scene válido: true
[GameManager] DEBUG: Armas después de equip: 1
```

---

## 🔍 PASO 2: VERIFICAR ENEMIGOS REDIMENSIONADOS

**Visual Esperado:**
- [ ] Enemigos están claramente **más pequeños** que antes
- [ ] No bloquean completamente la vista del jugador
- [ ] Puedes ver el área alrededor del jugador sin obstáculos
- [ ] Tier 1 (Skeletons) son notablemente más pequeños

**Si no ves cambio de tamaño:**
```
⚠️ Problema potencial:
- VisualCalibrator no se reinició
- Solución: Eliminar "user://visual_calibration.cfg" y reiniciar
```

---

## 🎯 PASO 3: DISPARAR CON VARITA DE HIELO

**Acción:** 
1. Moverte cerca de un enemigo (presiona WASD)
2. El juego debe disparar proyectiles automáticamente

**Qué observar:**
```
Visual:
- [ ] Proyectiles azul claro (carámbanos) salen del jugador
- [ ] Van hacia los enemigos
- [ ] Desaparecen al golpear o después de 4 segundos

En consola:
[IceProjectile] ❄️ Proyectil de hielo creado
[IceProjectile] ❄️ Golpe a Enemy_skeleton...
[IceProjectile] ❄️ Aplicando ralentización a Enemy_skeleton
```

**Monitor Debug (F3):**
- [ ] "Weapons: 1" (debe mostrar 1 arma equipada)
- [ ] El contador de proyectiles debe aumentar

---

## 🧊 PASO 4: VERIFICAR EFECTO DE RALENTIZACIÓN

**Cómo verificar:**
1. Mira un enemigo que no esté ralentizado (movimiento normal)
2. Dispara el proyectil de hielo
3. Observa que el enemigo **se mueve más lentamente** durante ~2 segundos

**En consola:**
```
[IceProjectile] ❄️ Aplicando ralentización a Enemy_skeleton
```

**Si no ves efecto:**
```
⚠️ Posible causa:
- El enemigo no tiene método apply_slow()
- El método take_damage() no se ejecuta correctamente
```

---

## 🌍 PASO 5: INSPECCIONAR TEXTURAS FUNKO POP

**Visual Esperado:**

### Arena:
- [ ] Color dorado/marrón claro (no gris)
- [ ] Variaciones de tono (dunas visibles)
- [ ] Textura más detallada que antes

### Bosque:
- [ ] Verde vibrante (no oscuro)
- [ ] Patrones de pasto visibles
- [ ] Más saturado que antes

### Hielo:
- [ ] Azul claro brillante
- [ ] Cristales visibles
- [ ] Grietas sutiles

### Fuego:
- [ ] Naranja saturado (no apagado)
- [ ] Patrón de llamas visible
- [ ] Zonas oscuras de carbón

### Abismo:
- [ ] Púrpura oscuro (no negro)
- [ ] Puntos de luz espectrales
- [ ] Efecto misterioso

**En consola:**
```
[InfiniteWorldManager] ✨ Bioma 'X' textura Funko Pop generada
```

---

## 🐛 PASO 6: VERIFICAR CONTROLES DEBUG

**Acciones:**
1. Presiona **F3** → Debe abrir/cerrar monitor de combate
2. Presiona **F4** → Debe ejecutar ataque automático
3. Presiona **Shift+F5** → Debe ejecutar algo de debug

**En consola:**
```
[QuickCombatDebug] Tecla F3 presionada
[QuickCombatDebug] Tecla F4 presionada  
[QuickCombatDebug] Tecla Shift+F5 presionada
```

**Si las teclas no funcionan:**
```
⚠️ Verificar:
- Ventana del juego tiene foco (clic dentro)
- No hay conflicto con otro sistema
```

---

## ✅ CHECKLIST FINAL

**Estado del Sistema:**

### Compilación
- [ ] Sin errores de compilación
- [ ] Sin warnings críticos
- [ ] Todas las clases cargan

### Combat
- [ ] IceWand equipa correctamente
- [ ] Proyectiles aparecen en pantalla
- [ ] Proyectiles golpean enemigos
- [ ] Ralentización funciona

### Visual
- [ ] Enemigos 50% más pequeños
- [ ] Texturas Funko Pop se ven
- [ ] Colores más vibrantes
- [ ] Detalle en chunks visible

### Debug
- [ ] Controles F3/F4/F5 funcionan
- [ ] Monitor muestra información
- [ ] Consola tiene mensajes DEBUG
- [ ] No hay errores RefCounted

---

## 📊 RESULTADO ESPERADO

### Consola (primer minuto):
```
✓ "BiomeTextureGeneratorEnhanced" inicializado
✓ Múltiples "texturas Funko Pop generadas"
✓ "Equipando varita de hielo..."
✓ "attack_manager válido: true"
✓ "weapon válido: true"
✓ "weapon.projectile_scene válido: true"
✓ "Armas después de equip: 1"
✓ Múltiples "Proyectil de hielo creado"
✓ Múltiples "Golpe a Enemy_..."
```

### Pantalla:
```
✓ Jugador en centro (blanco/plateado)
✓ Enemigos pequeños alrededor (50% más chicos)
✓ Proyectiles azul claro saliendo del jugador
✓ Chunks con texturas detalladas
✓ Colores vibrantes (verde bosque, azul hielo, etc)
✓ Enemigos ralentizados cuando son golpeados
```

### Monitor (F3):
```
✓ Weapons: 1
✓ Health: 100/100 (o similar)
✓ Proyectiles: número que va aumentando
✓ Daño: 8 (de IceWand)
```

---

## 🆘 TROUBLESHOOTING

### "Weapons: 0" en monitor
```
1. Revisar consola por mensajes DEBUG
2. Si "attack_manager válido: false" → AttackManager no inicializa
3. Si "weapon válido: false" → IceWand.gd no carga
4. Si "weapon.projectile_scene válido: false" → IceProjectile.tscn no encuentra
```

### No hay proyectiles visibles
```
1. Verificar que "Weapons: 1" aparece
2. Verificar que "[IceProjectile] ❄️ Proyectil de hielo creado" aparece
3. Si projectile se crea pero no se ve:
   - Problema en IceProjectile.gd _create_icicle_visual()
   - O problema en layer/collision
```

### Enemigos siguen siendo grandes
```
1. Eliminar: user://visual_calibration.cfg
2. Cerrar y reabrir Godot
3. Ejecutar F5 de nuevo
4. Debe regenerar calibración
```

### Texturas de chunks no tienen detalle
```
1. Verificar en consola: "BiomeTextureGeneratorEnhanced" aparece
2. Si no aparece, el generador no se está usando
3. Verificar en InfiniteWorldManager que usa BiomeTextureGeneratorEnhanced
```

### Controles debug no funcionan
```
1. Clic dentro de la ventana del juego (darle foco)
2. Revisar que no hay overlay otra cosa recibiendo input
3. En consola, buscar "[QuickCombatDebug]" para verificar se detecta la tecla
```

---

## 🎬 VIDEO DE PRUEBA (Comandos)

**Para que otro revisor pueda reproducir:**

```
1. Abre Godot con Spellloop
2. Presiona F5
3. Espera 2 segundos a que cargue
4. Presiona Ctrl+Shift+I para abrir console (si está disponible)
5. Presiona F3 para abrir monitor
6. Presiona WASD para mover
7. Verifica que ves:
   - Enemigos pequeños
   - Proyectiles azules
   - Texturas coloridas
8. Presiona ESC para salir
```

---

## 📝 REPORTE DE RESULTADOS

**Después de hacer todas las pruebas, reporta:**

```markdown
## Resultados Sesión 4

### ✓ Cambios Confirmados
- [ ] IceWand se equipa (Weapons: 1)
- [ ] Proyectiles de hielo aparecen
- [ ] Enemigos son 50% más pequeños
- [ ] Texturas tienen más detalle
- [ ] Colores son más vibrantes
- [ ] Efecto de ralentización funciona

### ⚠️ Problemas Encontrados
(Listar problemas específicos encontrados)

### 🔍 Eventos en Consola
(Copiar primeros 20 eventos de consola)

### 📸 Capturas
(Adjuntar screenshot del juego con todos los cambios visibles)
```

---

**Versión:** Sesión 4  
**Objetivo:** Validar todos los cambios de la sesión 4  
**Último actualizado:** [Timestamp]
