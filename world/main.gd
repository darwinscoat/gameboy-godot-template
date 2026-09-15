extends Node

var score = 0


func _process(_delta):
	if $Director.running:
		$HUD.update_wave($Director.time_left / $Director.wave.duration, $Director.time_left <= 0.0 and $Director.elite_alive())
	else:
		$HUD.hide_wave()


func game_over():
	$Director.stop()
	$Pause.enabled = false
	$HUD.show_game_over()


func new_game():
	score = 0
	get_tree().call_group("enemies", "queue_free")
	get_tree().call_group("pickups", "queue_free")
	$Player.start(Vector2.ZERO)
	$Pause.enabled = true
	$HUD.update_score(score)
	$HUD.show_message("Get Ready")
	$Director.start_run()


func add_score(points):
	score += points
	$HUD.update_score(score)


func _on_director_wave_started(number, banner):
	$HUD.show_message(banner if banner != "" else "Wave %d" % number)


func _on_director_wave_finished(_number):
	$HUD.hide_wave()
	$HUD.show_message("Wave complete")


func _on_director_wave_cleared(number):
	if number < $Director.waves.size():
		$Shop.open($Director.rng)


func _on_director_elite_spawned(kind):
	$HUD.show_message("Elite %s!" % kind.capitalize())
	$Player.shake(0.3)


func _on_director_run_won():
	$Director.stop()
	$Pause.enabled = false
	add_score($Player.coins)
	$HUD.show_game_over("You win")
