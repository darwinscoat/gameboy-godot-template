extends Node

signal wave_started(number, banner)
signal wave_finished(number)
signal wave_cleared(number)
signal run_won
signal scored(points)
signal boss_spawned(kind)
signal boss_died(kind)
signal milestone(kind, count)

const GROUP_SIZE = {"drip": 1, "pair": 2, "wall": 4, "ring": 6, "ambush": 1, "escort": 3}
const WALL_SPACING = 0.35
const ESCORT_SPREAD = 0.45
const AMBUSH_JITTER = 0.4

@export var waves: Array[WaveData]
@export var bee_scene: PackedScene
@export var fish_scene: PackedScene
@export var snake_scene: PackedScene
@export var queen_scene: PackedScene
@export var coin_scene: PackedScene
@export var spawn_distance: float = 120.0
@export var start_delay: float = 2.0
@export var collect_time: float = 4.0
@export var wave_gap: float = 3.0
@export var flee_lead: float = 5.0
@export var tick_seconds: int = 3
@export var run_seed: int = 0
@export var start_wave: int = 1
@export var endless: bool = false
@export_group("Endless")
@export var endless_duration: float = 50.0
@export var endless_cap: int = 12
@export var endless_cap_step: int = 1
@export var endless_cap_max: int = 20
@export var endless_pulse: float = 1.5
@export var endless_pulse_step: float = 0.05
@export var endless_pulse_min: float = 1.0
@export var elite_start: float = 0.05
@export var elite_step: float = 0.03
@export var queen_every: int = 10
@export var queen_at: float = 5.0
@export var queen_hp_step: float = 0.5
@export_group("Flawless")
@export var flawless_bonus: int = 100
@export_group("Snakes")
@export var snake_cap_step: int = 3
@export_group("Milestones")
@export var milestones: Array[int] = [10, 50]
@export var milestone_coins: Array[int] = [15, 30]
@export var rain_spread: Vector2 = Vector2(70, 60)
@export var rain_height: float = 60.0
@export var rain_stagger: float = 0.03
@export_group("Hearts")
@export var heart_scene: PackedScene
@export var heart_kills: int = 15
@export var heart_cooldown: float = 30.0

var rng = RandomNumberGenerator.new()
var player: Node2D
var player_dir = Vector2.RIGHT
var last_player_pos = Vector2.ZERO
var wave: WaveData
var wave_index = -1
var time_left = 0.0
var pulse_left = 0.0
var boss_done = false
var held = false
var last_second = 0
var running = false
var run_id = 0
var flawless = false
var kills = {}
var heart_meter = 0
var heart_wait = 0.0


func _process(delta):
	if not running:
		return
	var moved = player.position - last_player_pos
	if moved.length() > 0.1:
		player_dir = moved.normalized()
	last_player_pos = player.position
	time_left -= delta
	heart_wait = maxf(heart_wait - delta, 0.0)
	var boss = boss_alive()
	if time_left <= 0.0 and not boss:
		finish_wave()
		return
	var second = ceili(time_left)
	if second != last_second and second > 0 and second <= tick_seconds and wave.duration > tick_seconds:
		Sfx.play("timer_tick")
	last_second = second
	if time_left <= 0.0 and not held:
		held = true
		Sfx.play("boss_hold")
	if wave.boss != "" and not boss_done and wave.duration - time_left >= wave.boss_at:
		boss_done = true
		spawn_one(wave.boss, rng.randf() * TAU, true)
	if time_left <= (0.0 if boss else flee_lead):
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
	kills = {}
	heart_meter = 0
	heart_wait = 0.0
	var id = run_id
	await get_tree().create_timer(start_delay, false).timeout
	if id == run_id:
		next_wave()


func stop():
	run_id += 1
	running = false
	flawless = false


func next_wave():
	wave_index += 1
	if wave_index >= waves.size() and not endless:
		run_won.emit()
		return
	if run_seed != 0:
		rng.seed = run_seed * 100 + wave_index
	else:
		rng.randomize()
	wave = waves[wave_index] if wave_index < waves.size() else make_wave(wave_index + 1)
	time_left = wave.duration
	pulse_left = wave.pulse_interval
	boss_done = false
	held = false
	last_second = 0
	running = true
	wave_started.emit(wave_index + 1, wave.banner)
	if wave.opener != "":
		spawn_group(wave.opener)


