extends RigidBody2D

@export var chase_speed: float = 20.0
@export var turn_speed: float = 10.0
var target: Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	var mob_types = Array($AnimatedSprite2D.sprite_frames.get_animation_names())
	$AnimatedSprite2D.animation = mob_types.pick_random()
	$AnimatedSprite2D.play()
	target = get_tree().get_first_node_in_group("player")
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _physics_process(delta: float) -> void:
	if target == null or not target.visible:
		return
	var to_player = target.global_position - global_position
	var wanted_velocity = to_player.normalized() * chase_speed
	linear_velocity = linear_velocity.lerp(wanted_velocity, minf(turn_speed * delta, 1.0))
	$AnimatedSprite2D.flip_h = linear_velocity.x < 0
	
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
