
func _on_jackpot_item_pressed(index: int, item: Dictionary):
	"""Manejar click/selección de item en jackpot"""
	if popup_locked: return
	
	# Verificar si ya fue reclamado
	if _jackpot_claimed_items.has(item):
		# Ya reclamado -> No hacer nada o avisar
		return
		
	# Toggle estado "pendiente"
	var panel = item_buttons[index]
	var is_claimed = panel.get_meta("is_claimed", false)
	
	# Invertir estado
	is_claimed = !is_claimed
	panel.set_meta("is_claimed", is_claimed)
	
	# Actualizar UI
	_update_jackpot_item_visual(panel, is_claimed)
	
	# Actualizar botón de "Reclamar Seleccionados"
	_update_claim_selected_button()

func _update_jackpot_item_visual(panel: Control, is_selected: bool):
	"""Actualizar visual del item (borde verde si seleccionado)"""
	var style = panel.get_theme_stylebox("panel").duplicate()
	if is_selected:
		style.border_color = Color(0.2, 1.0, 0.4) # Verde brillante
		style.bg_color = Color(0.1, 0.3, 0.1, 0.8) # Fondo verdoso
		# Checkbox update
		var status = panel.find_child("StatusLabel", true, false)
		if status:
			status.text = "✅ Seleccionado"
			status.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	else:
		# Restaurar estilo original basado en rareza
		var item_data = panel.get_meta("item_data")
		var rarity = item_data.get("rarity", 0) + 1
		var base_style = UIVisualHelper.get_panel_style(rarity, false, false) # fallback
		style.border_color = base_style.border_color
		style.bg_color = base_style.bg_color
		
		var status = panel.find_child("StatusLabel", true, false)
		if status:
			status.text = "⬜ Pendiente"
			status.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			
	panel.add_theme_stylebox_override("panel", style)

func _update_claim_selected_button():
	"""Mostrar/Ocultar botón de reclamar parcial"""
	var count = 0
	for p in item_buttons:
		if p.get_meta("is_claimed", false):
			count += 1
			
	var btn = get_meta("claim_selected_btn", null)
	if btn:
		btn.visible = (count > 0 and count < item_buttons.size())

func _on_claim_all_pressed():
	"""Reclamar TODOS los items"""
	if popup_locked: return
	popup_locked = true
	all_items_claimed.emit(_jackpot_pending_items)
	queue_free()

func _on_claim_selected_pressed():
	"""Reclamar SOLO los seleccionados"""
	if popup_locked: return
	popup_locked = true
	
	var selected_items = []
	for p in item_buttons:
		if p.get_meta("is_claimed", false):
			selected_items.append(p.get_meta("item_data"))
			
	if selected_items.size() > 0:
		all_items_claimed.emit(selected_items)
	else:
		skipped.emit()
	queue_free()
