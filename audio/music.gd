extends Node

@export var fade_time: float = 0.25
@export var silence_db: float = -40.0
@export var duck_db: float = -12.0

var current = ""
var fades = {}
var levels = {}
var ducking: Tween

@onready var bus = AudioServer.get_bus_index("Music")
@onready var bus_db = AudioServer.get_bus_volume_db(bus)


func _ready():
	for player in get_children():
		levels[player] = player.volume_db


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


func duck(on):
	if ducking:
		ducking.kill()
	ducking = create_tween()
	ducking.tween_method(func(db): AudioServer.set_bus_volume_db(bus, db), AudioServer.get_bus_volume_db(bus), bus_db + (duck_db if on else 0.0), fade_time)


func fade_in(name, player):
	if fades.has(name):
		fades[name].kill()
	player.volume_db = silence_db
	create_tween().tween_property(player, "volume_db", levels[player], fade_time)
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
