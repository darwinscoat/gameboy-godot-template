extends Area2D

signal hit
signal hp_changed(hp, max_hp)

@export var speed = 35
@export var max_hp = 3
@export var invulnerable_time = 0.8
@export var knockback_speed = 80.0
@export var knockback_time = 0.2
@export var shake_time = 0.15

var hp = 3
var invulnerable_left = 0.0
var knockback = Vector2.ZERO
var shake_left = 0.0


func _ready():
	hide()


func _process(delta):
	shake_left = maxf(shake_left - delta, 0.0)
	$Camera2D.offset = Vector2(randi_range(-2, 2), randi_range(-2, 2)) if shake_left > 0.0 else Vector2.ZERO
	if not visible:
		return
	var velocity = Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1

	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		$AnimatedSprite2D.play()
		$AnimatedSprite2D.flip_h = velocity.x < 0
	else:
		$AnimatedSprite2D.stop()

	position += (velocity + knockback) * delta
	knockback = knockback.move_toward(Vector2.ZERO, knockback_speed / knockback_time * delta)

	invulnerable_left = maxf(invulnerable_left - delta, 0.0)
	$AnimatedSprite2D.visible = invulnerable_left == 0.0 or int(invulnerable_left * 10) % 2 == 0



func _physics_process(_delta):
	if not visible or invulnerable_left > 0.0:
		return
	for hitbox in get_overlapping_areas():
		take_damage(hitbox.damage, hitbox.global_position)
		return


func take_damage(amount, from):
	hp -= amount
	hp_changed.emit(hp, max_hp)
	invulnerable_left = invulnerable_time
	knockback = (global_position - from).normalized() * knockback_speed
	shake_left = shake_time
	if hp <= 0:
		hide()
		hit.emit()


func start(pos):
	position = pos
	hp = max_hp
	hp_changed.emit(hp, max_hp)
	invulnerable_left = 0.0
	knockback = Vector2.ZERO
	show()
