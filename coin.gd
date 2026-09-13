extends Area2D

@export var value = 1
@export var large_value = 3
@export var hop = 70.0
@export var bounce = 0.6
@export var slide_speed = 25.0
@export var slide_time = 1.0
@export var magnet_radius = 24.0
@export var magnet_speed = 90.0

var height = 0.0
var rise = 0.0
var slide = Vector2.ZERO
var target: Node2D


func _ready():
	rise = -hop
	slide = Vector2.from_angle(randf() * TAU) * slide_speed
	target = get_tree().get_first_node_in_group("player")
	$AnimatedSprite2D.play("large" if value >= large_value else "spin")


func _process(delta):
	rise += 200.0 * delta
	height += rise * delta
	if height > 0.0:
		height = 0.0
		rise = -rise * bounce if rise > 12.0 else 0.0
	$AnimatedSprite2D.position.y = height
	position += slide * delta
	slide = slide.move_toward(Vector2.ZERO, slide_speed / slide_time * delta)
	if target and target.visible and position.distance_to(target.position) < magnet_radius:
		position = position.move_toward(target.position, magnet_speed * delta)


func _on_area_entered(area):
	area.add_coins(value)
	queue_free()
