# debug_module.gd
class_name DebugModule
extends Node

signal log_requested(message: String)

@export var module_name: String = "Module"
@export var start_visible: bool = false
@export var hide_from_menu: bool = false

var debug_manager: DebugManager
var main_panel: Panel

# --- drag state --- #
var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO

func _init_module(manager: DebugManager) -> void:
	debug_manager = manager

func setup() -> void:
	pass

func post_setup() -> void:
	pass

func cleanup() -> void:
	pass

func set_module_visible(visible: bool) -> void:
	if main_panel:
		main_panel.visible = visible

func log_message(msg: String) -> void:
	log_requested.emit(msg)

# --- dragging --- #
# call this from the module's own _gui_input if the panel has
# mouse_filter = STOP (the default for Panel), or wire it up in
# setup() with the helper below.

func _setup_drag(panel: Panel) -> void:
	# ensure the panel receives input events
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(_on_panel_gui_input.bind(panel))

func _on_panel_gui_input(event: InputEvent, panel: Panel) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			# event.position is local to the panel
			_drag_offset = event.position
		else:
			_dragging = false
			# release focus so game inputs are not swallowed
			var focused := panel.get_viewport().gui_get_focus_owner()
			if focused:
				focused.release_focus()
	
	elif event is InputEventMouseMotion and _dragging:
		# the CanvasLayer may be scaled, compensate so drag speed matches cursor
		var canvas_layer := _get_canvas_layer()
		var layer_scale := canvas_layer.scale if canvas_layer else Vector2.ONE
		var delta: Vector2 = event.relative / layer_scale
		panel.position += delta

func _get_canvas_layer() -> CanvasLayer:
	var node: Node = self
	while node:
		if node is CanvasLayer:
			return node
		node = node.get_parent()
	return null
