# buff_manager.gd
class_name Buff_Manager
extends Node

signal buff_applied(buff: Buff_Definition, new_tier: int, source: StringName)
signal buff_tier_changed(buff: Buff_Definition, old_tier: int, new_tier: int, source: StringName)
signal radish_buff_rolled(buff: Buff_Definition, new_tier: int, flavor_text: String)

@export var context: Tony_Context

# all radish buffs preassigned in inspector for registration
@export var radish_buff_pool: Array[Buff_Definition] = []

# optional / testing
@export var starting_buffs: Array[Buff_Definition] = []

# for tracking at runtime
var _buff_tiers: Dictionary = {}
var _buff_defs_by_id: Dictionary = {}

func _ready() -> void:
	for buff in radish_buff_pool:
		_register_buff(buff)

	for buff in starting_buffs:
		apply_buff(buff, &"starting_load")

func apply_buff(buff: Buff_Definition, source: StringName = &"unknown") -> int:
	if buff == null:
		push_warning("Tony_Buff_Manager.apply_buff: buff is null")
		return 0

	_register_buff(buff)

	var old_tier := get_buff_tier(buff.buff_id)
	var new_tier := old_tier

	if old_tier <= 0:
		new_tier = 1
	elif buff.duplicates_upgrade:
		new_tier = min(old_tier + 1, buff.max_tier)

	_buff_tiers[buff.buff_id] = new_tier
	_recalculate_context_modifiers()

	buff_applied.emit(buff, new_tier, source)

	if new_tier != old_tier:
		buff_tier_changed.emit(buff, old_tier, new_tier, source)

	return new_tier

func set_buff_tier(buff: Buff_Definition, tier: int, source: StringName = &"unknown") -> int:
	if buff == null:
		push_warning("Tony_Buff_Manager.set_buff_tier: buff is null")
		return 0

	_register_buff(buff)

	var old_tier := get_buff_tier(buff.buff_id)
	var max_tier := buff.max_tier if buff.duplicates_upgrade else 1
	var new_tier := clampi(tier, 0, max_tier)

	if new_tier == old_tier:
		return new_tier

	if new_tier == 0:
		_buff_tiers.erase(buff.buff_id)
	else:
		_buff_tiers[buff.buff_id] = new_tier

	_recalculate_context_modifiers()
	buff_tier_changed.emit(buff, old_tier, new_tier, source)

	return new_tier

func remove_buff(buff: Buff_Definition, source: StringName = &"unknown") -> void:
	set_buff_tier(buff, 0, source)

func apply_random_radish_buff() -> Buff_Definition:
	if radish_buff_pool.is_empty():
		push_warning("Tony_Buff_Manager.apply_random_radish_buff: radish_buff_pool is empty")
		return null

	var index := randi_range(0, radish_buff_pool.size() - 1)
	var buff := radish_buff_pool[index]
	var new_tier := apply_buff(buff, &"radish")
	radish_buff_rolled.emit(buff, new_tier, buff.flavor_text)

	return buff

func get_buff_tier(buff_id: StringName) -> int:
	if _buff_tiers.has(buff_id):
		return int(_buff_tiers[buff_id])

	return 0

func has_buff(buff_id: StringName) -> bool:
	return get_buff_tier(buff_id) > 0

func get_buff_definition(buff_id: StringName) -> Buff_Definition:
	if _buff_defs_by_id.has(buff_id):
		return _buff_defs_by_id[buff_id]

	return null

func get_all_buff_tiers() -> Dictionary:
	return _buff_tiers.duplicate(true)

func _register_buff(buff: Buff_Definition) -> void:
	if buff == null:
		return

	if buff.buff_id == &"":
		push_warning("Tony_Buff_Manager: encountered buff with empty buff_id")
		return

	_buff_defs_by_id[buff.buff_id] = buff

func _recalculate_context_modifiers() -> void:
	if context == null:
		push_warning("Tony_Buff_Manager._recalculate_context_modifiers: context not assigned")
		return

	var speed_mult := 1.0
	var shout_radius_mult := 1.0
	var throw_speed_mult := 1.0
	var plant_radius_mult := 1.0

	for buff_id in _buff_tiers:
		var tier: int = int(_buff_tiers[buff_id])

		if tier <= 0:
			continue

		var buff: Buff_Definition = _buff_defs_by_id.get(buff_id)

		if buff == null:
			continue

		var total_modifier := buff.modifier_per_tier * tier

		match buff.stat_type:
			Buff_Definition.StatType.MOVE_SPEED:
				speed_mult += total_modifier
			Buff_Definition.StatType.SHOUT_RADIUS:
				shout_radius_mult += total_modifier
			Buff_Definition.StatType.THROW_SPEED:
				throw_speed_mult += total_modifier
			Buff_Definition.StatType.PLANT_RADIUS:
				plant_radius_mult += total_modifier

	context.set_speed_mult(speed_mult)
	context.set_shout_radius_mult(shout_radius_mult)
	context.set_throw_speed_mult(throw_speed_mult)
	context.set_plant_radius_mult(plant_radius_mult)
