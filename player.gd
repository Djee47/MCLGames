extends CharacterBody2D

# === Movement Constants ===
const MOVE_SPEED = 200.0
const JUMP_FORCE = -320.0
const GRAVITY = 1300.0
const WALL_SLIDE_SPEED = 100.0
const MAX_FALL_SPEED = 800.0
const MIN_JUMP_CUT = 0.5

# === Wall jump forces ===
const WALL_JUMP_FORCE = Vector2(350, -500)
const WALL_JUMP_FORCE_NEUTRAL = Vector2(0, -650)

# === Dash Constants ===
const DASH_SPEED = 400.0
const DASH_DURATION = 0.15
const DASH_COOLDOWN = 0.3

# === Stamina Constants ===
const MAX_STAMINA = 2.5
const STAMINA_DRAIN_RATE = 1.0
const STAMINA_RECOVER_RATE = 0.8

# === Double Jump Constants ===
const MAX_JUMPS = 2

# === State Variables ===
var is_wall_sliding = false
var is_wall_grabbing = false
var wall_direction = 0
var input_dir = 0
var jump_pressed = false
var jump_held = false
var grab_held = false
var jumps_done = 0

# === Dash State ===
var is_dashing = false
var dash_dir = Vector2.ZERO
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var can_dash = true

# === Stamina State ===
var stamina = MAX_STAMINA

func _ready():
	jumps_done = 0

func _physics_process(delta):
	handle_input()
	handle_stamina(delta)

	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
			dash_cooldown_timer = DASH_COOLDOWN
	else:
		if dash_cooldown_timer > 0.0:
			dash_cooldown_timer -= delta
			if dash_cooldown_timer <= 0.0:
				can_dash = true

		handle_wall_actions()
		apply_gravity(delta)
		handle_jump()

	if is_dashing:
		velocity = dash_dir * DASH_SPEED
	else:
		velocity.x = input_dir * MOVE_SPEED

	move_and_slide()
	clamp_fall_speed()
	reset_jumps_if_needed()

func handle_input():
	input_dir = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	jump_pressed = Input.is_action_just_pressed("ui_accept")
	jump_held = Input.is_action_pressed("ui_accept")
	grab_held = Input.is_action_pressed("wall_grab")  # holding Shift to grab

	if Input.is_action_just_pressed("dash") and can_dash and not is_dashing:
		start_dash()

func start_dash():
	is_dashing = true
	can_dash = false
	dash_timer = DASH_DURATION

	var dx = 0
	if Input.is_action_pressed("ui_right"):
		dx += 1
	if Input.is_action_pressed("ui_left"):
		dx -= 1
	var dy = 0
	if Input.is_action_pressed("ui_down"):
		dy += 1
	if Input.is_action_pressed("ui_up"):
		dy -= 1

	var dir_vec = Vector2(dx, dy)
	if dir_vec == Vector2.ZERO:
		dir_vec = Vector2(1, 0)
	dash_dir = dir_vec.normalized()

func handle_stamina(delta):
	if is_wall_grabbing or is_wall_sliding:
		stamina -= STAMINA_DRAIN_RATE * delta
		stamina = max(stamina, 0)
		if stamina == 0:
			is_wall_grabbing = false
			is_wall_sliding = false
	else:
		stamina += STAMINA_RECOVER_RATE * delta
		stamina = min(stamina, MAX_STAMINA)

func handle_jump():
	if is_dashing:
		return  # no jumps while dashing

	if jump_pressed:
		if is_on_floor():
			velocity.y = JUMP_FORCE
			jumps_done = 1

		elif is_wall_grabbing or is_wall_sliding:
			# Always jump away from the wall, no vertical jump up
			if input_dir == -wall_direction:
				# Neutral wall jump (jump off wall without moving horizontally)
				velocity = WALL_JUMP_FORCE_NEUTRAL
			else:
				# Directional wall jump away from the wall
				velocity.x = WALL_JUMP_FORCE.x * -wall_direction
				velocity.y = WALL_JUMP_FORCE.y

			is_wall_grabbing = false
			is_wall_sliding = false
			jumps_done = 1  # reset jumps_done to 1 after wall jump

		elif jumps_done < MAX_JUMPS:
			velocity.y = JUMP_FORCE
			jumps_done += 1

	if not jump_held and velocity.y < 0:
		velocity.y *= MIN_JUMP_CUT

func reset_jumps_if_needed():
	if is_on_floor():
		jumps_done = 0
	elif not is_wall_grabbing and not is_wall_sliding and jumps_done == 0:
		jumps_done = 1

func apply_gravity(delta):
	if is_on_floor() or is_dashing:
		return

	if is_wall_grabbing:
		velocity.y = 0
	elif is_wall_sliding:
		velocity.y = min(velocity.y + GRAVITY * delta, WALL_SLIDE_SPEED)
	else:
		velocity.y += GRAVITY * delta

func handle_wall_actions():
	is_wall_sliding = false
	is_wall_grabbing = false
	wall_direction = 0

	if is_on_wall() and stamina > 0:
		wall_direction = get_wall_direction()
		if grab_held:
			is_wall_grabbing = true
		elif input_dir == wall_direction:
			is_wall_sliding = true

func clamp_fall_speed():
	if velocity.y > MAX_FALL_SPEED:
		velocity.y = MAX_FALL_SPEED

func get_wall_direction() -> int:
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision.get_normal().x > 0.9:
			return -1
		elif collision.get_normal().x < -0.9:
			return 1
	return 0
