extends Node3D

@onready var camera_3d: Camera3D = $"../Camera3D"

@export var camera_fov_degrees: float = 100.0
@export var max_distance: float = 200.0 / 39.37
@export var max_tag_angle_to_cam: float = 80
@export var slow_physics: bool = true

@export var num_poses_grid: Vector2 = Vector2(10.0, 5.0)
@export var rotation_increment_degrees: float = 4
@export var camera_translation_increment: float = 0.1
@export var field_dimentions_meters: Vector2 = Vector2(16.540988, 8.069326)

@onready var camera_attributes: Array[Node3D] = []
@onready var tag_points = ["MarkerUR", "MarkerUL", "MarkerDR", "MarkerDL"]
@onready var tag_directory: Node3D = $TagDirectory
@onready var camera_directory: Node3D = $CameraDirectory
@onready var allowed_areas: Node3D = $AllowedAreas
@onready var robot_collision: Area3D = $CameraDirectory/RobotCollision

var camera_attributes_index_focus: int = 0
var position_translation_increment: Vector2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position_translation_increment = Vector2(field_dimentions_meters.x / num_poses_grid.x, field_dimentions_meters.y / num_poses_grid.y)
	set_april_tags()
	add_camera(Vector3(0.0, 0.0, 0.4), Vector3()) 
	for i in range(len(camera_attributes)):
		camera_attributes[i].name = str(i)
		camera_directory.add_child(camera_attributes[i])
	update_raycasts_for_next_iteration(camera_attributes[camera_attributes_index_focus])


## adds a camera, also flips y and z for ease of use
func add_camera(cam_position_meters: Vector3, cam_rotation_degrees: Vector3) -> void:
	var camera_scene = load("res://scenes/camera_marker.tscn")
	var cam_instance = camera_scene.instantiate()
	cam_instance.position = Vector3(cam_position_meters.x, cam_position_meters.z, cam_position_meters.y)
	cam_instance.rotation_degrees = Vector3(cam_rotation_degrees.x, cam_rotation_degrees.z, cam_rotation_degrees.y)
	camera_attributes.append(cam_instance)

## When initializing the camera, this creates the needed april tags
func set_april_tags(json_path: String = "2026-rebuilt-welded.json") -> void:
	# Read JSON, and get tags
	var file = FileAccess.open(json_path, FileAccess.READ)
	var parse_text = JSON.parse_string(file.get_as_text())
	var tags = parse_text["tags"]

	# set data for each tag in the list
	for i in range(len(tags)):
		# get april_tag scene
		var tag_scene = load("res://scenes/april_tag.tscn")
		var tag_instance = tag_scene.instantiate()
		
		tag_instance.name = str(i)
		tag_instance.position = Vector3(
			tags[i]["pose"]["translation"]["x"],
			tags[i]["pose"]["translation"]["z"],
			tags[i]["pose"]["translation"]["y"]
		)

		# rotation
		var w = tags[i]["pose"]["rotation"]["quaternion"]["W"]
		var x = tags[i]["pose"]["rotation"]["quaternion"]["X"]
		var y = tags[i]["pose"]["rotation"]["quaternion"]["Y"]
		var z = tags[i]["pose"]["rotation"]["quaternion"]["Z"]
		var quat = Basis(Quaternion(w, x, y, z)) # wrong, but it works?
		tag_instance.transform.basis = quat

		# flip x and y, and rotate 90
		var temp_x = tag_instance.rotation.y
		tag_instance.rotation.y = tag_instance.rotation.x + deg_to_rad(90)
		tag_instance.rotation.x = temp_x
		tag_directory.add_child(tag_instance)
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if robot_collision.has_overlapping_bodies():
		print("rejected")
		camera_attributes_index_focus = 0
		move_robot()
		update_raycasts_for_next_iteration(camera_attributes[camera_attributes_index_focus])
		return
		
	var current_camera_attribute = camera_attributes[camera_attributes_index_focus]
	var unblocked_tags = filter_tags_by_raycast()
	var tags_within_view_angle = filter_tags_by_cam_view_angle(current_camera_attribute, unblocked_tags)
	var tags_within_distance = filter_tags_by_distance(current_camera_attribute, tags_within_view_angle)	
	var tags_within_tag_angle = filter_tags_by_tag_angle(current_camera_attribute, tags_within_distance)

	camera_attributes_index_focus += 1
	if (camera_attributes_index_focus >= len(camera_attributes)):
		camera_attributes_index_focus = 0
		move_robot()

	update_raycasts_for_next_iteration(camera_attributes[camera_attributes_index_focus])
	

