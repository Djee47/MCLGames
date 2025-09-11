extends CharacterBody2D

const SPEED = 100.0
const JUMP_POWER = -900.0
const GRAVITY = 1000.0

const FRICTION = 1000.0
const WALL_JUMP_PUSHBACK = 400.0
const WALL_SLIDE_SPEED = 100.0
const WALL_SLIDE_GRAVITY_START := 20.0  # very small gravity
const WALL_SLIDE_GRAVITY_MAX := GRAVITY  # full gravity after a while
const WALL_SLIDE_HOLD_TIME := 1
const WALL_SLIDE_ACCEL_TIME := WALL_SLIDE_HOLD_TIME + 2.5  # seconds to reach full gravity

var wall_slide_time: float = 0.0 
var is_wall_sliding = false
var wall_direction = 0.0

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_movement(delta)
	print(velocity.y)
	
#asda



func apply_gravity(delta: float) -> void:
	if is_wall_sliding:
		wall_slide_time += delta
		if wall_slide_time < WALL_SLIDE_HOLD_TIME:
			velocity.y = 0
		else:
			var t: float = clamp(wall_slide_time / WALL_SLIDE_ACCEL_TIME, 0.0, 1.0)
			var slide_gravity: float = lerp(WALL_SLIDE_GRAVITY_START, WALL_SLIDE_GRAVITY_MAX, t)
			velocity.y += slide_gravity * delta	
		if is_on_floor():
			is_wall_sliding = false
			wall_slide_time = 0.0
	else:
		wall_slide_time = 0.0
		if !is_on_floor():
			velocity.y += GRAVITY * delta

func handle_movement(delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	var applied_horizontal_friction = 0
	if direction:
		velocity.x = direction * SPEED * 4
		applied_horizontal_friction = 0
		
		if(is_on_wall_only()):
			for i in range(get_slide_collision_count()):
				var collision = get_slide_collision(i)
				var normal = collision.get_normal()
				wall_direction = normal.x
				if normal.x > 0:
					#wall on left
					if Input.is_action_pressed("ui_left"):
						is_wall_sliding = true
					if Input.is_action_pressed("ui_right"):
						is_wall_sliding = false
				elif normal.x < 0:
					#wall on right
					if Input.is_action_pressed("ui_left"):
						is_wall_sliding = false
					if Input.is_action_pressed("ui_right"):
						is_wall_sliding = true
	else:
		if(is_on_floor()):
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
			applied_horizontal_friction = FRICTION

	handle_jump()
	move_and_slide()
	
func handle_jump() -> void:
	if Input.is_action_pressed("ui_up"):
		#reset wal slide time
		wall_slide_time = 0.0
		if is_on_floor():
			velocity.y = JUMP_POWER
		elif !is_on_floor() && is_on_wall_only():
			#print("i am on floor? ", is_on_floor())
			if wall_direction > 0:
				#wall on left
				if Input.is_action_pressed("ui_left"):
					velocity.x = WALL_JUMP_PUSHBACK
					velocity.y = JUMP_POWER
			elif wall_direction  < 0:
				#wall on right
				if Input.is_action_pressed("ui_right"):
					velocity.x = -WALL_JUMP_PUSHBACK
					velocity.y = JUMP_POWER
	
#func detect_wall_direction() -> int:
	
