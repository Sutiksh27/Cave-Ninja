class_name PauseMenu
extends Control

@onready var margin_container: MarginContainer = $MarginContainer
@onready var resume_btn: Button = $MarginContainer/VBoxContainer/ResumeBtn
@onready var options_btn: Button = $MarginContainer/VBoxContainer/OptionsBtn
@onready var exit_menu_btn: Button = $MarginContainer/VBoxContainer/ExitMenuBtn
@onready var options_menu: OptionsMenu = $OptionsMenu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	handle_connecting_signals()
	set_process(false)
	self.process_mode = Node.PROCESS_MODE_ALWAYS

# Runs while paused too (PROCESS_MODE_ALWAYS), so Esc can also resume
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if visible:
			resume_game()
		else:
			pause_game()
		get_viewport().set_input_as_handled()

func _on_resume_btn_pressed() -> void:
	resume_game()

func _on_options_btn_pressed() -> void:
	margin_container.visible = false
	options_menu.set_process(true)
	options_menu.visible = true

func _on_exit_to_menu_btn_pressed() -> void:
	get_tree().paused = false
	# Loaded by path: preloading it here would be circular (the main menu preloads
	# the game scene, which contains this pause menu) and yields an empty scene.
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
	
func _on_exit_options_menu() -> void:
	margin_container.visible = true
	options_menu.visible = false
	
func handle_connecting_signals() -> void:
	resume_btn.button_down.connect(_on_resume_btn_pressed)
	options_btn.button_down.connect(_on_options_btn_pressed)
	exit_menu_btn.button_down.connect(_on_exit_to_menu_btn_pressed)
	options_menu.exit_options_menu.connect(_on_exit_options_menu)

# Function to pause the game, call this from the main game to trigger the pause menu
func pause_game() -> void:
	# Pause the game by pausing the scene tree
	get_tree().paused = true
	# Make the pause menu visible
	self.visible = true
	
func resume_game() -> void:
	get_tree().paused = false
	self.visible = false  # Hide the pause menu
	_on_exit_options_menu()  # Reopen on the main pause page next time
	set_process(false)
