class_name Grass
extends Area2D

func _ready():
	var collision_shape = get_node_or_null("CollisionShape2D")
	if collision_shape:
		collision_shape.debug_color = Color.GREEN
