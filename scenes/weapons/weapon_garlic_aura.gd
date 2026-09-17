class_name WeaponGarlicAura
extends Node2D

@export var radius: float = 95.0
@export var damage: float = 14.0
@export var tick_rate: float = 0.5

var tick_timer: Timer
var pulse_anim: float = 0.0

func _ready() -> void:
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
	var current_r: float = radius + pulse
	# 은은한 오라 렌더링
	draw_circle(Vector2.ZERO, current_r, Color(1.0, 0.95, 0.5, 0.12))
	draw_arc(Vector2.ZERO, current_r, 0, TAU, 32, Color(1.0, 0.9, 0.4, 0.45), 2.0)

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
