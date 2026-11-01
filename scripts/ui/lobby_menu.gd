extends Node
## Multiplayer lobby – host or join a LAN game.
## UI built entirely in GDScript; root.size is set explicitly so that
## 0.5/1.0 anchors on children resolve correctly at first frame.

const GAME_SCENE := "res://scenes/environment/world.tscn"

# ── Panel references ──────────────────────────────────────────────────────────
var _setup_panel:  Control
var _join_panel:   Control
var _lobby_panel:  Control

# ── Input references ──────────────────────────────────────────────────────────
var _name_input:        LineEdit
var _join_ip_input:     LineEdit
var _player_list_label: Label
var _start_btn:         Button
var _status_label:      Label


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_ui()
	NetworkManager.server_created.connect(_on_server_created)
	NetworkManager.connected_to_server.connect(_on_connected)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.peer_joined.connect(_on_peer_joined)
	NetworkManager.peer_left.connect(_on_peer_left)
	NetworkManager.game_starting.connect(_on_game_starting)


# ── UI construction ───────────────────────────────────────────────────────────

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)

	# Dark background
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.08, 0.04)
	canvas.add_child(bg)

	# Root control with EXPLICIT size – this is what makes all child anchors work
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)
	root.size = get_viewport().get_visible_rect().size
	bg.size   = root.size

	# ── Title ─────────────────────────────────────────────────────────────────
	var title := Label.new()
	title.text = "✦ MULTIPLAYER ✦"
	# full-width, top area  (0-anchor = safe before add_child)
	title.position = Vector2(0, 30)
	title.custom_minimum_size = Vector2(1280, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.5, 0.95, 0.5))
	title.add_theme_font_size_override("font_size", 40)
	root.add_child(title)

	# ── Back button (always visible, top-left) ─────────────────────────────
	var back_btn := _make_btn("◀ BACK", _on_back)
	# 0-anchors: position is absolute pixel
	back_btn.position = Vector2(16, 16)
	back_btn.custom_minimum_size = Vector2(140, 40)
	root.add_child(back_btn)

	# ── Panels ─────────────────────────────────────────────────────────────
	_setup_panel = _build_setup_panel(root)
	_join_panel  = _build_join_panel(root)
	_lobby_panel = _build_lobby_panel(root)
	_join_panel.visible  = false
	_lobby_panel.visible = false


func _build_setup_panel(parent: Control) -> Control:
	# Centered card 420 × 300
	var card := _make_card(parent, 420, 310)

	var vbox := _card_vbox(card)
	vbox.add_child(_section_label("Your Name"))
	_name_input = _make_input("Wizard", "Enter your name")
	vbox.add_child(_name_input)

	vbox.add_child(_vspace(16))

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(hbox)
	hbox.add_child(_make_btn("HOST GAME",  _on_host))
	hbox.add_child(_make_btn("JOIN GAME",  _on_show_join))

	_status_label = Label.new()
	_status_label.text = ""
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	_status_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_status_label)

	return card


func _build_join_panel(parent: Control) -> Control:
	# Centered card 420 × 280
	var card := _make_card(parent, 420, 280)

	var vbox := _card_vbox(card)

	var header := Label.new()
	header.text = "Join a LAN Server"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
	header.add_theme_font_size_override("font_size", 18)
	vbox.add_child(header)

	vbox.add_child(_vspace(8))
	vbox.add_child(_section_label("Server IP Address"))
	_join_ip_input = _make_input("", "e.g.  192.168.1.100")
	vbox.add_child(_join_ip_input)

	vbox.add_child(_vspace(16))

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(hbox)
	hbox.add_child(_make_btn("CONNECT", _on_connect))
	hbox.add_child(_make_btn("BACK",    _on_join_back))

	var err_lbl := Label.new()
	err_lbl.name = "ErrorLabel"
	err_lbl.text = ""
	err_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	err_lbl.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	err_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(err_lbl)

	return card


func _build_lobby_panel(parent: Control) -> Control:
	# Slightly taller card 460 × 380
	var card := _make_card(parent, 460, 380)

	var vbox := _card_vbox(card)

	var header := Label.new()
	header.text = "Lobby"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
	header.add_theme_font_size_override("font_size", 22)
	vbox.add_child(header)

	var hr := ColorRect.new()
	hr.color = Color(0.3, 0.6, 0.3, 0.45)
	hr.custom_minimum_size = Vector2(360, 2)
	vbox.add_child(hr)

	_player_list_label = Label.new()
	_player_list_label.custom_minimum_size = Vector2(360, 100)
	_player_list_label.text = ""
	_player_list_label.add_theme_color_override("font_color", Color(0.9, 0.95, 0.9))
	_player_list_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(_player_list_label)

	var wait_lbl := Label.new()
	wait_lbl.name = "WaitLabel"
	wait_lbl.text = ""
	wait_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wait_lbl.add_theme_color_override("font_color", Color(0.55, 0.8, 0.55))
	wait_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(wait_lbl)

	vbox.add_child(_vspace(8))

	_start_btn = _make_btn("▶  START GAME", _on_start_game)
	_start_btn.visible = false
	vbox.add_child(_start_btn)

	return card


# ── Card / widget helpers ─────────────────────────────────────────────────────

## Creates a centered panel card of (w × h) pixels.
func _make_card(parent: Control, w: float, h: float) -> Control:
	var card := Panel.new()
	# explicit position (0-anchor, so safe before add_child)
	card.position = Vector2(640.0 - w * 0.5, 360.0 - h * 0.5)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.12, 0.07, 0.94)
	style.corner_radius_top_left    = 12
	style.corner_radius_top_right   = 12
	style.corner_radius_bottom_left  = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.border_width_top    = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.65, 0.3, 0.7)
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)
	card.size = Vector2(w, h)   # set AFTER add_child
	return card


