extends Node


var all_data: Array = []
var current_test: Dictionary

func new_test(camera_attributes: Array[Node3D]):
	if !current_test.is_empty():
		all_data.append(current_test)
		
	current_test = {
		"Camera_attributes": [],
		"Results": {}
	}
	for cam in camera_attributes:
		current_test["Camera_attributes"].append({
			"name": cam.name,
			"tx": cam.global_position.x,
			"ty": cam.global_position.z,
			"tz": cam.global_position.y,
			"rx": cam.global_rotation.x,
			"ry": cam.global_rotation.z,
			"rz": cam.global_rotation.y
		})
		current_test["Results"][cam.name] = []

		print("Testing Camera pose, at translation: " + str(cam.global_position) + ", and rotation :" + str(cam.global_rotation))

func add_measurement(camera_attribute: Node3D, robot: Node3D, tags: Array[Node3D]):
	print("Testing Measurement at: " + str(robot.global_position) + ", and rotation :" + str(robot.global_rotation))
	var tag_data = []
	for tag in tags:
		tag_data.append({
			"tag_name": tag.name,
			"skew_yaw": tag.skew_yaw,
			"skew_pitch": tag.skew_pitch,
			"distance": tag.distance
			}
		)
	var measurement_data = {
		"robot position": {
			"tx": robot.global_position.x,
			"ty": robot.global_position.z,
			"tz": robot.global_position.y,
			"rx": robot.global_rotation.x,
			"ry": robot.global_rotation.z,
			"rz": robot.global_rotation.y
		},
		"tag_data": tag_data
	}
	current_test["Results"][camera_attribute.name].append(measurement_data)

func save():
	all_data.append(current_test)
	var file = FileAccess.open("res://results.json", FileAccess.WRITE)
	var json_string = JSON.stringify(all_data, "\t") 
	file.store_string(json_string)
	file.close()

