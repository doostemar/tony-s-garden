# debug_console.gd
class_name DebugConsole
extends DebugModule

var console: RichTextLabel
var panel: Panel
var console_lines: Array[String] = []

@export var max_lines: int = 20
@export var panel_size: Vector2 = Vector2(310, 250)
@export var panel_position: Vector2 = Vector2(200, 10)

func _init() -> void:
	module_name = "Console"
	start_visible = false

func setup() -> void:
	_create_console()
	# enable dragging on the panel
	_setup_drag(panel)

func post_setup() -> void:
	log_message("Debug Console initialized")

func _create_console() -> void:
	panel = Panel.new()
	panel.name = "ConsolePanel"
	panel.position = panel_position
	panel.size = panel_size
	add_child(panel)
	
	main_panel = panel
	
	var title := Label.new()
	title.text = "Debug Console"
	title.position = Vector2(10, 5)
	panel.add_child(title)
	
	console = RichTextLabel.new()
	console.name = "Console"
	console.position = Vector2(10, 25)
	console.size = Vector2(panel_size.x - 20, panel_size.y - 70)
	console.bbcode_enabled = true
	console.scroll_following = true
	# RichTextLabel should not steal mouse events meant for dragging the panel
	console.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(console)
	
	var clear_btn := Button.new()
	clear_btn.text = "Clear"
	clear_btn.position = Vector2(10, panel_size.y - 40)
	clear_btn.size = Vector2(80, 30)
	clear_btn.focus_mode = Control.FOCUS_NONE
	clear_btn.pressed.connect(clear_console)
	panel.add_child(clear_btn)

func log_message(msg: String) -> void:
	var timestamp := Time.get_time_string_from_system().substr(0, 8)
	var formatted_msg := "[%s] %s" % [timestamp, msg]
	console_lines.append(formatted_msg)
	
	if console_lines.size() > max_lines:
		console_lines.pop_front()
	
	if console:
		console.clear()
		console.append_text("\n".join(console_lines))

func clear_console() -> void:
	console_lines.clear()
	if console:
		console.clear()
	log_message("Console cleared")
