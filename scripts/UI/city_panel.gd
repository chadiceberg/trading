extends PanelContainer

@onready var main_container = $MainContainer
@onready var vbox_container = $MainContainer/VBoxContainer
@onready var title_label = $MainContainer/VBoxContainer/TitleLabel
@onready var tier_label = $MainContainer/VBoxContainer/TierLabel
@onready var increase_tier_button = $MainContainer/VBoxContainer/HBoxContainer/IncreaseTierButton
@onready var decrease_tier_button = $MainContainer/VBoxContainer/HBoxContainer/DecreaseTierButton
@onready var extraction_label = $MainContainer/VBoxContainer/ExtractionLabel
@onready var upkeep_label = $MainContainer/VBoxContainer/UpkeepLabel
@onready var recipes_label = $MainContainer/VBoxContainer/RecipesLabel
@onready var facilities_label = $MainContainer/VBoxContainer/FacilitiesLabel
@onready var trade_routes_label = $MainContainer/VBoxContainer/TradeRoutesLabel
@onready var close_button = $MainContainer/VBoxContainer/CloseButton
@onready var trade_button_container = $MainContainer/VBoxContainer/TradeButtonContainer

var city_manager: CityManager
var current_city: City

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	increase_tier_button.pressed.connect(_on_increase_tier_pressed)
	decrease_tier_button.pressed.connect(_on_decrease_tier_pressed)
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
	
	# Update all labels and buttons
	title_label.text = info["name"]
	tier_label.text = "Tier: %d" % info["tier"]
	extraction_label.text = "Extraction Rates:\n" + format_dict(info["extraction_rates"])
	upkeep_label.text = "Upkeep Costs:\n" + format_dict(info["upkeep_costs"])
	recipes_label.text = "Recipes:\n" + format_recipes(info["recipes"])
	facilities_label.text = "Facilities:\n" + format_facilities(info["facilities"])
	trade_routes_label.text = "Potential Trade Routes:\n" + format_trade_routes(info["potential_trade_routes"])
	_update_trade_buttons(info["potential_trade_routes"])
	
	# Update button states
	increase_tier_button.disabled = info["tier"] >= city.MAX_TIER
	decrease_tier_button.disabled = info["tier"] <= 0
	
	# Check if the panel is too tall and adjust layout
	_adjust_layout()
	
	# Show and center the panel
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

func _on_increase_tier_pressed() -> void:
	if current_city and current_city.city_tier < current_city.MAX_TIER:
		current_city.city_tier += 1
		update_info(current_city)

func _on_decrease_tier_pressed() -> void:
	if current_city and current_city.city_tier > 0:
		current_city.city_tier -= 1
		update_info(current_city)

func _on_close_pressed() -> void:
	#if city_manager:
		#city_manager.trade_route_visualizer.clear_routes()
	hide()

func _adjust_layout() -> void:
	# Wait for the frame to ensure sizes are updated
	await get_tree().process_frame
	
	# Get screen height and panel size
	var screen_size = get_viewport_rect().size
	var panel_height = vbox_container.get_rect().size.y
	
	# If the panel fits within 90% of screen height, keep single column
	if panel_height <= screen_size.y * 0.9:
		# Ensure single column layout
		if main_container.get_child_count() > 1:
			_restore_single_column()
		return
	
	# Calculate number of columns needed (approximate)
	var children = vbox_container.get_children()
	var child_count = children.size()
	var target_height = screen_size.y * 0.9
	var items_per_column = ceil(float(child_count) / ceil(panel_height / target_height))
	var num_columns = ceil(float(child_count) / items_per_column)
	
	# Clear existing layout
	var original_children = []
	for child in vbox_container.get_children():
		vbox_container.remove_child(child)
		original_children.append(child)
	
	# Create HBoxContainer if not already present
	var hbox: HBoxContainer
	if main_container.get_child_count() == 1:
		hbox = HBoxContainer.new()
		hbox.name = "HBoxContainer"
		main_container.add_child(hbox)
	else:
		hbox = main_container.get_node("HBoxContainer")
		for child in hbox.get_children():
			child.queue_free()
	
	# Create new VBoxContainers for columns
	for i in range(num_columns):
		var new_vbox = VBoxContainer.new()
		new_vbox.name = "Column" + str(i)
		hbox.add_child(new_vbox)
	
	# Distribute children across columns
	var current_column = 0
	var items_in_current_column = 0
	for child in original_children:
		var target_vbox = hbox.get_child(current_column)
		target_vbox.add_child(child)
		items_in_current_column += 1
		if items_in_current_column >= items_per_column and current_column < num_columns - 1:
			current_column += 1
			items_in_current_column = 0
	
	# Update panel size
	size = Vector2.ZERO  # Reset to recalculate
	await get_tree().process_frame
	size = get_rect().size

func _restore_single_column() -> void:
	# If HBoxContainer exists, move all children back to original VBoxContainer
	if main_container.get_child_count() > 1:
		var hbox = main_container.get_node("HBoxContainer")
		var all_children = []
		for vbox in hbox.get_children():
			for child in vbox.get_children():
				vbox.remove_child(child)
				all_children.append(child)
			vbox.queue_free()
		hbox.queue_free()
		
		# Re-add children to original VBoxContainer
		for child in all_children:
			vbox_container.add_child(child)
	
	# Update panel size
	size = Vector2.ZERO
	await get_tree().process_frame
	size = get_rect().size
