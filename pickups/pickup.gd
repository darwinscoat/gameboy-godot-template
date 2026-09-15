class_name Pickup
extends Area2D

@export_group("Bounce")
@export var hop: float = 120.0
@export var hop_variance: float = 0.15
@export var hop_gravity: float = 420.0
@export var bounce: float = 0.6
@export var settle_rise: float = 25.0
@export_group("Slide")
@export var slide_speed: float = 35.0
@export var slide_time: float = 1.0
@export var slide_spread: float = 0.6
@export_group("Magnet")
@export var magnet_speed: float = 90.0
@export_group("Shadow")
@export var shadow_full_height: float = 20.0
@export_group("Sound")
@export var bounce_sound: String = "coin_bounce"

var height = 0.0
var rise = 0.0
var slide = Vector2.ZERO
var target: Node2D


func _ready():
	rise = -hop * randf_range(1.0 - hop_variance, 1.0 + hop_variance)
	target = get_tree().get_first_node_in_group("player")
	var away = (position - target.position).angle() if target and position.distance_to(target.position) > 1.0 else randf() * TAU
	slide = Vector2.from_angle(away + randf_range(-slide_spread, slide_spread)) * slide_speed


func _process(delta):
	rise += hop_gravity * delta
	height += rise * delta
	if height > 0.0:
		height = 0.0
		if rise > settle_rise:
			rise = -rise * bounce
			Sfx.play(bounce_sound)
		else:
			rise = 0.0
	$Sprite.position.y = height
	$Shadow.frame = roundi(lerpf($Shadow.hframes - 1, 0.0, clampf(-height / shadow_full_height, 0.0, 1.0)))
	position += slide * delta
	slide = slide.move_toward(Vector2.ZERO, slide_speed / slide_time * delta)
	if slide == Vector2.ZERO and target and target.visible and position.distance_to(target.position) < target.magnet_radius:
		position = position.move_toward(target.position, magnet_speed * delta)
	for area in get_overlapping_areas():
		if collect(area):
			queue_free()
			return


func collect(_player) -> bool:
	return true
