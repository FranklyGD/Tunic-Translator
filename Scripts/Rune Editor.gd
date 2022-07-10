tool
extends Control

export(Array, bool) var active_segments = [
	true, true, true, true, true,
	true, true, true, true, true, true
] setget set_active_segments
export(bool) var flipped = false setget set_flipped

export(bool) var editable = true

export(float) var thickness = 8 setget set_thickness
export(float) var radius = 32 setget set_radius
export(float) var height = 32 setget set_height

export(Color) var color = Color.white
export(Color) var hovered_color = Color.slategray
export(Color) var hovered_segment_color = Color.orange

export(bool) var cut_under_line = true setget set_cut_under_line

var hovered = false
var hovered_segment = -1

signal rune_edit(pattern, flipped)

const segments = [
	# Vowel
	[0,1],
	[1,2],
	[2,3],
	[3,4],
	[4,5],
	
	# Consonent
	[6,0],
	[6,1],
	[6,2],
	[7,3],
	[7,4],
	[7,5],
]

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		request_ready()

func _ready() -> void:
	connect("mouse_entered", self, "_mouse_entered")
	connect("mouse_exited", self, "_mouse_exited")
	update() # Force draw
	
func _gui_input(event: InputEvent) -> void:
	if not editable:
		return
		
	if event is InputEventMouseButton:
		if event.pressed:
			on_mouse_press(event.button_index)
	if event is InputEventMouseMotion:
		on_mouse_move(event.position)


func on_mouse_move(mouse_position: Vector2) -> void:
	hovered_segment = get_closest_segment(mouse_position)		
	update()

func _mouse_entered() -> void:
	if not editable:
		return
		
	hovered = true
	update()
	
func _mouse_exited() -> void:
	if not editable:
		return
		
	hovered = false
	hovered_segment = -1
	update()
	
func on_mouse_press(button: int) -> void:
	if button == 1:
		active_segments[hovered_segment] = not active_segments[hovered_segment]
		accept_event()
	if button == 2:
		flipped = not flipped
		accept_event()

	var rune = owner
	var rune_index = rune.get_index() - 1
	var word = rune.get_parent()
	var word_index = word.get_word_index()
	var line = word.get_parent()
	var line_index = line.get_line_index()
	
	var pattern = active_segments.duplicate()
	pattern.append(flipped)
	Persistent.main_writer.patterns[line_index][word_index][rune_index] = pattern
	Persistent.emit_signal("data_updated")

	emit_signal("rune_edit", active_segments, flipped)
	update()
	
func get_closest_segment(position: Vector2) -> int:
	var half_width = get_width_half()
	var center = rect_size / 2
	
	var points = PoolVector2Array()
	points.append(Vector2(half_width, -.5 * (radius + height)))
	points.append(Vector2(0, -(1 * radius + .5 * height)))
	points.append(Vector2(-half_width, -.5 * (radius + height)))
	points.append(Vector2(-half_width, .5 * (radius + height)))
	points.append(Vector2(0, (1 * radius + .5 * height)))
	points.append(Vector2(half_width, .5 * (radius + height)))
	points.append(Vector2(0, -.5 * height))
	points.append(Vector2(0, .5 * height))
	
	var closest_segment = -1
	var closest_distance = INF
	
	for i in 11:
		var segment = segments[i]
		var distance = distance_to_segment(center + points[segment[0]], center + points[segment[1]], position)
		if distance < closest_distance:
			closest_distance = distance
			closest_segment = i
	
	return closest_segment

