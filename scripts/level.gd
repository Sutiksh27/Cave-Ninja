extends Node2D

## Keeps the player's camera inside the painted Terrain area.

func _ready() -> void:
	var terrain: TileMapLayer = $Terrain
	var tile_size = Vector2(terrain.tile_set.tile_size)
	var rect = Rect2(terrain.get_used_rect())
	var camera: Camera2D = $Player/Camera2D
	camera.limit_left = int(rect.position.x * tile_size.x)
	camera.limit_top = int(rect.position.y * tile_size.y)
	camera.limit_right = int(rect.end.x * tile_size.x)
	camera.limit_bottom = int(rect.end.y * tile_size.y)
	camera.reset_smoothing()
