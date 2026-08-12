# debug_game_controls.gd
class_name DebugGameControls
extends DebugModule

@export var game_manager_path: NodePath
@export var panel_size: Vector2 = Vector2(320, 460)
@export var panel_position: Vector2 = Vector2(780, 10)
@export var time_step: float = 10.0
@export var update_interval: float = 0.2

var game_manager: GameManager

var panel: Panel
var info_label: RichTextLabel
var pause_button: CheckButton
var time_input: LineEdit
var time_set_button: Button
var time_add_button: Button
var time_remove_button: Button
var day_label: Label
var day_prev_button: Button
var day_next_button: Button
var quota_input: SpinBox
var reset_day_button: Button

var _update_timer: float = 0.0

func _init() -> void:
	module_name = "Game Controls"
	start_visible = false

func setup() -> void:
	if not game_manager_path.is_empty():
		game_manager = get_node_or_null(game_manager_path)
	
	if game_manager == null:
		game_manager = _find_game_manager()
	
	if game_manager == null:
		push_error("DebugGameControls: GameManager not found")
		return
	
	_create_panel()
	_setup_drag(panel)
	_connect_game_signals()

func post_setup() -> void:
	_refresh_all()
	log_message("Game Controls panel initialized")

# --- panel --- #
func _create_panel() -> void:
	panel = Panel.new()
	panel.name = "GameControlsPanel"
	panel.position = panel_position
	panel.size = panel_size
	add_child(panel)
	main_panel = panel
	
	var root_vbox := VBoxContainer.new()
	root_vbox.name = "RootVBox"
	root_vbox.position = Vector2(10, 10)
	root_vbox.size = Vector2(panel_size.x - 20, panel_size.y - 20)
	panel.add_child(root_vbox)
	
	# title
	var title := Label.new()
	title.text = "Game Controls"
	title.add_theme_font_size_override("font_size", 16)
	root_vbox.add_child(title)
	
	# live status
	info_label = RichTextLabel.new()
	info_label.bbcode_enabled = true
	info_label.fit_content = true
	info_label.custom_minimum_size = Vector2(0, 60)
	info_label.scroll_active = false
	info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_vbox.add_child(info_label)
	
	_add_separator(root_vbox)
	
	# timer pause toggle
	pause_button = CheckButton.new()
	pause_button.text = "Pause Day Timer"
	pause_button.focus_mode = Control.FOCUS_NONE
	pause_button.toggled.connect(_on_pause_toggled)
	root_vbox.add_child(pause_button)
	
	_add_separator(root_vbox)
	
	# time controls
	var time_title := Label.new()
	time_title.text = "Time"
	time_title.add_theme_font_size_override("font_size", 14)
	root_vbox.add_child(time_title)
	
	var time_entry_row := HBoxContainer.new()
	root_vbox.add_child(time_entry_row)
	
	var time_entry_label := Label.new()
	time_entry_label.text = "Set:"
	time_entry_label.custom_minimum_size = Vector2(30, 0)
	time_entry_row.add_child(time_entry_label)
	
	time_input = LineEdit.new()
	time_input.placeholder_text = "seconds"
	time_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_input.text_submitted.connect(_on_time_text_submitted)
	time_entry_row.add_child(time_input)
	
	time_set_button = Button.new()
	time_set_button.text = "Apply"
	time_set_button.custom_minimum_size = Vector2(60, 0)
	time_set_button.focus_mode = Control.FOCUS_NONE
	time_set_button.pressed.connect(_on_time_set_pressed)
	time_entry_row.add_child(time_set_button)
	
	var time_step_row := HBoxContainer.new()
	root_vbox.add_child(time_step_row)
	
	time_remove_button = Button.new()
	time_remove_button.text = "- %.0fs" % time_step
	time_remove_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_remove_button.focus_mode = Control.FOCUS_NONE
	time_remove_button.pressed.connect(_on_time_remove_pressed)
	time_step_row.add_child(time_remove_button)
	
	time_add_button = Button.new()
	time_add_button.text = "+ %.0fs" % time_step
	time_add_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_add_button.focus_mode = Control.FOCUS_NONE
	time_add_button.pressed.connect(_on_time_add_pressed)
	time_step_row.add_child(time_add_button)
	
	_add_separator(root_vbox)
	
	# day controls
	var day_title := Label.new()
	day_title.text = "Day"
	day_title.add_theme_font_size_override("font_size", 14)
	root_vbox.add_child(day_title)
	
	var day_row := HBoxContainer.new()
	root_vbox.add_child(day_row)
	
	day_prev_button = Button.new()
	day_prev_button.text = "< Prev"
	day_prev_button.custom_minimum_size = Vector2(70, 0)
	day_prev_button.focus_mode = Control.FOCUS_NONE
	day_prev_button.pressed.connect(_on_day_prev_pressed)
	day_row.add_child(day_prev_button)
	
	day_label = Label.new()
	day_label.text = "Day ?"
	day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	day_row.add_child(day_label)
	
	day_next_button = Button.new()
	day_next_button.text = "Next >"
	day_next_button.custom_minimum_size = Vector2(70, 0)
	day_next_button.focus_mode = Control.FOCUS_NONE
	day_next_button.pressed.connect(_on_day_next_pressed)
	day_row.add_child(day_next_button)
	
	_add_separator(root_vbox)
	
	# quota controls
	var quota_title := Label.new()
	quota_title.text = "Quota Target"
	quota_title.add_theme_font_size_override("font_size", 14)
	root_vbox.add_child(quota_title)
	
	var quota_row := HBoxContainer.new()
	root_vbox.add_child(quota_row)
	
	quota_input = SpinBox.new()
	quota_input.min_value = 0
	quota_input.max_value = 999
	quota_input.step = 1
	quota_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# spinbox's internal lineedit should not hold focus after use
	quota_input.get_line_edit().focus_mode = Control.FOCUS_CLICK
	quota_input.get_line_edit().focus_exited.connect(_clear_focus)
	quota_row.add_child(quota_input)
	
	var quota_apply := Button.new()
	quota_apply.text = "Apply"
	quota_apply.custom_minimum_size = Vector2(60, 0)
	quota_apply.focus_mode = Control.FOCUS_NONE
	quota_apply.pressed.connect(_on_quota_apply_pressed)
	quota_row.add_child(quota_apply)
	
	_add_separator(root_vbox)
	
	# reset day button
	reset_day_button = Button.new()
	reset_day_button.text = "Reset Day"
	reset_day_button.focus_mode = Control.FOCUS_NONE
	reset_day_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_day_button.pressed.connect(_on_reset_day_pressed)
	root_vbox.add_child(reset_day_button)

