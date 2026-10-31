extends Control

@onready var dot: ColorRect = $Dot

const COLOR_DEFAULT := Color.WHITE
const COLOR_INTERACTABLE := Color.GREEN

func _ready() -> void:
	# 1. Completely disable UI mouse interaction
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if dot:
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 2. Keep this node tiny (6x6) and center it directly on screen
	custom_minimum_size = Vector2(6, 6)
	size = Vector2(6, 6)
	pivot_offset = Vector2(3, 3)
	
	# Position in exact center of viewport
	position = (get_viewport_rect().size / 2.0) - pivot_offset

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and dot:
		position = (get_viewport_rect().size / 2.0) - pivot_offset

func set_highlight(active: bool) -> void:
	if dot:
		dot.color = COLOR_INTERACTABLE if active else COLOR_DEFAULT
