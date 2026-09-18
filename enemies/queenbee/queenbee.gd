extends Enemy

@export var hover_height: float = 6.0
@export var hover_range: float = 40.0
@export var hover_speed: float = 40.0
@export var orbit_speed: float = 0.5
@export var climb_speed: float = 60.0
@export var rest_time: float = 1.5
@export var shadow_full_height: float = 8.0
@export var shot_scene: PackedScene
@export var bee_scene: PackedScene
@export_group("Volley")
@export var volley_tell: float = 0.4
@export var volley_gap: float = 0.5
@export var volley_count: int = 2
@export var volley_shots: int = 3
@export var volley_spread: float = 0.5
@export var volley_range: float = 56.0
@export var retreat_speed: float = 80.0
@export var retreat_time: float = 0.6
@export_group("Swarm")
@export var summon_time: float = 1.5
@export var summon_height: float = 14.0
@export var summon_radius: float = 8.0
@export var summon_spin: float = TAU
@export var swarm_size: int = 4
@export var swarm_radius: float = 10.0
@export var swarm_step: float = 5.0
@export var swarm_turn: float = 1.6
@export var swarm_gap: float = 0.15
@export var swarm_flicker: float = 1.0
@export var swarm_cap: int = 6
@export_group("Swoop")
@export var swoop_tell: float = 0.6
@export var swoop_height: float = 24.0
@export var swoop_speed: float = 140.0
@export var nova_shots: int = 8
@export var vanish_time: float = 0.4
@export var vanish_shudder: float = 2.0
@export var blink_time: float = 0.6
@export var appear_time: float = 0.3
@export_group("Phases")
@export var rage_hp: float = 0.5
@export var rage_shots: int = 5
@export var rage_rest: float = 0.6
@export var frenzy_hp: float = 0.25
@export_group("Crown")
@export var crown_y: float = -10.0
@export var crown_drop: float = 20.0
@export var crown_time: float = 1.2

var height = 0.0
var angle = 0.0
var move = -1
var volleys = 0
var spin = 0.0
var dive_target = Vector2.ZERO
var dive_time = 0.0
var crowned = false
var crown_left = 0.0


func _ready():
	super()
	height = hover_height
	enter("", rest_time)


func make_elite():
	super()
	$Crown.hide()


func steer(to_player, delta):
	var sprite = $AnimatedSprite2D
	var lift = hover_height
	match state:
		"retreat":
			linear_velocity = -to_player.normalized() * retreat_speed
			face(to_player.x < 0)
			set_anim("walk")
			if to_player.length() >= volley_range or state_left == 0.0:
				enter("volley", volley_tell)
		"volley":
			hold(delta)
			face(to_player.x < 0)
			set_anim("attack")
			lift = hover_height + 2
			if state_left == 0.0:
				fan(to_player)
				volleys -= 1
				if volleys > 0:
					enter("volley", volley_gap)
				else:
					finish_move()
		"summon":
			spin += summon_spin * delta
			linear_velocity = Vector2.from_angle(spin) * summon_radius * summon_spin
			face(linear_velocity.x < 0)
			set_anim("walk")
			sprite.speed_scale = 2.0
			lift = summon_height
			if state_left == 0.0:
				sprite.speed_scale = 1.0
				finish_move()
		"swoop":
			hold(delta)
			face(dive_target.x < position.x)
			set_anim("attack")
			lift = swoop_height
			if state_left == 0.0:
				dive_time = maxf(position.distance_to(dive_target) / swoop_speed, delta)
				Sfx.play("queen_swoop")
				enter("dive", dive_time)
		"dive":
			linear_velocity = (dive_target - position) / maxf(state_left, delta)
			face(linear_velocity.x < 0)
			set_anim("glide")
			height = swoop_height * state_left / dive_time
			lift = height
			if state_left == 0.0:
				nova()
				enter("vanish", vanish_time)
		"vanish":
			linear_velocity = Vector2.ZERO
			lift = height
			var tick = int(state_left * 30)
			shake(vanish_shudder if tick % 2 == 0 else -vanish_shudder)
			visible = tick % 3 > 0
			if state_left == 0.0:
				shake(0.0)
				visible = false
				enter("blink", blink_time)
		"blink":
			linear_velocity = Vector2.ZERO
			if state_left == 0.0:
				angle = randf() * TAU
				position = target.position + Vector2.from_angle(angle) * hover_range
				visible = true
				enter("appear", appear_time)
		"appear":
			linear_velocity = Vector2.ZERO
			visible = int(state_left * 30) % 2 == 0
			if state_left == 0.0:
				visible = true
				enter("", rest_time * (rage_rest if raging() else 1.0))
		_:
			angle += orbit_speed * delta
			var spot = target.position + Vector2.from_angle(angle) * hover_range
			linear_velocity = (spot - position).limit_length(hover_speed)
			face(to_player.x < 0)
			set_anim("walk")
			if state_left == 0.0:
				next_move()
	height = move_toward(height, lift, climb_speed * delta)
	crown(delta)
	sprite.offset.y = -height
	$Hurtbox.position.y = -height
	$Shadow.frame = roundi(lerpf($Shadow.hframes - 1, 0.0, clampf(height / shadow_full_height, 0.0, 1.0)))
	$Hitbox/CollisionShape2D.set_deferred("disabled", state != "dive")
	$Hurtbox/CollisionShape2D.set_deferred("disabled", state == "dive" or state == "blink")


