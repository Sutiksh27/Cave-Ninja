extends Node

@onready var menu_music_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var level_music_player: AudioStreamPlayer = AudioStreamPlayer.new()

@export var menu_music: AudioStream = preload("res://assets/Music/Adventure.ogg")
@export var level_music: AudioStream = preload("res://assets/Music/Cave.ogg")

var current_scene = ""

func _ready():
	# Add the audio players to the scene tree
	add_child(menu_music_player)
	add_child(level_music_player)

	# Load the audio streams into the players
	menu_music_player.stream = menu_music
	level_music_player.stream = level_music
	menu_music_player.bus = "Music"
	level_music_player.bus = "Music"

	# Ensure that music doesn't stop between scenes
	menu_music_player.autoplay = false
	level_music_player.autoplay = false

func play_menu_music():
	if current_scene != "menu":
		level_music_player.stop()
		menu_music_player.play()
		current_scene = "menu"

func play_level_music():
	if current_scene != "level":
		menu_music_player.stop()
		level_music_player.play()
		current_scene = "level"
