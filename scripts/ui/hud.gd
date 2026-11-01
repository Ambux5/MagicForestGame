extends CanvasLayer
## Gameplay HUD – health/mana/xp bars, spell slots, enemy health bar,
## level-up notification, and game-over overlay.

# ── Spell data ────────────────────────────────────────────────────────────────
const SPELL_NAMES := ["Nature Bolt", "Fireball", "Healing", "Nature Shield"]
const SPELL_COLORS := [
	Color(0.2, 0.85, 0.3),
	Color(1.0, 0.45, 0.05),
	Color(0.3, 0.95, 0.55),
	Color(0.2, 0.75, 0.3),
]
const SPELL_KEY_LABELS := ["1", "2", "3", "4"]

# ── Node refs (built in _ready) ───────────────────────────────────────────────
var _health_bar: ProgressBar
var _mana_bar: ProgressBar
var _xp_bar: ProgressBar
var _level_label: Label
var _enemy_health_bar: ProgressBar
var _enemy_name_label: Label
var _enemy_bar_container: Control
var _spell_slots: Array[Control] = []
var _cooldown_overlays: Array[ColorRect] = []
var _level_up_panel: Control
var _game_over_panel: Control
var _notice_timer: float = 0.0
const NOTICE_DURATION := 2.5


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("hud")
	_build_hud()
	_connect_signals()


func _build_hud() -> void:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.size = get_viewport().get_visible_rect().size   # explicit size – fixes 0.5/1.0 anchor resolution

	_build_health_mana_bars(root)
	_build_spell_bar(root)
	_build_xp_level(root)
	_build_enemy_health_bar(root)
	_build_level_up_notice(root)
	_build_game_over(root)


func _build_health_mana_bars(parent: Control) -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchor_and_offset(SIDE_LEFT, 0, 16)
	vbox.set_anchor_and_offset(SIDE_TOP, 0, 16)
	vbox.set_anchor_and_offset(SIDE_RIGHT, 0, 280)
	vbox.set_anchor_and_offset(SIDE_BOTTOM, 0, 100)
	vbox.add_theme_constant_override("separation", 6)
	parent.add_child(vbox)

	_health_bar = _make_bar("HP", Color(0.85, 0.2, 0.2), 100.0)
	vbox.add_child(_health_bar)

	_mana_bar = _make_bar("MP", Color(0.2, 0.4, 0.95), 80.0)
	vbox.add_child(_mana_bar)


func _make_bar(label_text: String, color: Color, max_val: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = max_val
	bar.value = max_val
	bar.custom_minimum_size = Vector2(260, 22)
	bar.show_percentage = false
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("fill", style)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.7)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("background", bg_style)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.position = Vector2(6, 2)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_font_size_override("font_size", 11)
	bar.add_child(lbl)
	return bar


func _build_spell_bar(parent: Control) -> void:
	var hbox := HBoxContainer.new()
	# bottom-centre: x = 640-130 = 510, y = 720-82 = 638
	hbox.position = Vector2(510, 638)
	hbox.custom_minimum_size = Vector2(260, 72)
	hbox.add_theme_constant_override("separation", 6)
	parent.add_child(hbox)

	for i in 4:
		var slot := _make_spell_slot(i)
		hbox.add_child(slot)
		_spell_slots.append(slot)


