extends Area2D

class_name Tile

signal tile_clicked(tile: Tile)

# Configuration
@export var tile_type: String = "unknown" : set = _set_tile_type
@export var is_passable: bool = true
@export var movement_cost: float = 1.0
@export var extraction_value: int = 1

# Resources
@export var base_production: Dictionary = 	{
	"grain": 0,
	"iron": 0,
	"wood": 0,
	"lumber": 0,
	"stone": 0,
	"water": 0
	}
@export var resources: Dictionary = {}
var tile_production = {}
# State
var controlled_by: Node = null
var overlapping_areas: Array[Area2D] = []

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Terrain costs for trade routes (shared with City.gd)
const TerrainCosts = preload("res://scripts/Data/terrain_costs.gd")

func _ready() -> void:
        _set_tile_type(tile_type)
        _initialize_tile()
        _check_overlaps()

func _initialize_tile() -> void:
	add_to_group("tiles")
	if not collision_shape:
		push_error("Tile %s at %s missing CollisionShape2D" % [tile_type, global_position])
	if not sprite:
		push_warning("Tile %s at %s missing Sprite2D" % [tile_type, global_position])
	if not tile_type:
		push_error("Tile at %s has no type assigned" % global_position)
		tile_type = "unknown"
	if not is_connected("input_event", _on_input_event):
		input_event.connect(_on_input_event)
	name = "Tile_%s_%s" % [tile_type, global_position]
	#print("Tile %s initialized at %s" % [tile_type, global_position])
	tile_production = base_production

func _check_overlaps() -> void:
	overlapping_areas = get_overlapping_areas()
	if overlapping_areas.size() > 0:
		print("Tile %s at %s overlaps with %d areas" % [tile_type, global_position, overlapping_areas.size()])

func _set_tile_type(new_type: String) -> void:
	tile_type = new_type
       if tile_type in TerrainCosts.TERRAIN_COSTS:
               movement_cost = TerrainCosts.TERRAIN_COSTS[tile_type]
	else:
               movement_cost = TerrainCosts.TERRAIN_COSTS["unknown"]
		push_warning("Tile type %s not in TERRAIN_COSTS, using default cost" % tile_type)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click()

func _handle_click() -> void:
	print("Tile %s clicked at %s" % [tile_type, global_position])
	emit_signal("tile_clicked", self)

func get_tile_state() -> Dictionary:
	return {
		"tile_type": tile_type,
		"global_position": global_position,
		"extraction_value": extraction_value
	}
	

func get_type() -> String:
	return tile_type

func get_terrain_cost() -> float:
	return movement_cost

func get_controlled_production() -> Dictionary:
	return base_production.duplicate() if controlled_by else {}

func get_extraction_value() -> int:
	return extraction_value

func set_controlled_by(controller: Node) -> void:
	controlled_by = controller
	print("Tile %s at %s now controlled by %s" % [tile_type, global_position, controller.name if controller else "none"])

func get_extraction_rates() -> Dictionary:
	return base_production
	
func highlight() -> void:
	if sprite:
		sprite.modulate = Color(1,1,0,1)
		
func unhighlight() -> void:
	if sprite:
		sprite.modulate = Color(1,1,1,1)
