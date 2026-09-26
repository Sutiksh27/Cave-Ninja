class_name Chest
extends Area2D

## Emitted when the player touches the chest; the GameManager decides whether it opens.
signal player_reached

var opened = false

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


func _on_body_entered(body: Node2D) -> void:
	if not opened and body is Player:
		player_reached.emit()

func open():
	opened = true
	animated_sprite_2d.play("ChestOpen")
	$OpenSound.play()
