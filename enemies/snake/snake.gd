extends Enemy

@export var bite_range: float = 14.0
@export var charge_time: float = 0.5
@export var bite_speed: float = 160.0
@export var bite_time: float = 0.2
@export var recoil_time: float = 0.5
@export var wait_range: float = 36.0
@export var strike_gap: float = 0.6
@export var patience: float = 1.0
@export var coil_frame: int = 0
@export var roll_frame: int = 1
@export var bite_anim_speed: float = 3.0

var bite_direction = Vector2.ZERO
var waited = 0.0


func make_elite():
	super()
	patience = 0.0


func steer(to_player, delta):
	match state:
		"charge":
			linear_velocity = bite_direction * chase_speed if to_player.length() > bite_range else Vector2.ZERO
			face(bite_direction.x < 0)
			coil()
			$AnimatedSprite2D.offset.y = -1 if int(state_left * 20) % 2 == 0 else 0
			if state_left == 0.0:
				$AnimatedSprite2D.offset.y = 0
				linear_velocity = bite_direction * bite_speed
				Sfx.play("snake_bite")
				set_anim("attack")
				$AnimatedSprite2D.frame = roll_frame
				$AnimatedSprite2D.speed_scale = bite_anim_speed
				enter("bite", bite_time)
		"bite":
			if state_left == 0.0:
				linear_velocity = -to_player.normalized() * chase_speed
				enter("recoil", recoil_time)
		"recoil":
			set_anim("walk")
			if state_left == 0.0:
				enter("", 0.0)
		_:
			if to_player.length() >= wait_range:
				chase(to_player, delta)
				set_anim("walk")
			elif target.get_node("Sword").time_until((-to_player).angle()) >= strike_gap or waited >= patience:
				waited = 0.0
				bite_direction = to_player.normalized()
				Sfx.play("snake_charge")
				enter("charge", charge_time)
			else:
				waited += delta
				linear_velocity = linear_velocity.lerp(Vector2.ZERO, minf(turn_speed * delta, 1.0))
				face(to_player.x < 0)
				coil()


func coil():
	var sprite = $AnimatedSprite2D
	if sprite.animation != "attack" or sprite.is_playing():
		sprite.play("attack")
		sprite.pause()
	sprite.frame = coil_frame


func set_anim(name):
	if name != "attack":
		$AnimatedSprite2D.speed_scale = 1.0
	super(name)
