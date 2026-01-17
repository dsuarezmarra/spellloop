extends Node2D

# Referencias
var player: CharacterBody2D
var ui_layer: CanvasLayer
var debug_panel: PanelContainer

# Configuración
const WEAPON_IDS = ["magic_wand", "axe", "garlic", "fire_wand", "lightning_ring", "runetracer"]
const UPGRADE_IDS = ["spinach", "armor", "hollow_heart", "pummarola", "empty_tome", "candelabrador"]

func _ready():
    # 0. Asegurar Mouse Visible
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    
    # 1. Configurar Entorno
    setup_environment()
    
    # 2. Spawnear Player
    spawn_player()
    
    # 3. Crear UI de Debug
    create_debug_ui()
    
    print("[TestGym] Iniciado. Usa el panel para probar armas.")

func setup_environment():
    # Fondo simple
    var bg = ColorRect.new()
    bg.color = Color(0.1, 0.1, 0.15)
    bg.size = Vector2(5000, 5000)
    bg.position = Vector2(-2500, -2500)
    bg.z_index = -100
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE # FIX: No bloquear inputs
    add_child(bg)
    
    # Grid visual (opcional)
    # ...

func spawn_player():
    # Intentar cargar la escena del player real
    var player_scene = load("res://scenes/entities/Player.tscn")
    if player_scene:
        player = player_scene.instantiate()
    else:
        # Fallback si no existe la escena (crear uno básico)
        printerr("[TestGym] Warn: No se encontró Player.tscn, creando dummy")
        player = CharacterBody2D.new()
        var sprite = Sprite2D.new()
        sprite.texture = PlaceholderTexture2D.new()
        sprite.scale = Vector2(20, 20)
        player.add_child(sprite)
        
        # Necesita componentes básicos para funcionar con managers
        var collision = CollisionShape2D.new()
        var shape = CircleShape2D.new()
        shape.radius = 10
        collision.shape = shape
        player.add_child(collision)
        
        # Añadir AttackManager si es necesario
        if not player.has_node("AttackManager"):
            var am = AttackManager.new()
            am.name = "AttackManager"
            player.add_child(am)
            # CRITICAL FIX: Initialize AttackManager with player reference
            am.initialize(player)
            
        # Añadir PlayerStats stats
        player.set_meta("stats", PlayerStats.new())
    
    player.position = Vector2(640, 360) # Centro pantalla aprox
    add_child(player)
    
    # Ensure AttackManager is initialized if we loaded a scene that didn't auto-init
    var am = player.get_node_or_null("AttackManager")
    if am and not am.player:
        am.initialize(player)
    
    # Configurar cámara
    var cam = Camera2D.new()
    player.add_child(cam)
    cam.make_current()

func create_debug_ui():
    ui_layer = CanvasLayer.new()
    add_child(ui_layer)
    
    debug_panel = PanelContainer.new()
    debug_panel.position = Vector2(20, 20)
    ui_layer.add_child(debug_panel)
    
    var vbox = VBoxContainer.new()
    debug_panel.add_child(vbox)
    
    # Título
    var label = Label.new()
    label.text = "🧪 TEST GYM"
    vbox.add_child(label)
    
    # Botones Armas
    var weapons_label = Label.new()
    weapons_label.text = "-- Armas --"
    vbox.add_child(weapons_label)
    
    var grid = GridContainer.new()
    grid.columns = 2
    vbox.add_child(grid)
    
    for wid in WEAPON_IDS:
        var btn = Button.new()
        btn.text = "+ " + wid.capitalize()
        btn.pressed.connect(_on_add_weapon.bind(wid))
        grid.add_child(btn)
        
    # Botones Utilidad
    var util_label = Label.new()
    util_label.text = "-- Utilidad --"
    vbox.add_child(util_label)
    
    var btn_dummy = Button.new()
    btn_dummy.text = "Spawn Dummy Target"
    btn_dummy.pressed.connect(_spawn_dummy)
    vbox.add_child(btn_dummy)
    
    var btn_clear = Button.new()
    btn_clear.text = "Clear Weapons"
    btn_clear.pressed.connect(_clear_weapons)
    vbox.add_child(btn_clear)

    var btn_auto = Button.new()
    btn_auto.text = "▶ RUN AUTO-TEST"
    btn_auto.modulate = Color(0.5, 1, 0.5)
    btn_auto.pressed.connect(_run_auto_test_sequence)
    vbox.add_child(btn_auto)

    var btn_heal = Button.new()
    btn_heal.text = "Heal Player"
    btn_heal.pressed.connect(func(): if player.has_method("heal"): player.heal(100))
    vbox.add_child(btn_heal)

