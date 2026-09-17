extends Enemy

@export var sting_range: float = 18.0
@export var sting_speed: float = 80.0
@export var sting_time: float = 0.15
@export var sting_start: int = 3
@export var sting_frame: int = 5
@export var attack_speed: float = 3.0
@export var sting_rest: float = 0.3
@export_group("Elite")
@export var shot_scene: PackedScene
@export var shot_range: float = 64.0
@export var shot_cooldown: float = 2.0

var stung = false
var shot_left = 0.0


func steer(to_player, delta):
	var sprite = $AnimatedSprite2D
	shot_left = maxf(shot_left - delta, 0.0)
	match state:
		"sting":
			if stung:
				if state_left == 0.0:
					enter("rest", sting_rest)
			elif sprite.frame >= sting_frame:
				stung = true
				linear_velocity = to_player.normalized() * sting_speed
				face(linear_velocity.x < 0)
				sprite.pause()
				Sfx.play("bee_sting")
				enter("sting", sting_time)
			else:
				linear_velocity = linear_velocity.lerp(Vector2.ZERO, minf(turn_speed * delta, 1.0))
				face(to_player.x < 0)
		"shoot":
			linear_velocity = linear_velocity.lerp(Vector2.ZERO, minf(turn_speed * delta, 1.0))
			face(to_player.x < 0)
			if sprite.frame >= sting_frame:
				shoot(to_player)
				shot_left = shot_cooldown
				enter("rest", sting_rest)
		"rest":
			chase(to_player, delta)
			if state_left == 0.0:
				enter("", 0.0)
		_:
			chase(to_player, delta)
			if to_player.length() < sting_range:
				stung = false
				set_anim("attack")
				sprite.frame = sting_start
				enter("sting", 0.0)
			elif elite and shot_left == 0.0 and to_player.length() < shot_range:
				set_anim("attack")
				sprite.frame = sting_start
				enter("shoot", 0.0)
	if state != "sting" and state != "shoot":
		set_anim("walk")
	$Hitbox/CollisionShape2D.set_deferred("disabled", not stung or state != "sting")


func shoot(to_player):
	var shot = shot_scene.instantiate()
	shot.position = position
	shot.direction = to_player.normalized()
	Sfx.play("bee_shoot")
	get_parent().add_child(shot)


func set_anim(name):
	$AnimatedSprite2D.speed_scale = attack_speed if name == "attack" else 1.0
	super(name)
