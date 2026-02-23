# enemy_factory.gd
class_name Enemy_Factory
extends Node

@export var context: Animal_Context
@export var difficulty_settings = [ 8, 5, 3 ]

# -- animal scenes -- #
@onready var _mole_scene: PackedScene = preload("res://scenes/mole.tscn")

# food preferences
enum food_pref { SEED, SPROUT, MATURE, ABANDONED }

var animals: Array[ Dictionary ] = []
var _steal_rates: Array = []

func init( steal_rates: Array ):
	animals = [
		{},
		{},
		{ "mole" : _mole_scene },
		{} 
	]
	_steal_rates = steal_rates

func spawn_animal( loc: Vector2i, state: int ) -> Node:
	var idx := state
	if idx < 0 or idx >= animals.size():
		push_warning( "enemy_factory.spawn_animal: state out of range: $s" % state )
		return null
	
	var valid_animals: Dictionary = animals[ idx ]
	
	if valid_animals.is_empty():
		push_warning( "enemy_factory.spawn_animal: no animals available for state=%s (idx = %s)" % [ state, idx ] )
		return null
	
	var options: Array = valid_animals.values() # we get an array of animal scenes
	var animal_scene := options.pick_random() as PackedScene # we pick a random one and convert it to PackedScene
	
	var instance := animal_scene.instantiate()
	instance.init( loc, _steal_rates[ context.difficulty ] )
	
	return instance
