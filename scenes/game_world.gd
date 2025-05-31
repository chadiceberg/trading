extends Node2D

var selected_city: City = null

@export var default_city: City

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	pass

func _on_city_city_clicked(city: City) -> void:
	selected_city = city
	print("Selected new City: ", selected_city.city_name)
