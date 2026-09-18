extends CanvasLayer

@export var shop: NodePath
@export var curtain: NodePath
@export var normal_style: StyleBox
@export var selected_style: StyleBox
@export var dim: Color = Color(0.341, 0.341, 0.341)

var enabled = false
var switching = false
var selected = 0
var upgrades = []


func _ready():
	hide()


func _process(_delta):
	if not enabled or switching:
		return
	if visible:
		if Input.is_action_just_pressed("move_left"):
			select(selected - 1)
		elif Input.is_action_just_pressed("move_right"):
			select(selected + 1)
		elif Input.is_action_just_pressed("move_up"):
			select(selected - $Grid.columns)
		elif Input.is_action_just_pressed("move_down"):
			select(selected + $Grid.columns)
	if not Input.is_action_just_pressed("start"):
		return
	if get_tree().paused and not visible:
		return
	if visible:
		close()
	else:
		open()


func open():
	switching = true
	get_tree().paused = true
	Sfx.play("pause")
	await get_node(curtain).cover()
	build()
	show()
	get_node(curtain).reveal()
	switching = false


func close():
	switching = true
	Sfx.play("unpause")
	await get_node(curtain).cover()
	hide()
	await get_node(curtain).reveal()
	get_tree().paused = false
	switching = false


func build():
	upgrades = get_node(shop).upgrades.filter(func(upgrade): return not upgrade.repeatable)
	for cell in $Grid.get_children():
		cell.free()
	var player = get_tree().get_first_node_in_group("player")
	for upgrade in upgrades:
		var level = player.level(upgrade)
		var cell = PanelContainer.new()
		var box = VBoxContainer.new()
		box.add_theme_constant_override("separation", 1)
		var icon = TextureRect.new()
		icon.texture = upgrade.icon
		icon.custom_minimum_size = Vector2(16, 16)
		icon.modulate = Color.WHITE if level > 0 else dim
		box.add_child(icon)
		var pips = HBoxContainer.new()
		pips.alignment = BoxContainer.ALIGNMENT_CENTER
		pips.add_theme_constant_override("separation", 2)
		for j in upgrade.costs.size():
			var pip = ColorRect.new()
			pip.custom_minimum_size = Vector2(4, 3)
			pip.color = Color.WHITE if j < level else dim
			pips.add_child(pip)
		box.add_child(pips)
		cell.add_child(box)
		$Grid.add_child(cell)
	selected = clampi(selected, 0, upgrades.size() - 1)
	refresh()


func select(index):
	selected = wrapi(index, 0, upgrades.size())
	Sfx.play("shop_move")
	refresh()


func refresh():
	var player = get_tree().get_first_node_in_group("player")
	for i in $Grid.get_child_count():
		$Grid.get_child(i).add_theme_stylebox_override("panel", selected_style if i == selected else normal_style)
	var upgrade = upgrades[selected]
	$Name.text = "%s %d/%d" % [upgrade.title, player.level(upgrade), upgrade.costs.size()]
	$Description.text = upgrade.description
