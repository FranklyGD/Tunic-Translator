tool
extends Node

var translations

const base_scale = [
	16.35, # 0 C
	17.32, # 1
	18.35, # 2 D
	19.45, # 3
	20.60, # 4 E
	21.83, # 5 F
	23.12, # 6
	24.50, # 7 G
	25.96, # 8
	27.50, # 9 A
	29.14, # 10
	30.87, # 11 B
]

var main_writer
var file_dialog : FileDialog

signal data_updated

func _enter_tree() -> void:
	var file = File.new()
	file.open("res://translations.json", File.READ)
	var json = file.get_as_text()
	translations = parse_json(json)
	file.close()

func _ready():
	main_writer = get_node("/root/Translator/HSplitContainer/Control/VSplitContainer/Preview Panel/ScrollContainer/Trunic Writer")
	file_dialog = get_node("/root/Translator/FileDialog")

	main_writer.patterns = [
		[ # line
			[ # word
				[ # rune pattern
					false, false, false, true, true, false, true, false, true, true, true, false,
				],
				[false, false, false, false, false, true, true, false, true, true, false, false],
			],
			[
				[false, false, false, true, true, false, true, true, false, true, true, true],
			],
		],
		[
			[
				[false, false, false, false, false, true, false, true, false, true, false, false],
				[true, true, true, true, false, true, true, false, false, true, false, false],
				[false, false, false, true, true, false, false, true, true, false, true, false],
				[false, false, false, false, false, true, true, false, false, false, true, false],
			],
		],
	]

func get_translation(group: String, key: String, value) -> Dictionary:
	if value is Array:
		for entry in translations[group]:
			if entry.has(key):
				var found = true
				for i in min(len(entry[key]), len(value)):
					if not entry[key][i] == value[i]:
						found = false
						break
					
				if found:
					return entry
	else:
		for entry in translations[group]:
			if entry.has(key):
				if entry[key] is Array:
					if entry[key].has(value):
						return entry
				elif entry[key] == value:
					return entry
		
	return {}
