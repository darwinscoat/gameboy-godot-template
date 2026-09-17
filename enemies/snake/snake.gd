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
@export_group("Elite")
@export var roll_speed: float = 100.0
@export var roll_time: float = 0.5
@export var roll_anim_speed: float = 3.0
@export var dizzy_time: float = 1.0
@export var elite_knockback: float = 60.0
@export var shade_scene: PackedScene
@export var shade_count: int = 2
@export var shade_spread: float = 1.05
@export var shade_every: int = 3
@export var shudder: int = 2

var bite_direction = Vector2.ZERO
var waited = 0.0
var rolls = 0
var teaming = false


func make_elite():
	super()
	patience = 0.0
	knockback_speed = elite_knockback


func steer(to_player, delta):
	var sprite = $AnimatedSprite2D
	match state:
		"charge":
			linear_velocity = bite_direction * chase_speed if to_player.length() > bite_range and not elite else Vector2.ZERO
			face(bite_direction.x < 0)
			coil()
			if teaming:
				sprite.offset.x = shudder if int(state_left * 30) % 2 == 0 else -shudder
			else:
				sprite.offset.y = -1 if int(state_left * 20) % 2 == 0 else 0
			if state_left == 0.0:
				sprite.offset = Vector2.ZERO
				Sfx.play("snake_bite")
				set_anim("attack")
				sprite.frame = roll_frame
				if elite:
					sprite.speed_scale = roll_anim_speed
					linear_velocity = bite_direction * roll_speed
					$Hurtbox/CollisionShape2D.set_deferred("disabled", true)
					enter("roll", roll_time)
				else:
					sprite.speed_scale = bite_anim_speed
					linear_velocity = bite_direction * bite_speed
					enter("bite", bite_time)
		"bite":
			if state_left == 0.0:
				linear_velocity = -to_player.normalized() * chase_speed
				enter("recoil", recoil_time)
		"recoil":
			set_anim("walk")
			if state_left == 0.0:
				enter("", 0.0)
		"roll":
			linear_velocity = bite_direction * roll_speed
			if sprite.frame == coil_frame:
				sprite.frame = roll_frame
			if state_left == 0.0:
				$Hurtbox/CollisionShape2D.set_deferred("disabled", false)
				set_anim("walk")
				sprite.pause()
				enter("dizzy", dizzy_time)
		"dizzy":
			linear_velocity = linear_velocity.lerp(Vector2.ZERO, minf(turn_speed * delta, 1.0))
			sprite.offset.x = 1 if int(state_left * 10) % 2 == 0 else -1
			if state_left == 0.0:
				sprite.offset.x = 0
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
				if elite:
					rolls += 1
					teaming = rolls % shade_every == 0
					if teaming:
						double_team(to_player)
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


func double_team(to_player):
	for i in shade_count:
		var side = 1.0 if i % 2 == 0 else -1.0
		var shade = shade_scene.instantiate()
		shade.position = target.position - to_player.rotated(side * shade_spread * (i / 2 + 1))
		shade.direction = (target.position - shade.position).normalized()
		shade.speed = roll_speed
		shade.coil_left = charge_time
		shade.roll_left = roll_time
		shade.coil_frame = coil_frame
		shade.roll_frame = roll_frame
		shade.anim_speed = roll_anim_speed
		shade.shudder = shudder
		get_parent().add_child(shade)
