extends Node
## Main Menu scene root – builds the entire title screen procedurally.

var _animated_bg: ColorRect
var _particle_time: float = 0.0
var _particles: Array[Node] = []


func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_menu()
	_build_background()


func _build_background() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var bg := ColorRect.new()
	bg.size = vp
	bg.color = Color(0.04, 0.08, 0.04)
	bg.z_index = -10
	add_child(bg)
	_animated_bg = bg

	var canvas := CanvasLayer.new()
	canvas.layer = -1
	add_child(canvas)

	for i in 30:
		var dot_sz := randf_range(2.0, 6.0)
		var dot := ColorRect.new()
		dot.size = Vector2(dot_sz, dot_sz)
		dot.color = Color(0.2, 0.9, 0.3, randf_range(0.3, 0.9))
		dot.position = Vector2(randf_range(0, vp.x), randf_range(0, vp.y))
		canvas.add_child(dot)
		_particles.append(dot)


func _process(delta: float) -> void:
	_particle_time += delta
	for i in _particles.size():
		var dot := _particles[i] as ColorRect
		if dot:
			dot.position.y -= delta * randf_range(8, 25)
			dot.modulate.a = 0.5 + sin(_particle_time * 2.0 + i) * 0.4
			if dot.position.y < -10:
				dot.position.y = 730
				dot.position.x = randf_range(0, 1280)


func _build_menu() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)

	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)
	root.size = get_viewport().get_visible_rect().size

	# ── Title panel ────────────────────────────────────────────────────────────
	var title_panel := _make_title_panel()
	root.add_child(title_panel)

	# ── Button panel ───────────────────────────────────────────────────────────
	var btn_panel := _make_button_panel()
	root.add_child(btn_panel)

	# ── Bottom credits ─────────────────────────────────────────────────────────
	var credits_lbl := Label.new()
	credits_lbl.text = "Magical Forest RPG  •  Godot 4  •  Raspberry Pi 4 Edition"
	# bottom: y = 720-24 = 696, full width
	credits_lbl.position = Vector2(0, 696)
	credits_lbl.custom_minimum_size = Vector2(1280, 24)
	credits_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credits_lbl.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5, 0.7))
	credits_lbl.add_theme_font_size_override("font_size", 11)
	root.add_child(credits_lbl)


func _make_title_panel() -> Control:
	var panel := Control.new()
	# centre: x = 640-350 = 290, top = 60, size 700×160
	panel.position = Vector2(290, 60)
	panel.custom_minimum_size = Vector2(700, 160)

	var title := Label.new()
	title.text = "✦ MAGICAL FOREST ✦"
	title.position = Vector2.ZERO
	title.custom_minimum_size = Vector2(700, 130)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.5, 0.95, 0.5))
	title.add_theme_font_size_override("font_size", 52)
	panel.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "An Enchanted Adventure"
	subtitle.position = Vector2(0, 130)
	subtitle.custom_minimum_size = Vector2(700, 30)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7, 0.85))
	subtitle.add_theme_font_size_override("font_size", 18)
	panel.add_child(subtitle)

	return panel


func _make_button_panel() -> Control:
	var vbox := VBoxContainer.new()
	# centre: x = 640-140 = 500, y = 360-100 = 260
	vbox.position = Vector2(500, 260)
	vbox.custom_minimum_size = Vector2(280, 0)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)

	_add_menu_btn(vbox, "NEW GAME",     _on_new_game)
	_add_menu_btn(vbox, "CONTINUE",    _on_continue, not SaveSystem.save_exists())
	_add_menu_btn(vbox, "MULTIPLAYER", _on_multiplayer)
	_add_menu_btn(vbox, "SETTINGS",    _on_settings)
	_add_menu_btn(vbox, "CREDITS",     _on_credits)
	_add_menu_btn(vbox, "EXIT",        _on_exit)

	return vbox


func _add_menu_btn(parent: Container, text: String, callback: Callable, disabled: bool = false) -> void:
	var btn := Button.new()
	btn.text = text
	btn.disabled = disabled
	btn.custom_minimum_size = Vector2(240, 46)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.1, 0.22, 0.1, 0.88)
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(0.3, 0.7, 0.3, 0.6)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.18, 0.40, 0.18, 0.95)
	hover.corner_radius_top_left = 8
	hover.corner_radius_top_right = 8
	hover.corner_radius_bottom_left = 8
	hover.corner_radius_bottom_right = 8
	hover.border_width_left = 2
	hover.border_width_top = 2
	hover.border_width_right = 2
	hover.border_width_bottom = 2
	hover.border_color = Color(0.4, 0.85, 0.4, 0.9)
	btn.add_theme_stylebox_override("hover", hover)

	btn.add_theme_color_override("font_color", Color(0.9, 1.0, 0.9))
	btn.add_theme_font_size_override("font_size", 16)

	btn.pressed.connect(callback)
	btn.mouse_entered.connect(func(): AudioManager.play_sfx("ui_hover"))

	parent.add_child(btn)


func _on_new_game() -> void:
	AudioManager.play_sfx("ui_click")
	GameManager.start_new_game()


func _on_multiplayer() -> void:
	AudioManager.play_sfx("ui_click")
	get_tree().change_scene_to_file("res://scenes/menus/lobby_menu.tscn")


func _on_continue() -> void:
	AudioManager.play_sfx("ui_click")
	if SaveSystem.load_game():
		GameManager.continue_game()


func _on_settings() -> void:
	AudioManager.play_sfx("ui_click")
	var settings := load("res://scenes/ui/settings_menu.tscn")
	if settings:
		var inst = settings.instantiate()
		add_child(inst)


func _on_credits() -> void:
	AudioManager.play_sfx("ui_click")
	_show_credits_popup()


func _on_exit() -> void:
	AudioManager.play_sfx("ui_click")
	get_tree().quit()


func _show_credits_popup() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 50
	add_child(canvas)

	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)
	root.size = get_viewport().get_visible_rect().size

	var overlay := ColorRect.new()
	overlay.position = Vector2.ZERO
	overlay.color = Color(0, 0, 0, 0.75)
	root.add_child(overlay)
	overlay.size = root.size   # set AFTER add_child

	var panel := Panel.new()
	# centre: x = 640-280 = 360, y = 360-200 = 160
	panel.position = Vector2(360, 160)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.10, 0.07, 0.95)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)
	panel.size = Vector2(560, 400)   # set AFTER add_child

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(20, 20)
	vbox.custom_minimum_size = Vector2(520, 0)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var credits_text := """MAGICAL FOREST RPG

A stylized low-poly 3D fantasy RPG
built with Godot Engine 4.x

Optimised for Raspberry Pi 4

Features:
  • Third-person wizard character
  • 4 magical spells
  • 3 unique enemy types
  • RPG progression system
  • Save / load system
  • Full settings menu

Made with Godot 4 – godotengine.org"""

	var lbl := Label.new()
	lbl.text = credits_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color(0.85, 0.95, 0.85))
	lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(lbl)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(120, 36)
	close_btn.pressed.connect(canvas.queue_free)
	vbox.add_child(close_btn)