# --- Acciones ---

func _on_add_weapon(id: String):
    print("[TestGym] Intentando añadir arma: ", id)
    # Buscar AttackManager
    var am = player.get_node_or_null("AttackManager")
    # Si no es nulo y tiene el método
    if am and am.has_method("add_weapon_by_id"):
        var res = am.add_weapon_by_id(id)
        if res:
            _show_toast("Added: " + id)
        else:
            _show_toast("Failed to add: " + id)
    elif am and am.has_method("add_weapon"):
        # Fallback a add_weapon directo si es necesario
        var w = BaseWeapon.new(id)
        var res = am.add_weapon(w)
        if res:
             _show_toast("Added (BaseWeapon): " + id)
    else:
        printerr("[TestGym] Error: Player no tiene AttackManager o método add_weapon_by_id")

func _spawn_dummy():
    var dummy = Node2D.new()
    dummy.name = "DummyTarget"
    
    var sprite = Sprite2D.new()
    # Texture placeholder roja
    var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
    img.fill(Color.RED)
    sprite.texture = ImageTexture.create_from_image(img)
    dummy.add_child(sprite)
    
    # Hacerlo "enemigo" para que las armas le apunten
    dummy.add_to_group("enemies")
    
    # Posición aleatoria cerca del player
    var offset = Vector2(randf_range(-200, 200), randf_range(-200, 200))
    dummy.position = player.position + offset
    
    # Añadir colisión básica si es necesaria para detección
    # Muchos sistemas usan Area2D o checkean distancia.
    # Vamos a añadir un Area2D por si acaso.
    var area = Area2D.new()
    var col = CollisionShape2D.new()
    var shape = CircleShape2D.new()
    shape.radius = 20
    col.shape = shape
    area.add_child(col)
    dummy.add_child(area)
    
    # Script básico para recibir daño (si las armas llaman a take_damage)
    var script = GDScript.new()
    script.source_code = """
    extends Node2D
    var health = 999999
    
    func take_damage(amount, _source=null):
        # Efecto visual simple (print o label flotante)
        var label = Label.new()
        label.text = str(int(amount))
        label.modulate = Color.RED
        label.z_index = 100
        add_child(label)
        var tw = create_tween()
        tw.tween_property(label, "position", Vector2(0, -50), 0.5)
        tw.tween_callback(label.queue_free)
    """
    dummy.set_script(script)
    
    add_child(dummy)
    _show_toast("Dummy Spawned")

func _clear_weapons():
    var am = player.get_node_or_null("AttackManager")
    if am and "weapons" in am:
        am.weapons.clear() # Limpieza forzada básica
        _show_toast("Weapons Cleared")

func _show_toast(msg: String):
    var label = Label.new()
    label.text = msg
    label.position = Vector2(player.position.x - 50, player.position.y - 100)
    label.z_index = 200
    label.modulate = Color.YELLOW
    add_child(label)
    var tw = create_tween()
    tw.tween_property(label, "position", Vector2(label.position.x, label.position.y - 50), 1.0)
    tw.tween_property(label, "modulate:a", 0.0, 1.0)
    tw.tween_callback(label.queue_free)

func _run_auto_test_sequence():
    print("[TestGym] Starting Auto-Test Sequence...")
    _show_toast("STARTED AUTO-TEST")
    _clear_weapons()
    
    # Create a coroutine-like sequence using manual timer or tween
    var tw = create_tween()
    
    # Step 1: Equip Magic Wand
    tw.tween_callback(func(): 
        _on_add_weapon("magic_wand")
        _show_toast("Testing: Magic Wand")
    )
    tw.tween_interval(1.5)
    
    # Step 2: Equip Axe
    tw.tween_callback(func(): 
        _on_add_weapon("axe")
        _show_toast("Testing: Axe")
    )
    tw.tween_interval(1.5)
    
    # Step 3: Equip many
    tw.tween_callback(func():
        _on_add_weapon("garlic")
        _on_add_weapon("fire_wand")
        _on_add_weapon("lightning_ring")
        _show_toast("Stress Test: Adding 3 more...")
    )
    tw.tween_interval(2.0)
    
    # Finish
    tw.tween_callback(func():
        var am = player.get_node_or_null("AttackManager")
        var count = am.get_weapon_count() if am else 0
        if count >= 5:
            _show_toast("✅ TEST PASSED: 5 Weapons Active")
        else:
            _show_toast("❌ TEST FAILED: Count mismatch")
    )
