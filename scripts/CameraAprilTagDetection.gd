extends Node3D

@export var camera_fov_degrees: float = 100.0
@export var max_distance: float = 200.0 / 39.37
@export var max_tag_angle_to_cam: float = 80

@export var num_poses_grid: Vector2 = Vector2(40.0, 40.0)
@export var rotation_increment_degrees: float = 5
@export var camera_translation_increment: float = 0.1
@export var field_dimensions_meters: Vector2 = Vector2(16.540988, 8.069326)



@onready var tag_directory: Node3D = $TagDirectory
@onready var camera_directory: Node3D = $CameraDirectory
@onready var allowed_areas: Node3D = $AllowedAreas
@onready var robot_collision: Area3D = $CameraDirectory/RobotCollision

var position_translation_increment: Vector2
var num_camera_changes: int = 0
var num_robot_pose_changes: int = 0
var data: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position_translation_increment = Vector2(field_dimensions_meters.x / num_poses_grid.x, field_dimensions_meters.y / num_poses_grid.y)
	tag_directory.set_april_tags()

	camera_directory.add_camera(Vector3(0.0, -0.2, 0.4), Vector3(0.0, 15.0, 30.0)) 
	camera_directory.add_camera(Vector3(0.0, 0.2, 0.4), Vector3(0.0, 15.0, -30.0)) 
	camera_directory.setup_cameras()

	tag_directory.update_raycasts_for_next_iteration(camera_directory.get_current_camera())

		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if robot_collision.has_overlapping_bodies():
		print("rejected")
		move_robot()
		tag_directory.update_raycasts_for_next_iteration(camera_directory.get_current_camera())
		camera_directory.skip_current_iteration()
		return
		
	var unblocked_tags = filter_tags_by_raycast()
	var tags_within_view_angle = filter_tags_by_cam_view_angle(camera_directory.get_current_camera(), unblocked_tags)
	var tags_within_distance = filter_tags_by_distance(camera_directory.get_current_camera(), tags_within_view_angle)	
	var tags_within_tag_angle = filter_tags_by_tag_angle(camera_directory.get_current_camera(), tags_within_distance)

	var is_reset = camera_directory.next_camera()
	if is_reset:
		move_robot()

	tag_directory.update_raycasts_for_next_iteration(camera_directory.get_current_camera())
	
	
## gives a list of the tags that are not blocked by anything
## doesn't need camera attribute as the raycasts have been already handled by update_raycasts_for_next_iteration
func filter_tags_by_raycast() -> Array[Node3D]:
	var unblocked_april_tags: Array[Node3D] = []
	
	# get every tag in the tag directory in the camera
	for tag in tag_directory.get_all_tags():
		# for each corner of the april tag scene
		var see_all_four_corners = true
		for ray_cast in tag.get_ray_casts():
			if ray_cast.is_colliding():
				see_all_four_corners = false
			
		if see_all_four_corners:
			unblocked_april_tags.append(tag)
			tag.visible = true
		else:
			tag.visible = false
	
	return unblocked_april_tags

## get the tags that are within view angles
func filter_tags_by_cam_view_angle(camera_attribute: Node3D, tags: Array[Node3D]) -> Array[Node3D]:
	# horizontal
	var tags_in_view: Array[Node3D] = []
	for tag in tags:
		var direction = tag.global_position - camera_attribute.global_position
		
		# get 2d values for x, and z
		var direction_2d_yaw = Vector2(direction.x, direction.z)
		var direction_2d_pitch = Vector2(direction.x, direction.y)
		
		# get the angle between the tags
		var angle_yaw = direction_2d_yaw.angle()
		var angle_pitch = direction_2d_pitch.angle()

		# account rotation of marker
		var angle_diff_yaw = wrapf(angle_yaw + camera_attribute.global_rotation.y, -PI, PI)
		var angle_diff_pitch_left = wrapf(angle_pitch + camera_attribute.global_rotation.z, -PI, PI)
		var angle_diff_pitch_right = wrapf(angle_pitch + camera_attribute.global_rotation.z - PI, -PI, PI)

		if abs(angle_diff_yaw) <= deg_to_rad(camera_fov_degrees / 2.0) && \
			(abs(angle_diff_pitch_left) <= deg_to_rad(camera_fov_degrees / 2.0) || \
			abs(angle_diff_pitch_right) <= deg_to_rad(camera_fov_degrees / 2.0)):
			tag.visible = true
			tags_in_view.append(tag)
		else:
			tag.visible = false
	
	return tags_in_view

func filter_tags_by_distance(camera_attribute: Node3D, tags: Array[Node3D]) -> Array[Node3D]:
	var tags_within_range: Array[Node3D] = []
	
	for tag in tags:
		if camera_attribute.global_position.distance_to(tag.global_position) < max_distance:
			tag.visible = true
			tags_within_range.append(tag)
		else:
			tag.visible = false
			 
	return tags_within_range		

func filter_tags_by_tag_angle(camera_attribute: Node3D, tags: Array[Node3D]) -> Array[Node3D]:
	var tags_within_angle: Array[Node3D] = []
	
	for tag in tags:
		# take away 90 from yaw, because that's the default rotation for april tags
		var yaw = wrapf((tag.global_rotation.y - deg_to_rad(90.0)) - camera_attribute.global_rotation.y, -PI, PI)
		var pitch = wrapf(tag.global_rotation.z - camera_attribute.global_rotation.z, -PI, PI)
		tag.skew_yaw = yaw
		tag.skew_pitch = pitch

		if abs(yaw) <= deg_to_rad(max_tag_angle_to_cam) && abs(pitch) <= deg_to_rad(max_tag_angle_to_cam):
			tag.visible = true
			tags_within_angle.append(tag)
		else:
			tag.visible = false 
		
	return tags_within_angle

func move_robot():
	var new_rot: float = camera_directory.global_rotation_degrees.y + rotation_increment_degrees
	if new_rot < 180.0 - rotation_increment_degrees: 
		camera_directory.global_rotation_degrees.y += rotation_increment_degrees
		return
	print("reset")
	camera_directory.global_rotation.y = -PI + 0.0001 # reset rotation after it completes a full rotation
	
	camera_directory.global_position.x += position_translation_increment.x
	if camera_directory.global_position.x < field_dimensions_meters.x: return
	camera_directory.global_position.x = 0.0

	camera_directory.global_position.z += position_translation_increment.y
	if camera_directory.global_position.z < field_dimensions_meters.y: return
	camera_directory.global_position.z = 0.0
	num_camera_changes += 1
	print("completed full cycle")
	
