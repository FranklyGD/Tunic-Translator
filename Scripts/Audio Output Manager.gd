extends Node

export(NodePath) var filedialog_path

var generator_index = 0
var generator_thread : Thread
var semitone = 0 setget set_semitone
var nps = 12 setget set_nps

var changed = true
var will_play = -1
var currently_playing = -1

signal audio_played
signal audio_finished

func _ready() -> void:
	Persistent.connect("data_updated", self, "on_lines_changed")

func _process(_delta: float) -> void:
	if will_play != -1:
		if generator_thread and not generator_thread.is_alive():
			generator_thread.wait_to_finish()
			generator_thread = null
		
		if not generator_thread:
			if currently_playing != -1:
				get_child(currently_playing).stop()

			var audio_player: AudioStreamPlayer = get_child(will_play)
			audio_player.play()
			
			emit_signal("audio_played")
			if not audio_player.is_connected("finished", self, "finished"):
				audio_player.connect("finished", self, "finished")
			
			currently_playing = will_play
			will_play = -1

func finished() -> void:
	var audio_player: AudioStreamPlayer = get_child(currently_playing)
	audio_player.disconnect("finished", self, "finished")

	currently_playing = -1
	emit_signal("audio_finished")

func play() -> void:
	if will_play != -1:
		return
		
	if changed:
		generate()
	will_play = generator_index
		
func generate() -> void:
	var notes = build_notes()
	
	generator_thread = Thread.new()
	generator_thread.start(get_child(generator_index), "generate", {"notes": notes, "nps": nps})
	
	changed = false

func save_audio() -> void:
	var file_dialog = Persistent.file_dialog
	file_dialog.filters = ["*.wav ; Audio file"]
	file_dialog.connect("file_selected", self, "_export_audio_dialog_file_selected")
	file_dialog.connect("popup_hide", self, "file_dialog_close")
	file_dialog.popup_centered()

func file_dialog_close() -> void:
	var file_dialog = Persistent.file_dialog
	file_dialog.disconnect("file_selected", self, "_export_audio_dialog_file_selected")
	file_dialog.disconnect("popup_hide", self, "file_dialog_close")
	
func _export_audio_dialog_file_selected(path: String) -> void:
	if changed:
		generate()
	var stream: AudioStreamSample = get_child(generator_index).stream
	stream.save_to_wav(path)

func build_notes() -> PoolIntArray:
	var notes = PoolIntArray()
	var base_tone = semitone
	
	for line in Persistent.main_writer.patterns:
		for word in line:
			for rune in word:
				for tone in build_from_pattern(rune):
					notes.append(base_tone + tone)
			
			
			base_tone += 1
	
	return notes

func build_from_pattern(pattern: Array) -> Array:
	var tune = PoolIntArray([0]) # Base line
	var empty = true
	
	for s in 5:
		if pattern[s]:
			empty = false
			break
	
	var vowel_tune: PoolIntArray
	if not empty:
		var vowel_translation = Persistent.get_translation("vowels", "rune", pattern.slice(0, 4))
		if vowel_translation.empty():
			vowel_tune = []
		else:
			vowel_tune = vowel_translation.tune
		
	empty = true
	
	for s in 6:
		if pattern[5+s]:
			empty = false
			break
	
	var consonant_tune: PoolIntArray
	if not empty:
		var consonant_translation = Persistent.get_translation("consonants", "rune", pattern.slice(5, 10))
		if consonant_translation.empty():
			consonant_tune = []
		else:
			consonant_tune = consonant_translation.tune

	tune.append_array(consonant_tune)
	tune.append_array(vowel_tune)
	
	if pattern[11]:
		var reverse_tune = PoolIntArray()
		reverse_tune.resize(len(tune))
		
		for ii in len(tune):
			reverse_tune[ii] = tune[len(tune) - 1 - ii]
		return reverse_tune
		
	return tune

func _generator_index_item_selected(value: int) -> void:
	generator_index = value
	changed = true

func set_semitone(value: int) -> void:
	semitone = value
	changed = true

func set_nps(value: int) -> void:
	nps = value
	changed = true

func on_lines_changed() -> void:
	changed = true
