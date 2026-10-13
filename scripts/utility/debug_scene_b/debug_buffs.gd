# debug_buffs.gd
class_name DebugBuffs
extends DebugModule

@export var panel_size: Vector2 = Vector2(360, 300)
@export var panel_position: Vector2 = Vector2(440, 10)

var buff_manager: Buff_Manager

var panel: Panel
var rows_container: VBoxContainer
var _rows: Dictionary = {}

func _init() -> void:
	module_name = "Buff Controls"
	start_visible = false

func setup() -> void:
	var player := debug_manager.get_player()

	if player == null:
		push_error("DebugBuffs: Player not found")
		return

	if not player.has_method("get_buff_manager"):
		push_error("DebugBuffs: Player does not expose get_buff_manager()")
		return

	buff_manager = player.get_buff_manager()

	if buff_manager == null:
		push_error("DebugBuffs: Buff_Manager not found")
		return

	_create_panel()
	_setup_drag(panel)

	if not buff_manager.buff_tier_changed.is_connected(_on_buff_tier_changed):
		buff_manager.buff_tier_changed.connect(_on_buff_tier_changed)

func post_setup() -> void:
	_refresh_all()
	log_message("Buff Controls panel initialized")

func _create_panel() -> void:
	panel = Panel.new()
	panel.name = "BuffControlsPanel"
	panel.position = panel_position
	panel.size = panel_size
	add_child(panel)
	main_panel = panel

	var root := VBoxContainer.new()
	root.position = Vector2(10, 10)
	root.size = Vector2(panel_size.x - 20, panel_size.y - 20)
	panel.add_child(root)

	var title := Label.new()
	title.text = "Buff Controls"
	title.add_theme_font_size_override("font_size", 16)
	root.add_child(title)

	rows_container = VBoxContainer.new()
	root.add_child(rows_container)

	for buff in buff_manager.radish_buff_pool:
		if buff:
			_create_buff_row(buff)

func _create_buff_row(buff: Buff_Definition) -> void:
	var row := HBoxContainer.new()
	rows_container.add_child(row)

	var name_label := Label.new()
	name_label.text = buff.display_name if buff.display_name != "" else str(buff.buff_id)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(name_label)

	var minus_button := Button.new()
	minus_button.text = "-"
	minus_button.custom_minimum_size = Vector2(36, 0)
	minus_button.focus_mode = Control.FOCUS_NONE
	minus_button.pressed.connect(_on_minus_pressed.bind(buff))
	row.add_child(minus_button)

	var tier_label := Label.new()
	tier_label.custom_minimum_size = Vector2(70, 0)
	tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(tier_label)

	var plus_button := Button.new()
	plus_button.text = "+"
	plus_button.custom_minimum_size = Vector2(36, 0)
	plus_button.focus_mode = Control.FOCUS_NONE
	plus_button.pressed.connect(_on_plus_pressed.bind(buff))
	row.add_child(plus_button)

	_rows[buff.buff_id] = {
		"buff": buff,
		"tier_label": tier_label,
		"minus": minus_button,
		"plus": plus_button,
	}

func _on_minus_pressed(buff: Buff_Definition) -> void:
	var current := buff_manager.get_buff_tier(buff.buff_id)
	var new_tier := buff_manager.set_buff_tier(buff, current - 1, &"debug")

	log_message("%s -> tier %d" % [_get_buff_name(buff), new_tier])

func _on_plus_pressed(buff: Buff_Definition) -> void:
	var new_tier := buff_manager.apply_buff(buff, &"debug")

	log_message("%s -> tier %d" % [_get_buff_name(buff), new_tier])

func _on_buff_tier_changed(_buff: Buff_Definition, _old_tier: int, _new_tier: int, _source: StringName) -> void:
	_refresh_all()

func _refresh_all() -> void:
	if buff_manager == null:
		return

	for buff_id in _rows:
		var data: Dictionary = _rows[buff_id]
		var buff: Buff_Definition = data["buff"]
		var tier := buff_manager.get_buff_tier(buff.buff_id)
		var max_tier := buff.max_tier if buff.duplicates_upgrade else 1
		var tier_label: Label = data["tier_label"]
		var minus_button: Button = data["minus"]
		var plus_button: Button = data["plus"]

		tier_label.text = "%d / %d" % [tier, max_tier]
		minus_button.disabled = tier <= 0
		plus_button.disabled = tier >= max_tier

func _get_buff_name(buff: Buff_Definition) -> String:
	if buff.display_name != "":
		return buff.display_name

	return str(buff.buff_id)
