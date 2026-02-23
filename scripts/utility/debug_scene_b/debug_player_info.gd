# debug_player_info.gd
class_name DebugPlayerInfo
extends DebugModule

var panel: Panel
var info_label: RichTextLabel
var player: CharacterBody2D
var player_context: Tony_Context

@export var panel_size: Vector2 = Vector2(250, 200)
@export var panel_position: Vector2 = Vector2(520, 10)
@export var update_interval: float = 0.1

var update_timer: float = 0.0

func _init() -> void:
	module_name = "Player Info"
	start_visible = false

func setup() -> void:
	player = debug_manager.get_player()
	
	if player == null:
		push_error("DebugPlayerInfo: No player available")
		return
	
	if player.has_node("Tony_Context"):
		player_context = player.get_node("Tony_Context")
	elif player.get("context") != null:
		player_context = player.context
	else:
		push_warning("DebugPlayerInfo: Could not find Tony_Context on player")
	
	_create_panel()
	_setup_drag(panel)

func post_setup() -> void:
	log_message("Player Info panel initialized")

func _create_panel() -> void:
	panel = Panel.new()
	panel.name = "PlayerInfoPanel"
	panel.position = panel_position
	panel.size = panel_size
	add_child(panel)
	
	main_panel = panel
	
	var title := Label.new()
	title.text = "Player Info"
	title.position = Vector2(10, 5)
	panel.add_child(title)
	
	info_label = RichTextLabel.new()
	info_label.name = "InfoLabel"
	info_label.position = Vector2(10, 30)
	info_label.size = Vector2(panel_size.x - 20, panel_size.y - 40)
	info_label.bbcode_enabled = true
	info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(info_label)

func _process(delta: float) -> void:
	if not panel or not panel.visible:
		return
	
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		_update_info()

func _update_info() -> void:
	if player == null:
		return
	
	var lines: Array[String] = []
	
	var pos := player.global_position
	lines.append("[color=yellow]Position:[/color] (%.1f, %.1f)" % [pos.x, pos.y])
	
	var vel := player.velocity
	var speed := vel.length()
	lines.append("[color=yellow]Velocity:[/color] (%.1f, %.1f)" % [vel.x, vel.y])
	lines.append("[color=yellow]Speed:[/color] %.2f" % speed)
	
	if player.has_method("get_speed"):
		lines.append("[color=yellow]Move Speed:[/color] %.2f" % player.get_speed())
	elif player.get("movement_speed") != null:
		lines.append("[color=yellow]Move Speed:[/color] %.2f" % player.movement_speed)
	
	if player_context:
		var dir_name := _direction_to_string(player_context.last_dir)
		lines.append("[color=cyan]Direction:[/color] %s" % dir_name)
		
		var moving_color := "green" if player_context.is_moving else "gray"
		lines.append("[color=cyan]Moving:[/color] [color=%s]%s[/color]" % [moving_color, player_context.is_moving])
		
		var carry_name := _carry_state_to_string(player_context.carry_state)
		var carry_color := "green" if player_context.carry_state != Tony_Context.CarryState.NONE else "gray"
		lines.append("[color=cyan]Carrying:[/color] [color=%s]%s[/color]" % [carry_color, carry_name])
		
		if player_context.item_in_hand_id != &"":
			lines.append("[color=cyan]Item ID:[/color] %s" % player_context.item_in_hand_id)
		
		if player_context.speed_mult != 1.0:
			lines.append("[color=cyan]Speed Mult:[/color] %.2f" % player_context.speed_mult)
	
	if player.has_method("is_on_floor"):
		var on_floor := player.is_on_floor()
		var floor_color := "green" if on_floor else "red"
		lines.append("[color=yellow]On Floor:[/color] [color=%s]%s[/color]" % [floor_color, on_floor])
	
	info_label.clear()
	info_label.append_text("\n".join(lines))

func _direction_to_string(dir: int) -> String:
	match dir:
		Tony_Context.Direction.UP:    return "UP"
		Tony_Context.Direction.DOWN:  return "DOWN"
		Tony_Context.Direction.LEFT:  return "LEFT"
		Tony_Context.Direction.RIGHT: return "RIGHT"
		_:                            return "UNKNOWN"

func _carry_state_to_string(state: int) -> String:
	match state:
		Tony_Context.CarryState.NONE:   return "Empty"
		Tony_Context.CarryState.RADISH: return "Radish"
		_:                              return "Unknown"
