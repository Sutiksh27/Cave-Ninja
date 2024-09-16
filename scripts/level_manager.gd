extends Node

# The name of the first level to load
var current_level_name: String = "Level1"

# The path to the levels direcory
var levels_directory: String = "res://scenes/levels/"

# Reference to the current level instance
var current_level: Node = null

# Signals
signal level_loaded(level_name: String)
signal level_completed(level_name: String)

func _ready() -> void:
	# Load the initial level when the game starts
	load_level(current_level_name)
	MusicManager.play_level_music()
	

# Loads a level by name
func load_level(level_name: String) -> void:
	# If there is an existing level, remove it first
	if current_level != null:
		remove_current_level()

	# Construct the full path to the level scene file
	var level_path: String = levels_directory + level_name + ".tscn"

	# Load the level scene
	var level_scene: PackedScene = load(level_path)
	if level_scene == null:
		print("Error: Level scene not found: " + level_path)
		return

	# Instance the level and add it to the CurrentLevel node
	current_level = level_scene.instantiate()
	get_node("/root/Game/CurrentLevel").add_child(current_level)

	# Update the current level name
	current_level_name = level_name

	# Emit the signal that the level has been loaded
	emit_signal("level_loaded", level_name)
	print("Level loaded: " + level_name)

# Removes the current level from the scene tree
func remove_current_level() -> void:
	if current_level != null:
		current_level.queue_free()
		current_level = null
		print("Current level removed.")

# Handles the transition to the next level
func transition_to_next_level() -> void:
	var next_level_name: String = get_next_level_name()
	if next_level_name != "":
		load_level(next_level_name)
	else:
		print("No more levels to load.")
		# You can handle game completion here, like showing a victory screen

# Returns the name of the next level, based on the current level
func get_next_level_name() -> String:
	# Define a list of levels in the order they should be played
	var level_sequence: Array = ["Level1", "Level2", "Level3"]

	# Find the index of the current level
	var current_index: int = level_sequence.find(current_level_name)

	# If the current level is not the last one, return the next level's name
	if current_index != -1 and current_index < level_sequence.size() - 1:
		return level_sequence[current_index + 1]

	# Return an empty string if there are no more levels
	return ""

# Called when a level is completed (e.g., the player reaches the end of the level)
func on_level_completed() -> void:
	emit_signal("level_completed", current_level_name)
	transition_to_next_level()

# Restart the current level
func restart_level() -> void:
	load_level(current_level_name)
