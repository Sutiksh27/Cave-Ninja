class_name Enemy
extends StaticBody2D

## A stationary ninja that throws shuriken at the player once it can see them.
## One katana slash (or a reflected shuriken) defeats it.

const SHURIKEN_SCENE = preload("res://prefabs/Shuriken.tscn")
const POOF_SCENE = preload("res://prefabs/jump_dust_particles.tscn")
const WINDUP_TIME = 0.35   # telegraph: the ninja flashes in its throw pose first
const THROW_POSE_TIME = 0.2
const HAND_OFFSET = Vector2(8, 0)

@export var facing = -1
@export var aimed = false            # throw at the player instead of straight ahead
@export var throw_interval = 1.8
@export var first_throw_delay = 0.8
@export var sight_range = Vector2(220, 40)  # straight throwers: x reach and y tolerance; aimed: x is the radius
@export var shuriken_speed = 110.0

var cooldown = 0.0
var windup = 0.0
var pose_timer = 0.0
var defeated = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	cooldown = first_throw_delay
	play_pose("Idle")

func _physics_process(delta: float) -> void:
	if defeated:
		return
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	if windup > 0.0:
		windup -= delta
		if windup <= 0.0:
			throw(player)
		return

	pose_timer -= delta
	if pose_timer <= 0.0:
		play_pose("Idle")
	if player.is_dead or not can_see(player):
		return
	facing = 1 if player.global_position.x > global_position.x else -1
	cooldown -= delta
	if cooldown <= 0.0:
		windup = WINDUP_TIME
		play_pose("Throw")
		animated_sprite.modulate = Color(1.8, 1.8, 1.8)

func can_see(player: Node2D) -> bool:
	var to_player = player.global_position - global_position
	if aimed:
		if to_player.length() > sight_range.x:
			return false
	elif absf(to_player.x) > sight_range.x or absf(to_player.y) > sight_range.y:
		return false
	var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position, Shuriken.LAYER_ENVIRONMENT)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func throw(player: Node2D):
	cooldown = throw_interval
	pose_timer = THROW_POSE_TIME
	animated_sprite.modulate = Color.WHITE
	var start = global_position + HAND_OFFSET * Vector2(facing, 1)
	var direction = (player.global_position - start).normalized() if aimed else Vector2(facing, 0)
	var shuriken = SHURIKEN_SCENE.instantiate()
	shuriken.velocity = direction * shuriken_speed
	get_parent().add_child(shuriken)
	shuriken.global_position = start
	$ThrowSound.play()

func play_pose(pose: String):
	animated_sprite.play(pose + ("Right" if facing > 0 else "Left"))

## Called by the player's slash or a reflected shuriken.
func hit():
	if defeated:
		return
	defeated = true
	windup = 0.0
	$CollisionShape2D.set_deferred("disabled", true)
	animated_sprite.modulate = Color.WHITE
	animated_sprite.play("Dead")
	$DefeatSound.play()
	var poof = POOF_SCENE.instantiate()
	get_parent().add_child(poof)
	poof.global_position = global_position
	poof.rotation = -PI / 2
	var tween = create_tween()
	tween.tween_interval(0.4)
	tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)
