extends Node

onready var text_edit_node = get_node("TextEdit")

func rebuild() -> void:
	var lines = Persistent.main_writer.patterns
	
	var line_pool = PoolStringArray()
	for line in lines:
		
		var word_pool = PoolStringArray()
		for word in line:
		
			var phenome_pool = PoolStringArray()
			for rune in word:
				phenome_pool.append(get_phenomes_from_pattern(rune))
			word_pool.append(phenome_pool.join(" "))
		line_pool.append(word_pool.join("  "))
	text_edit_node.text = line_pool.join("\n")
	text_edit_node.update()

func get_phenomes_from_pattern(pattern: Array) -> String:
	var empty = true
	
	for s in 5:
		if pattern[s]:
			empty = false
			break
	
	var vowel_phenome: String
	if not empty:
		var vowel_translation = Persistent.get_translation("vowels", "rune", pattern.slice(0, 4))
		if vowel_translation.empty():
			vowel_phenome = "?"
		else:
			vowel_phenome = vowel_translation.phenome
		
	empty = true
	
	for s in 6:
		if pattern[5+s]:
			empty = false
			break
	
	var consonant_phenome: String
	if not empty:
		var consonant_translation = Persistent.get_translation("consonants", "rune", pattern.slice(5, 10))
		if consonant_translation.empty():
			consonant_phenome = "?"
		else:
			consonant_phenome = consonant_translation.phenome

	if consonant_phenome or vowel_phenome:
		if consonant_phenome and vowel_phenome:
			if pattern[11]:
				return vowel_phenome + "'" + consonant_phenome
			else:
				return consonant_phenome + "'" + vowel_phenome
		elif not vowel_phenome:
			return consonant_phenome
		elif not consonant_phenome:
			return vowel_phenome
	
	return ""

func _tab_changed(tab: int) -> void:
	if tab == get_index():
		rebuild()
