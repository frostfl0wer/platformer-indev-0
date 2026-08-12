extends Camera2D

@export var target: Node
@export var ready_position: Vector2

func _process(_delta: float) -> void:
	if Auto.cam_mode == "follow":
		position.x = target.position.x
		position.y = target.position.y
	else:
		position = ready_position
