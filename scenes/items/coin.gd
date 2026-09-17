class_name Coin
extends Area2D

@export var gold_value: int = 15

var is_collected: bool = false
var target_player: Player = null
var current_speed: float = 80.0
var max_speed: float = 680.0
var acceleration: float = 750.0

func _ready() -> void:
	collision_layer = 8
	collision_mask = 0
	queue_redraw()

func _draw() -> void:
	# 황금빛 코인 그래픽 (바깥 테두리 + 금빛 면 + 내부 음각)
	draw_circle(Vector2.ZERO, 6.0, Color(0.95, 0.78, 0.15, 1.0))
	draw_circle(Vector2.ZERO, 4.5, Color(1.0, 0.88, 0.3, 1.0))
	draw_circle(Vector2.ZERO, 2.5, Color(0.85, 0.65, 0.1, 1.0))

func collect(player: Player) -> void:
	if is_collected:
		return
	is_collected = true
	target_player = player
	# 플레이어 자석 흡수 중에는 추가 충돌 비활성화
	set_deferred("monitoring", false)

func _physics_process(delta: float) -> void:
	if not is_collected:
		# 가벼운 공중 부양 둥둥 효과
		position.y += sin(Time.get_ticks_msec() * 0.006) * 0.25
		return

	if not is_instance_valid(target_player):
		queue_free()
		return

	var to_player: Vector2 = target_player.global_position - global_position
	var distance: float = to_player.length()

	current_speed = min(current_speed + acceleration * delta, max_speed)
	var move_step: float = current_speed * delta

	if distance <= move_step or distance <= 18.0:
		# 플레이어에게 도달 -> 골드 지급
		var main_node: Node = get_tree().current_scene
		if main_node and main_node.has_method("add_run_gold"):
			main_node.add_run_gold(gold_value)
		else:
			SaveManager.get_instance().add_gold(gold_value)
		queue_free()
	else:
		global_position += to_player.normalized() * move_step
