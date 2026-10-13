# debug_radish_growth.gd
class_name DebugRadishGrowth
extends DebugModule

@export var radish_manager_path: NodePath
@export var panel_size: Vector2 = Vector2(360, 190)
@export var panel_position: Vector2 = Vector2(440, 330)
@export var multiplier_step: float = 0.25
@export var max_multiplier: float = 20.0

var radish_manager: Radish_Manager

var panel: Panel
var _inputs: Dictionary = {}

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
	title.text = "Radish Growth"
	title.add_theme_font_size_override("font_size", 16)
	root.add_child(title)

	var description := Label.new()
	description.text = "1.0 = normal speed"
	description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(description)

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

	var input := SpinBox.new()
	input.min_value = 0.0
	input.max_value = max_multiplier
	input.step = multiplier_step
	input.allow_greater = true
	input.allow_lesser = false
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.value_changed.connect(_on_value_changed.bind(state))
	row.add_child(input)

	var plus_button := Button.new()
	plus_button.text = "+"
	plus_button.custom_minimum_size = Vector2(36, 0)
	plus_button.focus_mode = Control.FOCUS_NONE
	plus_button.pressed.connect(_on_step_pressed.bind(state, 1.0))
	row.add_child(plus_button)

	_inputs[state] = input

func _on_step_pressed(state: int, direction: float) -> void:
	var input: SpinBox = _inputs[state]
	input.value = maxf(0.0, input.value + multiplier_step * direction)

func _on_value_changed(value: float, state: int) -> void:
	radish_manager.set_growth_multiplier(state, value)
	log_message("%s growth multiplier -> %.2f" % [_get_state_name(state), value])

func _refresh_all() -> void:
	if radish_manager == null:
		return

	for state in _inputs:
		var input: SpinBox = _inputs[state]
		input.set_value_no_signal(radish_manager.get_growth_multiplier(state))

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
