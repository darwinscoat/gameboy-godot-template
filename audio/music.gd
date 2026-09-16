extends Node

@export var fade_time: float = 0.25
@export var silence_db: float = -40.0

var current = ""
var positions = {}
var fades = {}


func play(name, from := 0.0):
	if name == current:
		return
	fade_out()
	var player = get_node_or_null(name.to_pascal_case())
	if player:
		if fades.has(name):
			fades[name].kill()
		player.volume_db = silence_db
		player.play(from)
		create_tween().tween_property(player, "volume_db", 0.0, fade_time)
	current = name


func resume(name):
	play(name, positions.get(name, 0.0))


func stop():
	fade_out()


func fade_out():
	if current == "":
		return
	var player = get_node(current.to_pascal_case())
	positions[current] = player.get_playback_position()
	var tween = create_tween()
	tween.tween_property(player, "volume_db", silence_db, fade_time)
	tween.tween_callback(player.stop)
	fades[current] = tween
	current = ""
