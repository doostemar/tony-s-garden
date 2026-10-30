# carry_manager.gd
class_name Carry_Manager
extends Node

signal held_count_changed(count: int)

@export var context: Tony_Context

# item that will be thrown next (top of the stack)
var held_item: Node = null

# every item currently being carried, in pickup order
var held_items: Array[Node] = []

var _item_in_hand_id: StringName = &""
var _carry_state: int = Tony_Context.CarryState.NONE


func is_hand_empty() -> bool:
	_prune_invalid_items()
	return held_items.is_empty()


func get_item_in_hand_id() -> StringName:
	_prune_invalid_items()
	return _item_in_hand_id


func get_carry_state() -> int:
	_prune_invalid_items()
	return _carry_state


func get_held_item() -> Node:
	_prune_invalid_items()
	return held_item


func get_held_items() -> Array[Node]:
	_prune_invalid_items()
	return held_items


func get_held_count() -> int:
	_prune_invalid_items()
	return held_items.size()


func is_holding(item: Node) -> bool:
	if not is_instance_valid(item):
		return false

	return held_items.has(item)


# compatibility method for existing callers
func set_carry_item(
	item_id: StringName,
	carry_state: int,
	item
) -> void:
	add_carry_item(item_id, carry_state, item)


func add_carry_item(
	item_id: StringName,
	carry_state: int,
	item
) -> bool:
	if not _is_usable(item):
		push_warning(
			"Carry_Manager.add_carry_item: invalid item"
		)
		return false

	_prune_invalid_items()

	if held_items.has(item):
		return false

	# store the reference only
	held_items.append(item)
	held_item = item
	_item_in_hand_id = item_id
	_carry_state = carry_state

	_sync_context()
	return true


# removes and returns one valid item from the stack
func take_held_item() -> Node:
	_prune_invalid_items()

	var item: Node = null

	while not held_items.is_empty():
		# untyped because the popped reference may have been freed
		var candidate = held_items.pop_back()

		if _is_usable(candidate):
			item = candidate
			break

	_refresh_hand_state()
	return item


# drops every reference without modifying the items themselves
func clear_hand() -> void:
	held_items.clear()
	_reset_hand_state()
	_sync_context()


# ---- internal validation ---- #

func _is_usable(item) -> bool:
	if not is_instance_valid(item):
		return false

	if not item is Node:
		return false

	if item.is_queued_for_deletion():
		return false

	return true


func _prune_invalid_items() -> void:
	var changed := false

	for i in range(held_items.size() - 1, -1, -1):
		var candidate = held_items[i]

		if not _is_usable(candidate):
			held_items.remove_at(i)
			changed = true

	if changed:
		_refresh_hand_state()


func _refresh_hand_state() -> void:
	if held_items.is_empty():
		_reset_hand_state()
	else:
		held_item = held_items.back()

	_sync_context()


func _reset_hand_state() -> void:
	held_item = null
	_item_in_hand_id = &""
	_carry_state = Tony_Context.CarryState.NONE


func _sync_context() -> void:
	if context:
		context.item_in_hand_id = _item_in_hand_id
		context.carry_state = _carry_state
		context.held_count = held_items.size()

	held_count_changed.emit(held_items.size())
