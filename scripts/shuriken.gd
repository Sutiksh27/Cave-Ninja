class_name Shuriken
extends Area2D

## Thrown by an Enemy. Kills the player (it sits on the Hazards layer) and breaks on walls.
## A katana slash sends it back, after which it only hurts enemies.

const LIFETIME = 4.0
const SPIN_SPEED = 20.0
const REFLECT_SPEED_SCALE = 1.5
const LAYER_PROJECTILES = 64
const LAYER_ENVIRONMENT = 1
const LAYER_ENEMIES = 32

var velocity = Vector2.ZERO
var reflected = false
var age = 0.0

@onready var sprite_2d: Sprite2D = $Sprite2D


func _physics_process(delta: float) -> void:
	position += velocity * delta
	sprite_2d.rotation += SPIN_SPEED * delta
	age += delta
	if age > LIFETIME:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is Enemy:
		body.hit()
	queue_free()

## Called by the player's slash.
func hit():
	if reflected:
		return
	reflected = true
	velocity = -velocity * REFLECT_SPEED_SCALE
	collision_layer = LAYER_PROJECTILES
	collision_mask = LAYER_ENVIRONMENT | LAYER_ENEMIES
	sprite_2d.modulate = Color(0.6, 1.0, 1.0)
	$ReflectSound.play()
