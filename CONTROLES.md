# 🎮 CONTROLES DEL JUEGO - Isaac Style

## 🕹️ **Controles Principales**

### Movimiento (WASD)
- **W** - Mover arriba
- **A** - Mover izquierda  
- **S** - Mover abajo
- **D** - Mover derecha

### Disparo (Flechas)
- **↑** - Disparar arriba
- **←** - Disparar izquierda
- **↓** - Disparar abajo  
- **→** - Disparar derecha

### Acciones Especiales
- **Shift** - Dash/Sprint
- **Mouse Click** - Disparar hacia el cursor (backup)

## 🎯 **Controles de Testing**

### En MinimalTestRoom
- **Enter** - Generar objeto cerca del jugador
- **T** - Generar objeto cerca del jugador (alternativo)
- **R** - Reiniciar escena
- **ESC** - Salir del juego

## 🎲 **Objetos Coleccionables**

### Tipos de Objetos
- 🔥 **Fire Power** - Proyectiles queman enemigos
- ❄️ **Ice Power** - Proyectiles ralentizan enemigos  
- ⚡ **Lightning Power** - Proyectiles atraviesan enemigos
- 💪 **Damage Up** - Aumenta daño +5
- 🔄 **Fire Rate Up** - Dispara más rápido
- 🎯 **Multi Shot** - Dispara múltiples proyectiles
- ❤️ **Health Up** - Aumenta vida máxima +20
- 💨 **Speed Up** - Aumenta velocidad de movimiento

### Mecánicas
- Los objetos aparecen automáticamente cada 10 segundos
- Máximo 5 objetos en el mapa simultáneamente
- Los efectos son **acumulativos** - recoger múltiples objetos del mismo tipo mejora el efecto
- Los efectos elementales se pueden combinar (fuego + hielo + rayo)

## 🔧 **Problemas Resueltos**

### Crash al Recoger Objetos
- ✅ Arreglado problema de tween en objetos eliminados
- ✅ Efectos visuales ahora se crean en el padre antes de eliminar el objeto

### Congelamiento de Movimiento/Disparo
- ✅ Separados completamente los controles de movimiento (WASD) y disparo (Flechas)
- ✅ Movimiento se procesa PRIMERO para evitar conflictos
- ✅ El input se procesa en orden correcto en `_physics_process`

## 🎮 **Recomendaciones de Uso**

1. **Movimiento**: Usa WASD para moverte libremente
2. **Disparo**: Usa las flechas para disparar en cualquier dirección independientemente del movimiento
3. **Twin-Stick**: El juego soporta movimiento + disparo simultáneo sin conflictos
4. **Objetos**: Recoge todos los objetos que puedas para potenciar tu personaje
5. **Testing**: Usa T o Enter para generar objetos y probar combinaciones

¡Disfruta del sistema Isaac-style! 🎉