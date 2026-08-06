# game_manager.gd
# this probably needs to get split up
class_name GameManager
extends Node

signal day_started(day_number: int)
signal day_ended(success: bool, harvested: int, quota: int)
signal quota_updated(current: int, target: int)
signal time_updated(time_remaining: float)
signal bonus_updated(total_bonus: int)
signal timer_paused_changed(is_paused: bool)
signal awaiting_continue_changed(is_waiting: bool)
signal game_ended()

@export var tony: CharacterBody2D 
@export var garden_manager: Garden_Manager
@export var radish_manager: Radish_Manager
@export var animal_manager: Node2D
@export var day_configs: Array[DayConfig] = []
@export var auto_start_day_one: bool = true
@export var endless_spawn_chance_increment: float = 0.05

var current_day_index: int = 0
var current_quota_progress: int = 0
var bonus_radishes: int = 0
var time_remaining: float = 10.0
var day_in_progress: bool = false
var timer_paused: bool = false
var awaiting_continue: bool = false
var endless_mode: bool = false

var _last_displayed_second: int = -1

var _tony_spawn_position: Vector2


# --- lifecycle --- #
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_signals()
	_ensure_default_configs()

	if tony:
		_tony_spawn_position = tony.global_position

	if auto_start_day_one:
		call_deferred("start_day", 0)

	if garden_manager:
		print("GardenManager path: ", garden_manager.get_path())
	else:
		print("GardenManager is NULL")

func _process(delta: float) -> void:
	if not day_in_progress:
		return
	
	if timer_paused:
		return
	
	time_remaining -= delta
	
	var current_second := int(ceil(max(time_remaining, 0)))
	if current_second != _last_displayed_second:
		_last_displayed_second = current_second
		time_updated.emit(time_remaining)
	
	if time_remaining <= 0:
		time_remaining = 0
		_end_day()

func _unhandled_input(event: InputEvent) -> void:
	if awaiting_continue and event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		confirm_continue()

# --- setup --- #
func _connect_signals() -> void:
	event_bus.harvested.connect(_on_radish_harvested)

func _ensure_default_configs() -> void:
	if not day_configs.is_empty():
		return
	
	var day1 := DayConfig.new()
	day1.day_number = 1
	day1.quota = 1
	day1.time_limit = 10.0
	day1.garden_side_length = 9
	day1.difficulty = 0
	day_configs.append(day1)
	
	var day2 := DayConfig.new()
	day2.day_number = 2
	day2.quota = 1
	day2.time_limit = 10.0
	day2.garden_side_length = 11
	day2.difficulty = 1
	day_configs.append(day2)
	
	var day3 := DayConfig.new()
	day3.day_number = 3
	day3.quota = 1
	day3.time_limit = 10.0
	day3.garden_side_length = 13
	day3.difficulty = 2
	day_configs.append(day3)

# --- day stuff --- #
func start_day(day_index: int = -1) -> void:
	if day_index >= 0:
		current_day_index = day_index

	var config := _get_current_config()
	if not config:
		push_error("GameManager: No config for day index %d" % current_day_index)
		return

	current_quota_progress = 0
	time_remaining = config.time_limit
	_last_displayed_second = -1
	day_in_progress = true
	timer_paused = false
	awaiting_continue = false

	_apply_day_config(config)  # clean up previous day BEFORE unpausing
	get_tree().paused = false  # unpause so the new day runs cleanly

	day_started.emit(config.day_number)
	quota_updated.emit(current_quota_progress, config.quota)
	time_updated.emit(time_remaining)
	bonus_updated.emit(bonus_radishes)
	timer_paused_changed.emit(timer_paused)
	awaiting_continue_changed.emit(awaiting_continue)

	print("GameManager: Day %d started | Quota: %d | Time: %.0fs | Difficulty: %d" % [
		config.day_number, config.quota, config.time_limit, config.difficulty
	])

