extends Node

signal wave_started(number, banner)
signal wave_finished(number)
signal run_won
signal scored(points)
signal elite_spawned(kind)

const GROUP_SIZE = {"drip": 1, "pair": 2, "wall": 4, "ring": 6, "ambush": 1, "escort": 3}
const WALL_SPACING = 0.35
const ESCORT_SPREAD = 0.45
const AMBUSH_JITTER = 0.4

@export var waves: Array[WaveData]
@export var bee_scene: PackedScene
@export var fish_scene: PackedScene
@export var snake_scene: PackedScene
@export var spawn_distance: float = 120.0
@export var start_delay: float = 2.0
@export var wave_gap: float = 3.0
@export var flee_lead: float = 5.0
@export var run_seed: int = 0
@export var start_wave: int = 1

var rng = RandomNumberGenerator.new()
var player: Node2D
var player_dir = Vector2.RIGHT
var last_player_pos = Vector2.ZERO
var wave: WaveData
var wave_index = -1
var time_left = 0.0
var pulse_left = 0.0
var elite_done = false
var running = false
var run_id = 0


func _process(delta):
	if not running:
		return
	var moved = player.position - last_player_pos
	if moved.length() > 0.1:
		player_dir = moved.normalized()
	last_player_pos = player.position
	time_left -= delta
	var boss = elite_alive()
	if time_left <= 0.0 and not boss:
		finish_wave()
		return
	if wave.elite != "" and not elite_done and wave.duration - time_left >= wave.elite_at:
		elite_done = true
		spawn_one(wave.elite, rng.randf() * TAU, true)
	if time_left <= flee_lead and not boss:
		return
	pulse_left -= delta
	if pulse_left <= 0.0:
		pulse_left = wave.pulse_interval
		spawn_group(pick_grouping())


func start_run():
	run_id += 1
	running = false
	player = get_tree().get_first_node_in_group("player")
	wave_index = start_wave - 2
	var id = run_id
	await get_tree().create_timer(start_delay).timeout
	if id == run_id:
		next_wave()


func stop():
	run_id += 1
	running = false


func next_wave():
	wave_index += 1
	if wave_index >= waves.size():
		run_won.emit()
		return
	wave = waves[wave_index]
	if run_seed != 0:
		rng.seed = run_seed * 100 + wave_index
	else:
		rng.randomize()
	time_left = wave.duration
	pulse_left = wave.pulse_interval
	elite_done = false
	running = true
	wave_started.emit(wave_index + 1, wave.banner)
	if wave.opener != "":
		spawn_group(wave.opener)


func finish_wave():
	running = false
	get_tree().call_group("enemies", "flee")
	wave_finished.emit(wave_index + 1)
	var id = run_id
	await get_tree().create_timer(wave_gap).timeout
	if id == run_id:
		next_wave()


func alive() -> int:
	var count = 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.dying and not enemy.fleeing:
			count += 1
	return count


func elite_alive() -> bool:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.elite and not enemy.dying:
			return true
	return false


func pick_grouping() -> String:
	var room = wave.max_alive - alive()
	var options = {}
	for name in GROUP_SIZE:
		if wave.get(name) > 0.0 and GROUP_SIZE[name] <= room:
			options[name] = wave.get(name)
	if options.is_empty():
		return "drip" if room > 0 else ""
	return weighted_pick(options)


func pick_kind() -> String:
	return weighted_pick({"bee": wave.bee, "fish": wave.fish, "snake": wave.snake})


func weighted_pick(options: Dictionary) -> String:
	var total = 0.0
	for weight in options.values():
		total += weight
	var roll = rng.randf() * total
	for name in options:
		roll -= options[name]
		if roll <= 0.0:
			return name
	return options.keys().back()


func spawn_group(name: String):
	var angle = rng.randf() * TAU
	match name:
		"drip":
			spawn_one(pick_kind(), angle)
		"pair":
			var kind = pick_kind()
			spawn_one(kind, angle)
			spawn_one(kind, angle + PI)
		"wall":
			for i in GROUP_SIZE["wall"]:
				spawn_one("bee", angle + (i - 1.5) * WALL_SPACING)
		"ring":
			for i in GROUP_SIZE["ring"]:
				spawn_one("bee", angle + i * TAU / GROUP_SIZE["ring"])
		"ambush":
			spawn_one("snake", player_dir.angle() + PI + rng.randf_range(-AMBUSH_JITTER, AMBUSH_JITTER))
		"escort":
			spawn_one("fish", angle)
			spawn_one("bee", angle - ESCORT_SPREAD)
			spawn_one("bee", angle + ESCORT_SPREAD)


func spawn_one(kind: String, angle: float, elite := false):
	var scene = {"bee": bee_scene, "fish": fish_scene, "snake": snake_scene}[kind]
	var enemy = scene.instantiate()
	enemy.position = player.position + Vector2.from_angle(angle) * spawn_distance
	if elite:
		enemy.make_elite()
		elite_spawned.emit(kind)
	enemy.died.connect(func(points): scored.emit(points))
	add_sibling(enemy)
