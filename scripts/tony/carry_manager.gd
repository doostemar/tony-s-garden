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
	return _carry_state == Tony_Context.CarryState.NONE


func get_item_in_hand_id() -> StringName:
	return _item_in_hand_id


func get_carry_state() -> int:
	return _carry_state


func get_held_item() -> Node:
	return held_item


func get_held_items() -> Array[Node]:
	return held_items


func get_held_count() -> int:
	return held_items.size()


func is_holding(item: Node) -> bool:
	return held_items.has(item)


# post item stack change: adds items to stack
func set_carry_item(item_id: StringName, carry_state: int, item) -> void:
	add_carry_item(item_id, carry_state, item)


func add_carry_item(item_id: StringName, carry_state: int, item) -> bool:
	if item == null:
		push_warning("Carry_Manager.add_carry_item: attempting to hold item that is null")
		return false

	if held_items.has(item):
		return false

	# store the reference only
	# node stays out of the scene tree while held — parenting a Node2D to a plain Node positions it at world origin.
	held_items.append(item)
	held_item = item
	_item_in_hand_id = item_id
	_carry_state = carry_state

	_sync_context()
	return true


# removes and returns ONE item (the most recently picked up)
# returns null if nothing valid is held
# hand state is cleared automatically when the stack becomes empty
func take_held_item() -> Node:
	var item: Node = null

	while item == null and not held_items.is_empty():
		var candidate: Node = held_items.pop_back()

		if candidate != null and is_instance_valid(candidate):
			item = candidate

	if held_items.is_empty():
		_reset_hand_state()
	else:
		held_item = held_items.back()

	_sync_context()
	return item


# drops every reference (does not touch the items themselves)
func clear_hand() -> void:
	held_items.clear()
	_reset_hand_state()
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
