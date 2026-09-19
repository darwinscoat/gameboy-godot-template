extends Pickup

@export var lifetime: float = 20.0
@export var warn_time: float = 5.0
@export var heal_amount: int = 2

var age = 0.0
var warned = false


func _ready():
	super()
	z_index = Layers.RARE_PICKUP
	Sfx.play("heart_drop")


func _process(delta):
	super(delta)
	age += delta
	if age >= lifetime - warn_time and not warned:
		warned = true
		Sfx.play("heart_warn")
	$Sprite.visible = age < lifetime - warn_time or int(age * 10) % 2 == 0
	if age >= lifetime:
		Sfx.play("heart_expire")
		queue_free()


func collect(player) -> bool:
	if not player.heal(heal_amount):
		return false
	Sfx.play("heart_collect")
	return true
