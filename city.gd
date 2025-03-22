extends Node2D
	
@export var inventory: Dictionary = {
	'grain': 100,
	'iron': 20
}

func calculate_price(resource):
	var supply = inventory[resource]
	var demand = 100 - supply
	return resources[resource]['base_price'] * (1 + (demand - supply)/100.0)

func _on_production_timer_timeout() -> void:
	inventory['grain'] += 10

func _on_demand_timer_timeout() -> void:
	if inventory['grain'] > 0:
		inventory['grain'] -= 5