func _make_spell_slot(index: int) -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(56, 56)

	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.custom_minimum_size = Vector2(56, 56)
	bg.color = Color(0.06, 0.06, 0.10, 0.92)
	container.add_child(bg)

	var icon_rect := TextureRect.new()
	icon_rect.name = "SpellIcon"
	icon_rect.position = Vector2(4, 4)
	icon_rect.custom_minimum_size = Vector2(48, 48)
	icon_rect.texture = _make_spell_icon(index)
	icon_rect.stretch_mode = TextureRect.STRETCH_SCALE
	container.add_child(icon_rect)

	var cooldown_overlay := ColorRect.new()
	cooldown_overlay.position = Vector2.ZERO
	cooldown_overlay.custom_minimum_size = Vector2(56, 56)
	cooldown_overlay.color = Color(0, 0, 0, 0.65)
	cooldown_overlay.visible = false
	container.add_child(cooldown_overlay)
	_cooldown_overlays.append(cooldown_overlay)

	var key_label := Label.new()
	key_label.text = SPELL_KEY_LABELS[index]
	key_label.position = Vector2(3, 44)
	key_label.custom_minimum_size = Vector2(52, 10)
	key_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	key_label.add_theme_font_size_override("font_size", 10)
	container.add_child(key_label)

	# Border frame (transparent centre, coloured edge)
	var border_panel := Panel.new()
	border_panel.position = Vector2.ZERO
	border_panel.custom_minimum_size = Vector2(56, 56)
	border_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bstyle := StyleBoxFlat.new()
	bstyle.draw_center = false
	bstyle.border_width_left   = 2; bstyle.border_width_top    = 2
	bstyle.border_width_right  = 2; bstyle.border_width_bottom = 2
	bstyle.border_color = Color(0.45, 0.65, 0.45, 0.9)
	bstyle.corner_radius_top_left    = 3; bstyle.corner_radius_top_right   = 3
	bstyle.corner_radius_bottom_left = 3; bstyle.corner_radius_bottom_right = 3
	border_panel.add_theme_stylebox_override("panel", bstyle)
	container.add_child(border_panel)

	return container


# ── Spell icon generation ─────────────────────────────────────────────────────

func _make_spell_icon(index: int) -> ImageTexture:
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	match index:
		0: _icon_nature_bolt(img)
		1: _icon_fireball(img)
		2: _icon_healing(img)
		3: _icon_shield(img)
	return ImageTexture.create_from_image(img)


func _icon_nature_bolt(img: Image) -> void:
	_img_dot(img, 24, 24, 20, Color(0.02, 0.10, 0.01))
	var bolt := Color(0.50, 1.00, 0.20)
	var core := Color(0.88, 1.00, 0.68)
	_img_line(img, 34,  2, 18, 23, 3, bolt)
	_img_line(img, 18, 23, 30, 23, 3, bolt)
	_img_line(img, 30, 23, 14, 46, 3, bolt)
	_img_line(img, 34,  2, 18, 23, 1, core)
	_img_line(img, 18, 23, 30, 23, 1, core)
	_img_line(img, 30, 23, 14, 46, 1, core)
	_img_dot(img, 14, 46, 4, Color(0.65, 1.0, 0.35, 0.7))


func _icon_fireball(img: Image) -> void:
	_img_dot(img, 24, 27, 19, Color(0.45, 0.04, 0.00, 0.9))
	_img_dot(img, 24, 27, 14, Color(0.95, 0.28, 0.00))
	_img_dot(img, 24, 27, 10, Color(1.00, 0.55, 0.05))
	_img_dot(img, 24, 27,  6, Color(0.741, 0.0, 0.122, 1.0))
	_img_dot(img, 24, 27,  3, Color(1.00, 0.98, 0.80))
	_img_line(img, 24, 13, 24,  3, 1, Color(1.00, 0.60, 0.10))
	_img_line(img, 18, 15, 14,  5, 1, Color(1.00, 0.45, 0.05))
	_img_line(img, 30, 15, 34,  5, 1, Color(1.00, 0.45, 0.05))
	_img_line(img, 13, 20,  8, 11, 1, Color(0.90, 0.30, 0.00))
	_img_line(img, 35, 20, 40, 11, 1, Color(0.90, 0.30, 0.00))


func _icon_healing(img: Image) -> void:
	_img_dot(img, 24, 24, 20, Color(0.02, 0.10, 0.03))
	var c := Color(0.25, 0.96, 0.45)
	_img_rect(img,  7, 18, 34, 11, c)
	_img_rect(img, 18,  7, 11, 34, c)
	_img_dot(img, 24, 24, 5, Color(0.65, 1.00, 0.70, 0.55))


