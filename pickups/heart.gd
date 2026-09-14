extends Pickup

@export var lifetime: float = 20.0
@export var warn_time: float = 5.0

var age = 0.0


func _process(delta):
	super(delta)
	age += delta
	$Sprite.visible = age < lifetime - warn_time or int(age * 10) % 2 == 0
	if age >= lifetime:
		queue_free()


func collect(player) -> bool:
	return player.heal(1)
