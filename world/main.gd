extends Node

var score = 0


func game_over():
	$Director.stop()
	$HUD.show_game_over()


func new_game():
	score = 0
	$Player.start(Vector2.ZERO)
	$HUD.update_score(score)
	$HUD.show_message("Get Ready")
	get_tree().call_group("enemies", "queue_free")
	get_tree().call_group("pickups", "queue_free")
	$Director.start_run()


func add_score(points):
	score += points
	$HUD.update_score(score)


func _on_director_wave_started(number, banner):
	$HUD.show_message(banner if banner != "" else "Wave %d" % number)


func _on_director_wave_finished(_number):
	$HUD.show_message("Wave complete")


func _on_director_elite_spawned(kind):
	$HUD.show_message("Elite %s!" % kind.capitalize())
	$Player.shake(0.3)


func _on_director_run_won():
	$Director.stop()
	$HUD.show_game_over("You win")
