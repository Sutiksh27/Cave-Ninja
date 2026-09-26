extends Node

const SAVE_PATH = "user://save.cfg"
const LEVEL_END_DELAY = 3.0

var keys: int = 0
var keys_required: int = 0
var deaths: int = 0
var round_time = 0.0
var level_running = false

@onready var level_manager: Node = $"../LevelManager"

signal keys_changed(keys: int, keys_required: int)
signal deaths_changed(deaths: int)
signal round_time_changed(round_time: float)
signal hint_shown(text: String)
signal level_finished(time: float, best_time: float, deaths: int)

func _ready():
	level_manager.level_loaded.connect(_on_level_loaded)

func _process(delta):
	if level_running:
		round_time += delta
		round_time_changed.emit(round_time)

func _on_level_loaded(level: Node):
	keys = 0
	keys_required = 0
	deaths = 0
	round_time = 0.0
	for node in level.find_children("*", "", true, false):
		if node is Key:
			keys_required += 1
			node.collected.connect(_on_key_collected)
		elif node is Chest:
			node.player_reached.connect(_on_chest_reached.bind(node))
		elif node is Player:
			node.died.connect(_on_player_died)
	level_running = true
	keys_changed.emit(keys, keys_required)
	deaths_changed.emit(deaths)

func _on_key_collected():
	keys += 1
	keys_changed.emit(keys, keys_required)

func _on_player_died():
	deaths += 1
	deaths_changed.emit(deaths)

func _on_chest_reached(chest: Chest):
	if not level_running:
		return
	if keys < keys_required:
		hint_shown.emit("Find all the keys first! (%d/%d)" % [keys, keys_required])
		return
	level_running = false
	chest.open()
	var best_time = save_best_time(level_manager.current_level_name, round_time)
	level_finished.emit(round_time, best_time, deaths)
	get_tree().create_timer(LEVEL_END_DELAY, false).timeout.connect(level_manager.on_level_completed)

# Stores the time if it beats the saved one and returns the best time.
func save_best_time(level_name: String, time: float) -> float:
	var save = ConfigFile.new()
	save.load(SAVE_PATH)
	var best = save.get_value("best_times", level_name, INF)
	if time < best:
		best = time
		save.set_value("best_times", level_name, best)
		save.save(SAVE_PATH)
	return best
