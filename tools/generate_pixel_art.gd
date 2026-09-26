extends SceneTree
## Generates the 16px pixel-art tiles, moving platform and checkpoint lantern
## so the level art matches the pixel-art character and cave background.
## Run from the project folder, then let the editor re-import the PNGs:
##   godot --headless --path . -s res://tools/generate_pixel_art.gd
##
## cave_tiles.png layout (16px cells, x,y):
##   rows 0-1  terrain for each side mask (N=1 E=2 S=4 W=8 set = neighbour present)
##   (0,2)(1,2) extra fill variants    (2,2)(3,2) extra grass-top variants
##   (4..7,2)   one-way ledge: left, middle, right, single
##   (0,3) spikes up  (1,3) spikes down  (2,3)(3,3) grass  (4,3)(5,3) mushrooms
##   (6,3) rocks      (7,3) tall grass
##   (0,4) vine top   (1,4) vine middle  (2,4) vine end    (3,4) hanging moss
##   (4,4)(5,4) deep and deeper rock fill, for tiles far from open space
##
## assets/combat/: enemy ninja sheets (player sheets recoloured), shuriken, slash arc

const T := 16
const OUT_DIR := "res://assets/tiles/"
const COMBAT_DIR := "res://assets/combat/"

const CLEAR := Color(0, 0, 0, 0)
const OUTLINE := Color("07120c")
const CRACK := Color("0c1e14")
const STONE := Color("15301f")
const STONE_HI := Color("1f452b")
const STONE_SPECK := Color("27552f")
# [crack, stone, highlight, speck] for normal, deep and deeper rock
const ROCK_SHADES := [
	[CRACK, STONE, STONE_HI, STONE_SPECK],
	[Color("08140d"), Color("0f2316"), Color("15301e"), Color("1a3a23")],
	[Color("050c08"), Color("09170e"), Color("0d2014"), Color("112819")],
]
const MOSS_D := Color("2e6b2a")
const MOSS := Color("4f9e32")
const MOSS_L := Color("8fd048")
const MOSS_TIP := Color("c6ee70")
const THORN_L := Color("efe6cf")
const THORN_M := Color("b3a58a")
const THORN_D := Color("6b5f4c")
const VINE_D := Color("1f4d22")
const VINE := Color("3b7e2e")
const LEAF := Color("6fb83e")

const PALETTE := {
	"L": MOSS_TIP, "l": MOSS_L, "m": MOSS, "d": MOSS_D,
	"C": Color("a8f2ff"), "c": Color("45c6e0"), "k": Color("1e7896"),
	"s": Color("d8efe4"), "t": Color("8fb3a6"),
	"r": Color("4a6b52"), "R": Color("2f4a37"), "q": Color("1d3024"),
}
const LANTERN_PALETTE := {"h": Color("93a596"), "g": Color("62756a"), "q": Color("3b4a42")}
const WINDOW_UNLIT := {"w": Color("1a2420"), "W": Color("243029")}
const WINDOW_LIT := {"w": Color("ffb347"), "W": Color("fff1b0")}

# Player colour -> enemy colour: red hood, black outfit, gold trim.
const ENEMY_COLORS := {
	"79b8ce": Color("c23b3b"),
	"5f7160": Color("2b2833"),
	"3b3643": Color("15131a"),
	"d14b34": Color("f1c471"),
}
const SHURIKEN_PALETTE := {"l": Color("e8eef2"), "m": Color("a9b6bd"), "d": Color("5d6b73"), "c": Color("1b2226")}
const SHURIKEN := [
	"...l...",
	"...l...",
	"..lmm..",
	"llmcmdd",
	"..mmd..",
	"...d...",
	"...d...",
]

# Internal stone cracks per fill variant, as [x0, y0, x1, y1] lines.
const CRACKS := [
	[[0, 7, 14, 7], [9, 0, 9, 6], [4, 8, 4, 14]],
	[[0, 9, 14, 9], [5, 0, 5, 8], [11, 10, 11, 14]],
	[[7, 0, 7, 14], [0, 6, 6, 6], [8, 10, 14, 10]],
]
const GRASS_TIPS := [0, 1, 2, 0, 1, 0, 0, 2, 1, 0, 1, 2, 0, 0, 1, 0]
const MOSS_DRIPS := [0, 1, 0, 2, 0, 0, 1, 0, 3, 1, 0, 0, 2, 0, 1, 0]

