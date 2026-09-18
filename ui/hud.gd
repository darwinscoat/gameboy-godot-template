extends CanvasLayer

signal start_game
signal message_hidden
signal cat_changed(index)

@export var restart_delay: float = 2.0
@export var boss_blink: float = 0.125
@export var start_blink: float = 0.5
@export var wave_height: float = 2.0
@export var wave_speed: float = 1.0
@export var title_wave: float = 1.5
@export var title: String = "[font_size=16]Churro[/font_size]\nwill survive!"
@export var boss_wave: float = 2.0
@export var coin_hop_time: float = 0.1
@export var reveal_speed: float = 30.0
@export var erase_speed: float = 45.0
@export var slow_reveal: float = 0.4
@export var boss_flicker: float = 0.3
@export var heart_full: Texture2D
@export var heart_half: Texture2D
@export var heart_empty: Texture2D
@export var cats: Array[String] = ["Churro", "Miles"]

var coin_hop_left = 0.0
var last_coins = 0
var coins_y = 0.0
var shown = 0.0
var reveal_rate = 0.0
var erasing = false
var flicker_left = 0.0
var cat = 0


func _ready():
	coins_y = $Coins.position.y
	show_title()
	show_start()
	Music.play("title")


func _process(delta):
	coin_hop_left = maxf(coin_hop_left - delta, 0.0)
	$Coins.position.y = coins_y - (1.0 if coin_hop_left > 0.0 else 0.0)
	if $Message.visible:
		var total = $Message.get_total_character_count()
		if erasing:
			shown = maxf(shown - erase_speed * delta, 0.0)
			if shown == 0.0:
				$Message.hide()
				message_hidden.emit()
		else:
			shown = minf(shown + reveal_rate * delta, total)
		var count = ceili(shown)
		if count > $Message.visible_characters and not erasing:
			Sfx.play("text_tick")
		$Message.visible_characters = count
		flicker_left = maxf(flicker_left - delta, 0.0)
		$Message.modulate.a = 0.0 if flicker_left > 0.0 and int(flicker_left * 20) % 2 == 0 else 1.0
	if not $StartLabel.visible:
		return
	$StartLabel.modulate.a = 1.0 if int(Time.get_ticks_msec() / (start_blink * 1000)) % 2 == 0 else 0.0
	if $Picker.visible:
		var step = int(Input.is_action_just_pressed("move_down")) - int(Input.is_action_just_pressed("move_up"))
		if step != 0:
			cat = wrapi(cat + step, 0, cats.size())
			Sfx.play("shop_move")
			update_picker()
			cat_changed.emit(cat)
	if Input.is_action_just_pressed("start"):
		Sfx.play("start")
		$StartLabel.hide()
		$Picker.hide()
		$Best.hide()
		start_game.emit()


func wave(text, strength := 1.0) -> String:
	return "[center][wave amp=%d freq=%f]%s[/wave][/center]" % [roundi(wave_height * strength * 10), wave_speed * strength * TAU, text]


func show_message(text, strong := false, slow := false):
	reveal(wave(text, boss_wave if strong else 1.0), reveal_speed * (slow_reveal if slow else 1.0))
	if strong:
		shown = $Message.get_total_character_count()
		$Message.visible_characters = -1
		flicker_left = boss_flicker
	$MessageTimer.start()


func show_title():
	reveal(wave(title, title_wave), reveal_speed)


func reveal(bbcode, rate):
	$Message.text = bbcode
	$Message.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	$Message.visible_characters = 0
	$Message.show()
	shown = 0.0
	reveal_rate = rate
	erasing = false
	flicker_left = 0.0


func show_game_over(text := "Game Over"):
	show_message(text, false, true)
	await message_hidden
	show_title()
	await get_tree().create_timer(restart_delay).timeout
	show_start()
	Music.play("title")


func show_start():
	$StartLabel.show()
	$Picker.visible = Save.completed
	update_picker()
	update_best(Save.best)


func update_picker():
	var lines = []
	for i in cats.size():
		lines.append(("> " if i == cat else "  ") + cats[i])
	$Picker.text = "\n".join(lines)


func update_best(best):
	$Best.text = "Best %d" % best
	$Best.visible = best > 0 and $StartLabel.visible


func update_score(score):
	$ScoreLabel.text = str(score)


func update_coins(coins):
	$Coins/Label.text = str(coins)
	if coins > last_coins:
		coin_hop_left = coin_hop_time
	last_coins = coins


func update_hp(hp, max_hp):
	for heart in $Hearts.get_children():
		heart.queue_free()
	for i in max_hp / 2:
		var heart = TextureRect.new()
		heart.texture = crop(heart_full if hp >= 2 * i + 2 else heart_half if hp == 2 * i + 1 else heart_empty)
		$Hearts.add_child(heart)


func update_wave(fraction, boss):
	$WaveBar.show()
	$WaveBar/Fill.size.x = roundf($WaveBar.size.x * (1.0 if boss else clampf(fraction, 0.0, 1.0)))
	$WaveBar/Fill.visible = not boss or int(Time.get_ticks_msec() / (boss_blink * 1000)) % 2 == 0


func hide_wave():
	$WaveBar.hide()


func update_abilities(flip, dash):
	$Abilities.show()
	$Abilities/BarA/Fill.size.x = roundf($Abilities/BarA.size.x * clampf(flip, 0.0, 1.0))
	$Abilities/BarB/Fill.size.x = roundf($Abilities/BarB.size.x * clampf(dash, 0.0, 1.0))


func hide_abilities():
	$Abilities.hide()


func crop(texture: Texture2D) -> AtlasTexture:
	var atlas = AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = texture.get_image().get_used_rect()
	return atlas


func _on_message_timer_timeout():
	erasing = true
	$Message.visible_characters_behavior = TextServer.VC_GLYPHS_RTL
