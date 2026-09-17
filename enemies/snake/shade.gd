extends Area2D

@export var damage: int = 1

var direction = Vector2.RIGHT
var speed = 0.0
var coil_left = 0.0
var roll_left = 0.0
var coil_frame = 0
var roll_frame = 1
var anim_speed = 3.0
var shudder = 2


func _ready():
	$AnimatedSprite2D.play("attack")
	$AnimatedSprite2D.pause()
	$AnimatedSprite2D.frame = coil_frame
	$AnimatedSprite2D.flip_h = direction.x < 0
	$CollisionShape2D.disabled = true


func _physics_process(delta):
	visible = Engine.get_physics_frames() % 2 == 0
	var sprite = $AnimatedSprite2D
	if coil_left > 0.0:
		coil_left -= delta
		sprite.offset.x = shudder if int(coil_left * 30) % 2 == 0 else -shudder
		if coil_left <= 0.0:
			sprite.offset.x = 0
			sprite.play("attack")
			sprite.frame = roll_frame
			sprite.speed_scale = anim_speed
			$CollisionShape2D.set_deferred("disabled", false)
		return
	position += direction * speed * delta
	if sprite.frame == coil_frame:
		sprite.frame = roll_frame
	roll_left -= delta
	if roll_left <= 0.0 or not get_overlapping_areas().is_empty():
		queue_free()
