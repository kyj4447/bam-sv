class_name WeaponGarlicAura
extends Node2D

@export var radius: float = 95.0
@export var damage: float = 14.0
@export var tick_rate: float = 0.5

var tick_timer: Timer
var pulse_anim: float = 0.0

func _ready() -> void:
	z_index = -1
	show_behind_parent = true
	tick_timer = Timer.new()
	tick_timer.wait_time = tick_rate
	tick_timer.autostart = true
	tick_timer.one_shot = false
	tick_timer.timeout.connect(_on_tick_timeout)
	add_child(tick_timer)

func _process(delta: float) -> void:
	pulse_anim += delta * 3.0
	queue_redraw()

func _draw() -> void:
	var pulse: float = sin(pulse_anim) * 4.0
	var wave: float = cos(pulse_anim * 0.8) * 2.5
	var base_r: float = radius + pulse

	# 1. 내부 코어: 깊고 차분한 딥 네이비
	draw_circle(Vector2.ZERO, base_r * 0.5, Color(0.04, 0.09, 0.28, 0.16))
	
	# 2. 중간 층: 네이비 ~ 오션 블루 오로라 바디
	draw_circle(Vector2.ZERO, base_r * 0.8, Color(0.06, 0.18, 0.48, 0.11))
	draw_circle(Vector2.ZERO, base_r, Color(0.08, 0.32, 0.7, 0.06))

	# 3. 경계선: 안개처럼 부드럽게 퍼지는 투명 오로라 림 (페더링 다중 아크)
	draw_arc(Vector2.ZERO, base_r - 5.0, 0, TAU, 48, Color(0.15, 0.45, 0.88, 0.18), 3.0)
	draw_arc(Vector2.ZERO, base_r, 0, TAU, 56, Color(0.25, 0.65, 0.98, 0.32 + wave * 0.03), 2.0)
	draw_arc(Vector2.ZERO, base_r + 4.0, 0, TAU, 48, Color(0.18, 0.5, 0.9, 0.14), 3.5)
	draw_arc(Vector2.ZERO, base_r + 9.0, 0, TAU, 40, Color(0.1, 0.3, 0.75, 0.06), 5.0)

func _on_tick_timeout() -> void:
	var enemies: Array = get_tree().get_nodes_in_group("enemy")
	var player: Player = owner as Player
	var dmg_mult: float = player.damage_multiplier if is_instance_valid(player) else 1.0
	var final_dmg: float = damage * dmg_mult
	var r_sq: float = radius * radius
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_squared_to((enemy as Node2D).global_position) <= r_sq:
			if enemy.has_method("take_damage"):
				enemy.take_damage(final_dmg)

func upgrade() -> void:
	radius += 18.0
	damage += 6.0
