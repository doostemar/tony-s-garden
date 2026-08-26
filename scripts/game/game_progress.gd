# game_progress.gd
class_name GameProgress
extends Node

signal quota_changed(current: int, target: int)
signal bonus_changed(total_bonus: int)

var _quota_progress: int = 0
var _quota_target: int = 0
var _bonus_radishes: int = 0


func begin_day(
	quota_target: int,
	emit_updates: bool = true
) -> void:
	_quota_progress = 0
	_quota_target = max(quota_target, 0)

	if emit_updates:
		quota_changed.emit(
			_quota_progress,
			_quota_target
		)

		bonus_changed.emit(_bonus_radishes)


func record_harvest(value: int) -> void:
	_quota_progress += value

	quota_changed.emit(
		_quota_progress,
		_quota_target
	)

	if _quota_progress == _quota_target:
		print(
			"GameProgress: Quota met! "
			+ "Keep harvesting for bonus radishes!"
		)


func finish_day() -> bool:
	var success: bool = (
		_quota_progress >= _quota_target
	)

	if _quota_progress > _quota_target:
		var excess: int = (
			_quota_progress - _quota_target
		)

		_bonus_radishes += excess

		bonus_changed.emit(_bonus_radishes)

		print(
			"GameProgress: Added %d excess radishes "
			+ "to bonus bank (total: %d)"
			% [excess, _bonus_radishes]
		)

	return success


func set_quota_target(value: int) -> void:
	_quota_target = max(value, 0)

	quota_changed.emit(
		_quota_progress,
		_quota_target
	)


func spend_bonus_radishes(amount: int) -> bool:
	if amount < 0:
		return false

	if amount > _bonus_radishes:
		return false

	_bonus_radishes -= amount
	bonus_changed.emit(_bonus_radishes)

	return true


func add_bonus_radishes(amount: int) -> void:
	_bonus_radishes += amount
	bonus_changed.emit(_bonus_radishes)


func get_quota_progress() -> int:
	return _quota_progress


func get_quota_target() -> int:
	return _quota_target


func get_bonus_radishes() -> int:
	return _bonus_radishes
