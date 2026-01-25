extends Node3D


@export var cam_position_inches: Vector3
@export var cam_rotation_degrees: Vector3
@export var vertical_view_angle_degrees: float = 45
@export var horizontal_view_angle_degrees: float = 45
@export var max_distance: float = 200.0 / 39.37
var vertical_view_angle_rad: float
var horizontal_view_angle_rad: float

@onready var tag_points = ["MarkerUR", "MarkerUL", "MarkerDR", "MarkerDL"]
@onready var tag_directory: Node3D = $TagDirectory
@onready var camera_marker: Marker3D = get_node("CameraMarker") 
 
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_april_tags()



## When initializing the camera, this creates the needed april tags
func set_april_tags(json_path: String = "2026-rebuilt-welded.json"):
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
		var quat = Basis(Quaternion(w, x, y, z))
		tag_instance.transform.basis = quat

		# flip x and y, and rotate 90
		var temp_x = tag_instance.rotation.y
		tag_instance.rotation.y = tag_instance.rotation.x + deg_to_rad(90)
		tag_instance.rotation.x = temp_x
		tag_directory.add_child(tag_instance)
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# all can be done within for loop, and maybe there should be multiple cameras, so that there can be just one set of tags
	var unblocked_tags = filter_tags_by_raycast()
	var tags_within_view_angle = filter_tags_by_angle(unblocked_tags)
	var tags_within_distance = filter_tags_by_distance(tags_within_view_angle)
	print(tags_within_distance)	
	print()

## updates the raycasts, gives a list of the tags that are not blocked by anything
func filter_tags_by_raycast() -> Array[Node3D]:
	var unblocked_april_tags: Array[Node3D] = []

	# get every tag in the tag directory in the camera
	for tag in tag_directory.get_children():
		# for each corner of the april tag scene
		var see_all_four_corners = true
		for marker_name in tag_points:
			var marker = tag.get_node(marker_name)
			var ray_cast = marker.get_node("RayCast3D")
			ray_cast.target_position = ray_cast.to_local(camera_marker.position)
			
			if ray_cast.is_colliding():
				see_all_four_corners = false
			
		if see_all_four_corners:
			unblocked_april_tags.append(tag)
	
	return unblocked_april_tags

## get the tags that are within view angles
func filter_tags_by_angle(tags: Array[Node3D]) -> Array[Node3D]:
	# horizontal
	var tags_in_h_view: Array[Node3D] = []
	for tag in tags:
		var direction = tag.position - camera_marker.position
		
		# get 2d values for x, and z
		var direction_2d_yaw = Vector2(direction.x, direction.z)
		var direction_2d_pitch = Vector2(direction.x, direction.y)
		
		# get the angle between the tags
		var angle_yaw = direction_2d_yaw.angle()
		var angle_pitch = direction_2d_pitch.angle()
		
		# account rotation of marker
		var angle_diff_yaw = wrapf(angle_yaw + camera_marker.rotation.y, -PI, PI)
		var angle_diff_pitch = wrapf(angle_pitch + camera_marker.rotation.z, -PI, PI)
		
		if abs(angle_diff_yaw) <= deg_to_rad(horizontal_view_angle_degrees) && abs(angle_diff_pitch) <= deg_to_rad(vertical_view_angle_degrees):
			tags_in_h_view.append(tag)
	
	return tags_in_h_view

func filter_tags_by_distance(tags: Array[Node3D]) -> Array[Node3D]:
	var tags_within_range: Array[Node3D] = []
	
	for tag in tags:
		if camera_marker.position.distance_to(tag.position) < max_distance:
			tags_within_range.append(tag)

	return tags_within_range		

	
