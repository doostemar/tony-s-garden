# mole.gd
class_name Mole
extends StaticBody2D

@export var animation_component: Mole_Animations
@export var collision_shape: CollisionShape2D

var _steal_timer: Timer
var _timer_duration: int

func init( location: Vector2i, duration: int ):
	add_to_group( "animal" )
	global_position = location
	animation_component.init()
	
	# ordering
	z_index = 0
	z_as_relative = true
	y_sort_enabled = false

	# timer
	_timer_duration = duration

func _ready():
	_setup_timer()
	
func _setup_timer():
	_steal_timer = Timer.new()
	_steal_timer.wait_time = _timer_duration
	_steal_timer.one_shot = true
	_steal_timer.timeout.connect(_on_timeout)
	add_child(_steal_timer)
	# defer the start until the node is in the tree
	_steal_timer.start.call_deferred()
	print("we get here: mole._setup_timer")

func _on_timeout():
	print("we get here: mole._on_timeout")
	event_bus.emit_signal( "animal_stealing", self )
	exit()

func exit():
	collision_shape.set_deferred( "disabled", true )
	animation_component.play_exit()
	animation_component.animation_finished.connect( _on_exit_finished )

func _on_exit_finished():
	event_bus.emit_signal("animal_despawned", self)
	queue_free()