const MUSHROOMS_SMALL := [
	"...CCC..........",
	"..CCccc.........",
	".Cccccck........",
	".kkkkkkk....Cc..",
	"....st.....Ccck.",
	"....st.....kkkk.",
	"....st......st..",
	"...sstt.....st..",
]
const MUSHROOM_BIG := [
	"......CCC.......",
	"....CCCccck.....",
	"...CCcccccck....",
	"..CccCcccccck...",
	"..kcccccccckk...",
	"...kkkkkkkkk....",
	"......sst.......",
	"......sst.......",
	"......sst.......",
	"......sst.......",
	".....ssstt......",
]
const ROCKS := [
	"..rrR.....rR....",
	".rrRRR...rRRR...",
	".rRRRRq..RRRRq..",
	"rRRRRRqq.RRRqq..",
]
const LANTERN := [
	"................",
	".......hg.......",
	"......hhgq......",
	"....hhhhggqq....",
	"..hhhhhhhggggq..",
	".qqqqqqqqqqqqqq.",
	"...hggggggggq...",
	"...hgwwwwwwgq...",
	"...hgwWWWWwgq...",
	"...hgwWWWWwgq...",
	"...hgwwwwwwgq...",
	"...hggggggggq...",
	"..hhhhhgggggqq..",
	"......hggq......",
	"......hggq......",
	"......hggq......",
	"......hggq......",
	"......hggq......",
	"......hggq......",
	".....hhgggq.....",
	"....hhhggggq....",
	"...hhhhgggggq...",
	"...qqqqqqqqqq...",
	"................",
]

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)

	var atlas := Image.create_empty(8 * T, 5 * T, false, Image.FORMAT_RGBA8)
	for mask in 16:
		draw_terrain(atlas, Vector2i(mask % 8, mask / 8), mask, 0)
	draw_terrain(atlas, Vector2i(0, 2), 15, 1)
	draw_terrain(atlas, Vector2i(1, 2), 15, 2)
	draw_terrain(atlas, Vector2i(2, 2), 14, 1)
	draw_terrain(atlas, Vector2i(3, 2), 14, 2)
	draw_ledge(atlas, Vector2i(4, 2), true, false)
	draw_ledge(atlas, Vector2i(5, 2), false, false)
	draw_ledge(atlas, Vector2i(6, 2), false, true)
	draw_ledge(atlas, Vector2i(7, 2), true, true)
	draw_spikes(atlas, Vector2i(0, 3), false)
	draw_spikes(atlas, Vector2i(1, 3), true)
	draw_grass(atlas, Vector2i(2, 3), 11, 5, 5)
	draw_grass(atlas, Vector2i(3, 3), 23, 4, 4)
	draw_sprite(atlas, Vector2i(4, 3), MUSHROOMS_SMALL, PALETTE)
	draw_sprite(atlas, Vector2i(5, 3), MUSHROOM_BIG, PALETTE)
	draw_sprite(atlas, Vector2i(6, 3), ROCKS, PALETTE)
	draw_grass(atlas, Vector2i(7, 3), 37, 7, 10)
	draw_vine(atlas, Vector2i(0, 4), 0)
	draw_vine(atlas, Vector2i(1, 4), 1)
	draw_vine(atlas, Vector2i(2, 4), 2)
	draw_hanging_moss(atlas, Vector2i(3, 4))
	draw_terrain(atlas, Vector2i(4, 4), 15, 0, 1)
	draw_terrain(atlas, Vector2i(5, 4), 15, 1, 2)
	atlas.save_png(OUT_DIR + "cave_tiles.png")

	make_platform().save_png(OUT_DIR + "platform.png")
	make_lantern().save_png(OUT_DIR + "checkpoint.png")

	DirAccess.make_dir_recursive_absolute(COMBAT_DIR)
	for sheet in ["Idle", "Attack", "Dead"]:
		recolor("res://assets/Character/%s.png" % sheet, ENEMY_COLORS).save_png(COMBAT_DIR + "ninja_%s.png" % sheet.to_lower())
	make_shuriken().save_png(COMBAT_DIR + "shuriken.png")
	make_slash().save_png(COMBAT_DIR + "slash.png")
	print("Pixel art written to ", OUT_DIR, " and ", COMBAT_DIR)
	quit()

