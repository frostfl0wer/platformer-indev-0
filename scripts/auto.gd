extends Node

var gravity = 800
var cam_mode = "follow"

func _process(_delta: float) -> void:
	if Input.is_action_pressed("quit"):
		get_tree().quit()
	#Engine.max_fps=10

#casts a ray
#NOTE: world = get_world_2d() which should be accessable from where this function is called
func cast(world:World2D, from:Vector2, to:Vector2, exclude=[self]):
	var space_state = world.direct_space_state
	var query = PhysicsRayQueryParameters2D.create(from, to)
	query.exclude = exclude#keep in array type
	return space_state.intersect_ray(query)
