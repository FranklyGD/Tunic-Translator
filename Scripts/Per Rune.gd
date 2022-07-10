extends Node

onready var lines_node = get_node("ScrollContainer/Lines")

func _ready() -> void:
	call_deferred("rebuild")

func rebuild() -> void:
	lines_node.clear()
	
	var lines = Persistent.main_writer.patterns
	
	for line in lines:
		var new_line = lines_node.add_line()
		
		for word in line:
			var new_word = new_line.add_word()
		
			for rune in word:
				var new_rune = new_word.add_rune()
				var rune_gen = new_rune.get_node("Rune Generator")
			
				var segments = rune.slice(0, 10)
				rune_gen.active_segments = segments
				rune_gen.flipped = rune[11]
				rune_gen.emit_signal("rune_edit", segments, rune[11])

func _tab_changed(tab: int) -> void:
	if tab == get_index():
		rebuild()
