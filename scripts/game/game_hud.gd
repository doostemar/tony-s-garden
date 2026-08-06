class_name GameHUD
extends CanvasLayer

@export_group("Gameplay References")
@export var game_manager: GameManager
@export var tony: CharacterBody2D
@export var animal_manager: Node2D

@export_group("Main Display")
@export var day_label: Label
@export var timer_label: Label
@export var quota_label: Label
@export var bonus_label: Label

@export_group("Status Display")
@export var difficulty_label: Label
@export var spawn_chance_label: Label
@export var pause_button: CheckButton

@export_group("Buff Display")
@export var buff_container: VBoxContainer

const DIFFICULTY_NAMES := [
	"Chill",
	"Hungry",
	"Ravenous",
]

var buff_manager: Buff_Manager
var animal_context: Animal_Context

# buff_id -> { "label": Label, "buff": Buff_Definition }
var _buff_labels: Dictionary = {}


func _ready() -> void:
	_resolve_references()
	_connect_signals()
	_build_buff_display()
	_initialize_display()


func _resolve_references() -> void:
	if game_manager == null:
		push_error("GameHUD: game_manager not assigned.")

	if tony == null:
		push_error("GameHUD: tony not assigned.")
	elif tony.has_method("get_buff_manager"):
		buff_manager = tony.get_buff_manager()
	else:
		push_error("GameHUD: Tony does not provide get_buff_manager().")

	if animal_manager == null:
		push_warning("GameHUD: animal_manager not assigned.")
	elif "context" in animal_manager:
		animal_context = animal_manager.context


func _connect_signals() -> void:
	if game_manager:
		game_manager.time_updated.connect(_on_time_updated)
		game_manager.quota_updated.connect(_on_quota_updated)
		game_manager.bonus_updated.connect(_on_bonus_updated)
		game_manager.day_started.connect(_on_day_started)
		game_manager.day_ended.connect(_on_day_ended)
		game_manager.timer_paused_changed.connect(
			_on_timer_paused_changed
		)

	if pause_button:
		pause_button.toggled.connect(_on_pause_toggled)

	if buff_manager:
		buff_manager.buff_applied.connect(_on_buff_applied)

	if event_bus.has_signal("difficulty_changed"):
		event_bus.difficulty_changed.connect(
			_on_difficulty_changed
		)

	if (
		animal_manager
		and animal_manager.has_signal("spawn_chance_updated")
	):
		animal_manager.spawn_chance_updated.connect(
			_on_spawn_chance_updated
		)


func _build_buff_display() -> void:
	if buff_container == null:
		push_error("GameHUD: buff_container not assigned.")
		return

	for child in buff_container.get_children():
		child.queue_free()

	_buff_labels.clear()

	if buff_manager == null:
		return

	for buff in buff_manager.radish_buff_pool:
		if buff == null:
			continue

		var label := Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		buff_container.add_child(label)

		_buff_labels[buff.buff_id] = {
			"label": label,
			"buff": buff,
		}

	_update_buff_display()


func _initialize_display() -> void:
	if day_label:
		day_label.text = "Day %d" % (
			game_manager.get_current_day_number()
			if game_manager
			else 1
		)

	if timer_label:
		if game_manager:
			_on_time_updated(game_manager.get_time_remaining())
		else:
			timer_label.text = "1:00"

	if quota_label:
		if game_manager:
			_on_quota_updated(
				game_manager.get_quota_progress(),
				game_manager.get_quota_target()
			)
		else:
			quota_label.text = "0 / 5"

	if bonus_label:
		bonus_label.text = "Bonus: %d" % (
			game_manager.get_bonus_radishes()
			if game_manager
			else 0
		)

	if pause_button and game_manager:
		_on_timer_paused_changed(
			game_manager.is_timer_paused()
		)

	_update_difficulty_display()
	_update_spawn_chance_display()
	_update_buff_display()


