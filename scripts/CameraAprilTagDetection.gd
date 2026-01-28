extends Node3D



@export var num_poses_grid: Vector2 = Vector2(20.0, 20.0)
@export var rotation_increment_degrees: float = 22.5
@export var camera_translation_increment: float = 0.1
@export var field_dimensions_meters: Vector2 = Vector2(16.540988, 8.069326)
@export var tests: int = 1

@onready var tag_directory: Node3D = $TagDirectory
@onready var camera_directory: Node3D = $CameraDirectory
@onready var allowed_areas: Node3D = $AllowedAreas
@onready var robot_collision: Area3D = $CameraDirectory/RobotCollision
@onready var database: Node = $Database



var position_translation_increment: Vector2
var num_camera_changes: int = 0
var data: Array = []

func _ready() -> void:
	position_translation_increment = Vector2(
		(field_dimensions_meters.x / 2.0) / num_poses_grid.x, 
		field_dimensions_meters.y / num_poses_grid.y
	)
	tag_directory.set_april_tags()

	camera_directory.add_camera(Vector3(0.0, -0.2, 0.4), Vector3(0.0, 15.0, 30.0)) 
	camera_directory.add_camera(Vector3(0.0, 0.2, 0.4), Vector3(0.0, 15.0, -30.0)) 
	camera_directory.add_camera(Vector3(0.0, 0.0, 0.4), Vector3(0.0, 0.0, 0.0)) 
	camera_directory.setup_cameras()
	database.new_test(camera_directory.camera_attributes)

	tag_directory.update_raycasts_for_next_iteration(camera_directory.get_current_camera())



func _process(delta: float) -> void:
	if robot_collision.has_overlapping_bodies():
		move_robot()
		tag_directory.update_raycasts_for_next_iteration(camera_directory.get_current_camera())
		camera_directory.skip_current_iteration()
		return
		
	var unblocked_tags = camera_directory.filter_april_tags(tag_directory.get_all_tags())
	database.add_measurement(camera_directory.get_current_camera(), camera_directory, unblocked_tags)

	# determine if all the cameras have been processed. If so, test for the next pose
	var is_reset = camera_directory.next_camera()
	if is_reset:
		move_robot()

	tag_directory.update_raycasts_for_next_iteration(camera_directory.get_current_camera())

## moves the robot based off it's current position
## starts by rotating, 
## if it has made a full revolution, then change it's position x, back to rotating again
## if it has gone through all the x positions, then it will translate it's y position
func move_robot():
	var new_rot: float = camera_directory.global_rotation_degrees.y + rotation_increment_degrees
	if new_rot < 180.0 - rotation_increment_degrees: 
		camera_directory.global_rotation_degrees.y += rotation_increment_degrees
		return
	camera_directory.global_rotation.y = -PI + 0.0001 # reset rotation after it completes a full rotation
	
	camera_directory.global_position.x += position_translation_increment.x
	if camera_directory.global_position.x < (field_dimensions_meters.x / 2.0) + (position_translation_increment.x / 2.0): return
	camera_directory.global_position.x = 0.0

	camera_directory.global_position.z += position_translation_increment.y
	if camera_directory.global_position.z < field_dimensions_meters.y + (position_translation_increment.y / 2.0): return
	camera_directory.global_position.z = 0.0
	num_camera_changes += 1
	
	if num_camera_changes >= tests:
		database.save(true)
		
	
	database.new_test(camera_directory.camera_attributes)
	
