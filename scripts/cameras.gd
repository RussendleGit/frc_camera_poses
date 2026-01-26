extends Node3D

var camera_attributes: Array[Node3D] = []
var current_camera_used_index: int = 0

func setup_cameras():
	for i in range(len(camera_attributes)):
		camera_attributes[i].name = str(i)
		add_child(camera_attributes[i])

## adds a camera, also flips y and z for ease of use
func add_camera(cam_position_meters: Vector3, cam_rotation_degrees: Vector3):
	var camera_scene = load("res://scenes/camera_marker.tscn")
	var cam_instance: Node = camera_scene.instantiate()
	cam_instance.position = Vector3(cam_position_meters.x, cam_position_meters.z, cam_position_meters.y)
	cam_instance.rotation_degrees = Vector3(cam_rotation_degrees.x, cam_rotation_degrees.z, cam_rotation_degrees.y)
	camera_attributes.append(cam_instance)

func get_current_camera():
	return camera_attributes[current_camera_used_index]

## sets the camera index to the next being processed
## returns a bool weather it has gone back to the first camera
func next_camera() -> bool:
	current_camera_used_index += 1
	if (current_camera_used_index >= len(camera_attributes)):
		current_camera_used_index = 0
		return true
	return false

func skip_current_iteration():
	current_camera_used_index = 0
