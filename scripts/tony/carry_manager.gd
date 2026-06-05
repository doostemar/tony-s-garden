# carry_manager.gd
class_name Carry_Manager
extends Node

@export var context: Tony_Context
var held_item: Node = null  

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

func set_carry_item(item_id: StringName, carry_state: int, item) -> void:
	if item == null: 
		push_warning("Carry_Manager.set_carry_item: attempting to hold item that is null")
		return
	# Store the reference only. The node stays out of the scene tree while
	# held — parenting a Node2D to a plain Node positions it at world origin.
	held_item = item
	_item_in_hand_id = item_id
	_carry_state = carry_state
	if context:
		context.item_in_hand_id = _item_in_hand_id
		context.carry_state = _carry_state

func clear_hand() -> void:
	held_item = null 
	_item_in_hand_id = &""
	_carry_state = Tony_Context.CarryState.NONE
	if context:
		context.item_in_hand_id = _item_in_hand_id
		context.carry_state = _carry_state
