extends Node3D

@onready var camera_3d: Camera3D = $"../Camera3D"

@export var camera_fov_degrees: float = 100.0

@export var max_distance: float = 200.0 / 39.37
@export var max_tag_angle_to_cam: float = 80

@onready var camera_attributes: Array[Node3D] = []
@onready var tag_points = ["MarkerUR", "MarkerUL", "MarkerDR", "MarkerDL"]
@onready var tag_directory: Node3D = $TagDirectory
var camera_attributes_index_focus: int = 0
 
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_april_tags()
	add_camera(Vector3(2.0, 2.0, 0.0), Vector3(0.0, -45.0, 20.0))
	add_camera(Vector3(9.0, 7.0, 0.0), Vector3(0.0, 45.0, 20.0))
	for i in range(len(camera_attributes)):
		camera_attributes[i].name = str(i)
		add_child(camera_attributes[i])
	update_raycasts_for_next_iteration(camera_attributes[camera_attributes_index_focus])


## adds a camera, also flips y and z for ease of use
func add_camera(cam_position_meters: Vector3, cam_rotation_degrees: Vector3) -> void:
	var camera_scene = load("res://scenes/camera_marker.tscn")
	var cam_instance = camera_scene.instantiate()
	cam_instance.position = Vector3(cam_position_meters.x, cam_position_meters.z, cam_position_meters.y)
	cam_instance.rotation_degrees = cam_rotation_degrees 
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
	# all can be done within for loop, and maybe there should be multiple cameras, so that there can be just one set of tags
	print("camera: ", camera_attributes[camera_attributes_index_focus].name)
	var unblocked_tags = filter_tags_by_raycast()
	print(unblocked_tags)
	print()
	var tags_within_view_angle = filter_tags_by_cam_view_angle(camera_attributes[camera_attributes_index_focus], unblocked_tags)
	print(tags_within_view_angle)
	print()
	var tags_within_distance = filter_tags_by_distance(camera_attributes[camera_attributes_index_focus], tags_within_view_angle)
	print(tags_within_distance)
	print()
	var tags_within_tag_angle = filter_tags_by_tag_angle(camera_attributes[camera_attributes_index_focus], tags_within_distance)
	print(tags_within_tag_angle)	
	print()

	camera_attributes_index_focus += 1
	if (camera_attributes_index_focus >= len(camera_attributes)):
		camera_attributes_index_focus = 0
	update_raycasts_for_next_iteration(camera_attributes[camera_attributes_index_focus])
	
	

## because you can't force update a raycast safely
## this will just update the positions for the next camera, and let godot handle it
func update_raycasts_for_next_iteration(next_camera_attribute: Node3D) -> void:
	for tag in tag_directory.get_children():
		tag.visible = true
		for marker_name in tag_points:
			var marker = tag.get_node(marker_name)
			var ray_cast = marker.get_node("RayCast3D")
			ray_cast.target_position = ray_cast.to_local(next_camera_attribute.position)
	
	camera_3d.position = camera_attributes[camera_attributes_index_focus].position
	camera_3d.rotation.y = camera_attributes[camera_attributes_index_focus].rotation.y - deg_to_rad(90)
	camera_3d.rotation.x = camera_attributes[camera_attributes_index_focus].rotation.z 
		
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
	
	return unblocked_april_tags

## get the tags that are within view angles
func filter_tags_by_cam_view_angle(camera_attribute: Node3D, tags: Array[Node3D]) -> Array[Node3D]:
	# horizontal
	var tags_in_h_view: Array[Node3D] = []
	for tag in tags:
		var direction = tag.position - camera_attribute.position
		
		# get 2d values for x, and z
		var direction_2d_yaw = Vector2(direction.x, direction.z)
		var direction_2d_pitch = Vector2(direction.x, direction.y)
		
		# get the angle between the tags
		var angle_yaw = direction_2d_yaw.angle()
		var angle_pitch = direction_2d_pitch.angle()
		
		# account rotation of marker
		var angle_diff_yaw = wrapf(angle_yaw + camera_attribute.rotation.y, -PI, PI)
		var angle_diff_pitch = wrapf(angle_pitch + camera_attribute.rotation.z, -PI, PI)
		
		if abs(angle_diff_yaw) <= deg_to_rad(camera_fov_degrees) && abs(angle_diff_pitch) <= deg_to_rad(camera_fov_degrees):
			tags_in_h_view.append(tag)
	
	camera_3d.fov = camera_fov_degrees # for debug, to show what camera could be seeing in view port
	return tags_in_h_view

func filter_tags_by_distance(camera_attribute: Node3D, tags: Array[Node3D]) -> Array[Node3D]:
	var tags_within_range: Array[Node3D] = []
	
	for tag in tags:
		if camera_attribute.position.distance_to(tag.position) < max_distance:
			tags_within_range.append(tag)
		else:
			tag.visible = false # for debug, to show what the camera isn't seeing
	return tags_within_range		

func filter_tags_by_tag_angle(camera_attribute: Node3D, tags: Array[Node3D]) -> Array[Node3D]:
	var tags_within_angle: Array[Node3D] = []
	
	for tag in tags:
		# take away 90 from yaw, because that's the default rotation for april tags
		var yaw = wrapf((tag.rotation.y - deg_to_rad(90.0)) - camera_attribute.rotation.y, -PI, PI)
		var pitch = wrapf(tag.rotation.z - camera_attribute.rotation.z, -PI, PI)

		if abs(yaw) <= deg_to_rad(max_tag_angle_to_cam) && abs(pitch) <= deg_to_rad(max_tag_angle_to_cam):
			tags_within_angle.append(tag)
		else:
			tag.visible = false # for debug, to show what the camera isn't seeing
		
	
	return tags_within_angle
