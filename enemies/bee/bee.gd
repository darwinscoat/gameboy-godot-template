extends Enemy

@export var attack_range: float = 12.0


func steer(to_player, delta):
	chase(to_player, delta)
	set_anim("attack" if to_player.length() < attack_range else "walk")
