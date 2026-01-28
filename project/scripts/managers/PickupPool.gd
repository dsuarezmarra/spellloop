# PickupPool.gd
# Sistema de pooling para recolectables (Monedas, XP, etc.)
# Reduce overhead de instanciación y Garbage Collection.

extends Node

# Configuración
const MAX_POOL_SIZE = 300
const INITIAL_POOL_SIZE = 50

# Pool
var _pool: Array[CoinPickup] = []
var _active_pickups: Array[CoinPickup] = []
var _base_pickup_scene: PackedScene = null

func _ready() -> void:
    # Registrar como singleton de grupo
    add_to_group("pickup_pool")
    
    # Cargar escena base si existe, o usar script base
    # Por ahora asumimos que CoinPickup es nuestro objeto base
    # Si CoinPickup es un script puro attached a un nodo, necesitamos saber cómo instanciarlo.
    # Dado que CoinPickup.gd era usado como script en Area2D prefabricados, 
    # necesitamos saber si hay una escena .tscn.
    # Revisión de código anterior sugiere que CoinPickup.gd crea sus hijos por código (_setup_collision, _setup_visual).
    # Así que podemos instanciar el script directamente en un Area2D.
    
    _prefill_pool()

func _prefill_pool() -> void:
    for i in range(INITIAL_POOL_SIZE):
        var pickup = _create_new_pickup()
        pickup.process_mode = Node.PROCESS_MODE_DISABLED
        pickup.visible = false
        _pool.append(pickup)
        # No añadir al tree todavía para ahorrar

func _create_new_pickup() -> CoinPickup:
    var pickup = CoinPickup.new()
    pickup.name = "CoinPickup"
    return pickup

func get_pickup(pos: Vector2, value: int, type_hint = null) -> CoinPickup:
    var pickup: CoinPickup
    
    if _pool.is_empty():
        pickup = _create_new_pickup()
    else:
        pickup = _pool.pop_back()
    
    # Asegurar que está en el árbol
    if not pickup.is_inside_tree():
        add_child(pickup)
        
    pickup.process_mode = Node.PROCESS_MODE_INHERIT
    pickup.visible = true
    
    # Añadir a tracking activos
    _active_pickups.append(pickup)
    
    # Inicializar
    # CoinPickup espera 'type' como enum, podemos inferirlo del value si es null
    if type_hint != null:
        pickup.initialize(pos, value, null, type_hint)
    else:
        pickup.initialize_by_value(pos, value, null)
        
    return pickup

func return_pickup(pickup: CoinPickup) -> void:
    if not is_instance_valid(pickup):
        return
        
    # Desactivar
    pickup.process_mode = Node.PROCESS_MODE_DISABLED
    pickup.visible = false
    pickup.global_position = Vector2(-9999, -9999) # Lejos
    
    _active_pickups.erase(pickup)
    
    if _pool.size() < MAX_POOL_SIZE:
        _pool.append(pickup)
    else:
        pickup.queue_free()

func clear_active() -> void:
    # Devolver todos los activos al pool (ej: fin de partida)
    # Copia segura para iterar
    var active = _active_pickups.duplicate()
    for p in active:
        return_pickup(p)
