extends Node

var path = "user://churro.cfg"
var completed = false
var best = 0


func _ready():
	var file = ConfigFile.new()
	if file.load(path) == OK:
		completed = file.get_value("run", "completed", false)
		best = file.get_value("run", "best", 0)


func record(score, won):
	completed = completed or won
	best = maxi(best, score)
	var file = ConfigFile.new()
	file.set_value("run", "completed", completed)
	file.set_value("run", "best", best)
	file.save(path)
