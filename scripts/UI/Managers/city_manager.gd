extends Node

class_name CityManager

var cities: Array[City] = []
var trade_route_visualizer: TradeRouteVisualizer

var selected_city: City = null

signal city_clicked_via_manager(city: City)

func _ready() -> void:
	_find_cities()
	_setup_visualizer()

func _setup_visualizer() -> void:
	trade_route_visualizer = TradeRouteVisualizer.new()
	add_child(trade_route_visualizer)

func _find_cities() -> void:
	cities = []
	for node in get_tree().get_nodes_in_group("cities"):
		if node is City:
			cities.append(node)
			node.city_clicked.connect(_on_city_clicked)
	print("CityManager found %d cities" % cities.size())

func add_city(city: City) -> void:
	if not cities.has(city):
		cities.append(city)
		city.add_to_group("cities")
		city.city_clicked.connect(_on_city_clicked)
		print("CityManager added city: %s" % city.city_name)

func remove_city(city: City) -> void:
	cities.erase(city)
	if city.is_in_group("cities"):
		city.remove_from_group("cities")
	if city.is_connected("city_clicked", _on_city_clicked):
		city.city_clicked.disconnect(_on_city_clicked)
	print("CityManager removed city: %s" % city.city_name)

func get_city_by_name(city_name: String) -> City:
	for city in cities:
		if city.city_name == city_name:
			return city
	return null

func initiate_trade(sender: City, target: City, resource: String, amount: int) -> void:
	if sender and target and sender != target:
		sender.trade_with(target, resource, amount)

func process_all_resources() -> void:
	for city in cities:
		for recipe_name in city.recipes.keys():
			if city.can_process_resource(city.recipes[recipe_name]):
				city.process_resource(recipe_name)

func build_facility_in_city(city_name: String, facility_name: String) -> void:
	var city = get_city_by_name(city_name)
	if city:
		city.build_facility(facility_name)

func get_all_cities_info() -> Array[Dictionary]:
	var info_array: Array[Dictionary] = []
	for city in cities:
		info_array.append(city.get_info())
	return info_array

func calculate_all_trade_routes() -> void:
	for city in cities:
		city.calculate_potential_trade_routes(cities)

func show_trade_routes(city: City) -> void:
	trade_route_visualizer.clear_routes()
	for route in city.potential_trade_routes:
		var path = route["path"]
		var target_city = route["target_city"]
		trade_route_visualizer.add_route(path, city.world_map, target_city)

func establish_trade_route(sender: City, target: City) -> void:
	for route in sender.potential_trade_routes:
		if route["target_city"] == target:
			sender.establish_trade_route(target, route["path"])
			trade_route_visualizer.clear_routes()
			break

func _on_city_clicked(city: City) -> void:
	print("CityManager: City %s was clicked" % city.city_name)
	city._update_extraction_area()
	calculate_all_trade_routes()
	show_trade_routes(city)
	
	selected_city = city
	print("New selected city")
	emit_signal("city_clicked_via_manager", selected_city)
	
