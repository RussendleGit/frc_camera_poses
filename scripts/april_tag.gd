extends Node3D

@onready var label_3d: Label3D = $Label3D

var tag_points = ["MarkerUR", "MarkerUL", "MarkerDR", "MarkerDL"]
var ray_casts: Array[Node] = []

@export var skew_yaw: float = 0.0
@export var skew_pitch: float = 0.0
@export var distance: float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label_3d.text = name

	for point in tag_points:
		var marker = get_node(point)
		var ray_cast = marker.get_node("RayCast3D")
		ray_casts.append(ray_cast)

func get_ray_casts() -> Array[Node]:
	return ray_casts
