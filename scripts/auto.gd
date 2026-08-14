extends Node

var gravity = 700
var cam_mode = "follow"

#player stats (prefix pl_)
var pl_speed = 300
var pl_x_vel_cap = 3000

var pl_jump_height = -320
var pl_wall_slide_speed = 40

var pl_state:String = ""
var pl_coyote_state:String = ""

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

#applies force to target body with builtin (or defined i guess) velocity.x and velocity.y
func apply_force(target, delta, forcex=0, forcey=0):
	target.velocity.x+=forcex*delta
	target.velocity.y+=forcey*delta
