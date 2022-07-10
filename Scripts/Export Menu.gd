extends MenuButton

signal export_image
signal export_audio

func _ready() -> void:
	var pop_up: PopupMenu  = get_popup()
	pop_up.add_item("Trunic (Image)", 0)
	pop_up.add_item("Tuneic (Audio)", 1)
	
	pop_up.connect("id_pressed", self, "menu_item_selected")
	
func menu_item_selected(id: int) -> void:
	if id == 0:
		emit_signal("export_image")
	elif id == 1:
		emit_signal("export_audio")
