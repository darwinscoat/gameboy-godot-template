class_name UpgradeData
extends Resource

@export var title: String = ""
@export var blurb: String = ""
@export var icon: Texture2D
@export_enum("hp", "move", "magnet", "damage", "count", "spin") var stat: String = "hp"
@export var amount: int = 1
@export var costs: Array[int] = [10]
