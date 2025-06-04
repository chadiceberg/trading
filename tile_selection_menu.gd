extends Control

@onready var tile_manager = $TileManager

func _on_default_button_pressed() -> void:
	emit_signal("tile_type_received", "default")

func _on_grain_button_pressed() -> void:
	tile_manager.emit_signal("tile_type_received", "grain")

func _on_forest_button_pressed() -> void:
	tile_manager.emit_signal("tile_type_received", "forest")


func _on_fertile_button_pressed() -> void:
	tile_manager.emit_signal("tile_type_received", "fertile")

func _on_swamp_button_pressed() -> void:
	tile_manager.emit_signal("tile_type_received", "swamp")

func _on_water_button_pressed() -> void:
	tile_manager.emit_signal("tile_type_received", "water")

func _on_mountain_button_pressed() -> void:
	tile_manager.emit_signal("tile_type_received", "mountain")

func _on_mine_button_pressed() -> void:
	tile_manager.emit_signal("tile_type_received", "mine")

func _on_rural_button_pressed() -> void:
	tile_manager.emit_signal("tile_type_received", "rural")
