extends Area2D

@export var speed: float = 60.0
@export var lifetime: float = 2.0
@export var damage: int = 1

var direction = Vector2.RIGHT


func _ready():
	z_index = Layers.STING
	var step = roundi(fmod(direction.angle() + TAU, TAU) / (TAU / 16)) % 16
	rotation = (step / 4) * TAU / 4
	$Sprite2D.frame = step % 4


func _physics_process(delta):
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0 or not get_overlapping_areas().is_empty():
		queue_free()
