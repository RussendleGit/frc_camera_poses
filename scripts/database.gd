extends Node

var database: SQLite = null

func setup_db():
	database = SQLite.new()
	database.path = "res://camera_data.sqlite"
	database.verbosity_level = SQLite.VERBOSE
	database.foreign_keys = true
	database.open_db()
	
	var test_runs_table: Dictionary = {
		"cam_pose_x": {"data_type": "real"},
		"cam_pose_y": {"data_type": "real"},
		"cam_pose_z": {"data_type": "real"},
		"cam_rot_x": {"data_type": "real"},
		"cam_rot_y": {"data_type": "real"},
		"cam_rot_z": {"data_type": "real"},
		"test_number": {
			"data_type": "int",
			"primary_key": true,
			"auto_increment": true
		},
	}
	
	database.create_table("test_runs", test_runs_table)

	var april_tag_measurements_table: Dictionary = {
		"test_num": {
		  "data_type": "int",
		  "foreign_key": "test_runs.test_number"
		},
		"skew_yaw": {"data_type": "real"},
		"skew_pitch": {"data_type": "real"},
		"distance": {"data_type": "real"}
	}
	database.create_table("april_tag_measurements", april_tag_measurements_table)

func add_camera(cam_pose: Vector3, cam_rot: Vector3):
	database.insert_row("test_runs", {
		"cam_pose_x": cam_pose.x,
		"cam_pose_y": cam_pose.z,
		"cam_pose_z": cam_pose.y,
		"cam_rot_x": cam_pose.x,
		"cam_rot_y": cam_pose.z,
		"cam_rot_z": cam_pose.y
	})
func close_db():
	database.close_db()
