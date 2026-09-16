extends Node

@export var fade_time: float = 0.25
@export var silence_db: float = -40.0

var current = ""
var fades = {}


func play(name):
	if name == current:
		return
	fade_out()
	var player = get_node_or_null(name.to_pascal_case())
	if player:
		player.stream_paused = false
		player.play()
		fade_in(name, player)


func resume(name):
	var player = get_node_or_null(name.to_pascal_case())
	if player == null or not player.stream_paused:
		play(name)
		return
	if name == current:
		return
	fade_out()
	player.stream_paused = false
	fade_in(name, player)


func stop():
	fade_out()


func fade_in(name, player):
	if fades.has(name):
		fades[name].kill()
	player.volume_db = silence_db
	create_tween().tween_property(player, "volume_db", 0.0, fade_time)
	current = name


func fade_out():
	if current == "":
		return
	var player = get_node(current.to_pascal_case())
	var tween = create_tween()
	tween.tween_property(player, "volume_db", silence_db, fade_time)
	tween.tween_callback(func(): player.stream_paused = true)
	fades[current] = tween
	current = ""
