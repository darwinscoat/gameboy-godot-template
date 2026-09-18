extends Area2D

signal hit
signal hp_changed(hp, max_hp)
signal coins_changed(coins)
signal scored(points)

const STATS = {"hp": "max_hp", "move": "speed", "magnet": "magnet_radius", "damage": "damage", "count": "count", "spin": "speed", "flip": "flip_cooldown", "dash_cooldown": "dash_cooldown", "dash": "dash_distance", "iframes": "dash_iframes"}

@export var speed: float = 35.0
@export var max_hp: int = 6
@export var magnet_radius: float = 24.0
@export var invulnerable_time: float = 0.8
@export var knockback_speed: float = 80.0
@export var knockback_time: float = 0.2
@export var shake_time: float = 0.15
@export var shake_pixels: int = 2
@export var death_time: float = 1.0
@export var spawn_grace: float = 1.0
@export var low_hp: int = 2
@export_group("Dash")
@export var dash_distance: float = 24.0
@export var dash_time: float = 0.15
@export var dash_cooldown: float = 1.5
@export var dash_iframes: float = 0.1
@export var dash_iframes_bonus: float = 0.05
@export_group("")
@export var cats: Array[SpriteFrames]

var hp = 6
var invulnerable_left = 0.0
var knockback = Vector2.ZERO
var shake_left = 0.0
var coins = 0
var hits = 0
var dash_left = 0.0
var dash_wait = 0.0
var dash_dir = Vector2.RIGHT
var dead = false
var hurt = false
var levels = {}
var base = {}


func _ready():
	hide()
	for stat in STATS:
		base[stat] = holder(stat).get(STATS[stat])


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
	dash_wait = maxf(dash_wait - delta, 0.0)
	dash_left = maxf(dash_left - delta, 0.0)
	if Input.is_action_just_pressed("a"):
		$Sword.flip()
	if Input.is_action_just_pressed("b") and dash_wait == 0.0:
		dash_dir = velocity.normalized() if velocity.length() > 0.0 else Vector2(-1.0 if $AnimatedSprite2D.flip_h else 1.0, 0.0)
		dash_left = dash_time
		dash_wait = dash_cooldown
		invulnerable_left = maxf(invulnerable_left, dash_iframes)
		Sfx.play("player_dash")
	if dash_left > 0.0:
		velocity = dash_dir * dash_distance / dash_time
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
	hits += 1
	hp_changed.emit(hp, max_hp)
	hurt = true
	Sfx.play("player_hit")
	if hp > 0 and hp <= low_hp and hp + amount > low_hp:
		Sfx.play("low_hp")
	invulnerable_left = invulnerable_time
	knockback = (global_position - from).normalized() * knockback_speed
	shake(shake_time)
	if hp <= 0:
		die()


func die():
	dead = true
	Sfx.play("player_death")
	invulnerable_left = 0.0
	$AnimatedSprite2D.visible = true
	$AnimatedSprite2D.play("death")
	hit.emit()
	await get_tree().create_timer(death_time).timeout
	hide()


func start(pos):
	position = pos
	dead = false
	levels = {}
	for stat in STATS:
		holder(stat).set(STATS[stat], base[stat])
	$Sword.rebuild()
	hp = max_hp
	hp_changed.emit(hp, max_hp)
	coins = 0
	coins_changed.emit(coins)
	hits = 0
	dash_left = 0.0
	dash_wait = 0.0
	invulnerable_left = spawn_grace
	hurt = false
	knockback = Vector2.ZERO
	show()


func set_cat(index):
	$AnimatedSprite2D.sprite_frames = cats[index]


func add_coins(amount):
	coins += amount
	coins_changed.emit(coins)


func heal(amount) -> bool:
	if hp >= max_hp:
		return false
	hp = mini(hp + amount, max_hp)
	hp_changed.emit(hp, max_hp)
	return true


func holder(stat) -> Node:
	return $Sword if stat in ["damage", "count", "spin", "flip"] else self


func level(upgrade) -> int:
	return levels.get(upgrade, 0)


func apply(upgrade):
	levels[upgrade] = level(upgrade) + 1
	if upgrade.stat == "heal":
		heal(int(upgrade.amount))
		return
	if upgrade.stat == "score":
		scored.emit(int(upgrade.amount))
		return
	var node = holder(upgrade.stat)
	var value = node.get(STATS[upgrade.stat])
	node.set(STATS[upgrade.stat], value + (int(upgrade.amount) if value is int else upgrade.amount))
	if upgrade.stat == "hp":
		heal(int(upgrade.amount))
	elif upgrade.stat == "count":
		$Sword.rebuild()
	elif upgrade.stat == "dash":
		dash_iframes += dash_iframes_bonus
