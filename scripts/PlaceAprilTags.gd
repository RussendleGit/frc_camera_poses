extends Node3D


func _ready() -> void:
	get_positions("2026-rebuilt-welded.json")


func get_positions(json_path: String):
	var file = FileAccess.open(json_path, FileAccess.READ)
	var parse_text = JSON.parse_string(file.get_as_text())
	var tags = parse_text["tags"]

	for i in range(len(tags)):
		var tag_scene = load("res://scenes/april_tag.tscn")
		var tag_instance = tag_scene.instantiate()
		add_child(tag_instance)
		tag_instance.name = str(i)
		tag_instance.position = Vector3(
			tags[i]["pose"]["translation"]["x"],`
			tags[i]["pose"]["translation"]["z"],
			tags[i]["pose"]["translation"]["y"]
		)

		var w = tags[i]["pose"]["rotation"]["quaternion"]["W"]
		var x = tags[i]["pose"]["rotation"]["quaternion"]["X"]
		var y = tags[i]["pose"]["rotation"]["quaternion"]["Y"]
		var z = tags[i]["pose"]["rotation"]["quaternion"]["Z"]
		var quat = Basis(Quaternion(w, x, y, z))
		tag_instance.transform.basis = quat

		var temp_x = tag_instance.rotation.y
		tag_instance.rotation.y = tag_instance.rotation.x + deg_to_rad(90)
		tag_instance.rotation.x = temp_x
