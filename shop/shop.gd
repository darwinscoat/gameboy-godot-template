extends CanvasLayer

const ATTACK = ["damage", "count", "spin"]

@export var upgrades: Array[UpgradeData]
@export var normal_style: StyleBox
@export var selected_style: StyleBox
@export var dim: Color = Color(0.341, 0.341, 0.341)
@export var curtain: NodePath
@export var director: NodePath

var player: Node
var offered = []
var sold = []
var selected = 0
var closing = false


func _ready():
	hide()


func _process(_delta):
	if not visible or closing:
		return
	if Input.is_action_just_pressed("move_left"):
		select(selected - 1)
	elif Input.is_action_just_pressed("move_right"):
		select(selected + 1)
	elif Input.is_action_just_pressed("a"):
		buy()
	elif Input.is_action_just_pressed("b"):
		close()


func open(rng):
	player = get_tree().get_first_node_in_group("player")
	offered = pick(rng)
	if offered.is_empty():
		return
	sold = []
	sold.resize(offered.size())
	sold.fill(false)
	selected = 0
	closing = false
	refresh()
	get_tree().paused = true
	await get_node(curtain).cover()
	show()
	Sfx.play("shop_open")
	Music.play("shop")
	get_node(curtain).reveal()


func close():
	closing = true
	Sfx.play("shop_close")
	await get_node(curtain).cover()
	hide()
	get_tree().paused = false
	Music.resume("play")
	get_node(curtain).reveal()


func pick(rng) -> Array:
	var pool = upgrades.filter(func(upgrade): return not upgrade.repeatable and player.level(upgrade) < upgrade.costs.size())
	var picked = []
	draw(picked, pool.filter(func(upgrade): return upgrade.stat in ATTACK), rng)
	if picked.is_empty() or cost_of(picked[0]) > player.coins:
		draw(picked, pool.filter(func(upgrade): return cost_of(upgrade) <= player.coins), rng)
	while picked.size() < mini($Cards.get_child_count(), pool.size()):
		draw(picked, pool, rng)
	while picked.size() < $Cards.get_child_count():
		var extras = upgrades.filter(func(upgrade): return upgrade.repeatable and not picked.has(upgrade))
		if extras.is_empty():
			break
		draw(picked, extras, rng)
	for i in range(picked.size() - 1, 0, -1):
		var j = rng.randi() % (i + 1)
		var swap = picked[i]
		picked[i] = picked[j]
		picked[j] = swap
	return picked


func draw(picked, options, rng):
	options = options.filter(func(upgrade): return not picked.has(upgrade))
	if not options.is_empty():
		picked.append(options[rng.randi() % options.size()])


func cost_of(upgrade) -> int:
	var level = player.level(upgrade)
	var last = upgrade.costs.size() - 1
	var cost = upgrade.costs[mini(level, last)] + upgrade.cost_step * maxi(level - last, 0)
	return mini(cost, upgrade.cost_max) if upgrade.cost_max > 0 else cost


func blocked(upgrade) -> bool:
	match upgrade.stat:
		"heal":
			return player.hp >= player.max_hp
		"flawless":
			return get_node(director).flawless
	return false


func select(index):
	selected = wrapi(index, 0, offered.size())
	Sfx.play("shop_move")
	refresh()


func buy():
	var upgrade = offered[selected]
	if sold[selected] or player.coins < cost_of(upgrade) or blocked(upgrade):
		Sfx.play("shop_deny")
		return
	Sfx.play("shop_buy")
	player.add_coins(-cost_of(upgrade))
	if upgrade.stat == "flawless":
		get_node(director).flawless = true
	else:
		player.apply(upgrade)
	sold[selected] = not upgrade.repeatable
	refresh()


func refresh():
	var cards = $Cards.get_children()
	for i in cards.size():
		var card = cards[i]
		card.visible = i < offered.size()
		if not card.visible:
			continue
		var upgrade = offered[i]
		var level = player.level(upgrade)
		var cost = cost_of(upgrade)
		card.add_theme_stylebox_override("panel", selected_style if i == selected else normal_style)
		card.get_node("Icon").texture = upgrade.icon
		card.get_node("Icon").modulate = dim if sold[i] else Color.WHITE
		card.get_node("PriceBox/Coin").visible = not sold[i]
		card.get_node("PriceBox/Price").text = "Sold" if sold[i] else str(cost)
		card.get_node("PriceBox/Price").modulate = Color.WHITE if sold[i] or (player.coins >= cost and not blocked(upgrade)) else dim
		var pips = card.get_node("Pips")
		for pip in pips.get_children():
			pips.remove_child(pip)
			pip.queue_free()
		for j in (0 if upgrade.repeatable else upgrade.costs.size()):
			var pip = ColorRect.new()
			pip.custom_minimum_size = Vector2(4, 3)
			pip.color = Color.WHITE if j < level else dim
			pips.add_child(pip)
		pips.position.x = (card.size.x - upgrade.costs.size() * 6 + 2) / 2
	var current = offered[selected]
	$Info.text = "%s\n%s" % [current.title, current.blurb]
