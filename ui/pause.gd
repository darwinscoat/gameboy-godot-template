extends CanvasLayer

@export var shop: NodePath
@export var dim: Color = Color(0.341, 0.341, 0.341)

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
	if visible:
		show_owned()


func show_owned():
	for cell in $Panel/Owned.get_children():
		cell.free()
	var player = get_tree().get_first_node_in_group("player")
	for upgrade in get_node(shop).upgrades:
		var level = player.level(upgrade)
		if upgrade.repeatable or level == 0:
			continue
		var cell = VBoxContainer.new()
		cell.add_theme_constant_override("separation", 1)
		var icon = TextureRect.new()
		icon.texture = upgrade.icon
		icon.custom_minimum_size = Vector2(16, 16)
		cell.add_child(icon)
		var pips = HBoxContainer.new()
		pips.alignment = BoxContainer.ALIGNMENT_CENTER
		pips.add_theme_constant_override("separation", 2)
		for j in upgrade.costs.size():
			var pip = ColorRect.new()
			pip.custom_minimum_size = Vector2(4, 3)
			pip.color = Color.WHITE if j < level else dim
			pips.add_child(pip)
		cell.add_child(pips)
		$Panel/Owned.add_child(cell)
	$Panel.visible = $Panel/Owned.get_child_count() > 0
