extends CanvasLayer

signal start_game

@export var restart_delay: float = 2.0
@export var elite_blink: float = 0.125
@export var start_blink: float = 0.5
@export var heart_full: Texture2D
@export var heart_half: Texture2D
@export var heart_empty: Texture2D


func _process(_delta):
	if not $StartLabel.visible:
		return
	$StartLabel.modulate.a = 1.0 if int(Time.get_ticks_msec() / (start_blink * 1000)) % 2 == 0 else 0.0
	if Input.is_action_just_pressed("start"):
		$StartLabel.hide()
		start_game.emit()


func show_message(text):
	$Message.text = text
	$Message.show()
	$MessageTimer.start()


func show_game_over(text := "Game Over"):
	show_message(text)
	await $MessageTimer.timeout
	$Message.text = "Churro"
	$Message.show()
	await get_tree().create_timer(restart_delay).timeout
	$StartLabel.show()


func update_score(score):
	$ScoreLabel.text = str(score)


func update_coins(coins):
	$Coins/Label.text = str(coins)


func update_hp(hp, max_hp):
	for heart in $Hearts.get_children():
		heart.queue_free()
	for i in max_hp / 2:
		var heart = TextureRect.new()
		heart.texture = crop(heart_full if hp >= 2 * i + 2 else heart_half if hp == 2 * i + 1 else heart_empty)
		$Hearts.add_child(heart)


func update_wave(fraction, elite):
	$WaveBar.show()
	$WaveBar/Fill.size.x = roundf($WaveBar.size.x * (1.0 if elite else clampf(fraction, 0.0, 1.0)))
	$WaveBar/Fill.visible = not elite or int(Time.get_ticks_msec() / (elite_blink * 1000)) % 2 == 0


func hide_wave():
	$WaveBar.hide()


func crop(texture: Texture2D) -> AtlasTexture:
	var atlas = AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = texture.get_image().get_used_rect()
	return atlas


func _on_message_timer_timeout():
	$Message.hide()