func draw_terrain(img: Image, cell: Vector2i, mask: int, variant: int, shade := 0) -> void:
	var o := cell * T
	var n := (mask & 1) != 0
	var e := (mask & 2) != 0
	var s := (mask & 4) != 0
	var w := (mask & 8) != 0

	var crack := {}
	for i in T:
		crack[Vector2i(i, 15)] = true
		crack[Vector2i(15, i)] = true
	for seg in CRACKS[variant]:
		for x in range(seg[0], seg[2] + 1):
			for y in range(seg[1], seg[3] + 1):
				crack[Vector2i(x, y)] = true

	var rng := RandomNumberGenerator.new()
	rng.seed = mask * 97 + variant * 13 + 1
	var colors: Array = ROCK_SHADES[shade]
	for y in T:
		for x in T:
			var p := Vector2i(x, y)
			var c: Color = colors[1]
			if crack.has(p):
				c = colors[0]
			elif y == 0 or crack.has(p + Vector2i.UP):
				c = colors[2]
			elif (x == 0 or crack.has(p + Vector2i.LEFT)) and rng.randf() < 0.6:
				c = colors[2]
			elif rng.randf() < 0.05:
				c = colors[3]
			img.set_pixelv(o + p, c)

	if not w:
		for y in T:
			img.set_pixelv(o + Vector2i(0, y), OUTLINE)
	if not e:
		for y in T:
			img.set_pixelv(o + Vector2i(15, y), OUTLINE)
			img.set_pixelv(o + Vector2i(14, y), CRACK)
	if not s:
		for x in T:
			img.set_pixelv(o + Vector2i(x, 15), OUTLINE)
			img.set_pixelv(o + Vector2i(x, 14), CRACK)
		if not w:
			img.set_pixelv(o + Vector2i(0, 15), CLEAR)
		if not e:
			img.set_pixelv(o + Vector2i(15, 15), CLEAR)
	if not n:
		# Grass band: rows 0-1 are blade tips only, the solid surface starts at row 2.
		var shift := variant * 5
		for x in T:
			var tip: int = GRASS_TIPS[(x + shift) % T]
			var drip: int = MOSS_DRIPS[(x + shift) % T]
			img.set_pixelv(o + Vector2i(x, 0), MOSS_TIP if tip == 2 else CLEAR)
			img.set_pixelv(o + Vector2i(x, 1), [CLEAR, MOSS_TIP, MOSS_L][tip])
			img.set_pixelv(o + Vector2i(x, 2), MOSS_L)
			img.set_pixelv(o + Vector2i(x, 3), MOSS)
			for y in range(4, 5 + drip):
				img.set_pixelv(o + Vector2i(x, y), MOSS_D)
		if not w:
			img.set_pixelv(o + Vector2i(0, 2), CLEAR)
		if not e:
			img.set_pixelv(o + Vector2i(15, 2), CLEAR)

