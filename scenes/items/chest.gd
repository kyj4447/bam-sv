class_name Chest
extends Area2D

signal chest_opened(chest: Chest)

var anim_time: float = 0.0
var is_collected: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 # Player 감지
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	anim_time += delta * 4.0
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	if body is Player:
		is_collected = true
		chest_opened.emit(self)
		
		# 메인 씬에 보물상자 열기 요청
		var main_node: Node = get_tree().current_scene
		if main_node and main_node.has_method("open_chest_modal"):
			main_node.call_deferred("open_chest_modal")
			
		queue_free()

func _draw() -> void:
	var float_offset: float = sin(anim_time) * 4.0
	var pos: Vector2 = Vector2(0, float_offset)
	
	# 황금빛 상자 베이스
	var box_rect: Rect2 = Rect2(pos.x - 14, pos.y - 10, 28, 20)
	draw_rect(box_rect, Color(0.9, 0.7, 0.1, 1.0))
	draw_rect(box_rect, Color(0.6, 0.4, 0.05, 1.0), false, 2.0)
	
	# 상자 뚜껑
	var lid_rect: Rect2 = Rect2(pos.x - 16, pos.y - 15, 32, 8)
	draw_rect(lid_rect, Color(1.0, 0.85, 0.2, 1.0))
	draw_rect(lid_rect, Color(0.7, 0.5, 0.1, 1.0), false, 2.0)
	
	# 잠금 장치 / 보석 하이라이트
	draw_circle(pos + Vector2(0, -2), 3.5, Color(0.2, 0.9, 1.0, 1.0))
	
	# 황금빛 발광 아우라
	var glow_alpha: float = (sin(anim_time * 1.5) + 1.0) * 0.25 + 0.1
	draw_arc(pos, 22.0, 0, TAU, 24, Color(1.0, 0.9, 0.3, glow_alpha), 2.5)
