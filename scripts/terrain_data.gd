extends Resource
class_name TerrainData

@export var name: String = "Grass"
@export var texture: Texture2D
@export var movement_cost: float = 1.0
@export var resources: Dictionary = {}
@export var is_passable: bool = true
