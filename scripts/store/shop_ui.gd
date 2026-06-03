#shop_ui.gd
class_name ShopUI
extends CanvasLayer

@export var game_manager: GameManager
@export var tony: CharacterBody2D

const ITEM_NAMES := {
	Buff_Definition.StatType.MOVE_SPEED: "Coffee",
	Buff_Definition.StatType.THROW_SPEED: "Baseball glove",
	Buff_Definition.StatType.PLANT_RADIUS: "Big seed bag",
	Buff_Definition.StatType.SHOUT_RADIUS: "Whistle",
}
const ITEM_ORDER := [
	Buff_Definition.StatType.MOVE_SPEED,
	Buff_Definition.StatType.THROW_SPEED,
	Buff_Definition.StatType.PLANT_RADIUS,
	Buff_Definition.StatType.SHOUT_RADIUS,
]
const ITEM_COST := 1

var _panel: Panel
var _title_label: Label
var _radish_label: Label
var _no_radish_label: Label
var _shop_content: VBoxContainer
var _continue_btn: Button
var _item_rows: Dictionary = {}  # StatType -> { button, row, buff }
var buff_manager: Buff_Manager

# tracks whether the shop was opened with zero radishes so we show the
# simplified "no radishes" layout for the entire session (even if a debug
# command adds radishes mid-shop, the layout stays consistent)
var _opened_with_no_radishes: bool = false

# --- keyboard navigation ---
var _focusable_buttons: Array[Button] = []
var _focus_index: int = 0

func _ready() -> void:
	layer = 10
	# keep shop responsive while the tree is paused (day-end freeze)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false

	if game_manager:
		game_manager.day_ended.connect(_on_day_ended)
		game_manager.bonus_updated.connect(_on_bonus_updated)
		game_manager.day_started.connect(_on_day_started)

	if tony:
		buff_manager = tony.get_buff_manager()

# ── input ────────────────────────────────────────────────────────────────
# W / S  = navigate focus        space = activate focused button
# A / D / enter are consumed so they don't leak to other systems
# mouse events are ignored via mouse_filter on all child control nodes

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_W:
				_move_focus(-1)
				get_viewport().set_input_as_handled()
			KEY_S:
				_move_focus(1)
				get_viewport().set_input_as_handled()
			KEY_A, KEY_D:
				# consume so WASD doesn't leak while shop is open
				get_viewport().set_input_as_handled()
			KEY_SPACE:
				_activate_focused()
				get_viewport().set_input_as_handled()
			KEY_ENTER, KEY_KP_ENTER:
				# block Enter from reaching GameManager's _unhandled_input
				get_viewport().set_input_as_handled()

# ── ui construction ──────────────────────────────────────────────────────

func _build_ui() -> void:
	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.position = Vector2(-200, -180)
	_panel.size = Vector2(400, 360)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(15, 15)
	vbox.custom_minimum_size = Vector2(370, 330)
	_panel.add_child(vbox)

	_title_label = Label.new()
	_title_label.text = "Shop"
	_title_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(_title_label)

	_radish_label = Label.new()
	_radish_label.text = "Radishes: 0"
	vbox.add_child(_radish_label)

	_no_radish_label = Label.new()
	_no_radish_label.text = "You have no extra radishes to trade."
	_no_radish_label.add_theme_font_size_override("font_size", 16)
	_no_radish_label.visible = false
	vbox.add_child(_no_radish_label)

	# item rows live inside _shop_content so they can be hidden as a group
	_shop_content = VBoxContainer.new()
	vbox.add_child(_shop_content)

	for stat_type in ITEM_ORDER:
		var row := HBoxContainer.new()
		_shop_content.add_child(row)

		# placeholder sprite
		var icon := ColorRect.new()
		icon.color = Color(0.3, 0.3, 0.3, 1.0)
		icon.custom_minimum_size = Vector2(32, 32)
		row.add_child(icon)

		var btn := Button.new()
		btn.text = "%s  (1 radish)" % ITEM_NAMES[stat_type]
		btn.custom_minimum_size = Vector2(280, 36)
		btn.focus_mode = Control.FOCUS_ALL
		btn.pressed.connect(_on_item_pressed.bind(stat_type))
		row.add_child(btn)

		_item_rows[stat_type] = { "button": btn, "row": row }

	vbox.add_child(HSeparator.new())

	_continue_btn = Button.new()
	_continue_btn.text = "Continue to Next Day"
	_continue_btn.focus_mode = Control.FOCUS_ALL
	_continue_btn.pressed.connect(_on_continue_pressed)
	vbox.add_child(_continue_btn)

	# disable all mouse interaction – shop is keyboard-only
	_set_mouse_filter_recursive(_panel, Control.MOUSE_FILTER_IGNORE)

