# day_schedule.gd
class_name DaySchedule
extends Node

signal endless_day_created(config: DayConfig)

@export var day_configs: Array[DayConfig] = []

var _current_day_index: int = 0
var _endless_mode: bool = false


func _ready() -> void:
	_ensure_default_configs()


func get_current_config() -> DayConfig:
	if (
		_current_day_index >= 0
		and _current_day_index < day_configs.size()
	):
		return day_configs[_current_day_index]

	return null


func set_current_day(day_index: int) -> bool:
	if day_index < 0 or day_index >= day_configs.size():
		return false

	_current_day_index = day_index
	return true


func advance() -> bool:
	var next_index: int = _current_day_index + 1

	if next_index >= day_configs.size():
		if not _endless_mode:
			return false

		if not _append_endless_config():
			return false

	_current_day_index = next_index
	return true


func enter_endless_mode() -> void:
	_endless_mode = true


func is_endless_mode() -> bool:
	return _endless_mode


func is_on_final_day() -> bool:
	return (
		_endless_mode
		or _current_day_index >= day_configs.size() - 1
	)


func get_day_count() -> int:
	return day_configs.size()


func get_current_day_index() -> int:
	return _current_day_index


func get_current_day_number() -> int:
	var config: DayConfig = get_current_config()

	if config == null:
		return 0

	return config.day_number


func _append_endless_config() -> bool:
	var base: DayConfig = _get_endless_base_config()

	if base == null:
		push_error(
			"DaySchedule: Cannot create endless day because no base config exists."
		)
		return false

	var config: DayConfig = DayConfig.new()

	var last_config: DayConfig = day_configs[day_configs.size() - 1]

	config.day_number = last_config.day_number + 1
	config.quota = base.quota
	config.time_limit = base.time_limit
	config.garden_side_length = base.garden_side_length
	config.difficulty = base.difficulty

	day_configs.append(config)

	endless_day_created.emit(config)

	print(
		"DaySchedule: Endless day %d generated"
		% config.day_number
	)

	return true


func _get_endless_base_config() -> DayConfig:
	for config: DayConfig in day_configs:
		if config.day_number == 3:
			return config

	if day_configs.is_empty():
		return null

	return day_configs[min(2, day_configs.size() - 1)]


func _ensure_default_configs() -> void:
	if not day_configs.is_empty():
		return

	var day1: DayConfig = DayConfig.new()
	day1.day_number = 1
	day1.quota = 1
	day1.time_limit = 10.0
	day1.garden_side_length = 9
	day1.difficulty = 0
	day_configs.append(day1)

	var day2: DayConfig = DayConfig.new()
	day2.day_number = 2
	day2.quota = 1
	day2.time_limit = 10.0
	day2.garden_side_length = 11
	day2.difficulty = 1
	day_configs.append(day2)

	var day3: DayConfig = DayConfig.new()
	day3.day_number = 3
	day3.quota = 1
	day3.time_limit = 10.0
	day3.garden_side_length = 13
	day3.difficulty = 2
	day_configs.append(day3)
