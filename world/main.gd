extends Node

@export var cash_rate: int = 1
@export var cash_tick: float = 0.02
@export var cash_chunks: int = 150
@export var bonus_step: int = 100

var score = 0
var bet_hits = -1


func _process(_delta):
	var offsets = []
	var hp = 0.0
	var max_hp = 0.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.boss and not enemy.dying:
			offsets.append(enemy.position - $Player.position)
			hp += enemy.hp
			max_hp += enemy.max_hp
	if $Director.running:
		$HUD.update_wave($Director.time_left / $Director.wave.duration, hp / max_hp if max_hp > 0.0 else -1.0)
	else:
		$HUD.hide_wave()
	$HUD.update_markers(offsets)
	if $Player.visible and not $Player.dead:
		var sword = $Player/Sword
		$HUD.update_abilities(1.0 - sword.flip_left / sword.flip_cooldown, 1.0 - $Player.dash_wait / $Player.dash_cooldown)
	else:
		$HUD.hide_abilities()


func game_over():
	Sfx.play("game_over")
	Music.play("game_over")
	$Director.stop()
	$Pause.enabled = false
	$HUD.show_game_over()
	Save.record(score, false)
	$HUD.update_best(Save.best)


func new_game():
	await $Transition.cover()
	score = 0
	bet_hits = -1
	Enemy.vacuum_ready = 0
	get_tree().call_group("enemies", "queue_free")
	get_tree().call_group("pickups", "queue_free")
	get_tree().call_group("shots", "queue_free")
	get_tree().call_group("ghosts", "queue_free")
	$Player.start(Vector2.ZERO)
	$Pause.enabled = true
	$HUD.update_score(score)
	$HUD.show_message("Get Ready")
	$Director.endless = $HUD.cat == 1
	$Director.start_run()
	Music.play("play")
	$Transition.reveal()


func add_score(points):
	score += points
	$HUD.update_score(score)


func cash_out():
	var step = maxi($Player.coins / cash_chunks, 1)
	while $Player.coins > 0:
		var amount = mini(step, $Player.coins)
		$Player.add_coins(-amount)
		add_score(amount * cash_rate)
		Sfx.play("score_tick")
		await get_tree().create_timer(cash_tick).timeout
	Save.record(score, true)
	$HUD.update_best(Save.best)


func pay(points):
	while points > 0:
		var step = mini(bonus_step, points)
		points -= step
		add_score(step)
		Sfx.play("score_tick")
		await get_tree().create_timer(cash_tick).timeout


func _on_hud_cat_changed(index):
	$Player.set_cat(index)


func _on_director_wave_started(number, banner):
	Sfx.play("wave_start")
	$HUD.show_message(banner if banner != "" else "Wave %d" % number)
	if $Director.flawless:
		$Director.flawless = false
		bet_hits = $Player.hits


func _on_director_wave_finished(number):
	Sfx.play("wave_end")
	$HUD.hide_wave()
	if bet_hits == $Player.hits:
		Sfx.play("flawless")
		$HUD.show_message("Flawless!", true)
		pay($Director.flawless_bonus * number)
	else:
		$HUD.show_message("Wave complete")
	bet_hits = -1


func _on_director_wave_cleared(number):
	if $Director.endless or number < $Director.waves.size():
		$HUD.hide_abilities()
		$HUD.hide_markers()
		$Shop.open($Director.rng)


func _on_director_boss_spawned(kind):
	Sfx.play("elite_spawn")
	Music.play("boss")
	$HUD.show_message(("The %s!" if kind == "queen" else "Elite %s!") % kind.capitalize(), true)
	$Player.shake(0.3)


func _on_director_run_won():
	Sfx.play("run_won")
	Music.play("win")
	$Director.stop()
	$Pause.enabled = false
	$HUD.show_game_over("You win")
	cash_out()


func _on_director_milestone(kind, count):
	Sfx.play("milestone")
	$HUD.show_message("%d %s!" % [count, {"bee": "bees", "fish": "fish", "snake": "snakes"}[kind]])


func _on_director_boss_died(_kind):
	Music.resume("play")
