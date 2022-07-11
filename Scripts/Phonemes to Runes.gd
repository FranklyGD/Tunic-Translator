extends Node

onready var text_edit_node = get_node("TextEdit")

func rebuild() -> void:
	var lines = Persistent.main_writer.patterns
	
	var line_pool = PoolStringArray()
	for line in lines:
		
		var word_pool = PoolStringArray()
		for word in line:
		
			var phoneme_pool = PoolStringArray()
			for rune in word:
				phoneme_pool.append(get_phonemes_from_pattern(rune))
			word_pool.append(phoneme_pool.join(" "))
		line_pool.append(word_pool.join("  "))
	text_edit_node.text = line_pool.join("\n")
	text_edit_node.update()

func get_phonemes_from_pattern(pattern: Array) -> String:
	var empty = true
	
	for s in 5:
		if pattern[s]:
			empty = false
			break
	
	var vowel_phoneme: String
	if not empty:
		var vowel_translation = Persistent.get_translation("vowels", "rune", pattern.slice(0, 4))
		if vowel_translation.empty():
			vowel_phoneme = "?"
		else:
			vowel_phoneme = vowel_translation.phoneme
		
	empty = true
	
	for s in 6:
		if pattern[5+s]:
			empty = false
			break
	
	var consonant_phoneme: String
	if not empty:
		var consonant_translation = Persistent.get_translation("consonants", "rune", pattern.slice(5, 10))
		if consonant_translation.empty():
			consonant_phoneme = "?"
		else:
			consonant_phoneme = consonant_translation.phoneme

	if consonant_phoneme or vowel_phoneme:
		if consonant_phoneme and vowel_phoneme:
			if pattern[11]:
				return vowel_phoneme + "'" + consonant_phoneme
			else:
				return consonant_phoneme + "'" + vowel_phoneme
		elif not vowel_phoneme:
			return consonant_phoneme
		elif not consonant_phoneme:
			return vowel_phoneme
	
	return ""

func _tab_changed(tab: int) -> void:
	if tab == get_index():
		rebuild()
