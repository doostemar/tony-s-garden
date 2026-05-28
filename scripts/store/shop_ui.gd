# shop_ui.gd
class_name ShopUI
extends CanvasLayer

@export var game_manager: GameManager
@export var tony: CharacterBody2D
@export var debug_manager: DebugManager

# order : m t p s
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
var _radish_label: Label
var _item_rows: Dictionary = {} # StatType -> { button, buff }
var buff_manager: Buff_Manager

func _ready() -> void:
	layer = 10
	_build_ui()
	visible = false

	if game_manager:
		game_manager.day_ended.connect(_on_day_ended)
		game_manager.bonus_updated.connect(_on_bonus_updated)
		
	if tony:
		buff_manager = tony.get_buff_manager()

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

	var title := Label.new()
	title.text = "Shop"
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	_radish_label = Label.new()
	_radish_label.text = "Radishes: 0"
	vbox.add_child(_radish_label)

	vbox.add_child(HSeparator.new())

	for stat_type in ITEM_ORDER:
		var row := HBoxContainer.new()
		vbox.add_child(row)

		# blank sprite placeholder
		var icon := ColorRect.new()
		icon.color = Color(0.3, 0.3, 0.3, 1.0)
		icon.custom_minimum_size = Vector2(32, 32)
		row.add_child(icon)

		var btn := Button.new()
		btn.text = "%s  (1 radish)" % ITEM_NAMES[stat_type]
		btn.custom_minimum_size = Vector2(280, 36)
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_on_item_pressed.bind(stat_type))
		row.add_child(btn)

		_item_rows[stat_type] = { "button": btn }

	vbox.add_child(HSeparator.new())

	var continue_btn := Button.new()
	continue_btn.text = "Continue to Next Day"
	continue_btn.focus_mode = Control.FOCUS_NONE
	continue_btn.pressed.connect(_on_continue_pressed)
	vbox.add_child(continue_btn)

# --- open/close ---

func _on_day_ended(success: bool, _harvested: int, _quota: int) -> void:
	if not success:
		return
	if game_manager.get_bonus_radishes() <= 0:
		return
	_open_shop()

func _open_shop() -> void:
	# resolve buff defs from the buff manager's pool by stat type
	for stat_type in ITEM_ORDER:
		_item_rows[stat_type]["buff"] = _find_buff_for_stat(stat_type)

	_refresh()
	visible = true

	if debug_manager:
		debug_manager.set_suspended(true)

func _close_shop() -> void:
	visible = false
	if debug_manager:
		debug_manager.set_suspended(false)

func _on_continue_pressed() -> void:
	_close_shop()
	if game_manager and game_manager.is_awaiting_continue():
		game_manager._confirm_continue()

# --- purchase ---

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

# --- refresh / helpers ---

func _on_bonus_updated(_total: int) -> void:
	if visible:
		_refresh()

func _refresh() -> void:
	var radishes := game_manager.get_bonus_radishes()
	_radish_label.text = "Radishes: %d" % radishes

	for stat_type in ITEM_ORDER:
		var data: Dictionary = _item_rows[stat_type]
		var btn: Button = data["button"]
		var buff: Buff_Definition = data.get("buff")

		var at_max := false
		var label = ITEM_NAMES[stat_type]

		if buff == null:
			btn.disabled = true
			btn.text = "%s (unavailable)" % label
			continue

		var current_tier := buff_manager.get_buff_tier(buff.buff_id)
		at_max = current_tier >= buff.max_tier

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
