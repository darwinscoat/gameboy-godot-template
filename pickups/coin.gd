extends Pickup

@export var value: int = 1
@export var large_value: int = 3
@export var air_spin: float = 2.0


func _ready():
	super()
	$Sprite.play("large" if value >= large_value else "spin")


func _process(delta):
	super(delta)
	$Sprite.speed_scale = air_spin if height < 0.0 else 1.0


func collect(player) -> bool:
	player.add_coins(value)
	Sfx.play("coin_collect")
	return true
