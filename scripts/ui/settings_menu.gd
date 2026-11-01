extends CanvasLayer
## Settings menu – can be opened from pause menu or main menu.
## Saves all settings via SaveSystem.

var _master_slider: HSlider
var _music_slider: HSlider
var _sfx_slider: HSlider
var _cam_slider: HSlider
var _fullscreen_check: CheckButton
var _shadow_option: OptionButton
var _graphics_option: OptionButton
var _close_btn: Button


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_load_current_settings()


func _build_ui() -> void:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.size = get_viewport().get_visible_rect().size

	var overlay := ColorRect.new()
	overlay.position = Vector2.ZERO
	overlay.color = Color(0, 0, 0, 0.65)
	root.add_child(overlay)
	overlay.size = root.size   # set AFTER add_child

	var panel := Panel.new()
	# centre: x = 640-260 = 380, y = 360-280 = 80
	panel.position = Vector2(380, 80)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.10, 0.07, 0.95)
	style.corner_radius_top_left    = 10
	style.corner_radius_top_right   = 10
	style.corner_radius_bottom_left  = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left   = 2
	style.border_width_top    = 2
	style.border_width_right  = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.6, 0.3, 0.8)
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)
	panel.size = Vector2(520, 560)   # set AFTER add_child

	var scroll := ScrollContainer.new()
	# fill panel with 20px margins: pos (20,20), size 480×520
	scroll.position = Vector2(20, 20)
	scroll.custom_minimum_size = Vector2(480, 520)
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)

	var title := Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	_add_section_label(vbox, "── AUDIO ──")
	_master_slider = _add_slider(vbox, "Master Volume", 1.0)
	_music_slider = _add_slider(vbox, "Music Volume", 0.7)
	_sfx_slider = _add_slider(vbox, "SFX Volume", 1.0)

	_add_section_label(vbox, "── CONTROLS ──")
	_cam_slider = _add_slider(vbox, "Camera Sensitivity", 0.003, 0.001, 0.01)

	_add_section_label(vbox, "── DISPLAY ──")
	_fullscreen_check = _add_check(vbox, "Fullscreen")

	_add_section_label(vbox, "── GRAPHICS ──")
	_shadow_option = _add_option(vbox, "Shadow Quality", ["Off", "Low", "Medium"])
	_graphics_option = _add_option(vbox, "Graphics Quality", ["Low (Raspberry Pi)", "Medium", "High"])

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(hbox)

	var apply_btn := _make_btn("Apply")
	apply_btn.pressed.connect(_on_apply_pressed)
	hbox.add_child(apply_btn)

	_close_btn = _make_btn("Close")
	_close_btn.pressed.connect(_on_close_pressed)
	hbox.add_child(_close_btn)


func _add_section_label(parent: Container, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(lbl)


func _add_slider(parent: Container, label_text: String, default_val: float,
		min_val: float = 0.0, max_val: float = 1.0) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size.x = 160
	lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	lbl.add_theme_font_size_override("font_size", 13)
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = (max_val - min_val) / 100.0
	slider.value = default_val
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)

	return slider


func _add_check(parent: Container, label_text: String) -> CheckButton:
	var row := HBoxContainer.new()
	parent.add_child(row)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size.x = 160
	lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	lbl.add_theme_font_size_override("font_size", 13)
	row.add_child(lbl)

	var check := CheckButton.new()
	row.add_child(check)
	return check


func _add_option(parent: Container, label_text: String, items: Array[String]) -> OptionButton:
	var row := HBoxContainer.new()
	parent.add_child(row)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size.x = 160
	lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	lbl.add_theme_font_size_override("font_size", 13)
	row.add_child(lbl)

	var opt := OptionButton.new()
	for item in items:
		opt.add_item(item)
	row.add_child(opt)
	return opt


func _make_btn(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(120, 36)
	btn.add_theme_color_override("font_color", Color(0.9, 1.0, 0.9))
	return btn


func _load_current_settings() -> void:
	var cfg := SaveSystem.load_config()
	_master_slider.value = cfg.get_value("audio", "master", 1.0)
	_music_slider.value = cfg.get_value("audio", "music", 0.7)
	_sfx_slider.value = cfg.get_value("audio", "sfx", 1.0)
	_cam_slider.value = cfg.get_value("controls", "camera_sensitivity", 0.003)
	_fullscreen_check.button_pressed = cfg.get_value("display", "fullscreen", false)
	_shadow_option.selected = cfg.get_value("display", "shadow_quality", 0)
	_graphics_option.selected = cfg.get_value("display", "graphics_quality", 0)


func _on_apply_pressed() -> void:
	AudioManager.set_master_volume(_master_slider.value)
	AudioManager.set_music_volume(_music_slider.value)
	AudioManager.set_sfx_volume(_sfx_slider.value)

	if _fullscreen_check.button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	_apply_graphics_quality(_graphics_option.selected)
	_apply_shadow_quality(_shadow_option.selected)

	SaveSystem.save_current_settings(
		_master_slider.value,
		_music_slider.value,
		_sfx_slider.value,
		_cam_slider.value,
		_fullscreen_check.button_pressed,
		_shadow_option.selected,
		_graphics_option.selected
	)


func _apply_graphics_quality(idx: int) -> void:
	# 0 = Low (Raspberry Pi), 1 = Medium, 2 = High
	match idx:
		0:
			get_viewport().msaa_3d = Viewport.MSAA_DISABLED
			get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		1:
			get_viewport().msaa_3d = Viewport.MSAA_2X
		2:
			get_viewport().msaa_3d = Viewport.MSAA_4X


func _apply_shadow_quality(idx: int) -> void:
	# Modify the directional light in the world scene if present
	var lights := get_tree().get_nodes_in_group("main_light")
	for light in lights:
		if light is DirectionalLight3D:
			match idx:
				0:
					light.shadow_enabled = false
				1:
					light.shadow_enabled = true
				2:
					light.shadow_enabled = true


func _on_close_pressed() -> void:
	queue_free()
