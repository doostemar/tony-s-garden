# box.gd
extends StaticBody2D

@export var garden_manager: Garden_Manager
@export var deposit_area: Area2D
@export var deposit_radius: float = 1.5
@export var radish_layer_bit: int = 6   # must match Radish.radish_layer_bit

func _ready():
	position = garden_manager.get_center()
	event_bus.garden_regenerated.connect(_on_garden_regenerated)
	_setup_deposit_area()

func _setup_deposit_area() -> void:
	deposit_area.monitoring = true
	deposit_area.monitorable = false
	deposit_area.collision_layer = 0
	deposit_area.collision_mask = 1 << radish_layer_bit
	deposit_area.area_entered.connect(_on_radish_area_entered)

func _on_radish_area_entered(area: Area2D) -> void:
	var radish := area.get_parent() as Radish
	if radish == null or not is_instance_valid(radish):
		return

	# Only accept radishes that were thrown — not ones being carried over the box.
	if radish.holder != null:
		return

	var state := radish.get_current_state()
	if state != Radish.RadishState.AIRBORNE and state != Radish.RadishState.LANDED:
		return

	_deposit(radish)

func _deposit(radish: Radish) -> void:
	event_bus.harvested.emit(1)
	event_bus.radish_destroy_requested.emit(radish)

func _on_garden_regenerated(_side_length: int) -> void:
	position = garden_manager.get_center()
