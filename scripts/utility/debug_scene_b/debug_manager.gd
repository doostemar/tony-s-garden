# debug_manager.gd
class_name DebugManager
extends CanvasLayer

signal debug_menu_toggled(is_open: bool)

@export var player_path: Node
@export var garden_manager_path: Node

@export var ui_offset: Vector2 = Vector2(400, 50)
@export var ui_scale: Vector2 = Vector2(0.5, 0.5)
@export var toggle_button_size: Vector2 = Vector2(80, 30)
@export var toggle_button_position: Vector2 = Vector2(10, 10)

var player: CharacterBody2D
var garden_manager: Garden_Manager

var modules: Array[DebugModule] = []
var _debug_menu_open: bool = false

var _toggle_button: Button
var _menu_panel: Panel
var _menu_container: VBoxContainer
var _module_buttons: Dictionary = {}

func _ready() -> void:
	player = player_path
	garden_manager = garden_manager_path
	
	if player == null:
		push_warning("DebugManager: Player not found at path: %s" % player_path)
	if garden_manager == null:
		push_warning("DebugManager: Garden_Manager not found at path: %s" % garden_manager_path)
	
	offset = ui_offset
	scale = ui_scale
	
	_create_toggle_button()
	_create_debug_menu()
	_initialize_modules()
	
	for module in modules:
		module.post_setup()
	
	_set_debug_menu_open(false)

# --- Focus clearing --- #

func _input(event: InputEvent) -> void:
	# after any mouse click anywhere, release focus from UI controls.
	# this prevents buttons/spinboxes from consuming spacebar or other
	# game inputs after being clicked
	if event is InputEventMouseButton and event.pressed == false:
		_clear_ui_focus()

func _clear_ui_focus() -> void:
	# releasing focus from the current focused control is enough
	# the viewport will hold no focused control until the player clicks
	# a ui element again
	var focused := get_viewport().gui_get_focus_owner()
	if focused:
		focused.release_focus()

# --- ui --- #

func _create_toggle_button() -> void:
	var button_container := Control.new()
	button_container.name = "ToggleButtonContainer"
	button_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	button_container.position = (toggle_button_position - offset) / ui_scale
	button_container.scale = Vector2.ONE / ui_scale
	add_child(button_container)
	
	_toggle_button = Button.new()
	_toggle_button.name = "DebugToggleButton"
	_toggle_button.text = "Debug"
	_toggle_button.size = toggle_button_size
	_toggle_button.pressed.connect(_on_toggle_button_pressed)
	# Prevent the toggle button itself from holding focus
	_toggle_button.focus_mode = Control.FOCUS_NONE
	button_container.add_child(_toggle_button)

func _create_debug_menu() -> void:
	_menu_panel = Panel.new()
	_menu_panel.name = "DebugMenuPanel"
	_menu_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_menu_panel.position = Vector2(10, 50)
	add_child(_menu_panel)
	
	var vbox := VBoxContainer.new()
	vbox.name = "MenuVBox"
	vbox.position = Vector2(10, 10)
	_menu_panel.add_child(vbox)
	
	var title := Label.new()
	title.text = "Debug Menu"
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)
	
	var sep := HSeparator.new()
	vbox.add_child(sep)
	
	_menu_container = VBoxContainer.new()
	_menu_container.name = "ModuleToggles"
	vbox.add_child(_menu_container)
	
	_add_collision_toggle(vbox)
	_update_menu_size()

func _add_collision_toggle(parent: VBoxContainer) -> void:
	var sep := HSeparator.new()
	parent.add_child(sep)
	
	var collision_btn := CheckButton.new()
	collision_btn.text = "Show Collisions"
	collision_btn.button_pressed = get_tree().debug_collisions_hint
	collision_btn.focus_mode = Control.FOCUS_NONE
	collision_btn.toggled.connect(_on_collision_toggle)
	parent.add_child(collision_btn)

func _on_collision_toggle(enabled: bool) -> void:
	get_tree().debug_collisions_hint = enabled
	var console := get_console()
	if console:
		console.log_message("Collision shapes: %s" % ("ON" if enabled else "OFF"))

func _initialize_modules() -> void:
	for child in get_children():
		if child is DebugModule:
			_register_module(child)

func _register_module(module: DebugModule) -> void:
	module._init_module(self)
	module.setup()
	modules.append(module)
	
	var console := get_console()
	if console and module != console:
		module.log_requested.connect(console.log_message)
	
	if not module.hide_from_menu:
		_add_module_to_menu(module)
	
	module.set_module_visible(module.start_visible)

func _add_module_to_menu(module: DebugModule) -> void:
	var check_btn := CheckButton.new()
	check_btn.text = module.module_name
	check_btn.button_pressed = module.start_visible
	check_btn.focus_mode = Control.FOCUS_NONE
	check_btn.toggled.connect(func(pressed): _on_module_toggled(module, pressed))
	_menu_container.add_child(check_btn)
	_module_buttons[module] = check_btn
	_update_menu_size()

func _update_menu_size() -> void:
	await get_tree().process_frame
	var content_size = _menu_panel.get_child(0).get_combined_minimum_size()
	_menu_panel.size = content_size + Vector2(20, 20)

func _on_module_toggled(module: DebugModule, visible: bool) -> void:
	module.set_module_visible(visible)
	var console := get_console()
	if console:
		console.log_message("%s: %s" % [module.module_name, "ON" if visible else "OFF"])

func _on_toggle_button_pressed() -> void:
	_set_debug_menu_open(not _debug_menu_open)

func _set_debug_menu_open(is_open: bool) -> void:
	_debug_menu_open = is_open
	_menu_panel.visible = is_open
	_toggle_button.text = "Debug ▼" if is_open else "Debug ►"
	
	for module in modules:
		if not module.hide_from_menu:
			if is_open:
				var btn = _module_buttons.get(module)
				if btn:
					module.set_module_visible(btn.button_pressed)
			else:
				module.set_module_visible(false)
	
	debug_menu_toggled.emit(is_open)

func get_console() -> DebugConsole:
	for module in modules:
		if module is DebugConsole:
			return module
	return null

func get_player() -> CharacterBody2D:
	return player

func get_garden_manager() -> Garden_Manager:
	return garden_manager

func add_module(module: DebugModule) -> void:
	add_child(module)
	_register_module(module)
	module.post_setup()

func remove_module(module: DebugModule) -> void:
	module.cleanup()
	modules.erase(module)
	
	if module in _module_buttons:
		_module_buttons[module].queue_free()
		_module_buttons.erase(module)
		_update_menu_size()
	
	module.queue_free()

func is_debug_menu_open() -> bool:
	return _debug_menu_open

func set_debug_menu_open(is_open: bool) -> void:
	_set_debug_menu_open(is_open)
