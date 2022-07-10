extends Control

var rune_scene = preload("res://Scenes/Rune.tscn")
onready var rune_instance: Node = rune_scene.instance()

func add_rune(idx: int = get_rune_count(), update: bool = false) -> Node:
	var rune = rune_instance.duplicate()
	
	add_child(rune, true)
	move_child(rune, idx + 1)
	
	rune.get_node("Rune Generator").active_segments = [
		false, false, false, false, false,
		false, false, false, false, false, false
	]
	rune.get_node("Input Center/Phenome Input").text = ""
	
	if update:
		Persistent.main_writer.patterns[get_parent().get_line_index()][get_word_index()].insert(idx, [
			false, false, false, false, false,
			false, false, false, false, false, false,
			false
		])
		Persistent.main_writer.update()
		Persistent.emit_signal("data_updated")
	
	return rune

func erase() -> void:
	var word_index = get_word_index()
	var line = get_parent()
	var line_index = line.get_line_index()
	
	Persistent.main_writer.patterns[line_index].remove(word_index)
	queue_free()

func get_rune_count() -> int:
	return get_child_count() - 3
	
func get_word_index() -> int:
	return get_index()

func _add_rune_button_pressed():
	add_rune(get_rune_count(), true)
