extends Control

@onready var game_manager = get_node("/root/Game/GameManager")
@onready var key_label: Label = $KeyLabel
@onready var life_label: Label = $LifeLabel
@onready var time_label: Label = $TimeLabel
@onready var win_label: Label = $WinLabel
@onready var timer: Timer = $"../../GameManager/Timer"

func _ready():
	win_label.text = ""
	life_label.text = "Lives: " + str(Globals.lives)
	game_manager.connect("keys_changed", Callable(self, "_on_keys_changed"))
	game_manager.connect("lives_changed", Callable(self, "_on_lives_changed"))
	game_manager.connect("round_time_changed", Callable(self, "_on_round_time_changed"))
	game_manager.connect("win_time_published", Callable(self, "_on_win_time_published"))
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	
func _on_keys_changed(keys):
	key_label.text = str(keys)
	
func _on_lives_changed(lives):
	life_label.text = "Lives: " + str(lives)

func _on_round_time_changed(round_time):
	time_label.text = "Time: " + str(round_time)
	
func _on_win_time_published(win_time):
	win_label.text = "You Won! \n" + "Time: " + str(win_time)
	timer.start()
	await timer.timeout
	win_label.text = ""
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