func _icon_shield(img: Image) -> void:
	_img_dot(img, 24, 26, 20, Color(0.02, 0.08, 0.01))
	var c     := Color(0.35, 0.88, 0.25)
	var inner := Color(0.58, 1.00, 0.42)
	_img_line(img,  8,  8, 40,  8, 3, c)
	_img_line(img,  8,  8,  8, 30, 3, c)
	_img_line(img, 40,  8, 40, 30, 3, c)
	_img_line(img,  8, 30, 24, 44, 3, c)
	_img_line(img, 40, 30, 24, 44, 3, c)
	_img_line(img, 24, 13, 24, 40, 1, inner)
	_img_line(img, 24, 22, 16, 30, 1, inner)
	_img_line(img, 24, 22, 32, 30, 1, inner)
	_img_line(img, 24, 32, 18, 38, 1, inner)
	_img_line(img, 24, 32, 30, 38, 1, inner)


func _img_dot(img: Image, cx: int, cy: int, r: int, col: Color) -> void:
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if dx * dx + dy * dy <= r * r:
				var px := cx + dx; var py := cy + dy
				if px >= 0 and py >= 0 and px < img.get_width() and py < img.get_height():
					img.set_pixel(px, py, col)


func _img_line(img: Image, x0: int, y0: int, x1: int, y1: int, r: int, col: Color) -> void:
	var steps := maxi(abs(x1 - x0), abs(y1 - y0))
	for i in range(steps + 1):
		var t: float = float(i) / maxf(float(steps), 1.0)
		_img_dot(img,
			int(round(lerp(float(x0), float(x1), t))),
			int(round(lerp(float(y0), float(y1), t))),
			r, col)


func _img_rect(img: Image, rx: int, ry: int, rw: int, rh: int, col: Color) -> void:
	for py in range(ry, ry + rh):
		for px in range(rx, rx + rw):
			if px >= 0 and py >= 0 and px < img.get_width() and py < img.get_height():
				img.set_pixel(px, py, col)


func _build_xp_level(parent: Control) -> void:
	var vbox := VBoxContainer.new()
	# top-right: x = 1280-200 = 1080, y = 16
	vbox.position = Vector2(1080, 16)
	vbox.custom_minimum_size = Vector2(184, 0)
	vbox.alignment = BoxContainer.ALIGNMENT_END
	parent.add_child(vbox)

	_level_label = Label.new()
	_level_label.text = "Level 1"
	_level_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	_level_label.add_theme_font_size_override("font_size", 16)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(_level_label)

	_xp_bar = _make_bar("XP", Color(0.9, 0.75, 0.15), 100.0)
	_xp_bar.custom_minimum_size = Vector2(180, 16)
	vbox.add_child(_xp_bar)


func _build_enemy_health_bar(parent: Control) -> void:
	_enemy_bar_container = VBoxContainer.new()
	# top-centre: x = 640-130 = 510, y = 16
	_enemy_bar_container.position = Vector2(510, 16)
	_enemy_bar_container.custom_minimum_size = Vector2(260, 0)
	_enemy_bar_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_enemy_bar_container.visible = false
	parent.add_child(_enemy_bar_container)

	_enemy_name_label = Label.new()
	_enemy_name_label.text = "Enemy"
	_enemy_name_label.add_theme_color_override("font_color", Color(1, 0.7, 0.7))
	_enemy_name_label.add_theme_font_size_override("font_size", 13)
	_enemy_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_enemy_bar_container.add_child(_enemy_name_label)

	_enemy_health_bar = _make_bar("", Color(0.8, 0.15, 0.15), 100.0)
	_enemy_health_bar.custom_minimum_size = Vector2(260, 18)
	_enemy_bar_container.add_child(_enemy_health_bar)

	GameManager.enemy_targeted.connect(_on_enemy_targeted)
	GameManager.enemy_untargeted.connect(_on_enemy_untargeted)


func _build_level_up_notice(parent: Control) -> void:
	_level_up_panel = ColorRect.new()
	# centre: x = 640-150 = 490, y = 360-40 = 320
	_level_up_panel.position = Vector2(490, 320)
	_level_up_panel.color = Color(0, 0, 0, 0.0)
	_level_up_panel.visible = false
	parent.add_child(_level_up_panel)
	_level_up_panel.size = Vector2(300, 50)   # set after add_child

	var lbl := Label.new()
	lbl.text = "✦ LEVEL UP! ✦"
	lbl.position = Vector2.ZERO
	lbl.custom_minimum_size = Vector2(300, 50)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.name = "LevelUpLabel"
	_level_up_panel.add_child(lbl)


