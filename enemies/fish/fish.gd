extends Enemy

@export var charge_range: float = 40.0
@export var charge_time: float = 0.6
@export var dash_speed: float = 140.0
@export var dash_time: float = 0.35
@export var rest_time: float = 0.6
@export var charge_anim_speed: float = 4.0
@export var dash_frame: int = 2
@export_group("Elite")
@export var elite_dashes: int = 3
@export var elite_charge_time: float = 0.4
@export var elite_recharge_time: float = 0.25
@export var elite_rest_time: float = 1.2
@export_group("Ghost")
@export var ghost_near: float = 8.0
@export var ghost_far: float = 24.0
@export var ghost_pulse: float = 0.2

var dash_direction = Vector2.ZERO
var dashes_left = 0


func _physics_process(delta):
	super(delta)
	var charging = state == "charge" and not dying and target != null and target.visible
	$Ghost.visible = charging and Engine.get_physics_frames() % 2 == 0
	if charging:
		var pulse = 1.0 - fmod(state_left, ghost_pulse) / ghost_pulse
		$Ghost.position = dash_direction * lerpf(ghost_near, ghost_far, pulse)
		$Ghost.flip_h = dash_direction.x < 0
		$Ghost.frame = dash_frame


func steer(to_player, delta):
	match state:
		"charge":
			linear_velocity = Vector2.ZERO
			face(dash_direction.x < 0)
			set_anim("walk")
			$AnimatedSprite2D.offset.x = 1 if int(state_left * 20) % 2 == 0 else -1
			if state_left == 0.0:
				$AnimatedSprite2D.offset.x = 0
				Sfx.play("fish_dash")
				set_anim("attack")
				$AnimatedSprite2D.frame = dash_frame
				enter("dash", dash_time)
		"dash":
			linear_velocity = dash_direction * dash_speed
			if state_left == 0.0:
				dashes_left -= 1
				if dashes_left > 0:
					dash_direction = to_player.normalized()
					Sfx.play("fish_charge")
					enter("charge", elite_recharge_time)
				else:
					enter("rest", elite_rest_time if elite else rest_time)
		"rest":
			linear_velocity = linear_velocity.lerp(Vector2.ZERO, minf(turn_speed * delta, 1.0))
			set_anim("walk")
			if state_left == 0.0:
				enter("", 0.0)
		_:
			chase(to_player, delta)
			set_anim("walk")
			if to_player.length() < charge_range:
				dash_direction = to_player.normalized()
				dashes_left = elite_dashes if elite else 1
				Sfx.play("fish_charge")
				enter("charge", elite_charge_time if elite else charge_time)


func run(to_player, _delta):
	match state:
		"charge":
			linear_velocity = Vector2.ZERO
			face(dash_direction.x < 0)
			set_anim("walk")
			$AnimatedSprite2D.offset.x = 1 if int(state_left * 20) % 2 == 0 else -1
			if state_left == 0.0:
				$AnimatedSprite2D.offset.x = 0
				Sfx.play("fish_dash")
				set_anim("attack")
				$AnimatedSprite2D.frame = dash_frame
				enter("dash", INF)
		"dash":
			linear_velocity = dash_direction * dash_speed
		_:
			dash_direction = -to_player.normalized()
			Sfx.play("fish_charge")
			enter("charge", charge_time)


func set_anim(name):
	$AnimatedSprite2D.speed_scale = charge_anim_speed if state == "charge" and name == "walk" else 1.0
	super(name)
