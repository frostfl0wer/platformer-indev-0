extends Camera2D

@export var target: Node

func _process(_delta: float) -> void:
	if Auto.cam_mode == "follow":
		position.x = target.position.x
