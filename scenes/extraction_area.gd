extends Area2D



func _ready():
	var bodies = get_overlapping_bodies()
	var areas = get_overlapping_areas()
	print("Bodies: ", bodies.size(), " | Areas: ", areas.size())
