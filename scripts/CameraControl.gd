extends Camera3D

# Movement settings
@export var move_speed: float = 10.0
@export var sprint_multiplier: float = 2.0
@export var mouse_sensitivity: float = 0.003

# Rotation limits
@export var min_pitch: float = -89.0
@export var max_pitch: float = 89.0

var rotation_x: float = 0.0
var rotation_y: float = 0.0
var mouse_captured: bool = false

func _ready():
	# Capture mouse on start (optional)
	# Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# mouse_captured = true
	pass

func _input(event):
	# Toggle mouse capture with right click
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if mouse_captured:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				mouse_captured = false
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				mouse_captured = true
	
	# Mouse look (only when captured)
	if event is InputEventMouseMotion and mouse_captured:
		rotation_y -= event.relative.x * mouse_sensitivity
		rotation_x -= event.relative.y * mouse_sensitivity
		rotation_x = clamp(rotation_x, deg_to_rad(min_pitch), deg_to_rad(max_pitch))
		
		rotation.x = rotation_x
		rotation.y = rotation_y

func _process(delta):
	if not mouse_captured:
		return
	
	# Get input direction
	var input_dir = Vector3.ZERO
	
	if Input.is_key_pressed(KEY_W):
		input_dir -= transform.basis.z
	if Input.is_key_pressed(KEY_S):
		input_dir += transform.basis.z
	if Input.is_key_pressed(KEY_A):
		input_dir -= transform.basis.x
	if Input.is_key_pressed(KEY_D):
		input_dir += transform.basis.x
	if Input.is_key_pressed(KEY_Q):
		input_dir -= transform.basis.y
	if Input.is_key_pressed(KEY_E):
		input_dir += transform.basis.y
	
	# Normalize to prevent faster diagonal movement
	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
	
	# Apply sprint
	var speed = move_speed
	if Input.is_key_pressed(KEY_SHIFT):
		speed *= sprint_multiplier
	
	# Move camera
	position += input_dir * speed * delta
