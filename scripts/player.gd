extends CharacterBody2D

@export var jump_particles_scene: PackedScene = preload("res://prefabs/jump_dust_particles.tscn")
@export var wall_particles_scene: PackedScene = preload("res://prefabs/wall_dust_particles.tscn")
const SPEED = 130.0
const JUMP_VELOCITY = -400.0
const TILE_SIZE = 512 * 0.05
const WALL_JUMP_VELOCITY = Vector2(130.0, -400.0)
var direction = 0
var percent_moved_to_next_tile = 0.0
var is_moving = false
var is_wall_jumping = false
var can_wall_jump_left = false
var can_wall_jump_right = false

@onready var trail_2d: Line2D = $Trail2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready():
	animated_sprite.play("IdleFront")
	
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

		# Handle jump.
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			$JumpSound.play()
			velocity.y = JUMP_VELOCITY
			play_jump_animation()
			spawn_jump_particles(position, Vector2(0, -1))
		elif is_on_wall_left() and can_wall_jump_left:
			wall_jump_left()
		elif is_on_wall_right() and can_wall_jump_right:
			wall_jump_right()
		return  # Stop further animation changes for this frame.
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if Input.is_action_pressed("move_left"):
		direction = -1
		velocity.x = direction * SPEED
		animated_sprite.play("WalkLeft")
		
	elif Input.is_action_pressed("move_right"):
		direction = 1
		velocity.x = direction * SPEED
		animated_sprite.play("WalkRight")
	
	else:
		# No movement input; stop the player and play the idle animation.
		velocity.x = 0
		if direction > 0:
			animated_sprite.play("IdleRight")
		elif direction < 0:
			animated_sprite.play("IdleLeft")
		else:
			animated_sprite.play("IdleFront")
			
	# Spawn particles
	if is_on_wall_left() or is_on_wall_right():
		if velocity.y > 0:
			spawn_wall_particles(position, Vector2(0, -1))
	
	move_and_slide()

# Ensure jump animation plays when in the air.
	if not is_on_floor() and abs(velocity.y) > 0:
		play_jump_animation()

	# Reset wall jump state when on the floor.
	if is_on_floor():
		is_wall_jumping = false
	
	if not is_player_on_wall():
		reset_wall_jump_state()

func is_player_on_wall() -> bool:
	# Check if the player is touching a wall.
	return is_on_wall_left() or is_on_wall_right()	

func is_on_wall_left() -> bool:
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision.get_normal()[0]>0:
			return true
	return false
	
func is_on_wall_right() -> bool:
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision.get_normal()[0] < 0:
			return true
	return false

func wall_jump():
	# Handle wall jump mechanics.
	is_wall_jumping = true
	if is_on_wall_left():
		velocity.x = WALL_JUMP_VELOCITY.x  # Jump right
		direction = 1
		animated_sprite.play("JumpRight")
		$JumpSound.play()
	elif is_on_wall_right():
		velocity.x = -WALL_JUMP_VELOCITY.x  # Jump left
		direction = -1
		animated_sprite.play("JumpLeft")
		$JumpSound.play()
	velocity.y = WALL_JUMP_VELOCITY.y  # Jump up
	
func wall_jump_left():
	is_wall_jumping = true
	can_wall_jump_left = false
	velocity.x = WALL_JUMP_VELOCITY.x
	direction = 1
	animated_sprite.play("JumpRight")
	velocity.y = WALL_JUMP_VELOCITY.y 
	

func wall_jump_right():
	is_wall_jumping = true
	can_wall_jump_right = false
	velocity.x = -WALL_JUMP_VELOCITY.x
	direction = -1
	animated_sprite.play("JumpLeft")
	velocity.y = WALL_JUMP_VELOCITY.y 
	
func reset_wall_jump_state():
	can_wall_jump_left = true
	can_wall_jump_right = true

func play_jump_animation():
	
	if direction > 0:
		animated_sprite.play("JumpRight")
	elif direction < 0:
		animated_sprite.play("JumpLeft")
		
## VISUALS ##

func spawn_jump_particles(pos: Vector2, normal: Vector2) -> void:
	var instance = jump_particles_scene.instantiate()
	get_tree().get_current_scene().add_child(instance)
	instance.global_position = pos
	instance.rotation = normal.angle()
	
func spawn_wall_particles(pos: Vector2, normal: Vector2) -> void:
	var instance = wall_particles_scene.instantiate()
	get_tree().get_current_scene().add_child(instance)
	instance.global_position = pos
	instance.rotation = normal.angle()
