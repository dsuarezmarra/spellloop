# ThemeManager.gd
# Manages consistent theming across the entire game UI
# Provides standardized colors, fonts, styles, and spacing

extends Node

signal theme_changed(theme_name: String)

# Color Palette
enum ColorScheme {
	PRIMARY,
	SECONDARY,
	ACCENT,
	SUCCESS,
	WARNING,
	ERROR,
	INFO,
	BACKGROUND,
	SURFACE,
	TEXT_PRIMARY,
	TEXT_SECONDARY,
	DISABLED
}

# Color definitions
var color_palette: Dictionary = {
	ColorScheme.PRIMARY: Color(0.2, 0.4, 0.8),      # Blue
	ColorScheme.SECONDARY: Color(0.3, 0.3, 0.3),    # Dark Gray
	ColorScheme.ACCENT: Color(0.9, 0.6, 0.2),       # Orange
	ColorScheme.SUCCESS: Color(0.2, 0.7, 0.3),      # Green
	ColorScheme.WARNING: Color(0.9, 0.8, 0.2),      # Yellow
	ColorScheme.ERROR: Color(0.8, 0.2, 0.2),        # Red
	ColorScheme.INFO: Color(0.3, 0.7, 0.9),         # Light Blue
	ColorScheme.BACKGROUND: Color(0.1, 0.1, 0.15),  # Very Dark Blue
	ColorScheme.SURFACE: Color(0.15, 0.15, 0.2),    # Dark Blue
	ColorScheme.TEXT_PRIMARY: Color(1.0, 1.0, 1.0), # White
	ColorScheme.TEXT_SECONDARY: Color(0.7, 0.7, 0.7), # Light Gray
	ColorScheme.DISABLED: Color(0.4, 0.4, 0.4)      # Medium Gray
}

# Typography
enum FontSize {
	TINY = 10,
	SMALL = 12,
	NORMAL = 14,
	LARGE = 16,
	XLARGE = 20,
	XXLARGE = 24,
	TITLE = 32,
	HEADER = 48
}

# Spacing
enum Spacing {
	NONE = 0,
	TINY = 2,
	SMALL = 4,
	NORMAL = 8,
	MEDIUM = 12,
	LARGE = 16,
	XLARGE = 24,
	XXLARGE = 32
}

# Border radius
enum BorderRadius {
	NONE = 0,
	SMALL = 4,
	NORMAL = 8,
	LARGE = 12,
	ROUND = 50
}

# Current theme
var current_theme: String = "default"
var themes: Dictionary = {}

func _ready() -> void:
	"""Initialize theme manager"""
	_create_default_themes()
	_apply_theme(current_theme)
	print("[ThemeManager] Theme Manager initialized with theme: ", current_theme)

func _create_default_themes() -> void:
	"""Create default theme configurations"""
	themes["default"] = {
		"name": "Default Dark",
		"colors": color_palette,
		"spacing": Spacing,
		"fonts": FontSize,
		"borders": BorderRadius
	}
	
	# Create light theme variant
	var light_colors = color_palette.duplicate()
	light_colors[ColorScheme.BACKGROUND] = Color(0.95, 0.95, 0.95)
	light_colors[ColorScheme.SURFACE] = Color(1.0, 1.0, 1.0)
	light_colors[ColorScheme.TEXT_PRIMARY] = Color(0.1, 0.1, 0.1)
	light_colors[ColorScheme.TEXT_SECONDARY] = Color(0.4, 0.4, 0.4)
	
	themes["light"] = {
		"name": "Light Theme",
		"colors": light_colors,
		"spacing": Spacing,
		"fonts": FontSize,
		"borders": BorderRadius
	}

func get_color(color_scheme: ColorScheme) -> Color:
	"""Get color from current theme"""
	var theme_data = themes.get(current_theme, themes["default"])
	return theme_data.colors.get(color_scheme, Color.WHITE)

func get_font_size(size: FontSize) -> int:
	"""Get font size value"""
	return int(size)

func get_spacing(spacing: Spacing) -> int:
	"""Get spacing value"""
	return int(spacing)

func get_border_radius(radius: BorderRadius) -> int:
	"""Get border radius value"""
	return int(radius)

