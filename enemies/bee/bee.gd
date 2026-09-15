extends Enemy

@export var sting_range: float = 18.0
@export var sting_speed: float = 80.0
@export var sting_time: float = 0.15
@export var sting_start: int = 3
@export var sting_frame: int = 5
@export var attack_speed: float = 3.0
@export var sting_rest: float = 0.3

var stung = false


func steer(to_player, delta):
	var sprite = $AnimatedSprite2D
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
				enter("sting", sting_time)
			else:
				linear_velocity = linear_velocity.lerp(Vector2.ZERO, minf(turn_speed * delta, 1.0))
				face(to_player.x < 0)
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
	if state != "sting":
		set_anim("walk")
	$Hitbox/CollisionShape2D.set_deferred("disabled", not stung or state != "sting")


func set_anim(name):
	$AnimatedSprite2D.speed_scale = attack_speed if name == "attack" else 1.0
	super(name)
