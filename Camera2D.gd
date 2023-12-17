extends Camera2D

# Camera movement parameters
var acceleration: float = 1500  # Acceleration rate
var max_speed: float = 1200    # Maximum speed
var initial_speed: float = 500 # Initial movement speed
var velocity = Vector2()       # Current velocity

# Zoom parameters
var zoom_speed: float = 6    # Zoom speed
var min_zoom: Vector2 = Vector2(0.5, 0.5)  # Minimum zoom level
var max_zoom: Vector2 = Vector2(2, 2)      # Maximum zoom level

# Screen edge sensitivity for mouse scrolling
var edge_threshold: float = 50

# Export a NodePath variable for setting the camera bounds in the editor
@export var bounds_node_path: NodePath

# Middle mouse dragging
var dragging: bool = false
var last_mouse_position: Vector2 = Vector2()

func _process(delta):
	var movement_input = Vector2()

	
	# Handle middle mouse button dragging
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		if !dragging:
			dragging = true
			last_mouse_position = get_viewport().get_mouse_position()

		var current_mouse_position = get_viewport().get_mouse_position()
		if current_mouse_position != last_mouse_position:
			var drag_offset = (last_mouse_position - current_mouse_position) / zoom
			position += drag_offset
			last_mouse_position = current_mouse_position
	else:
		dragging = false
		
	# Skip other movement logic if dragging
	if dragging:
		handle_zoom(delta)
		return
	# WASD Movement Input
	movement_input.x = get_axis_input(KEY_A, KEY_D, velocity.x)
	movement_input.y = get_axis_input(KEY_W, KEY_S, velocity.y)

	# Mouse Movement at Screen Edges
	var mouse_position = get_viewport().get_mouse_position()
	movement_input = apply_edge_movement(mouse_position, movement_input)

	# Apply acceleration and clamp velocity
	if movement_input != Vector2.ZERO:
		velocity += movement_input.normalized() * acceleration * delta
		velocity.x = clamp(velocity.x, -max_speed, max_speed)
		velocity.y = clamp(velocity.y, -max_speed, max_speed)

		if movement_input.x == 0:
			velocity.x = 0
		if movement_input.y == 0:
			velocity.y = 0
	else:
		velocity = Vector2.ZERO

	# Apply the velocity to move the camera
	if !dragging:
		position += velocity * delta

	# Get the bounds node from the exported NodePath
	var bounds_node = get_node_or_null(bounds_node_path)
	if bounds_node:
		var bounds = bounds_node.get_node("CollisionShape2D").shape.extents
		var clamped_x = clamp(global_position.x, bounds_node.global_position.x - bounds.x, bounds_node.global_position.x + bounds.x)
		var clamped_y = clamp(global_position.y, bounds_node.global_position.y - bounds.y, bounds_node.global_position.y + bounds.y)
		global_position = Vector2(clamped_x, clamped_y)
	else:
		print_debug("Bounds node not found or not set")

	# Zoom with scroll wheel
	handle_zoom(delta)

# Helper function to get movement input for an axis
func get_axis_input(negative_key, positive_key, current_velocity):
	var axis_input = 0.0
	if Input.is_key_pressed(negative_key):
		axis_input -= 1
	elif Input.is_key_pressed(positive_key):
		axis_input += 1
	else:
		# Snap to zero if the key for the current direction is released
		return 0 if current_velocity != 0 else axis_input
	return axis_input

# Apply edge movement for mouse position
func apply_edge_movement(mouse_position, movement_input):
	if mouse_position.x < edge_threshold:
		movement_input.x -= 1
	if mouse_position.x > get_viewport().size.x - edge_threshold:
		movement_input.x += 1
	if mouse_position.y < edge_threshold:
		movement_input.y -= 1
	if mouse_position.y > get_viewport().size.y - edge_threshold:
		movement_input.y += 1
	return movement_input

# Handle camera zoom
func handle_zoom(delta):
	if Input.is_action_just_released("ui_zoom_in"):
		zoom += Vector2(zoom_speed, zoom_speed) * delta
	elif Input.is_action_just_released("ui_zoom_out"):
		zoom -= Vector2(zoom_speed, zoom_speed) * delta
	zoom.x = clamp(zoom.x, min_zoom.x, max_zoom.x)
	zoom.y = clamp(zoom.y, min_zoom.y, max_zoom.y)