func _apply_day_config(config: DayConfig) -> void:
	event_bus.difficulty_changed.emit(config.difficulty)
	_reset_tony()              # clear hand first, then reset position
	_reset_radish_manager()    # now safe to free all radishes
	_reset_animal_manager()
	if garden_manager:
		garden_manager.side_length = config.garden_side_length
		garden_manager.regenerate_garden()
	else:
		push_warning("GameManager: garden_manager not assigned, cannot resize garden")

func _reset_tony() -> void:
	if not tony:
		return
	# drop whatever tony is holding so radish_manager can safely free it
	if tony.carry_manager:
		tony.carry_manager.clear_hand()
	tony.global_position = _tony_spawn_position

func _reset_animal_manager() -> void:
	if animal_manager and animal_manager.has_method("reset"):
		animal_manager.reset()
	else:
		if not animal_manager:
			push_warning("GameManager: animal_manager not assigned")

func _end_day() -> void:
	day_in_progress = false
	timer_paused = false
	
	var config := _get_current_config()
	if not config:
		return
	
	var success := current_quota_progress >= config.quota
	
	if current_quota_progress > config.quota:
		var excess := current_quota_progress - config.quota
		bonus_radishes += excess
		bonus_updated.emit(bonus_radishes)
		print("GameManager: Added %d excess radishes to bonus bank (total: %d)" % [excess, bonus_radishes])
	
	# freeze all gameplay – tony, animals, radish timers, etc.
	# nodes with PROCESS_MODE_ALWAYS (GameManager, ShopUI, DebugManager)
	# keep running.
	get_tree().paused = true
	
	day_ended.emit(success, current_quota_progress, config.quota)
	
	print("GameManager: Day %d ended | Success: %s | Harvested: %d/%d" % [
		config.day_number, success, current_quota_progress, config.quota
	])
	
	_set_awaiting_continue(true)
	print("GameManager: Press Enter to continue to next day")

func _set_awaiting_continue(value: bool) -> void:
	awaiting_continue = value
	awaiting_continue_changed.emit(awaiting_continue)

func confirm_continue() -> void:
	_set_awaiting_continue(false)

	if not advance_to_next_day():
		print("GameManager: All days completed!")

func get_quota_target() -> int:
	var config := _get_current_config()
	return config.quota if config else 0

func advance_to_next_day() -> bool:
	current_day_index += 1
	if current_day_index >= day_configs.size():
		if endless_mode:
			_append_endless_config()
		else:
			push_warning("GameManager: No more days configured!")
			return false
	start_day()
	return true

# --- endless mode --- #

func enter_endless_mode() -> void:
	endless_mode = true
	print("GameManager: Endless mode enabled")

func is_on_final_day() -> bool:
	# final configured day, or any day once we're in endless mode
	return endless_mode or current_day_index >= day_configs.size() - 1

func restart_current_day() -> void:
	start_day(current_day_index)

func end_game() -> void:
	day_in_progress = false
	_set_awaiting_continue(false)
	print("GameManager: Game ended by player")
	game_ended.emit()
	get_tree().quit()   # swap for a scene transition / end screen later

func _append_endless_config() -> void:
	var base := _get_endless_base_config()
	if base == null:
		push_error("GameManager: cannot build endless config, no base config")
		return
	var cfg := DayConfig.new()
	cfg.day_number = day_configs[day_configs.size() - 1].day_number + 1
	cfg.quota = base.quota
	cfg.time_limit = base.time_limit
	cfg.garden_side_length = base.garden_side_length
	cfg.difficulty = base.difficulty
	day_configs.append(cfg)
	_increase_animal_spawn_chance()
	print("GameManager: Endless day %d generated" % cfg.day_number)
func _get_endless_base_config() -> DayConfig:
	# use day 3's parameters as the basis for endless play
	for config in day_configs:
		if config.day_number == 3:
			return config
	if day_configs.is_empty():
		return null
	return day_configs[min(2, day_configs.size() - 1)]

func _increase_animal_spawn_chance() -> void:
	if animal_manager and animal_manager.has_method("increase_spawn_chance"):
		animal_manager.increase_spawn_chance(endless_spawn_chance_increment)

