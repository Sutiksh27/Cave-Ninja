@tool
extends EditorScript

# Traces tile collision polygons from each tile's texture alpha.
# Usage: open a level scene, open this file in the Script editor,
# then File > Run (Ctrl+Shift+X). Save the scene afterwards.
#
# Only tiles whose collision is still the default full square get replaced,
# so tiles with no collision stay non-solid and hand-drawn shapes are kept.

const PHYSICS_LAYER := 0
# Alpha above this counts as solid.
const ALPHA_THRESHOLD := 0.5
# Max deviation from the traced outline, in texture pixels.
# Tiles are 512px drawn at 0.05 scale, so 20 texture px ~= 1 world px.
const SIMPLIFY_EPSILON := 20.0

func _run() -> void:
	var root := get_scene()
	if root == null:
		push_error("Open a level scene first.")
		return

	var done := {}
	for layer in root.find_children("*", "TileMapLayer", true, false):
		var tile_set: TileSet = layer.tile_set
		if tile_set == null or done.has(tile_set):
			continue
		done[tile_set] = true
		if tile_set.get_physics_layers_count() <= PHYSICS_LAYER:
			continue
		for i in tile_set.get_source_count():
			var source := tile_set.get_source(tile_set.get_source_id(i)) as TileSetAtlasSource
			if source and source.texture:
				_process_source(source, layer.name)

func _process_source(source: TileSetAtlasSource, layer_name: String) -> void:
	var image := source.texture.get_image()
	if image.is_compressed():
		image.decompress()

	var replaced := 0
	for t in source.get_tiles_count():
		var coords := source.get_tile_id(t)
		var data := source.get_tile_data(coords, 0)
		if not _is_default_square(data, source.texture_region_size):
			continue

		var region := source.get_tile_texture_region(coords)
		var bitmap := BitMap.new()
		bitmap.create_from_image_alpha(image.get_region(region), ALPHA_THRESHOLD)
		var polygons := bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO, region.size), SIMPLIFY_EPSILON)

		# Polygon points are relative to the tile's center.
		var offset := Vector2(region.size) / 2.0 + Vector2(data.texture_origin)
		data.set_collision_polygons_count(PHYSICS_LAYER, polygons.size())
		for p in polygons.size():
			var points := PackedVector2Array()
			for v in polygons[p]:
				points.append(v - offset)
			data.set_collision_polygon_points(PHYSICS_LAYER, p, points)
		replaced += 1

	print("%s / %s: traced %d tiles" % [layer_name, source.texture.resource_path.get_file(), replaced])

func _is_default_square(data: TileData, size: Vector2i) -> bool:
	if data.get_collision_polygons_count(PHYSICS_LAYER) != 1:
		return false
	var h := Vector2(size) / 2.0
	var square := PackedVector2Array([Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)])
	return data.get_collision_polygon_points(PHYSICS_LAYER, 0) == square
