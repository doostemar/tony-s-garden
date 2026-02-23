# box.gd
extends StaticBody2D

@export var garden_manager: Garden_Manager

func _ready():
	position = garden_manager.get_center()
	event_bus.garden_regenerated.connect(_on_garden_regenerated)

func _on_garden_regenerated(_side_length: int) -> void:
	position = garden_manager.get_center()
