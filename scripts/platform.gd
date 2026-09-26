extends AnimatableBody2D

## Moves back and forth between its start position and start + move_by.
@export var move_by = Vector2.ZERO
@export var duration = 2.0
@export var pause_time = 0.4


func _ready() -> void:
	if move_by == Vector2.ZERO:
		return
	var start = position
	var tween = create_tween().set_loops()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", start + move_by, duration).set_delay(pause_time)
	tween.tween_property(self, "position", start, duration).set_delay(pause_time)