func _draw() -> void:
	var half_width = get_width_half()
	var center = rect_size / 2
	
	var points = PoolVector2Array()
	points.append(Vector2(half_width, -.5 * (radius + height)))
	points.append(Vector2(0, -(1 * radius + .5 * height)))
	points.append(Vector2(-half_width, -.5 * (radius + height)))
	points.append(Vector2(-half_width, .5 * (radius + height)))
	points.append(Vector2(0, (1 * radius + .5 * height)))
	points.append(Vector2(half_width, .5 * (radius + height)))
	points.append(Vector2(0, -.5 * height))
	points.append(Vector2(0, .5 * height))
	
	var used_points = []
	
	# Main Segments (Hovered)
	if hovered:
		for segment in segments:
			draw_segment(center + points[segment[0]], center + points[segment[1]], 1.5 * thickness, hovered_color)
		
		for point in points:
			draw_circle(center + point, 1.5 * thickness / 2, hovered_color)
		
	# Main Segments
	for i in 11:
		if active_segments[i]:
			var segment = segments[i]
			for p in 2:
				var point_index = segment[p]
				if not used_points.has(point_index):
					used_points.append(point_index)
					
			if not (i == 2 and cut_under_line):
				draw_segment(center + points[segment[0]], center + points[segment[1]], thickness, color)

	if active_segments[2] and cut_under_line:
		draw_segment(center + points[2], center + (points[2] + points[3]) / 2, thickness, color)
		draw_segment(center + points[3], center + lerp(points[3], points[2], .5 * radius / (radius + height)), thickness, color)

	# Bridge
	var top_part = false
	for i in 3:
		if active_segments[i+5]:
			top_part = true
			
	var bottom_part = false
	for i in 3:
		if active_segments[i+8]:
			bottom_part = true
		
	if active_segments[6] and bottom_part or active_segments[9] and top_part:
		if cut_under_line:
			draw_segment(center + points[6], center, thickness, color)
		else:
			draw_segment(center + points[6], center + points[7], thickness, color)
			
	# Endpoint Caps
	for point_index in used_points:
		draw_circle(center + points[point_index], thickness / 2, color)
	
	if active_segments[2] and cut_under_line:
		draw_circle(center + lerp(points[3], points[2], .5 * radius / (radius + height)), thickness / 2, color)
	
	# Extra
	if cut_under_line:
		draw_segment(center + (points[2] + points[3]) / 2, center + (points[0] + points[5]) / 2, thickness, color)
		draw_circle(center + (points[2] + points[3]) / 2, thickness / 2, color)
		draw_circle(center + (points[0] + points[5]) / 2, thickness / 2, color)
	
	if flipped:
		draw_ring(center + points[4] + Vector2(0, radius / 4), radius / 4 - 0.5 * thickness, radius / 4 + 0.5 * thickness, color)
		
	# Highlight Main Segments
	if hovered_segment > -1:
		var segment = segments[hovered_segment]
		for p in 2:
			var point_index = segment[p]
			
			draw_circle(center + points[point_index], thickness / 4, hovered_segment_color)
			draw_segment(center + points[segment[0]], center + points[segment[1]], thickness / 2, hovered_segment_color)

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

func distance_to_segment(p0: Vector2, p1: Vector2, position: Vector2) -> float:
	var local_pos = position - p0
	var vector = p1 - p0
	var tangent = vector.normalized()
	var t = vector.dot(local_pos) / vector.length_squared()
	
	var distance
	if t < 0:
		distance = position.distance_to(p0)
	elif t > 1:
		distance = position.distance_to(p1)
	else:
		distance = abs(local_pos.x * -tangent.y + local_pos.y * tangent.x)
	
	return distance

# Set/Get

func set_active_segments(toggles: Array) -> void:
	toggles.resize(11)
	active_segments = toggles
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

func set_cut_under_line(toggle: bool) -> void:
	cut_under_line = toggle
	update()
	
func set_flipped(toggle: bool) -> void:
	flipped = toggle
	update()

func get_width_half() -> float:
	return sin(PI/3) * radius
	
func get_width() -> float:
	return get_width_half() * 2
	
func _get_minimum_size() -> Vector2:
	var special_x = sin(PI/3)
	return Vector2(ceil(special_x * 2 * radius), height + 3 * radius + 2 * thickness)
