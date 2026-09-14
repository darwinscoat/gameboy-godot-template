extends Sprite2D

var target: Node2D


func _ready():
	target = get_tree().get_first_node_in_group("player")


func _process(_delta):
	var tile = texture.get_size()
	position = (target.position / tile).floor() * tile - region_rect.size / 2
