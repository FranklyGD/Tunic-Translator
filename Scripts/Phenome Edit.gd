tool
extends TextEdit

var last_line_count = 0
var last_line = 0
var last_word_rune = {}

func _ready() -> void:
	connect("cursor_changed", self, "_cursor_changed")
	connect("text_changed", self, "_text_changed")
	
	for entry in Persistent.translations.vowels:
		add_keyword_color(entry.phoneme, Color.lightcoral)
		add_keyword_color(entry.phoneme.to_lower(), Color.lightcoral)
	for entry in Persistent.translations.consonants:
		add_keyword_color(entry.phoneme, Color.lightgreen)
		add_keyword_color(entry.phoneme.to_lower(), Color.lightgreen)
	
	update()
	
func _text_changed() -> void:
	# Get first rune
	var start_line
	var start_word
	var start_rune
	
	var end_line
	var end_word
	var end_rune
	
	var current_line = cursor_get_line()
	var current_column = cursor_get_column()
	
	var current_word_rune = get_wr(current_line, current_column)
	
	if get_line_count() < last_line_count: # Erased lines
		start_line = current_line
		start_word = current_word_rune.word
		start_rune = current_word_rune.rune
		
		end_line = get_line_count() - 1
		
	else:
		if current_line == last_line:
			start_line = current_line
			end_line = start_line
			
			if current_word_rune.word == last_word_rune.word:
				start_word = current_word_rune.word
				end_word = start_word
			
				if current_word_rune.rune > last_word_rune.rune:
					start_rune = last_word_rune.rune
					end_rune = current_word_rune.rune
				else:
					start_rune = current_word_rune.rune
					end_rune = last_word_rune.rune
			
			elif current_word_rune.word > last_word_rune.word:
				start_word = last_word_rune.word
				start_rune = last_word_rune.rune
				
				end_word = current_word_rune.word
				end_rune = current_word_rune.rune
			else:
				start_word = current_word_rune.word
				start_rune = current_word_rune.rune
				
				end_word = last_word_rune.word
				end_rune = last_word_rune.rune
			
		elif current_line > last_line:
			start_line = last_line
			start_word = last_word_rune.word
			start_rune = last_word_rune.rune
			
			end_line = current_line
			end_word = current_word_rune.word
			end_rune = current_word_rune.rune
		else:
			start_line = current_line
			start_word = current_word_rune.word
			start_rune = current_word_rune.rune
			
			end_line = last_line
			end_word = last_word_rune.word
			end_rune = last_word_rune.rune
	
	var line = start_line
	var word = start_word
	var rune = start_rune
	
	Persistent.main_writer.patterns.resize(get_line_count())
	
	while false and line <= end_line:

		var words = get_line(line).split("  ")
		if not Persistent.main_writer.patterns[line]:
			Persistent.main_writer.patterns[line] = []
		Persistent.main_writer.patterns[line].resize(len(words))
		
		while end_word != null and word <= end_word or (end_word == null or line != end_line) and word < len(words):
			
			var runes = words[word].split(" ")
			if not Persistent.main_writer.patterns[line][word]:
				Persistent.main_writer.patterns[line][word] = []
			Persistent.main_writer.patterns[line][word].resize(len(runes))
			
			while end_rune != null and rune <= end_rune or (end_rune == null or line != end_line and word != end_word) and rune < len(runes):
				
				Persistent.main_writer.patterns[line][word][rune] = get_pattern_from_phonemes(runes[rune])
		
				rune += 1
			
			rune = 0
			word += 1
		
		word = 0
		line += 1
	
	while line <= end_line:

		var words = get_line(line).split("  ")
		if not Persistent.main_writer.patterns[line]:
			Persistent.main_writer.patterns[line] = []
		Persistent.main_writer.patterns[line].resize(len(words))
		
		while word < len(words):
			
			var runes = words[word].split(" ")
			if not Persistent.main_writer.patterns[line][word]:
				Persistent.main_writer.patterns[line][word] = []
			Persistent.main_writer.patterns[line][word].resize(len(runes))
			
			while rune < len(runes):
				
				Persistent.main_writer.patterns[line][word][rune] = get_pattern_from_phonemes(runes[rune])
		
				rune += 1
			
			rune = 0
			word += 1
		
		word = 0
		line += 1
	
	Persistent.main_writer.update()
	Persistent.emit_signal("data_updated")
	last_line_count = get_line_count()
	
func _cursor_changed() -> void:
	last_line = cursor_get_line()
	last_word_rune = get_wr(last_line, cursor_get_column())

func get_wr(line: int, column: int) -> Dictionary:
	var substring = get_line(line).substr(0, column)
	
	var words = substring.split("  ")
	var word_idx = len(words) - 1
	
	var rune_idx = len(words[word_idx].split(" ")) - 1
	
	return {"word": word_idx, "rune": rune_idx}

func get_pattern_from_phonemes(phoneme_pair: String) -> Array:
	var pattern = [
		false, false, false, false, false,
		false, false, false, false, false, false,
		false
	]
		
	if not phoneme_pair.empty():
		# Split Text
		var phonemes = phoneme_pair.to_upper().split("'")
		
		# Find Correct Patterns
		var flipped = false
		
		var translation_c : Dictionary
		var translation_v : Dictionary
		
		translation_c = Persistent.get_translation("consonants", "phoneme", phonemes[0])
		if translation_c.empty():
			translation_c = Persistent.get_translation("consonants", "aliases", phonemes[0])
		
		if translation_c.empty():
			translation_v = Persistent.get_translation("vowels", "phoneme", phonemes[0])
			if translation_v.empty():
				translation_v = Persistent.get_translation("vowels", "aliases", phonemes[0])
			if len(phonemes) > 1:
				flipped = true
		elif len(phonemes) > 1:
			translation_v = Persistent.get_translation("vowels", "phoneme", phonemes[1])
			if translation_v.empty():
				translation_v = Persistent.get_translation("vowels", "aliases", phonemes[1])
			
		if flipped:
			translation_c = Persistent.get_translation("consonants", "phoneme", phonemes[1])
			if translation_c.empty():
				translation_c = Persistent.get_translation("consonants", "aliases", phonemes[1])
		
		# Set Rune Pattern
		if not translation_v.empty():
			for i in 5:
				pattern[i] = translation_v.rune[i]
				
		if not translation_c.empty():
			for i in 6:
				pattern[i+5] = translation_c.rune[i]

		pattern[11] = flipped
		
	return pattern
	
func update() -> void:
	last_line_count = get_line_count()
