tool
extends Control

export(float) var thickness = 8 setget set_thickness
export(float) var radius = 32 setget set_radius
export(float) var height = 32 setget set_height
export(float) var shear = 0 setget set_shear

export(Color) var color = Color.white

export(bool) var cut_under_line = true setget set_cut_under_line

var patterns = [] setget set_patterns

const segments = [
	# Vowels
	[0,1],
	[1,2],
	[2,3],
	[3,4],
	[4,5],
	
	# Consonants
	[6,0],
	[6,1],
	[6,2],
	[7,3],
	[7,4],
	[7,5],
]

var points: PoolVector2Array

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		request_ready()
		
func _ready() -> void:
	update()

func _draw() -> void:
	var special_x = sin(PI/3)
	
	points = PoolVector2Array()
	points.append(Vector2(special_x * radius, -.5 * (radius + height)))
	points.append(Vector2(0, -(1 * radius + .5 * height)))
	points.append(Vector2(-special_x * radius, -.5 * (radius + height)))
	points.append(Vector2(-special_x * radius, .5 * (radius + height)))
	points.append(Vector2(0, (1 * radius + .5 * height)))
	points.append(Vector2(special_x * radius, .5 * (radius + height)))
	points.append(Vector2(0, -.5 * height))
	points.append(Vector2(0, .5 * height))

	var line_height = get_line_height()
	var pen: Vector2 = Vector2(thickness + line_height * abs(tan(deg2rad(shear))) / 2, line_height / 2)
	
	for line in patterns:
		write_line(line, pen)
		pen += Vector2(0, line_height)

func write_line(line: Array, pen: Vector2) -> void:
	var rune_width = get_rune_width()
	
	var sheer_transform = Transform2D(Vector2.RIGHT, Vector2(tan(deg2rad(shear)), 1), pen)
	draw_set_transform_matrix(sheer_transform)
	pen = Vector2.ZERO

	for word in line:
		# Under Cut
		if cut_under_line:
			var start = pen + Vector2(-thickness / 2, 0)
			var end = pen + Vector2(len(word) * rune_width + thickness / 2, 0)
			
			draw_segment(start, end, thickness, color)
		
		for rune_pattern in word:
			write_rune(rune_pattern, pen)
			
			pen += Vector2(rune_width, 0)
		pen += Vector2(rune_width / 2, 0)
	
func write_rune(rune_pattern: Array, pen: Vector2) -> void:
	var center = pen + Vector2(get_rune_width_half(), 0)
	
	var used_points = []
		
	# Main Segments
	for i in 11:
		if rune_pattern[i]:
			var segment = segments[i]
			for p in 2:
				var point_index = segment[p]
				if not used_points.has(point_index):
					used_points.append(point_index)
					
			if not (i == 2 and cut_under_line):
				draw_segment(center + points[segment[0]], center + points[segment[1]], thickness, color)

	if rune_pattern[2] and cut_under_line:
		draw_segment(center + points[2], center + (points[2] + points[3]) / 2, thickness, color)
		draw_segment(center + points[3], center + lerp(points[3], points[2], .5 * radius / (radius + height)), thickness, color)

	# Bridge
	var top_part = false
	for i in 3:
		if rune_pattern[i+5]:
			top_part = true
			
	var bottom_part = false
	for i in 3:
		if rune_pattern[i+8]:
			bottom_part = true
		
	if rune_pattern[6] and bottom_part or rune_pattern[9] and top_part:
		if cut_under_line:
			draw_segment(center + points[6], center, thickness, color)
		else:
			draw_segment(center + points[6], center + points[7], thickness, color)
			
	# Endpoint Caps
	for point_index in used_points:
		draw_circle(center + points[point_index], thickness / 2, color)
	
	if rune_pattern[2] and cut_under_line:
		draw_circle(center + lerp(points[3], points[2], .5 * radius / (radius + height)), thickness / 2, color)
	
	# Flipped
	if rune_pattern[11]:
		draw_ring(center + points[4] + Vector2(0, radius / 4), radius / 4 - 0.5 * thickness, radius / 4 + 0.5 * thickness, color)

func draw_circle(center: Vector2, radius: float, color: Color) -> void:
	var points = PoolVector2Array()
	for i in 32:
		var theta = float(i) / 32 * 2 * PI
		points.append(center + Vector2(cos(theta) * radius, sin(theta) * radius))
	
	var colors = PoolColorArray([color])
	
	draw_polygon(points, colors, PoolVector2Array(), null, null, true)

func draw_segment(p0: Vector2, p1: Vector2, width: float, color: Color) -> void:
	var tangent = (p1 - p0).normalized()
	var normal = Vector2(-tangent.y, tangent.x) * width / 2
	
	var points = PoolVector2Array()
	points.append(p0 + normal)
	points.append(p1 + normal)
	points.append(p1 - normal)
	points.append(p0 - normal)
	
	var colors = PoolColorArray([color])
	
	draw_polygon(points, colors, PoolVector2Array(), null, null, true)

func draw_ring(center: Vector2, inner_radius: float, outer_radius: float, color: Color) -> void:
	var points = PoolVector2Array()
	for i in 33:
		var theta = float(i) / 32 * 2 * PI
		points.append(center + Vector2(cos(theta) * outer_radius, sin(theta) * outer_radius))

	for i in 33:
		var theta = -float(i) / 32 * 2 * PI
		points.append(center + Vector2(cos(theta) * inner_radius, sin(theta) * inner_radius))
			
	var colors = PoolColorArray([color])
	
	draw_polygon(points, colors, PoolVector2Array(), null, null, true)

func set_patterns(value: Array) -> void:
	patterns = value
	update()
	
