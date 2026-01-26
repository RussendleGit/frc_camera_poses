extends Node3D

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
		add_child(tag_instance)