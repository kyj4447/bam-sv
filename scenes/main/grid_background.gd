class_name GridBackground
extends Node2D

@export var grid_size: float = 64.0
@export var grid_color: Color = Color(0.12, 0.15, 0.22, 1.0)
@export var bg_color: Color = Color(0.06, 0.08, 0.12, 1.0)

var camera: Camera2D = null

func _ready() -> void:
	z_index = -100

func _process(_delta: float) -> void:
	if not is_instance_valid(camera):
		camera = get_viewport().get_camera_2d()
	queue_redraw()

func _draw() -> void:
	var vp_size := get_viewport_rect().size
	var center := Vector2.ZERO
	if is_instance_valid(camera):
		center = camera.global_position
		
	var half_w := vp_size.x * 0.75
	var half_h := vp_size.y * 0.75
	var rect := Rect2(center.x - half_w, center.y - half_h, half_w * 2.0, half_h * 2.0)
	
	# 배경 베이스 색상
	draw_rect(rect, bg_color)
	
	# 그리드 선 그리기
	var start_x: float = floor((center.x - half_w) / grid_size) * grid_size
	var end_x: float = ceil((center.x + half_w) / grid_size) * grid_size
	var start_y: float = floor((center.y - half_h) / grid_size) * grid_size
	var end_y: float = ceil((center.y + half_h) / grid_size) * grid_size
	
	var x: float = start_x
	while x <= end_x:
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.position.y + rect.size.y), grid_color, 1.0)
		x += grid_size
		
	var y: float = start_y
	while y <= end_y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.position.x + rect.size.x, y), grid_color, 1.0)
		y += grid_size
