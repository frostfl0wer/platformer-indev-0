extends CharacterBody2D
#one goal of this node is to replicatable so when i change scenes i can just add it again

#player stats
enum States {IDLE, RUN, JUMP, FALL}

var acceleration := 2000
var speed:=140
var jump_vel := -300
var input_direction := 1
var state: States = States.FALL

var jump_buffer_timer = Timer.new()
const JUMP_BUFFER_TIME:=0.1

var coyote_timer = Timer.new()
const COYOTE_TIME:=0.1

func _ready() -> void:
	add_child(jump_buffer_timer)
	jump_buffer_timer.one_shot = true
	add_child(coyote_timer)
	coyote_timer.one_shot = true

#state machine tutorial used: https://www.gdquest.com/tutorial/godot/design-patterns/finite-state-machine/
func _physics_process(delta: float) -> void:
	get_input_direction()
	
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer.start(JUMP_BUFFER_TIME)
	var jump_queued = not jump_buffer_timer.is_stopped()
	var coyote_time_active = not coyote_timer.is_stopped()
	
	#states are detected based on inputs, sensors built into CharacterBody2D, and most importantly, the state the player is currently in
	var horiz_movement := Input.is_action_pressed("left") or Input.is_action_pressed("right")
	if is_on_floor():
		if state in [States.RUN, States.IDLE, States.JUMP] and jump_queued:
			state_init(States.JUMP)
		elif (state in [States.IDLE, States.FALL]) and horiz_movement:
			state_init(States.RUN)
		elif state in [States.RUN, States.FALL] and not horiz_movement:
			state_init(States.IDLE)
	if not is_on_floor():
		if (state in [States.JUMP, States.RUN, States.IDLE]) and (velocity.y >= 0 or Input.is_action_just_released("jump")):
			state_init(States.FALL)
		if (state in [States.FALL]) and coyote_time_active and jump_queued:
			state_init(States.JUMP)
	
	#actions are determined by the state
	if state==States.RUN:
		handle_horizontal_movement(delta)
	if state==States.IDLE:
		handle_horizontal_movement(delta)
	if state==States.FALL:
		handle_horizontal_movement(delta)
		velocity.y+=Auto.gravity*delta
	if state==States.JUMP:
		handle_horizontal_movement(delta)
		velocity.y+=Auto.gravity*delta
	
	
	
	print(state)
	move_and_slide()


#call this instead of manually assigning the state variable, allowing for actions on state entrance/exit to be down here
#as opposed to clogging up the state detection code
func state_init(new_state) -> void:
	print("init", new_state)
	
	#on state entrance, executed once
	if new_state==States.JUMP:
		velocity.y = jump_vel
		coyote_timer.stop()
	if new_state==States.FALL:
		velocity.y = move_toward(velocity.y, 0, -velocity.y*.5)
	
	var prev_state=state
	state=new_state
	
	#on state exit, executed once
	if prev_state in [States.IDLE, States.RUN] and new_state in [States.FALL]:
		coyote_timer.start(COYOTE_TIME)


#handles horizontal movement accounting for input direction
func handle_horizontal_movement(delta: float) -> void:
	velocity.x += acceleration*input_direction*delta
	cap_x_vel()
	
	if not input_direction:
		velocity.x = move_toward(velocity.x, 0, acceleration*delta)


#caps x velocity to the player's speed
#this is important because acceleration needs to be way higher than speed for smooth acceleration to feel good
func cap_x_vel() -> void:
	if velocity.x>speed:
		velocity.x=speed
	if velocity.x<-speed:
		velocity.x= -speed

#assigns direction of input to input_direction variable as either -1:left, 0:none, or 1:right
#this function really should've returned that value instead, but for now I'm going to leave it
func get_input_direction() -> void:
	if Input.is_action_pressed("left"):
		input_direction=-1
	elif Input.is_action_pressed("right"):
		input_direction=1
	else:
		input_direction=0
