extends Control

@onready var game_manager = $"../../GameManager"
@onready var key_label: Label = $KeyLabel
@onready var death_label: Label = $DeathLabel
@onready var time_label: Label = $TimeLabel
@onready var win_label: Label = $WinLabel
@onready var hint_timer: Timer = $HintTimer

func _ready():
	win_label.text = ""
	game_manager.keys_changed.connect(_on_keys_changed)
	game_manager.deaths_changed.connect(_on_deaths_changed)
	game_manager.round_time_changed.connect(_on_round_time_changed)
	game_manager.hint_shown.connect(_on_hint_shown)
	game_manager.level_finished.connect(_on_level_finished)
	hint_timer.timeout.connect(func(): win_label.text = "")
	self.process_mode = Node.PROCESS_MODE_ALWAYS

func _on_keys_changed(keys, keys_required):
	key_label.text = "%d/%d" % [keys, keys_required]

func _on_deaths_changed(deaths):
	death_label.text = "Deaths: %d" % deaths

func _on_round_time_changed(round_time):
	time_label.text = "Time: " + format_time(round_time)

func _on_hint_shown(text):
	win_label.text = text
	hint_timer.start()

func _on_level_finished(time, best_time, deaths):
	hint_timer.stop()
	win_label.text = "Level Complete!\nTime: %s\nBest: %s\nDeaths: %d" % [format_time(time), format_time(best_time), deaths]

static func format_time(seconds: float) -> String:
	return "%02d:%05.2f" % [int(seconds) / 60, fmod(seconds, 60.0)]
