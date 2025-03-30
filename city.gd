extends Node2D

# Exported variables for easy tweaking in the editor
@export var inventory: Dictionary = {
	"grain": 100,
	"iron": 20,
	"lumber": 0,  # Processed good example
}
@export var control_radius: float = 300.0  # Radius for resource extraction
@export var production_interval: float = 5.0  # Time between production ticks
@export var city_name: String = "Unnamed City"

# Trade network data
@export var trade_routes: Array = []  # Array of dictionaries like {"city": Node2D, "type": String, "distance": float}

# Resource extraction rates (based on surrounding area)
@export var extraction_rates: Dictionary = {
	"grain": 10,
	"iron": 5
}

# Upkeep costs
@export var upkeep_costs: Dictionary = {
	"grain": 5
}

# Processing recipes (raw -> goods)
@export var recipes: Dictionary = {
	"lumber": {"input": {"wood": 10}, "output": 5, "time": 2.0}
}

# Facilities and their effects
@export var facilities: Dictionary = {
	"farm": {"cost": {"grain": 20}, "effect": {"grain_extraction": 5}},
	"sawmill": {"cost": {"grain": 30}, "effect": {"lumber_output": 2}}
}

# References to child nodes (set these up in the scene tree)
@onready var production_timer = $ProductionTimer
@onready var demand_timer = $DemandTimer

func _ready() -> void:
	# Set up timers if not already done in the editor
	production_timer.wait_time = production_interval
	production_timer.start()
	demand_timer.wait_time = production_interval / 2  # Upkeep ticks more often
	demand_timer.start()

# Resource extraction on timer
func _on_production_timer_timeout() -> void:
	for resource in extraction_rates.keys():
		inventory[resource] = inventory.get(resource, 0) + extraction_rates[resource]
	print(city_name, " produced resources. Inventory: ", inventory)

# Upkeep/demand on timer
func _on_demand_timer_timeout() -> void:
	for resource in upkeep_costs.keys():
		if inventory[resource] >= upkeep_costs[resource]:
			inventory[resource] -= upkeep_costs[resource]
		else:
			print(city_name, " is in deficit for ", resource, "!")
			# Add penalty logic here (e.g., reduce production)
	print(city_name, " upkeep paid. Inventory: ", inventory)

# Trade with another city
func trade_with_city(target_city: Node2D, resource: String, amount: int) -> void:
	if inventory.get(resource, 0) >= amount:
		inventory[resource] -= amount
		target_city.receive_trade(resource, amount, self)
		print(city_name, " sent ", amount, " ", resource, " to ", target_city.city_name)
	else:
		print(city_name, " lacks enough ", resource, " for trade!")

# Receive trade from another city
func receive_trade(resource: String, amount: int, sender: Node2D) -> void:
	inventory[resource] = inventory.get(resource, 0) + amount
	print(city_name, " received ", amount, " ", resource, " from ", sender.city_name)

# Process resources into goods
func process_resource(recipe_name: String) -> void:
	var recipe = recipes.get(recipe_name)
	if recipe and can_process_resource(recipe):
		for input_resource in recipe["input"].keys():
			inventory[input_resource] -= recipe["input"][input_resource]
		await get_tree().create_timer(recipe["time"]).timeout
		inventory[recipe_name] = inventory.get(recipe_name, 0) + recipe["output"]
		print(city_name, " processed ", recipe_name, ". Inventory: ", inventory)

# Check if processing is possible
func can_process_resource(recipe: Dictionary) -> bool:
	for resource in recipe["input"].keys():
		if inventory.get(resource, 0) < recipe["input"][resource]:
			return false
	return true

# Build a facility
func build_facility(facility_name: String) -> void:
	var facility = facilities.get(facility_name)
	if facility and can_afford(facility["cost"]):
		for resource in facility["cost"].keys():
			inventory[resource] -= facility["cost"][resource]
		apply_facility_effect(facility_name)
		print(city_name, " built ", facility_name)

# Check if city can afford facility
func can_afford(cost: Dictionary) -> bool:
	for resource in cost.keys():
		if inventory.get(resource, 0) < cost[resource]:
			return false
	return true

# Apply facility effects
func apply_facility_effect(facility_name: String) -> void:
	var effect = facilities[facility_name]["effect"]
	for key in effect.keys():
		match key:
			"grain_extraction":
				extraction_rates["grain"] += effect[key]
			"lumber_output":
				recipes["lumber"]["output"] += effect[key]
	# Add more effects as needed
