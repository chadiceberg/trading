extends	Area2D

class_name City

signal city_clicked(city: City)
# Exported variables for easy tweaking in the editor
@export var inventory: Dictionary = {
	"grain": 100,
	"iron": 20,
	"lumber": 0,  # Processed good example
}
@export var control_radius: float = 300.0  # Radius for resource extraction
@export var production_interval: float = 5.0  # Time between production ticks
@export var city_name: String = "Unnamed City"
@export var city_tier: int = 0

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
@onready var world_map = $"../world_map"
@onready var extraction_area = $extraction_area
@onready var collision_shape = $CollisionShape2D

var owned_tiles: Array = []

func _ready() -> void:
	print ("city initializing")
	add_to_group("cities")
	if not is_connected("input_event", _on_input_event):
		input_event.connect(_on_input_event)
	if collision_shape == null:
		push_error("CollisionShape2D missing in %s" % name)
	else:
		print("City %s initialized at %s, collision extents: %s" % [
			name, global_position, collision_shape.shape.extents if collision_shape.shape is RectangleShape2D else "N/A"
		])
	# Set up timers if not already done in the editor
	$City_Label.text = city_name
	production_timer.wait_time = production_interval
	production_timer.start()
	demand_timer.wait_time = production_interval / 2  # Upkeep ticks more often
	demand_timer.start()
	if not is_connected("input_event", _on_input_event):
		input_event.connect(_on_input_event)
	print("City %s initialized at %s" % [name, global_position])
	owned_tiles = extraction_area.get_overlapping_areas()
	update_extraction_rates(owned_tiles)
	print_tiles_in_radius(owned_tiles)
	
# Get the CollisionShape2D from the Area2D
	var collision_shape = extraction_area.get_node("Extraction_Radius")
	if not collision_shape or not collision_shape.shape:
		print("No valid collision shape found!")
		return
	
	# Get the shape and its extent
	var shape = collision_shape.shape
	var center_world_pos = extraction_area.global_position
	
	# Convert center position to tile coordinates
	var center_tile_pos = world_map.local_to_map(world_map.to_local(center_world_pos))
	
	# Calculate the range of tiles to check based on shape
	var tile_size = world_map.tile_set.tile_size  # e.g., Vector2i(16, 16)
	var tiles_covered = []
	
	if shape is CircleShape2D:
		var radius = shape.radius
		var radius_in_tiles = int(radius / tile_size.x) + 1  # Approximate tile coverage
		
		# Check all tiles in a square around the center, then filter by radius
		for x in range(-radius_in_tiles, radius_in_tiles + 1):
			for y in range(-radius_in_tiles, radius_in_tiles + 1):
				var tile_pos = Vector2i(center_tile_pos.x + x, center_tile_pos.y + y)
				# Convert tile position back to world space to check distance
				var tile_world_pos = world_map.to_global(world_map.map_to_local(tile_pos))
				if center_world_pos.distance_to(tile_world_pos) <= radius:
					var tile_id = world_map.get_cell_source_id(tile_pos)
					if tile_id != -1:  # Tile exists
						tiles_covered.append({"pos": tile_pos, "id": tile_id})
						

	
	elif shape is RectangleShape2D:
		var extents = shape.extents
		var extents_in_tiles_x = int(extents.x / tile_size.x) + 1
		var extents_in_tiles_y = int(extents.y / tile_size.y) + 1
		
		# Check all tiles within the rectangle
		for x in range(-extents_in_tiles_x, extents_in_tiles_x + 1):
			for y in range(-extents_in_tiles_y, extents_in_tiles_y + 1):
				var tile_pos = Vector2i(center_tile_pos.x + x, center_tile_pos.y + y)
				var tile_id = world_map.get_cell_source_id(tile_pos)
				if tile_id != -1:
					tiles_covered.append({"pos": tile_pos, "id": tile_id})
	
	# Output the results
	if tiles_covered.size() > 0:
		print("City %s extraction area covers %d tiles:" % [name, tiles_covered.size()])
		#for tile in tiles_covered:
			#var tile_data = world_map.get_cell_tile_data(tile.pos)
			#var tile_name = tile_data.get_custom_data("name") if tile_data else "Unnamed"
			#print(" - Tile at", tile.pos)
	else:
		print("City %s extraction area covers no tiles" % name)
	
	
func _physics_process(delta):
	var overlapping_bodies = extraction_area.get_overlapping_bodies()
	if overlapping_bodies.size() > 0:
		print("City %s detects %d bodies:" % [name, overlapping_bodies.size()])
		for body in overlapping_bodies:
			if body is Tile:
				print(" - Overlapping TileMap: %s" % body.type)
				# Optional: Check specific tiles (see below)
				
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("City %s clicked at %s" % [name, global_position])
		emit_signal("city_clicked", self)

func get_city_info() -> Dictionary:
	return {
		"extraction_rates": extraction_rates,
		"upkeep_costs": upkeep_costs,
		"recipes": recipes,
		"facilities": facilities
	}

# Resource extraction on timer
func _on_production_timer_timeout() -> void:
	for resource in extraction_rates.keys():
		inventory[resource] = inventory.get(resource, 0) + extraction_rates[resource]
	# print(city_name, " produced resources. Inventory: ", inventory)

# Upkeep/demand on timer
func _on_demand_timer_timeout() -> void:
	for resource in upkeep_costs.keys():
		if inventory[resource] >= upkeep_costs[resource]:
			inventory[resource] -= upkeep_costs[resource]
		else:
			print(city_name, " is in deficit for ", resource, "!")
			# Add penalty logic here (e.g., reduce production)
	# print(city_name, " upkeep paid. Inventory: ", inventory)

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
func get_tiles_in_radius() -> Array:
	if not extraction_area:
		print(city_name, ": No ExtractionArea assigned!")
		return []
	
	var tiles_in_radius: Array = []
	var overlapping_bodies = extraction_area.get_overlapping_bodies()  # Get StaticBody2D tiles
	
	for body in overlapping_bodies:
		var tile = body.get_parent()  # Assuming tile is the parent Node2D
		if tile.has_method("get_type"):  # Check if it’s a tile node
			tiles_in_radius.append(tile)
	
	return tiles_in_radius

# Get tiles in radius (updated for node-based tiles)
func print_tiles_in_radius(tiles: Array) -> void:
	if tiles.is_empty():
		print(city_name, ": No tiles in extraction radius.")
		return
	
	print(city_name, ": Tiles in extraction radius:")
	for tile in tiles:
		var tile_type = tile.get_type()
		var coords = tile.position
		print(" - Type: ", tile_type, " | Coordinates: (", coords.x, ", ", coords.y, ")")

# Update extraction rates based on tile nodes
func update_extraction_rates(tiles: Array) -> void:
	extraction_rates = {"grain": 0, "iron": 0, "wood": 0}
	
	for tile in tiles:
		var tile_type = tile.get_type()
		match tile_type:
			"fertile":
				extraction_rates["food"] += tile.extraction_value
			"grain":
				extraction_rates["grain"] += tile.extraction_value  # Use tile's value
			"mine":
				extraction_rates["iron"] += tile.extraction_value
			"forest":
				extraction_rates["wood"] += tile.extraction_value
			"mountain":
				extraction_rates["iron"] += tile.extraction_value
			"rural":
				extraction_rates["wood"] += tile.extraction_value
			"swamp":
				extraction_rates["wood"] += tile.extraction_value
			"water":
				print("WATER")
	print(city_name, " extraction rates updated: ", extraction_rates)
