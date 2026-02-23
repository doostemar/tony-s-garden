# debug_collision_shapes.gd
class_name DebugCollisionShapes
extends DebugModule

## toggles visibility of collision shapes at runtime

var status_label: Label

func _init() -> void:
	module_name = "Collision Shapes"
	start_visible = false
	hide_from_menu = true 

func setup() -> void:
	# this module doesn't have a visual panel
	# hte toggle is built into DebugManager
	pass

## static helper to check if collisions are visible
static func are_collisions_visible() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		return tree.debug_collisions_hint
	return false

## static helper to set collision visibility
static func set_collisions_visible(visible: bool) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.debug_collisions_hint = visible
