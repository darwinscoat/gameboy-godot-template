extends Area2D

signal hit
signal hp_changed(hp, max_hp)
signal coins_changed(coins)

@export var speed: float = 35.0
@export var max_hp: int = 3
@export var invulnerable_time: float = 0.8
@export var knockback_speed: float = 80.0
@export var knockback_time: float = 0.2
@export var shake_time: float = 0.15
@export var shake_pixels: int = 2
@export var death_time: float = 1.0
@export var spawn_grace: float = 1.0

var hp = 3
var invulnerable_left = 0.0
var knockback = Vector2.ZERO
var shake_left = 0.0
var coins = 0
var dead = false
var hurt = false


func _ready():
	hide()


func _process(delta):
	shake_left = maxf(shake_left - delta, 0.0)
	$Camera2D.offset = Vector2(randi_range(-shake_pixels, shake_pixels), randi_range(-shake_pixels, shake_pixels)) if shake_left > 0.0 else Vector2.ZERO
	if dead or not visible:
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
		$AnimatedSprite2D.play("walk")
		if velocity.x != 0.0:
			$AnimatedSprite2D.flip_h = velocity.x < 0
	else:
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.stop()
	if invulnerable_left > 0.0 and hurt:
		$AnimatedSprite2D.play("hit")

	position += (velocity + knockback) * delta
	knockback = knockback.move_toward(Vector2.ZERO, knockback_speed / knockback_time * delta)

	invulnerable_left = maxf(invulnerable_left - delta, 0.0)
	if invulnerable_left == 0.0:
		hurt = false
	$AnimatedSprite2D.visible = not hurt or int(invulnerable_left * 10) % 2 == 0


func _physics_process(_delta):
	if dead or not visible or invulnerable_left > 0.0:
		return
	for hitbox in get_overlapping_areas():
		take_damage(hitbox.damage, hitbox.global_position)
		return


func shake(time):
	shake_left = time


func take_damage(amount, from):
	hp -= amount
	hp_changed.emit(hp, max_hp)
	hurt = true
	invulnerable_left = invulnerable_time
	knockback = (global_position - from).normalized() * knockback_speed
	shake(shake_time)
	if hp <= 0:
		die()


func die():
	dead = true
	invulnerable_left = 0.0
	$AnimatedSprite2D.visible = true
	$AnimatedSprite2D.play("death")
	hit.emit()
	await get_tree().create_timer(death_time).timeout
	hide()


func start(pos):
	position = pos
	dead = false
	hp = max_hp
	hp_changed.emit(hp, max_hp)
	coins = 0
	coins_changed.emit(coins)
	invulnerable_left = spawn_grace
	hurt = false
	knockback = Vector2.ZERO
	show()


func add_coins(amount):
	coins += amount
	coins_changed.emit(coins)


func heal(amount) -> bool:
	if hp >= max_hp:
		return false
	hp = mini(hp + amount, max_hp)
	hp_changed.emit(hp, max_hp)
	return true
