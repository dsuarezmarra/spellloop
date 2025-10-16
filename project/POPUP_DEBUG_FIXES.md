# Solución de Botones de Popup No Responsivos

## Problema Identificado
Los botones del popup de items del cofre no respondían a clics del mouse, a pesar de que:
- El popup se renderizaba correctamente
- Los items se mostraban en pantalla
- El juego se pausaba correctamente

## Raíz del Problema
Cuando `get_tree().paused = true` se ejecuta, **los nodos normales dejan de recibir input**. Aunque `CanvasLayer` es independiente de la cámara, sus nodos hijos (botones, controles) heredaban el estado de pausa y no procesaban input.

## Soluciones Implementadas

### 1. **CanvasLayer Process Mode (CRÍTICO)**
```gdscript
func _ready():
    layer = 100
    process_mode = Node.PROCESS_MODE_ALWAYS  # Procesar SIEMPRE aunque paused=true
    set_process_input(true)  # Habilitar procesamiento de input
```

**Por qué funciona:** Los CanvasLayers normalmente respetan el estado de pausa, pero con `PROCESS_MODE_ALWAYS` continúan procesando input incluso cuando el juego está pausado.

### 2. **Botones con Process Mode Explícito**
```gdscript
button.process_mode = Node.PROCESS_MODE_ALWAYS
```

**Por qué funciona:** Garantiza que cada botón individual también procese input durante pausa.

### 3. **Logging Mejorado en _input()**
```gdscript
func _input(event: InputEvent):
    print("[SimpleChestPopup] _input() llamado con evento: ", event.get_class())
    
    if event is InputEventKey and event.pressed:
        print("[SimpleChestPopup] InputEventKey detectado - keycode: ", event.keycode)
        # ... manejo de teclas
```

**Propósito:** Permitir debug visual de si _input() está siendo llamado.

### 4. **Logging Detallado en Button Press**
```gdscript
func _on_button_pressed(button_index: int, item_data: Dictionary):
    print("[SimpleChestPopup] *** BOTÓN PRESIONADO - INDEX: ", button_index, " ITEM: ", item_data.get("type"), " ***")
```

**Propósito:** Confirmar que la conexión lambda está funcionando.

## Flujo de Ejecución Esperado (Después del Fix)

```
1. Usuario toca cofre
   ↓
2. TreasureChest pausa juego: get_tree().paused = true
   ↓
3. SimpleChestPopup._ready() se ejecuta
   ├─ layer = 100 (al frente)
   ├─ process_mode = ALWAYS (procesa input)
   └─ set_process_input(true) (habilita input)
   ↓
4. setup_items() crea botones
   ├─ Cada botón obtiene process_mode = ALWAYS
   ├─ Cada botón conecta pressed signal con lambda
   └─ Lambda captura item_data y item_index
   ↓
5. Usuario hace clic en botón
   ↓
6. Button.pressed signal emite (AHORA FUNCIONA)
   ↓
7. Lambda ejecuta: _on_button_pressed(item_index, item_data)
   ↓
8. _process_item_selection(item, index)
   ├─ Emite: item_selected.emit(item)
   ├─ Pausa desactivada: get_tree().paused = false
   └─ Popup cerrado: queue_free()
   ↓
9. TreasureChest._on_popup_item_selected(item)
   ├─ Emite: chest_opened.emit(self, [item])
   ↓
10. ItemManager._on_chest_opened(chest, items)
   ├─ apply_item_effect(item)
   └─ Bonus aplicado al player
```

## Teclas Alternativas (También Funcionan)
- **1/2/3:** Seleccionar item por índice
- **ENTER:** Confirmar selección actual
- **ESC:** Cancelar/seleccionar primer item

Todos estos eventos ahora se capturan en `_input()` con logging para confirmar recepción.

## Testing Checklist

- [ ] Abrir juego (F5)
- [ ] Navegar a un cofre
- [ ] Verificar que popup aparezca centrado
- [ ] Verificar que 3 items se muestren
- [ ] **CLIC EN BOTÓN** → Verificar log: `[SimpleChestPopup] *** BOTÓN PRESIONADO - INDEX: X ITEM: tipo ***`
- [ ] Popup debe cerrarse
- [ ] Juego debe reanudar (unpause)
- [ ] Item bonus debe aplicarse (verificar stats del player)
- [ ] Probar con tecla 1/2/3 (debe funcionar igual)

## Archivos Modificados
- `scripts/ui/SimpleChestPopup.gd`
  - Añadido: `process_mode = ALWAYS` en CanvasLayer
  - Añadido: `set_process_input(true)` para explicititud
  - Añadido: `process_mode = ALWAYS` en botones individuales
  - Mejorado: Logging en `_input()` para debug
  - Mejorado: Logging en `_on_button_pressed()` para confirmar callback

## Notas Importantes

1. **CanvasLayer + Pausa:** CanvasLayer es independiente de cámara, pero NO de pausa. Se requiere `process_mode = ALWAYS` explícitamente.

2. **Herencia de Process Mode:** Los nodos hijos NO heredan automáticamente `process_mode` del padre. Por eso se establece en ambos niveles.

3. **Lambda + Item Data:** Las lambdas capturan `item_index` e `item_data` por valor, permitiendo que cada botón mantenga su propia información.

4. **Set Input As Handled:** Es importante que `_input()` llame a `get_tree().root.set_input_as_handled()` para evitar que otros nodos procesen el mismo input.

## Próximos Pasos (Si Aún No Funciona)

1. Verificar Console Output en Godot para confirmar logs
2. Si no ve `_input() llamado`, revisar `set_process_input(true)`
3. Si ve `_input()` pero no se procesa KEY_1/KEY_2, revisar InputMap en Project Settings
4. Si ves BOTÓN PRESIONADO pero popup no cierra, revisar `queue_free()` en `_process_item_selection()`
5. Si popup cierra pero item no se aplica, revisar `ItemManager.apply_item_effect()`

## Código de Referencia Rápida

```gdscript
# En cualquier CanvasLayer que necesite input durante pausa:
func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_process_input(true)

# En cualquier Control/Button hijo que necesite procesar:
node.process_mode = Node.PROCESS_MODE_ALWAYS
```

---

**Fecha:** 2025-01-XX
**Estado:** Ready for Testing ✅
**Cambios Críticos:** 3 (process_mode CanvasLayer, process_mode Buttons, set_process_input)
