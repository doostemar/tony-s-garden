# day_timer.gd
class_name DayTimer
extends Node

signal time_changed(time_remaining: float)
signal paused_changed(is_paused: bool)
signal expired()

var _time_remaining: float = 0.0
var _running: bool = false
var _paused: bool = false

var _last_displayed_second: int = -1


func _process(delta: float) -> void:
	if not _running or _paused:
		return

	_time_remaining = max(
		_time_remaining - delta,
		0.0
	)

	var current_second: int = int(ceil(_time_remaining))

	if current_second != _last_displayed_second:
		_last_displayed_second = current_second
		time_changed.emit(_time_remaining)

	if _time_remaining <= 0.0:
		_running = false
		expired.emit()


func start(
	duration: float,
	emit_updates: bool = true
) -> void:
	_time_remaining = max(duration, 0.0)
	_last_displayed_second = -1
	_running = true
	_paused = false

	if emit_updates:
		time_changed.emit(_time_remaining)
		paused_changed.emit(_paused)


func stop() -> void:
	_running = false
	_paused = false


func resume() -> void:
	if _time_remaining <= 0.0:
		return

	_running = true


func set_paused(value: bool) -> void:
	_paused = value
	paused_changed.emit(_paused)

	print(
		"DayTimer: %s"
		% ("PAUSED" if _paused else "RESUMED")
	)


func set_time(
	value: float,
	emit_update: bool = true
) -> void:
	_time_remaining = max(value, 0.0)
	_last_displayed_second = -1

	if emit_update:
		time_changed.emit(_time_remaining)


func add_time(
	amount: float,
	emit_update: bool = true
) -> void:
	set_time(
		_time_remaining + amount,
		emit_update
	)


func get_time_remaining() -> float:
	return _time_remaining


func is_paused() -> bool:
	return _paused


func is_running() -> bool:
	return _running
