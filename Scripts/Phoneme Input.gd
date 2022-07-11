extends LineEdit

func _ready() -> void:
	connect("text_changed", self, "text_changed")

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed:
			var rune = owner
	
			if event.scancode == KEY_BACKSPACE:
				if caret_position == 0: # At start
					var current_index = rune.get_index()
					var word = rune.get_parent()
					if current_index > 1: # Not first rune
						var previous_rune = word.get_child(current_index - 1)
						
						var input: LineEdit = previous_rune.get_node("Input Center/Phoneme Input")

						var original_position = len(input.text)
						input.text += text
						input.caret_position = original_position
						input.grab_focus()
						input.emit_signal("text_changed", input.text)
						
						rune.erase() # Delete rune
						
					else:
						var word_index = word.get_index()
						var line = word.get_parent()
						if word_index > 0: # Not first word
							var previous_word = line.get_child(word_index - 1)
							var last_rune = previous_word.get_child(previous_word.get_child_count() - 3)
							
							var input: LineEdit = last_rune.get_node("Input Center/Phoneme Input")
							
							var original_position = len(input.text)
							input.text += text
							input.caret_position = original_position
							input.grab_focus()
							input.emit_signal("text_changed", input.text)
								
							if word.get_rune_count() > 1:
								rune.erase() # Delete rune
							else:
								word.erase() # Delete word
						
						else:
							
							var line_index = line.get_index()
							if line_index > 0: # Not first word
								var lines = line.get_parent()
								var previous_line = lines.get_child(line_index - 1)
								var last_word = previous_line.get_child(previous_line.get_child_count() - 2)
								var last_rune = last_word.get_child(last_word.get_child_count() - 3)
								
								var input: LineEdit = last_rune.get_node("Input Center/Phoneme Input")
								
								var original_position = len(input.text)
								input.text += text
								input.caret_position = original_position
								input.grab_focus()
								input.emit_signal("text_changed", input.text)
								
								if word.get_rune_count() > 1:
									rune.erase() # Delete rune
								elif line.get_word_count() > 1:
									word.erase() # Delete word
								else:
									line.erase() # Delete line
								
			if event.scancode == KEY_LEFT:
				if caret_position == 0: # At start
					var current_index = rune.get_index()
					var word = rune.get_parent()
					if current_index > 1:
						var previous_rune = word.get_child(current_index - 1)
						
						var input: LineEdit = previous_rune.get_node("Input Center/Phoneme Input")
						input.caret_position = len(input.text)
						input.grab_focus()
						
					else:
						var word_index = word.get_index()
						if word_index > 0:
							var line = word.get_parent()
							var previous_word = line.get_child(word_index - 1)
							var last_rune = previous_word.get_child(previous_word.get_child_count() - 3)
							
							var input: LineEdit = last_rune.get_node("Input Center/Phoneme Input")
							input.caret_position = len(input.text)
							input.grab_focus()
			
			if event.scancode == KEY_RIGHT:
				if caret_position == len(text): # At end
					var current_index = rune.get_index()
					var word = rune.get_parent()
					if current_index < rune.get_parent().get_rune_count():
						var next_rune = word.get_child(current_index + 1)
						
						var input: LineEdit = next_rune.get_node("Input Center/Phoneme Input")
						input.caret_position = 0
						input.grab_focus()
						
					else:
						var word_index = word.get_index()
						if word_index < word.get_parent().get_child_count() - 2:
							var line = word.get_parent()
							var next_word = line.get_child(word_index + 1)
							var first_rune = next_word.get_child(1)
							
							var input: LineEdit = first_rune.get_node("Input Center/Phoneme Input")
							input.caret_position = 0
							input.grab_focus()

func rune_edit(pattern: Array, flipped: bool) -> void:
	build_from_segments(pattern, flipped)
	
