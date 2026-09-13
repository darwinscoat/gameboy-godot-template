extends RigidBody2D

@export var chase_speed: float = 20.0
@export var turn_speed: float = 10.0
@export var despawn_distance: float = 200.0
@export var max_hp = 2
@export var hit_cooldown = 0.25
@export var knockback_speed = 100.0
var target: Node2D
var hp = 2
var stun_left = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	hp = max_hp
	$AnimatedSprite2D.play("walk")
	target = get_tree().get_first_node_in_group("player")
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _physics_process(delta: float) -> void:
	stun_left = maxf(stun_left - delta, 0.0)
	$AnimatedSprite2D.modulate = Color(4, 4, 4) if stun_left > 0.0 else Color.WHITE
	if stun_left > 0.0 or target == null or not target.visible:
		return
	var to_player = target.global_position - global_position
	if to_player.length() > despawn_distance:
		queue_free()
		return
	var wanted_velocity = to_player.normalized() * chase_speed
	linear_velocity = linear_velocity.lerp(wanted_velocity, minf(turn_speed * delta, 1.0))
	$AnimatedSprite2D.flip_h = linear_velocity.x < 0


func take_damage(amount, from):
	if stun_left > 0.0:
		return
	hp -= amount
	stun_left = hit_cooldown
	linear_velocity = (global_position - from).normalized() * knockback_speed
	if hp <= 0:
		queue_free()