func create_button_style(variant: String = "primary") -> StyleBoxFlat:
	"""Create a standardized button style"""
	var style = StyleBoxFlat.new()
	
	match variant:
		"primary":
			style.bg_color = get_color(ColorScheme.PRIMARY)
			style.border_color = get_color(ColorScheme.PRIMARY)
		"secondary":
			style.bg_color = get_color(ColorScheme.SECONDARY)
			style.border_color = get_color(ColorScheme.SECONDARY)
		"accent":
			style.bg_color = get_color(ColorScheme.ACCENT)
			style.border_color = get_color(ColorScheme.ACCENT)
		"success":
			style.bg_color = get_color(ColorScheme.SUCCESS)
			style.border_color = get_color(ColorScheme.SUCCESS)
		"warning":
			style.bg_color = get_color(ColorScheme.WARNING)
			style.border_color = get_color(ColorScheme.WARNING)
		"error":
			style.bg_color = get_color(ColorScheme.ERROR)
			style.border_color = get_color(ColorScheme.ERROR)
		_:
			style.bg_color = get_color(ColorScheme.PRIMARY)
			style.border_color = get_color(ColorScheme.PRIMARY)
	
	# Standard button styling
	style.corner_radius_top_left = get_border_radius(BorderRadius.NORMAL)
	style.corner_radius_top_right = get_border_radius(BorderRadius.NORMAL)
	style.corner_radius_bottom_left = get_border_radius(BorderRadius.NORMAL)
	style.corner_radius_bottom_right = get_border_radius(BorderRadius.NORMAL)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	
	return style

func create_panel_style(variant: String = "default") -> StyleBoxFlat:
	"""Create a standardized panel style"""
	var style = StyleBoxFlat.new()
	
	match variant:
		"default":
			style.bg_color = get_color(ColorScheme.SURFACE)
			style.border_color = get_color(ColorScheme.TEXT_SECONDARY)
		"background":
			style.bg_color = get_color(ColorScheme.BACKGROUND)
			style.border_color = get_color(ColorScheme.TEXT_SECONDARY)
		"transparent":
			style.bg_color = Color.TRANSPARENT
			style.border_color = Color.TRANSPARENT
		_:
			style.bg_color = get_color(ColorScheme.SURFACE)
			style.border_color = get_color(ColorScheme.TEXT_SECONDARY)
	
	# Standard panel styling
	style.corner_radius_top_left = get_border_radius(BorderRadius.NORMAL)
	style.corner_radius_top_right = get_border_radius(BorderRadius.NORMAL)
	style.corner_radius_bottom_left = get_border_radius(BorderRadius.NORMAL)
	style.corner_radius_bottom_right = get_border_radius(BorderRadius.NORMAL)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	
	return style

func create_progress_bar_style(variant: String = "primary") -> StyleBoxFlat:
	"""Create a standardized progress bar style"""
	var style = StyleBoxFlat.new()
	
	match variant:
		"primary":
			style.bg_color = get_color(ColorScheme.PRIMARY)
		"success":
			style.bg_color = get_color(ColorScheme.SUCCESS)
		"warning":
			style.bg_color = get_color(ColorScheme.WARNING)
		"error":
			style.bg_color = get_color(ColorScheme.ERROR)
		"health":
			style.bg_color = get_color(ColorScheme.SUCCESS)
		"mana":
			style.bg_color = get_color(ColorScheme.INFO)
		"experience":
			style.bg_color = get_color(ColorScheme.ACCENT)
		_:
			style.bg_color = get_color(ColorScheme.PRIMARY)
	
	# Standard progress bar styling
	style.corner_radius_top_left = get_border_radius(BorderRadius.SMALL)
	style.corner_radius_top_right = get_border_radius(BorderRadius.SMALL)
	style.corner_radius_bottom_left = get_border_radius(BorderRadius.SMALL)
	style.corner_radius_bottom_right = get_border_radius(BorderRadius.SMALL)
	
	return style

func apply_button_theme(button: Button, variant: String = "primary") -> void:
	"""Apply consistent theme to a button"""
	if not button:
		return
	
	# Normal state
	button.add_theme_stylebox_override("normal", create_button_style(variant))
	
	# Hover state (slightly lighter)
	var hover_style = create_button_style(variant)
	hover_style.bg_color = hover_style.bg_color.lightened(0.1)
	button.add_theme_stylebox_override("hover", hover_style)
	
	# Pressed state (slightly darker)
	var pressed_style = create_button_style(variant)
	pressed_style.bg_color = pressed_style.bg_color.darkened(0.1)
	button.add_theme_stylebox_override("pressed", pressed_style)
	
	# Text color
	button.add_theme_color_override("font_color", get_color(ColorScheme.TEXT_PRIMARY))
	button.add_theme_color_override("font_hover_color", get_color(ColorScheme.TEXT_PRIMARY))
	button.add_theme_color_override("font_pressed_color", get_color(ColorScheme.TEXT_PRIMARY))
	
	# Font size
	button.add_theme_font_size_override("font_size", get_font_size(FontSize.NORMAL))