func set_thickness(pixels: float) -> void:
	thickness = max(pixels, 1)
	update()

func set_radius(pixels: float) -> void:
	radius = max(pixels, thickness/2)
	update()
	
func set_height(pixels: float) -> void:
	height = max(pixels, 0)
	update()

func set_shear(angle: float) -> void:
	shear = clamp(angle, -45, 45)

func set_cut_under_line(toggle: bool) -> void:
	cut_under_line = toggle
	update()
	
func get_rune_width_half() -> float:
	return sin(PI/3) * radius
	
func get_rune_width() -> float:
	return get_rune_width_half() * 2
	
func get_line_height() -> float:
	return height + 3 * radius + 2 * thickness

func _get_minimum_size() -> Vector2:
	var half_width = get_rune_width_half()
	var max_halves = 0
	
	for line in patterns:
		var halves = 0
		for word in line:
			var rune_count = len(word)
			halves += rune_count * 2
		
		var word_count = len(line)
		halves += word_count - 1
		
		if halves > max_halves:
			max_halves = halves
	
	var min_height = get_line_height() * len(patterns)
	return Vector2(max_halves * half_width + thickness + abs(tan(deg2rad(shear))) * min_height, min_height)

func get_rune_position(line: int, word: int, rune: int) -> Vector2:
	var half_width = get_rune_width_half()
	var x = 0
	var y = get_line_height() * line

	for w in word:
		x += (len(patterns[line][w]) * 2 + 1) * half_width

	x += rune * 2 * half_width

	return Vector2(x, y)

func save() -> void:
	var file_dialog = Persistent.file_dialog
	file_dialog.filters = ["*.svg ; Scalable Vector file"]
	file_dialog.connect("file_selected", self, "write_file")
	file_dialog.popup_centered()

func write_file(path: String) -> void:
	var file_dialog = Persistent.file_dialog
	file_dialog.disconnect("file_selected", self, "write_file")
	
	var file = File.new()
	file.open(path, File.WRITE)
	
	file.store_line('<?xml version="1.0" encoding="UTF-8" standalone="no"?>')
	
	var size = get_minimum_size()
	file.store_line('<svg width="%f" height="%f"  xmlns="http://www.w3.org/2000/svg">' % [size.x, size.y])
	
	var line_height = get_line_height()
	var pen: Vector2 = Vector2(thickness + line_height * abs(tan(deg2rad(shear))) / 2, line_height / 2)
	
	for line in patterns:
		store_line(file, line, pen)
		pen += Vector2(0, get_line_height())

	file.store_line('</svg>')
	
	file.close()
	
func store_line(file: File, line: Array, pen: Vector2) -> void:
	var rune_width = get_rune_width()

	file.store_line('<g id="line" stroke="#%s" transform="translate(%f,%f) skewX(%f)">' % [color.to_html(), pen.x, pen.y, shear])	
	pen = Vector2.ZERO

	for word in line:
		file.store_line('<g id="word">')
			
		# Under Cut
		if cut_under_line:
			var start = pen
			var end = pen + Vector2(len(word) * rune_width, 0)
			
			file.store_line('<line x1="%f" y1="%f" x2="%f" y2="%f" stroke-width="%f" stroke-linecap="round"/>' % [start.x, start.y, end.x, end.y, thickness])
		
		for rune in word:
			file.store_line('<g id="rune">')
			store_rune(file, rune, pen)
			file.store_line('</g>')
			
			pen += Vector2(rune_width, 0)
		pen += Vector2(rune_width / 2, 0)
		
		file.store_line('</g>')
		
	file.store_line('</g>')
	
func store_rune(file: File, rune_pattern: Array, pen: Vector2) -> void:
	var center = pen + Vector2(get_rune_width_half(), 0)
	
	var used_points = []
		
	# Main Segments
	for i in 11:
		if rune_pattern[i]:
			var segment = segments[i]
			for p in 2:
				var point_index = segment[p]
				if not used_points.has(point_index):
					used_points.append(point_index)
					
			if not (i == 2 and cut_under_line):
				store_segment(file, center + points[segment[0]], center + points[segment[1]], thickness)

	if rune_pattern[2] and cut_under_line:
		store_segment(file, center + points[2], center + (points[2] + points[3]) / 2, thickness)
		store_segment(file, center + points[3], center + lerp(points[3], points[2], .5 * radius / (radius + height)), thickness)

	# Bridge
	var top_part = false
	for i in 3:
		if rune_pattern[i+5]:
			top_part = true
			
	var bottom_part = false
	for i in 3:
		if rune_pattern[i+8]:
			bottom_part = true
		
	if rune_pattern[6] and bottom_part or rune_pattern[9] and top_part:
		if cut_under_line:
			store_segment(file, center + points[6], center, thickness)
		else:
			store_segment(file, center + points[6], center + points[7], thickness)
	
	# Flipped
	if rune_pattern[11]:
		store_ring(file, center + points[4] + Vector2(0, radius / 4), radius / 4 - 0.5 * thickness, radius / 4 + 0.5 * thickness)

func store_segment(file: File, p0: Vector2, p1: Vector2, width: float) -> void:
	file.store_line('<line x1="%f" y1="%f" x2="%f" y2="%f" stroke-width="%f" stroke-linecap="round" />' % [p0.x, p0.y, p1.x, p1.y, width])

func store_ring(file: File, center: Vector2, inner_radius: float, outer_radius: float) -> void:
	file.store_line('<circle cx="%f" cy="%f" r="%f" fill="none" stroke-width="%f" />' % [center.x, center.y, (outer_radius + inner_radius) / 2, outer_radius - inner_radius])
