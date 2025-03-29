extends Node2D

class_name Tile

@export var movement_cost: float = 1.0
@export var resources: Dictionary = {}
@export var is_passable: bool = true
@export var type: String

@onready var sprite = $Sprite2D
@onready var collision = $Area2D/CollisionShape2D

func _ready() -> void:
	set_process_input(true)
	
func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("tile_clicked", self)
		on_click()
		
func on_click():
	print(type, " clicked at ", position)
