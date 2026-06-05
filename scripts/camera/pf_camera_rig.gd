# pf_camera_rig.gd
class_name PFCameraRig
extends Node3D

@export var enable_edge_scrolling: bool = false
@export var enable_camera_snap: bool = true

@export_category("Input Speeds")
@export var keyboard_pan_speed: float = 20.0
@export var edge_scroll_speed: float = 20.0
@export var mouse_drag_speed: float = 0.05
@export var mouse_rotation_speed: float = 0.3
@export var keyboard_zoom_speed: float = 20.0
@export var mouse_wheel_zoom_speed: float = 2.0

@export_category("Smoothing Weights")
@export var pan_smoothing: float = 15.0
@export var rotation_smoothing: float = 5.0
@export var zoom_smoothing: float = 5.0

@export_category("Zoom Limits")
@export var default_zoom: float = 20.0
@export var min_zoom: float = 5.0
@export var max_zoom: float = 30.0

@export_category("Controls & Targets")
@export var reset_camera_key: Key = KEY_QUOTELEFT
@export var edge_margin: float = 30.0

var camera: Camera3D
var tracked_target: Node3D = null

# Target states for smoothing
var target_position: Vector3
var target_rotation_y: float
var target_zoom: float

var _is_dragging: bool = false
var _is_rotating_camera: bool = false
var _last_mouse_pos: Vector2

func _ready():
	# Initialize or find Camera3D
	for child in get_children():
		if child is Camera3D:
			camera = child
			break
			
	if not camera:
		camera = Camera3D.new()
		add_child(camera)
		
	# Setup HD-2D Orthographic perspective
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = default_zoom
	# To center the origin at a -30 degree pitch, Z must be Y / tan(30) (which is Y * 1.732)
	camera.position = Vector3(0, 20, 34.641) 
	camera.rotation_degrees = Vector3(-30, 0, 0) # Pitch down -30 degrees
	
	# Initial Gimbal State
	rotation_degrees.y = 45.0
	target_rotation_y = 45.0
	target_position = position
	target_zoom = default_zoom

func _process(delta: float):
	_handle_panning(delta)
	
	# Handle Keyboard Zooming (Hold to zoom)
	if Input.is_key_pressed(KEY_PAGEUP):
		target_zoom = clamp(target_zoom - (keyboard_zoom_speed * delta), min_zoom, max_zoom)
	if Input.is_key_pressed(KEY_PAGEDOWN):
		target_zoom = clamp(target_zoom + (keyboard_zoom_speed * delta), min_zoom, max_zoom)
	
	# Smoothly interpolate position, rotation, and zoom
	position = position.lerp(target_position, pan_smoothing * delta)
	
	# Using standard lerp instead of lerp_angle prevents snapping/bouncing 
	# when the rotation crosses the 180 / -180 degree boundary.
	rotation_degrees.y = lerp(rotation_degrees.y, target_rotation_y, rotation_smoothing * delta)
	
	camera.size = lerp(camera.size, target_zoom, zoom_smoothing * delta)

func _unhandled_input(event: InputEvent):
	# Handle Rotation (Q/E) and Reset
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			target_rotation_y += 90.0
		elif event.keycode == KEY_E:
			target_rotation_y -= 90.0
		elif event.keycode == reset_camera_key:
			target_zoom = default_zoom
			if is_instance_valid(tracked_target):
				focus_on_position(tracked_target.global_position)
			
	# Handle Zooming (Scroll Wheel)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom = clamp(target_zoom - mouse_wheel_zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom = clamp(target_zoom + mouse_wheel_zoom_speed, min_zoom, max_zoom)
			
		# Handle Middle Click Drag start/stop
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				_is_dragging = true
				_last_mouse_pos = event.position
			else:
				_is_dragging = false
				
		# Handle Right Click Rotate start/stop
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_is_rotating_camera = true
				_last_mouse_pos = event.position
			else:
				_is_rotating_camera = false
				
	# Handle Mouse Motion for Dragging and Rotating
	if event is InputEventMouseMotion:
		var delta_mouse = event.relative # relative tracks hardware motion directly, preventing edge-jitter
		
		
		if _is_dragging:
			# Move target relative to camera rotation
			var right = transform.basis.x.normalized()
			var forward = -transform.basis.z.normalized()
			
			# Note: Dragging mouse right should move camera left, so we invert
			target_position -= right * delta_mouse.x * mouse_drag_speed * (target_zoom / default_zoom)
			target_position += forward * delta_mouse.y * mouse_drag_speed * (target_zoom / default_zoom)
			
		if _is_rotating_camera:
			target_rotation_y -= delta_mouse.x * mouse_rotation_speed

func _handle_panning(delta: float):
	if _is_dragging:
		return # Do not process WASD or Edge while dragging
		
	var input_dir = Vector2.ZERO
	
	# WASD Panning
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): input_dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): input_dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): input_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): input_dir.x += 1
	
	var _is_edge_scrolling = false
	
	# Edge Scrolling
	if enable_edge_scrolling and input_dir == Vector2.ZERO:
		var vp_size = get_viewport().get_visible_rect().size
		var mouse_pos = get_viewport().get_mouse_position()
		
		# Only edge scroll if mouse is actually inside the window (mostly for windowed mode)
		if Rect2(Vector2.ZERO, vp_size).has_point(mouse_pos):
			if mouse_pos.x < edge_margin: 
				input_dir.x -= 1
				_is_edge_scrolling = true
			elif mouse_pos.x > vp_size.x - edge_margin: 
				input_dir.x += 1
				_is_edge_scrolling = true
			
			if mouse_pos.y < edge_margin: 
				input_dir.y -= 1
				_is_edge_scrolling = true
			elif mouse_pos.y > vp_size.y - edge_margin: 
				input_dir.y += 1
				_is_edge_scrolling = true
			
	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		var right = transform.basis.x.normalized()
		var forward = -transform.basis.z.normalized()
		
		var move_speed = keyboard_pan_speed
		if _is_edge_scrolling:
			move_speed = edge_scroll_speed
			
		move_speed = move_speed * (target_zoom / default_zoom) # Scale speed by zoom
		target_position += right * input_dir.x * move_speed * delta
		target_position -= forward * input_dir.y * move_speed * delta

func focus_on_position(pos: Vector3, snap_immediately: bool = false):
	if not enable_camera_snap:
		return
		
	# Ignore Y position so the gimbal stays on the ground
	var floor_pos = Vector3(pos.x, 0, pos.z)
	target_position = floor_pos
	
	if snap_immediately:
		position = target_position
