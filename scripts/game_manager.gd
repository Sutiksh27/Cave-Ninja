extends Node

const KEYS_REQUIRED: int = 3
const PLAYER_START_POSITION: Vector2 = Vector2(100, 600)
var keys: int = 0
var start_time: float = 0.0
var completion_times: Array = []
var level_completed: bool = false
var round_time = 0.0
#@onready var key_text: Label = $KeyText
#@onready var win_text: Label = $WinText
@onready var level_manager: Node = $"../LevelManager"
@onready var pause_menu: PauseMenu = $"../CanvasLayer/PauseMenu"

signal keys_changed(keys: int)
signal lives_changed(lives: int)
signal round_time_changed(round_time: float)
signal win_time_published(win_time: float)
signal level_finished

func _ready():
	var current_level = get_node("/root/Game/CurrentLevel")
	var chest = current_level.get_node(level_manager.current_level_name).get_node("Chest")
	var hud = get_node("/root/Game/CanvasLayer/HUD")
	start_time = Time.get_ticks_msec() / 1000.0
	if chest:
		print("Chest Found!")
		chest.connect("level_completed", Callable(self, "_on_level_completed"))
	if hud:
		connect("keys_changed", Callable(hud, "on_keys_changed"))
		connect("lives_changed", Callable(hud, "on_lives_changed"))


func _process(delta):
	round_time += delta
	emit_signal("round_time_changed", round_time)
	if Input.is_action_pressed("pause"):
		if get_tree().paused:
			resume_game()
		else:
			pause_menu.set_process(true)
			pause_game()
		
func add_key():
	keys += 1
	print("Keys Collected: ", keys)
	emit_signal("keys_changed", keys)
	
func lose_life():
	Globals.lives -= 1
	print("Lives: ", Globals.lives)
	emit_signal("lives_changed", Globals.lives)
	
	if Globals.lives <= 0:
		game_over()
	
func game_over():
	print("Game Over! Going back to main menu.")
	var main_menu_scene = preload("res://ui/main_menu.tscn")
	get_tree().change_scene_to_packed(main_menu_scene)
	
func record_completion_time():
	var completion_time = (Time.get_ticks_msec() / 1000.0) - start_time
	completion_times.append(completion_time)
	emit_signal("win_time_published", completion_time)

func _on_level_completed():
	level_completed = true
	record_completion_time()
	#level_manager.on_level_completed()
	Globals.lives = 3
	keys = 0
	round_time = 0.0
	start_time = Time.get_ticks_msec() / 1000.0

func restart_game_timer() -> void:
	round_time = 0.0
	
func pause_game():
	if pause_menu:
		get_tree().paused = true
		pause_menu.visible = true

func resume_game():
	if pause_menu:
		get_tree().paused = false
		pause_menu.visible = false
