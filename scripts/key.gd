class_name Key
extends Area2D

signal collected

const BOB_HEIGHT = 2.0
const BOB_SPEED = 3.0

var picked = false

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Sprite2D


func _process(_delta: float) -> void:
	var t = Time.get_ticks_msec() / 1000.0 * BOB_SPEED + position.x
	sprite_2d.position.y = roundf(sin(t) * BOB_HEIGHT)

func _on_body_entered(body: Node2D) -> void:
	if picked or not body is Player:
		return
	picked = true
	collected.emit()
	animation_player.play("pickup")