func build_from_segments(segments: Array, flipped: bool) -> void:
	var empty = true
	
	for s in 5:
		if segments[s]:
			empty = false
			break
	
	var vowel_phoneme: String
	if not empty:
		var vowel_translation = Persistent.get_translation("vowels", "rune", segments.slice(0, 4))
		if vowel_translation.empty():
			vowel_phoneme = "?"
		else:
			vowel_phoneme = vowel_translation.phoneme
		
	empty = true
	
	for s in 6:
		if segments[5+s]:
			empty = false
			break
	
	var consonant_phoneme: String
	if not empty:
		var consonant_translation = Persistent.get_translation("consonants", "rune", segments.slice(5, 10))
		if consonant_translation.empty():
			consonant_phoneme = "?"
		else:
			consonant_phoneme = consonant_translation.phoneme

	if not consonant_phoneme and not vowel_phoneme:
		text = ""
	elif consonant_phoneme and vowel_phoneme:
		if flipped:
			text = vowel_phoneme + "'" + consonant_phoneme
		else:
			text = consonant_phoneme + "'" + vowel_phoneme
	elif not vowel_phoneme:
		text = consonant_phoneme
	elif not consonant_phoneme:
		text = vowel_phoneme

func text_changed(new_text: String) -> void:
	var rune = owner
	var rune_pattern: Node = rune.get_node("Rune Generator")
	
	if new_text.empty():
		rune_pattern.active_segments = [
			false, false, false, false, false,
			false, false, false, false, false, false
		]
		rune_pattern.flipped = false
		
		var rune_index = rune.get_rune_index()
		var word = rune.get_parent()
		var word_index = word.get_word_index()
		var line = word.get_parent()
		var line_index = line.get_line_index()
		
		var pattern = rune_pattern.active_segments.duplicate()
		pattern.append(rune_pattern.flipped)
		Persistent.main_writer.patterns[line_index][word_index][rune_index] = pattern
		Persistent.main_writer.update()
	else:
		new_text = new_text.to_upper()
		
		# Split Text
		var phoneme_pairs = new_text.split(" ", true, 1)
		var phonemes = phoneme_pairs[0].split("'")
		
		var current_position = caret_position
		
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
		if translation_v.empty():
			for i in 5:
				rune_pattern.active_segments[i] = false
		else:
			for i in 5:
				rune_pattern.active_segments[i] = translation_v.rune[i]
				
		if translation_c.empty():
			for i in 6:
				rune_pattern.active_segments[i+5] = false
		else:
			for i in 6:
				rune_pattern.active_segments[i+5] = translation_c.rune[i]
			
		rune_pattern.flipped = flipped
		
		var rune_index = rune.get_rune_index()
		var word = rune.get_parent()
		var word_index = word.get_word_index()
		var line = word.get_parent()
		var line_index = line.get_line_index()
		
		var pattern = rune_pattern.active_segments.duplicate()
		pattern.append(rune_pattern.flipped)
		Persistent.main_writer.patterns[line_index][word_index][rune_index] = pattern
		Persistent.main_writer.update()
		Persistent.emit_signal("data_updated")

		# Carry
		if len(phoneme_pairs) > 1:
			text = phoneme_pairs[0]

			if word.get_rune_count() > 1 and phoneme_pairs[0].empty(): # Move current rune into a new word
				var new_word = line.add_word(word_index + 1, true) # Add new word entry

				var child_index = rune.get_index()
				for i in word.get_rune_count() - rune_index:
					var child = word.get_child(child_index)
					
					word.remove_child(child)
					new_word.add_child(child)
					new_word.move_child(child, new_word.get_child_count() - 3)

					var transfer_rune = Persistent.main_writer.patterns[line_index][word_index].pop_at(rune_index)
					Persistent.main_writer.patterns[line_index][word_index + 1].append(transfer_rune)
					Persistent.emit_signal("data_updated")

			else:
				rune = rune.get_parent().add_rune(rune.get_rune_index() + 1, true)
				
			var input: LineEdit = rune.get_node("Input Center/Phoneme Input")
			
			input.text = phoneme_pairs[1]
			input.caret_position = current_position - len(phoneme_pairs[0]) - 1
			input.grab_focus()
			input.emit_signal("text_changed", phoneme_pairs[1])
