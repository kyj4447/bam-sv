class_name WeaponSolarAura
extends Node2D

@export var radius: float = 190.0
@export var damage: float = 30.0
@export var tick_rate: float = 0.4

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
	pulse_anim += delta * 4.0
	queue_redraw()

func _draw() -> void:
	var pulse: float = sin(pulse_anim) * 7.0
	var wave: float = cos(pulse_anim * 0.7) * 3.5
	var r: float = radius + pulse
	
	# 심연의 코스믹 네이비 오로라
	draw_circle(Vector2.ZERO, r * 0.5, Color(0.05, 0.08, 0.32, 0.18))
	draw_circle(Vector2.ZERO, r * 0.8, Color(0.08, 0.22, 0.55, 0.12))
	draw_circle(Vector2.ZERO, r, Color(0.1, 0.38, 0.8, 0.07))
	
	# 몽환적으로 번지는 투명 오로라 외곽 림
	draw_arc(Vector2.ZERO, r - 6.0, 0, TAU, 56, Color(0.2, 0.55, 0.95, 0.25), 4.0)
	draw_arc(Vector2.ZERO, r, 0, TAU, 64, Color(0.3, 0.8, 1.0, 0.45 + wave * 0.03), 2.5)
	draw_arc(Vector2.ZERO, r + 6.0, 0, TAU, 56, Color(0.18, 0.5, 0.9, 0.18), 4.5)
	draw_arc(Vector2.ZERO, r + 12.0, 0, TAU, 48, Color(0.1, 0.3, 0.75, 0.08), 6.0)

func _on_tick_timeout() -> void:
	var enemies: Array = get_tree().get_nodes_in_group("enemy")
	var player: Player = owner as Player
	var dmg_mult: float = player.damage_multiplier if is_instance_valid(player) else 1.0
	var final_dmg: float = damage * dmg_mult
	var r_sq: float = radius * radius
	
	var hit_count: int = 0
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_squared_to((enemy as Node2D).global_position) <= r_sq:
			if enemy.has_method("take_damage"):
				enemy.take_damage(final_dmg)
				hit_count += 1
				
	# 흡혈: 타격 성공 시 플레이어 체력 미량 회복
	if hit_count > 0 and is_instance_valid(player):
		var heal_amount: float = min(float(hit_count) * 0.4, 3.0)
		player.current_health = min(player.max_health, player.current_health + heal_amount)
		player.health_changed.emit(player.current_health, player.max_health)
