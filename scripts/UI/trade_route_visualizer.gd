extends Node2D

class_name TradeRouteVisualizer

var routes: Array[Dictionary] = []

func _draw() -> void:
	for route in routes:
		var path = route["path"]
		var world_map = route["world_map"]
		var color = Color(0, 1, 0, 0.5)  # Green with transparency
		for i in range(path.size() - 1):
			var start = world_map.to_global(world_map.map_to_local(path[i]))
			var end = world_map.to_global(world_map.map_to_local(path[i + 1]))
			draw_line(start, end, color, 2.0)
	pass

func add_route(path: Array[Vector2i], world_map: TileMapLayer, target_city: City) -> void:
	routes.append({"path": path, "world_map": world_map, "target_city": target_city})
	queue_redraw()

func clear_routes() -> void:
	routes.clear()
	queue_redraw()
