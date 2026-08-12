class_name GameManager
extends Node

# ------------------------------------------------------------------
# Public signals
# ------------------------------------------------------------------

signal day_started(day_number: int)
signal day_ended(
	success: bool,
	harvested: int,
	quota: int
)

signal quota_updated(
	current: int,
	target: int
)

signal time_updated(time_remaining: float)
signal bonus_updated(total_bonus: int)
signal timer_paused_changed(is_paused: bool)
signal awaiting_continue_changed(is_waiting: bool)
signal game_ended()


# ------------------------------------------------------------------
# World references
# ------------------------------------------------------------------

@export_group("World References")
@export var tony: CharacterBody2D
@export var garden_manager: Garden_Manager
@export var radish_manager: Radish_Manager
@export var animal_manager: Node2D

# ------------------------------------------------------------------
# Internal components
# ------------------------------------------------------------------

@export_group("Children")
@export var _schedule: DaySchedule
@export var _timer: DayTimer
@export var _progress: GameProgress
@export var _world_resetter: DayWorldResetter


# ------------------------------------------------------------------
# Game settings
# ------------------------------------------------------------------

@export_group("Game Settings")
@export var auto_start_day_one: bool = true
@export var endless_spawn_chance_increment: float = 0.05

# ------------------------------------------------------------------
# Lifecycle state owned by GameManager
# ------------------------------------------------------------------

var _day_in_progress: bool = false
var _awaiting_continue: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_configure_components()
	_connect_component_signals()
	_connect_gameplay_signals()

	if auto_start_day_one:
		call_deferred("start_day", 0)


func _unhandled_input(event: InputEvent) -> void:
	if (
		_awaiting_continue
		and event.is_action_pressed("ui_accept")
	):
		get_viewport().set_input_as_handled()
		confirm_continue()


# ------------------------------------------------------------------
# Setup
# ------------------------------------------------------------------

func _configure_components() -> void:
	_world_resetter.configure(
		tony,
		garden_manager,
		radish_manager,
		animal_manager
	)


func _connect_component_signals() -> void:
	_timer.time_changed.connect(
		_on_timer_time_changed
	)

	_timer.paused_changed.connect(
		_on_timer_paused_changed
	)

	_timer.expired.connect(
		_on_timer_expired
	)

	_progress.quota_changed.connect(
		_on_progress_quota_changed
	)

	_progress.bonus_changed.connect(
		_on_progress_bonus_changed
	)

	_schedule.endless_day_created.connect(
		_on_endless_day_created
	)


func _connect_gameplay_signals() -> void:
	event_bus.harvested.connect(
		_on_radish_harvested
	)


# ------------------------------------------------------------------
# Day lifecycle
# ------------------------------------------------------------------

func start_day(day_index: int = -1) -> void:
	if day_index >= 0:
		if not _schedule.set_current_day(day_index):
			push_error(
				"GameManager: Invalid day index %d"
				% day_index
			)
			return

	var config: DayConfig = (
		_schedule.get_current_config()
	)

	if config == null:
		push_error(
			"GameManager: No config for day index %d"
			% _schedule.get_current_day_index()
		)
		return

	# Establish lifecycle state before rebuilding.
	_day_in_progress = true
	_awaiting_continue = false

	# Difficulty is part of applying this day's world config.
	event_bus.difficulty_changed.emit(
		config.difficulty
	)

	# Completely prepare the world before gameplay resumes.
	_world_resetter.reset_for_day(config)

	get_tree().paused = false

	# Initialize child state without emitting internal updates yet.
	# GameManager emits the public signals below in the same order
	# as the original implementation.
	_progress.begin_day(
		config.quota,
		false
	)

	_timer.start(
		config.time_limit,
		false
	)

	# Preserve the original public notification order.
	day_started.emit(config.day_number)

	quota_updated.emit(
		_progress.get_quota_progress(),
		_progress.get_quota_target()
	)

	time_updated.emit(
		_timer.get_time_remaining()
	)

	bonus_updated.emit(
		_progress.get_bonus_radishes()
	)

	timer_paused_changed.emit(
		_timer.is_paused()
	)

	awaiting_continue_changed.emit(
		_awaiting_continue
	)

	print(
		"GameManager: Day %d started | "
		+ "Quota: %d | Time: %.0fs | Difficulty: %d"
		% [
			config.day_number,
			config.quota,
			config.time_limit,
			config.difficulty,
		]
	)


func _end_day() -> void:
	if not _day_in_progress:
		return

	_day_in_progress = false
	_timer.stop()

	var config: DayConfig = (
		_schedule.get_current_config()
	)

	if config == null:
		return

	var success: bool = _progress.finish_day()

	# Freeze gameplay after all end-of-day calculations.
	get_tree().paused = true

	day_ended.emit(
		success,
		_progress.get_quota_progress(),
		config.quota
	)

	print(
		"GameManager: Day %d ended | "
		+ "Success: %s | Harvested: %d/%d"
		% [
			config.day_number,
			success,
			_progress.get_quota_progress(),
			config.quota,
		]
	)

	_set_awaiting_continue(true)

	print(
		"GameManager: Press Enter to continue to next day"
	)


func advance_to_next_day() -> bool:
	if not _schedule.advance():
		push_warning(
			"GameManager: No more days configured!"
		)
		return false

	start_day()
	return true


func confirm_continue() -> void:
	_set_awaiting_continue(false)

	if not advance_to_next_day():
		print(
			"GameManager: All days completed!"
		)


func restart_current_day() -> void:
	start_day(
		_schedule.get_current_day_index()
	)


func end_game() -> void:
	_day_in_progress = false
	_timer.stop()

	_set_awaiting_continue(false)

	print(
		"GameManager: Game ended by player"
	)

	game_ended.emit()
	get_tree().quit()


