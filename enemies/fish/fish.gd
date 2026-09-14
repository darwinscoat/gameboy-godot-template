extends Enemy

@export var charge_range: float = 40.0
@export var charge_time: float = 0.6
@export var dash_speed: float = 140.0
@export var dash_time: float = 0.35
@export var rest_time: float = 0.6

var dash_direction = Vector2.ZERO


func steer(to_player, delta):
	match state:
		"charge":
			linear_velocity = Vector2.ZERO
			$AnimatedSprite2D.flip_h = to_player.x < 0
			$AnimatedSprite2D.offset.x = 1 if int(state_left * 20) % 2 == 0 else -1
			if state_left == 0.0:
				$AnimatedSprite2D.offset.x = 0
				dash_direction = to_player.normalized()
				enter("dash", dash_time)
		"dash":
			linear_velocity = dash_direction * dash_speed
			if state_left == 0.0:
				enter("rest", rest_time)
		"rest":
			linear_velocity = linear_velocity.lerp(Vector2.ZERO, minf(turn_speed * delta, 1.0))
			if state_left == 0.0:
				enter("", 0.0)
		_:
			chase(to_player, delta)
			if to_player.length() < charge_range:
				enter("charge", charge_time)
