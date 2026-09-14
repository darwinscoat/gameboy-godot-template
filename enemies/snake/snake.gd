extends Enemy

@export var bite_range: float = 14.0
@export var bite_speed: float = 160.0
@export var bite_time: float = 0.15
@export var recoil_time: float = 0.5


func steer(to_player, delta):
	match state:
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
				linear_velocity = to_player.normalized() * bite_speed
				enter("bite", bite_time)
