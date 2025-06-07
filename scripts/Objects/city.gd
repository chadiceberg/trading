extends Area2D

class_name City

signal city_clicked(city: City)

# Configuration
@export var city_name: String = "Unnamed City"
@export var init_city_tier: int = 0 
@export var control_radius: float = 300.0
@export var production_interval: float = 5.0

var city_tier: int = 0 : set = _set_city_tier

# Resources
@export var inventory: Dictionary = {
	"grain": 100,
	"iron": 20,
	"wood": 0,
	"lumber": 0,
	"stone": 0,
	"water": 0
}

@export var extraction_rates: Dictionary = {
	"grain": 0,
	"iron": 0,
	"wood": 0,
	"lumber": 0,
	"stone": 0,
	"water": 0
}

@export var upkeep_costs: Dictionary = {
	"grain": 5
}

# Production
@export var recipes: Dictionary = {
	"lumber": {"input": {"wood": 10}, "output": 5, "time": 2.0}
}

@export var facilities: Dictionary = {
	"farm": {"cost": {"grain": 20}, "effect": {"grain_extraction": 5}},
	"sawmill": {"cost": {"grain": 30}, "effect": {"lumber_output": 2}}
}

# Trade
@export var trade_routes: Array = []
var potential_trade_routes: Array[Dictionary] = []

# Node references
@onready var production_timer: Timer = $ProductionTimer
@onready var demand_timer: Timer = $DemandTimer
@onready var world_map: TileMapLayer = $"../world_map"
@onready var extraction_area: Area2D = $ExtractionArea
@onready var city_label: Label = $City_Label
@onready var city_area: Area2D = $CityArea
@onready var extraction_collision: CollisionShape2D = $ExtractionArea/ExtractionCollision
@onready var city_collision: CollisionShape2D = $CityArea/CityCollision

var owned_tiles: Array = []
var city_tiles: Array = []
var city_radius: float = 0.0
var extraction_radius: float = 0.0

const MAX_TIER: int = 5
const BASE_CITY_RADIUS: float = 16.0
const CITY_RADIUS_GROWTH: float = 16.0
const BASE_CONTROL_RADIUS: float = 80.0
const CONTROL_RADIUS_GROWTH: float = 64.0
const BASE_TRADE_DISTANCE: float = 100.0  # Base trade distance for tier 2
const BASE_STORAGE_MAX: int = 1500

var extraction_initialized = false

static var selected_city: City = null

# Terrain costs for trade routes
const TerrainCosts = preload("res://scripts/Data/terrain_costs.gd")

func _ready() -> void:
	await get_tree().process_frame
	_initialize_city()

func _physics_process(_delta: float) -> void:
	#_update_extraction_area()
	#_update_extraction_rates()
	pass
	
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("City %s clicked at %s" % [name, global_position])
		
		# Unhighlight tiles of previously selected city
		if selected_city and selected_city != self:
			selected_city._unhighlight_tiles()
		
		# Set this city as selected and highlight its tiles
		selected_city = self
		_highlight_tiles()
		
		emit_signal("city_clicked", self)
		_update_extraction_area()
		_update_extraction_rates()

func _initialize_city() -> void:
	name = city_name
	add_to_group("cities")
	city_label.text = city_name
	city_tier = init_city_tier
	_setup_timers()

func _setup_timers() -> void:
	production_timer.wait_time = production_interval
	production_timer.start()
	demand_timer.wait_time = production_interval / 2
	demand_timer.start()

func _update_extraction_area() -> void:
	owned_tiles = extraction_area.get_overlapping_areas()
	print("%s updating extraction area with radius %.1f: %d tiles detected" % [city_name, extraction_collision.shape.radius if extraction_collision.shape else 0.0, owned_tiles.size()])

func _set_city_tier(new_tier: int) -> void:
	city_tier = clampi(new_tier, 0, MAX_TIER)
	_unhighlight_tiles()
	_update_extraction_radius()
	_update_city_radius()
	_update_city_tiles()
	_update_extraction_area()
	_update_extraction_rates()
	_highlight_tiles()
	print("City Name: %s  City Tier: %d  City Radius: %.1f  Extraction Radius: %.1f" % [city_name, city_tier, city_radius, extraction_radius])
	print("%s tier updated to %d" % [city_name, city_tier])

