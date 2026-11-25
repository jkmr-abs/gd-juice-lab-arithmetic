extends Control

const OperationData = preload("res://scripts/operation_data.gd")
const GameLogic = preload("res://scripts/game_logic.gd")

const BOARD_PATH := "res://assets/reference_board.png"
const BACKGROUND_COLOR := Color("#174322")
const PANEL_MAX_SIZE := Vector2(1160.0, 710.0)

var _screen_mode := "board"
var _operation_id := ""
var _state_index := 0 # 0: question, 1: incorrect feedback, 2: correct feedback
var _operation: Dictionary = {}
var _panel_rect := Rect2()
var _footer_label: Label

func _ready() -> void:
	show_board()

func show_board() -> void:
	_screen_mode = "board"
	_operation_id = ""
	_operation = {}
	_clear_screen()
	_add_background()

	var board := TextureRect.new()
	board.name = "ReferenceBoard"
	board.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	board.texture = load(BOARD_PATH)
	board.position = Vector2(80.0, 16.0)
	board.size = Vector2(1120.0, 840.0)
	board.stretch_mode = TextureRect.STRETCH_SCALE
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(board)

	_add_label(
		"Choose an operation below, or use keys 1, 2, or 3.",
		Rect2(80.0, 861.0, 1120.0, 28.0),
		20,
		Color.WHITE
	)

	var labels := ["Play Subtraction", "Play Multiplication", "Play Division"]
	var ids := OperationData.operation_ids()
	var button_width := 330.0
	var gap := 26.0
	var start_x := (1280.0 - (button_width * 3.0 + gap * 2.0)) / 2.0
	for index in range(ids.size()):
		var operation_id: String = ids[index]
		var callback := start_operation.bind(operation_id)
		_make_button(
			labels[index],
			Rect2(start_x + index * (button_width + gap), 897.0, button_width, 46.0),
			callback,
			20
		)

func start_operation(operation_id: String) -> void:
	var operation := OperationData.get_operation(operation_id)
	if operation.is_empty():
		return
	_screen_mode = "game"
	_operation_id = operation_id
	_operation = operation
	_state_index = 0
	_render_game()

func _render_game() -> void:
	_clear_screen()
	_add_background()
	_add_game_navigation()

	var panel_paths: Array = _operation["panels"]
	var panel_path: String = panel_paths[_state_index]
	var panel_texture := load(panel_path) as Texture2D
	if panel_texture == null:
		_add_label("Could not load panel: %s" % panel_path, Rect2(40, 140, 1200, 60), 24, Color.WHITE)
		return

	var scale_factor := minf(
		PANEL_MAX_SIZE.x / float(panel_texture.get_width()),
		PANEL_MAX_SIZE.y / float(panel_texture.get_height())
	)
	var display_size := Vector2(panel_texture.get_size()) * scale_factor
	var panel_top := 92.0
	_panel_rect = Rect2(
		Vector2((1280.0 - display_size.x) / 2.0, panel_top + (PANEL_MAX_SIZE.y - display_size.y) / 2.0),
		display_size
	)

	var panel := TextureRect.new()
	panel.name = "ActiveStoryboardPanel"
	panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.texture = panel_texture
	panel.position = _panel_rect.position
	panel.size = _panel_rect.size
	panel.stretch_mode = TextureRect.STRETCH_SCALE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	if _state_index < 2:
		_add_answer_hotspots()

	var state_text := "Choose an answer from the artwork, or press its number key."
	if _state_index == 1:
		state_text = "Try again: choose the correct answer to see the success panel."
	elif _state_index == 2:
		state_text = "Correct! Press Enter or Space to replay, or select another operation."
	_footer_label = _add_label(
		state_text,
		Rect2(60.0, 818.0, 1160.0, 36.0),
		19,
		Color.WHITE
	)

	_make_button("Reference board", Rect2(450.0, 875.0, 190.0, 52.0), Callable(self, "show_board"), 18)
	_make_button("Replay question", Rect2(660.0, 875.0, 210.0, 52.0), Callable(self, "_reset_question"), 18)

