extends Node

@export var enemy_scenes: Array[PackedScene]
@export var spawn_distance: float = 120.0

var score = 0


func game_over():
	$ScoreTimer.stop()
	$SpawnTimer.stop()
	$HUD.show_game_over()


func new_game():
	score = 0
	$Player.start(Vector2.ZERO)
	$StartTimer.start()
	$HUD.update_score(score)
	$HUD.show_message("Get Ready")
	get_tree().call_group("enemies", "queue_free")
	get_tree().call_group("coins", "queue_free")


func _on_spawn_timer_timeout():
	var enemy = enemy_scenes.pick_random().instantiate()
	var direction = Vector2.from_angle(randf() * TAU)
	enemy.position = $Player.position + direction * spawn_distance
	add_child(enemy)


func _on_score_timer_timeout():
	score += 1
	$HUD.update_score(score)


func _on_start_timer_timeout():
	$SpawnTimer.start()
	$ScoreTimer.start()
