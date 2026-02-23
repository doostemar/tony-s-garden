# tony.gd
extends CharacterBody2D

# components and references
@export var movement_component: Tony_Movement # handles movement
@export var input_manager: Input_Manager # handles input
@export var animation_component: Tony_Animations # handles animations
@export var dirt_interaction: Dirt_Interaction # handles plant / harvest
@export var carry_manager: Carry_Manager # handles carry state
@export var context: Tony_Context # organizes the data / signals for other nodes
@export var box_deposit: Box_Deposit # small script for depositing radishes
@export var shout_component: Shout_Component # creates and toggles shout hitbox
@export var throw_component: Throw_Component # throws held radish

# variables
@export var movement_speed: float = 1.3 # tony's movement speed
@export var planting_hitbox_size: float = 3
@export var deposit_hitbox_size: float = 7
@export var shout_hitbox_size: float = 25
@export var shout_duration: float = 1

var held_radish: Radish

func _ready():
	held_radish = null
	movement_component.init( movement_speed )
	animation_component.init()
	dirt_interaction.init( planting_hitbox_size )
	box_deposit.init( deposit_hitbox_size )
	shout_component.init( shout_hitbox_size, shout_duration )
	
	input_manager.plant_pressed.connect( _on_action_plant )
	input_manager.dance_pressed.connect( _on_action_dance )
	input_manager.shout_pressed.connect( _on_action_shout )

func _physics_process( delta ):
	input_manager.process_input()
	var movement = movement_component.move()
	move_and_collide( movement ) # built in CharacterBody2D functiona

# ---- actions ----

func _on_action_plant():
	if carry_manager.is_hand_empty(): dirt_interaction.interact()
	elif not box_deposit.interact(): _throw()

func _on_action_shout():
	shout_component.shouting()

func _throw() -> void:
	if throw_component:
		throw_component.throw()
	else: print( "i can't throw this thing" )

func _on_action_dance():
	print( "dancing" )

# ---- helpers (deprecated) ----

# used to send the movement input stack to the movement component
func get_movement_input_stack() -> Array[String]:
	if input_manager and input_manager.has_method( "get_movement_input_stack" ):
		return input_manager.get_movement_input_stack()
	return []

func get_last_direction() -> int:
	return context.get_last_dir()

func get_speed() -> float:
	return movement_speed
