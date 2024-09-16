extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var game_manager = get_node("/root/Game/GameManager")


func _on_body_entered(body: Node2D) -> void:
	game_manager.add_key()
	animation_player.play("pickup")
