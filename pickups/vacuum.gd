extends Pickup

@export var vacuum_speed: float = 240.0


func _ready():
	super()
	Sfx.play("vacuum_drop")


func collect(_player) -> bool:
	for pickup in get_tree().get_nodes_in_group("pickups"):
		if pickup != self:
			pickup.vacuum(vacuum_speed)
	Sfx.play("vacuum_collect")
	return true
