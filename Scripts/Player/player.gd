extends CharacterBody2D

const SPEED = 100.0
const JUMP_POWER = -900.0
const GRAVITY = 1000.0

const FRICTION = 1000.0
const WALL_JUMP_PUSHBACK = 400.0
const WALL_SLIDE_SPEED = 100.0

var is_wall_sliding = false

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_movement(delta)


func apply_gravity(delta: float) -> void:
	if !is_on_floor() and !is_wall_sliding:
		velocity.y += GRAVITY * delta

func handle_movement(delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	var applied_horizontal_friction = 0
	if direction:
		velocity.x = direction * SPEED * 4
		applied_horizontal_friction = 0
	else:
		if(is_on_floor()):
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
			applied_horizontal_friction = FRICTION
	
	
	if(applied_horizontal_friction > 0):
		print_debug("friction is being applied")
	handle_jump()
	move_and_slide()
	
func handle_jump() -> void:
	if Input.is_action_pressed("ui_up"):
		if is_on_floor():
			velocity.y = JUMP_POWER
		elif is_on_wall_only():
			for i in range(get_slide_collision_count()):
				var collision = get_slide_collision(i)
				var normal = collision.get_normal()
				if normal.x > 0:
					#wall on left
					velocity.x = WALL_JUMP_PUSHBACK
					velocity.y = JUMP_POWER
				elif normal.x < 0:
					#wall on right
					velocity.x = -WALL_JUMP_PUSHBACK
					velocity.y = JUMP_POWER

#func detect_wall_direction() -> int:
	
