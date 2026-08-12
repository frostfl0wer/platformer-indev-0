extends CharacterBody2D
#one goal of this node is to replicatable so when i change scenes i can just add it again

func _physics_process(delta: float) -> void:
	#speed cap
	cap()
	#gravity
	Auto.apply_force(self, delta, 0, Auto.gravity)
	
	#x movement
	if Input.is_action_pressed("left"):
		Auto.apply_force(self, delta, -Auto.pl_speed, 0)
		if velocity.x>0:#apply extra force when turning to the right
			Auto.apply_force(self, delta, -Auto.pl_speed*2, 0)
		
	if Input.is_action_pressed("right"):
		Auto.apply_force(self, delta, Auto.pl_speed, 0)
		if velocity.x<0:#apply extra force when turning to the left
			Auto.apply_force(self, delta, Auto.pl_speed*2, 0)
		
	if !Input.is_action_pressed("left") and !Input.is_action_pressed("right"):
		@warning_ignore("narrowing_conversion") Auto.apply_force(self, delta, -velocity.x*3, 0)
		#speed truncation
		trunc_x_vel()
	
	
	#y movement
	#(dont read this if statement it just raycasts to the bottom corners of the player hitbox to see if either side is grounded)
	if Auto.cast(get_world_2d(), Vector2(position.x, position.y), Vector2(position.x+$col_player.shape.size.x/2, position.y+$col_player.shape.size.y/2+0.1)) or Auto.cast(get_world_2d(), Vector2(position.x, position.y), Vector2(position.x-$col_player.shape.size.x/2, position.y+$col_player.shape.size.y/2+0.1)): 
		Auto.pl_grounded=true
	else:
		Auto.pl_grounded=false
	
	if Input.is_action_just_pressed("jump") and Auto.pl_grounded:
		velocity.y+=Auto.pl_jump_height
	if !Auto.pl_grounded and !Input.is_action_pressed("jump") and velocity.y<0:#decelerate jump when you dont hold the spacebar
		@warning_ignore("narrowing_conversion") Auto.apply_force(self, delta, 0, -velocity.y*10)
	
	
	
	
	move_and_slide()
	print(Auto.pl_grounded)


#used for debugging raycasting
func _draw() -> void:
	draw_line(Vector2(position.x, position.y), Vector2(position.x+$col_player.shape.size.x/2, position.y+$col_player.shape.size.y/2), Color.GREEN)
	draw_line(Vector2(position.x, position.y), Vector2(position.x-$col_player.shape.size.x/2, position.y+$col_player.shape.size.y/2), Color.GREEN)
	pass

#truncate x velocity
func trunc_x_vel():
	if velocity.x < 10 and velocity.x > -10:
		velocity.x=0

#speed cap
func cap():
	if velocity.x > Auto.pl_x_vel_cap:
		velocity.x=Auto.pl_x_vel_cap
	if velocity.x < -Auto.pl_x_vel_cap:
		velocity.x= -Auto.pl_x_vel_cap
