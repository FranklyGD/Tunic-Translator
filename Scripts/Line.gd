extends Node

var word_scene = preload("res://Scenes/Word.tscn")
onready var word_instance: Node = word_scene.instance()

func add_word(idx: int = get_word_count(), update: bool = false) -> Node:
	var word = word_instance.duplicate()
	
	add_child(word, true)
	move_child(word, idx)
	
	if update:
		Persistent.main_writer.patterns[get_line_index()].insert(idx, [])
		
	return word

func erase() -> void:
	Persistent.main_writer.patterns.remove(get_line_index())
	queue_free()
	
func get_word_count() -> int:
	return get_child_count() - 1
	
func get_line_index() -> int:
	return get_index()

func _add_word_button_pressed() -> void:
	add_word(get_word_count(), true)
