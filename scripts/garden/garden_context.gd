extends Node

var radish_growth_rate: float = 50.0
var radish_growth_timer: float = 0.0
var radish_state_change_timer: float = 100.0

func _ready():
	print("hello")
	event_bus.garden_context_ready.emit( self )
