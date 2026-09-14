extends Pickup


func collect(player) -> bool:
	return player.heal(1)
