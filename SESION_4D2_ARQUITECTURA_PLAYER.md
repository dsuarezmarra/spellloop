# 🏗️ SESIÓN 4D-2 - ARQUITECTURA PLAYER GENÉRICA

## 📋 Resumen

Se implementó una **arquitectura escalable de personajes** basada en herencia:

```
BasePlayer (Genérico)
    └── WizardPlayer (Específico)
            └── SpellloopPlayer (Wrapper de escena)
```

---

## 🎯 Estructura Nueva

### 1️⃣ **BasePlayer.gd** (scripts/entities/players/BasePlayer.gd)
**Clase base genérica** para todos los personajes

**Responsabilidades:**
- ✅ Movimiento centrado (el mundo se mueve, player fijo)
- ✅ Sistema de salud (HealthComponent)
- ✅ Física y colisiones
- ✅ Equipamiento de armas (AttackManager)
- ✅ Estadísticas base (HP, armor, speed, etc.)
- ✅ Señales generales (damaged, died, movement_input)

**Métodos a sobrescribir en subclases:**
```gdscript
func _setup_animations() -> void:
	# Las subclases implementan esto
	
func _equip_starting_weapons() -> void:
	# Las subclases equipan sus armas específicas
```

**Ventajas:**
- Una sola implementación de salud, física, movimiento
- Fácil crear nuevos personajes (solo heredar)
- Lógica compartida = código limpio

---

### 2️⃣ **WizardPlayer.gd** (scripts/entities/players/WizardPlayer.gd)
**Clase específica** para el Mago

**Características únicas:**
- 🧙 Spell Power: 1.2x (20% más daño en hechizos)
- 🧙 Mana: 50/50
- 🧙 Armas: Varita de Hielo, Varita de Fuego
- 🧙 Estadísticas: Más magia, menos defensa

**Métodos sobrescritos:**
```gdscript
func _setup_animations() -> void:
	# Carga sprites específicos del wizard

func _equip_starting_weapons() -> void:
	# Equipa Ice Wand (+ debug output exhaustivo)
```

**Debug Output Agregado (4E):**
```
[WizardPlayer] === EQUIPANDO ARMAS INICIALES ===
[WizardPlayer] Cargando IceWand.gd...
[WizardPlayer] Script de IceWand cargado correctamente
[WizardPlayer] Instanciando IceWand...
[WizardPlayer] IceProjectile.tscn cargado
[WizardPlayer] === ESTADO PRE-EQUIP ===
[WizardPlayer] Armas antes: 0
[WizardPlayer] ice_wand.id: ice_wand
[WizardPlayer] === ESTADO POST-EQUIP ===
[WizardPlayer] Armas después: 1        ← CRÍTICO: Debe ser 1
```

---

### 3️⃣ **SpellloopPlayer.gd** (scripts/entities/SpellloopPlayer.gd)
**Wrapper** que la escena utiliza

**Propósito:**
- Mantener `class_name SpellloopPlayer` para compatibilidad de escenas
- Delegar toda la lógica a WizardPlayer dinámicamente
- Propagar señales y sincronizar propiedades

**Flujo en _ready():**
```
1. Cargar WizardPlayer.gd
2. Instanciar wizard_player = WizardPlayer.new()
3. Pasar referencias visuales (sprite, position)
4. Conectar señales del wizard a SpellloopPlayer
5. Llamar wizard_player._ready() (inicializa BasePlayer)
6. Copiar referencias visuales de vuelta
7. Sincronizar stats (hp, max_hp, move_speed)
```

---

## 🔗 Jerarquía de Inicialización

```
SpellloopPlayer._ready()
    ↓
    ├─ Cargar WizardPlayer.gd
    ├─ Instanciar WizardPlayer()
    ├─ Pasar referencias
    ├─ Conectar señales
    │
    └─ wizard_player._ready()
            ↓
            └─ BasePlayer._ready()
                ├─ _initialize_health_component()
                ├─ _initialize_visual()
                │   └─ _setup_animations()    ← WizardPlayer implementa
                ├─ _initialize_physics()
                ├─ _find_global_managers()
                │
                └─ _setup_weapons_deferred()
                    └─ _equip_starting_weapons()    ← WizardPlayer implementa
                        └─ equip_weapon(ice_wand)
                            └─ AttackManager.add_weapon()
```

---

## 📊 Relación con AttackManager

```
SpellloopPlayer (Escena)
    ↓
WizardPlayer
    ↓
BasePlayer
    ├─ attack_manager (Referencia encontrada en _find_global_managers())
    │
    └─ equip_weapon(weapon)
        └─ attack_manager.add_weapon(weapon)
            └─ weapons.append(weapon)
            └─ weapon_added.emit(weapon)
```

**Problema 4D anterior:** AttackManager not inicializado → fix en BasePlayer con await:
```gdscript
func _setup_weapons_deferred() -> void:
	await get_tree().process_frame  # Esperar un frame
	
	if attack_manager:
		attack_manager.initialize(self)
		_equip_starting_weapons()
```