func _add_separator(parent: Control) -> void:
	var sep := HSeparator.new()
	parent.add_child(sep)

func _clear_focus() -> void:
	var focused := get_viewport().gui_get_focus_owner() if get_viewport() else null
	if focused:
		focused.release_focus()

# --- signals/events --- #
func _connect_game_signals() -> void:
	game_manager.day_started.connect(_on_day_started)
	game_manager.time_updated.connect(_on_time_updated)
	game_manager.quota_updated.connect(_on_quota_updated)
	game_manager.timer_paused_changed.connect(_on_timer_paused_changed)

func _on_day_started(_day_number: int) -> void:
	_refresh_all()

func _on_time_updated(_time: float) -> void:
	_refresh_info()

func _on_quota_updated(_current: int, _target: int) -> void:
	_refresh_info()
	_refresh_quota_display()

func _on_timer_paused_changed(is_paused: bool) -> void:
	if pause_button:
		pause_button.set_pressed_no_signal(is_paused)

# --- ui refresh --- #
func _refresh_all() -> void:
	_refresh_info()
	_refresh_day_display()
	_refresh_quota_display()
	_refresh_pause_display()

func _refresh_info() -> void:
	if not info_label or not game_manager:
		return
	
	var config = game_manager.get_current_config()
	var lines: Array[String] = []
	
	var day_num := game_manager.get_current_day_number()
	var day_idx := game_manager.get_current_day_index()
	var total_days := game_manager.get_day_count()
	lines.append("[color=yellow]Day:[/color] %d  [color=gray](%d/%d)[/color]" % [day_num, day_idx + 1, total_days])
	
	var time_left := game_manager.get_time_remaining()
	var paused_tag := "  [color=red][PAUSED][/color]" if game_manager.is_timer_paused() else ""
	lines.append("[color=yellow]Time:[/color] %.1fs%s" % [time_left, paused_tag])
	
	if config:
		var progress := game_manager.get_quota_progress()
		var quota_target = config.quota
		var quota_color := "green" if progress >= quota_target else "white"
		lines.append("[color=yellow]Quota:[/color] [color=%s]%d / %d[/color]" % [quota_color, progress, quota_target])
		lines.append("[color=yellow]Difficulty:[/color] %d" % config.difficulty)
	
	var active_color := "green" if game_manager.is_day_in_progress() else "red"
	lines.append("[color=yellow]Active:[/color] [color=%s]%s[/color]" % [active_color, game_manager.is_day_in_progress()])
	
	if game_manager.is_awaiting_continue():
		lines.append("[color=cyan][Press Enter to continue][/color]")

	info_label.clear()
	info_label.append_text("\n".join(lines))


