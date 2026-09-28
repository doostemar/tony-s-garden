# rabbit_state.gd
class_name Rabbit_State
extends Node

var rabbit: Rabbit
var targeting: Rabbit_Targeting


func init(
	p_rabbit: Rabbit,
	p_targeting: Rabbit_Targeting
) -> void:
	rabbit = p_rabbit
	targeting = p_targeting


func enter() -> void:
	pass


func exit() -> void:
	pass


func process_physics(_delta: float) -> Rabbit_State:
	return null
