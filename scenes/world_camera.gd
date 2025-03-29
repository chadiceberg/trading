extends Camera2D

var drag_start_pos: Vector2
var is_dragging: bool = false
@export var drag_button: MouseButton = MOUSE_BUTTON_RIGHT

@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.0

@export var boundary_left: float = -1000
@export var boundary_right: float = 1000
@export var boundary_top: float = -1000
@export var boundary_bottom: float = 1000

func _ready():
	position = Vector2(boundary_right / 2, boundary_bottom / 2)
	
func _process(delta):
	pass
	# print("Camera pos: ", position, " | Zoom: ", zoom)

func _unhandled_input(event: InputEvent) -> void:
	
	if event is InputEventMouseButton:
		if event.button_index == drag_button:
			if event.pressed:
				drag_start_pos = event.position
				is_dragging = true
			else:
				is_dragging = false
		
	if is_dragging and event is InputEventMouseMotion:
		position -= (event.position - drag_start_pos) * zoom.x
		drag_start_pos = event.position
		_clamp_camera_position()
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(zoom_speed, get_global_mouse_position())
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(-zoom_speed, get_global_mouse_position())
	
	

func _zoom_camera(zoom_delta: float, zoom_anchor: Vector2):
	var old_zoom = zoom
	zoom += Vector2(zoom_delta, zoom_delta)
	zoom = zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
	
	if zoom != old_zoom:
		var mouse_offset = zoom_anchor - position 
		position -= mouse_offset * (zoom - old_zoom) / old_zoom
		_clamp_camera_position()

func _clamp_camera_position():
	return
	var viewpoint_size = get_viewport_rect().size / zoom_speed
	position.x = clamp(position.x, boundary_left + viewpoint_size.x / 2, boundary_right - viewpoint_size.x / 2)
	position.y = clamp(position.y, boundary_top + viewpoint_size.y / 2, boundary_bottom - viewpoint_size.y / 2)
