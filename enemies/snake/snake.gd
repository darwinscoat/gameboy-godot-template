extends Enemy

@export var bite_range: float = 14.0
@export var coil_time: float = 0.35
@export var bite_speed: float = 160.0
@export var bite_time: float = 0.15
@export var recoil_time: float = 0.5

var bite_direction = Vector2.ZERO


func steer(to_player, delta):
	match state:
		"coil":
			linear_velocity = Vector2.ZERO
			face(bite_direction.x < 0)
			$AnimatedSprite2D.offset.y = -1 if int(state_left * 20) % 2 == 0 else 0
			if state_left == 0.0:
				$AnimatedSprite2D.offset.y = 0
				linear_velocity = bite_direction * bite_speed
				enter("bite", bite_time)
		"bite":
			if state_left == 0.0:
				linear_velocity = -to_player.normalized() * chase_speed
				enter("recoil", recoil_time)
		"recoil":
			if state_left == 0.0:
				enter("", 0.0)
		_:
			chase(to_player, delta)
			if to_player.length() < bite_range:
				bite_direction = to_player.normalized()
				linear_velocity = Vector2.ZERO
				enter("coil", coil_time)
