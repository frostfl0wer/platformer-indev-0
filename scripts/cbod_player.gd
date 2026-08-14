extends CharacterBody2D
#one goal of this node is to replicatable so when i change scenes i can just add it again

var coyote_time_active=false

func _physics_process(delta: float) -> void:
	#speed cap
	cap()
	#gravity
	Auto.apply_force(self, delta, 0, Auto.gravity)
	
	
	#------------------------------------------------------------------------------------------------------------
	#x movement
	if Input.is_action_pressed("left"):
		Auto.apply_force(self, delta, -Auto.pl_speed, 0)
		if velocity.x>0:#apply extra force when turning to the right
			Auto.apply_force(self, delta, -Auto.pl_speed*2, 0)
		
	if Input.is_action_pressed("right"):
		Auto.apply_force(self, delta, Auto.pl_speed, 0)
		if velocity.x<0:#apply extra force when turning to the left
			Auto.apply_force(self, delta, Auto.pl_speed*2, 0)
		
	if !Input.is_action_pressed("left") and !Input.is_action_pressed("right") and Auto.pl_state == "grounded":
		@warning_ignore("narrowing_conversion") Auto.apply_force(self, delta, -velocity.x*10, 0)
		#speed truncation
		trunc_x_vel()
	
	
	
	if Auto.pl_state == "airborne":
		velocity=velocity*.99
	
	
	#------------------------------------------------------------------------------------------------------------
	#y movement
	#(dont read this if statement it just raycasts to the bottom corners of the player hitbox to see if either side is grounded)
	if Auto.cast(get_world_2d(), position, Vector2(position.x+$col_player.shape.size.x/2, position.y+$col_player.shape.size.y/2+0.1)) or Auto.cast(get_world_2d(), position, Vector2(position.x-$col_player.shape.size.x/2, position.y+$col_player.shape.size.y/2+0.1)): 
		Auto.pl_state="grounded"
		Auto.pl_coyote_state="grounded"
	else:
		Auto.pl_state="airborne"
	
	if Input.is_action_just_pressed("jump") and Auto.pl_state=="grounded":
		velocity.y+=Auto.pl_jump_height
	if Auto.pl_state=="airborne" and !Input.is_action_pressed("jump") and velocity.y<0:#decelerate jump when you dont hold the spacebar
		@warning_ignore("narrowing_conversion") Auto.apply_force(self, delta, 0, -velocity.y*10)
	
	
	#------------------------------------------------------------------------------------------------------------
	#wall sliding (right)
	#raycasts to the top and bottom right of the player hitbox
	if Auto.pl_state=="airborne" and Input.is_action_pressed("right") and Auto.cast(get_world_2d(), position, Vector2(position.x+$col_player.shape.size.x/2+0.1, position.y+$col_player.shape.size.y/2)) and Auto.cast(get_world_2d(), position, Vector2(position.x+$col_player.shape.size.x/2+0.1, position.y-$col_player.shape.size.y/2)):
		Auto.pl_state="wall_sliding_r"
		Auto.pl_coyote_state="wall_sliding_r"
	
	if Auto.pl_state=="wall_sliding_r":
		if velocity.y>0:
			velocity.y=Auto.pl_wall_slide_speed
		if Input.is_action_just_pressed("jump"):
			velocity.y+=Auto.pl_jump_height
			velocity.x+= -Auto.pl_speed+20
	#wall sliding (left)
	#raycasts to the top and bottom left of the player hitbox
	if Auto.pl_state=="airborne" and Input.is_action_pressed("left") and Auto.cast(get_world_2d(), position, Vector2(position.x-$col_player.shape.size.x/2-0.1, position.y+$col_player.shape.size.y/2)) and Auto.cast(get_world_2d(), position, Vector2(position.x-$col_player.shape.size.x/2-0.1, position.y-$col_player.shape.size.y/2)):
		Auto.pl_state="wall_sliding_l"
		Auto.pl_coyote_state="wall_sliding_l"
	
	if Auto.pl_state=="wall_sliding_l":
		if velocity.y>0:
			velocity.y=Auto.pl_wall_slide_speed
		if Input.is_action_just_pressed("jump"):
			velocity.y+=Auto.pl_jump_height
			velocity.x+= Auto.pl_speed-20
	
	#if Auto.cast(get_world_2d(), position, Vector2(position.x+$col_player.shape.size.x/2+0.1, position.y+$col_player.shape.size.y/2)) and not Auto.cast(get_world_2d(), position, Vector2(position.x+$col_player.shape.size.x/2+0.1, position.y-$col_player.shape.size.y/2)):
		#velocity=Vector2.ZERO
	
	#------------------------------------------------------------------------------------------------------------
	#coyote state
	#starts coyote_timer for different times depending on the state (ok i admit it i have no idea what i'm doing with this but whatever it works and it seems nicely scalable)
	if Auto.pl_coyote_state != Auto.pl_state and not coyote_time_active:
		match Auto.pl_coyote_state:
			"wall_sliding_l":
				coyote_timer(0.3)
			"wall_sliding_r":
				coyote_timer(0.3)
			"grounded":
				coyote_timer(0.1)
	#executes coyote actions during the coyote time
	if coyote_time_active:
		match Auto.pl_coyote_state:
			"wall_sliding_l":
				if Input.is_action_just_pressed("jump"):
					velocity.y=Auto.pl_wall_slide_speed
					velocity.y+=Auto.pl_jump_height
					velocity.x+= Auto.pl_speed-100
			"wall_sliding_r":
				if Input.is_action_just_pressed("jump"):
					velocity.y=Auto.pl_wall_slide_speed
					velocity.y+=Auto.pl_jump_height
					velocity.x+= -Auto.pl_speed+100
			"grounded":
				if Input.is_action_just_pressed("jump"):
					velocity.y+=Auto.pl_jump_height
	
	print(Auto.pl_state)
	
	move_and_slide()

