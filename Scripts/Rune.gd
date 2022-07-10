extends Control

func _ready():
	connect("mouse_entered", self, "on_mouse_enter")

func on_mouse_enter() -> void:
	for child in get_parent().get_children():
		child.show_behind_parent = true
	
	show_behind_parent = false

func update_pattern(pattern: Array) -> void:
	var rune_index = get_index() - 1
	var word = get_parent()
	var word_index = word.get_word_index()
	var line = word.get_parent()
	var line_index = line.get_line_index()
	
	Persistent.main_writer.patterns[line_index][word_index][rune_index] = pattern

func erase() -> void:
	var rune_index = get_index() - 1
	var word = get_parent()
	var word_index = word.get_word_index()
	var line = word.get_parent()
	var line_index = line.get_line_index()
	
	Persistent.main_writer.patterns[line_index][word_index].remove(rune_index)
	queue_free()

func get_rune_index() -> int:
	return get_index() - 1
