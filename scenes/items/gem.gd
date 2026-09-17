class_name Gem
extends Area2D

@export var exp_amount: float = 10.0

var target_player: Node2D = null
var is_collected: bool = false
var move_speed: float = 80.0
var acceleration: float = 750.0

func _ready() -> void:
	collision_layer = 8 # Layer 4: Gem
	collision_mask = 0

func _physics_process(delta: float) -> void:
	if not is_collected or not is_instance_valid(target_player):
		return
		
	# 플레이어를 향해 가속하며 날아감
	var dir: Vector2 = (target_player.global_position - global_position).normalized()
	move_speed += acceleration * delta
	global_position += dir * move_speed * delta
	
	# 플레이어와 근접 접촉 시 흡수
	if global_position.distance_to(target_player.global_position) <= 20.0:
		_consume()

func collect(player: Node2D) -> void:
	if is_collected:
		return
	is_collected = true
	target_player = player

func _consume() -> void:
	if is_instance_valid(target_player) and target_player.has_method("add_exp"):
		target_player.add_exp(exp_amount)
	
	# 팝 흡수 연출 (빠르게 확대 후 소멸)
	set_physics_process(false)
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.08)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.06)
	tween.tween_callback(queue_free)

func _draw() -> void:
	# 다이아몬드/마름모 형태의 영롱한 에메랄드 젬 렌더링
	var points: PackedVector2Array = [
		Vector2(0, -9),
		Vector2(6, 0),
		Vector2(0, 9),
		Vector2(-6, 0)
	]
	# 외곽선 / 발광
	draw_colored_polygon(points, Color(0.2, 0.95, 0.65, 0.95))
	# 내부 코어 하이라이트
	var inner_points: PackedVector2Array = [
		Vector2(0, -5),
		Vector2(3, 0),
		Vector2(0, 5),
		Vector2(-3, 0)
	]
	draw_colored_polygon(inner_points, Color(0.8, 1.0, 0.9, 0.9))