func _refresh_day_display() -> void:
	if not day_label or not game_manager:
		return
	
	var day_idx := game_manager.get_current_day_index()
	var total := game_manager.get_day_count()
	var day_num := game_manager.get_current_day_number()
	
	day_label.text = "Day %d" % day_num
	day_prev_button.disabled = day_idx <= 0
	day_next_button.disabled = day_idx >= total - 1

func _refresh_quota_display() -> void:
	if not quota_input or not game_manager:
		return
	var config = game_manager.get_current_config()
	if config:
		quota_input.set_value_no_signal(config.quota)

func _refresh_pause_display() -> void:
	if not pause_button or not game_manager:
		return
	pause_button.set_pressed_no_signal(game_manager.is_timer_paused())

# --- button stuff --- #
func _on_pause_toggled(paused: bool) -> void:
	if not game_manager:
		return
	game_manager.set_timer_paused(paused)
	log_message("Timer %s" % ("paused" if paused else "resumed"))

func _on_time_set_pressed() -> void:
	_apply_time_from_input()

func _on_time_text_submitted(_text: String) -> void:
	_apply_time_from_input()
	# Clear focus so Enter doesn't loop
	_clear_focus()

func _apply_time_from_input() -> void:
	if not game_manager:
		return
	var text := time_input.text.strip_edges()
	if not text.is_valid_float():
		log_message("[color=red]Invalid time value: '%s'[/color]" % text)
		return
	var value := text.to_float()
	game_manager.debug_set_time(value)
	time_input.clear()
	log_message("Time set to %.1f" % value)
	_refresh_info()

func _on_time_add_pressed() -> void:
	if not game_manager:
		return
	game_manager.debug_add_time(time_step)
	log_message("Added %.0fs" % time_step)
	_refresh_info()

func _on_time_remove_pressed() -> void:
	if not game_manager:
		return
	game_manager.debug_add_time(-time_step)
	log_message("Removed %.0fs" % time_step)
	_refresh_info()

func _on_day_prev_pressed() -> void:
	if not game_manager:
		return
	var new_index := game_manager.get_current_day_index() - 1
	if new_index < 0:
		return
	game_manager.debug_set_day(new_index)
	log_message("Switched to day %d" % game_manager.get_current_day_number())
	_refresh_all()

func _on_day_next_pressed() -> void:
	if not game_manager:
		return
	var new_index := game_manager.get_current_day_index() + 1
	if new_index >= game_manager.get_day_count():
		return
	game_manager.debug_set_day(new_index)
	log_message("Switched to day %d" % game_manager.get_current_day_number())
	_refresh_all()

func _on_quota_apply_pressed() -> void:
	if not game_manager:
		return
	var new_quota := int(quota_input.value)
	game_manager.debug_set_quota(new_quota)
	log_message("Quota set to %d" % new_quota)
	_refresh_info()

func _on_reset_day_pressed() -> void:
	if not game_manager:
		return
	game_manager.debug_reset_day()
	log_message("Day reset")
	_refresh_all()

# --- p --- #
func _process(delta: float) -> void:
	if not panel or not panel.visible:
		return
	
	_update_timer += delta
	if _update_timer >= update_interval:
		_update_timer = 0.0
		_refresh_info()
		_refresh_day_display()

# --- util --- #
func _find_game_manager() -> GameManager:
	var nodes := get_tree().get_nodes_in_group("game_manager")
	if nodes.size() > 0 and nodes[0] is GameManager:
		return nodes[0]
	return _recursive_find(get_tree().root)

func _recursive_find(node: Node) -> GameManager:
	if node is GameManager:
		return node
	for child in node.get_children():
		var result := _recursive_find(child)
		if result:
			return result
	return null