func make_wave(number: int) -> WaveData:
	var n = number - waves.size()
	var made = WaveData.new()
	made.duration = endless_duration
	made.max_alive = mini(endless_cap + endless_cap_step * n, endless_cap_max)
	made.pulse_interval = maxf(endless_pulse - endless_pulse_step * n, endless_pulse_min)
	var kinds = ["bee", "fish", "snake"]
	var featured = kinds[rng.randi() % kinds.size()]
	for kind in kinds:
		made.set(kind, 1.0 if kind == featured else 0.5)
	for name in GROUP_SIZE:
		made.set(name, 0.5)
	made.set(GROUP_SIZE.keys()[rng.randi() % GROUP_SIZE.size()], 1.5)
	made.opener = ["", "ring", "wall", "escort"][rng.randi() % 4]
	made.elite_chance = minf(elite_start + elite_step * (n - 1), 1.0)
	if number % queen_every == 0:
		made.banner = "The Queen"
		made.boss = "queen"
		made.boss_at = queen_at
	return made


func finish_wave():
	running = false
	get_tree().call_group("enemies", "flee")
	wave_finished.emit(wave_index + 1)
	var id = run_id
	await get_tree().create_timer(collect_time, false).timeout
	if id != run_id:
		return
	wave_cleared.emit(wave_index + 1)
	await get_tree().create_timer(wave_gap, false).timeout
	if id == run_id:
		next_wave()


func alive() -> int:
	var count = 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.dying and not enemy.fleeing:
			count += 1
	return count


func boss_alive() -> bool:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.boss and not enemy.dying:
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
	var options = {"bee": wave.bee, "fish": wave.fish, "snake": wave.snake}
	if snakes_capped():
		options["snake"] = 0.0
	return weighted_pick(options)


func snakes_capped() -> bool:
	var number = wave_index + 1
	if number > waves.size():
		return false
	var cap = number / snake_cap_step
	var alive_snakes = 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.scene_file_path == snake_scene.resource_path and not enemy.boss and not enemy.dying and not enemy.fleeing:
			alive_snakes += 1
	return alive_snakes >= cap


func tally(kind: String, at: Vector2):
	fill_heart(at)
	kills[kind] = kills.get(kind, 0) + 1
	var step = milestones.find(kills[kind])
	if step >= 0:
		milestone.emit(kind, kills[kind])
		rain(milestone_coins[step])


func fill_heart(at: Vector2):
	if wave_index >= waves.size() or player.hp >= player.max_hp:
		return
	heart_meter += 1
	var needed = (player.max_hp - player.hp + 1) / 2 - get_tree().get_nodes_in_group("hearts").size()
	if heart_meter < heart_kills or heart_wait > 0.0 or needed <= 0:
		return
	heart_meter = 0
	heart_wait = heart_cooldown
	var heart = heart_scene.instantiate()
	heart.position = at
	add_sibling(heart)


func rain(count: int):
	var id = run_id
	for i in count:
		if id != run_id or player == null:
			return
		var coin = coin_scene.instantiate()
		coin.position = player.position + Vector2(randf_range(-rain_spread.x, rain_spread.x), randf_range(-rain_spread.y, rain_spread.y))
		coin.slide_speed = 0.0
		add_sibling(coin)
		coin.height = -rain_height * randf_range(0.6, 1.0)
		coin.rise = 0.0
		coin.slide = Vector2.ZERO
		await get_tree().create_timer(rain_stagger, false).timeout


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


func spawn_one(kind: String, angle: float, boss := false):
	if kind == "snake" and not boss and snakes_capped():
		kind = pick_kind()
	var scene = {"bee": bee_scene, "fish": fish_scene, "snake": snake_scene, "queen": queen_scene}[kind]
	var enemy = scene.instantiate()
	enemy.position = player.position + Vector2.from_angle(angle) * spawn_distance
	if wave_index >= waves.size():
		enemy.hearts = false
	if boss:
		enemy.make_elite()
		enemy.make_boss()
		if kind == "queen" and endless:
			enemy.max_hp = roundi(enemy.max_hp * (1.0 + queen_hp_step * float(wave_index + 1 - waves.size()) / queen_every))
		boss_spawned.emit(kind)
		enemy.died.connect(func(_points): boss_died.emit(kind))
	elif rng.randf() < wave.elite_chance:
		enemy.make_elite()
	enemy.died.connect(func(points): scored.emit(points))
	enemy.died.connect(func(_points): tally(kind, enemy.position))
	add_sibling(enemy)
