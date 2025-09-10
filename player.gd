extends CharacterBody2D

const SPEED = 200.0
const JUMP_POWER = -900.0
const GRAVITY = 1000.0

const FRICTION = 200.0
const WALL_JUMP_PUSHBACK = 400.0
const WALL_SLIDE_SPEED = 100.0

var is_wall_sliding = false

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_movement(delta)
	handle_jump()
	handle_wall_slide(delta)

	move_and_slide()

func apply_gravity(delta: float) -> void:
	if !is_on_floor() and !is_wall_sliding:
		velocity.y += GRAVITY * delta

func handle_movement(_delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * _delta)

func handle_jump() -> void:
	if Input.is_action_just_pressed("ui_up"):
		if is_on_floor():
			velocity.y = JUMP_POWER
	elif is_on_wall():
		velocity.y = JUMP_POWER
	if Input.is_action_pressed("ui_left"):
		velocity.x = WALL_JUMP_PUSHBACK
	else:velocity.x = -WALL_JUMP_PUSHBACK

func handle_wall_slide(_delta: float) -> void:
	is_wall_sliding = is_on_wall() and !is_on_floor() and velocity.y > 0
	if is_wall_sliding:
		velocity.y = min(velocity.y, WALL_SLIDE_SPEED)