func draw_ledge(img: Image, cell: Vector2i, left_end: bool, right_end: bool) -> void:
	var o := cell * T
	for x in T:
		var tip: int = GRASS_TIPS[(x + 3) % T]
		img.set_pixelv(o + Vector2i(x, 0), MOSS_TIP if tip == 2 else CLEAR)
		img.set_pixelv(o + Vector2i(x, 1), [CLEAR, MOSS_TIP, MOSS_L][tip])
		img.set_pixelv(o + Vector2i(x, 2), MOSS_L)
		img.set_pixelv(o + Vector2i(x, 3), MOSS)
		img.set_pixelv(o + Vector2i(x, 4), MOSS_D if MOSS_DRIPS[x] >= 2 else STONE_HI)
		img.set_pixelv(o + Vector2i(x, 5), CRACK if x % 8 == 7 else STONE)
		img.set_pixelv(o + Vector2i(x, 6), CRACK if x % 8 == 7 else STONE)
		img.set_pixelv(o + Vector2i(x, 7), OUTLINE)
	for end in [[left_end, 0, 1], [right_end, 15, 14]]:
		if not end[0]:
			continue
		for y in 8:
			img.set_pixelv(o + Vector2i(end[1], y), CLEAR)
		for y in range(4, 7):
			img.set_pixelv(o + Vector2i(end[2], y), OUTLINE)
		img.set_pixelv(o + Vector2i(end[2], 7), CLEAR)

func draw_spikes(img: Image, cell: Vector2i, flip: bool) -> void:
	var tmp := Image.create_empty(T, T, false, Image.FORMAT_RGBA8)
	for spec in [[2.5, 7], [7.5, 9], [12.5, 7]]:
		var cx: float = spec[0]
		var h: int = spec[1]
		for i in h:
			var half := 2.0 * (1.0 - float(i) / h) + 0.2
			for x in T:
				var dx := x + 0.5 - (cx + 0.5)
				if absf(dx) <= half:
					var c := THORN_L if dx <= 0.0 else THORN_M
					tmp.set_pixel(x, 15 - i, THORN_D if i == 0 else c)
	add_outline(tmp)
	if flip:
		tmp.flip_y()
	img.blit_rect(tmp, Rect2i(0, 0, T, T), cell * T)

