extends CharacterBody2D
#one goal of this node is to replicatable so when i change scenes i can just add it again

#player stats
enum States {IDLE, RUN, JUMP, FALL, SLIDE, WALLKICK, WALLBOUNCE}

var deceleration := 2000
var acceleration := 1000
var speed:=100
var jump_vel := -200
var wallkick_vel := 230
var max_wallslide_speed:=300
var input_direction := 1
var state: States = States.FALL

var jump_buffer_timer = Timer.new()
const JUMP_BUFFER_TIME:=0.1

var coyote_timer = Timer.new()
const COYOTE_TIME:=0.1

var slide_coyote_timer = Timer.new()
const SLIDE_COYOTE_TIME:=0.1

var wall_col_dir:=""

#func _draw() -> void:
	#draw_line(position, Vector2(position.x+$col_player.shape.size.x/2+3, position.y), Color.GREEN)
	#draw_line(position, Vector2(position.x-$col_player.shape.size.x/2-3, position.y), Color.GREEN)

func _ready() -> void:
	add_child(jump_buffer_timer)
	jump_buffer_timer.one_shot = true
	add_child(coyote_timer)
	coyote_timer.one_shot = true
	add_child(slide_coyote_timer)
	slide_coyote_timer.one_shot=true

#state machine tutorial used: https://www.gdquest.com/tutorial/godot/design-patterns/finite-state-machine/
func _physics_process(delta: float) -> void:
	get_input_direction()
	
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer.start(JUMP_BUFFER_TIME)
	var jump_queued = not jump_buffer_timer.is_stopped()
	var slide_coyote_time_active = not slide_coyote_timer.is_stopped()
	var coyote_time_active = not coyote_timer.is_stopped()
	var horiz_movement := Input.is_action_pressed("left") or Input.is_action_pressed("right")
	
	#states are detected based on inputs, sensors built into CharacterBody2D, and most importantly, the state the player is currently in
	if is_on_floor():
		if state in [States.RUN, States.IDLE, States.JUMP] and jump_queued:
			state_init(States.JUMP)
		elif (state in [States.IDLE, States.FALL, States.SLIDE]) and horiz_movement:
			state_init(States.RUN)
		elif state in [States.RUN, States.FALL, States.SLIDE] and not horiz_movement:
			state_init(States.IDLE)
	if not is_on_floor():
		if (state in [States.JUMP, States.RUN, States.IDLE, States.WALLKICK, States.WALLBOUNCE]) and (velocity.y >= 0 or Input.is_action_just_released("jump")):
			state_init(States.FALL)
		if (state in [States.SLIDE] and (not is_on_wall() or get_input_direction()==0)):#from Sliding state needs a seperate boolean from the above if statement
			state_init(States.FALL)
		if (state in [States.FALL, States.SLIDE]) and coyote_time_active and jump_queued and get_wall_collision_direction()=="":
			state_init(States.JUMP)
		if (state in [States.FALL]) and slide_coyote_time_active and jump_queued and get_input_direction()!=0:
			state_init(States.WALLKICK)
	
	if is_on_wall():#NOTE: i programmed this with is_on_wall_only() so if something with slide state and its child jump states break, try switching this back to is_on_wall_only()
		if state in [States.FALL] and ((get_wall_collision_direction()=="left" and get_input_direction()==-1) or (get_wall_collision_direction()=="right" and get_input_direction()==1)):
			state_init(States.SLIDE)
		if state in [States.SLIDE] and (get_input_direction() and jump_queued):
			state_init(States.WALLKICK)
	if get_wall_collision_direction()!="":
		if state in [States.FALL] and (not get_input_direction() and Input.is_action_just_pressed("jump")):#hack around jump_queued because it would return true if you let go the spacebar fast enough and cause you to wallbounce without an input
			state_init(States.WALLBOUNCE)
	
	#actions are determined by the state
	if state==States.RUN:
		handle_horizontal_movement(delta)
	if state==States.IDLE:
		handle_horizontal_movement(delta)
	if state==States.FALL:
		handle_horizontal_movement(delta, true)
		velocity.y+=Auto.gravity*delta
	if state==States.JUMP:
		handle_horizontal_movement(delta, true)
		velocity.y+=Auto.gravity*delta
	if state==States.WALLKICK:
		handle_horizontal_movement(delta, true)
		velocity.y+=Auto.gravity*delta
	if state==States.WALLBOUNCE:
		handle_horizontal_movement(delta, true)
		velocity.y+=Auto.gravity*delta
	if state==States.SLIDE:
		handle_horizontal_movement(delta)
		velocity.y += Auto.gravity*delta/3
		#TODO: check if this is actually working/useful
		if velocity.y > max_wallslide_speed:
			velocity.y=max_wallslide_speed
	
	
	
	#print(state)
	#print(velocity.x)
	move_and_slide()


#call this instead of manually assigning the state variable, allowing for actions on state entrance/exit to be down here
#as opposed to clogging up the state detection code
func state_init(new_state) -> void:
	print("init", new_state)
	
	#on state entrance, executed once
	if new_state==States.FALL:
		velocity.y = move_toward(velocity.y, 0, -velocity.y*.5)
	if new_state==States.SLIDE:
		velocity.y= move_toward(velocity.y, 0, 100)
	if new_state==States.WALLKICK:
		handle_wallkick(get_wall_collision_direction(10))
		slide_coyote_timer.stop()
	if new_state==States.WALLBOUNCE:
		handle_wallkick(get_wall_collision_direction(), .75)
	if new_state==States.JUMP:
		velocity.y=jump_vel
		coyote_timer.stop()
	
	var prev_state=state
	state=new_state
	
	#on state exit, executed once
	if prev_state in [States.IDLE, States.RUN] and new_state in [States.FALL]:
		coyote_timer.start(COYOTE_TIME)
	if prev_state in [States.SLIDE] and new_state in [States.FALL]:
		slide_coyote_timer.start(SLIDE_COYOTE_TIME)


#handles horizontal movement accounting for input direction
func handle_horizontal_movement(delta: float, arial:bool=false) -> void:
	velocity.x = move_toward(velocity.x, speed*input_direction, acceleration*delta)
	
	if not input_direction and not arial:
		velocity.x = move_toward(velocity.x, 0, deceleration*delta)

func handle_wallkick(dir, modifier:=1.0):
	if dir=="right":
		velocity.y = jump_vel*.8
		velocity.x = -wallkick_vel*modifier
	elif dir=="left":
		velocity.y = jump_vel*.8
		velocity.x = wallkick_vel*modifier

#get wall_col_dir
func get_wall_collision_direction(dist:=3) -> String:
	if Auto.cast(get_world_2d(), position, Vector2(position.x+$col_player.shape.size.x/2+dist, position.y)):
		return "right"
	elif Auto.cast(get_world_2d(), position, Vector2(position.x-$col_player.shape.size.x/2-dist, position.y)):
		return "left"
	else:
		return ""

#assigns direction of input to input_direction variable as either -1:left, 0:none, or 1:right
#this function really should've returned that value instead, but for now I'm going to leave it
func get_input_direction() -> int:
	if Input.is_action_pressed("left"):
		input_direction=-1
		$animspr_player.flip_h=true
	elif Input.is_action_pressed("right"):
		input_direction=1
		$animspr_player.flip_h=false
	else:
		input_direction=0
	return input_direction
