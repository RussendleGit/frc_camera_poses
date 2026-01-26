extends Node3D

@onready var label_3d: Label3D = $Label3D

@export var skew_yaw: float = 0.0
@export var skew_pitch: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label_3d.text = name