## because you can't force update a raycast safely
## this will just update the positions for the next camera, and let godot handle it
func update_raycasts_for_next_iteration(next_camera_attribute: Node3D) -> void:
	for tag in tag_directory.get_children():
		#tag.visible = true
		for marker_name in tag_points:
			var marker = tag.get_node(marker_name)
			var ray_cast = marker.get_node("RayCast3D")
			ray_cast.target_position = ray_cast.to_local(next_camera_attribute.global_position)
	
	camera_3d.position = camera_attributes[camera_attributes_index_focus].global_position
	camera_3d.rotation.y = camera_attributes[camera_attributes_index_focus].global_rotation.y - deg_to_rad(90)
	camera_3d.rotation.x = camera_attributes[camera_attributes_index_focus].global_rotation.z 
		
## gives a list of the tags that are not blocked by anything
## doesn't need camera attribute as the raycasts have been already handled by update_raycasts_for_next_iteration
func filter_tags_by_raycast() -> Array[Node3D]:
	var unblocked_april_tags: Array[Node3D] = []
	
	# get every tag in the tag directory in the camera
	for tag in tag_directory.get_children():
		# for each corner of the april tag scene
		var see_all_four_corners = true
		for marker_name in tag_points:
			var marker = tag.get_node(marker_name)
			var ray_cast = marker.get_node("RayCast3D")
			
			if ray_cast.is_colliding():
				see_all_four_corners = false
			
		if see_all_four_corners:
			unblocked_april_tags.append(tag)
			tag.visible = true
		else:
			tag.visible = true
	
	return unblocked_april_tags

## get the tags that are within view angles
func filter_tags_by_cam_view_angle(camera_attribute: Node3D, tags: Array[Node3D]) -> Array[Node3D]:
	# horizontal
	var tags_in_h_view: Array[Node3D] = []
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
			tags_in_h_view.append(tag)
		else:
			tag.visible = true
	
	camera_3d.fov = camera_fov_degrees # for debug, to show what camera could be seeing in view port
	return tags_in_h_view

func filter_tags_by_distance(camera_attribute: Node3D, tags: Array[Node3D]) -> Array[Node3D]:
	var tags_within_range: Array[Node3D] = []
	
	for tag in tags:
		if camera_attribute.global_position.distance_to(tag.global_position) < max_distance:
			tag.visible = true
			tags_within_range.append(tag)
		else:
			tag.visible = true 
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
			tag.visible = true 
		
	
	return tags_within_angle

func move_robot():
	var new_rot: float = camera_directory.global_rotation_degrees.y + rotation_increment_degrees
	if new_rot < 180.0 - rotation_increment_degrees: 
		camera_directory.global_rotation_degrees.y += rotation_increment_degrees
		return
	camera_directory.global_rotation.y = -PI + 0.0001 # reset rotation after it completes a full rotation
	
	camera_directory.global_position.x += position_translation_increment.x
	if camera_directory.global_position.x < field_dimentions_meters.x: return
	camera_directory.global_position.x = 0.0

	camera_directory.global_position.z += position_translation_increment.y
	if camera_directory.global_position.z < field_dimentions_meters.y: return
	camera_directory.global_position.z = 0.0
	print("completed full cycle")
	
