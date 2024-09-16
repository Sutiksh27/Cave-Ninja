extends Control

const RESOLUTION_DICT: Dictionary = {
	"640 x 360" : Vector2i(640, 360),
	"1152 x 648" : Vector2i(1152, 648),
	"1280 x 720" : Vector2i(1280, 720),
	"1920 x 1080" : Vector2i(1920, 1080),
}
@onready var option_button: OptionButton = $HBoxContainer/OptionButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_resolution_items()
	option_button.item_selected.connect(_on_resolution_selected)
	

func add_resolution_items() -> void:
	for resolution_size in RESOLUTION_DICT:
		option_button.add_item(resolution_size)
	
func _on_resolution_selected(idx: int) -> void:
	DisplayServer.window_set_size(RESOLUTION_DICT.values()[idx])
