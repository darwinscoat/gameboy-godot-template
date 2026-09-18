class_name Enemy
extends RigidBody2D

signal died(points)

@export var chase_speed: float = 20.0
@export var turn_speed: float = 10.0
@export var despawn_distance: float = 200.0
@export var max_hp: int = 4
@export var hit_cooldown: float = 0.25
@export var hit_stun: float = 0.25
@export var knockback_speed: float = 100.0
@export var coin_value: int = 1
@export var score_value: int = 10
@export var offscreen_distance: float = 110.0
@export var coin_scene: PackedScene
@export var heart_scene: PackedScene
@export var hearts: bool = true
@export var vacuum_scene: PackedScene
@export var vacuum_chance: float = 0.05
@export var vacuum_cooldown: float = 60.0
@export var flee_multiplier: float = 2.0
@export_group("Elite")
@export var elite_hp_multiplier: int = 4
@export var elite_coin_multiplier: int = 7
@export var elite_score_multiplier: int = 4
@export var elite_speed_multiplier: float = 0.8
@export var elite_damage: int = 1
@export var rain_slide_speed: float = 80.0
@export var rain_spread: float = 0.5
@export var rain_stagger: float = 0.04
@export var rain_shudder: int = 2
@export var rain_values: Array[int] = [1]
@export var stun_gap: float = 2.0
@export_group("Boss")
@export var boss_offscreen_multiplier: float = 2.0

static var vacuum_ready = 0

var target: Node2D
var hp = 2
var stun_left = 0.0
var immune_left = 0.0
var stun_gap_left = 0.0
var dying = false
var fleeing = false
var elite = false
var boss = false
var crown_x = 0.0
var state = ""
var state_left = 0.0
var spawn_left = 0.0
var spawn_flicker = 0.0
var spawn_hitbox = true


func _ready():
	hp = max_hp
	crown_x = $Crown.position.x
	set_anim("walk")
	target = get_tree().get_first_node_in_group("player")


func _physics_process(delta):
	if dying or target == null:
		return
	var to_player = target.global_position - global_position
	if to_player.length() > despawn_distance and not boss:
		queue_free()
		return
	if fleeing:
		state_left = maxf(state_left - delta, 0.0)
		run(to_player, delta)
		return
	if spawn_left > 0.0:
		spawn_left = maxf(spawn_left - delta, 0.0)
		visible = spawn_left < spawn_flicker and int(spawn_left * 20) % 2 == 0
		if spawn_left == 0.0:
			visible = true
			$CollisionShape2D.set_deferred("disabled", false)
			$Hitbox/CollisionShape2D.set_deferred("disabled", not spawn_hitbox)
			$Hurtbox/CollisionShape2D.set_deferred("disabled", false)
		return
	stun_left = maxf(stun_left - delta, 0.0)
	immune_left = maxf(immune_left - delta, 0.0)
	stun_gap_left = maxf(stun_gap_left - delta, 0.0)
	$AnimatedSprite2D.modulate = Color(4, 4, 4) if immune_left > 0.0 else Color.WHITE
	if not target.visible:
		set_anim("walk")
		return
	if stun_left > 0.0:
		return
	state_left = maxf(state_left - delta, 0.0)
	steer(to_player, delta)


func steer(to_player, delta):
	chase(to_player, delta)


func run(to_player, _delta):
	linear_velocity = -to_player.normalized() * chase_speed * flee_multiplier
	face(linear_velocity.x < 0)
	set_anim("walk")


func chase(to_player, delta):
	var speed = chase_speed * (boss_offscreen_multiplier if boss and to_player.length() > offscreen_distance else 1.0)
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
	$Hitbox.damage += elite_damage
	$Crown.show()


func make_boss():
	boss = true


func materialise(delay, flicker):
	spawn_left = delay + flicker
	spawn_flicker = flicker
	spawn_hitbox = not $Hitbox/CollisionShape2D.disabled
	visible = false
	$CollisionShape2D.set_deferred("disabled", true)
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)
	$Hurtbox/CollisionShape2D.set_deferred("disabled", true)


func flee():
	if boss:
		return
	fleeing = true
	stun_left = 0.0
	immune_left = 0.0
	enter("", 0.0)
	$AnimatedSprite2D.modulate = Color.WHITE
	$AnimatedSprite2D.offset = Vector2.ZERO
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)
	$Hurtbox/CollisionShape2D.set_deferred("disabled", true)
	if coin_scene and spawn_left == 0.0:
		var coin = coin_scene.instantiate()
		coin.position = position
		coin.value = 1
		coin.slide_spread = PI
		get_parent().add_child(coin)


func enter(next, time):
	state = next
	state_left = time


func set_anim(name):
	if $AnimatedSprite2D.animation != name or not $AnimatedSprite2D.is_playing():
		$AnimatedSprite2D.play(name)


func take_damage(amount, from):
	if immune_left > 0.0 or dying:
		return
	hp -= amount
	immune_left = hit_cooldown
	Sfx.play("elite_hit" if elite else "enemy_hit")
	if stun_gap_left == 0.0:
		stun_left = hit_stun
		linear_velocity = (global_position - from).normalized() * knockback_speed
		if elite:
			stun_gap_left = stun_gap
	if hp <= 0:
		die()


func die():
	dying = true
	died.emit(score_value)
	Sfx.play("elite_death" if elite else "enemy_death")
	linear_velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", true)
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)
	$Hurtbox/CollisionShape2D.set_deferred("disabled", true)
	$AnimatedSprite2D.modulate = Color.WHITE
	if elite:
		$AnimatedSprite2D.pause()
	else:
		set_anim("death")
	var left = coin_value
	var i = 0
	while left > 0:
		var coin = coin_scene.instantiate()
		coin.position = position
		coin.value = mini(rain_values.pick_random(), left) if elite else left
		left -= coin.value
		i += 1
		if elite:
			coin.slide_speed = rain_slide_speed * randf_range(1.0 - rain_spread, 1.0)
			coin.slide_spread = PI
		get_parent().add_child(coin)
		if elite:
			$AnimatedSprite2D.offset.x = rain_shudder if i % 2 == 1 else -rain_shudder
			await get_tree().create_timer(randf() * rain_stagger, false).timeout
	$AnimatedSprite2D.offset = Vector2.ZERO
	var hearts_needed = (target.max_hp - target.hp + 1) / 2 - get_tree().get_nodes_in_group("hearts").size() if target else 0
	if heart_scene and hearts and boss and hearts_needed > 0:
		var heart = heart_scene.instantiate()
		heart.position = position
		get_parent().add_child(heart)
	if vacuum_scene and Time.get_ticks_msec() >= vacuum_ready and randf() < vacuum_chance:
		vacuum_ready = Time.get_ticks_msec() + int(vacuum_cooldown * 1000)
		var vacuum = vacuum_scene.instantiate()
		vacuum.position = position
		get_parent().add_child(vacuum)
	if elite:
		set_anim("death")
	if $AnimatedSprite2D.is_playing():
		await $AnimatedSprite2D.animation_finished
	queue_free()
