class_name DamageNumber
extends Node2D

@onready var label: Label = $Label

func setup(amount: float, is_critical: bool = false) -> void:
	# 노드가 트리에 추가되기 전이거나 직후일 수 있으므로 안전 처리
	if not is_node_ready():
		await ready

	label.text = str(int(amount))
	
	if is_critical:
		label.modulate = Color(1.0, 0.3, 0.2, 1.0)
		label.add_theme_font_size_override("font_size", 22)
	else:
		label.modulate = Color(1.0, 0.92, 0.4, 1.0)
		label.add_theme_font_size_override("font_size", 16)

	var tween: Tween = create_tween().set_parallel(true)
	
	# 위로 솟아오르며 좌우로 살짝 퍼지는 모션
	var target_x: float = randf_range(-25.0, 25.0)
	var target_y: float = randf_range(-45.0, -60.0)
	var target_pos: Vector2 = position + Vector2(target_x, target_y)
	
	tween.tween_property(self, "position", target_pos, 0.55).set_trans(Tween.TRANS_OUT).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.25, 1.25), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "scale", Vector2(0.8, 0.8), 0.3)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.35).set_delay(0.2)
	
	tween.chain().tween_callback(queue_free)