func _update_buff_display() -> void:
	if buff_manager == null:
		return

	for buff_id in _buff_labels:
		var data: Dictionary = _buff_labels[buff_id]
		var buff: Buff_Definition = data["buff"]
		var label: Label = data["label"]

		var tier := buff_manager.get_buff_tier(buff_id)

		label.text = "%s: %d/%d" % [
			buff.display_name,
			tier,
			buff.max_tier,
		]

		if tier > 0:
			label.add_theme_color_override(
				"font_color",
				Color.GREEN
			)
		else:
			label.remove_theme_color_override("font_color")


func _update_difficulty_display() -> void:
	if difficulty_label == null:
		return

	var difficulty := (
		animal_context.difficulty
		if animal_context
		else 0
	)

	var difficulty_name = (
		DIFFICULTY_NAMES[difficulty]
		if (
			difficulty >= 0
			and difficulty < DIFFICULTY_NAMES.size()
		)
		else str(difficulty)
	)

	difficulty_label.text = (
		"Difficulty: %s" % difficulty_name
	)


func _update_spawn_chance_display() -> void:
	if spawn_chance_label == null:
		return

	if animal_manager == null:
		spawn_chance_label.text = "Spawn Chance: unavailable"
		return

	if not animal_manager.has_method("get_spawn_chance"):
		spawn_chance_label.text = "Spawn Chance: unavailable"
		return

	var chance: float = animal_manager.get_spawn_chance()

	spawn_chance_label.text = "Spawn Chance: %d%%" % int(
		round(chance * 100.0)
	)


func _on_time_updated(time_remaining: float) -> void:
	if timer_label == null:
		return

	var total_seconds := int(
		ceil(max(time_remaining, 0.0))
	)

	var minutes := total_seconds / 60
	var seconds := total_seconds % 60

	timer_label.text = "%d:%02d" % [
		minutes,
		seconds,
	]

	if total_seconds <= 10:
		timer_label.add_theme_color_override(
			"font_color",
			Color.RED
		)
	elif total_seconds <= 30:
		timer_label.add_theme_color_override(
			"font_color",
			Color.ORANGE
		)
	else:
		timer_label.remove_theme_color_override("font_color")


func _on_quota_updated(current: int, target: int) -> void:
	if quota_label == null:
		return

	quota_label.text = "%d / %d" % [
		current,
		target,
	]

	if current >= target:
		quota_label.add_theme_color_override(
			"font_color",
			Color.GREEN
		)
	else:
		quota_label.remove_theme_color_override("font_color")


func _on_bonus_updated(total_bonus: int) -> void:
	if bonus_label:
		bonus_label.text = "Bonus: %d" % total_bonus


func _on_day_started(day_number: int) -> void:
	if day_label:
		day_label.text = "Day %d" % day_number

	if timer_label:
		timer_label.remove_theme_color_override("font_color")

	if quota_label:
		quota_label.remove_theme_color_override("font_color")

	if pause_button:
		pause_button.set_pressed_no_signal(false)
		pause_button.text = "Pause"

	_update_difficulty_display()
	_update_spawn_chance_display()
	_update_buff_display()


func _on_day_ended(
	success: bool,
	harvested: int,
	quota: int
) -> void:
	if success:
		print(
			"GameHUD: Day complete! You harvested %d/%d radishes!"
			% [harvested, quota]
		)
	else:
		print(
			"GameHUD: Day failed. You only harvested %d/%d radishes."
			% [harvested, quota]
		)


func _on_timer_paused_changed(is_paused: bool) -> void:
	if pause_button == null:
		return

	pause_button.set_pressed_no_signal(is_paused)
	pause_button.text = (
		"Resume"
		if is_paused
		else "Pause"
	)


func _on_pause_toggled(pressed: bool) -> void:
	if game_manager:
		game_manager.set_timer_paused(pressed)


func _on_buff_applied(
	_buff: Buff_Definition,
	_tier: int,
	_source: StringName
) -> void:
	_update_buff_display()


func _on_difficulty_changed(_difficulty: int) -> void:
	_update_difficulty_display()
	_update_spawn_chance_display()


func _on_spawn_chance_updated(_chance: float) -> void:
	_update_spawn_chance_display()
