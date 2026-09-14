extends RigidBody2D

@export var chase_speed: float = 20.0
@export var turn_speed: float = 10.0
@export var despawn_distance: float = 200.0
@export var max_hp: int = 2
@export var hit_cooldown: float = 0.25
@export var knockback_speed: float = 100.0
@export var coin_value: int = 1
@export var coin_scene: PackedScene

var target: Node2D
var hp = 2
var stun_left = 0.0
var dying = false


func _ready():
	hp = max_hp
	$AnimatedSprite2D.play("walk")
	target = get_tree().get_first_node_in_group("player")


func _physics_process(delta):
	if dying:
		return
	stun_left = maxf(stun_left - delta, 0.0)
	$AnimatedSprite2D.modulate = Color(4, 4, 4) if stun_left > 0.0 else Color.WHITE
	if stun_left > 0.0 or target == null or not target.visible:
		return
	var to_player = target.global_position - global_position
	if to_player.length() > despawn_distance:
		queue_free()
		return
	steer(to_player, delta)


func steer(to_player, delta):
	var wanted_velocity = to_player.normalized() * chase_speed
	linear_velocity = linear_velocity.lerp(wanted_velocity, minf(turn_speed * delta, 1.0))
	$AnimatedSprite2D.flip_h = linear_velocity.x < 0


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
	linear_velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", true)
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)
	$Hurtbox/CollisionShape2D.set_deferred("disabled", true)
	$AnimatedSprite2D.modulate = Color.WHITE
	$AnimatedSprite2D.play("death")
	var coin = coin_scene.instantiate()
	coin.position = position
	coin.value = coin_value
	get_parent().add_child(coin)
	await $AnimatedSprite2D.animation_finished
	queue_free()
