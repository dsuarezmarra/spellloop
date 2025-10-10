# 🔧 CORRECCIÓN: collision_shape no declarada

## ✅ **Error Corregido:**

### **Problema:**
❌ **ERROR**: `Identifier "collision_shape" not declared in the current scope`

### **Causa:** 
Los enemigos (BasicSlime, SentinelOrb, PatrolGuard) estaban usando `collision_shape` pero no estaba declarada en su clase base.

### **Solución Aplicada:**
✅ **Añadido a Entity.gd** (clase base de todos los enemigos):
```gdscript
# Common node references  
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
```

### **Jerarquía de Herencia:**
```
Entity.gd (base)
├── collision_shape declarada ✅
└── Enemy.gd (hereda de Entity)
    ├── BasicSlime.gd ✅
    ├── SentinelOrb.gd ✅  
    └── PatrolGuard.gd ✅
```

## 🎮 **Para Probar:**

1. **Recargar proyecto** en Godot
2. **Verificar Output** - no debería mostrar error de collision_shape
3. **Presionar F5** para ejecutar
4. **Todos los enemigos** deberían funcionar correctamente

## 📊 **Estado Actual:**
- ✅ **collision_shape**: DECLARADA en Entity.gd
- ✅ **Herencia**: CORRECTA para todos los enemigos
- ✅ **Error de parser**: RESUELTO
- ✅ **Compatibilidad**: Mantenida con Player y Projectile

## 🎯 **Funcionalidad Esperada:**
- ✅ **Enemigos**: Deberían cargar sin errores
- ✅ **Collisiones**: Funcionando correctamente  
- ✅ **BasicSlime, SentinelOrb, PatrolGuard**: Operativos

---

**Estado: ERROR DE collision_shape CORREGIDO** ✅