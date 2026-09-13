extends CanvasLayer

# Notifies `Main` node that the button has been pressed
signal start_game

@export var heart_full: Texture2D
@export var heart_empty: Texture2D

func show_message(text):
	$Message.text = text
	$Message.show()
	$MessageTimer.start()

func show_game_over():
	show_message("Game Over")
	# Wait until the MessageTimer has counted down.
	await $MessageTimer.timeout

	$Message.text = "It's Rat Time!"
	$Message.show()
	# Make a one-shot timer and wait for it to finish.
	await get_tree().create_timer(2.0).timeout
	$StartButton.show()
	
func update_score(score):
	$ScoreLabel.text = str(score)

func update_coins(coins):
	$Coins/Label.text = str(coins)

func update_hp(hp, max_hp):
	for heart in $Hearts.get_children():
		heart.queue_free()
	for i in max_hp:
		var heart = TextureRect.new()
		heart.texture = heart_full if i < hp else heart_empty
		$Hearts.add_child(heart)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_button_pressed():
	$StartButton.hide()
	start_game.emit()
	

func _on_message_timer_timeout() -> void:
	$Message.hide()
