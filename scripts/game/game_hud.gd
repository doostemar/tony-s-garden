class_name GameHUD
extends CanvasLayer

@export var game_manager: GameManager

@onready var vbox: VBoxContainer = $MarginContainer/VBoxContainer
@onready var timer_label: Label = $MarginContainer/VBoxContainer/timer_label
@onready var quota_label: Label = $MarginContainer/VBoxContainer/quota_label
@onready var bonus_label: Label = $MarginContainer/VBoxContainer/bonus_label
@onready var day_label: Label = $MarginContainer/VBoxContainer/day_label

const DIFFICULTY_NAMES := ["Chill", "Hungry", "Ravenous"]

# created in code
var _pause_button: CheckButton
var _difficulty_label: Label
var _spawn_chance_label: Label
var _buff_container: VBoxContainer
var _buff_labels: Dictionary = {}   # buff_id -> { "label": Label, "buff": Buff_Definition }

# resolved references
var buff_manager: Buff_Manager
var animal_manager                       # untyped so we can call its methods dynamically
var animal_context: Animal_Context

# --- lifecycle --- #

func _ready() -> void:
	_resolve_references()
	_build_controls()
	_build_status_display()
	_build_buff_display()
	_connect_signals()
	_initialize_display()

func _resolve_references() -> void:
	if not game_manager:
		push_error("GameHUD: game_manager not assigned!")
		return

	if game_manager.tony and game_manager.tony.has_method("get_buff_manager"):
		buff_manager = game_manager.tony.get_buff_manager()

	animal_manager = game_manager.animal_manager

	if animal_manager:
		animal_context = animal_manager.context

# --- build dynamic ui --- #

func _build_controls() -> void:
	_pause_button = CheckButton.new()
	_pause_button.text = "Pause"
	_pause_button.focus_mode = Control.FOCUS_NONE
	_pause_button.toggled.connect(_on_pause_toggled)
	vbox.add_child(_pause_button)

func _build_status_display() -> void:
	_difficulty_label = Label.new()
	vbox.add_child(_difficulty_label)

	_spawn_chance_label = Label.new()
	vbox.add_child(_spawn_chance_label)

	_update_difficulty_display()
	_update_spawn_chance_display()

func _build_buff_display() -> void:
	var header := Label.new()
	header.text = "Buffs"
	vbox.add_child(header)

	_buff_container = VBoxContainer.new()
	vbox.add_child(_buff_container)

	if buff_manager == null:
		return

	for buff in buff_manager.radish_buff_pool:
		if buff == null:
			continue

		var lbl := Label.new()
		_buff_container.add_child(lbl)
		_buff_labels[buff.buff_id] = {
			"label": lbl,
			"buff": buff
		}

	_update_buff_display()

# --- signals --- #

func _connect_signals() -> void:
	if game_manager:
		game_manager.time_updated.connect(_on_time_updated)
		game_manager.quota_updated.connect(_on_quota_updated)
		game_manager.bonus_updated.connect(_on_bonus_updated)
		game_manager.day_started.connect(_on_day_started)
		game_manager.day_ended.connect(_on_day_ended)
		game_manager.timer_paused_changed.connect(_on_timer_paused_changed)

	if buff_manager:
		buff_manager.buff_applied.connect(_on_buff_applied)

	if event_bus.has_signal("difficulty_changed"):
		event_bus.difficulty_changed.connect(_on_difficulty_changed)

	if animal_manager and animal_manager.has_signal("spawn_chance_updated"):
		animal_manager.spawn_chance_updated.connect(_on_spawn_chance_updated)

func _initialize_display() -> void:
	if timer_label:
		timer_label.text = "1:00"
	if quota_label:
		quota_label.text = "0 / 5"
	if bonus_label:
		bonus_label.text = "Bonus: 0"
	if day_label:
		day_label.text = "Day 1"

# --- updates --- #

func _update_buff_display() -> void:
	if buff_manager == null:
		return

	for buff_id in _buff_labels:
		var data: Dictionary = _buff_labels[buff_id]
		var buff: Buff_Definition = data["buff"]
		var lbl: Label = data["label"]

		var tier := buff_manager.get_buff_tier(buff_id)
		lbl.text = "%s: %d/%d" % [buff.display_name, tier, buff.max_tier]

		if tier > 0:
			lbl.add_theme_color_override("font_color", Color.GREEN)
		else:
			lbl.remove_theme_color_override("font_color")

func _update_difficulty_display() -> void:
	if _difficulty_label == null:
		return

	var diff := animal_context.difficulty if animal_context else 0
	var diff_name = (
		DIFFICULTY_NAMES[diff]
		if diff >= 0 and diff < DIFFICULTY_NAMES.size()
		else str(diff)
	)

	_difficulty_label.text = "Difficulty: %s" % diff_name

func _update_spawn_chance_display() -> void:
	if _spawn_chance_label == null or animal_manager == null:
		return

	var chance: float = animal_manager.get_spawn_chance()
	_spawn_chance_label.text = "Spawn Chance: %d%%" % int(round(chance * 100.0))

# --- signal handlers --- #

func _on_time_updated(time_remaining: float) -> void:
	if not timer_label:
		return

	var total_seconds := int(ceil(max(time_remaining, 0)))
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60

	timer_label.text = "%d:%02d" % [minutes, seconds]

	if total_seconds <= 10:
		timer_label.add_theme_color_override("font_color", Color.RED)
	elif total_seconds <= 30:
		timer_label.add_theme_color_override("font_color", Color.ORANGE)
	else:
		timer_label.remove_theme_color_override("font_color")

func _on_quota_updated(current: int, target: int) -> void:
	if not quota_label:
		return

	quota_label.text = "%d / %d" % [current, target]

	if current >= target:
		quota_label.add_theme_color_override("font_color", Color.GREEN)
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

	if _pause_button:
		_pause_button.set_pressed_no_signal(false)
		_pause_button.text = "Pause"

	_update_difficulty_display()
	_update_spawn_chance_display()
	_update_buff_display()

func _on_day_ended(success: bool, harvested: int, quota: int) -> void:
	if success:
		print("GameHUD: Day complete! You harvested %d/%d radishes!" % [harvested, quota])
	else:
		print("GameHUD: Day failed. You only harvested %d/%d radishes." % [harvested, quota])

func _on_timer_paused_changed(is_paused: bool) -> void:
	if _pause_button:
		_pause_button.set_pressed_no_signal(is_paused)
		_pause_button.text = "Resume" if is_paused else "Pause"

func _on_pause_toggled(pressed: bool) -> void:
	if game_manager:
		game_manager.set_timer_paused(pressed)

func _on_buff_applied(_buff: Buff_Definition, _tier: int, _source: StringName) -> void:
	_update_buff_display()

func _on_difficulty_changed(_difficulty: int) -> void:
	_update_difficulty_display()
	_update_spawn_chance_display()   # difficulty shifts can move spawn chance

func _on_spawn_chance_updated(_chance: float) -> void:
	_update_spawn_chance_display()
