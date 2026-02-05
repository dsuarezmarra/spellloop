# 🎯 Guía Completa para Crear Sprites de Proyectiles

## Índice
1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Especificaciones Técnicas](#especificaciones-técnicas)
3. [Proceso de Creación](#proceso-de-creación)
4. [Integración en el Juego](#integración-en-el-juego)
5. [Checklist de Verificación](#checklist-de-verificación)
6. [Solución de Problemas](#solución-de-problemas)

---

## Resumen Ejecutivo

### ⚠️ REGLA DE ORO
> **TODOS los sprites de proyectiles DEBEN apuntar hacia la DERECHA (→) en sus frames.**
> 
> El sistema de rotación usa `rotation = direction.angle()` donde:
> - Derecha (→) = 0°
> - Abajo (↓) = 90°
> - Izquierda (←) = 180°
> - Arriba (↑) = -90°

Si el sprite apunta en otra dirección, el proyectil rotará incorrectamente en el juego.

### Archivos Necesarios por Proyectil
```
project/assets/sprites/projectiles/{weapon_id}/
├── flight.png    (384x64 - 6 frames de 64x64)
└── impact.png    (384x64 - 6 frames de 64x64)
```

> **NOTA**: Solo se necesitan 2 archivos. El `launch.png` fue eliminado porque no se usa - los proyectiles empiezan directamente en animación de vuelo.

---

## Especificaciones Técnicas

### Dimensiones de Sprites

| Animación | Frames | Tamaño Frame | Tamaño Total | FPS |
|-----------|--------|--------------|--------------|-----|
| Flight    | 6      | 64x64        | 384x64       | 12  |
| Impact    | 6      | 64x64        | 384x64       | 15  |

> **NOTA**: `launch.png` ya no se usa. Los proyectiles empiezan directamente con la animación de vuelo.

### Formato de Imagen
- **Formato**: PNG con transparencia (RGBA)
- **Fondo**: Transparente
- **Disposición**: Horizontal (frames uno al lado del otro)
- **Orden de frames**: Izquierda a derecha (frame 0 → frame N)

### Orientación del Sprite (CRÍTICO)

```
CORRECTO ✅                    INCORRECTO ❌
    
   ══►                            ◄══
   Apunta a la DERECHA            Apunta a la IZQUIERDA
   (ángulo 0°)                    (requeriría offset de 180°)
```

El código de rotación es simple:
```gdscript
# AnimatedProjectileSprite.set_direction()
rotation = dir.angle()
```

Si el sprite apunta a la derecha (0°), esto funciona perfectamente para cualquier dirección.

---

## Proceso de Creación

### Paso 1: Generar Sprites con IA

#### Prompt Base (usar siempre al inicio)
```
I need you to create pixel art sprites for a roguelike video game. 

STYLE REQUIREMENTS:
- Art style: Cartoon/Funko Pop - cute, round shapes with big cute features
- Resolution: 64x64 pixels per frame
- Format: Horizontal sprite strip (frames side by side)
- Background: Transparent (checkerboard pattern to show transparency)
- Outline: 1-2 pixel dark outline around all shapes
- Colors: Bold, saturated colors with clear highlights
- Feel: Friendly but magical, suitable for all ages

TECHNICAL REQUIREMENTS:
- Each animation should be a horizontal strip
- Frames should be evenly spaced
- Keep designs centered in each frame
- Leave 2-4 pixels padding from edges
- Use consistent lighting (light from top-left)

CRITICAL ORIENTATION:
- The projectile MUST point to the RIGHT (→) in all frames
- This is essential for in-game rotation to work correctly
```

#### Plantilla para Flight (6 frames) - `flight.png`
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).

Subject: [DESCRIPCIÓN DEL PROYECTIL] in flight

Design:
- Shape: [FORMA PRINCIPAL]
- Main body: [COLOR PRINCIPAL] (#HEXCODE)
- Highlights: [COLOR SECUNDARIO] (#HEXCODE)
- Glow: [COLOR DE BRILLO] (#HEXCODE)
- Outline: [COLOR DE CONTORNO] (#HEXCODE)

CRITICAL ORIENTATION: MUST point to the RIGHT (→) in ALL frames.

Animation: [DESCRIPCIÓN DE LA ANIMACIÓN DE VUELO]
- Frames 1-6: [COMPORTAMIENTO]

Effects:
- Particles trailing behind (to the LEFT, opposite of movement)
- [OTROS EFECTOS]
```

#### Plantilla para Impact (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).

Subject: [DESCRIPCIÓN DEL PROYECTIL] impact/explosion

Design:
- Same color palette as flight
- [COLORES]

Animation: Projectile hitting and exploding
- Frame 1: Just impacted, starting to react
- Frame 2: Explosion burst begins
- Frame 3: Maximum explosion size
- Frame 4: Fragments spreading outward
- Frame 5: Fading, particles remain
- Frame 6: Final particles fading to transparent

Effects:
- [EFECTOS DE EXPLOSIÓN ESPECÍFICOS]
```

### Paso 2: Procesar los Sprites (si es necesario)

Si los sprites generados no tienen las dimensiones correctas, usar el script de procesamiento:

```powershell
cd C:\git\loopialike\utils
python process_sprites_universal.py --input "ruta/sprites_raw" --output "project/assets/sprites/projectiles/{weapon_id}" --weapon "{weapon_id}"
```

### Paso 3: Verificar Orientación

Abrir los sprites en un editor de imágenes y verificar:
1. ¿El proyectil apunta a la DERECHA en `flight.png`?
2. ¿Las dimensiones son correctas? (384x64 para flight e impact)

### Paso 4: Colocar en la Carpeta Correcta

```
project/assets/sprites/projectiles/{weapon_id}/
├── flight.png
└── impact.png
```

El `weapon_id` debe coincidir EXACTAMENTE con el ID en `WeaponDatabase.gd`.

---

## Integración en el Juego

### Configuración Automática

El sistema detecta automáticamente los sprites si:
1. Están en la carpeta correcta: `assets/sprites/projectiles/{weapon_id}/`
2. Los archivos se llaman exactamente: `flight.png`, `impact.png`
3. Las dimensiones son correctas (384x64 cada uno)

### Configuración en ProjectileVisualManager

Si necesitas configuración personalizada, edita `ProjectileVisualManager.gd`:

```gdscript
const WEAPON_SPRITE_CONFIG: Dictionary = {
    "weapon_id": {
        "flight_frames": 6,    # Número de frames en flight.png
        "flight_fps": 12.0,    # Velocidad de animación
        "impact_frames": 6,    # Número de frames en impact.png
        "impact_fps": 15.0,
        "sprite_scale": 0.5    # Escala del sprite (0.5 = 50%)
    }
}
```

### Flujo de Carga de Sprites

```
1. BaseWeapon.perform_attack() 
   ↓
2. ProjectileFactory.create_projectile()
   ↓
3. SimpleProjectile._ready()
   ↓
4. SimpleProjectile._try_create_animated_visual()
   ↓
5. ProjectileVisualManager.create_projectile_visual()
   ↓
6. _try_load_custom_sprites() - Busca en assets/sprites/projectiles/{weapon_id}/
   ↓
7. AnimatedProjectileSprite.setup() - Configura las animaciones
   ↓
8. AnimatedProjectileSprite.set_direction() - Aplica rotation = dir.angle()
```

---

## Checklist de Verificación

### Antes de Generar Sprites
- [ ] Tengo el `weapon_id` correcto de `WeaponDatabase.gd`
- [ ] Conozco los colores del elemento (revisar otros sprites del mismo elemento)
- [ ] El prompt incluye "MUST point to the RIGHT (→)"

### Después de Generar Sprites
- [ ] **Orientación**: El proyectil apunta a la DERECHA (→)
- [ ] **Dimensiones flight.png**: 384x64 (6 frames de 64x64)
- [ ] **Dimensiones impact.png**: 384x64 (6 frames de 64x64)
- [ ] **Formato**: PNG con fondo transparente
- [ ] **Nombres de archivo**: Exactamente `flight.png`, `impact.png`

### Después de Colocar en el Proyecto
- [ ] Carpeta correcta: `project/assets/sprites/projectiles/{weapon_id}/`
- [ ] El `weapon_id` coincide con `WeaponDatabase.gd`
- [ ] Ejecutar el juego y verificar visualmente

### Test en el Juego
- [ ] Abrir escena de test de armas
- [ ] Equipar el arma
- [ ] Disparar en TODAS las direcciones:
  - [ ] Derecha (→) - El sprite NO debe rotar
  - [ ] Arriba (↑) - El sprite debe rotar -90°
  - [ ] Izquierda (←) - El sprite debe rotar 180°
  - [ ] Abajo (↓) - El sprite debe rotar 90°
  - [ ] Diagonales

---

## Solución de Problemas

### Problema: El proyectil rota incorrectamente

**Síntoma**: El sprite apunta en dirección equivocada en algunas direcciones.

**Causa más probable**: El sprite NO apunta a la derecha en el archivo original.

**Solución**:
1. Abrir `flight.png` en un editor de imágenes
2. Verificar que el proyectil apunta a la DERECHA (→)
3. Si no, rotar el sprite 180° y guardar

### Problema: No aparece el sprite animado

**Síntoma**: Se ve un círculo/forma procedural en lugar del sprite personalizado.

**Causas posibles**:
1. La carpeta no existe o tiene nombre incorrecto
2. Los archivos no se llaman `flight.png`, `impact.png`
3. El `weapon_id` no coincide con la carpeta

**Solución**:
```gdscript
# Añadir este log en SimpleProjectile._try_create_animated_visual()
print("Buscando sprites para: %s" % _weapon_id)
```

### Problema: Las dimensiones son incorrectas

**Síntoma**: El sprite se ve cortado o con frames incorrectos.

**Solución**: Usar el script de verificación:
```powershell
# PowerShell - Verificar dimensiones
Get-ChildItem "project\assets\sprites\projectiles\{weapon_id}\*.png" | ForEach-Object {
    $img = [System.Drawing.Image]::FromFile($_.FullName)
    Write-Host "$($_.Name) - $($img.Width)x$($img.Height)"
    $img.Dispose()
}
```

Dimensiones esperadas:
- `flight.png`: 384x64
- `impact.png`: 384x64

### Problema: Doble rotación

**Síntoma**: El sprite rota el doble de lo esperado.

**Causa**: Algo está rotando tanto el nodo padre como el sprite hijo.

**Verificación**: Buscar estos logs:
```
parent_rot=0.00°    ← DEBE ser 0
sprite_rot=X°       ← Debe coincidir con el ángulo de dirección
```

Si `parent_rot` NO es 0, hay algo rotando el nodo SimpleProjectile.

**Archivos a revisar**:
- `ProjectileFactory.gd` - No debe haber `projectile.rotation = ...`
- Cualquier código que cree proyectiles manualmente

---

## Paleta de Colores por Elemento

| Elemento | Principal | Secundario | Brillo | Contorno |
|----------|-----------|------------|--------|----------|
| Ice      | #66CCFF   | #99EEFF    | #FFFFFF| #1A3A5C  |
| Fire     | #FF6611   | #FFCC00    | #FF9944| #661100  |
| Lightning| #FFFF4D   | #FFFFFF    | #FFFFCC| #CC9900  |
| Arcane   | #9933FF   | #CC66FF    | #E6CCFF| #330066  |
| Shadow   | #4D1A66   | #9933CC    | #663399| #1A0033  |
| Nature   | #4DCC33   | #99FF66    | #CCFF99| #1A4D13  |
| Wind     | #E6FFFF   | #CCFFFF    | #FFFFFF| #99CCCC  |
| Earth    | #996633   | #CC9966    | #FFCC99| #4D3319  |
| Light    | #FFFF99   | #FFFFCC    | #FFFFFF| #CCCC66  |
| Void     | #330033   | #660066    | #990099| #1A001A  |

---

## Resumen Rápido

```
1. SIEMPRE apuntar a la DERECHA (→)
2. Dimensiones: flight=384x64, impact=384x64
3. Carpeta: project/assets/sprites/projectiles/{weapon_id}/
4. Archivos: flight.png, impact.png
5. Probar en TODAS las direcciones
```

¡Eso es todo! Siguiendo esta guía, los sprites de proyectiles deberían funcionar correctamente a la primera.
