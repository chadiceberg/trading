extends Node

@onready var tile_map_layer: TileMapLayer = $"../world_map"
var tile_instances: Dictionary = {} # Vector2i -> Tile
var city_instances: Array = [] # Array of City
var city_panel: Node = null
var city_panel_scene: PackedScene = preload("res://city_panel.tscn")

func _ready() -> void:
	if tile_map_layer == null:
		push_error("tile_map_layer is null!")
		return
	print("tile_map_layer initialized: ", tile_map_layer.name)
	
	city_panel = city_panel_scene.instantiate()
	add_child(city_panel)
	city_panel.hide()
	
	await get_tree().process_frame
	initialize_tiles()
	initialize_cities()

func initialize_tiles() -> void:
	var tiles = get_tree().get_nodes_in_group("tiles")
	print("Found tiles: ", tiles.size())
	if tiles.is_empty():
		push_error("No tiles found!")
		return
	for tile in tiles:
		var tile_pos = tile_map_layer.local_to_map(tile.global_position)
		tile_instances[tile_pos] = tile
		#print("Tile at %s: %s" % [tile_pos, tile.get_type()])
		tile.tile_clicked.connect(_on_tile_clicked.bind(tile_pos))

func initialize_cities() -> void:
	var cities = get_tree().get_nodes_in_group("cities")
	print("Found cities: ", cities.size())
	for city in cities:
		print("Registering city: %s at %s" % [city.name, city.global_position])
		city_instances.append(city)
		if not city.is_connected("city_clicked", _on_city_clicked):
			city.city_clicked.connect(_on_city_clicked)
			print("Connected city_clicked for %s" % city.name)

func _on_tile_clicked(tile: Tile, tile_pos: Vector2i) -> void:
	print("Tile clicks disabled for testing")
	#print("Tile clicked: %s at %s, resources: %s" % [
		#tile.get_type(), tile_pos, tile.resources
	#])
	#city_panel.hide()
	#harvest_resource(tile, tile_pos)

func _on_city_clicked(city: City) -> void:
	print("Handling city click for %s at %s" % [city.name, city.global_position])
	city_panel.update_info(city)

func harvest_resource(tile: Tile, tile_pos: Vector2i) -> void:
	for resource in tile.resources.keys():
		var amount = min(tile.resources[resource], tile.extraction_value)
		if amount > 0:
			tile.resources[resource] -= amount
			print("Harvested %d %s from %s" % [amount, resource, tile.get_type()])
			if tile.resources[resource] <= 0:
				tile.resources.erase(resource)
				if tile.resources.is_empty():
					tile_map_layer.set_cell(tile_pos, -1)
					tile_instances.erase(tile_pos)
					tile.queue_free()
					print("%s at %s depleted" % [tile.get_type(), tile_pos])
