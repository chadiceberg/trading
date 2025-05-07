extends PanelContainer

@onready var title_label = $VBoxContainer/TitleLabel
@onready var extraction_label = $VBoxContainer/ExtractionLabel
@onready var upkeep_label = $VBoxContainer/UpkeepLabel
@onready var recipes_label = $VBoxContainer/RecipesLabel
@onready var facilities_label = $VBoxContainer/FacilitiesLabel
@onready var trade_routes_label = $VBoxContainer/TradeRoutesLabel
@onready var close_button = $VBoxContainer/CloseButton
@onready var trade_button_container = $VBoxContainer/TradeButtonContainer

var city_manager: CityManager
var current_city: City

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	hide()
	_find_city_manager()

func _find_city_manager() -> void:
	for node in get_tree().get_nodes_in_group("city_manager"):
		if node is CityManager:
			city_manager = node
			break
	if not city_manager:
		push_error("CityInfoPanel: No CityManager found!")

func update_info(city: City) -> void:
	current_city = city
	var info = city.get_info()
	title_label.text = info["name"]
	extraction_label.text = "Extraction Rates:\n" + format_dict(info["extraction_rates"])
	upkeep_label.text = "Upkeep Costs:\n" + format_dict(info["upkeep_costs"])
	recipes_label.text = "Recipes:\n" + format_recipes(info["recipes"])
	facilities_label.text = "Facilities:\n" + format_facilities(info["facilities"])
	trade_routes_label.text = "Potential Trade Routes:\n" + format_trade_routes(info["potential_trade_routes"])
	_update_trade_buttons(info["potential_trade_routes"])
	show()
	position = (get_viewport_rect().size - size) / 2

func format_dict(dict: Dictionary) -> String:
	var result = ""
	for key in dict.keys():
		result += "%s: %s\n" % [key.capitalize(), dict[key]]
	return result if result else "None"

func format_recipes(recipes: Dictionary) -> String:
	var result = ""
	for key in recipes.keys():
		var recipe = recipes[key]
		result += "%s: Input %s, Output %s, Time %.1fs\n" % [
			key.capitalize(), format_dict(recipe["input"]), recipe["output"], recipe["time"]
		]
	return result if result else "None"

func format_facilities(facilities: Dictionary) -> String:
	var result = ""
	for key in facilities.keys():
		var facility = facilities[key]
		result += "%s: Cost %s, Effect %s\n" % [
			key.capitalize(), format_dict(facility["cost"]), format_dict(facility["effect"])
		]
	return result if result else "None"

func format_trade_routes(routes: Array[Dictionary]) -> String:
	var result = ""
	for route in routes:
		var target_city = route["target_city"]
		var cost = route["cost"]
		result += "To %s: Cost %.1f\n" % [target_city.city_name, cost]
	return result if result else "None"

func _update_trade_buttons(routes: Array[Dictionary]) -> void:
	for child in trade_button_container.get_children():
		child.queue_free()
	
	for route in routes:
		var target_city = route["target_city"]
		var button = Button.new()
		button.text = "Trade with %s" % target_city.city_name
		button.pressed.connect(func(): _on_trade_button_pressed(target_city))
		trade_button_container.add_child(button)

func _on_trade_button_pressed(target_city: City) -> void:
	if city_manager and current_city:
		city_manager.establish_trade_route(current_city, target_city)
		update_info(current_city)

func _on_close_pressed() -> void:
	if city_manager:
		city_manager.trade_route_visualizer.clear_routes()
	hide()
