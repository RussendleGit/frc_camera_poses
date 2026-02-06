extends Node3D
@onready var database: Node = $"../Database"

@export var max_tag_distance: float = 200.0 / 39.37
@export var max_tag_skew_degrees: float = 80
@export var camera_fov_degrees: float = 100.0

@export var camera_translation_increment: float = .1
@export var camera_rotation_increment_degrees: float = 1.0
@export var drive_train_dimensions: Vector3 = Vector3(25.0 / 39.37, 30.0 / 39.37, 30.0 / 39.37)
@export var min_cam_hight: float = 0.15
@export var camera_pitch_limits_degrees: Vector2 = Vector2(-35.0, 35.0)

var camera_attributes: Array[Node3D] = []
var current_camera_used_index: int = 0
var current_camera: Node3D


func setup_cameras():
	for i in range(len(camera_attributes)):
		camera_attributes[i].name = str(i)
		add_child(camera_attributes[i])
	current_camera = camera_attributes[0]

## adds a camera, also flips y and z for ease of use
func add_camera_at_pose(cam_position_meters: Vector3, cam_rotation_degrees: Vector3):
	var camera_scene = load("res://scenes/camera_marker.tscn")
	var cam_instance: Node = camera_scene.instantiate()
	cam_instance.position = Vector3(cam_position_meters.x, cam_position_meters.z, cam_position_meters.y)
	cam_instance.rotation_degrees = Vector3(cam_rotation_degrees.x, cam_rotation_degrees.z, cam_rotation_degrees.y)
	camera_attributes.append(cam_instance)

## adds camera to the less most position on the robot, and sets them up automatically
func add_cameras(num_cams: int):
	for i in range(num_cams):
		add_camera_at_pose(
			Vector3(-drive_train_dimensions.x / 2.0, -drive_train_dimensions.z / 2.0, min_cam_hight), 
			Vector3(0.0, -camera_pitch_limits_degrees.x / 2.0, 0.0)
		)
	setup_cameras()

## gets the current camera that's supposed to be read
func get_current_camera():
	return camera_attributes[current_camera_used_index]

## sets the camera index to the next being processed
## returns a bool weather it has gone back to the first camera
func next_camera() -> bool:
	current_camera_used_index += 1
	var is_reset: bool = current_camera_used_index >= len(camera_attributes)
	if (is_reset):
		current_camera_used_index = 0
	current_camera = camera_attributes[current_camera_used_index]
	return is_reset

## usually used if the robot is in an invalid position
## resets the camera back to 0
func skip_current_iteration():
	current_camera_used_index = 0

## given the april tags, this filters the tags based off restrictions set on this node
func filter_april_tags(tags: Array[Node]) -> Array[Node3D]:
	var viewable_tags: Array[Node3D] = []
	
	# get every tag in the tag directory in the camera
	for tag in tags:
		# ignore of which the raycast is colliding
		var see_all_four_corners = true
		for ray_cast in tag.get_ray_casts():
			if ray_cast.is_colliding():
				see_all_four_corners = false
				break
		
		if !see_all_four_corners:
			tag.visible = false
			continue

		# ignore tags that are too far away
		var distance_from_cam: float = current_camera.global_position.distance_to(tag.global_position)
		tag.distance = distance_from_cam
		if distance_from_cam > max_tag_distance:
			continue

		# ignore tags that are too skewed
		var skew_yaw = wrapf((tag.global_rotation.y - deg_to_rad(90.0)) - current_camera.global_rotation.y, -PI, PI)
		var skew_pitch = wrapf(tag.global_rotation.z - current_camera.global_rotation.z, -PI, PI)
		tag.skew_yaw = skew_yaw
		tag.skew_pitch = skew_pitch

		if abs(skew_yaw) > deg_to_rad(max_tag_skew_degrees) || abs(skew_pitch) > deg_to_rad(max_tag_skew_degrees):
			tag.visible = false
			continue

		# for ignoring tags outside of fov
		var direction = tag.global_position - current_camera.global_position
		
		# ignore tags outside fov yaw
		var direction_2d_yaw = Vector2(direction.x, direction.z)
		var angle_yaw = direction_2d_yaw.angle()
		var angle_diff_yaw = wrapf(angle_yaw + current_camera.global_rotation.y, -PI, PI)
		if abs(angle_diff_yaw) > deg_to_rad(camera_fov_degrees / 2.0):
			tag.visible = false
			continue

		# ignore tags outside of pitch
		var direction_2d_pitch = Vector2(direction.x, direction.y)
		var angle_pitch = direction_2d_pitch.angle()
		var angle_diff_pitch_left = wrapf(angle_pitch + current_camera.global_rotation.z, -PI, PI)
		var angle_diff_pitch_right = wrapf(angle_pitch + current_camera.global_rotation.z - PI, -PI, PI)
		if (abs(angle_diff_pitch_left) > deg_to_rad(camera_fov_degrees / 2.0) &&
			abs(angle_diff_pitch_right) > deg_to_rad(camera_fov_degrees / 2.0)):
			tag.visible = false
			continue

		viewable_tags.append(tag)
		tag.visible = true
		
	return viewable_tags

func move_camera():
	for i in range(len(camera_attributes)):
		var cam = camera_attributes[i]
		# yaw
		var new_yaw: float = cam.rotation_degrees.y + camera_rotation_increment_degrees
		if new_yaw < 180.0: 
			cam.rotation_degrees.y += camera_rotation_increment_degrees
			return
		cam.rotation.y = -PI + 0.0001

		# pitch
		var new_pitch: float = cam.rotation_degrees.z + camera_rotation_increment_degrees
		if new_pitch > camera_pitch_limits_degrees.x && new_pitch < camera_pitch_limits_degrees.y:
			cam.rotation_degrees.z += camera_rotation_increment_degrees
			return
		cam.rotation_degrees.z = camera_pitch_limits_degrees.x

		# x
		cam.position.x += camera_translation_increment
		if cam.position.x < drive_train_dimensions.x / 2.0: return
		cam.position.x = -drive_train_dimensions.x / 2.0

		# z
		cam.position.z += camera_translation_increment
		if cam.position.z < drive_train_dimensions.z / 2.0: return
		cam.position.z = -drive_train_dimensions.z / 2.0

		# y
		cam.position.y += camera_translation_increment
		if cam.position.y < drive_train_dimensions.y: return
		cam.position.y = min_cam_hight
	database.save(true)

	
