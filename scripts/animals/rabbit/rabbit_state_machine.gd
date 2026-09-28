# rabbit_state_machine.gd
class_name Rabbit_State_Machine
extends Node

var current_state: Rabbit_State


func init(rabbit: Rabbit, targeting: Rabbit_Targeting, starting_state: Rabbit_State) -> void:
	for child in get_children():
		if child is Rabbit_State:
			child.init(rabbit, targeting)

	change_state(starting_state)


func change_state(new_state: Rabbit_State) -> void:
	if new_state == null:
		return

	if current_state:
		current_state.exit()

	current_state = new_state
	current_state.enter()


func process_physics(delta: float) -> void:
	if current_state == null:
		return

	var new_state := current_state.process_physics(delta)

	if new_state:
		change_state(new_state)


func is_in_state(state: Rabbit_State) -> bool:
	return current_state == state