func draw_grass(img: Image, cell: Vector2i, seed: int, blades: int, max_height: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var o := cell * T
	for b in blades:
		var bx := rng.randi_range(2, 13)
		var h := rng.randi_range(3, max_height)
		var lean := rng.randi_range(-1, 1)
		for i in h:
			var x := bx + (lean if i >= h * 2 / 3 else 0)
			var c := MOSS_D if i < h / 3 else (MOSS_TIP if i == h - 1 else MOSS)
			img.set_pixelv(o + Vector2i(x, 15 - i), c)

func draw_sprite(img: Image, cell: Vector2i, rows: Array, palette: Dictionary) -> void:
	var tmp := Image.create_empty(T, T, false, Image.FORMAT_RGBA8)
	var top := T - rows.size()
	for y in rows.size():
		for x in T:
			var ch: String = rows[y][x]
			if palette.has(ch):
				tmp.set_pixel(x, top + y, palette[ch])
	add_outline(tmp)
	img.blit_rect(tmp, Rect2i(0, 0, T, T), cell * T)

func draw_vine(img: Image, cell: Vector2i, part: int) -> void:
	# part 0 = top (attached to ceiling), 1 = middle, 2 = end.
	var o := cell * T
	var length := 11 if part == 2 else T
	for y in length:
		# Period of 16 so segments line up when stacked.
		var x := 7 + roundi(sin(TAU * y / T) * 1.5)
		img.set_pixelv(o + Vector2i(x, y), VINE_D)
		img.set_pixelv(o + Vector2i(x + 1, y), VINE)
		if y % 6 == (1 + part * 2) % 6 and y < length - 1:
			var side := -1 if (y / 6 + part) % 2 == 0 else 2
			img.set_pixelv(o + Vector2i(x + side, y), LEAF)
			img.set_pixelv(o + Vector2i(x + side + signi(side), y + 1), LEAF)
	if part == 2:
		for p in [Vector2i(6, 11), Vector2i(7, 11), Vector2i(8, 11), Vector2i(9, 11), Vector2i(7, 12), Vector2i(8, 12), Vector2i(8, 13)]:
			img.set_pixelv(o + p, LEAF)
		img.set_pixelv(o + Vector2i(7, 13), MOSS_TIP)

func draw_hanging_moss(img: Image, cell: Vector2i) -> void:
	var o := cell * T
	var lengths := [2, 4, 1, 5, 3, 0, 2, 6, 3, 1, 4, 2, 0, 3, 5, 1]
	for x in T:
		for y in lengths[x]:
			var c := MOSS_D if y < lengths[x] - 1 else MOSS
			img.set_pixelv(o + Vector2i(x, y), c)

func make_platform() -> Image:
	var w := 3 * T
	var img := Image.create_empty(w, 10, false, Image.FORMAT_RGBA8)
	for x in w:
		var tip: int = GRASS_TIPS[x % T]
		img.set_pixel(x, 0, MOSS_TIP if tip == 2 else CLEAR)
		img.set_pixel(x, 1, [CLEAR, MOSS_TIP, MOSS_L][tip])
		img.set_pixel(x, 2, MOSS_L)
		img.set_pixel(x, 3, MOSS)
		img.set_pixel(x, 4, MOSS_D if MOSS_DRIPS[x % T] >= 2 else STONE_HI)
		for y in range(5, 8):
			img.set_pixel(x, y, CRACK if x % T == 15 else STONE)
		img.set_pixel(x, 8, CRACK)
		img.set_pixel(x, 9, OUTLINE)
	for x in [0, w - 1]:
		for y in range(3, 10):
			img.set_pixel(x, y, OUTLINE)
		for y in 3:
			img.set_pixel(x, y, CLEAR)
		img.set_pixel(x, 9, CLEAR)
	return img

func make_lantern() -> Image:
	var img := Image.create_empty(2 * T, LANTERN.size(), false, Image.FORMAT_RGBA8)
	for frame in 2:
		var palette := LANTERN_PALETTE.merged(WINDOW_LIT if frame == 1 else WINDOW_UNLIT)
		var tmp := Image.create_empty(T, LANTERN.size(), false, Image.FORMAT_RGBA8)
		for y in LANTERN.size():
			for x in T:
				var ch: String = LANTERN[y][x]
				if palette.has(ch):
					tmp.set_pixel(x, y, palette[ch])
		add_outline(tmp)
		img.blit_rect(tmp, Rect2i(0, 0, T, LANTERN.size()), Vector2i(frame * T, 0))
	return img

func add_outline(img: Image) -> void:
	var src := img.duplicate() as Image
	for y in img.get_height():
		for x in img.get_width():
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var p: Vector2i = Vector2i(x, y) + d
				if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height() and src.get_pixelv(p).a > 0.0:
					img.set_pixel(x, y, OUTLINE)
					break

func recolor(path: String, colors: Dictionary) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			var key := c.to_html(false)
			if c.a > 0.0 and colors.has(key):
				img.set_pixel(x, y, colors[key])
	return img

func make_shuriken() -> Image:
	var img := Image.create_empty(9, 9, false, Image.FORMAT_RGBA8)
	for y in SHURIKEN.size():
		for x in SHURIKEN[y].length():
			var ch: String = SHURIKEN[y][x]
			if SHURIKEN_PALETTE.has(ch):
				img.set_pixel(x + 1, y + 1, SHURIKEN_PALETTE[ch])
	add_outline(img)
	return img

# Three 24x24 frames of a sword arc facing right, thinning and fading out.
func make_slash() -> Image:
	var size := 24
	var img := Image.create_empty(size * 3, size, false, Image.FORMAT_RGBA8)
	var centre := Vector2(-2, size / 2.0)
	var outer := 21.0
	for f in 3:
		var thickness: float = [7.0, 5.0, 2.5][f]
		var max_angle: float = [60.0, 70.0, 80.0][f]
		var alpha: float = [1.0, 0.85, 0.55][f]
		for y in size:
			for x in size:
				var d := Vector2(x + 0.5, y + 0.5) - centre
				var angle := absf(rad_to_deg(d.angle()))
				if angle > max_angle:
					continue
				var t := thickness * (1.0 - pow(angle / max_angle, 2.0))
				var r := d.length()
				if r <= outer and r >= outer - t:
					var c := Color.WHITE if r > outer - 1.5 else Color("9fe8ff")
					c.a = alpha
					img.set_pixel(f * size + x, y, c)
	return img