# recursively sets mouse_filter on every Control descendant
func _set_mouse_filter_recursive(node: Node, filter: Control.MouseFilter) -> void:
	if node is Control:
		node.mouse_filter = filter
	for child in node.get_children():
		_set_mouse_filter_recursive(child, filter)

# ── keyboard focus helpers ───────────────────────────────────────────────

# rebuilds the list of buttons the player can navigate to and grabs focus.
func _rebuild_focusable_list() -> void:
	_focusable_buttons.clear()
	if _shop_content.visible:
		for stat_type in ITEM_ORDER:
			var btn: Button = _item_rows[stat_type]["button"]
			if btn.visible:
				_focusable_buttons.append(btn)
	_focusable_buttons.append(_continue_btn)
	_focus_index = clampi(_focus_index, 0, _focusable_buttons.size() - 1)
	_apply_focus()

func _move_focus(direction: int) -> void:
	if _focusable_buttons.is_empty():
		return
	_focus_index = wrapi(_focus_index + direction, 0, _focusable_buttons.size())
	_apply_focus()

func _apply_focus() -> void:
	if _focusable_buttons.is_empty():
		return
	_focus_index = clampi(_focus_index, 0, _focusable_buttons.size() - 1)
	_focusable_buttons[_focus_index].grab_focus()

func _activate_focused() -> void:
	if _focusable_buttons.is_empty():
		return
	var btn := _focusable_buttons[_focus_index]
	if not btn.disabled:
		btn.emit_signal("pressed")

# ── open / close ─────────────────────────────────────────────────────────

func _on_day_ended(success: bool, _harvested: int, _quota: int) -> void:
	if not success:
		return
	# shop always opens on a successful day, even with 0 bonus radishes
	_open_shop()

func _on_day_started(_day_number: int) -> void:
	# ensure shop closes if a debug command starts a new day while it's open
	_close_shop()

func _open_shop() -> void:
	_opened_with_no_radishes = game_manager.get_bonus_radishes() <= 0

	if not _opened_with_no_radishes:
		for stat_type in ITEM_ORDER:
			_item_rows[stat_type]["buff"] = _find_buff_for_stat(stat_type)

	_refresh()
	visible = true
	_focus_index = 0
	_rebuild_focusable_list()

func _close_shop() -> void:
	visible = false

func _on_continue_pressed() -> void:
	_close_shop()
	if game_manager and game_manager.is_awaiting_continue():
		game_manager._confirm_continue()

# ── purchase ─────────────────────────────────────────────────────────────

func _on_item_pressed(stat_type: int) -> void:
	var data: Dictionary = _item_rows[stat_type]
	var buff: Buff_Definition = data.get("buff")
	if buff == null:
		return
	if game_manager.get_bonus_radishes() < ITEM_COST:
		return
	if buff_manager.get_buff_tier(buff.buff_id) >= buff.max_tier:
		return

	if not game_manager.spend_bonus_radishes(ITEM_COST):
		return
	buff_manager.apply_buff(buff, &"shop")
	_refresh()
	_rebuild_focusable_list()

# ── refresh / helpers ────────────────────────────────────────────────────

func _on_bonus_updated(_total: int) -> void:
	if visible:
		_refresh()
		_rebuild_focusable_list()

func _refresh() -> void:
	# --- no-radish layout ---
	if _opened_with_no_radishes:
		_title_label.text = ""
		_radish_label.visible = false
		_no_radish_label.visible = true
		_shop_content.visible = false
		return

	# --- normal shop layout ---
	_title_label.text = "Shop"
	_radish_label.visible = true
	_no_radish_label.visible = false
	_shop_content.visible = true

	var radishes := game_manager.get_bonus_radishes()
	_radish_label.text = "Radishes: %d" % radishes

	for stat_type in ITEM_ORDER:
		var data: Dictionary = _item_rows[stat_type]
		var btn: Button = data["button"]
		var buff: Buff_Definition = data.get("buff")
		var label = ITEM_NAMES[stat_type]

		if buff == null:
			btn.disabled = true
			btn.text = "%s (unavailable)" % label
			continue

		var current_tier := buff_manager.get_buff_tier(buff.buff_id)
		var at_max := current_tier >= buff.max_tier

		if at_max:
			btn.visible = false
		else:
			btn.visible = true
			btn.disabled = radishes < ITEM_COST
			btn.text = "%s  (1 radish)  [tier %d/%d]" % [label, current_tier, buff.max_tier]

func _find_buff_for_stat(stat_type: int) -> Buff_Definition:
	for buff in buff_manager.radish_buff_pool:
		if buff and buff.stat_type == stat_type:
			return buff
	return null