func _card_vbox(card: Control) -> VBoxContainer:
	var vbox := VBoxContainer.new()
	# position: 24px margin; width fills card minus margins
	vbox.position = Vector2(24, 20)
	vbox.custom_minimum_size = Vector2(card.size.x - 48, 0)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	card.add_child(vbox)
	return vbox


func _section_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", Color(0.7, 0.88, 0.7))
	lbl.add_theme_font_size_override("font_size", 13)
	return lbl


func _make_input(default_text: String, placeholder: String) -> LineEdit:
	var le := LineEdit.new()
	le.text = default_text
	le.placeholder_text = placeholder
	le.custom_minimum_size = Vector2(340, 42)
	le.add_theme_font_size_override("font_size", 15)
	le.add_theme_color_override("font_color", Color(0.95, 1.0, 0.95))
	le.add_theme_color_override("font_placeholder_color", Color(0.5, 0.65, 0.5, 0.8))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.16, 0.08, 0.92)
	style.corner_radius_top_left    = 6
	style.corner_radius_top_right   = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left   = 1
	style.border_width_right  = 1
	style.border_width_top    = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.3, 0.6, 0.3, 0.7)
	style.content_margin_left  = 10
	style.content_margin_right = 10
	le.add_theme_stylebox_override("normal", style)
	return le


func _make_btn(text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(168, 46)
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", Color(0.9, 1.0, 0.9))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.10, 0.22, 0.10, 0.88)
	normal.corner_radius_top_left    = 8
	normal.corner_radius_top_right   = 8
	normal.corner_radius_bottom_left  = 8
	normal.corner_radius_bottom_right = 8
	normal.border_width_left   = 1
	normal.border_width_right  = 1
	normal.border_width_top    = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(0.3, 0.7, 0.3, 0.6)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.18, 0.42, 0.18, 0.95)
	hover.corner_radius_top_left    = 8
	hover.corner_radius_top_right   = 8
	hover.corner_radius_bottom_left  = 8
	hover.corner_radius_bottom_right = 8
	hover.border_width_left   = 2
	hover.border_width_right  = 2
	hover.border_width_top    = 2
	hover.border_width_bottom = 2
	hover.border_color = Color(0.45, 0.88, 0.45, 0.9)
	btn.add_theme_stylebox_override("hover", hover)

	btn.pressed.connect(callback)
	return btn


func _vspace(px: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, px)
	return c


# ── Helpers ───────────────────────────────────────────────────────────────────

func _refresh_player_list() -> void:
	if not is_inside_tree():
		return
	var lines := ""
	var local_id := NetworkManager.get_local_peer_id()
	for pid: int in NetworkManager.players:
		var pname: String = NetworkManager.players[pid]
		var host_tag := "  [Host]" if pid == 1 else ""
		var you_tag  := "  ← You" if pid == local_id else ""
		lines += "• %s%s%s\n" % [pname, host_tag, you_tag]
	_player_list_label.text = lines
	if _start_btn:
		_start_btn.disabled = NetworkManager.players.size() < 2


func _show_lobby() -> void:
	_setup_panel.visible = false
	_join_panel.visible  = false
	_lobby_panel.visible = true
	_start_btn.visible   = NetworkManager.is_host
	_refresh_player_list()
	var wait_lbl := _lobby_panel.get_node_or_null("WaitLabel") as Label
	if wait_lbl:
		if NetworkManager.is_host:
			wait_lbl.text = "Hosting on port %d  –  waiting for players…" % NetworkManager.DEFAULT_PORT
		else:
			wait_lbl.text = "Connected!  Waiting for the host to start…"


# ── Button handlers ───────────────────────────────────────────────────────────

func _on_host() -> void:
	var p_name := _name_input.text.strip_edges()
	if p_name.is_empty():
		p_name = "Wizard"
	var err := NetworkManager.host_game(NetworkManager.DEFAULT_PORT, p_name)
	if err != OK:
		_status_label.text = "Failed to host (error %d). Port may be busy." % err


func _on_show_join() -> void:
	_setup_panel.visible = false
	_join_panel.visible  = true


func _on_connect() -> void:
	var p_name := _name_input.text.strip_edges()
	if p_name.is_empty():
		p_name = "Wizard"
	var ip := _join_ip_input.text.strip_edges()
	if ip.is_empty():
		var err_lbl := _join_panel.get_node_or_null("ErrorLabel") as Label
		if err_lbl:
			err_lbl.text = "Please enter the server's IP address."
		return
	var err := NetworkManager.join_game(ip, NetworkManager.DEFAULT_PORT, p_name)
	if err != OK:
		var err_lbl := _join_panel.get_node_or_null("ErrorLabel") as Label
		if err_lbl:
			err_lbl.text = "Connection error %d. Check the IP address." % err


func _on_join_back() -> void:
	NetworkManager.disconnect_network()
	_join_panel.visible  = false
	_setup_panel.visible = true


func _on_start_game() -> void:
	NetworkManager.start_game_for_all()


func _on_back() -> void:
	NetworkManager.disconnect_network()
	GameManager.go_to_main_menu()


# ── NetworkManager signal handlers ───────────────────────────────────────────

func _on_server_created() -> void:
	_show_lobby()


func _on_connected() -> void:
	_show_lobby()


func _on_connection_failed() -> void:
	_join_panel.visible  = false
	_setup_panel.visible = true
	_status_label.text   = "Connection failed. Check the IP address and try again."


func _on_peer_joined(_pid: int, _pname: String) -> void:
	if _lobby_panel.visible:
		_refresh_player_list()


func _on_peer_left(_pid: int) -> void:
	if _lobby_panel.visible:
		_refresh_player_list()


func _on_game_starting() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)
