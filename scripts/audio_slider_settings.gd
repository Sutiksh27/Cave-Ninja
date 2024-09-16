extends Control

@onready var audio_name_label: Label = $HBoxContainer/AudioNameLabel
@onready var h_slider: HSlider = $HBoxContainer/HSlider
@onready var audio_num_label: Label = $HBoxContainer/AudioNumLabel

@export_enum("Master", "SoundEffects", "Music") var bus_name: String

var bus_idx: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	h_slider.value_changed.connect(_on_hslider_value_changed)
	get_bus_name_by_idx()
	set_name_label_text()
	set_slider_value()
	
func set_name_label_text() -> void:
	audio_name_label.text = str(bus_name) + " Volume"
	
func set_num_label_text() -> void:
	audio_num_label.text = str(h_slider.value * 100)
	
func get_bus_name_by_idx() -> void:
	bus_idx = AudioServer.get_bus_index(bus_name)
	
func set_slider_value() -> void:
	h_slider.value = db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	set_num_label_text()
	
func _on_hslider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
	set_num_label_text()