---

## 🛠️ Cómo Crear un Nuevo Personaje

**Ejemplo: RoguePlayer**

```gdscript
# scripts/entities/players/RoguePlayer.gd
extends BasePlayer
class_name RoguePlayer

var character_class: String = "Rogue"
var character_sprites_key: String = "rogue"

@export var move_speed: float = 280.0  # Más rápido
@export var hp: int = 60               # Menos vida

var crit_chance: float = 0.5           # 50% crítico (especial)

func _setup_animations() -> void:
	# Cargar sprites de rogue
	var sprite_db = get_tree().root.get_node_or_null("SpriteDB")
	# ... configure rogue animations ...

func _equip_starting_weapons() -> void:
	# Equipar dagger + poison
	var dagger_script = load("res://scripts/entities/weapons/daggers/Dagger.gd")
	var dagger = dagger_script.new()
	equip_weapon(dagger)
```

**Luego crear KnightSpellloopPlayer o RogueSpellloopPlayer:**

```gdscript
# SpellloopPlayer ahora puede recibir parámetro
# var character_class = "rogue"  # En exportar o argumento
```

---

## 🐛 Arreglos Aplicados en 4D

### Fix #1: IceWand extends Resource → RefCounted ✅
**Archivo:** `IceWand.gd`
```gdscript
# Antes:
extends Resource

# Ahora:
extends RefCounted
```
**Por qué:** RefCounted es más ligero y apropiado para objetos runtime instantiados dinámicamente.

### Fix #2: InfiniteWorldManager biome_index ✅
**Archivo:** `InfiniteWorldManager.gd`
```gdscript
# Antes:
var tex = generator.generate_chunk_texture_enhanced(Vector2i.ZERO, CHUNK_SIZE)

# Ahora:
var biome_index = match(biome)...
var pos_for_generation = Vector2i(biome_index * 1000, biome_index * 1000)
var tex = generator.generate_chunk_texture_enhanced(pos_for_generation, CHUNK_SIZE)
```
**Por qué:** Diferentes biomas generan diferentes texturas (FastNoiseLite crea ruido diferente para X,Y diferentes).

### Fix #3: BasePlayer await antes de equip_weapons ✅
**Archivo:** `BasePlayer.gd`
```gdscript
func _setup_weapons_deferred() -> void:
	await get_tree().process_frame
	
	if attack_manager:
		attack_manager.initialize(self)
		_equip_starting_weapons()
```
**Por qué:** Asegurar que todo esté inicializado antes de equipar armas.

### Fix #4: WizardPlayer debug output exhaustivo ✅
**Archivo:** `WizardPlayer.gd`
- Logging PRE-equip: estado inicial del array
- Logging DURANTE: confirmación de carga de archivos
- Logging POST-equip: verificación de que arma se agregó

---

## ✨ Beneficios de esta Arquitectura

1. **DRY (Don't Repeat Yourself):**
   - Un solo HealthComponent, Physics, Movimiento
   - Otros personajes solo heredan

2. **Extensibilidad:**
   - Agregar Rogue, Knight, etc. es trivial
   - Solo 50 líneas por personaje vs 400 antes

3. **Debuggable:**
   - Cada personaje puede agregar su propio logging
   - BasePlayer proporciona hooks (_setup_animations, _equip_starting_weapons)

4. **Testeable:**
   - Crear personaje test: `WizardPlayer.new()` sin escena
   - Verificar que armas se equipan correctamente

5. **Flexible:**
   - Cambiar personaje en runtime: crear `RoguePlayer.new()`
   - Soportar múltiples personajes sin duplicar código

---

## 📝 Archivos Creados/Modificados

| Archivo | Cambio | Estado |
|---------|--------|--------|
| `BasePlayer.gd` | Creado - Clase base genérica | ✅ |
| `WizardPlayer.gd` | Creado - Clase específica Wizard | ✅ |
| `SpellloopPlayer.gd` | Reescrito - Wrapper de escena | ✅ |
| `IceWand.gd` | Resource → RefCounted | ✅ |
| `InfiniteWorldManager.gd` | Fix biome texturas | ✅ |
| `GameManager.gd` | Debug output (anterior 4D) | ✅ |

---

## 🚀 Próximos Pasos

1. **Ejecutar F5** - Verificar si Weapons: 1 (no 0)
2. **Revisar Console:**
   - Buscar `[WizardPlayer] === EQUIPANDO ARMAS INICIALES ===`
   - Buscar `[WizardPlayer] Armas después: 1`
3. **Si persiste Weapons: 0:**
   - Verificar si `_equip_starting_weapons()` se ejecuta
   - Revisar si `attack_manager.add_weapon()` agrega correctamente
4. **Verificar Texturas:**
   - Chunks deben tener diferentes colores (verde, blanco, etc.)
5. **Limpiar Debug Output:**
   - Una vez funcione, reducir prints en WizardPlayer

---

Generado: Sesión 4D-2 (Arquitectura Player)  
Estado: Archivos creados, pronto F5 para validar