func apply_label_theme(label: Label, variant: String = "primary") -> void:
	"""Apply consistent theme to a label"""
	if not label:
		return
	
	match variant:
		"primary":
			label.add_theme_color_override("font_color", get_color(ColorScheme.TEXT_PRIMARY))
			label.add_theme_font_size_override("font_size", get_font_size(FontSize.NORMAL))
		"secondary":
			label.add_theme_color_override("font_color", get_color(ColorScheme.TEXT_SECONDARY))
			label.add_theme_font_size_override("font_size", get_font_size(FontSize.NORMAL))
		"title":
			label.add_theme_color_override("font_color", get_color(ColorScheme.TEXT_PRIMARY))
			label.add_theme_font_size_override("font_size", get_font_size(FontSize.TITLE))
		"header":
			label.add_theme_color_override("font_color", get_color(ColorScheme.TEXT_PRIMARY))
			label.add_theme_font_size_override("font_size", get_font_size(FontSize.HEADER))
		"small":
			label.add_theme_color_override("font_color", get_color(ColorScheme.TEXT_SECONDARY))
			label.add_theme_font_size_override("font_size", get_font_size(FontSize.SMALL))
		"success":
			label.add_theme_color_override("font_color", get_color(ColorScheme.SUCCESS))
			label.add_theme_font_size_override("font_size", get_font_size(FontSize.NORMAL))
		"warning":
			label.add_theme_color_override("font_color", get_color(ColorScheme.WARNING))
			label.add_theme_font_size_override("font_size", get_font_size(FontSize.NORMAL))
		"error":
			label.add_theme_color_override("font_color", get_color(ColorScheme.ERROR))
			label.add_theme_font_size_override("font_size", get_font_size(FontSize.NORMAL))

func apply_panel_theme(panel: Panel, variant: String = "default") -> void:
	"""Apply consistent theme to a panel"""
	if not panel:
		return
	
	panel.add_theme_stylebox_override("panel", create_panel_style(variant))

func apply_progress_bar_theme(progress_bar: ProgressBar, variant: String = "primary") -> void:
	"""Apply consistent theme to a progress bar"""
	if not progress_bar:
		return
	
	# Fill style
	progress_bar.add_theme_stylebox_override("fill", create_progress_bar_style(variant))
	
	# Background style
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = get_color(ColorScheme.DISABLED)
	bg_style.corner_radius_top_left = get_border_radius(BorderRadius.SMALL)
	bg_style.corner_radius_top_right = get_border_radius(BorderRadius.SMALL)
	bg_style.corner_radius_bottom_left = get_border_radius(BorderRadius.SMALL)
	bg_style.corner_radius_bottom_right = get_border_radius(BorderRadius.SMALL)
	progress_bar.add_theme_stylebox_override("background", bg_style)

func set_theme(theme_name: String) -> void:
	"""Change to a different theme"""
	if themes.has(theme_name):
		current_theme = theme_name
		_apply_theme(theme_name)
		theme_changed.emit(theme_name)
		print("[ThemeManager] Theme changed to: ", theme_name)
	else:
		print("[ThemeManager] Theme not found: ", theme_name)

func _apply_theme(theme_name: String) -> void:
	"""Apply theme to existing UI elements"""
	var theme_data = themes.get(theme_name, themes["default"])
	color_palette = theme_data.colors
	
	# Update any global theme settings here
	# This could include updating the default theme resource

func get_available_themes() -> Array:
	"""Get list of available theme names"""
	return themes.keys()

func create_spacing_container(spacing_type: Spacing, direction: String = "vertical") -> Control:
	"""Create a spacer with consistent spacing"""
	var spacer: Control
	
	if direction == "vertical":
		spacer = VSeparator.new()
		spacer.custom_minimum_size.y = get_spacing(spacing_type)
	else:
		spacer = HSeparator.new()
		spacer.custom_minimum_size.x = get_spacing(spacing_type)
	
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer