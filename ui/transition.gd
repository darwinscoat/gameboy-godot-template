extends CanvasLayer

signal covered
signal revealed

@export var tile: int = 8
@export var cover_time: float = 0.4
@export var reveal_time: float = 0.4
@export var hold_time: float = 0.1
@export var flip_time: float = 0.15
@export var jitter: float = 0.0
@export var origin: Vector2 = Vector2(1, 1)
@export_enum("line", "arc") var front: String = "line"
@export_enum("fold", "flip") var style: String = "fold"
@export var same_path: bool = true
@export var checker: bool = true
@export var shades: Array[Color] = [Color(0.631, 0.631, 0.631), Color(0.341, 0.341, 0.341), Color.BLACK]

var cols = 0
var rows = 0
var waves = []
var noise = []
var phase = ""
var t = 0.0
var length = 0.0


func _ready():
	var size = get_viewport().get_visible_rect().size
	cols = ceili(size.x / tile)
	rows = ceili(size.y / tile)
	$Tiles.draw.connect(draw_tiles)


func _process(delta):
	if phase == "" or phase == "hold":
		return
	t += delta
	$Tiles.queue_redraw()
	if t < length:
		return
	if phase == "cover":
		phase = "hold"
		covered.emit()
	else:
		phase = ""
		$Tiles.queue_redraw()
		revealed.emit()


func cover():
	waves = []
	noise = []
	var far = 0.0
	for i in cols * rows:
		var away = (Vector2(i % cols + 0.5, i / cols + 0.5) / Vector2(cols, rows) - origin).abs()
		waves.append(away.x + away.y if front == "line" else away.length())
		noise.append(randf() * jitter)
		far = maxf(far, waves[i])
	for i in waves.size():
		waves[i] /= far
	phase = "cover"
	t = 0.0
	length = cover_time + jitter
	Sfx.play("curtain_cover")
	await covered


func reveal():
	phase = "reveal"
	t = -hold_time
	length = reveal_time + jitter
	Sfx.play("curtain_reveal")
	await revealed


func progress(i) -> float:
	if phase == "hold":
		return 1.0
	var span = cover_time if phase == "cover" else reveal_time
	var wave = waves[i] if phase == "cover" or same_path else 1.0 - waves[i]
	var p = clampf((t - wave * (span - flip_time) - noise[i]) / flip_time, 0.0, 1.0)
	return p if phase == "cover" else 1.0 - p


func draw_tiles():
	if phase == "":
		return
	for i in cols * rows:
		var p = progress(i)
		if p <= 0.0:
			continue
		var col = i % cols
		var row = i / cols
		var shade = shades[mini(int(p * shades.size()), shades.size() - 1)]
		if style == "fold":
			fold(col * tile, row * tile, p, shade)
			continue
		var size = ceili(p * tile)
		var rect = Rect2(col * tile + (tile - size) / 2, row * tile, size, tile)
		if checker and (col + row) % 2 == 1:
			rect = Rect2(col * tile, row * tile + (tile - size) / 2, tile, size)
		$Tiles.draw_rect(rect, shade)


func fold(x, y, p, shade):
	var edge = tile if p < 0.5 else roundi(tile * (1.0 - (p - 0.5) * 2.0))
	for line in tile:
		var from = maxi(edge - line, 0)
		if from < tile:
			$Tiles.draw_rect(Rect2(x + from, y + line, tile - from, 1), shade)
