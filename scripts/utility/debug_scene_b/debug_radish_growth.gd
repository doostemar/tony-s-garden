# debug_radish_growth.gd
class_name DebugRadishGrowth
extends DebugModule

@export var radish_manager_path: NodePath
@export var panel_size: Vector2 = Vector2(400, 150)
@export var panel_position: Vector2 = Vector2(440, 330)
@export var time_step: float = 1

var radish_manager: Radish_Manager

var panel: Panel
var _inputs: Dictionary = {}  # state -> LineEdit


func _init() -> void:
	module_name = "Radish Growth"
	start_visible = false


func setup() -> void:
	if not radish_manager_path.is_empty():
		radish_manager = get_node_or_null(radish_manager_path)

	if radish_manager == null:
		radish_manager = _find_radish_manager(get_tree().root)

	if radish_manager == null:
		push_error("DebugRadishGrowth: Radish_Manager not found")
		return

	_create_panel()
	_setup_drag(panel)


func post_setup() -> void:
	_refresh_all()
	log_message("Radish Growth panel initialized")


func _create_panel() -> void:
	panel = Panel.new()
	panel.name = "RadishGrowthPanel"
	panel.position = panel_position
	panel.size = panel_size
	add_child(panel)
	main_panel = panel

	var root := VBoxContainer.new()
	root.position = Vector2(10, 10)
	root.size = Vector2(panel_size.x - 20, panel_size.y - 20)
	panel.add_child(root)

	var title := Label.new()
	title.text = "Radish Growth (seconds, 0 = instant)"
	title.add_theme_font_size_override("font_size", 16)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(title)

	_create_state_row(root, "Seed", Radish.RadishState.SEED)
	_create_state_row(root, "Sprout", Radish.RadishState.SPROUT)


func _create_state_row(parent: VBoxContainer, label_text: String, state: int) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(70, 0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)

	var minus_button := Button.new()
	minus_button.text = "-"
	minus_button.custom_minimum_size = Vector2(36, 0)
	minus_button.focus_mode = Control.FOCUS_NONE
	minus_button.pressed.connect(_on_step_pressed.bind(state, -1.0))
	row.add_child(minus_button)

	var input := LineEdit.new()
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.text_submitted.connect(_on_text_submitted.bind(state))
	input.focus_exited.connect(_on_focus_exited.bind(state))
	row.add_child(input)

	var plus_button := Button.new()
	plus_button.text = "+"
	plus_button.custom_minimum_size = Vector2(36, 0)
	plus_button.focus_mode = Control.FOCUS_NONE
	plus_button.pressed.connect(_on_step_pressed.bind(state, 1.0))
	row.add_child(plus_button)

	var default_button := Button.new()
	default_button.text = "Default"
	default_button.focus_mode = Control.FOCUS_NONE
	default_button.pressed.connect(_on_default_pressed.bind(state))
	row.add_child(default_button)

	_inputs[state] = input


# --- input handlers --- #

func _on_step_pressed(state: int, direction: float) -> void:
	_apply_value(state, radish_manager.get_growth_time(state) + time_step * direction)


func _on_text_submitted(text: String, state: int) -> void:
	_apply_text(state, text)


func _on_focus_exited(state: int) -> void:
	var input: LineEdit = _inputs[state]
	_apply_text(state, input.text)


func _on_default_pressed(state: int) -> void:
	radish_manager.reset_growth_time(state)
	_refresh(state)
	log_message("%s growth time -> default (%s s)" % [_get_state_name(state), _format(radish_manager.get_growth_time(state))])


func _apply_text(state: int, text: String) -> void:
	var trimmed := text.strip_edges()

	if trimmed.is_valid_float():
		_apply_value(state, trimmed.to_float())
	else:
		# invalid / unchanged entry: just put the current value back
		_refresh(state)


func _apply_value(state: int, value: float) -> void:
	value = maxf(value, 0.0)

	if not is_equal_approx(value, radish_manager.get_growth_time(state)):
		radish_manager.set_growth_time(state, value)
		log_message("%s growth time -> %s s" % [_get_state_name(state), _format(value)])

	_refresh(state)


# --- display --- #


func _refresh(state: int) -> void:
	if radish_manager == null or not _inputs.has(state):
		return

	var input: LineEdit = _inputs[state]
	input.text = _format(radish_manager.get_growth_time(state))


func _refresh_all() -> void:
	for state in _inputs:
		_refresh(state)


func _format(value: float) -> String:
	return String.num(value, 3)


func _get_state_name(state: int) -> String:
	match state:
		Radish.RadishState.SEED:
			return "Seed"
		Radish.RadishState.SPROUT:
			return "Sprout"
		_:
			return "State %d" % state


func _find_radish_manager(node: Node) -> Radish_Manager:
	if node is Radish_Manager:
		return node

	for child in node.get_children():
		var result := _find_radish_manager(child)

		if result:
			return result

	return null
