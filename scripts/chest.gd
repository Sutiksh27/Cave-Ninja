extends Area2D

@onready var game_manager = get_node("/root/Game/GameManager")

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

signal level_completed 

func _on_body_entered(body: Node2D) -> void:
	if game_manager and game_manager.keys == game_manager.KEYS_REQUIRED:
		emit_signal("level_completed")
		animated_sprite_2d.play("ChestOpen")
