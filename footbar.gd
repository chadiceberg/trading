extends Control

# Signals
signal build_facility_requested(city: City, facility_name: String)
signal trade_route_requested(city: City, target_city: City)

# Node references
@onready var city_info_label: Label = $PanelContainer/HBoxContainer/CityInfoLabel
#@onready var build_button: Button = $PanelContainer/HBoxContainer/BuildButton
#@onready var trade_button: Button = $PanelContainer/HBoxContainer/TradeButton
@onready var grain_label: Label = $PanelContainer/HBoxContainer/GrainLabel
@onready var stone_label: Label = $PanelContainer/HBoxContainer/StoneLabel
@onready var wood_label: Label = $PanelContainer/HBoxContainer/WoodLabel

# State
var selected_city: City = null

func _ready() -> void:
	# Anchor the Control node to the bottom of the viewport
	set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	set_offset(SIDE_TOP, -40)  # 40 pixels high
	set_offset(SIDE_LEFT, 0)
	set_offset(SIDE_RIGHT, 0)
	set_offset(SIDE_BOTTOM, 0)
	
	# Connect button signals
	#build_button.pressed.connect(_on_build_button_pressed)
	#trade_button.pressed.connect(_on_trade_button_pressed)
	
	# Initialize UI
	update_ui()

func set_selected_city(city: City) -> void:
	selected_city = city
	update_ui()

func update_ui() -> void:
	if selected_city:
		var info = selected_city.get_info()
		city_info_label.text = "%s (Tier %d)\nGrain: %d\nIron: %d\nWood: %d" % [
			info["name"], 
			info["tier"]
		]
		grain_label.text = str(info["inventory"].get("grain", 0))
		stone_label.text = str(info["inventory"].get("stone", 0))
		wood_label.text = str(info["inventory"].get("wood", 0))
	else:
		city_info_label.text = "No city selected"

func _on_build_button_pressed() -> void:
	if selected_city:
		# Example: Build a farm (modify as needed for your game)
		emit_signal("build_facility_requested", selected_city, "farm")

func _on_trade_button_pressed() -> void:
	if selected_city:
		# Find a target city for trade (simplified; you may want a UI to select target)
		var cities = get_tree().get_nodes_in_group("cities")
		for city in cities:
			if city != selected_city:
				emit_signal("trade_route_requested", selected_city, city)
				break


func _on_city_manager_city_clicked_via_manager(city: City) -> void:
	selected_city = city
	update_ui()