# --- debug methods --- #
func set_timer_paused(paused: bool) -> void:
	if not day_in_progress:
		return
	timer_paused = paused
	timer_paused_changed.emit(timer_paused)
	print("GameManager: Timer %s" % ("PAUSED" if paused else "RESUMED"))

func debug_add_time(amount: float) -> void:
	time_remaining = max(time_remaining + amount, 0.0)
	_last_displayed_second = -1
	
	if not day_in_progress and time_remaining > 0:
		_resume_day_from_debug()
	
	time_updated.emit(time_remaining)
	print("GameManager: Time adjusted by %.1f, now %.1f" % [amount, time_remaining])

func debug_set_time(value: float) -> void:
	time_remaining = max(value, 0.0)
	_last_displayed_second = -1
	
	if not day_in_progress and time_remaining > 0:
		_resume_day_from_debug()
	
	time_updated.emit(time_remaining)
	print("GameManager: Time set to %.1f" % time_remaining)

func debug_set_day(day_index: int) -> void:
	if day_index < 0 or day_index >= day_configs.size():
		push_warning("GameManager: Invalid day index %d" % day_index)
		return
	start_day(day_index)  # start_day already unpauses the tree
	print("GameManager: Jumped to day index %d" % day_index)

func debug_set_quota(new_quota: int) -> void:
	var config := _get_current_config()
	if not config:
		return
	config.quota = max(new_quota, 0)
	quota_updated.emit(current_quota_progress, config.quota)
	print("GameManager: Quota changed to %d" % config.quota)

func _reset_radish_manager():
	await(radish_manager.reset())

func debug_reset_day() -> void:
	var config := _get_current_config()
	if not config:
		return

	current_quota_progress = 0
	time_remaining = config.time_limit
	_last_displayed_second = -1
	day_in_progress = true
	timer_paused = false
	awaiting_continue = false

	_reset_tony()
	_reset_animal_manager()
	_reset_radish_manager()

	get_tree().paused = false

	if garden_manager:
		garden_manager.side_length = config.garden_side_length
		garden_manager.regenerate_garden()

	quota_updated.emit(current_quota_progress, config.quota)
	time_updated.emit(time_remaining)
	timer_paused_changed.emit(timer_paused)
	awaiting_continue_changed.emit(awaiting_continue)

	print("GameManager: Day %d reset" % config.day_number)


func _resume_day_from_debug() -> void:
	day_in_progress = true
	awaiting_continue = false
	# Unpause so gameplay resumes when debug restores time
	get_tree().paused = false
	timer_paused_changed.emit(timer_paused)
	awaiting_continue_changed.emit(awaiting_continue)
	print("GameManager: Day resumed via debug")

func get_day_count() -> int:
	return day_configs.size()

func get_current_day_index() -> int:
	return current_day_index

func is_timer_paused() -> bool:
	return timer_paused

func is_awaiting_continue() -> bool:
	return awaiting_continue

# --- events --- #
func _on_radish_harvested(value: int) -> void:
	if not day_in_progress:
		return
	
	var config := _get_current_config()
	if not config:
		return
	
	current_quota_progress += value
	quota_updated.emit(current_quota_progress, config.quota)
	
	if current_quota_progress == config.quota:
		print("GameManager: Quota met! Keep harvesting for bonus radishes!")

# --- get --- #
func _get_current_config() -> DayConfig:
	if current_day_index >= 0 and current_day_index < day_configs.size():
		return day_configs[current_day_index]
	return null

func get_current_day_number() -> int:
	var config := _get_current_config()
	return config.day_number if config else 0

func get_bonus_radishes() -> int:
	return bonus_radishes

func get_quota_progress() -> int:
	return current_quota_progress

func get_time_remaining() -> float:
	return time_remaining

func is_day_in_progress() -> bool:
	return day_in_progress

func spend_bonus_radishes(amount: int) -> bool:
	if amount > bonus_radishes:
		return false
	bonus_radishes -= amount
	bonus_updated.emit(bonus_radishes)
	return true

func add_bonus_radishes(amount: int) -> void:
	bonus_radishes += amount
	bonus_updated.emit(bonus_radishes)
