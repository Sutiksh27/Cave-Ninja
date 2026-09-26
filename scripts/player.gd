class_name Player
extends CharacterBody2D

signal died

@export var jump_particles_scene: PackedScene = preload("res://prefabs/jump_dust_particles.tscn")
@export var wall_particles_scene: PackedScene = preload("res://prefabs/wall_dust_particles.tscn")

const RUN_SPEED = 120.0
const GROUND_ACCEL = 1000.0
const GROUND_FRICTION = 1400.0
const AIR_ACCEL = 700.0
const JUMP_VELOCITY = -330.0
const JUMP_GRAVITY = 920.0   # while rising
const FALL_GRAVITY = 1400.0  # while falling, for a snappier arc
const JUMP_CUT = 0.5         # upward speed kept when jump is released early
const MAX_FALL_SPEED = 320.0
const WALL_SLIDE_SPEED = 60.0
const WALL_JUMP_VELOCITY = Vector2(140.0, -300.0)
const WALL_JUMP_LOCK_TIME = 0.12  # ignore steering briefly so the jump pushes off the wall
const WALL_CHECK_DISTANCE = 2.0
const COYOTE_TIME = 0.1
const JUMP_BUFFER_TIME = 0.12
const WALL_DUST_INTERVAL = 0.1
const RESPAWN_DELAY = 0.5
const ATTACK_TIME = 0.25          # length of the slash pose
const ATTACK_ACTIVE_TIME = 0.12   # hits land during the first part of the slash
const ATTACK_COOLDOWN = 0.3
const ATTACK_REACH = 14.0

var facing = 1
var coyote_timer = 0.0
var jump_buffer_timer = 0.0
var wall_jump_lock = 0.0
var wall_dust_timer = 0.0
var attack_timer = 0.0
var attack_cooldown = 0.0
var is_dead = false
var respawn_point: Vector2

@onready var trail_2d: Line2D = $Trail2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var slash: AnimatedSprite2D = $Slash
@onready var katana: Sprite2D = $Katana


func _ready():
	respawn_point = global_position
	animated_sprite.play("IdleRight")
	$Hurtbox.body_entered.connect(func(_body): die())
	$Hurtbox.area_entered.connect(func(_area): die())
	slash.animation_finished.connect(slash.hide)

func _exit_tree():
	# Leaving mid-death (e.g. back to the menu) must not keep the slow motion.
	Engine.time_scale = 1.0

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	var input = Input.get_axis("move_left", "move_right")
	var wall_dir = get_wall_direction()

	coyote_timer = COYOTE_TIME if is_on_floor() else coyote_timer - delta
	jump_buffer_timer = JUMP_BUFFER_TIME if Input.is_action_just_pressed("jump") else jump_buffer_timer - delta
	wall_jump_lock -= delta

	if wall_jump_lock <= 0.0:
		var accel = GROUND_ACCEL if is_on_floor() else AIR_ACCEL
		if input == 0.0 and is_on_floor():
			accel = GROUND_FRICTION
		velocity.x = move_toward(velocity.x, input * RUN_SPEED, accel * delta)

	if not is_on_floor():
		var gravity = JUMP_GRAVITY if velocity.y < 0.0 else FALL_GRAVITY
		velocity.y = minf(velocity.y + gravity * delta, MAX_FALL_SPEED)
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT

	var wall_sliding = wall_dir != 0 and input == wall_dir and velocity.y > 0.0
	if wall_sliding:
		velocity.y = minf(velocity.y, WALL_SLIDE_SPEED)
		wall_dust_timer -= delta
		if wall_dust_timer <= 0.0:
			wall_dust_timer = WALL_DUST_INTERVAL
			spawn_particles(wall_particles_scene, global_position + Vector2(wall_dir * 5, 4), Vector2.UP)

	if jump_buffer_timer > 0.0:
		if coyote_timer > 0.0:
			jump()
		elif wall_dir != 0:
			wall_jump(wall_dir)

	move_and_slide()

	attack_timer -= delta
	attack_cooldown -= delta
	if Input.is_action_just_pressed("attack") and attack_cooldown <= 0.0:
		start_attack()
	if attack_timer > ATTACK_TIME - ATTACK_ACTIVE_TIME:
		for target in get_attack_targets():
			if target.has_method("hit"):
				target.hit()

	update_animation(input)

# -1 when a wall is touching the left side, 1 for the right side, 0 otherwise.
func get_wall_direction() -> int:
	if is_on_floor():
		return 0
	if test_move(global_transform, Vector2(-WALL_CHECK_DISTANCE, 0)):
		return -1
	if test_move(global_transform, Vector2(WALL_CHECK_DISTANCE, 0)):
		return 1
	return 0

func jump():
	velocity.y = JUMP_VELOCITY
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	$JumpSound.play()
	spawn_particles(jump_particles_scene, global_position + Vector2(0, 8), Vector2.UP)

func wall_jump(wall_dir: int):
	velocity = Vector2(-wall_dir * WALL_JUMP_VELOCITY.x, WALL_JUMP_VELOCITY.y)
	facing = -wall_dir
	wall_jump_lock = WALL_JUMP_LOCK_TIME
	jump_buffer_timer = 0.0
	$JumpSound.play()
	spawn_particles(jump_particles_scene, global_position + Vector2(wall_dir * 5, 0), Vector2(-wall_dir, 0))

# Queries the physics space directly: an Area2D's overlap lists miss
# objects when neither side has moved (e.g. slashing a ninja while standing still).
func get_attack_targets() -> Array:
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = attack_hitbox.get_node("CollisionShape2D").shape
	query.transform = attack_hitbox.global_transform
	query.collision_mask = attack_hitbox.collision_mask
	query.collide_with_areas = true
	return get_world_2d().direct_space_state.intersect_shape(query).map(func(hit): return hit.collider)

func start_attack():
	attack_timer = ATTACK_TIME
	attack_cooldown = ATTACK_COOLDOWN
	slash.position.x = facing * ATTACK_REACH
	slash.flip_h = facing < 0
	slash.show()
	slash.frame = 0
	slash.play()
	katana.position.x = facing * 11
	katana.rotation_degrees = -90 * facing
	katana.show()
	$SlashSound.play()

func update_animation(input: float):
	if input != 0.0 and wall_jump_lock <= 0.0 and attack_timer <= 0.0:
		facing = 1 if input > 0.0 else -1
	attack_hitbox.position.x = facing * ATTACK_REACH
	katana.visible = attack_timer > 0.0
	var side = "Right" if facing > 0 else "Left"
	if attack_timer > 0.0:
		animated_sprite.play("Attack" + side)
	elif not is_on_floor():
		animated_sprite.play("Jump" + side)
	elif absf(velocity.x) > 10.0:
		animated_sprite.play("Walk" + side)
	else:
		animated_sprite.play("Idle" + side)

func die():
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	attack_timer = 0.0
	katana.hide()
	slash.hide()
	animated_sprite.play("Dead")
	$HurtSound.play()
	died.emit()
	Engine.time_scale = 0.5
	get_tree().create_timer(RESPAWN_DELAY, false, false, true).timeout.connect(_respawn)

func _respawn():
	Engine.time_scale = 1.0
	global_position = respawn_point
	velocity = Vector2.ZERO
	trail_2d.clear_points()
	camera.reset_smoothing()
	is_dead = false

## VISUALS ##

func spawn_particles(scene: PackedScene, pos: Vector2, normal: Vector2) -> void:
	var instance = scene.instantiate()
	get_tree().get_current_scene().add_child(instance)
	instance.global_position = pos
	instance.rotation = normal.angle()