#------------------------------------------------------------------------------------------------------------
#used for debugging raycasting
func _draw() -> void:
	#getupt raycasts r
	draw_line(position, Vector2(position.x+$col_player.shape.size.x/2, position.y), Color.RED)
	
	#sliding raycasts r
	draw_line(position, Vector2(position.x+$col_player.shape.size.x/2+0.1, position.y+$col_player.shape.size.y/2), Color.WHITE)
	draw_line(position, Vector2(position.x+$col_player.shape.size.x/2+0.1, position.y-$col_player.shape.size.y/2), Color.WHITE)
	#sliding raycasts l
	draw_line(position, Vector2(position.x-$col_player.shape.size.x/2+0.1, position.y+$col_player.shape.size.y/2), Color.WHITE)
	draw_line(position, Vector2(position.x-$col_player.shape.size.x/2+0.1, position.y-$col_player.shape.size.y/2), Color.WHITE)
	
	#grounded raycasts
	draw_line(position, Vector2(position.x+$col_player.shape.size.x/2, position.y+$col_player.shape.size.y/2), Color.GREEN)
	draw_line(position, Vector2(position.x-$col_player.shape.size.x/2, position.y+$col_player.shape.size.y/2), Color.GREEN)
	pass

#------------------------------------------------------------------------------------------------------------
#timer which handles coyote time
func coyote_timer(time):
	#print("timer start")
	coyote_time_active=true
	await get_tree().create_timer(time).timeout
	Auto.pl_coyote_state=Auto.pl_state
	coyote_time_active=false
	#print("timer stop")

#------------------------------------------------------------------------------------------------------------
#truncate x velocity
func trunc_x_vel():
	if velocity.x < 20 and velocity.x > -20:
		velocity.x=0

#------------------------------------------------------------------------------------------------------------
#speed cap
func cap():
	if velocity.x > Auto.pl_x_vel_cap:
		velocity.x=Auto.pl_x_vel_cap
	if velocity.x < -Auto.pl_x_vel_cap:
		velocity.x= -Auto.pl_x_vel_cap
