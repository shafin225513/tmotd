extends CanvasLayer

@onready var ammo_label: Label = $AmmoLabel

func update_status(text_info: String) -> void:
	if ammo_label:
		ammo_label.text = text_info
