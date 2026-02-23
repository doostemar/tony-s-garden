class_name GameHUD
extends CanvasLayer

@export var game_manager: GameManager

@onready var timer_label: Label = $MarginContainer/VBoxContainer/timer_label
@onready var quota_label: Label = $MarginContainer/VBoxContainer/quota_label
@onready var bonus_label: Label = $MarginContainer/VBoxContainer/bonus_label
@onready var day_label: Label = $MarginContainer/VBoxContainer/day_label

# --- lifecycle --- #
func _ready() -> void:
	_connect_signals()
	_initialize_display()

func _connect_signals() -> void:
	if not game_manager:
		push_error("GameHUD: game_manager not assigned!")
		return
	
	game_manager.time_updated.connect(_on_time_updated)
	game_manager.quota_updated.connect(_on_quota_updated)
	game_manager.bonus_updated.connect(_on_bonus_updated)
	game_manager.day_started.connect(_on_day_started)
	game_manager.day_ended.connect(_on_day_ended)

func _initialize_display() -> void:
	if timer_label:
		timer_label.text = "1:00"
	if quota_label:
		quota_label.text = "0 / 5"
	if bonus_label:
		bonus_label.text = "Bonus: 0"
	if day_label:
		day_label.text = "Day 1"

# --- signal --- #
func _on_time_updated(time_remaining: float) -> void:
	if not timer_label:
		return
	
	var total_seconds := int(ceil(max(time_remaining, 0)))
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]
	
	# visual feedback when time is low
	if total_seconds <= 10:
		timer_label.add_theme_color_override("font_color", Color.RED)
	elif total_seconds <= 30:
		timer_label.add_theme_color_override("font_color", Color.ORANGE)
	else:
		timer_label.remove_theme_color_override("font_color")

func _on_quota_updated(current: int, target: int) -> void:
	if not quota_label:
		return
	
	quota_label.text = "%d / %d" % [current, target]
	
	# visual feedback when quota is met
	if current >= target:
		quota_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		quota_label.remove_theme_color_override("font_color")

func _on_bonus_updated(total_bonus: int) -> void:
	if not bonus_label:
		return
	
	bonus_label.text = "Bonus: %d" % total_bonus

func _on_day_started(day_number: int) -> void:
	if day_label:
		day_label.text = "Day %d" % day_number
	
	# reset visual states
	if timer_label:
		timer_label.remove_theme_color_override("font_color")
	if quota_label:
		quota_label.remove_theme_color_override("font_color")

func _on_day_ended(success: bool, harvested: int, quota: int) -> void:
	# you could show a popup or transition screen here
	if success:
		print("GameHUD: Day complete! You harvested %d/%d radishes!" % [harvested, quota])
	else:
		print("GameHUD: Day failed. You only harvested %d/%d radishes." % [harvested, quota])
