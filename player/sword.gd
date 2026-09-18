extends Node2D

@export var fish_scene: PackedScene
@export var count: int = 1
@export var speed: float = 180.0
@export var radius: float = 20.0
@export var size: int = 1
@export var damage: int = 2
@export var flip_cooldown: float = 2.0
@export var ready_flash: float = 0.1
@export var ghosts: int = 0
@export var ghost_scene: PackedScene

var angle = 0.0
var direction = 1.0
var flip_left = 0.0
var flash_left = 0.0


func _ready():
	rebuild()


func rebuild():
	direction = 1.0
	flip_left = 0.0
	flash_left = 0.0
	for fish in get_children():
		remove_child(fish)
		fish.queue_free()
	for i in count:
		add_child(fish_scene.instantiate())


func _process(delta):
	if flip_left > 0.0 and flip_left <= delta:
		flash_left = ready_flash
	flip_left = maxf(flip_left - delta, 0.0)
	flash_left = maxf(flash_left - delta, 0.0)
	angle = fmod(angle + deg_to_rad(speed) * direction * delta + TAU, TAU)
	var fishes = get_children()
	for i in fishes.size():
		var fish = fishes[i]
		fish.modulate = Color(4, 4, 4) if flash_left > 0.0 else Color.WHITE
		var a = angle + TAU * i / fishes.size()
		var step = roundi(fmod(a, TAU) / (TAU / 16)) % 16
		fish.position = Vector2.from_angle(a) * radius * size
		fish.rotation = (step / 4) * TAU / 4
		fish.get_node("Sprite2D").frame = step % 4


func _physics_process(_delta):
	if not is_visible_in_tree():
		return
	for fish in get_children():
		for hurtbox in fish.get_overlapping_areas():
			hurtbox.get_parent().take_damage(damage, fish.global_position)


func time_until(at) -> float:
	var soonest = INF
	var fishes = get_children()
	for i in fishes.size():
		var a = angle + TAU * i / fishes.size()
		soonest = minf(soonest, wrapf((at - a) * direction, 0.0, TAU) / deg_to_rad(speed))
	return soonest


func flip() -> bool:
	if flip_left > 0.0:
		return false
	direction = -direction
	flip_left = flip_cooldown
	Sfx.play("sword_flip")
	if ghosts > 0:
		haunt()
	return true


func haunt():
	for fish in get_children():
		var ghost = ghost_scene.instantiate()
		ghost.position = fish.global_position
		ghost.direction = fish.position.normalized()
		ghost.damage = damage
		ghost.hits = ghosts
		get_parent().get_parent().add_child(ghost)
	Sfx.play("ghost_fish")
