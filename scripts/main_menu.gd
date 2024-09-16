extends Control

@onready var start_btn: Button = $MarginContainer/VBoxContainer/StartBtn
@onready var options_btn: Button = $MarginContainer/VBoxContainer/OptionsBtn
@onready var quit_btn: Button = $MarginContainer/VBoxContainer/QuitBtn
@onready var options_menu: OptionsMenu = $OptionsMenu
@onready var start_level: PackedScene = preload("res://scenes/Main.tscn")
@onready var margin_container: MarginContainer = $MarginContainer

func _ready() -> void:
	handle_connecting_signals()
	MusicManager.play_menu_music()
	
func _on_start_btn_pressed() -> void:
	get_tree().change_scene_to_packed(start_level)
	
func _on_options_btn_pressed() -> void:
	margin_container.visible = false
	options_menu.set_process(true)
	options_menu.visible = true

func _on_quit_btn_pressed() -> void:
	get_tree().quit()
	
func _on_exit_options_menu() -> void:
	margin_container.visible = true
	options_menu.visible = false

func handle_connecting_signals() -> void:
	start_btn.button_down.connect(_on_start_btn_pressed)
	options_btn.button_down.connect(_on_options_btn_pressed)
	quit_btn.button_down.connect(_on_quit_btn_pressed)
	options_menu.exit_options_menu.connect(_on_exit_options_menu)
