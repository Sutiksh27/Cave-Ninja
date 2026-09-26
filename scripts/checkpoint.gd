class_name Checkpoint
extends Area2D

## The checkpoint's position is where the player respawns (player centre).

var active = false

@onready var sprite_2d: Sprite2D = $Sprite2D


func _on_body_entered(body: Node2D) -> void:
	if active or not body is Player:
		return
	active = true
	sprite_2d.frame = 1
	$ActivateSound.play()
	body.respawn_point = global_position
