extends CanvasLayer
## Pause menu – shown when ESC is pressed during gameplay.

var _panel: Panel


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()
	GameManager.game_paused.connect(_on_game_paused)


func _build_ui() -> void:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.size = get_viewport().get_visible_rect().size

	var overlay := ColorRect.new()
	overlay.position = Vector2.ZERO
	overlay.color = Color(0, 0, 0, 0.55)
	root.add_child(overlay)
	overlay.size = root.size   # set AFTER add_child

	_panel = Panel.new()
	# centre: x = 640-180 = 460, y = 360-200 = 160
	_panel.position = Vector2(460, 160)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.08, 0.92)
	style.corner_radius_top_left    = 10
	style.corner_radius_top_right   = 10
	style.corner_radius_bottom_left  = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left   = 2
	style.border_width_top    = 2
	style.border_width_right  = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.6, 0.3, 0.8)
	_panel.add_theme_stylebox_override("panel", style)
	root.add_child(_panel)
	_panel.size = Vector2(360, 400)   # set AFTER add_child

	var vbox := VBoxContainer.new()
	# fill panel with 30px margins: pos (30,30), width 360-60=300
	vbox.position = Vector2(30, 30)
	vbox.custom_minimum_size = Vector2(300, 0)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	_panel.add_child(vbox)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	var separator := HSeparator.new()
	vbox.add_child(separator)

	_add_button(vbox, "RESUME", _on_resume_pressed)
	_add_button(vbox, "SAVE GAME", _on_save_pressed)
	_add_button(vbox, "SETTINGS", _on_settings_pressed)
	_add_button(vbox, "MAIN MENU", _on_main_menu_pressed)
	_add_button(vbox, "EXIT GAME", _on_exit_pressed)


func _add_button(parent: Container, text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(200, 40)
	btn.pressed.connect(callback)
	_style_button(btn)
	parent.add_child(btn)
	return btn


func _style_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.12, 0.22, 0.12, 0.9)
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_left = 6
	normal.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.2, 0.4, 0.2, 1.0)
	hover.corner_radius_top_left = 6
	hover.corner_radius_top_right = 6
	hover.corner_radius_bottom_left = 6
	hover.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("hover", hover)

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.1, 0.3, 0.1, 1.0)
	pressed_style.corner_radius_top_left = 6
	pressed_style.corner_radius_top_right = 6
	pressed_style.corner_radius_bottom_left = 6
	pressed_style.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("pressed", pressed_style)

	btn.add_theme_color_override("font_color", Color(0.9, 1.0, 0.9))
	btn.add_theme_font_size_override("font_size", 14)


func _on_game_paused(paused: bool) -> void:
	visible = paused
	if paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_resume_pressed() -> void:
	GameManager.set_pause(false)


func _on_save_pressed() -> void:
	SaveSystem.save_game()


func _on_settings_pressed() -> void:
	var settings := load("res://scenes/ui/settings_menu.tscn")
	if settings:
		var inst = settings.instantiate()
		get_tree().root.add_child(inst)


func _on_main_menu_pressed() -> void:
	GameManager.go_to_main_menu()


func _on_exit_pressed() -> void:
	SaveSystem.save_game()
	get_tree().quit()
