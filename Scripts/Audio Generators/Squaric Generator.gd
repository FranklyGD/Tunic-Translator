extends AudioStreamPlayer
		
func generate(data: Dictionary):
	var notes: PoolIntArray = data.notes
	var nps: float = data.nps
	generate_sample(notes, nps)
	
func generate_sample(notes: PoolIntArray, nps: float = 12):
	var sample = AudioStreamSample.new()
	sample.format = AudioStreamSample.FORMAT_16_BITS
	sample.loop_mode = AudioStreamSample.LOOP_DISABLED
	sample.stereo = false
	sample.mix_rate = 44100
	
	var delta = nps / sample.mix_rate
		
	var phase_times = PoolRealArray()
	for i in 9:
		phase_times.append(0.0)
	var note_count = len(notes)
	
	var raw_values = PoolRealArray()
	var beat_time = 0.0
	while beat_time < note_count + 20:
		# Get frequency from note
		var note = notes[int(min(beat_time, note_count - 1))]
		var octave = note / 12 + 4
		note = note % 12
		var frequency = Persistent.base_scale[note] * pow(2, octave)
		
		if fmod(beat_time, 1) > 0.9:
			# Slide
			var note2 = notes[int(min(beat_time + 1, note_count - 1))]
			var octave2 = note2 / 12 + 4
			note2 = note2 % 12
			var frequency2 = Persistent.base_scale[note2] * pow(2, octave2)
			frequency = lerp(frequency, frequency2, (fmod(beat_time, 1)-0.9) / 0.1)
			
		# Write wave form value
		var value = 0.0
		
		var amp = 16.35 * pow(2, 4) / frequency
		if beat_time < note_count:
			amp *= 1
		else:
			amp *= 1 - (beat_time - note_count) * 0.05
		
		value += sinwave_gen(phase_times[0], amp)
		
		value += sinwave_gen(phase_times[1], amp * 0.0316)
		value += sinwave_gen(phase_times[2], amp * 0.0177)
		value += sinwave_gen(phase_times[3], amp * 0.01)
		value += sinwave_gen(phase_times[4], amp * 0.00562)
		
		value += sinwave_gen(phase_times[5], amp * 0.0316)
		value += sinwave_gen(phase_times[6], amp * 0.0177)
		value += sinwave_gen(phase_times[7], amp * 0.01)
		value += sinwave_gen(phase_times[8], amp * 0.00562)
		
		raw_values.append(value)
		
		# Advance Phase
		phase_times[0] = fmod(phase_times[0] + frequency / sample.mix_rate, 1.0)
		
		phase_times[1] = fmod(phase_times[1] + (frequency + 4800) / sample.mix_rate, 1.0)
		phase_times[2] = fmod(phase_times[2] + (frequency + 4800 * 2) / sample.mix_rate, 1.0)
		phase_times[3] = fmod(phase_times[3] + (frequency + 4800 * 3) / sample.mix_rate, 1.0)
		phase_times[4] = fmod(phase_times[4] + (frequency + 4800 * 4) / sample.mix_rate, 1.0)
		
		phase_times[5] = fmod(phase_times[5] + (4800 - frequency) / sample.mix_rate, 1.0)
		phase_times[6] = fmod(phase_times[6] + (4800 * 2 - frequency) / sample.mix_rate, 1.0)
		phase_times[7] = fmod(phase_times[7] + (4800 * 3 - frequency) / sample.mix_rate, 1.0)
		phase_times[8] = fmod(phase_times[8] + (4800 * 4 - frequency) / sample.mix_rate, 1.0)
		
		beat_time += delta
	
	# Major Echos
	var echo0_values = echo_filter(raw_values, 4, int(0.5 / delta), 0.5)
	var source_values = mix_in(echo0_values, raw_values, 0.5, 1)
	var echo1_values = echo_filter(source_values, 6, int(8 / delta), 0.4)
	raw_values = mix_in(echo1_values, source_values, 0.5, 1)
	
	# Compress
	var values = PoolByteArray()
	for raw_value in raw_values:
		var compressed = int(clamp(raw_value / 2, -0.5, 0.5) * 0xffff)
		values.append(compressed & 0xff)
		values.append(compressed >> 8 & 0xff)
	
	sample.data = values
	stream = sample

func sinwave_gen(phase: float, amplitude: float) -> float:
	return sin(phase * TAU) * amplitude

func echo_filter(values: PoolRealArray, count: int, delay: int, decay: float) -> PoolRealArray:
	var original_length = len(values)
	var delayed_values = PoolRealArray()
	delayed_values.resize(original_length + delay * count)
	
	for i in len(delayed_values):
		delayed_values[i] = 0
		
	for i in original_length:
		delayed_values[i + delay] = (delayed_values[i] + values[i]) * decay
		
	for i in len(delayed_values) - original_length - delay:
		delayed_values[i + original_length + delay] = delayed_values[i + original_length] * decay
	
	return delayed_values

func mix_in(values0: PoolRealArray, values1: PoolRealArray, gain0: float, gain1: float) -> PoolRealArray:
	var mixed_values = PoolRealArray()
	
	mixed_values.resize(len(values0))
	
	for i in len(values1):
		mixed_values[i] = values0[i] * gain0 + values1[i] * gain1
		
	for i in len(values0) - len(values1):
		mixed_values[i + len(values1)] = values0[i + len(values1)] * gain0
		
	return mixed_values