func _build_game_over(parent: Control) -> void:
	_game_over_panel = ColorRect.new()
	_game_over_panel.position = Vector2.ZERO
	_game_over_panel.color = Color(0, 0, 0, 0.7)
	_game_over_panel.visible = false
	parent.add_child(_game_over_panel)
	_game_over_panel.size = Vector2(1280, 720)   # set after add_child

	var vbox := VBoxContainer.new()
	# centre: x = 640-200 = 440, y = 360-80 = 280
	vbox.position = Vector2(440, 280)
	vbox.custom_minimum_size = Vector2(400, 0)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_game_over_panel.add_child(vbox)

	var title := Label.new()
	title.text = "YOU HAVE FALLEN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)

	var retry_btn := Button.new()
	retry_btn.text = "Try Again"
	retry_btn.custom_minimum_size = Vector2(200, 44)
	retry_btn.pressed.connect(func():
		_game_over_panel.visible = false
		GameManager.start_new_game()
	)
	vbox.add_child(retry_btn)

	var btn := Button.new()
	btn.text = "Return to Menu"
	btn.custom_minimum_size = Vector2(200, 44)
	btn.pressed.connect(func(): GameManager.go_to_main_menu())
	vbox.add_child(btn)


func _connect_signals() -> void:
	GameManager.health_changed.connect(_on_health_changed)
	GameManager.mana_changed.connect(_on_mana_changed)
	GameManager.experience_gained.connect(_on_xp_gained)
	GameManager.level_up.connect(_on_level_up)


# ── Per-frame ─────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	_update_cooldown_overlays()
	_update_level_up_notice(delta)
	_update_selected_spell_highlight()


func _update_cooldown_overlays() -> void:
	for i in 4:
		var frac := GameManager.get_cooldown_fraction(i)
		_cooldown_overlays[i].visible = frac > 0.0
		if frac > 0.0:
			# Scale the overlay vertically (pivot at top so it shrinks downward)
			_cooldown_overlays[i].pivot_offset = Vector2(0, 0)
			_cooldown_overlays[i].scale = Vector2(1.0, frac)


func _update_level_up_notice(delta: float) -> void:
	if _notice_timer > 0.0:
		_notice_timer -= delta
		var a := minf(_notice_timer / NOTICE_DURATION * 2.0, 1.0)
		var lbl := _level_up_panel.get_node("LevelUpLabel") as Label
		if lbl:
			lbl.modulate.a = a
		if _notice_timer <= 0.0:
			_level_up_panel.visible = false


func _update_selected_spell_highlight() -> void:
	var player := GameManager.player_node
	if not is_instance_valid(player) or not player.has_method("get_selected_spell"):
		return
	var sel: int = player.get_selected_spell()
	for i in _spell_slots.size():
		var slot := _spell_slots[i]
		var bg := slot.get_child(0) as ColorRect
		if bg:
			bg.color = Color(0.2, 0.3, 0.2, 0.9) if i == sel else Color(0.08, 0.08, 0.12, 0.85)


# ── Signal handlers ───────────────────────────────────────────────────────────

func _on_health_changed(current: float, maximum: float) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current


func _on_mana_changed(current: float, maximum: float) -> void:
	_mana_bar.max_value = maximum
	_mana_bar.value = current


func _on_xp_gained(_amount: int, _total: int) -> void:
	_xp_bar.max_value = 100.0
	_xp_bar.value = GameManager.get_xp_fraction() * 100.0


func _on_level_up(new_level: int) -> void:
	_level_label.text = "Level %d" % new_level
	_level_up_panel.visible = true
	_notice_timer = NOTICE_DURATION
	_on_xp_gained(0, 0)


func _on_enemy_targeted(enemy_node: Node) -> void:
	_enemy_bar_container.visible = true
	if enemy_node.has_method("get_health_fraction"):
		_enemy_health_bar.value = enemy_node.get_health_fraction() * 100.0
	if "enemy_name" in enemy_node:
		_enemy_name_label.text = enemy_node.enemy_name


func _on_enemy_untargeted() -> void:
	_enemy_bar_container.visible = false


func show_game_over() -> void:
	_game_over_panel.visible = true