func _update_city_radius() -> void:
	if not city_collision:
		push_error("%s: City collision node not initialized!" % city_name)
		return
	
	# Calculate new city radius
	if city_tier == 0:
		city_radius = 0.0
	else:
		city_radius = BASE_CITY_RADIUS + (CITY_RADIUS_GROWTH * (city_tier - 1))
	
	# Create new CircleShape2D with updated radius
	var new_shape = CircleShape2D.new()
	new_shape.radius = city_radius
	city_collision.shape = new_shape
	
	print("%s city radius updated: city_radius=%.1f, extraction_radius=%.1f" % [city_name, city_radius, extraction_radius])

func _update_extraction_radius() -> void:
	if not extraction_collision:
		push_error("%s: Extraction collision node not initialized!" % city_name)
		return
	
	extraction_radius = (BASE_CONTROL_RADIUS * city_tier) + BASE_CONTROL_RADIUS
	
	# Create new CircleShape2D with updated radius
	var new_shape = CircleShape2D.new()
	new_shape.radius = extraction_radius
	extraction_collision.shape = new_shape
	
	print("%s extraction radius updated to %.1f" % [city_name, extraction_radius])

func _update_city_tiles() -> void:
	city_tiles.clear()
	if not world_map:
		push_error("%s: No world_map assigned!" % city_name)
		return
	
	var center_pos = Vector2i(global_position / 16.0)  # Approximate tile coords (adjust if tile size differs)
	
	
	city_tiles = city_area.get_overlapping_areas()
	
	print("%s updated city_tiles: %d tiles" % [city_name, city_tiles.size()])



func _on_production_timer_timeout() -> void:
	for resource in extraction_rates.keys():
		inventory[resource] = inventory.get(resource, 0) + extraction_rates[resource]
	
	print(city_name, inventory)

func _on_demand_timer_timeout() -> void:
	for resource in upkeep_costs.keys():
		if inventory[resource] >= upkeep_costs[resource]:
			inventory[resource] -= upkeep_costs[resource]
		else:
			print("%s is in deficit for %s!" % [city_name, resource])

func get_info() -> Dictionary:
	return {
		"name": city_name,
		"tier": city_tier,
		"inventory": inventory,
		"extraction_rates": extraction_rates,
		"upkeep_costs": upkeep_costs,
		"recipes": recipes,
		"facilities": facilities,
		"city_tiles": city_tiles,
		"potential_trade_routes": potential_trade_routes
	}

func trade_with(target_city: City, resource: String, amount: int) -> void:
	if inventory.get(resource, 0) >= amount:
		inventory[resource] -= amount
		target_city.receive_trade(resource, amount, self)
		print("%s sent %d %s to %s" % [city_name, amount, resource, target_city.city_name])
	else:
		print("%s lacks enough %s for trade!" % [city_name, resource])

func receive_trade(resource: String, amount: int, sender: City) -> void:
	inventory[resource] = inventory.get(resource, 0) + amount
	print("%s received %d %s from %s" % [city_name, amount, resource, sender.city_name])

func process_resource(recipe_name: String) -> void:
	var recipe = recipes.get(recipe_name)
	if recipe and can_process_resource(recipe):
		for input_resource in recipe["input"].keys():
			inventory[input_resource] -= recipe["input"][input_resource]
		await get_tree().create_timer(recipe["time"]).timeout
		inventory[recipe_name] = inventory.get(recipe_name, 0) + recipe["output"]
		print("%s processed %s. Inventory: %s" % [city_name, recipe_name, inventory])

func can_process_resource(recipe: Dictionary) -> bool:
	for resource in recipe["input"].keys():
		if inventory.get(resource, 0) < recipe["input"][resource]:
			return false
	return true

func build_facility(facility_name: String) -> void:
	var facility = facilities.get(facility_name)
	if facility and can_afford(facility["cost"]):
		for resource in facility["cost"].keys():
			inventory[resource] -= facility["cost"][resource]
		_apply_facility_effect(facility_name)
		print("%s built %s" % [city_name, facility_name])

func can_afford(cost: Dictionary) -> bool:
	for resource in cost.keys():
		if inventory.get(resource, 0) < cost[resource]:
			return false
	return true

func _apply_facility_effect(facility_name: String) -> void:
	var effect = facilities[facility_name]["effect"]
	for key in effect.keys():
		match key:
			"grain_extraction":
				extraction_rates["grain"] += effect[key]
			"lumber_output":
				recipes["lumber"]["output"] += effect[key]

func _log_tiles_in_radius(tiles: Array) -> void:
	if tiles.is_empty():
		print("%s: No tiles in extraction radius." % city_name)
		return
	
	print("%s: Tiles in extraction radius:" % city_name)
	for tile in tiles:
		var coords = tile.global_position
		print(" Type: %s -  Coordinates: (%d, %d)" % [tile.tile_type, coords.x, coords.y])

