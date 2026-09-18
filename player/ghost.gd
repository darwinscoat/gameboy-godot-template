extends Area2D

@export var speed: float = 120.0
@export var reach: float = 40.0
@export var spin: float = 24.0

var direction = Vector2.RIGHT
var damage = 2
var hits = 1
var bitten = {}
var travelled = 0.0
var step = 0.0


func _physics_process(delta):
	var move = direction * speed * delta
	position += move
	travelled += move.length()
	step += spin * delta
	var facing = int(step) % 16
	rotation = (facing / 4) * TAU / 4
	$Sprite2D.frame = facing % 4
	visible = Engine.get_physics_frames() % 2 == 0
	for hurtbox in get_overlapping_areas():
		var enemy = hurtbox.get_parent()
		if bitten.has(enemy):
			continue
		bitten[enemy] = true
		enemy.take_damage(damage, global_position)
		if bitten.size() >= hits:
			queue_free()
			return
	if travelled >= reach:
		queue_free()
