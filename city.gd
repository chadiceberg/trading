extends Node2D
	
@export var inventory: Dictionary = {
	'grain': 100,
	'iron': 20
}
@export var control_radius: float = 300.0
@export var production_interval: float = 5.0
@export var city_name: String = ""

func _on_production_timer_timeout() -> void:
	inventory['grain'] += 10

func _on_demand_timer_timeout() -> void:
	if inventory['grain'] > 0:
		inventory['grain'] -= 5