func _update_extraction_rates() -> void:
	clear_dictionary_values(extraction_rates)
	for tile in owned_tiles:
		var tile_rates = tile.get_extraction_rates()
		for key in extraction_rates:
			if tile_rates.has(key):
				extraction_rates[key] += tile_rates[key]
	print("%s extraction rates updated: %s" % [city_name, extraction_rates])

func calculate_potential_trade_routes(cities: Array[City]) -> void:
	potential_trade_routes.clear()
	if city_tier < 2:
		return
	
	var max_distance = BASE_TRADE_DISTANCE * city_tier / 2.0
	var start_pos = Vector2i(global_position / 16.0)  # Approximate tile coords
	
	for target_city in cities:
		if target_city == self:
			continue
		var end_pos = Vector2i(target_city.global_position / 16.0)
		var path = _find_path(start_pos, end_pos, max_distance)
		if path.size() > 0:
			var route_cost = _calculate_path_cost(path)
			if route_cost <= max_distance:
				potential_trade_routes.append({
					"target_city": target_city,
					"path": path,
					"cost": route_cost
				})
	
	print("%s calculated %d potential trade routes" % [city_name, potential_trade_routes.size()])

func _find_path(start: Vector2i, end: Vector2i, max_distance: float) -> Array[Vector2i]:
	var open_set: Array[Vector2i] = [start]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {start: 0.0}
	var f_score: Dictionary = {start: _heuristic(start, end)}
	
	while open_set.size() > 0:
		var current = _get_lowest_f_score(open_set, f_score)
		if current == end:
			return _reconstruct_path(came_from, current)
		
		open_set.erase(current)
		
		for neighbor in _get_neighbors(current):
			var tentative_g_score = g_score[current] + _get_terrain_cost(neighbor)
			if tentative_g_score < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g_score
				f_score[neighbor] = tentative_g_score + _heuristic(neighbor, end)
				if tentative_g_score <= max_distance and not open_set.has(neighbor):
					open_set.append(neighbor)
	
	return []

func _get_lowest_f_score(open_set: Array[Vector2i], f_score: Dictionary) -> Vector2i:
	var lowest = open_set[0]
	var lowest_score = f_score[lowest]
	for pos in open_set:
		if f_score[pos] < lowest_score:
			lowest = pos
			lowest_score = f_score[pos]
	return lowest

func _heuristic(a: Vector2i, b: Vector2i) -> float:
	return a.distance_to(b)

func _get_neighbors(pos: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var tile_size = 16.0  # Hardcoded; adjust if needed
	for offset in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
		var neighbor = pos + offset
		# Check if a tile exists at this position
		for tile in get_tree().get_nodes_in_group("tiles"):
			var tile_pos = Vector2i(tile.global_position / tile_size)
			if tile_pos == neighbor and tile.is_passable:
				neighbors.append(neighbor)
				break
	return neighbors

func _get_terrain_cost(pos: Vector2i) -> float:
	var tile_size = 16.0
	var world_pos = Vector2(pos) * tile_size
	for tile in get_tree().get_nodes_in_group("tiles"):
		if tile.global_position.distance_to(world_pos) < tile_size / 2:
			return tile.get_terrain_cost()
       return TerrainCosts.TERRAIN_COSTS["unknown"]

func _calculate_path_cost(path: Array[Vector2i]) -> float:
	var cost = 0.0
	for pos in path:
		cost += _get_terrain_cost(pos)
	return cost

func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [current]
	while came_from.has(current):
		current = came_from[current]
		path.append(current)
	path.reverse()
	return path

func establish_trade_route(target_city: City, path: Array[Vector2i]) -> void:
	trade_routes.append({"city": target_city, "path": path})
	print("%s established trade route with %s" % [city_name, target_city.city_name])
	
func clear_dictionary_values(dict: Dictionary) -> void:
	for key in dict.keys():
		dict[key] = 0

func _highlight_tiles() -> void:
	_update_extraction_area()
	for tile in owned_tiles:
		if tile is Tile:
			tile.highlight()
	print("%s highlighted %d tiles in extraction radius" % [city_name, owned_tiles.size()])

func _unhighlight_tiles() -> void:
	for tile in owned_tiles:
			if tile is Tile:
				tile.unhighlight()
	print("%s unhighlighted %d tiles" % [city_name, owned_tiles.size()])