func hold(delta):
	linear_velocity = linear_velocity.lerp(Vector2.ZERO, minf(turn_speed * delta, 1.0))


func shake(x):
	$AnimatedSprite2D.offset.x = x
	$Crown.offset.x = x


func raging() -> bool:
	return hp <= max_hp * rage_hp


func frenzied() -> bool:
	return hp <= max_hp * frenzy_hp


func next_move():
	move = (move + 1) % 3
	match move:
		0:
			volleys = volley_count
			enter("retreat", retreat_time)
		1:
			Sfx.play("queen_summon")
			summon()
			enter("summon", summon_time)
		2:
			dive_target = target.position
			enter("swoop", swoop_tell)


func finish_move():
	if frenzied():
		enter("vanish", vanish_time)
	else:
		enter("", rest_time * (rage_rest if raging() else 1.0))


func fan(to_player):
	var shots = rage_shots if raging() else volley_shots
	for i in shots:
		var shot = shot_scene.instantiate()
		shot.position = position + Vector2(0, -height)
		shot.direction = to_player.normalized().rotated(volley_spread * (i - (shots - 1) / 2.0))
		get_parent().add_child(shot)
	Sfx.play("bee_shoot")


func nova():
	for i in nova_shots:
		var shot = shot_scene.instantiate()
		shot.position = position
		shot.direction = Vector2.from_angle(TAU * i / nova_shots)
		get_parent().add_child(shot)
	Sfx.play("bee_shoot")


func summon():
	if get_tree().get_nodes_in_group("enemies").size() > swarm_cap:
		return
	for i in swarm_size:
		var bee = bee_scene.instantiate()
		bee.hearts = hearts
		bee.position = position + Vector2.from_angle(angle + swarm_turn * i) * (swarm_radius + swarm_step * i)
		if raging() and i == 0:
			bee.make_elite()
		bee.materialise(swarm_gap * i, swarm_flicker)
		get_parent().add_child(bee)


func crown(delta):
	if not crowned and raging():
		crowned = true
		crown_left = crown_time
	if not crowned:
		return
	if visible:
		crown_left = maxf(crown_left - delta, 0.0)
	$Crown.visible = crown_left == 0.0 or int(crown_left * 15) % 3 > 0
	$Crown.position.y = -height + crown_y - crown_drop * crown_left / crown_time
