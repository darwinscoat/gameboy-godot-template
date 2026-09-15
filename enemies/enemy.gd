class_name Enemy
extends RigidBody2D

signal died(points)

@export var chase_speed: float = 20.0
@export var turn_speed: float = 10.0
@export var despawn_distance: float = 200.0
@export var max_hp: int = 4
@export var hit_cooldown: float = 0.25
@export var knockback_speed: float = 100.0
@export var coin_value: int = 1
@export var score_value: int = 10
@export var offscreen_distance: float = 110.0
@export var coin_scene: PackedScene
@export var heart_scene: PackedScene
@export var heart_chance: float = 0.05
@export var flee_multiplier: float = 2.0
@export_group("Elite")
@export var elite_hp_multiplier: int = 4
@export var elite_coin_multiplier: int = 10
@export var elite_score_multiplier: int = 4
@export var elite_speed_multiplier: float = 0.8
@export var elite_offscreen_multiplier: float = 2.0
@export var rain_slide_speed: float = 80.0

var target: Node2D
var hp = 2
var stun_left = 0.0
var dying = false
var fleeing = false
var elite = false
var crown_x = 0.0
var state = ""
var state_left = 0.0


func _ready():
	hp = max_hp
	crown_x = $Crown.position.x
	set_anim("walk")
	target = get_tree().get_first_node_in_group("player")


func _physics_process(delta):
	if dying or target == null:
		return
	var to_player = target.global_position - global_position
	if to_player.length() > despawn_distance and not elite:
		queue_free()
		return
	if fleeing:
		linear_velocity = -to_player.normalized() * chase_speed * flee_multiplier
		face(linear_velocity.x < 0)
		return
	stun_left = maxf(stun_left - delta, 0.0)
	$AnimatedSprite2D.modulate = Color(4, 4, 4) if stun_left > 0.0 else Color.WHITE
	if not target.visible:
		set_anim("walk")
		return
	if stun_left > 0.0:
		return
	state_left = maxf(state_left - delta, 0.0)
	steer(to_player, delta)


func steer(to_player, delta):
	chase(to_player, delta)


func chase(to_player, delta):
	var speed = chase_speed * (elite_offscreen_multiplier if elite and to_player.length() > offscreen_distance else 1.0)
	var wanted_velocity = to_player.normalized() * speed
	linear_velocity = linear_velocity.lerp(wanted_velocity, minf(turn_speed * delta, 1.0))
	face(linear_velocity.x < 0)


func face(left):
	$AnimatedSprite2D.flip_h = left
	$Crown.position.x = -crown_x if left else crown_x


func make_elite():
	elite = true
	max_hp *= elite_hp_multiplier
	coin_value *= elite_coin_multiplier
	score_value *= elite_score_multiplier
	chase_speed *= elite_speed_multiplier
	$Hitbox.damage += 1
	$Crown.show()


func flee():
	if elite:
		return
	fleeing = true
	stun_left = 0.0
	$AnimatedSprite2D.modulate = Color.WHITE
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)
	$Hurtbox/CollisionShape2D.set_deferred("disabled", true)


func enter(next, time):
	state = next
	state_left = time


func set_anim(name):
	if $AnimatedSprite2D.animation != name or not $AnimatedSprite2D.is_playing():
		$AnimatedSprite2D.play(name)


func take_damage(amount, from):
	if stun_left > 0.0 or dying:
		return
	hp -= amount
	stun_left = hit_cooldown
	linear_velocity = (global_position - from).normalized() * knockback_speed
	if hp <= 0:
		die()


func die():
	dying = true
	died.emit(score_value)
	linear_velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", true)
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)
	$Hurtbox/CollisionShape2D.set_deferred("disabled", true)
	$AnimatedSprite2D.modulate = Color.WHITE
	set_anim("death")
	for i in (coin_value if elite else 1):
		var coin = coin_scene.instantiate()
		coin.position = position
		coin.value = 1 if elite else coin_value
		if elite:
			coin.slide_speed = rain_slide_speed
			coin.slide_spread = PI
		get_parent().add_child(coin)
	var hearts_needed = (target.max_hp - target.hp + 1) / 2 - get_tree().get_nodes_in_group("hearts").size() if target else 0
	if heart_scene and hearts_needed > 0 and randf() < heart_chance:
		var heart = heart_scene.instantiate()
		heart.position = position
		get_parent().add_child(heart)
	await $AnimatedSprite2D.animation_finished
	queue_free()
