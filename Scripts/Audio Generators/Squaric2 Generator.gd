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
	sample.mix_rate = 48000
	
	var delta = nps / sample.mix_rate
		
	var phase_time = 0.0
	var note_count = len(notes)
	
	var raw_values = PoolRealArray()
	var beat_time = 0.0
	while beat_time < len(notes) + 5:
		# Get frequency from note
		var note = notes[int(min(beat_time, note_count - 1))]
		var octave = note / 12 + 4
		note = note % 12
		var frequency = Persistent.base_scale[note] * pow(2, octave)
		
		# Write wave form value
		var value = 0.0
		
		var note_time: float
		if beat_time < note_count:
			note_time = fmod(beat_time, 1)
		else:
			note_time = beat_time - note_count
		
		var amp = 1 - note_time * 0.15
		
		for i in range(1, 20000 / frequency + 2, 2):
			value += sinwave_gen(phase_time * i, sinwave_gen(note_time * max(i * frequency / 1000 - 5, 0) * 0.125 + 0.25, 1) * amp * (0.04 / pow(i, 0.5)))
		
		for i in range(1, 10000 / frequency + 2, 2):
			value += sinwave_gen(2 * phase_time * i, sinwave_gen(note_time * max(i * 2 * frequency / 1000 - 5, 0) * 0.125 + 0.25, 1) * amp * (1.0 / pow(i, 1.0)))
			value += sinwave_gen(2 * phase_time * (i + 1), sinwave_gen(note_time * max((i + 1) * 2 * frequency / 1000 - 5, 0) * 0.125 + 0.25, 1) * amp * (0.08 / pow(i, 0.25)))
		
		raw_values.append(value * 0.5)
		
		# Advance Phase
		phase_time = fmod(phase_time + frequency / sample.mix_rate, 1.0)
		
		beat_time += delta
		
	var echo0_values = echo_filter(raw_values, 9, int(3 / delta), 0.5)
	raw_values = mix_in(echo0_values, raw_values, 1, 1)
	
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
