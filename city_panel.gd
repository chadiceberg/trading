extends PanelContainer

@onready var title_label = $VBoxContainer/TitleLabel
@onready var extraction_label = $VBoxContainer/ExtractionLabel
@onready var upkeep_label = $VBoxContainer/UpkeepLabel
@onready var recipes_label = $VBoxContainer/RecipesLabel
@onready var facilities_label = $VBoxContainer/FacilitiesLabel
@onready var close_button = $VBoxContainer/CloseButton

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	hide()

func update_info(city: City) -> void:
	var info = city.get_city_info()
	title_label.text = "City Info"
	extraction_label.text = "Extraction Rates:\n" + format_dict(info["extraction_rates"])
	upkeep_label.text = "Upkeep Costs:\n" + format_dict(info["upkeep_costs"])
	#recipes_label.text = "Recipes:\n" + format_recipes(info["recipes"])
	facilities_label.text = "Facilities:\n" + format_facilities(info["facilities"])
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

func _on_close_pressed() -> void:
	hide()
