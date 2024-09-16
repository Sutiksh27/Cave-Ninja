class_name OptionsMenu
extends Control

@onready var exit_button: Button = $MarginContainer/VBoxContainer/ExitButton

signal exit_options_menu
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	exit_button.button_down.connect(on_exit_pressed)
	set_process(false)
	
func on_exit_pressed() -> void:
	exit_options_menu.emit()
	set_process(false)
