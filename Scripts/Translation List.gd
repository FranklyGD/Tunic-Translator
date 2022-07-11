tool
extends GridContainer

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		request_ready()

func _ready() -> void:
	add_constant_override("hseparation", 15)

	for child in get_children():
		child.queue_free()
	
	var label

	label = Label.new()
	label.text = "Phoneme"
	add_child(label)
	
	label = Label.new()
	label.text = "Examples"
	add_child(label)
	
	label = Label.new()
	label.text = "Rune"
	add_child(label)
	
	label = Label.new()
	label.text = "Tune (Relative Octave-Semitones)"
	add_child(label)

	for i in 4:
		add_child(HSeparator.new())
	
	for entry in Persistent.translations.vowels:
		add_row(entry)
	
	for i in 4:
		add_child(HSeparator.new())

	for entry in Persistent.translations.consonants:
		add_row(entry)

func add_row(entry: Dictionary) -> void:
	var label

	label = Label.new()
	label.text = entry.phoneme
	if entry.has("aliases"):
		label.text += " (%s)" % PoolStringArray(entry.aliases).join(", ")
	add_child(label)

	label = Label.new()
	label.text = PoolStringArray(entry.examples).join(", ")
	add_child(label)

	var trunic = preload("res://Scripts/Trunic.gd").new()

	var rune = [false, false, false, false, false, false, false, false, false, false, false, false]
	
	if len(entry.rune) > 5:
		for i in 6:
			rune[i+5] = entry.rune[i]
	else:
		for i in 5:
			rune[i] = entry.rune[i]

	trunic.patterns = [[[rune]]]

	trunic.radius = 10
	trunic.height = 10
	trunic.thickness = 2

	var center = CenterContainer.new()
	center.add_child(trunic)

	add_child(center)
	
	label = Label.new()
	label.text = ""
	for t in entry.tune:
		label.text += "%d-%d " % [int(t) / 12, int(t) % 12]
	add_child(label)
