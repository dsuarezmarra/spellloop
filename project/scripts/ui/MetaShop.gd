extends Control

class_name MetaShop

signal purchase_made(cost: int, luck_points: int)

@onready var info_label: Label = $VBox/InfoLabel
@onready var buy_button: Button = $VBox/BuyButton

func _ready():
    buy_button.pressed.connect(_on_buy_pressed)
    refresh()

func refresh():
    var sm = null
    if get_tree() and get_tree().root and get_tree().root.has_node("SaveManager"):
        sm = get_tree().root.get_node("SaveManager")
    var currency = 0
    if sm and sm.has_method("get_player_progression"):
        var pd = sm.get_player_progression()
        currency = pd.get("meta_currency", 0)
    info_label.text = "Meta Currency: %d\nBuy +1 Luck for 50" % [currency]

func _on_buy_pressed():
    var sm = null
    if get_tree() and get_tree().root and get_tree().root.has_node("SaveManager"):
        sm = get_tree().root.get_node("SaveManager")
    if not sm:
        return
    var pd = sm.get_player_progression()
    var currency = pd.get("meta_currency", 0)
    var cost = 50
    if currency >= cost:
        pd["meta_currency"] = currency - cost
        # ensure meta defaults exist and add luck
        if sm.has_method("get_meta_data"):
            var meta = sm.get_meta_data()
            meta["luck_points"] = int(meta.get("luck_points", 0)) + 1
            sm._save_meta()
        sm.save_game_data()
        emit_signal("purchase_made", cost, 1)
        refresh()
        # small confirmation
        if get_tree() and get_tree().root and get_tree().root.has_node("UIManager"):
            var ui = get_tree().root.get_node("UIManager")
            if ui and ui.has_method("show_notification"):
                ui.show_notification("Bought +1 Luck")
