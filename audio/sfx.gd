extends Node


func play(name):
	var player = get_node_or_null(name.to_pascal_case())
	if player:
		player.play()
