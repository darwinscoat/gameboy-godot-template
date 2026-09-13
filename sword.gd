extends Node2D

@export var fish_scene: PackedScene
@export var count = 1
@export var speed = 180.0
@export var radius = 20.0
@export var size = 1
@export var damage = 1

var angle = 0.0


func _ready():
	rebuild()


func rebuild():
	for fish in get_children():
		remove_child(fish)
		fish.queue_free()
	for i in count:
		add_child(fish_scene.instantiate())


func _process(delta):
	angle = fmod(angle + deg_to_rad(speed) * delta, TAU)
	var fishes = get_children()
	for i in fishes.size():
		var fish = fishes[i]
		var a = angle + TAU * i / fishes.size()
		var step = roundi(fmod(a, TAU) / (TAU / 16)) % 16
		fish.position = Vector2.from_angle(a) * radius * size
		fish.scale = Vector2(size, size)
		fish.rotation = (step / 4) * TAU / 4
		fish.get_node("Sprite2D").frame = step % 4


func _physics_process(_delta):
	if not is_visible_in_tree():
		return
	for fish in get_children():
		for hurtbox in fish.get_overlapping_areas():
			hurtbox.get_parent().take_damage(damage, fish.global_position)