# ------------------------------------------------------------------
# Endless mode
# ------------------------------------------------------------------

func enter_endless_mode() -> void:
	_schedule.enter_endless_mode()

	print(
		"GameManager: Endless mode enabled"
	)


func _on_endless_day_created(
	_config: DayConfig
) -> void:
	if (
		animal_manager
		and animal_manager.has_method(
			"increase_spawn_chance"
		)
	):
		animal_manager.increase_spawn_chance(
			endless_spawn_chance_increment
		)


func is_on_final_day() -> bool:
	return _schedule.is_on_final_day()


# ------------------------------------------------------------------
# Timer
# ------------------------------------------------------------------

func set_timer_paused(paused: bool) -> void:
	if not _day_in_progress:
		return

	_timer.set_paused(paused)


func _on_timer_time_changed(
	time_remaining: float
) -> void:
	time_updated.emit(time_remaining)


func _on_timer_paused_changed(
	is_paused: bool
) -> void:
	timer_paused_changed.emit(is_paused)


func _on_timer_expired() -> void:
	_end_day()


# ------------------------------------------------------------------
# Progress / economy
# ------------------------------------------------------------------

func _on_radish_harvested(value: int) -> void:
	if not _day_in_progress:
		return

	_progress.record_harvest(value)


func _on_progress_quota_changed(
	current: int,
	target: int
) -> void:
	quota_updated.emit(
		current,
		target
	)


func _on_progress_bonus_changed(
	total_bonus: int
) -> void:
	bonus_updated.emit(total_bonus)


func spend_bonus_radishes(amount: int) -> bool:
	return _progress.spend_bonus_radishes(amount)


func add_bonus_radishes(amount: int) -> void:
	_progress.add_bonus_radishes(amount)


# ------------------------------------------------------------------
# Continue state
# ------------------------------------------------------------------

func _set_awaiting_continue(value: bool) -> void:
	_awaiting_continue = value

	awaiting_continue_changed.emit(
		_awaiting_continue
	)


# ------------------------------------------------------------------
# Debug API
#
# Keep these on GameManager. Debug tools don't need to know which
# internal component owns the underlying state.
# ------------------------------------------------------------------

func debug_add_time(amount: float) -> void:
	_timer.add_time(
		amount,
		false
	)

	if (
		not _day_in_progress
		and _timer.get_time_remaining() > 0.0
	):
		_resume_day_from_debug()

	time_updated.emit(
		_timer.get_time_remaining()
	)

	print(
		"GameManager: Time adjusted by %.1f, now %.1f"
		% [
			amount,
			_timer.get_time_remaining(),
		]
	)


func debug_set_time(value: float) -> void:
	_timer.set_time(
		value,
		false
	)

	if (
		not _day_in_progress
		and _timer.get_time_remaining() > 0.0
	):
		_resume_day_from_debug()

	time_updated.emit(
		_timer.get_time_remaining()
	)

	print(
		"GameManager: Time set to %.1f"
		% _timer.get_time_remaining()
	)


func debug_set_day(day_index: int) -> void:
	if (
		day_index < 0
		or day_index >= _schedule.get_day_count()
	):
		push_warning(
			"GameManager: Invalid day index %d"
			% day_index
		)
		return

	start_day(day_index)

	print(
		"GameManager: Jumped to day index %d"
		% day_index
	)


func debug_set_quota(new_quota: int) -> void:
	var config: DayConfig = (
		_schedule.get_current_config()
	)

	if config == null:
		return

	config.quota = max(new_quota, 0)

	_progress.set_quota_target(
		config.quota
	)

	print(
		"GameManager: Quota changed to %d"
		% config.quota
	)


func debug_reset_day() -> void:
	var config: DayConfig = (
		_schedule.get_current_config()
	)

	if config == null:
		return

	_day_in_progress = true
	_awaiting_continue = false

	_world_resetter.reset_for_day(config)

	get_tree().paused = false

	_progress.begin_day(
		config.quota,
		false
	)

	_timer.start(
		config.time_limit,
		false
	)

	# Match the old debug-reset notification behavior.
	quota_updated.emit(
		_progress.get_quota_progress(),
		_progress.get_quota_target()
	)

	time_updated.emit(
		_timer.get_time_remaining()
	)

	timer_paused_changed.emit(
		_timer.is_paused()
	)

	awaiting_continue_changed.emit(
		_awaiting_continue
	)

	print(
		"GameManager: Day %d reset"
		% config.day_number
	)


func _resume_day_from_debug() -> void:
	_day_in_progress = true
	_awaiting_continue = false

	_timer.resume()

	get_tree().paused = false

	# Preserve the original debug resume notifications.
	timer_paused_changed.emit(
		_timer.is_paused()
	)

	awaiting_continue_changed.emit(
		_awaiting_continue
	)

	print(
		"GameManager: Day resumed via debug"
	)


# ------------------------------------------------------------------
# Public query API
# ------------------------------------------------------------------

func get_current_config() -> DayConfig:
	return _schedule.get_current_config()


func get_day_count() -> int:
	return _schedule.get_day_count()


func get_current_day_index() -> int:
	return _schedule.get_current_day_index()


func get_current_day_number() -> int:
	return _schedule.get_current_day_number()


func get_quota_progress() -> int:
	return _progress.get_quota_progress()


func get_quota_target() -> int:
	return _progress.get_quota_target()


func get_bonus_radishes() -> int:
	return _progress.get_bonus_radishes()


func get_time_remaining() -> float:
	return _timer.get_time_remaining()


func is_timer_paused() -> bool:
	return _timer.is_paused()


func is_awaiting_continue() -> bool:
	return _awaiting_continue


func is_day_in_progress() -> bool:
	return _day_in_progress
