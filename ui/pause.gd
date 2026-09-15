extends CanvasLayer

var enabled = false


func _ready():
	hide()


func _process(_delta):
	if not enabled or not Input.is_action_just_pressed("start"):
		return
	if get_tree().paused and not visible:
		return
	visible = not visible
	get_tree().paused = visible
	Sfx.play("pause" if visible else "unpause")
