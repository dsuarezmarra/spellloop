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
    var _gt = get_tree()
    sm = _gt.root.get_node_or_null("SaveManager") if _gt and _gt.root else null
    var currency = 0
    var luck = 0
    if sm and sm.has_method("get_player_progression"):
        var pd = sm.get_player_progression()
        currency = pd.get("meta_currency", 0)
    if sm and sm.has_method("get_meta_data"):
        var meta = sm.get_meta_data()
        luck = int(meta.get("luck_points", 0))
    info_label.text = "Meta Currency: %d\nLuck: %d\nBuy +1 Luck for 50" % [currency, luck]

func _on_buy_pressed():
    var sm = null
    var _gt2 = get_tree()
    sm = _gt2.root.get_node_or_null("SaveManager") if _gt2 and _gt2.root else null
    if not sm:
        return
    var pd = sm.get_player_progression()
    var currency = pd.get("meta_currency", 0)
    var cost = 50
    if currency < cost:
        # Not enough currency
        var _gt3 = get_tree()
        var ui_err = _gt3.root.get_node_or_null("UIManager") if _gt3 and _gt3.root else null
        if ui_err and ui_err.has_method("show_notification"):
            ui_err.show_notification("Not enough Meta Currency")
        return

    # Deduct currency
    pd["meta_currency"] = currency - cost

    # Add luck via public API
    if sm.has_method("add_meta_luck"):
        sm.add_meta_luck(1)
    elif sm.has_method("get_meta_data") and sm.has_method("set_meta_value"):
        var meta2 = sm.get_meta_data()
        meta2["luck_points"] = int(meta2.get("luck_points", 0)) + 1
        sm.set_meta_value("luck_points", meta2["luck_points"])

    # Persist changes
    if sm.has_method("save_game_data"):
        sm.save_game_data()

    emit_signal("purchase_made", cost, 1)
    refresh()

    # small confirmation
    var _gt4 = get_tree()
    var ui = _gt4.root.get_node_or_null("UIManager") if _gt4 and _gt4.root else null
    if ui and ui.has_method("show_notification"):
        ui.show_notification("Bought +1 Luck")