func _add_game_navigation() -> void:
	_make_button("← Board", Rect2(24.0, 22.0, 145.0, 48.0), Callable(self, "show_board"), 18)
	var ids := OperationData.operation_ids()
	var x := 190.0
	for operation_id in ids:
		var data := OperationData.get_operation(operation_id)
		var selected := operation_id == _operation_id
		var callback := start_operation.bind(operation_id)
		_make_button(
			str(data["label"]),
			Rect2(x, 22.0, 215.0, 48.0),
			callback,
			18,
			selected
		)
		x += 225.0

func _add_answer_hotspots() -> void:
	var layouts: Array = _operation["hotspots"]
	var positions: Array = layouts[_state_index]
	var choices: Array = _operation["choices"]
	var hotspot_size := Vector2(_panel_rect.size.x * 0.17, _panel_rect.size.y * 0.27)

	for index in range(choices.size()):
		var normalized: Array = positions[index]
		var center := _panel_rect.position + Vector2(
			float(normalized[0]) * _panel_rect.size.x,
			float(normalized[1]) * _panel_rect.size.y
		)
		var answer := int(choices[index])
		var hotspot := Button.new()
		hotspot.name = "AnswerHotspot%d" % answer
		hotspot.text = ""
		hotspot.tooltip_text = "Choose %d" % answer
		hotspot.position = center - hotspot_size / 2.0
		hotspot.size = hotspot_size
		hotspot.focus_mode = Control.FOCUS_ALL
		hotspot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_apply_hotspot_styles(hotspot)
		hotspot.pressed.connect(_on_answer_selected.bind(answer))
		add_child(hotspot)

func _on_answer_selected(answer: int) -> void:
	if _state_index >= 2:
		return
	var result: String = GameLogic.next_feedback_state(
		"question" if _state_index == 0 else "incorrect",
		answer,
		int(_operation["answer"])
	)
	_state_index = 2 if result == "correct" else 1
	_render_game()

func _reset_question() -> void:
	if _screen_mode != "game":
		return
	_state_index = 0
	_render_game()

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	if event.keycode == KEY_ESCAPE:
		show_board()
		return

	if _screen_mode == "board":
		if event.keycode == KEY_1:
			start_operation("subtraction")
		elif event.keycode == KEY_2:
			start_operation("multiplication")
		elif event.keycode == KEY_3:
			start_operation("division")
		return

	if event.keycode >= KEY_0 and event.keycode <= KEY_9 and _state_index < 2:
		var answer := int(event.keycode - KEY_0)
		if answer in _operation["choices"]:
			_on_answer_selected(answer)
	elif (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE) and _state_index == 2:
		_reset_question()
	elif event.keycode == KEY_R:
		_reset_question()

func _add_background() -> void:
	var background := ColorRect.new()
	background.color = BACKGROUND_COLOR
	background.position = Vector2.ZERO
	background.size = Vector2(1280.0, 960.0)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	move_child(background, 0)

func _add_label(text: String, rect: Rect2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.55))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _make_button(
	text: String,
	rect: Rect2,
	callback: Callable,
	font_size: int = 20,
	selected: bool = false
) -> Button:
	var button := Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color("#fff1ad"))
	button.add_theme_color_override("font_pressed_color", Color("#ffe28a"))
	button.add_theme_stylebox_override("normal", _button_style(selected))
	button.add_theme_stylebox_override("hover", _button_style(true))
	button.add_theme_stylebox_override("pressed", _button_style(true))
	button.add_theme_stylebox_override("focus", _button_style(true))
	button.pressed.connect(callback)
	add_child(button)
	return button

func _button_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#397548") if selected else Color("#285d37")
	style.border_color = Color("#ffd75e") if selected else Color("#b8d88e")
	style.set_border_width_all(2 if selected else 1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style

func _apply_hotspot_styles(button: Button) -> void:
	var clear_style := StyleBoxFlat.new()
	clear_style.bg_color = Color(1.0, 1.0, 1.0, 0.0)
	clear_style.set_border_width_all(0)
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(1.0, 0.82, 0.12, 0.13)
	hover_style.border_color = Color(1.0, 0.82, 0.12, 0.82)
	hover_style.set_border_width_all(3)
	hover_style.set_corner_radius_all(40)
	button.add_theme_stylebox_override("normal", clear_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	button.add_theme_stylebox_override("focus", hover_style)

func _clear_screen() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
