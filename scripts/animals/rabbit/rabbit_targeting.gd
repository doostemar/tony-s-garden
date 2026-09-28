# rabbit_targeting.gd
class_name Rabbit_Targeting
extends Node

var rabbit: Rabbit
var context: Animal_Context
var active_animals: Array[Node] = []

var target: Radish


func init(p_rabbit: Rabbit) -> void:
	rabbit = p_rabbit


func set_context(p_context: Animal_Context, p_active_animals: Array[Node]) -> void:
	context = p_context
	active_animals = p_active_animals


func get_target() -> Radish:
	return target


func set_target(radish: Radish) -> void:
	target = radish


func release_target() -> Radish:
	var released := target
	target = null
	return released


func is_target_valid() -> bool:
	if not is_instance_valid(target):
		return false

	if target.is_queued_for_deletion():
		return false

	return target.get_current_state() == Radish.RadishState.SPROUT


func acquire_random_sprout() -> bool:
	var available := get_available_sprouts(get_other_rabbits())

	if available.is_empty():
		return false

	target = available.pick_random()
	return true


func get_available_sprouts(rabbits: Array[Node]) -> Array[Radish]:
	var result: Array[Radish] = []

	if context == null:
		return result

	for radish in context.get_radishes():
		if is_sprout_available(radish, rabbits):
			result.append(radish)

	return result


func is_sprout_available(radish: Radish, rabbits: Array[Node]) -> bool:
	if not is_instance_valid(radish):
		return false

	if radish.is_queued_for_deletion():
		return false

	if radish.get_current_state() != Radish.RadishState.SPROUT:
		return false

	for other in rabbits:
		if not is_instance_valid(other):
			continue

		if other == rabbit:
			continue

		if other is Rabbit:
			if (other as Rabbit).get_target() == radish:
				return false

	return true


func get_other_rabbits() -> Array[Node]:
	if rabbit == null or not rabbit.is_inside_tree():
		return active_animals

	return get_tree().get_nodes_in_group(Rabbit.RABBIT_GROUP)
