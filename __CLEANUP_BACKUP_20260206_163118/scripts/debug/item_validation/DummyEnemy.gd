extends CharacterBody2D
class_name DummyEnemy

signal damage_taken(amount, is_crit)
signal status_applied(name, duration, params)
signal status_removed(name)

@onready var health_component = $HealthComponent

# Status State
var _burn_timer: float = 0.0
var _burn_damage: float = 0.0
var _burn_tick_timer: float = 0.0
var _is_burning: bool = false
const BURN_TICK_INTERVAL: float = 0.5

var _bleed_timer: float = 0.0
var _bleed_damage: float = 0.0
var _bleed_tick_timer: float = 0.0
var _is_bleeding: bool = false
const BLEED_TICK_INTERVAL: float = 0.5

var _freeze_timer: float = 0.0
var _slow_timer: float = 0.0
var _stun_timer: float = 0.0

func _ready():
	add_to_group("enemies")
	add_to_group("test_dummy")

func _process(delta: float):
	# Burn Logic
	if _is_burning:
		_burn_timer -= delta
		_burn_tick_timer += delta
		if _burn_tick_timer >= BURN_TICK_INTERVAL:
			_burn_tick_timer = 0.0
			take_damage(_burn_damage, Vector2.ZERO, {"element": "fire"})
			
		if _burn_timer <= 0:
			_is_burning = false
			status_removed.emit("burn")

	# Bleed Logic
	if _is_bleeding:
		_bleed_timer -= delta
		_bleed_tick_timer += delta
		if _bleed_tick_timer >= BLEED_TICK_INTERVAL:
			_bleed_tick_timer = 0.0
			take_damage(_bleed_damage, Vector2.ZERO, {"element": "bleed"})
			
		if _bleed_timer <= 0:
			_is_bleeding = false
			status_removed.emit("bleed")

	# Tracking other timers
	if _freeze_timer > 0:
		_freeze_timer -= delta
		if _freeze_timer <= 0: status_removed.emit("freeze")
			
	if _slow_timer > 0:
		_slow_timer -= delta
		if _slow_timer <= 0: status_removed.emit("slow")
			
	if _stun_timer > 0:
		_stun_timer -= delta
		if _stun_timer <= 0: status_removed.emit("stun")

func take_damage(amount: float, _knockback_force: Vector2 = Vector2.ZERO, source = null):
	var is_crit = false 
	var element = "physical"
	
	if source is Dictionary and source.has("element"):
		element = source["element"]
	
	if health_component:
		if health_component.has_method("take_damage"):
			health_component.take_damage(int(amount), element)
		
		# For validation signal, we just emit amount/crit
		damage_taken.emit(amount, is_crit)

# --- Status Methods ---

func apply_burn(damage_per_tick: float, duration: float) -> void:
	if _is_burning:
		_burn_damage = max(_burn_damage, damage_per_tick)
		_burn_timer = max(_burn_timer, duration)
	else:
		_burn_damage = damage_per_tick
		_burn_timer = duration
		_burn_tick_timer = 0.0
		_is_burning = true
	
	status_applied.emit("burn", _burn_timer, {"damage": _burn_damage})

func apply_bleed(damage_per_tick: float, duration: float) -> void:
	if _is_bleeding:
		_bleed_damage = max(_bleed_damage, damage_per_tick)
		_bleed_timer = max(_bleed_timer, duration)
	else:
		_bleed_damage = damage_per_tick
		_bleed_timer = duration
		_bleed_tick_timer = 0.0
		_is_bleeding = true
	
	status_applied.emit("bleed", _bleed_timer, {"damage": _bleed_damage})

func apply_freeze(amount: float, duration: float) -> void:
	_freeze_timer = max(_freeze_timer, duration)
	status_applied.emit("freeze", duration, {"amount": amount})

func apply_slow(amount: float, duration: float) -> void:
	_slow_timer = max(_slow_timer, duration)
	status_applied.emit("slow", duration, {"amount": amount})
	
func apply_stun(duration: float) -> void:
	_stun_timer = max(_stun_timer, duration)
	status_applied.emit("stun", duration, {})

func apply_pull(_center: Vector2, _force: float, duration: float) -> void:
	# Mock pull
	status_applied.emit("pull", duration, {"center": _center, "force": _force})

func apply_blind(duration: float) -> void:
	status_applied.emit("blind", duration, {})

# --- Observability API ---

func get_active_statuses() -> Dictionary:
	var statuses = {}
	
	if _is_burning:
		statuses["burn"] = {
			"remaining_time": _burn_timer,
			"damage_per_tick": _burn_damage, 
			"tick_interval": BURN_TICK_INTERVAL,
			"active": true
		}
		
	if _is_bleeding:
		statuses["bleed"] = {
			"remaining_time": _bleed_timer,
			"damage_per_tick": _bleed_damage,
			"tick_interval": BLEED_TICK_INTERVAL,
			"active": true
		}
		
	if _freeze_timer > 0:
		statuses["freeze"] = {"remaining_time": _freeze_timer, "active": true}
		
	if _slow_timer > 0:
		statuses["slow"] = {"remaining_time": _slow_timer, "active": true}
		
	if _stun_timer > 0:
		statuses["stun"] = {"remaining_time": _stun_timer, "active": true}
		
	return statuses

func is_burning() -> bool: return _is_burning
func is_bleeding() -> bool: return _is_bleeding
func is_frozen() -> bool: return _freeze_timer > 0
func is_slowed() -> bool: return _slow_timer > 0
func is_stunned() -> bool: return _stun_timer > 0
