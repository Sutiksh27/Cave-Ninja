extends Area2D

const PLAYER_SPAWN_POSITION: Vector2 = Vector2(100, 600)
@onready var timer: Timer = $Timer
@onready var death_sound: AudioStreamPlayer2D = $DeathSound
@onready var game_manager = get_node("/root/Game/GameManager")
signal player_died

func _on_timer_timeout() -> void:
	Engine.time_scale = 1.0
	#get_tree().reload_current_scene()

func _on_body_entered(body: Node2D) -> void:
	game_manager.lose_life()
	game_manager.restart_game_timer() # to restart the game time
	death_sound.play()
	Engine.time_scale = 0.5
	
	# Resposition the player body
	body.position = PLAYER_SPAWN_POSITION
	
	# Disable the collision temporarily
	body.get_node("CollisionShape2D").disabled = true
	
	# Restart the timer to give a delay before re-enabling collision or full speed 
	timer.start()
	
	# Reactivate collision after some time
	await  timer.timeout
	body.get_node("CollisionShape2D").disabled = false
	Engine.time_scale = 1.0
	
