extends Node

var line_scene = preload("res://Scenes/Line.tscn")
onready var line_instance: Node = line_scene.instance()

func add_line(idx: int = get_line_count(), update: bool = false) -> Node:
	var line = line_instance.duplicate()
	
	add_child(line, true)
	move_child(line, idx)
	
	if update:
		Persistent.main_writer.patterns.insert(idx, [])
	
	return line

func clear() -> void:
	for i in get_line_count():
		get_child(i).queue_free()

func get_line_count() -> int:
	return get_child_count() - 1

func _add_line_button_pressed() -> void:
	add_line(get_line_count(), true)
